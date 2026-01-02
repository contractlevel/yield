package onchain

import (
	"fmt"
	"math/big"

	"cre-rebalance/cre-rebalance-workflow/internal/aaveV3"
	"cre-rebalance/cre-rebalance-workflow/internal/compoundV3"
)

func GetOptimalStrategy(currentStrategy Strategy, liquidityAdded *big.Int) (Strategy, error) {
	if len(SupportedStrategies) == 0 {
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

	for _, cand := range SupportedStrategies {
		// For the current strategy, we want the APY “as is”, so liquidityAdded = 0.
		liq := liquidityAdded
		if sameStrategy(cand, currentStrategy) {
			liq = big.NewInt(0)
		}

		apy, err := CalculateAPYForStrategy(cand, liq)
		if err != nil {
			return Strategy{}, fmt.Errorf("calculate APY for strategy %+v: %w", cand, err)
		}
		if apy == nil {
			return Strategy{}, fmt.Errorf("nil APY returned for strategy %+v", cand)
		}

		if !bestSet || apy.Cmp(bestAPY) > 0 {
			bestAPY = new(big.Int).Set(apy)
			bestStrategy = cand
			bestSet = true
		}
	}

	if !bestSet {
		return Strategy{}, fmt.Errorf("no valid APY found among supported strategies")
	}

	return bestStrategy, nil
}

func CalculateAPYForStrategy(strategy Strategy, liquidityAdded *big.Int) (*big.Int, error) {
	switch strategy.ProtocolId {
		case AaveV3ProtocolId:
			return aaveV3.GetAPY(strategy.ChainSelector, liquidityAdded)

		case CompoundV3ProtocolId:
			return compoundV3.GetAPY(strategy.ChainSelector, liquidityAdded)

		default:
			return nil, fmt.Errorf("unsupported protocolId: %d", strategy.ProtocolId)
	}
}

func sameStrategy(a, b Strategy) bool {
	return a.ProtocolId == b.ProtocolId &&
		a.ChainSelector == b.ChainSelector
}
