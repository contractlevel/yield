package main

import (
	"fmt"
	"log/slog"
	"math/big"

	"cre-rebalance/cre-rebalance-workflow/internal/helper"
	"cre-rebalance/cre-rebalance-workflow/internal/onchain"
	"cre-rebalance/cre-rebalance-workflow/internal/strategy"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

/*//////////////////////////////////////////////////////////////
                         INIT WORKFLOW
//////////////////////////////////////////////////////////////*/

// InitWorkflow registers the cron handler.
func InitWorkflow(config *helper.Config, logger *slog.Logger, secretsProvider cre.SecretsProvider) (cre.Workflow[*helper.Config], error) {
	return cre.Workflow[*helper.Config]{
		cre.Handler(
			cron.Trigger(&cron.Config{Schedule: config.Schedule}),
			onCronTrigger,
		),
	}, nil
}

/*//////////////////////////////////////////////////////////////
                  DEPS FOR ON-CRON (INJECTION POINT)
//////////////////////////////////////////////////////////////*/

type OnCronDeps struct {
	ReadCurrentStrategy func(peer onchain.ParentPeerInterface, runtime cre.Runtime) (onchain.Strategy, error)
	ReadTVL             func(peer onchain.YieldPeerInterface, runtime cre.Runtime) (*big.Int, error)
	WriteRebalance      func(rb onchain.RebalancerInterface, runtime cre.Runtime, logger *slog.Logger, gasLimit uint64, optimal onchain.Strategy) error
}

// defaultOnCronDeps are the onchain implementations.
var defaultOnCronDeps = OnCronDeps{
	ReadCurrentStrategy: onchain.ReadCurrentStrategy,
	ReadTVL:             onchain.ReadTVL,
	WriteRebalance:      onchain.WriteRebalance,
}

/*//////////////////////////////////////////////////////////////
                        ON CRON TRIGGER
//////////////////////////////////////////////////////////////*/

func onCronTrigger(config *helper.Config, runtime cre.Runtime, trigger *cron.Payload) (*strategy.StrategyResult, error) {
	return onCronTriggerWithDeps(config, runtime, trigger, defaultOnCronDeps)
}

func onCronTriggerWithDeps(config *helper.Config, runtime cre.Runtime, trigger *cron.Payload, deps OnCronDeps) (*strategy.StrategyResult, error) {
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

	// Instantiate ParentPeer contract once.
	parentPeer, err := onchain.NewParentPeerBinding(parentEvmClient, parentCfg.YieldPeerAddress)
	if err != nil {
		return nil, fmt.Errorf("failed to create ParentPeer binding: %w", err)
	}

	// Read current strategy from ParentPeer via deps.
	currentStrategy, err := deps.ReadCurrentStrategy(parentPeer, runtime)
	if err != nil {
		return nil, fmt.Errorf("failed to read strategy from ParentPeer: %w", err)
	}
	logger.Info(
		"Read current strategy from ParentPeer",
		"protocolId", fmt.Sprintf("0x%x", currentStrategy.ProtocolId),
		"chainSelector", currentStrategy.ChainSelector,
	)

	// Decide which YieldPeer to use for TVL:
	// - If the strategy lives on the parent chain, reuse parentPeer.
	// - Otherwise, instantiate a YieldPeer on the strategy chain.
	var strategyPeer onchain.YieldPeerInterface
	var rebalanceGasLimit uint64

	if currentStrategy.ChainSelector == parentCfg.ChainSelector {
		// Same chain: no extra client or contract instantiation.
		strategyPeer = parentPeer
		rebalanceGasLimit = parentCfg.GasLimit
	} else {
		// Different chain: find config and instantiate strategy peer.
		strategyChainCfg, err := helper.FindEvmConfigByChainSelector(config.Evms, currentStrategy.ChainSelector)
		if err != nil {
			return nil, fmt.Errorf("no EVM config found for strategy chainSelector %d: %w", currentStrategy.ChainSelector, err)
		}

		// Create EVM client for strategy chain once.
		strategyEvmClient := &evm.Client{ChainSelector: strategyChainCfg.ChainSelector}

		// Instantiate Strategy YieldPeer contract once.
		// @review still using parent_peer binding; underlying contract should be a child.
		childPeer, err := onchain.NewChildPeerBinding(strategyEvmClient, strategyChainCfg.YieldPeerAddress)
		if err != nil {
			return nil, fmt.Errorf("failed to create strategy YieldPeer binding: %w", err)
		}

		strategyPeer = childPeer
		rebalanceGasLimit = strategyChainCfg.GasLimit
	}

	// Read the TVL from the strategy YieldPeer via deps.
	tvl, err := deps.ReadTVL(strategyPeer, runtime)
	if err != nil {
		return nil, fmt.Errorf("failed to get total value from strategy YieldPeer: %w", err)
	}

	// pseudocode placeholder: (this will use multiple defillama tier apis to get an aggregated optimal strategy)
	// aggregatedOptimalStrategy := offchain.GetAggregatedOptimalStrategy()

	// Calculate optimal strategy based on TVL and lending pool state (pseudocode inside).
	optimalStrategy := strategy.CalculateOptimalStrategy(logger, currentStrategy, tvl)

	if currentStrategy != optimalStrategy {
		// Inject write function that performs the actual onchain rebalance on the parent chain.
		writeFn := func(optimal onchain.Strategy) error {
			// Lazily validate + parse Rebalancer address only if we actually rebalance.
			// Instantiate Rebalancer contract once per rebalance attempt.
			parentRebalancer, err := onchain.NewRebalancerBinding(parentEvmClient, parentCfg.RebalancerAddress)
			if err != nil {
				return fmt.Errorf("failed to create parent Rebalancer binding: %w", err)
			}

			return deps.WriteRebalance(parentRebalancer, runtime, logger, rebalanceGasLimit, optimal)
		}

		logger.Info(
			"Strategy changed and APY improvement deemed worthwhile; rebalancing",
			"currentProtocolId", fmt.Sprintf("0x%x", currentStrategy.ProtocolId),
			"currentChainSelector", currentStrategy.ChainSelector,
			"optimalProtocolId", fmt.Sprintf("0x%x", optimalStrategy.ProtocolId),
			"optimalChainSelector", optimalStrategy.ChainSelector,
		)

		err := strategy.Rebalance(optimalStrategy, writeFn)
		if err != nil {
			return nil, fmt.Errorf("failed to rebalance: %w", err)
		}
		return &strategy.StrategyResult{
			Current: currentStrategy,
			Optimal: optimalStrategy,
			Updated: true,
		}, nil
	}

	logger.Info("Strategy unchanged; no rebalance needed")
	return &strategy.StrategyResult{
		Current: currentStrategy,
		Optimal: optimalStrategy,
		Updated: false,
	}, nil
}
