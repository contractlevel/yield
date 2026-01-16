package main

// import (
// 	"log/slog"
// 	"math/big"
// 	"testing"

// 	"rebalance/workflow/internal/helper"
// 	"rebalance/workflow/internal/onchain"

// 	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
// 	"github.com/smartcontractkit/cre-sdk-go/cre"
// 	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
// 	"github.com/stretchr/testify/require"
// )

// /*//////////////////////////////////////////////////////////////
//                         SETUP / UTILITY
// //////////////////////////////////////////////////////////////*/

// const (
// 	parentChainSelector = 1
// 	childChainSelector  = 2
// 	parentGasLimit      = 500_000
// 	childGasLimit       = 777_000
// 	parentYieldAddr     = "0xparent"
// 	parentRebalancer    = "0xrebalancer-parent"
// 	childYieldAddr      = "0xchild"
// )

// // @review should this move to the helper package?
// func newTestConfig() *helper.Config {
// 	cfg := &helper.Config{
// 		Evms: []helper.EvmConfig{
// 			{
// 				ChainName:         "parent-chain",
// 				ChainSelector:     parentChainSelector,
// 				YieldPeerAddress:  parentYieldAddr,
// 				RebalancerAddress: parentRebalancer,
// 				GasLimit:          parentGasLimit,
// 			},
// 			{
// 				ChainName:        "child-chain",
// 				ChainSelector:    childChainSelector,
// 				YieldPeerAddress: childYieldAddr,
// 				GasLimit:         childGasLimit,
// 			},
// 		},
// 	}
// 	return cfg
// }

// func newStrategy(id byte, chainSelector uint64) onchain.Strategy {
// 	return onchain.Strategy{
// 		ProtocolId:    [32]byte{id},
// 		ChainSelector: chainSelector,
// 	}
// }

// /*//////////////////////////////////////////////////////////////
//                            FUZZ TESTS
// //////////////////////////////////////////////////////////////*/

// // Fuzz_onCronTriggerWithDeps_RebalanceThresholdAndGasLimit fuzzes the APY delta and
// // whether the current strategy is on the parent or child chain. It verifies:
// //   - WriteRebalance is called iff delta >= threshold.
// //   - StrategyResult.Updated == (delta >= threshold).
// //   - gasLimit passed to WriteRebalance matches the gasLimit of the correct EVM config:
// //       * parent gasLimit when currentStrategy.ChainSelector == parentCfg.ChainSelector
// //       * child gasLimit otherwise.
// func Fuzz_onCronTriggerWithDeps_RebalanceThresholdAndGasLimit(f *testing.F) {
// 	// Seed a few interesting edge/near-edge cases.
// 	f.Add(-1.0, true)  // below threshold, same chain
// 	f.Add(0.0, true)   // at threshold boundary, same chain
// 	f.Add(1.0, true)   // above threshold, same chain
// 	f.Add(-1.0, false) // below threshold, different chain
// 	f.Add(0.0, false)  // at threshold boundary, different chain
// 	f.Add(1.0, false)  // above threshold, different chain

// 	f.Fuzz(func(t *testing.T, delta float64, sameChain bool) {
// 		t.Helper()

// 		// Model: currentAPY = 0, optimalAPY = delta.
// 		currentAPY := 0.0
// 		optimalAPY := currentAPY + delta

// 		runtime := testutils.NewRuntime(t, nil)

// 		// Two EVM configs: parent and child.
// 		cfg := newTestConfig()
// 		parentCfg := cfg.Evms[0]
// 		childCfg := cfg.Evms[1]

// 		// Decide which chain the current strategy is on.
// 		curChainSelector := parentCfg.ChainSelector
// 		if !sameChain {
// 			curChainSelector = childCfg.ChainSelector
// 		}

// 		currentStrategy := newStrategy(1, curChainSelector)
// 		optimalStrategy := newStrategy(2, parentCfg.ChainSelector)

// 		var (
// 			writeCalled bool
// 			gotGasLimit uint64
// 		)

