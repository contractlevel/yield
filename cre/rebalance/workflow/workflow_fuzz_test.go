package main

import (
	"log/slog"
	"math/big"
	"testing"

	"rebalance/workflow/internal/helper"
	"rebalance/workflow/internal/onchain"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"
)

/*//////////////////////////////////////////////////////////////
                        SETUP / UTILITY
//////////////////////////////////////////////////////////////*/

const (
	parentChainSelector = 1
	childChainSelector  = 2
	parentGasLimit      = 500_000
	childGasLimit       = 777_000
	parentYieldAddr     = "0xparent"
	parentRebalancer    = "0xrebalancer-parent"
	childYieldAddr      = "0xchild"
)

// @review should this move to the helper package?
func newTestConfig() *helper.Config {
	return &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:         "parent-chain",
				ChainSelector:     parentChainSelector,
				YieldPeerAddress:  parentYieldAddr,
				RebalancerAddress: parentRebalancer,
				GasLimit:          parentGasLimit,
			},
			{
				ChainName:        "child-chain",
				ChainSelector:    childChainSelector,
				YieldPeerAddress: childYieldAddr,
				GasLimit:         childGasLimit,
			},
		},
	}
}

func newStrategy(id byte, chainSelector uint64) onchain.Strategy {
	return onchain.Strategy{
		ProtocolId:    [32]byte{id},
		ChainSelector: chainSelector,
	}
}

func noopInitSupportedStrategies(*helper.Config) error {
	return nil
}

/*//////////////////////////////////////////////////////////////
                           FUZZ TESTS
//////////////////////////////////////////////////////////////*/

// Fuzz_onCronTriggerWithDeps_RebalanceThresholdAndGasLimit fuzzes the APY delta and
// whether the current strategy is on the parent or child chain. It verifies:
//   - WriteRebalance is called iff delta >= threshold.
//   - StrategyResult.Updated == (delta >= threshold).
//   - gasLimit passed to WriteRebalance matches the gasLimit of the correct EVM config:
//       * parent gasLimit when currentStrategy.ChainSelector == parentCfg.ChainSelector
//       * child gasLimit otherwise.
func Fuzz_onCronTriggerWithDeps_RebalanceThresholdAndGasLimit(f *testing.F) {
	// Seed a few interesting edge/near-edge cases.
	f.Add(-1.0, true)  // below threshold, same chain
	f.Add(0.0, true)   // below threshold, same chain
	f.Add(1.0, true)   // above threshold, same chain
	f.Add(-1.0, false) // below threshold, different chain
	f.Add(0.0, false)  // below threshold, different chain
	f.Add(1.0, false)  // above threshold, different chain

	f.Fuzz(func(t *testing.T, delta float64, sameChain bool) {
		t.Helper()

		// Model: currentAPY = 0, optimalAPY = delta.
		currentAPY := 0.0
		optimalAPY := currentAPY + delta

		runtime := testutils.NewRuntime(t, nil)

		cfg := newTestConfig()
		parentCfg := cfg.Evms[0]
		childCfg := cfg.Evms[1]

		// Decide which chain the current strategy is on.
		curChainSelector := parentCfg.ChainSelector
		if !sameChain {
			curChainSelector = childCfg.ChainSelector
		}

		currentStrategy := newStrategy(1, curChainSelector)
		optimalStrategy := newStrategy(2, parentCfg.ChainSelector)

		var (
			writeCalled bool
			gotGasLimit uint64
		)

		deps := OnCronDeps{
			NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
				return nil, nil
			},
			NewChildPeerBinding: func(_ *evm.Client, _ string) (onchain.YieldPeerInterface, error) {
				return nil, nil
			},
			NewRebalancerBinding: func(_ *evm.Client, _ string) (onchain.RebalancerInterface, error) {
				return nil, nil
			},
			ReadCurrentStrategy: func(_ *helper.Config, _ cre.Runtime, _ onchain.ParentPeerInterface) (onchain.Strategy, error) {
				return currentStrategy, nil
			},
			ReadTVL: func(_ *helper.Config, _ cre.Runtime, _ onchain.YieldPeerInterface) (*big.Int, error) {
				// TVL doesn't affect the rebalance decision in this model.
				return big.NewInt(1_000), nil
			},
			WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, gasLimit uint64, optimal onchain.Strategy) error {
				writeCalled = true
				gotGasLimit = gasLimit
				require.Equal(t, optimalStrategy, optimal, "WriteRebalance optimal mismatch")
				return nil
			},
			GetOptimalAndCurrentStrategyWithAPY: func(_ *helper.Config, _ cre.Runtime, cur onchain.Strategy, tvl *big.Int) (onchain.StrategyWithAPY, onchain.StrategyWithAPY, error) {
				require.Equal(t, currentStrategy, cur, "current strategy passed to GetOptimalAndCurrentStrategyWithAPY mismatch")
				require.NotNil(t, tvl, "tvl should not be nil")
				return onchain.StrategyWithAPY{
						Strategy: optimalStrategy,
						APY:      optimalAPY,
					}, onchain.StrategyWithAPY{
						Strategy: currentStrategy,
						APY:      currentAPY,
					}, nil
			},
			InitSupportedStrategies: noopInitSupportedStrategies,
		}

		res, err := onCronTriggerWithDeps(cfg, runtime, nil, deps)
		require.NoError(t, err, "unexpected error from onCronTriggerWithDeps")
		require.NotNil(t, res, "expected non-nil result")

		shouldRebalance := delta >= threshold

		if shouldRebalance {
			require.True(t, writeCalled,
				"expected WriteRebalance to be called when delta >= threshold (delta=%f, threshold=%f)", delta, threshold)
			require.True(t, res.Updated, "expected result.Updated=true when delta >= threshold")

			expectedGas := parentCfg.GasLimit
			if !sameChain {
				expectedGas = childCfg.GasLimit
			}
			require.Equal(t, expectedGas, gotGasLimit,
				"unexpected gasLimit passed to WriteRebalance (sameChain=%v)", sameChain)
		} else {
			require.False(t, writeCalled,
				"expected WriteRebalance NOT to be called when delta < threshold (delta=%f, threshold=%f)", delta, threshold)
			require.False(t, res.Updated,
				"expected result.Updated=false when delta < threshold")
		}
	})
}

