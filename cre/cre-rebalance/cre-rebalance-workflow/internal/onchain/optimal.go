package onchain

import (
	"fmt"
	"math/big"

	"cre-rebalance/cre-rebalance-workflow/internal/aaveV3"
	"cre-rebalance/cre-rebalance-workflow/internal/compoundV3"
	"cre-rebalance/cre-rebalance-workflow/internal/helper"
	
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

func GetOptimalStrategy(config *helper.Config, runtime cre.Runtime, currentStrategy Strategy, liquidityAdded *big.Int) (Strategy, error) {
	initSupportedStrategies(config)

	if len(supportedStrategies) == 0 {
		return Strategy{}, fmt.Errorf("no supported strategies configured")
	}
	if liquidityAdded == nil {
		return Strategy{}, fmt.Errorf("liquidityAdded must not be nil")
	}

	var (
		bestStrategy Strategy
		bestAPY      *big.Int
		bestSet      bool
	)

	for _, strategy := range supportedStrategies {
		// For the current strategy, we want the APY “as is”, so liquidityAdded = 0.
		liq := liquidityAdded
		if sameStrategy(strategy, currentStrategy) {
			liq = big.NewInt(0)
		}

		apy, err := CalculateAPYForStrategy(config, runtime, strategy, liq)
		if err != nil {
			return Strategy{}, fmt.Errorf("calculate APY for strategy %+v: %w", strategy, err)
		}
		if apy == nil {
			return Strategy{}, fmt.Errorf("nil APY returned for strategy %+v", strategy)
		}

		if !bestSet || apy.Cmp(bestAPY) > 0 {
			bestAPY = new(big.Int).Set(apy)
			bestStrategy = strategy
			bestSet = true
		}
	}

	if !bestSet {
		return Strategy{}, fmt.Errorf("no valid APY found among supported strategies")
	}

	return bestStrategy, nil
}

// @review scaling for different strategy package GetAPY return values needs to be consistent!
// ie is the aaveV3 value scaled to RAY when compoundV3 scales to WAD?
func CalculateAPYForStrategy(config *helper.Config, runtime cre.Runtime, strategy Strategy, liquidityAdded *big.Int) (*big.Int, error) {
	switch strategy.ProtocolId {
		case AaveV3ProtocolId:
			return aaveV3.GetAPY(config, runtime, liquidityAdded, strategy.ChainSelector)

		case CompoundV3ProtocolId:
			return compoundV3.GetAPY(config, runtime, liquidityAdded, strategy.ChainSelector)

		default:
			return nil, fmt.Errorf("unsupported protocolId: %d", strategy.ProtocolId)
	}
}

func sameStrategy(a, b Strategy) bool {
	return a.ProtocolId == b.ProtocolId &&
		a.ChainSelector == b.ChainSelector
}
