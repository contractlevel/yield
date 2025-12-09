package main

import (
	"fmt"
	"log/slog"
	"math/big"

	"cre-rebalance/contracts/evm/src/generated/rebalancer"
	"cre-rebalance/contracts/evm/src/generated/parent_peer"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

/*//////////////////////////////////////////////////////////////
                             TYPES
//////////////////////////////////////////////////////////////*/
// Strategy mirrors the Solidity struct:
//
// struct Strategy {
//   bytes32 protocolId;
//   uint64  chainSelector;
// }
type Strategy struct {
	ProtocolId    [32]byte
	ChainSelector uint64
}

// Config is loaded from config.json
//
// {
//   "schedule": "0 */1 * * * *",
//   "evms": [
//     {
//       "chainName": "ethereum-testnet-sepolia",
//       "chainSelector": 16015286601757825753,
//       "yieldPeerAddress": "0x...",
//       "rebalancerAddress": "0x...",
//       "gasLimit": 500000
//     }
//   ]
// }
type Config struct {
	Schedule string      `json:"schedule"`
	Evms     []EvmConfig `json:"evms"`
}

// EvmConfig:
// - evms[0] is the parent chain: where the Parent YieldPeer is
//   and where we read the currentStrategy from.
// - currentStrategy.ChainSelector tells us which chain the active strategy
//   adapter lives on.
type EvmConfig struct {
	ChainName         string `json:"chainName"`
	ChainSelector     uint64 `json:"chainSelector"`
	YieldPeerAddress  string `json:"yieldPeerAddress"`
	RebalancerAddress string `json:"rebalancerAddress"`
	GasLimit          uint64 `json:"gasLimit"` // @review should this be uint64???
}

// StrategyResult is primarily for debugging / testing.
type StrategyResult struct {
	Current Strategy `json:"current"`
	Optimal Strategy `json:"optimal"`
	Updated bool     `json:"updated"`
}

/*//////////////////////////////////////////////////////////////
                         INIT WORKFLOW
//////////////////////////////////////////////////////////////*/
// InitWorkflow registers the cron handler.
func InitWorkflow(config *Config, logger *slog.Logger, secretsProvider cre.SecretsProvider) (cre.Workflow[*Config], error) {
	return cre.Workflow[*Config]{
		cre.Handler(
			cron.Trigger(&cron.Config{Schedule: config.Schedule}),
			onCronTrigger,
		),
	}, nil
}

/*//////////////////////////////////////////////////////////////
                        ON CRON TRIGGER
//////////////////////////////////////////////////////////////*/
func onCronTrigger(config *Config, runtime cre.Runtime, trigger *cron.Payload) (*StrategyResult, error) {
	logger := runtime.Logger()

	// Ensure we have at least one EVM config and treat evms[0] as parent chain.
	if len(config.Evms) == 0 {
		return nil, fmt.Errorf("no EVM configs provided")
	}
	parentCfg := config.Evms[0]

	// Create EVM client for parent chain.
	parentEvmClient := &evm.Client{
		ChainSelector: parentCfg.ChainSelector,
	}

	// Validate + parse ParentPeer address
	if !common.IsHexAddress(parentCfg.YieldPeerAddress) {
		return nil, fmt.Errorf("invalid YieldPeer address: %s", parentCfg.YieldPeerAddress)
	}
	parentYieldPeerAddr := common.HexToAddress(parentCfg.YieldPeerAddress)

	// Instantiate ParentPeer contract
	parentYieldPeer, err := parent_peer.NewParentPeer(parentEvmClient, parentYieldPeerAddr, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create parent YieldPeer binding: %w", err)
	}

	// Read current strategy from parent YieldPeer.
	current, err := parentYieldPeer.GetStrategy(runtime, big.NewInt(-3)).Await()
	if err != nil {
		return nil, fmt.Errorf("failed to read strategy from parent YieldPeer: %w", err)
	}

	currentStrategy := Strategy{
		ProtocolId:    current.ProtocolId,
		ChainSelector: current.ChainSelector,
	}
	logger.Info(
		"Read current strategy from parent YieldPeer",
		"protocolId", fmt.Sprintf("0x%x", currentStrategy.ProtocolId),
		"chainSelector", currentStrategy.ChainSelector,
	)

	// Find EVM config whose chainSelector is currentStrategy.ChainSelector.
	strategyChainCfg, err := findEvmConfigByChainSelector(config.Evms, currentStrategy.ChainSelector)
	if err != nil {
		return nil, fmt.Errorf("no EVM config found for strategy chainSelector %d: %w", currentStrategy.ChainSelector, err)
	}
	strategyEvmClient := &evm.Client{ChainSelector: strategyChainCfg.ChainSelector}

	// Validate + parse Strategy YieldPeer address
	if !common.IsHexAddress(strategyChainCfg.YieldPeerAddress) {
		return nil, fmt.Errorf("invalid YieldPeer address: %s", strategyChainCfg.YieldPeerAddress)
	}
	strategyYieldPeerAddr := common.HexToAddress(strategyChainCfg.YieldPeerAddress)
	
	// Instantiate Strategy YieldPeer contract
	// @review this is using parent_peer contract, but could be a child.
	strategyYieldPeer, err := parent_peer.NewParentPeer(strategyEvmClient, strategyYieldPeerAddr, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create strategy YieldPeer binding: %w", err)
	}

	// Read the TVL from the current Strategy YieldPeer.
	tvl, err := strategyYieldPeer.GetTotalValue(runtime, big.NewInt(-3)).Await()
	if err != nil {
		return nil, fmt.Errorf("failed to get total value from strategy YieldPeer: %w", err)
	}

	// Calculate optimal strategy based on TVL and lending pool state (pseudocode inside).
	optimalStrategy := calculateOptimalStrategy(logger, currentStrategy, tvl)

	// Decide whether to rebalance and, if so, execute onchain tx via parentRebalancer.

	// Inject write function that performs the actual onchain rebalance on the parent chain.
	// @review why would we want to inject this function?
	writeFn := func(optimal Strategy) error {
		// Validate + parse Rebalancer address
		if !common.IsHexAddress(parentCfg.RebalancerAddress) {
			return fmt.Errorf("invalid Rebalancer address: %s", parentCfg.RebalancerAddress)
		}
		parentRebalancerAddr := common.HexToAddress(parentCfg.RebalancerAddress)

		// Instantiate Rebalancer contract
		parentRebalancer, err := rebalancer.NewRebalancer(parentEvmClient, parentRebalancerAddr, nil)
		if err != nil {
			return fmt.Errorf("failed to create parent Rebalancer binding: %w", err)
		}

		gasConfig := &evm.GasConfig{
			GasLimit: parentCfg.GasLimit,
		}

		// @review this Strategy
		rebalancerStrategy := rebalancer.Strategy{
			ProtocolId:    optimal.ProtocolId,
			ChainSelector: optimal.ChainSelector,
		}

		resp, err := parentRebalancer.
			WriteReportFromStrategy(runtime, rebalancerStrategy, gasConfig).
			Await()
		if err != nil {
			return fmt.Errorf("failed to update strategy on Rebalancer: %w", err)
		}

		logger.Info(
			"Rebalancer update transaction submitted",
			"txHash", fmt.Sprintf("0x%x", resp.TxHash),
		)

		return nil
	}

	// Delegate comparison + APY-threshold logic + optional write to the pure function.
	return decideAndMaybeRebalance(logger, currentStrategy, optimalStrategy, writeFn)
}

/*//////////////////////////////////////////////////////////////
                    CALCULATE OPTIMAL STRATEGY
//////////////////////////////////////////////////////////////*/
// calculateOptimalStrategy is where the "brains" of the strategy selection live.
// For now it's just pseudocode / comments.
// This will need to factor in the ProtocolId as to how APY is calculated. ie we will perform different logic for aave v3 and v4
func calculateOptimalStrategy(
	logger *slog.Logger,
	current Strategy,
	tvl *big.Int,
	// later you can pass additional pre-fetched pool state here if you want
) Strategy {
	// Read onchain state of lending pools and calculates APY
	//
	//    PSEUDOCODE EXAMPLE:
	//
	//    pools := fetchLendingPoolsState(current.ChainSelector)
	//
	//    for each pool in pools:
	//        baseApy := pool.SupplyRate
	//        utilization := pool.Utilization
	//        incentives := pool.RewardRate
	//        riskAdjustments := f(pool.Ltv, pool.LiquidationThreshold, pool.ReserveFactor)
	//
	//        effectiveApy := baseApy + incentives - riskAdjustments
	//        if effectiveApy > bestApy:
	//            bestApy = effectiveApy
	//            bestPool = pool
	//
	// Calculate APY decrease based on tvl and other pool factors like slippage
	//
	//    PSEUDOCODE EXAMPLE:
	//
	//    // model APY vs TVL degradation:
	//    // effectiveApy(tvl) = baseApy - k * log(1 + tvl / capacity)
	//    // where k > 0 encodes how quickly APY decays with size
	//    for candidatePool in candidatePools:
	//        projectedApy := modelProjectedApy(candidatePool, tvl)
	//        if projectedApy > bestProjectedApy:
	//            bestProjectedApy = projectedApy
	//            bestStrategy = Strategy{
	//                ProtocolId:    candidatePool.ProtocolId,
	//                ChainSelector: candidatePool.ChainSelector,
	//            }

	// Placeholder / dummy logic for now:
	// Use a fixed protocol ID as the "optimal" target, to keep the workflow
	// behavior deterministic while you iterate on the real APY model.
	protocol := "dummy-protocol-v1"
	hashedProtocolId := crypto.Keccak256([]byte(protocol))

	var optimalProtocolId [32]byte
	copy(optimalProtocolId[:], hashedProtocolId)

	optimal := Strategy{
		ProtocolId:    optimalProtocolId,
		ChainSelector: current.ChainSelector,
	}

	logger.Info(
		"Calculated optimal strategy candidate",
		"protocolId", fmt.Sprintf("0x%x", optimal.ProtocolId),
		"chainSelector", optimal.ChainSelector,
		"tvl", tvl.String(),
	)

	return optimal
}

// decideAndMaybeRebalance implements steps 6–8:
//
// 6. compare optimal strategy to current strategy (if same, return)
// 7. (else) calculate APY for current strategy (if negligible difference, return)
// 8. execute onchain rebalance tx (via writeFn)
func decideAndMaybeRebalance(
	logger *slog.Logger,
	current Strategy,
	optimal Strategy,
	writeFn func(optimal Strategy) error,
) (*StrategyResult, error) {
	// 6. Compare optimal vs current
	if current == optimal {
		logger.Info("Strategy unchanged; no update needed")
		return &StrategyResult{
			Current: current,
			Optimal: optimal,
			Updated: false,
		}, nil
	}

	// 7. (else) calculate APY for current strategy and only rebalance if difference is meaningful.
	//
	//    PSEUDOCODE EXAMPLE:
	//
	//    currentApy := computeCurrentStrategyApy(current)
	//    optimalApy := computeOptimalStrategyApy(optimal)
	//
	//    apyDiff := optimalApy - currentApy
	//    if apyDiff < minRebalanceThreshold {
	//        logger.Info("APY improvement negligible; skipping rebalance",
	//            "currentApy", currentApy,
	//            "optimalApy", optimalApy,
	//            "apyDiff", apyDiff,
	//        )
	//        return &StrategyResult{
	//            Current: current,
	//            Optimal: optimal,
	//            Updated: false,
	//        }, nil
	//    }

	logger.Info(
		"Strategy changed and APY improvement deemed worthwhile; rebalancing",
		"currentProtocolId", fmt.Sprintf("0x%x", current.ProtocolId),
		"currentChainSelector", current.ChainSelector,
		"optimalProtocolId", fmt.Sprintf("0x%x", optimal.ProtocolId),
		"optimalChainSelector", optimal.ChainSelector,
	)

	// 8. Execute onchain rebalance tx via injected function
	if err := writeFn(optimal); err != nil {
		return nil, err
	}

	return &StrategyResult{
		Current: current,
		Optimal: optimal,
		Updated: true,
	}, nil
}

func findEvmConfigByChainSelector(evms []EvmConfig, target uint64) (*EvmConfig, error) {
    for i := range evms {
        selector := evms[i].ChainSelector
        if selector == target {
            return &evms[i], nil
        }
    }
    return nil, fmt.Errorf("no evm config found for chainSelector %d", target)
}