// Fuzz_onCronTriggerWithDeps_StrategyEqualityNoRebalance fuzzes whether the
// current and optimal strategies are equal, and asserts that when they are
// equal the workflow does not rebalance, even if the APY delta is large.
func Fuzz_onCronTriggerWithDeps_StrategyEqualityNoRebalance(f *testing.F) {
	f.Add(true)
	f.Add(false)

	f.Fuzz(func(t *testing.T, equal bool) {
		t.Helper()

		runtime := testutils.NewRuntime(t, nil)

		cfg := newTestConfig()
		parentCfg := cfg.Evms[0]

		currentStrategy := newStrategy(1, parentCfg.ChainSelector)
		optimalStrategy := currentStrategy
		if !equal {
			optimalStrategy = newStrategy(2, parentCfg.ChainSelector)
		}

		// Force a large positive delta so that, absent equality short-circuiting,
		// a rebalance would occur.
		currentAPY := 0.0
		optimalAPY := threshold + 1.0

		var writeCalled bool

		deps := OnCronDeps{
			NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
				return nil, nil
			},
			NewChildPeerBinding: func(_ *evm.Client, _ string) (onchain.YieldPeerInterface, error) {
				// Everything is on the parent chain in this test.
				t.Fatalf("NewChildPeerBinding should not be called in this fuzz test")
				return nil, nil
			},
			NewRebalancerBinding: func(_ *evm.Client, _ string) (onchain.RebalancerInterface, error) {
				return nil, nil
			},
			ReadCurrentStrategy: func(_ *helper.Config, _ cre.Runtime, _ onchain.ParentPeerInterface) (onchain.Strategy, error) {
				return currentStrategy, nil
			},
			ReadTVL: func(_ *helper.Config, _ cre.Runtime, _ onchain.YieldPeerInterface) (*big.Int, error) {
				return big.NewInt(1_000), nil
			},
			WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
				writeCalled = true
				if equal {
					t.Fatalf("WriteRebalance should not be called when strategies are equal")
				}
				return nil
			},
			GetOptimalAndCurrentStrategyWithAPY: func(_ *helper.Config, _ cre.Runtime, cur onchain.Strategy, tvl *big.Int) (onchain.StrategyWithAPY, onchain.StrategyWithAPY, error) {
				require.Equal(t, currentStrategy, cur)
				require.NotNil(t, tvl)
				return onchain.StrategyWithAPY{
						Strategy: optimalStrategy,
						APY:      optimalAPY,
					}, onchain.StrategyWithAPY{
						Strategy: currentStrategy,
						APY:      currentAPY,
					}, nil
			},
			InitSupportedStrategies: noopInitSupportedStrategies,
		}

		res, err := onCronTriggerWithDeps(cfg, runtime, nil, deps)
		require.NoError(t, err, "unexpected error from onCronTriggerWithDeps")
		require.NotNil(t, res, "expected non-nil result")

		if equal {
			require.False(t, res.Updated, "expected Updated=false when strategies are equal")
			require.Equal(t, currentStrategy, res.Current)
			require.Equal(t, optimalStrategy, res.Optimal)
			require.False(t, writeCalled, "WriteRebalance should not be called when strategies are equal")
		} else {
			require.True(t, res.Updated, "expected Updated=true when strategies differ and delta >= threshold")
			require.True(t, writeCalled, "expected WriteRebalance to be called when strategies differ and delta >= threshold")
		}
	})
}

