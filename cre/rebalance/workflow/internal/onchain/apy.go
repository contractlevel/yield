package onchain

import (
	"math/big"
	"math"
	"fmt"

	"rebalance/workflow/internal/aaveV3"
	"rebalance/workflow/internal/compoundV3"
	"rebalance/workflow/internal/helper"

	"github.com/smartcontractkit/cre-sdk-go/cre"
)

/*//////////////////////////////////////////////////////////////
                     DEPENDENCY INJECTIONS
//////////////////////////////////////////////////////////////*/

// Synchronous APY deps used by CalculateAPYForStrategy.
type apyDeps struct {
	AaveV3GetAPY     func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error)
	CompoundV3GetAPY func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error)
}

var defaultAPYDeps = apyDeps{
	AaveV3GetAPY:     aaveV3.GetAPY,
	CompoundV3GetAPY: compoundV3.GetAPY,
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