// 		deps := OnCronDeps{
// 			NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
// 				return nil, nil
// 			},
// 			NewChildPeerBinding: func(_ *evm.Client, _ string) (onchain.YieldPeerInterface, error) {
// 				return nil, nil
// 			},
// 			NewRebalancerBinding: func(_ *evm.Client, _ string) (onchain.RebalancerInterface, error) {
// 				return nil, nil
// 			},
// 			ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
// 				return currentStrategy, nil
// 			},
// 			ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
// 				// TVL doesn't affect the rebalance decision in workflow.go in this model.
// 				return big.NewInt(1_000), nil
// 			},
// 			WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, gasLimit uint64, optimal onchain.Strategy) error {
// 				writeCalled = true
// 				gotGasLimit = gasLimit
// 				require.Equal(t, optimalStrategy, optimal, "WriteRebalance optimal mismatch")
// 				return nil
// 			},
// 			GetOptimalStrategy: func(_ *helper.Config, _ cre.Runtime) (onchain.Strategy, error) {
// 				return optimalStrategy, nil
// 			},
// 			CalculateAPYForStrategy: func(_ *helper.Config, _ cre.Runtime, s onchain.Strategy, _ *big.Int) (float64, error) {
// 				switch s {
// 				case optimalStrategy:
// 					return optimalAPY, nil
// 				case currentStrategy:
// 					return currentAPY, nil
// 				default:
// 					return 0.0, nil
// 				}
// 			},
// 		}

// 		res, err := onCronTriggerWithDeps(cfg, runtime, nil, deps)
// 		require.NoError(t, err, "unexpected error from onCronTriggerWithDeps")
// 		require.NotNil(t, res, "expected non-nil result")

// 		shouldRebalance := delta >= threshold

// 		if shouldRebalance {
// 			require.True(t, writeCalled,
// 				"expected WriteRebalance to be called when delta >= threshold (delta=%f, threshold=%f)", delta, threshold)
// 			require.True(t, res.Updated, "expected result.Updated=true when delta >= threshold")

// 			expectedGas := parentCfg.GasLimit
// 			if !sameChain {
// 				expectedGas = childCfg.GasLimit
// 			}
// 			require.Equal(t, expectedGas, gotGasLimit,
// 				"unexpected gasLimit passed to WriteRebalance (sameChain=%v)", sameChain)
// 		} else {
// 			require.False(t, writeCalled,
// 				"expected WriteRebalance NOT to be called when delta < threshold or APYs invalid (delta=%f, threshold=%f)", delta, threshold)
// 			require.False(t, res.Updated,
// 				"expected result.Updated=false when delta < threshold or APYs invalid")
// 		}
// 	})
// }

// // Fuzz_onCronTriggerWithDeps_StrategyEqualityNoRebalance fuzzes whether the
// // current and optimal strategies are equal, and asserts that when they are
// // equal the workflow short-circuits: no TVL read, no APY calculation, and no
// // rebalance.
// func Fuzz_onCronTriggerWithDeps_StrategyEqualityNoRebalance(f *testing.F) {
// 	f.Add(true)
// 	f.Add(false)

// 	f.Fuzz(func(t *testing.T, equal bool) {
// 		t.Helper()

// 		runtime := testutils.NewRuntime(t, nil)

// 		cfg := newTestConfig()
// 		parentCfg := cfg.Evms[0]

// 		currentStrategy := newStrategy(1, parentCfg.ChainSelector)
// 		optimalStrategy := currentStrategy
// 		if !equal {
// 			// Minimal deterministic difference.
// 			optimalStrategy.ProtocolId[0] ^= 1
// 		}

// 		var (
// 			tvlCalled        bool
// 			apyCalled        bool
// 			rebalancerCalled bool
// 			writeCalled      bool
// 		)

// 		deps := OnCronDeps{
// 			NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
// 				return nil, nil
// 			},
// 			NewChildPeerBinding: func(_ *evm.Client, _ string) (onchain.YieldPeerInterface, error) {
// 				// In this setup everything is on parent chain.
// 				t.Fatalf("NewChildPeerBinding should not be called in this fuzz test")
// 				return nil, nil
// 			},
// 			NewRebalancerBinding: func(_ *evm.Client, _ string) (onchain.RebalancerInterface, error) {
// 				rebalancerCalled = true
// 				if equal {
// 					t.Fatalf("NewRebalancerBinding should not be called when strategies are equal")
// 				}
// 				return nil, nil
// 			},
// 			ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
// 				return currentStrategy, nil
// 			},
// 			ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
// 				tvlCalled = true
// 				if equal {
// 					t.Fatalf("ReadTVL should not be called when strategies are equal")
// 				}
// 				return big.NewInt(1_000), nil
// 			},
// 			WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
// 				writeCalled = true
// 				if equal {
// 					t.Fatalf("WriteRebalance should not be called when strategies are equal")
// 				}
// 				return nil
// 			},
// 			GetOptimalStrategy: func(_ *helper.Config, _ cre.Runtime) (onchain.Strategy, error) {
// 				return optimalStrategy, nil
// 			},
// 			CalculateAPYForStrategy: func(_ *helper.Config, _ cre.Runtime, s onchain.Strategy, _ *big.Int) (float64, error) {
// 				apyCalled = true
// 				if equal {
// 					t.Fatalf("CalculateAPYForStrategy should not be called when strategies are equal")
// 				}
// 				// For unequal case, force delta >= threshold so rebalance path is exercised.
// 				if s == optimalStrategy {
// 					return threshold + 1.0, nil
// 				}
// 				if s == currentStrategy {
// 					return 0.0, nil
// 				}
// 				return 0.0, nil
// 			},
// 		}