// Fuzz_onCronTriggerWithDeps_ChildPeerBindingUsage fuzzes whether the current
// strategy is on the parent or child chain, and asserts that:
//   - NewChildPeerBinding is only called when the current strategy is NOT on the parent chain.
//   - ReadTVL is always called exactly once.
//   - No rebalance occurs when delta < threshold.
func Fuzz_onCronTriggerWithDeps_ChildPeerBindingUsage(f *testing.F) {
	f.Add(true)  // current strategy on parent chain
	f.Add(false) // current strategy on child chain

	f.Fuzz(func(t *testing.T, sameChain bool) {
		t.Helper()

		runtime := testutils.NewRuntime(t, nil)

		cfg := newTestConfig()
		parentCfg := cfg.Evms[0]
		childCfg := cfg.Evms[1]

		curChainSelector := parentCfg.ChainSelector
		if !sameChain {
			curChainSelector = childCfg.ChainSelector
		}

		currentStrategy := newStrategy(1, curChainSelector)
		optimalStrategy := newStrategy(2, parentCfg.ChainSelector)

		var (
			childBindCalls int
			readTVLCalls   int
			writeCalled    bool
		)

		deps := OnCronDeps{
			NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
				return nil, nil
			},
			NewChildPeerBinding: func(_ *evm.Client, _ string) (onchain.YieldPeerInterface, error) {
				childBindCalls++
				return nil, nil
			},
			NewRebalancerBinding: func(_ *evm.Client, _ string) (onchain.RebalancerInterface, error) {
				return nil, nil
			},
			ReadCurrentStrategy: func(_ *helper.Config, _ cre.Runtime, _ onchain.ParentPeerInterface) (onchain.Strategy, error) {
				return currentStrategy, nil
			},
			ReadTVL: func(_ *helper.Config, _ cre.Runtime, _ onchain.YieldPeerInterface) (*big.Int, error) {
				readTVLCalls++
				return big.NewInt(1_000), nil
			},
			WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
				writeCalled = true
				return nil
			},
			GetOptimalAndCurrentStrategyWithAPY: func(_ *helper.Config, _ cre.Runtime, cur onchain.Strategy, tvl *big.Int) (onchain.StrategyWithAPY, onchain.StrategyWithAPY, error) {
				require.Equal(t, currentStrategy, cur)
				require.NotNil(t, tvl)
				// Keep delta < threshold so rebalance never happens.
				return onchain.StrategyWithAPY{
						Strategy: optimalStrategy,
						APY:      0.0,
					}, onchain.StrategyWithAPY{
						Strategy: currentStrategy,
						APY:      0.0,
					}, nil
			},
			InitSupportedStrategies: noopInitSupportedStrategies,
		}

		res, err := onCronTriggerWithDeps(cfg, runtime, nil, deps)
		require.NoError(t, err, "unexpected error from onCronTriggerWithDeps")
		require.NotNil(t, res, "expected non-nil result")

		require.False(t, res.Updated, "expected Updated=false when delta < threshold")
		require.Equal(t, 1, readTVLCalls, "expected ReadTVL to be called exactly once")
		require.False(t, writeCalled, "WriteRebalance should not be called when delta < threshold")

		if sameChain {
			require.Equal(t, 0, childBindCalls,
				"expected NewChildPeerBinding not to be called when strategy is on parent chain")
		} else {
			require.Equal(t, 1, childBindCalls,
				"expected NewChildPeerBinding to be called once when strategy is on child chain")
		}
	})
}

