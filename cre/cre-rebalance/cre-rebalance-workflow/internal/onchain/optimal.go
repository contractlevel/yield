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

type apyDeps struct {
	AaveV3GetAPY     func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error)
	CompoundV3GetAPY func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error)
}

var defaultAPYDeps = apyDeps{
	AaveV3GetAPY:     aaveV3.GetAPY,
	CompoundV3GetAPY: compoundV3.GetAPY,
}

/*//////////////////////////////////////////////////////////////
                     GET OPTIMAL STRATEGY
//////////////////////////////////////////////////////////////*/

func GetOptimalStrategy(
	config *helper.Config,
	runtime cre.Runtime,
	currentStrategy Strategy,
	liquidityAdded *big.Int,
) (Strategy, error) {
	return getOptimalStrategyWithDeps(config, runtime, currentStrategy, liquidityAdded, defaultAPYDeps)
}

func getOptimalStrategyWithDeps(
	config *helper.Config,
	runtime cre.Runtime,
	currentStrategy Strategy,
	liquidityAdded *big.Int,
	deps apyDeps,
) (Strategy, error) {
	initSupportedStrategies(config)

	if len(supportedStrategies) == 0 {
		return Strategy{}, fmt.Errorf("no supported strategies configured")
	}
	// nil is not the same as big.NewInt(0)
	if liquidityAdded == nil {
		return Strategy{}, fmt.Errorf("liquidityAdded must not be nil")
	}

	var (
		bestStrategy Strategy
		bestAPY      float64
		bestSet      bool
	)

	for _, strategy := range supportedStrategies {
		// For the current strategy, we want the APY “as is”, so liquidityAdded = 0.
		liq := liquidityAdded
		if sameStrategy(strategy, currentStrategy) {
			liq = big.NewInt(0)
		}

		apy, err := calculateAPYForStrategyWithDeps(config, runtime, strategy, liq, deps)
		if err != nil {
			return Strategy{}, fmt.Errorf("calculate APY for strategy %+v: %w", strategy, err)
		}
		if apy == 0 {
			return Strategy{}, fmt.Errorf("0 APY returned for strategy %+v", strategy)
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

// @review this should return float64 from both GetAPY()
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