// 		res, err := onCronTriggerWithDeps(cfg, runtime, nil, deps)
// 		require.NoError(t, err, "unexpected error from onCronTriggerWithDeps")
// 		require.NotNil(t, res, "expected non-nil result")

// 		if equal {
// 			require.False(t, res.Updated, "expected Updated=false when strategies are equal")
// 			require.Equal(t, currentStrategy, res.Current)
// 			require.Equal(t, optimalStrategy, res.Optimal)

// 			require.False(t, tvlCalled, "ReadTVL should not be called when strategies are equal")
// 			require.False(t, apyCalled, "CalculateAPYForStrategy should not be called when strategies are equal")
// 			require.False(t, rebalancerCalled, "NewRebalancerBinding should not be called when strategies are equal")
// 			require.False(t, writeCalled, "WriteRebalance should not be called when strategies are equal")
// 		} else {
// 			require.True(t, res.Updated, "expected Updated=true when strategies differ and delta >= threshold")
// 			require.True(t, tvlCalled, "expected ReadTVL to be called when strategies differ")
// 			require.True(t, apyCalled, "expected CalculateAPYForStrategy to be called when strategies differ")
// 			require.True(t, rebalancerCalled, "expected NewRebalancerBinding to be called when strategies differ")
// 			require.True(t, writeCalled, "expected WriteRebalance to be called when strategies differ")
// 		}
// 	})
// }

// // Fuzz_onCronTriggerWithDeps_ChildPeerBindingUsage fuzzes whether the current
// // strategy is on the parent or child chain, and asserts that:
// //   - NewChildPeerBinding is only called when the current strategy is NOT on the parent chain.
// //   - ReadTVL is always called exactly once.
// //   - No rebalance occurs when delta < threshold.
// func Fuzz_onCronTriggerWithDeps_ChildPeerBindingUsage(f *testing.F) {
// 	f.Add(true)  // current strategy on parent chain
// 	f.Add(false) // current strategy on child chain

// 	f.Fuzz(func(t *testing.T, sameChain bool) {
// 		t.Helper()

// 		runtime := testutils.NewRuntime(t, nil)

// 		cfg := newTestConfig()
// 		parentCfg := cfg.Evms[0]
// 		childCfg := cfg.Evms[1]

// 		curChainSelector := parentCfg.ChainSelector
// 		if !sameChain {
// 			curChainSelector = childCfg.ChainSelector
// 		}

// 		currentStrategy := newStrategy(1, curChainSelector)
// 		optimalStrategy := newStrategy(2, parentCfg.ChainSelector)

// 		var (
// 			childBindCalls   int
// 			readTVLCalls     int
// 			rebalancerCalled bool
// 			writeCalled      bool
// 		)

// 		deps := OnCronDeps{
// 			NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
// 				return nil, nil
// 			},
// 			NewChildPeerBinding: func(_ *evm.Client, _ string) (onchain.YieldPeerInterface, error) {
// 				childBindCalls++
// 				return nil, nil
// 			},
// 			NewRebalancerBinding: func(_ *evm.Client, _ string) (onchain.RebalancerInterface, error) {
// 				rebalancerCalled = true
// 				return nil, nil
// 			},
// 			ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
// 				return currentStrategy, nil
// 			},
// 			ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
// 				readTVLCalls++
// 				return big.NewInt(1_000), nil
// 			},
// 			WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
// 				writeCalled = true
// 				return nil
// 			},
// 			GetOptimalStrategy: func(_ *helper.Config, _ cre.Runtime) (onchain.Strategy, error) {
// 				return optimalStrategy, nil
// 			},
// 			CalculateAPYForStrategy: func(_ *helper.Config, _ cre.Runtime, s onchain.Strategy, _ *big.Int) (float64, error) {
// 				// Keep delta < threshold so rebalance never happens.
// 				if s == optimalStrategy {
// 					return 0.0, nil
// 				}
// 				if s == currentStrategy {
// 					return 0.0, nil
// 				}
// 				return 0.0, nil
// 			},
// 		}