// Fuzz_onCronTriggerWithDeps_TVLWiring fuzzes TVL and chain placement and asserts that:
//   - GetOptimalAndCurrentStrategyWithAPY receives the same TVL that ReadTVL returns.
//   - GetOptimalAndCurrentStrategyWithAPY receives the same current strategy that
//     was read from ParentPeer.
func Fuzz_onCronTriggerWithDeps_TVLWiring(f *testing.F) {
	f.Add(int64(0), true)
	f.Add(int64(1_000), true)
	f.Add(int64(1_000), false)

	f.Fuzz(func(t *testing.T, tvlRaw int64, sameChain bool) {
		t.Helper()

		// Ensure non-negative TVL for sanity.
		if tvlRaw < 0 {
			tvlRaw = -tvlRaw
		}

		runtime := testutils.NewRuntime(t, nil)

		cfg := newTestConfig()
		parentCfg := cfg.Evms[0]
		childCfg := cfg.Evms[1]

		tvl := big.NewInt(tvlRaw)

		curChainSelector := parentCfg.ChainSelector
		if !sameChain {
			curChainSelector = childCfg.ChainSelector
		}

		currentStrategy := newStrategy(1, curChainSelector)
		optimalStrategy := newStrategy(2, parentCfg.ChainSelector)

		var (
			gotCurrent  onchain.Strategy
			gotLiquidity *big.Int
			writeCalled bool
		)

		deps := OnCronDeps{
			NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
				return nil, nil
			},
			NewChildPeerBinding: func(_ *evm.Client, _ string) (onchain.YieldPeerInterface, error) {
				return nil, nil
			},
			NewRebalancerBinding: func(_ *evm.Client, _ string) (onchain.RebalancerInterface, error) {
				// We keep delta=0 so no rebalance.
				t.Fatalf("NewRebalancerBinding should not be called in TVL wiring fuzz")
				return nil, nil
			},
			ReadCurrentStrategy: func(_ *helper.Config, _ cre.Runtime, _ onchain.ParentPeerInterface) (onchain.Strategy, error) {
				return currentStrategy, nil
			},
			ReadTVL: func(_ *helper.Config, _ cre.Runtime, _ onchain.YieldPeerInterface) (*big.Int, error) {
				// Return a copy so mutations won't affect our tvl variable.
				return new(big.Int).Set(tvl), nil
			},
			WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
				writeCalled = true
				return nil
			},
			GetOptimalAndCurrentStrategyWithAPY: func(_ *helper.Config, _ cre.Runtime, cur onchain.Strategy, liquidityAdded *big.Int) (onchain.StrategyWithAPY, onchain.StrategyWithAPY, error) {
				require.Nil(t, gotLiquidity, "GetOptimalAndCurrentStrategyWithAPY should be called exactly once")
				gotCurrent = cur
				if liquidityAdded != nil {
					gotLiquidity = new(big.Int).Set(liquidityAdded)
				}
				// APY values themselves don't matter here, only liquidityAdded and current strategy.
				return onchain.StrategyWithAPY{
						Strategy: optimalStrategy,
						APY:      0.0,
					}, onchain.StrategyWithAPY{
						Strategy: currentStrategy,
						APY:      0.0,
					}, nil
			},
			InitSupportedStrategies: noopInitSupportedStrategies,
		}

		res, err := onCronTriggerWithDeps(cfg, runtime, nil, deps)
		require.NoError(t, err, "unexpected error from onCronTriggerWithDeps")
		require.NotNil(t, res, "expected non-nil result")

		require.False(t, res.Updated, "expected Updated=false when delta == 0")
		require.False(t, writeCalled, "WriteRebalance should not be called when delta == 0")

		require.Equal(t, currentStrategy, gotCurrent,
			"expected current strategy to be passed through to GetOptimalAndCurrentStrategyWithAPY")

		require.NotNil(t, gotLiquidity, "expected non-nil liquidityAdded argument")
		require.Equal(t, 0, gotLiquidity.Cmp(tvl),
			"expected liquidityAdded == TVL; got %s, want %s",
			gotLiquidity.String(), tvl.String())
	})
}

