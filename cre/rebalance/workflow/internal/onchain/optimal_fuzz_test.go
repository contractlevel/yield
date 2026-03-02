package onchain

import (
	"math"
	"math/big"
	"testing"

	"rebalance/workflow/internal/helper"

	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"
)

/*//////////////////////////////////////////////////////////////
                 FUZZ: CHOOSES HIGHEST APY
//////////////////////////////////////////////////////////////*/

// Property:
// Given strictly positive, finite APYs for all strategies, the function must:
//   - Return an optimal strategy whose APY equals the global maximum APY.
//   - That optimal strategy must be one of the strategies that have that
//     maximum APY (ties are allowed).
//   - Return as current the APY corresponding to the current strategy.
//
// Setup: 2 chains, Aave+Compound each => 4 strategies total.
func Fuzz_getOptimalAndCurrentStrategyWithAPYWithDeps_selectsHighestAPY(f *testing.F) {
	// Seed corpus for quick regression and to ensure some basic cases
	f.Add(0.01, 0.02, 0.03, 0.04) // increasing APYs
	f.Add(0.10, 0.05, 0.07, 0.02) // best one is Aave chain 1
	f.Add(0.05, 0.08, 0.07, 0.06) // best one is Compound chain 1
	f.Add(0.05, 0.05, 0.05, 0.05) // all equal (ties)

	f.Fuzz(func(t *testing.T, aave1, comp1, aave2, comp2 float64) {
		// Only test the property when all APYs are strictly positive and finite.
		apys := []float64{aave1, comp1, aave2, comp2}
		for _, apy := range apys {
			if apy <= 0 || math.IsNaN(apy) || math.IsInf(apy, 0) {
				t.Skip()
			}
		}

		// Compute the global maximum APY for this fuzz input.
		bestAPY := apys[0]
		for _, apy := range apys[1:] {
			if apy > bestAPY {
				bestAPY = apy
			}
		}

		cfg := setupConfigWithStrategies(t, 1, 2)
		runtime := testutils.NewRuntime(t, nil)
		liquidityAdded := big.NewInt(1_000)

		currentStrategy := Strategy{
			ProtocolId:    AaveV3ProtocolId,
			ChainSelector: 1,
		}

		// Map (protocol, chain) -> APY
		apyMap := map[Strategy]float64{
			{ProtocolId: AaveV3ProtocolId, ChainSelector: 1}:       aave1,
			{ProtocolId: CompoundV3ProtocolId, ChainSelector: 1}:   comp1,
			{ProtocolId: AaveV3ProtocolId, ChainSelector: 2}:       aave2,
			{ProtocolId: CompoundV3ProtocolId, ChainSelector: 2}:   comp2,
		}

		deps := apyPromiseDeps{
			AaveV3GetAPYPromise: func(_ *helper.Config, _ cre.Runtime, _ *big.Int, chain uint64) cre.Promise[float64] {
				str := Strategy{ProtocolId: AaveV3ProtocolId, ChainSelector: chain}
				apy, ok := apyMap[str]
				require.True(t, ok, "missing APY for Aave strategy: %+v", str)
				return cre.PromiseFromResult(apy, nil)
			},
			CompoundV3GetAPYPromise: func(_ *helper.Config, _ cre.Runtime, _ *big.Int, chain uint64) cre.Promise[float64] {
				str := Strategy{ProtocolId: CompoundV3ProtocolId, ChainSelector: chain}
				apy, ok := apyMap[str]
				require.True(t, ok, "missing APY for Compound strategy: %+v", str)
				return cre.PromiseFromResult(apy, nil)
			},
		}

		optimal, current, err := getOptimalAndCurrentStrategyWithAPYWithDeps(
			cfg,
			runtime,
			currentStrategy,
			liquidityAdded,
			deps,
		)
		require.NoError(t, err)

		// Property 1: optimal APY equals the global maximum APY.
		require.Equal(t, bestAPY, optimal.APY)

		// Property 2: the chosen optimal strategy is one of the strategies
		// that have that maximum APY.
		optKey := Strategy{
			ProtocolId:    optimal.Strategy.ProtocolId,
			ChainSelector: optimal.Strategy.ChainSelector,
		}
		optAPY, ok := apyMap[optKey]
		require.True(t, ok, "optimal strategy not present in APY map")
		require.Equal(t, bestAPY, optAPY)

		// Property 3: current APY matches the APY for the current strategy.
		expectedCurrentAPY, ok := apyMap[currentStrategy]
		require.True(t, ok, "current strategy must be in APY map")
		require.Equal(t, expectedCurrentAPY, current.APY)
		require.Equal(t, currentStrategy, current.Strategy)
	})
}