// 		res, err := onCronTriggerWithDeps(cfg, runtime, nil, deps)
// 		require.NoError(t, err, "unexpected error from onCronTriggerWithDeps")
// 		require.NotNil(t, res, "expected non-nil result")

// 		require.False(t, res.Updated, "expected Updated=false when delta < threshold")
// 		require.Equal(t, 1, readTVLCalls, "expected ReadTVL to be called exactly once")
// 		require.False(t, rebalancerCalled, "Rebalancer should not be called when delta < threshold")
// 		require.False(t, writeCalled, "WriteRebalance should not be called when delta < threshold")

// 		if sameChain {
// 			require.Equal(t, 0, childBindCalls,
// 				"expected NewChildPeerBinding not to be called when strategy is on parent chain")
// 		} else {
// 			require.Equal(t, 1, childBindCalls,
// 				"expected NewChildPeerBinding to be called once when strategy is on child chain")
// 		}
// 	})
// }

// // Fuzz_onCronTriggerWithDeps_APYLiquidityAddedWiring fuzzes TVL and chain placement
// // and asserts that:
// //   - CalculateAPYForStrategy is called with liquidityAdded == TVL for the optimal strategy.
// //   - CalculateAPYForStrategy is called with liquidityAdded == 0 for the current strategy.
// func Fuzz_onCronTriggerWithDeps_APYLiquidityAddedWiring(f *testing.F) {
// 	f.Add(int64(0), true)
// 	f.Add(int64(1_000), true)
// 	f.Add(int64(1_000), false)

// 	f.Fuzz(func(t *testing.T, tvlRaw int64, sameChain bool) {
// 		t.Helper()

// 		runtime := testutils.NewRuntime(t, nil)

// 		cfg := newTestConfig()
// 		parentCfg := cfg.Evms[0]
// 		childCfg := cfg.Evms[1]

// 		tvl := big.NewInt(tvlRaw)

// 		curChainSelector := parentCfg.ChainSelector
// 		if !sameChain {
// 			curChainSelector = childCfg.ChainSelector
// 		}

// 		currentStrategy := newStrategy(1, curChainSelector)
// 		optimalStrategy := newStrategy(2, parentCfg.ChainSelector)

// 		var (
// 			optimalLiquAdded *big.Int
// 			currentLiquAdded *big.Int
// 		)

// 		deps := OnCronDeps{
// 			NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
// 				return nil, nil
// 			},
// 			NewChildPeerBinding: func(_ *evm.Client, _ string) (onchain.YieldPeerInterface, error) {
// 				return nil, nil
// 			},
// 			NewRebalancerBinding: func(_ *evm.Client, _ string) (onchain.RebalancerInterface, error) {
// 				// Should never be called; we keep delta=0 so no rebalance.
// 				t.Fatalf("NewRebalancerBinding should not be called in APY wiring fuzz")
// 				return nil, nil
// 			},
// 			ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
// 				return currentStrategy, nil
// 			},
// 			ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
// 				// Return a copy so mutations won't affect our tvl variable.
// 				return new(big.Int).Set(tvl), nil
// 			},
// 			WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
// 				t.Fatalf("WriteRebalance should not be called in APY wiring fuzz")
// 				return nil
// 			},
// 			GetOptimalStrategy: func(_ *helper.Config, _ cre.Runtime) (onchain.Strategy, error) {
// 				return optimalStrategy, nil
// 			},
// 			CalculateAPYForStrategy: func(_ *helper.Config, _ cre.Runtime, s onchain.Strategy, liquidityAdded *big.Int) (float64, error) {
// 				if s == optimalStrategy {
// 					require.Nil(t, optimalLiquAdded, "optimal strategy APY calculation called more than once")
// 					optimalLiquAdded = new(big.Int).Set(liquidityAdded)
// 				} else if s == currentStrategy {
// 					require.Nil(t, currentLiquAdded, "current strategy APY calculation called more than once")
// 					currentLiquAdded = new(big.Int).Set(liquidityAdded)
// 				}
// 				// APY values themselves don't matter here, only liquidityAdded.
// 				return 0.0, nil
// 			},
// 		}

// 		res, err := onCronTriggerWithDeps(cfg, runtime, nil, deps)
// 		require.NoError(t, err, "unexpected error from onCronTriggerWithDeps")
// 		require.NotNil(t, res, "expected non-nil result")

// 		require.NotNil(t, optimalLiquAdded, "expected CalculateAPYForStrategy to be called for optimal strategy")
// 		require.NotNil(t, currentLiquAdded, "expected CalculateAPYForStrategy to be called for current strategy")