// Fuzz_onCronTriggerWithDeps_DeltaTranslationInvariance fuzzes base APY, delta,
// and shift, and asserts that adding the same shift to both APYs does not change
// the rebalance decision (Updated flag and whether WriteRebalance is called).
func Fuzz_onCronTriggerWithDeps_DeltaTranslationInvariance(f *testing.F) {
	f.Add(int64(0), int64(0), int64(0))
	f.Add(int64(10), int64(5), int64(100))
	f.Add(int64(-10), int64(20), int64(-50))

	f.Fuzz(func(t *testing.T, baseRaw int64, deltaRaw int64, shiftRaw int64) {
		t.Helper()

		type decision struct {
			updated bool
			wrote   bool
		}

		// Scale inputs to keep APYs in a reasonable range.
		baseF := float64(baseRaw) / 10.0
		deltaF := float64(deltaRaw) / 10.0
		shiftF := float64(shiftRaw) / 10.0

		runOnce := func(shift float64) decision {
			runtime := testutils.NewRuntime(t, nil)

			cfg := newTestConfig()
			parentCfg := cfg.Evms[0]

			currentStrategy := newStrategy(1, parentCfg.ChainSelector)
			optimalStrategy := newStrategy(2, parentCfg.ChainSelector)

			currentAPY := baseF + shift
			optimalAPY := currentAPY + deltaF

			var (
				writeCalled bool
				updated     bool
			)

			deps := OnCronDeps{
				NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
					return nil, nil
				},
				NewChildPeerBinding: func(_ *evm.Client, _ string) (onchain.YieldPeerInterface, error) {
					t.Fatalf("NewChildPeerBinding should not be called in translation test")
					return nil, nil
				},
				NewRebalancerBinding: func(_ *evm.Client, _ string) (onchain.RebalancerInterface, error) {
					return nil, nil
				},
				ReadCurrentStrategy: func(_ *helper.Config, _ cre.Runtime, _ onchain.ParentPeerInterface) (onchain.Strategy, error) {
					return currentStrategy, nil
				},
				ReadTVL: func(_ *helper.Config, _ cre.Runtime, _ onchain.YieldPeerInterface) (*big.Int, error) {
					// TVL is irrelevant for the APY model here.
					return big.NewInt(1_000), nil
				},
				WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
					writeCalled = true
					return nil
				},
				GetOptimalAndCurrentStrategyWithAPY: func(_ *helper.Config, _ cre.Runtime, cur onchain.Strategy, tvl *big.Int) (onchain.StrategyWithAPY, onchain.StrategyWithAPY, error) {
					require.Equal(t, currentStrategy, cur)
					require.NotNil(t, tvl)
					return onchain.StrategyWithAPY{
							Strategy: optimalStrategy,
							APY:      optimalAPY,
						}, onchain.StrategyWithAPY{
							Strategy: currentStrategy,
							APY:      currentAPY,
						}, nil
				},
				InitSupportedStrategies: noopInitSupportedStrategies,
			}

			res, err := onCronTriggerWithDeps(cfg, runtime, nil, deps)
			require.NoError(t, err, "unexpected error from onCronTriggerWithDeps")
			require.NotNil(t, res, "expected non-nil result")

			updated = res.Updated

			return decision{
				updated: updated,
				wrote:   writeCalled,
			}
		}

		// Run once without shift and once with shift.
		dec1 := runOnce(0)
		dec2 := runOnce(shiftF)

		// Property: rebalance decision depends only on delta, not on absolute APY levels.
		require.Equal(t, dec1.updated, dec2.updated,
			"Updated mismatch between runs with same delta: run1=%v run2=%v", dec1.updated, dec2.updated)
		require.Equal(t, dec1.wrote, dec2.wrote,
			"WriteRebalance mismatch between runs with same delta: run1=%v run2=%v", dec1.wrote, dec2.wrote)
	})
}
