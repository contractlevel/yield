package main

import (
	"fmt"
	"log/slog"
	"math/big"

	"cre-rebalance/cre-rebalance-workflow/internal/helper"
	"cre-rebalance/cre-rebalance-workflow/internal/offchain"
	"cre-rebalance/cre-rebalance-workflow/internal/onchain"
	"cre-rebalance/cre-rebalance-workflow/internal/strategy"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

/*//////////////////////////////////////////////////////////////
                           CONFIG
//////////////////////////////////////////////////////////////*/

// threshold is the minimum APY improvement (in whatever units
// CalculateAPYForStrategy returns, typically 1e18 precision) required
// before we actually rebalance.
var threshold = big.NewInt(0) // @review TODO: set to something sensible, e.g. 5e15 for 0.5%

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

	// @review pseudocode placeholder: (this will use multiple defillama-tier APIs to get an aggregated optimal strategy)
	optimalStrategy, err := offchain.GetOptimalStrategy()
	if err != nil {
		return nil, fmt.Errorf("failed to get optimal strategy: %w", err)
	}

	// If nothing has changed, we can stop early.
	if currentStrategy == optimalStrategy {
		logger.Info("Strategy unchanged; no rebalance needed")
		return &strategy.StrategyResult{
			Current: currentStrategy,
			Optimal: optimalStrategy,
			Updated: false,
		}, nil
	}

	// Decide which YieldPeer to use for TVL:
	// - If the strategy lives on the parent chain, reuse parentPeer.
	// - Otherwise, instantiate a YieldPeer on the strategy chain.
	var (
		strategyPeer      onchain.YieldPeerInterface
		rebalanceGasLimit uint64
	)

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
		strategyPeer, err := onchain.NewChildPeerBinding(strategyEvmClient, strategyChainCfg.YieldPeerAddress)
		if err != nil {
			return nil, fmt.Errorf("failed to create strategy YieldPeer binding: %w", err)
		}

		rebalanceGasLimit = strategyChainCfg.GasLimit
	}

	// Read the TVL from the strategy YieldPeer via deps.
	tvl, err := deps.ReadTVL(strategyPeer, runtime)
	if err != nil {
		return nil, fmt.Errorf("failed to get total value from strategy YieldPeer: %w", err)
	}

	// Calculate the new APY for the optimal strategy if we deposit the Yieldcoin TVL into it.
	optimalStrategyAPY, err := onchain.CalculateAPYForStrategy(optimalStrategy, tvl)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate optimal strategy APY: %w", err)
	}

	// Calculate the current APY for the current strategy (liquidityAdded = 0).
	currentStrategyAPY, err := onchain.CalculateAPYForStrategy(currentStrategy, big.NewInt(0))
	if err != nil {
		return nil, fmt.Errorf("failed to calculate current strategy APY: %w", err)
	}

	// Compute delta := optimal - current as big.Int.
	delta := new(big.Int).Sub(optimalStrategyAPY, currentStrategyAPY)

	logger.Info(
		"Computed APYs",
		"tvl", tvl.String(),
		"currentAPY", currentStrategyAPY.String(),
		"optimalAPY", optimalStrategyAPY.String(),
		"delta", delta.String(),
		"threshold", threshold.String(),
	)

	// If the delta is below the threshold, return without updating.
	if delta.Cmp(threshold) < 0 {
		logger.Info("Delta below threshold; no rebalance needed")
		return &strategy.StrategyResult{
			Current: currentStrategy,
			Optimal: optimalStrategy,
			Updated: false,
		}, nil
	}

	// At this point:
	// - optimal APY is strictly better than current
	// - improvement exceeds threshold
	// so we go ahead and rebalance.

	parentRebalancer, err := onchain.NewRebalancerBinding(parentEvmClient, parentCfg.RebalancerAddress)
	if err != nil {
		return nil, fmt.Errorf("failed to create parent Rebalancer binding: %w", err)
	}

	if err := deps.WriteRebalance(parentRebalancer, runtime, logger, rebalanceGasLimit, optimalStrategy); err != nil {
		return nil, fmt.Errorf("failed to rebalance: %w", err)
	}

	return &strategy.StrategyResult{
		Current: currentStrategy,
		Optimal: optimalStrategy,
		Updated: true,
	}, nil
}