/*//////////////////////////////////////////////////////////////
        FUZZ: CURRENT STRATEGY USES ZERO LIQUIDITY
//////////////////////////////////////////////////////////////*/

// Property:
// For any positive liquidityAdded, the current strategy must be evaluated with
// zero liquidity, while all non-current strategies must be evaluated with the
// full liquidityAdded.
func Fuzz_getOptimalAndCurrentStrategyWithAPYWithDeps_zeroLiquidityForCurrent(f *testing.F) {
	// Seed corpus with a typical liquidity value.
	f.Add(int64(1_000))

	f.Fuzz(func(t *testing.T, liq int64) {
		if liq <= 0 {
			t.Skip()
		}
		liquidityAdded := big.NewInt(liq)

		cfg := setupConfigWithStrategies(t, 1, 2)
		runtime := testutils.NewRuntime(t, nil)

		currentStrategy := Strategy{
			ProtocolId:    AaveV3ProtocolId,
			ChainSelector: 1,
		}

		var (
			currentLiquidity *big.Int
			otherLiquidities []*big.Int
		)

		deps := apyPromiseDeps{
			AaveV3GetAPYPromise: func(_ *helper.Config, _ cre.Runtime, liqArg *big.Int, chain uint64) cre.Promise[float64] {
				str := Strategy{ProtocolId: AaveV3ProtocolId, ChainSelector: chain}
				if sameStrategy(str, currentStrategy) {
					// Capture liquidity used for the current strategy.
					currentLiquidity = new(big.Int).Set(liqArg)
				} else {
					// Capture liquidity used for non-current strategies.
					otherLiquidities = append(otherLiquidities, new(big.Int).Set(liqArg))
				}
				// Non-zero, finite APY to avoid triggering error paths.
				return cre.PromiseFromResult(0.05, nil)
			},
			CompoundV3GetAPYPromise: func(_ *helper.Config, _ cre.Runtime, liqArg *big.Int, chain uint64) cre.Promise[float64] {
				str := Strategy{ProtocolId: CompoundV3ProtocolId, ChainSelector: chain}
				require.False(t, sameStrategy(str, currentStrategy), "current strategy should not be Compound in this fuzz")
				otherLiquidities = append(otherLiquidities, new(big.Int).Set(liqArg))
				// Non-zero, finite APY to avoid triggering error paths.
				return cre.PromiseFromResult(0.04, nil)
			},
		}

		_, _, err := getOptimalAndCurrentStrategyWithAPYWithDeps(
			cfg,
			runtime,
			currentStrategy,
			liquidityAdded,
			deps,
		)
		require.NoError(t, err)

		// Current strategy must have been evaluated.
		require.NotNil(t, currentLiquidity, "current strategy liquidity should be captured")

		// Property 1: current strategy uses zero liquidity.
		requireBigEqual(t, big.NewInt(0), currentLiquidity)

		// Property 2: all non-current strategies use full liquidityAdded.
		require.NotEmpty(t, otherLiquidities, "there should be at least one non-current strategy")
		for _, got := range otherLiquidities {
			requireBigEqual(t, liquidityAdded, got)
		}
	})
}
