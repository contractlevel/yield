package main

import (
	"fmt"
	"log/slog"
	"math/big"

	"cre-rebalance/contracts/evm/src/generated/parent_peer"
	"cre-rebalance/contracts/evm/src/generated/rebalancer"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

/*//////////////////////////////////////////////////////////////
                             CONSTS
//////////////////////////////////////////////////////////////*/

const LatestBlock = int64(-3)

/*//////////////////////////////////////////////////////////////
                           INTERFACES
//////////////////////////////////////////////////////////////*/

// ParentPeerInterface defines the subset of methods used to read the current strategy.
type ParentPeerInterface interface {
	GetStrategy(runtime cre.Runtime, blockNumber *big.Int) cre.Promise[parent_peer.IYieldPeerStrategy]
}

// YieldPeerInterface defines the subset of methods used to read TVL.
type YieldPeerInterface interface {
	GetTotalValue(runtime cre.Runtime, blockNumber *big.Int) cre.Promise[*big.Int]
}

// RebalancerInterface defines the subset of methods used to write the rebalance report.
type RebalancerInterface interface {
	WriteReportFromIYieldPeerStrategy(runtime cre.Runtime, input rebalancer.IYieldPeerStrategy, gasConfig *evm.GasConfig) cre.Promise[*evm.WriteReportReply]
}

/*//////////////////////////////////////////////////////////////
                             TYPES
//////////////////////////////////////////////////////////////*/

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
	GasLimit          uint64 `json:"gasLimit"`
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
                  DEPS FOR ON-CRON (INJECTION POINT)
//////////////////////////////////////////////////////////////*/

type onCronDeps struct {
	ReadCurrentStrategy func(peer ParentPeerInterface, runtime cre.Runtime) (Strategy, error)
	ReadTVL             func(peer YieldPeerInterface, runtime cre.Runtime) (*big.Int, error)
	WriteRebalance      func(rb RebalancerInterface, runtime cre.Runtime, logger *slog.Logger, gasLimit uint64, optimal Strategy) error
}

// defaultOnCronDeps are the onchain implementations.
var defaultOnCronDeps = onCronDeps{
	ReadCurrentStrategy: chainReadCurrentStrategy,
	ReadTVL:             chainReadTVL,
	WriteRebalance:      chainWriteRebalance,
}

/*//////////////////////////////////////////////////////////////
                        ON CRON TRIGGER
//////////////////////////////////////////////////////////////*/

func onCronTrigger(config *Config, runtime cre.Runtime, trigger *cron.Payload) (*StrategyResult, error) {
	return onCronTriggerWithDeps(config, runtime, trigger, defaultOnCronDeps)
}

func onCronTriggerWithDeps(config *Config, runtime cre.Runtime, trigger *cron.Payload, deps onCronDeps) (*StrategyResult, error) {
	logger := runtime.Logger()

	// Ensure we have at least one EVM config and treat evms[0] as parent chain.
	if len(config.Evms) == 0 {
		return nil, fmt.Errorf("no EVM configs provided")
	}
	parentCfg := config.Evms[0]

	// Create EVM client for parent chain once.
	parentEvmClient := &evm.Client{
		ChainSelector: parentCfg.ChainSelector,
	}

	// Validate + parse ParentPeer address once.
	if !common.IsHexAddress(parentCfg.YieldPeerAddress) {
		return nil, fmt.Errorf("invalid YieldPeer address: %s", parentCfg.YieldPeerAddress)
	}
	parentYieldPeerAddr := common.HexToAddress(parentCfg.YieldPeerAddress)

	// Instantiate ParentPeer contract once.
	parentYieldPeer, err := parent_peer.NewParentPeer(parentEvmClient, parentYieldPeerAddr, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create parent YieldPeer binding: %w", err)
	}

	// Read current strategy from parent YieldPeer via deps.
	currentStrategy, err := deps.ReadCurrentStrategy(parentYieldPeer, runtime)
	if err != nil {
		return nil, fmt.Errorf("failed to read strategy from parent YieldPeer: %w", err)
	}
	logger.Info(
		"Read current strategy from parent YieldPeer",
		"protocolId", fmt.Sprintf("0x%x", currentStrategy.ProtocolId),
		"chainSelector", currentStrategy.ChainSelector,
	)

	// Decide which YieldPeer to use for TVL:
	// - If the strategy lives on the parent chain, reuse parentYieldPeer.
	// - Otherwise, instantiate a YieldPeer on the strategy chain.
	var strategyYieldPeer YieldPeerInterface

	if currentStrategy.ChainSelector == parentCfg.ChainSelector {
		// Same chain: no extra client or contract instantiation.
		strategyYieldPeer = parentYieldPeer
	} else {
		// Different chain: find config and instantiate strategy peer.
		strategyChainCfg, err := findEvmConfigByChainSelector(config.Evms, currentStrategy.ChainSelector)
		if err != nil {
			return nil, fmt.Errorf("no EVM config found for strategy chainSelector %d: %w", currentStrategy.ChainSelector, err)
		}

		// Create EVM client for strategy chain once.
		strategyEvmClient := &evm.Client{ChainSelector: strategyChainCfg.ChainSelector}

		// Validate + parse Strategy YieldPeer address once.
		if !common.IsHexAddress(strategyChainCfg.YieldPeerAddress) {
			return nil, fmt.Errorf("invalid YieldPeer address: %s", strategyChainCfg.YieldPeerAddress)
		}
		strategyYieldPeerAddr := common.HexToAddress(strategyChainCfg.YieldPeerAddress)

		// Instantiate Strategy YieldPeer contract once.
		// Note: still using parent_peer binding; underlying contract could be a child.
		strategyPeer, err := parent_peer.NewParentPeer(strategyEvmClient, strategyYieldPeerAddr, nil)
		if err != nil {
			return nil, fmt.Errorf("failed to create strategy YieldPeer binding: %w", err)
		}
		strategyYieldPeer = strategyPeer
	}

	// Read the TVL from the selected YieldPeer via deps.
	tvl, err := deps.ReadTVL(strategyYieldPeer, runtime)
	if err != nil {
		return nil, fmt.Errorf("failed to get total value from strategy YieldPeer: %w", err)
	}

	// Calculate optimal strategy based on TVL and lending pool state (pseudocode inside).
	optimalStrategy := calculateOptimalStrategy(logger, currentStrategy, tvl)

	// Inject write function that performs the actual onchain rebalance on the parent chain.
	writeFn := func(optimal Strategy) error {
		// Lazily validate + parse Rebalancer address only if we actually rebalance.
		if !common.IsHexAddress(parentCfg.RebalancerAddress) {
			return fmt.Errorf("invalid Rebalancer address: %s", parentCfg.RebalancerAddress)
		}
		parentRebalancerAddr := common.HexToAddress(parentCfg.RebalancerAddress)

		// Instantiate Rebalancer contract once per rebalance attempt.
		parentRebalancer, err := rebalancer.NewRebalancer(parentEvmClient, parentRebalancerAddr, nil)
		if err != nil {
			return fmt.Errorf("failed to create parent Rebalancer binding: %w", err)
		}

		return deps.WriteRebalance(parentRebalancer, runtime, logger, parentCfg.GasLimit, optimal)
	}

	// Delegate comparison + APY-threshold logic + optional write to the pure function.
	return decideAndMaybeRebalance(logger, currentStrategy, optimalStrategy, writeFn)
}

/*//////////////////////////////////////////////////////////////
                 ONCHAIN DEPENDENCY IMPLEMENTATIONS
//////////////////////////////////////////////////////////////*/

func chainReadCurrentStrategy(
	peer ParentPeerInterface,
	runtime cre.Runtime,
) (Strategy, error) {
	current, err := peer.GetStrategy(runtime, big.NewInt(LatestBlock)).Await()
	if err != nil {
		return Strategy{}, err
	}

	return Strategy{
		ProtocolId:    current.ProtocolId,
		ChainSelector: current.ChainSelector,
	}, nil
}

func chainReadTVL(
	peer YieldPeerInterface,
	runtime cre.Runtime,
) (*big.Int, error) {
	return peer.GetTotalValue(runtime, big.NewInt(LatestBlock)).Await()
}

func chainWriteRebalance(
	rb RebalancerInterface,
	runtime cre.Runtime,
	logger *slog.Logger,
	gasLimit uint64,
	optimal Strategy,
) error {
	gasConfig := &evm.GasConfig{GasLimit: gasLimit}

	rebalancerStrategy := rebalancer.IYieldPeerStrategy{
		ProtocolId:    optimal.ProtocolId,
		ChainSelector: optimal.ChainSelector,
	}

	resp, err := rb.WriteReportFromIYieldPeerStrategy(runtime, rebalancerStrategy, gasConfig).Await()
	if err != nil {
		return fmt.Errorf("failed to update strategy on Rebalancer: %w", err)
	}

	logger.Info(
		"Rebalancer update transaction submitted",
		"txHash", fmt.Sprintf("0x%x", resp.TxHash),
	)
	return nil
}

/*//////////////////////////////////////////////////////////////
                    CALCULATE OPTIMAL STRATEGY
//////////////////////////////////////////////////////////////*/

// calculateOptimalStrategy is where the "brains" of the strategy selection live.
// For now it's just pseudocode / comments.
func calculateOptimalStrategy(
	logger *slog.Logger,
	current Strategy, // @review not doing anything with currentStrategy here
	tvl *big.Int,
) Strategy {
	// Placeholder / dummy logic for now:
	// Use a fixed protocol ID as the "optimal" target, to keep the workflow
	// behavior deterministic while you iterate on the real APY model.
	protocol := "dummy-protocol-v1"
	hashedProtocolId := crypto.Keccak256([]byte(protocol))

	var optimalId [32]byte
	copy(optimalId[:], hashedProtocolId)

	optimal := Strategy{
		ProtocolId:    optimalId,
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

/*//////////////////////////////////////////////////////////////
                  DECIDE AND MAYBE REBALANCE
//////////////////////////////////////////////////////////////*/

func decideAndMaybeRebalance(
	logger *slog.Logger,
	current Strategy,
	optimal Strategy,
	writeFn func(Strategy) error,
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

	// 7. (else) APY logic placeholder – only rebalance when difference is meaningful. ie higher than neglible threshold

	logger.Info(
		"Strategy changed and APY improvement deemed worthwhile; rebalancing",
		"currentProtocolId", fmt.Sprintf("0x%x", current.ProtocolId),
		"currentChainSelector", current.ChainSelector,
		"optimalProtocolId", fmt.Sprintf("0x%x", optimal.ProtocolId),
		"optimalChainSelector", optimal.ChainSelector,
	)

	// 8. Execute onchain rebalance tx via injected function.
	if err := writeFn(optimal); err != nil {
		return nil, err
	}

	return &StrategyResult{
		Current: current,
		Optimal: optimal,
		Updated: true,
	}, nil
}

/*//////////////////////////////////////////////////////////////
                       HELPER FUNCTIONS
//////////////////////////////////////////////////////////////*/

func findEvmConfigByChainSelector(evms []EvmConfig, target uint64) (*EvmConfig, error) {
	for i := range evms {
		if evms[i].ChainSelector == target {
			return &evms[i], nil
		}
	}
	return nil, fmt.Errorf("no evm config found for chainSelector %d", target)
}
