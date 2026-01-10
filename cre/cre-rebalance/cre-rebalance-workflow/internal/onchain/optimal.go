package onchain

import (
	"fmt"
	"math"
	"math/big"

	"cre-rebalance/cre-rebalance-workflow/internal/aaveV3"
	"cre-rebalance/cre-rebalance-workflow/internal/compoundV3"
	"cre-rebalance/cre-rebalance-workflow/internal/helper"

	"github.com/smartcontractkit/cre-sdk-go/cre"
)

/*//////////////////////////////////////////////////////////////
                     DEPENDENCY INJECTIONS
//////////////////////////////////////////////////////////////*/

// Synchronous APY deps used by CalculateAPYForStrategy and
// any other sequential callers.
type apyDeps struct {
	AaveV3GetAPY     func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error)
	CompoundV3GetAPY func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error)
}

var defaultAPYDeps = apyDeps{
	AaveV3GetAPY:     aaveV3.GetAPY,
	CompoundV3GetAPY: compoundV3.GetAPY,
}

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
        s := strategy // capture

        liq := liquidityAdded
        if sameStrategy(s, currentStrategy) {
            liq = big.NewInt(0)
        }

		// @review moving this switch to a dedicated function
        var apyPromise cre.Promise[float64]
        switch s.ProtocolId {
        case AaveV3ProtocolId:
            apyPromise = deps.AaveV3GetAPYPromise(config, runtime, liq, s.ChainSelector)
        case CompoundV3ProtocolId:
            apyPromise = deps.CompoundV3GetAPYPromise(config, runtime, liq, s.ChainSelector)
        default:
            return Strategy{}, fmt.Errorf("unsupported protocolId: %x", s.ProtocolId)
        }

        strategies = append(strategies, s)
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

/*//////////////////////////////////////////////////////////////
                   CALCULATE APY FOR STRATEGY
//////////////////////////////////////////////////////////////*/

func CalculateAPYForStrategy(
	config *helper.Config,
	runtime cre.Runtime,
	strategy Strategy,
	liquidityAdded *big.Int,
) (float64, error) {
	return calculateAPYForStrategyWithDeps(config, runtime, strategy, liquidityAdded, defaultAPYDeps)
}

// @review scaling for different strategy package GetAPY return values needs to be consistent!
// ie is the aaveV3 value scaled to RAY when compoundV3 scales to WAD?
func calculateAPYForStrategyWithDeps(
	config *helper.Config,
	runtime cre.Runtime,
	strategy Strategy,
	liquidityAdded *big.Int,
	deps apyDeps,
) (float64, error) {
	var (
		apy float64
		err error
	)

	switch strategy.ProtocolId {
	case AaveV3ProtocolId:
		apy, err = deps.AaveV3GetAPY(config, runtime, liquidityAdded, strategy.ChainSelector)
		if err != nil {
			return 0, fmt.Errorf("getting APY from AaveV3: %w", err)
		}
	case CompoundV3ProtocolId:
		apy, err = deps.CompoundV3GetAPY(config, runtime, liquidityAdded, strategy.ChainSelector)
		if err != nil {
			return 0, fmt.Errorf("getting APY from CompoundV3: %w", err)
		}
	default:
		return 0, fmt.Errorf("unsupported protocolId: %x", strategy.ProtocolId)
	}

	// Guard against invalid float64 results.
	if math.IsNaN(apy) || math.IsInf(apy, 0) {
		return 0, fmt.Errorf("invalid APY value (NaN/Inf) for protocolId %x: %v", strategy.ProtocolId, apy)
	}

	return apy, nil
}

/*//////////////////////////////////////////////////////////////
                            UTILITY
//////////////////////////////////////////////////////////////*/

func sameStrategy(a, b Strategy) bool {
	return a.ProtocolId == b.ProtocolId &&
		a.ChainSelector == b.ChainSelector
}
