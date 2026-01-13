package onchain

import (
	"fmt"
	"math"
	"math/big"

	"rebalance/workflow/internal/aaveV3"
	"rebalance/workflow/internal/compoundV3"
	"rebalance/workflow/internal/helper"

	"github.com/smartcontractkit/cre-sdk-go/cre"
)

/*//////////////////////////////////////////////////////////////
                     DEPENDENCY INJECTIONS
//////////////////////////////////////////////////////////////*/

// Promise-based APY deps used by GetOptimalStrategy to evaluate
// all candidate strategies in parallel.
type apyPromiseDeps struct {
	AaveV3GetAPYPromise     func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64]
	CompoundV3GetAPYPromise func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64]
}

var defaultAPYPromiseDeps = apyPromiseDeps{
	AaveV3GetAPYPromise:     aaveV3.GetAPYPromise,
	CompoundV3GetAPYPromise: compoundV3.GetAPYPromise,
}

/*//////////////////////////////////////////////////////////////
                     GET OPTIMAL STRATEGY
//////////////////////////////////////////////////////////////*/

// GetOptimalStrategy evaluates all supported strategies in parallel using
// promise-based APY calculations and returns the strategy with the highest APY.
//
// It uses the promise-based deps, but the rest of the codebase can continue
// to use the synchronous CalculateAPYForStrategy.
func GetOptimalStrategy(
	config *helper.Config,
	runtime cre.Runtime,
	currentStrategy Strategy,
	liquidityAdded *big.Int,
) (Strategy, error) {
	return getOptimalStrategyWithDeps(config, runtime, currentStrategy, liquidityAdded, defaultAPYPromiseDeps)
}

// getOptimalStrategyWithDeps starts APY calculations for all supported
// strategies in parallel using promises, then awaits and selects the best.
//
// Error policy: if any strategy’s APY calculation fails or returns an invalid
// APY, the whole function returns an error.
func getOptimalStrategyWithDeps(
    config *helper.Config,
    runtime cre.Runtime,
    currentStrategy Strategy,
    liquidityAdded *big.Int,
    deps apyPromiseDeps,
) (Strategy, error) {
    initSupportedStrategies(config)

    if len(supportedStrategies) == 0 {
        return Strategy{}, fmt.Errorf("no supported strategies configured")
    }
    if liquidityAdded == nil {
        return Strategy{}, fmt.Errorf("liquidityAdded must not be nil")
    }

    // We keep strategies and promises aligned by index.
    strategies := make([]Strategy, 0, len(supportedStrategies))
    apyPromises := make([]cre.Promise[float64], 0, len(supportedStrategies))

    // First pass: kick off all APY computations (no Await yet).
    for _, strategy := range supportedStrategies {
        liq := liquidityAdded
        if sameStrategy(strategy, currentStrategy) {
            liq = big.NewInt(0)
        }

	    apyPromise:= getAPYPromiseFromStrategy(config, runtime, strategy, liq, deps)

        strategies = append(strategies, strategy)
        apyPromises = append(apyPromises, apyPromise)
    }

    var (
        bestStrategy Strategy
        bestAPY      float64
        bestSet      bool
    )

    // Second pass: Await each APY and pick the best.
    for i, apyPromise := range apyPromises {
		strategy := strategies[i]

        apy, err := apyPromise.Await()
        if err != nil {
            return Strategy{}, fmt.Errorf("calculate APY for strategy %+v: %w", strategy, err)
        }

        if apy == 0 {
            return Strategy{}, fmt.Errorf("0 APY returned for strategy %+v", strategy)
        }
        if math.IsNaN(apy) || math.IsInf(apy, 0) {
            return Strategy{}, fmt.Errorf("invalid APY value (NaN/Inf) for protocolId %x: %v",
			strategy.ProtocolId, apy)
        }

        if !bestSet || apy > bestAPY {
            bestAPY = apy
            bestStrategy = strategy
            bestSet = true
        }
    }

    return bestStrategy, nil
}

func getAPYPromiseFromStrategy(
	config *helper.Config,
	runtime cre.Runtime,
	strategy Strategy,
	liquidity *big.Int,
	deps apyPromiseDeps,
) cre.Promise[float64] {
	switch strategy.ProtocolId {
	case AaveV3ProtocolId:
		return deps.AaveV3GetAPYPromise(config, runtime, liquidity, strategy.ChainSelector)

	case CompoundV3ProtocolId:
		return deps.CompoundV3GetAPYPromise(config, runtime, liquidity, strategy.ChainSelector)

	default:
		return cre.PromiseFromResult(0.0, fmt.Errorf("unsupported protocolId: %x", strategy.ProtocolId))
	}
}