// 		require.Equal(t, 0, optimalLiquAdded.Cmp(tvl),
// 			"expected optimal strategy to be called with liquidityAdded == TVL; got %s, want %s",
// 			optimalLiquAdded.String(), tvl.String())

// 		require.Equal(t, 0, currentLiquAdded.Sign(),
// 			"expected current strategy to be called with liquidityAdded == 0; got %s",
// 			currentLiquAdded.String())
// 	})
// }

// // Fuzz_onCronTriggerWithDeps_DeltaTranslationInvariance fuzzes base APY, delta,
// // and shift, and asserts that adding the same shift to both APYs does not change
// // the rebalance decision (Updated flag and whether WriteRebalance is called).
// func Fuzz_onCronTriggerWithDeps_DeltaTranslationInvariance(f *testing.F) {
// 	f.Add(int64(0), int64(0), int64(0))
// 	f.Add(int64(10), int64(5), int64(100))
// 	f.Add(int64(-10), int64(20), int64(-50))

// 	f.Fuzz(func(t *testing.T, baseRaw int64, deltaRaw int64, shiftRaw int64) {
// 		t.Helper()

// 		type decision struct {
// 			updated    bool
// 			wrote      bool
// 			writeDelta float64
// 			optimalAPY float64
// 			currentAPY float64
// 		}

// 		runOnce := func(base, delta, shift int64) decision {
// 			runtime := testutils.NewRuntime(t, nil)

// 			cfg := newTestConfig()
// 			parentCfg := cfg.Evms[0]

// 			currentStrategy := newStrategy(1, parentCfg.ChainSelector)
// 			optimalStrategy := newStrategy(2, parentCfg.ChainSelector)

// 			baseF := float64(base)
// 			deltaF := float64(delta)
// 			shiftF := float64(shift)

// 			currentAPY := baseF + shiftF
// 			optimalAPY := currentAPY + deltaF

// 			var (
// 				writeCalled bool
// 				updated     bool
// 			)

// 			deps := OnCronDeps{
// 				NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
// 					return nil, nil
// 				},
// 				NewChildPeerBinding: func(_ *evm.Client, _ string) (onchain.YieldPeerInterface, error) {
// 					t.Fatalf("NewChildPeerBinding should not be called in translation test")
// 					return nil, nil
// 				},
// 				NewRebalancerBinding: func(_ *evm.Client, _ string) (onchain.RebalancerInterface, error) {
// 					return nil, nil
// 				},
// 				ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
// 					return currentStrategy, nil
// 				},
// 				ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
// 					// TVL is irrelevant for the APY model here.
// 					return big.NewInt(1_000), nil
// 				},
// 				WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
// 					writeCalled = true
// 					return nil
// 				},
// 				GetOptimalStrategy: func(_ *helper.Config, _ cre.Runtime) (onchain.Strategy, error) {
// 					return optimalStrategy, nil
// 				},
// 				CalculateAPYForStrategy: func(_ *helper.Config, _ cre.Runtime, s onchain.Strategy, _ *big.Int) (float64, error) {
// 					if s == optimalStrategy {
// 						return optimalAPY, nil
// 					}
// 					if s == currentStrategy {
// 						return currentAPY, nil
// 					}
// 					return 0.0, nil
// 				},
// 			}

// 			res, err := onCronTriggerWithDeps(cfg, runtime, nil, deps)
// 			require.NoError(t, err, "unexpected error from onCronTriggerWithDeps")
// 			require.NotNil(t, res, "expected non-nil result")

// 			updated = res.Updated

// 			return decision{
// 				updated:    updated,
// 				wrote:      writeCalled,
// 				optimalAPY: optimalAPY,
// 				currentAPY: currentAPY,
// 				writeDelta: optimalAPY - currentAPY,
// 			}
// 		}

// 		// Run once without shift and once with shift.
// 		dec1 := runOnce(baseRaw, deltaRaw, 0)
// 		dec2 := runOnce(baseRaw, deltaRaw, shiftRaw)

// 		// The delta should be identical in both runs.
// 		require.Equal(t, dec1.writeDelta, dec2.writeDelta,
// 			"expected identical APY deltas; got %f and %f", dec1.writeDelta, dec2.writeDelta)

// 		// Property: rebalance decision depends only on delta, not on absolute APY levels.
// 		require.Equal(t, dec1.updated, dec2.updated,
// 			"Updated mismatch between runs with same delta: run1=%v run2=%v", dec1.updated, dec2.updated)
// 		require.Equal(t, dec1.wrote, dec2.wrote,
// 			"WriteRebalance mismatch between runs with same delta: run1=%v run2=%v", dec1.wrote, dec2.wrote)
// 	})
// }