package main

import (
	"fmt"
	"log/slog"
	"math/big"

	"rebalance/workflow/internal/helper"
	"rebalance/workflow/internal/offchain"
	"rebalance/workflow/internal/onchain"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

/*//////////////////////////////////////////////////////////////
                           CONFIG
//////////////////////////////////////////////////////////////*/

// threshold is the minimum APY improvement (in the same units that
// CalculateAPYForStrategy returns, e.g. 0.05 for 5% APY) required
// before we rebalance.
// @review check the units are actually returned as described above.
// @review TODO: set a sensible threshold and determine scaling. 0.01 = 1 percentage point.
const threshold = 0.01

// StrategyResult is primarily for debugging / testing.
type StrategyResult struct {
	Current onchain.Strategy `json:"current"`
	Optimal onchain.Strategy `json:"optimal"`
	Updated bool             `json:"updated"`
}

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
	NewParentPeerBinding    func(client *evm.Client, addr string) (onchain.ParentPeerInterface, error)
	NewChildPeerBinding     func(client *evm.Client, addr string) (onchain.YieldPeerInterface, error)
	NewRebalancerBinding    func(client *evm.Client, addr string) (onchain.RebalancerInterface, error)
	ReadCurrentStrategy     func(peer onchain.ParentPeerInterface, runtime cre.Runtime) (onchain.Strategy, error)
	ReadTVL                 func(peer onchain.YieldPeerInterface, runtime cre.Runtime) (*big.Int, error)
	WriteRebalance          func(rb onchain.RebalancerInterface, runtime cre.Runtime, logger *slog.Logger, gasLimit uint64, optimal onchain.Strategy) error
	GetOptimalStrategy      func(config *helper.Config, runtime cre.Runtime) (onchain.Strategy, error)
	CalculateAPYForStrategy func(config *helper.Config, runtime cre.Runtime, strategy onchain.Strategy, liquidityAdded *big.Int) (float64, error)
}

// defaultOnCronDeps are the real onchain/offchain implementations.
var defaultOnCronDeps = OnCronDeps{
	NewParentPeerBinding:    onchain.NewParentPeerBinding,
	NewChildPeerBinding:     onchain.NewChildPeerBinding,
	NewRebalancerBinding:    onchain.NewRebalancerBinding,
	ReadCurrentStrategy:     onchain.ReadCurrentStrategy,
	ReadTVL:                 onchain.ReadTVL,
	WriteRebalance:          onchain.WriteRebalance,
	GetOptimalStrategy:      offchain.GetOptimalStrategy,
	CalculateAPYForStrategy: onchain.CalculateAPYForStrategy,
}

/*//////////////////////////////////////////////////////////////
                        ON CRON TRIGGER
//////////////////////////////////////////////////////////////*/

func onCronTrigger(config *helper.Config, runtime cre.Runtime, trigger *cron.Payload) (*StrategyResult, error) {
	return onCronTriggerWithDeps(config, runtime, trigger, defaultOnCronDeps)
}

// @review logging or removing trigger
func onCronTriggerWithDeps(config *helper.Config, runtime cre.Runtime, trigger *cron.Payload, deps OnCronDeps) (*StrategyResult, error) {
	logger := runtime.Logger()

	// Ensure we have at least one EVM config and treat evms[0] as the parent chain.
	if len(config.Evms) == 0 {
		return nil, fmt.Errorf("no EVM configs provided")
	}
	parentCfg := config.Evms[0]

	// Create EVM client for parent chain once.
	parentEvmClient := &evm.Client{
		ChainSelector: parentCfg.ChainSelector,
	}

	// Instantiate ParentPeer contract once.
	parentPeer, err := deps.NewParentPeerBinding(parentEvmClient, parentCfg.YieldPeerAddress)
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

	// Get aggregated optimal strategy from offchain.
	optimalStrategy, err := deps.GetOptimalStrategy(config, runtime)
	if err != nil {
		return nil, fmt.Errorf("failed to get optimal strategy: %w", err)
		// @review fallback to onchain.GetOptimalStrategy here instead of erroring?
		// pass onchain.GetOptimalStrategy(currentStrategy) so that it applies 0 liquidityAdded for that one
	}

	// If nothing has changed, we can stop early.
	if currentStrategy == optimalStrategy {
		logger.Info("Strategy unchanged; no rebalance needed")
		return &StrategyResult{
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
		strategyPeer, err = deps.NewChildPeerBinding(strategyEvmClient, strategyChainCfg.YieldPeerAddress)
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
	optimalStrategyAPY, err := deps.CalculateAPYForStrategy(config, runtime, optimalStrategy, tvl)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate optimal strategy APY: %w", err)
	}

	// Calculate the current APY for the current strategy (liquidityAdded = 0).
	currentStrategyAPY, err := deps.CalculateAPYForStrategy(config, runtime, currentStrategy, big.NewInt(0))
	if err != nil {
		return nil, fmt.Errorf("failed to calculate current strategy APY: %w", err)
	}

	// Compute delta := optimal - current as float64.
	delta := optimalStrategyAPY - currentStrategyAPY

	logger.Info(
		"Computed APYs",
		"tvl", tvl.String(),
		"currentAPY", currentStrategyAPY,
		"optimalAPY", optimalStrategyAPY,
		"delta", delta,
		"threshold", threshold,
	)

	// If the delta is below the threshold, return without updating.
	if delta < threshold {
		logger.Info("Delta below threshold; no rebalance needed")
		return &StrategyResult{
			Current: currentStrategy,
			Optimal: optimalStrategy,
			Updated: false,
		}, nil
	}

	// At this point:
	// - optimal APY is strictly better than current
	// - improvement meets or exceeds threshold
	// so we go ahead and rebalance.

	parentRebalancer, err := deps.NewRebalancerBinding(parentEvmClient, parentCfg.RebalancerAddress)
	if err != nil {
		return nil, fmt.Errorf("failed to create parent Rebalancer binding: %w", err)
	}

	if err := deps.WriteRebalance(parentRebalancer, runtime, logger, rebalanceGasLimit, optimalStrategy); err != nil {
		return nil, fmt.Errorf("failed to rebalance: %w", err)
	}

	return &StrategyResult{
		Current: currentStrategy,
		Optimal: optimalStrategy,
		Updated: true,
	}, nil
}