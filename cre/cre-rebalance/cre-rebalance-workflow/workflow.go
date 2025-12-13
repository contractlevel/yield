package main

import (
	"fmt"
	"log/slog"

	"cre-rebalance/contracts/evm/src/generated/parent_peer"
	"cre-rebalance/contracts/evm/src/generated/rebalancer"
	"cre-rebalance/cre-rebalance-workflow/internal/onchain"
	"cre-rebalance/cre-rebalance-workflow/internal/offchain"

	"github.com/ethereum/go-ethereum/common"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

/*//////////////////////////////////////////////////////////////
                         INIT WORKFLOW
//////////////////////////////////////////////////////////////*/

// InitWorkflow registers the cron handler.
func InitWorkflow(config *offchain.Config, logger *slog.Logger, secretsProvider cre.SecretsProvider) (cre.Workflow[*offchain.Config], error) {
	return cre.Workflow[*offchain.Config]{
		cre.Handler(
			cron.Trigger(&cron.Config{Schedule: config.Schedule}),
			onCronTrigger,
		),
	}, nil
}

/*//////////////////////////////////////////////////////////////
                  DEPS FOR ON-CRON (INJECTION POINT)
//////////////////////////////////////////////////////////////*/

// defaultOnCronDeps are the onchain implementations.
var defaultOnCronDeps = offchain.OnCronDeps{
	ReadCurrentStrategy: onchain.ReadCurrentStrategy,
	ReadTVL:             onchain.ReadTVL,
	WriteRebalance:      onchain.WriteRebalance,
}

/*//////////////////////////////////////////////////////////////
                        ON CRON TRIGGER
//////////////////////////////////////////////////////////////*/

func onCronTrigger(config *offchain.Config, runtime cre.Runtime, trigger *cron.Payload) (*offchain.StrategyResult, error) {
	return onCronTriggerWithDeps(config, runtime, trigger, defaultOnCronDeps)
}

func onCronTriggerWithDeps(config *offchain.Config, runtime cre.Runtime, trigger *cron.Payload, deps offchain.OnCronDeps) (*offchain.StrategyResult, error) {
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
	var strategyYieldPeer onchain.YieldPeerInterface
	var rebalanceGasLimit uint64

	if currentStrategy.ChainSelector == parentCfg.ChainSelector {
		// Same chain: no extra client or contract instantiation.
		strategyYieldPeer = parentYieldPeer
		rebalanceGasLimit = parentCfg.GasLimit
	} else {
		// Different chain: find config and instantiate strategy peer.
		strategyChainCfg, err := offchain.FindEvmConfigByChainSelector(config.Evms, currentStrategy.ChainSelector)
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
		rebalanceGasLimit = strategyChainCfg.GasLimit
	}

	// Read the TVL from the selected YieldPeer via deps.
	tvl, err := deps.ReadTVL(strategyYieldPeer, runtime)
	if err != nil {
		return nil, fmt.Errorf("failed to get total value from strategy YieldPeer: %w", err)
	}

	// Calculate optimal strategy based on TVL and lending pool state (pseudocode inside).
	optimalStrategy := offchain.CalculateOptimalStrategy(logger, currentStrategy, tvl)

	// Inject write function that performs the actual onchain rebalance on the parent chain.
	writeFn := func(optimal onchain.Strategy) error {
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

		return deps.WriteRebalance(parentRebalancer, runtime, logger, rebalanceGasLimit, optimal)
	}

	// Delegate comparison + APY-threshold logic + optional write to the pure function.
	return offchain.RebalanceIfNeeded(logger, currentStrategy, optimalStrategy, writeFn)
}