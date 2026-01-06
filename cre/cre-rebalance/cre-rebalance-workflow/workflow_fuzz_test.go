package main

import (
	"log/slog"
	"math/big"
	"testing"

	"cre-rebalance/cre-rebalance-workflow/internal/helper"
	"cre-rebalance/cre-rebalance-workflow/internal/onchain"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
)

const (
    parentChainSelector = 1
    childChainSelector  = 2
    parentGasLimit      = 500_000
    childGasLimit       = 777_000
    parentYieldAddr     = "0xparent"
    parentRebalancer    = "0xrebalancer-parent"
    childYieldAddr      = "0xchild"
)

func newTestConfig(withChild bool) *helper.Config {
    cfg := &helper.Config{
        Evms: []helper.EvmConfig{
            {
                ChainName:         "parent-chain",
                ChainSelector:     parentChainSelector,
                YieldPeerAddress:  parentYieldAddr,
                RebalancerAddress: parentRebalancer,
                GasLimit:          parentGasLimit,
            },
        },
    }
    if withChild {
        cfg.Evms = append(cfg.Evms, helper.EvmConfig{
            ChainName:        "child-chain",
            ChainSelector:    childChainSelector,
            YieldPeerAddress: childYieldAddr,
            GasLimit:         childGasLimit,
        })
    }
    return cfg
}

// Fuzz_onCronTriggerWithDeps_RebalanceThresholdAndGasLimit fuzzes the APY delta and
// whether the current strategy is on the parent or child chain. It verifies:
//   - WriteRebalance is called iff delta >= threshold.
//   - StrategyResult.Updated == (delta >= threshold).
//   - gasLimit passed to WriteRebalance matches the gasLimit of the correct EVM config:
//       * parent gasLimit when currentStrategy.ChainSelector == parentCfg.ChainSelector
//       * child gasLimit otherwise.
func Fuzz_onCronTriggerWithDeps_RebalanceThresholdAndGasLimit(f *testing.F) {
	// Seed a few interesting edge/near-edge cases.
	f.Add(int64(-1), true)  // below threshold, same chain
	f.Add(int64(0), true)   // at threshold, same chain
	f.Add(int64(1), true)   // above threshold, same chain
	f.Add(int64(-1), false) // below threshold, different chain
	f.Add(int64(0), false)  // at threshold, different chain
	f.Add(int64(1), false)  // above threshold, different chain

	f.Fuzz(func(t *testing.T, deltaRaw int64, sameChain bool) {
		t.Helper()

		// Model: currentAPY = 0, optimalAPY = delta.
		delta := big.NewInt(deltaRaw)
		currentAPY := big.NewInt(0)
		optimalAPY := new(big.Int).Add(currentAPY, delta)

		runtime := testutils.NewRuntime(t, nil)

		// Two EVM configs: parent and child.
		cfg := newTestConfig(true)
		parentCfg := cfg.Evms[0]
		childCfg := cfg.Evms[1]

		// Decide which chain the current strategy is on.
		curChainSelector := parentCfg.ChainSelector
		if !sameChain {
			curChainSelector = childCfg.ChainSelector
		}

		currentStrategy := onchain.Strategy{
			ProtocolId:    [32]byte{1},
			ChainSelector: curChainSelector,
		}
		optimalStrategy := onchain.Strategy{
			ProtocolId:    [32]byte{2},
			ChainSelector: parentCfg.ChainSelector,
		}

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
			ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
				return currentStrategy, nil
			},
			ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
				// TVL doesn't affect the rebalance decision in workflow.go in this model.
				return big.NewInt(1_000), nil
			},
			WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, gasLimit uint64, optimal onchain.Strategy) error {
				writeCalled = true
				gotGasLimit = gasLimit
				if optimal != optimalStrategy {
					t.Fatalf("WriteRebalance optimal mismatch: got %+v, want %+v", optimal, optimalStrategy)
				}
				return nil
			},
			GetOptimalStrategy: func() (onchain.Strategy, error) {
				return optimalStrategy, nil
			},
			CalculateAPYForStrategy: func(_ *helper.Config, _ cre.Runtime, s onchain.Strategy, _ *big.Int) (*big.Int, error) {
				switch s {
				case optimalStrategy:
					return new(big.Int).Set(optimalAPY), nil
				case currentStrategy:
					return new(big.Int).Set(currentAPY), nil
				default:
					return big.NewInt(0), nil
				}
			},
		}

		res, err := onCronTriggerWithDeps(cfg, runtime, nil, deps)
		if err != nil {
			t.Fatalf("unexpected error from onCronTriggerWithDeps: %v", err)
		}
		if res == nil {
			t.Fatalf("expected non-nil result")
		}

		shouldRebalance := delta.Cmp(threshold) >= 0

		if shouldRebalance {
			if !writeCalled {
				t.Fatalf("expected WriteRebalance to be called when delta >= threshold (delta=%s, threshold=%s)", delta.String(), threshold.String())
			}
			if !res.Updated {
				t.Fatalf("expected result.Updated=true when delta >= threshold")
			}

			expectedGas := parentCfg.GasLimit
			if !sameChain {
				expectedGas = childCfg.GasLimit
			}
			if gotGasLimit != expectedGas {
				t.Fatalf("unexpected gasLimit passed to WriteRebalance: got %d, want %d (sameChain=%v)", gotGasLimit, expectedGas, sameChain)
			}
		} else {
			if writeCalled {
				t.Fatalf("expected WriteRebalance NOT to be called when delta < threshold (delta=%s, threshold=%s)", delta.String(), threshold.String())
			}
			if res.Updated {
				t.Fatalf("expected result.Updated=false when delta < threshold")
			}
		}
	})
}

// Fuzz_onCronTriggerWithDeps_StrategyEqualityNoRebalance fuzzes whether the
// current and optimal strategies are equal, and asserts that when they are
// equal the workflow short-circuits: no TVL read, no APY calculation, and no
// rebalance.
func Fuzz_onCronTriggerWithDeps_StrategyEqualityNoRebalance(f *testing.F) {
	f.Add(true)
	f.Add(false)

	f.Fuzz(func(t *testing.T, equal bool) {
		t.Helper()

		runtime := testutils.NewRuntime(t, nil)

		cfg := newTestConfig(false)
		parentCfg := cfg.Evms[0]

		currentStrategy := onchain.Strategy{
			ProtocolId:    [32]byte{1},
			ChainSelector: parentCfg.ChainSelector,
		}
		optimalStrategy := currentStrategy
		if !equal {
			// Minimal deterministic difference.
			optimalStrategy.ProtocolId[0] ^= 1
		}

		var (
			tvlCalled        bool
			apyCalled        bool
			rebalancerCalled bool
			writeCalled      bool
		)

		deps := OnCronDeps{
			NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
				return nil, nil
			},
			NewChildPeerBinding: func(_ *evm.Client, _ string) (onchain.YieldPeerInterface, error) {
				// In this setup everything is on parent chain.
				t.Fatalf("NewChildPeerBinding should not be called in this fuzz test")
				return nil, nil
			},
			NewRebalancerBinding: func(_ *evm.Client, _ string) (onchain.RebalancerInterface, error) {
				rebalancerCalled = true
				if equal {
					t.Fatalf("NewRebalancerBinding should not be called when strategies are equal")
				}
				return nil, nil
			},
			ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
				return currentStrategy, nil
			},
			ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
				tvlCalled = true
				if equal {
					t.Fatalf("ReadTVL should not be called when strategies are equal")
				}
				return big.NewInt(1_000), nil
			},
			WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
				writeCalled = true
				if equal {
					t.Fatalf("WriteRebalance should not be called when strategies are equal")
				}
				return nil
			},
			GetOptimalStrategy: func() (onchain.Strategy, error) {
				return optimalStrategy, nil
			},
			CalculateAPYForStrategy: func(_ *helper.Config, _ cre.Runtime, s onchain.Strategy, _ *big.Int) (*big.Int, error) {
				apyCalled = true
				if equal {
					t.Fatalf("CalculateAPYForStrategy should not be called when strategies are equal")
				}
				// For unequal case, force delta >= threshold so rebalance path is exercised.
				if s == optimalStrategy {
					return new(big.Int).Add(threshold, big.NewInt(1)), nil
				}
				if s == currentStrategy {
					return big.NewInt(0), nil
				}
				return big.NewInt(0), nil
			},
		}

		res, err := onCronTriggerWithDeps(cfg, runtime, nil, deps)
		if err != nil {
			t.Fatalf("unexpected error from onCronTriggerWithDeps: %v", err)
		}
		if res == nil {
			t.Fatalf("expected non-nil result")
		}

		if equal {
			if res.Updated {
				t.Fatalf("expected Updated=false when strategies are equal")
			}
			if res.Current != currentStrategy || res.Optimal != optimalStrategy {
				t.Fatalf("unexpected result when equal: %+v", res)
			}
			if tvlCalled || apyCalled || rebalancerCalled || writeCalled {
				t.Fatalf("unexpected downstream calls when strategies are equal: tvl=%v apy=%v rebinder=%v write=%v",
					tvlCalled, apyCalled, rebalancerCalled, writeCalled)
			}
		} else {
			if !res.Updated {
				t.Fatalf("expected Updated=true when strategies differ and delta >= threshold")
			}
			if !tvlCalled || !apyCalled || !rebalancerCalled || !writeCalled {
				t.Fatalf("expected all downstream calls when strategies differ; tvl=%v apy=%v rebinder=%v write=%v",
					tvlCalled, apyCalled, rebalancerCalled, writeCalled)
			}
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

		cfg := newTestConfig(true)
		parentCfg := cfg.Evms[0]
		childCfg := cfg.Evms[1]

		curChainSelector := parentCfg.ChainSelector
		if !sameChain {
			curChainSelector = childCfg.ChainSelector
		}

		currentStrategy := onchain.Strategy{
			ProtocolId:    [32]byte{1},
			ChainSelector: curChainSelector,
		}
		optimalStrategy := onchain.Strategy{
			ProtocolId:    [32]byte{2},
			ChainSelector: parentCfg.ChainSelector,
		}

		var (
			childBindCalls   int
			readTVLCalls     int
			rebalancerCalled bool
			writeCalled      bool
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
				rebalancerCalled = true
				return nil, nil
			},
			ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
				return currentStrategy, nil
			},
			ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
				readTVLCalls++
				return big.NewInt(1_000), nil
			},
			WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
				writeCalled = true
				return nil
			},
			GetOptimalStrategy: func() (onchain.Strategy, error) {
				return optimalStrategy, nil
			},
			CalculateAPYForStrategy: func(_ *helper.Config, _ cre.Runtime, s onchain.Strategy, _ *big.Int) (*big.Int, error) {
				// Keep delta < threshold so rebalance never happens:
				// optimal=1, current=0 => delta=1 << threshold(1e17).
				if s == optimalStrategy {
					return big.NewInt(1), nil
				}
				if s == currentStrategy {
					return big.NewInt(0), nil
				}
				return big.NewInt(0), nil
			},
		}

		res, err := onCronTriggerWithDeps(cfg, runtime, nil, deps)
		if err != nil {
			t.Fatalf("unexpected error from onCronTriggerWithDeps: %v", err)
		}
		if res == nil {
			t.Fatalf("expected non-nil result")
		}
		if res.Updated {
			t.Fatalf("expected Updated=false when delta < threshold")
		}
		if readTVLCalls != 1 {
			t.Fatalf("expected ReadTVL to be called exactly once, got %d", readTVLCalls)
		}
		if rebalancerCalled || writeCalled {
			t.Fatalf("rebalancer/write should not be called when delta < threshold; rebinder=%v write=%v", rebalancerCalled, writeCalled)
		}

		if sameChain {
			if childBindCalls != 0 {
				t.Fatalf("expected NewChildPeerBinding not to be called when strategy is on parent chain; got %d calls", childBindCalls)
			}
		} else {
			if childBindCalls != 1 {
				t.Fatalf("expected NewChildPeerBinding to be called once when strategy is on child chain; got %d calls", childBindCalls)
			}
		}
	})
}

// Fuzz_onCronTriggerWithDeps_APYLiquidityAddedWiring fuzzes TVL and chain placement
// and asserts that:
//   - CalculateAPYForStrategy is called with liquidityAdded == TVL for the optimal strategy.
//   - CalculateAPYForStrategy is called with liquidityAdded == 0 for the current strategy.
func Fuzz_onCronTriggerWithDeps_APYLiquidityAddedWiring(f *testing.F) {
	f.Add(int64(0), true)
	f.Add(int64(1_000), true)
	f.Add(int64(1_000), false)

	f.Fuzz(func(t *testing.T, tvlRaw int64, sameChain bool) {
		t.Helper()

		runtime := testutils.NewRuntime(t, nil)

		cfg := newTestConfig(true)
		parentCfg := cfg.Evms[0]
		childCfg := cfg.Evms[1]

		tvl := big.NewInt(tvlRaw)

		curChainSelector := parentCfg.ChainSelector
		if !sameChain {
			curChainSelector = childCfg.ChainSelector
		}

		currentStrategy := onchain.Strategy{
			ProtocolId:    [32]byte{1},
			ChainSelector: curChainSelector,
		}
		optimalStrategy := onchain.Strategy{
			ProtocolId:    [32]byte{2},
			ChainSelector: parentCfg.ChainSelector,
		}

		var (
			optimalLiquAdded *big.Int
			currentLiquAdded *big.Int
		)

		deps := OnCronDeps{
			NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
				return nil, nil
			},
			NewChildPeerBinding: func(_ *evm.Client, _ string) (onchain.YieldPeerInterface, error) {
				return nil, nil
			},
			NewRebalancerBinding: func(_ *evm.Client, _ string) (onchain.RebalancerInterface, error) {
				// Should never be called; we keep delta=0 so no rebalance.
				t.Fatalf("NewRebalancerBinding should not be called in APY wiring fuzz")
				return nil, nil
			},
			ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
				return currentStrategy, nil
			},
			ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
				// Return a copy so mutations won't affect our tvl variable.
				return new(big.Int).Set(tvl), nil
			},
			WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
				t.Fatalf("WriteRebalance should not be called in APY wiring fuzz")
				return nil
			},
			GetOptimalStrategy: func() (onchain.Strategy, error) {
				return optimalStrategy, nil
			},
			CalculateAPYForStrategy: func(_ *helper.Config, _ cre.Runtime, s onchain.Strategy, liquidityAdded *big.Int) (*big.Int, error) {
				if s == optimalStrategy {
					if optimalLiquAdded != nil {
						t.Fatalf("optimal strategy APY calculation called more than once")
					}
					optimalLiquAdded = new(big.Int).Set(liquidityAdded)
				} else if s == currentStrategy {
					if currentLiquAdded != nil {
						t.Fatalf("current strategy APY calculation called more than once")
					}
					currentLiquAdded = new(big.Int).Set(liquidityAdded)
				}
				// APY values themselves don't matter here, only liquidityAdded.
				return big.NewInt(0), nil
			},
		}

		res, err := onCronTriggerWithDeps(cfg, runtime, nil, deps)
		if err != nil {
			t.Fatalf("unexpected error from onCronTriggerWithDeps: %v", err)
		}
		if res == nil {
			t.Fatalf("expected non-nil result")
		}

		if optimalLiquAdded == nil || currentLiquAdded == nil {
			t.Fatalf("expected CalculateAPYForStrategy to be called for both strategies; optimalAdded=%v currentAdded=%v",
				optimalLiquAdded, currentLiquAdded)
		}

		if optimalLiquAdded.Cmp(tvl) != 0 {
			t.Fatalf("expected optimal strategy to be called with liquidityAdded == TVL; got %s, want %s",
				optimalLiquAdded.String(), tvl.String())
		}
		if currentLiquAdded.Sign() != 0 {
			t.Fatalf("expected current strategy to be called with liquidityAdded == 0; got %s",
				currentLiquAdded.String())
		}
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
			updated     bool
			wrote       bool
			writeDelta  *big.Int
			optimalAPY  *big.Int
			currentAPY  *big.Int
		}

		runOnce := func(base, delta, shift int64) decision {
			runtime := testutils.NewRuntime(t, nil)

			cfg := newTestConfig(false)
			parentCfg := cfg.Evms[0]

			currentStrategy := onchain.Strategy{
				ProtocolId:    [32]byte{1},
				ChainSelector: parentCfg.ChainSelector,
			}
			optimalStrategy := onchain.Strategy{
				ProtocolId:    [32]byte{2},
				ChainSelector: parentCfg.ChainSelector,
			}

			baseBI := big.NewInt(base)
			deltaBI := big.NewInt(delta)
			shiftBI := big.NewInt(shift)

			currentAPY := new(big.Int).Add(baseBI, shiftBI)
			optimalAPY := new(big.Int).Add(currentAPY, deltaBI)

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
				ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
					return currentStrategy, nil
				},
				ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
					// TVL is irrelevant for the APY model here.
					return big.NewInt(1_000), nil
				},
				WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
					writeCalled = true
					return nil
				},
				GetOptimalStrategy: func() (onchain.Strategy, error) {
					return optimalStrategy, nil
				},
				CalculateAPYForStrategy: func(_ *helper.Config, _ cre.Runtime, s onchain.Strategy, _ *big.Int) (*big.Int, error) {
					if s == optimalStrategy {
						return new(big.Int).Set(optimalAPY), nil
					}
					if s == currentStrategy {
						return new(big.Int).Set(currentAPY), nil
					}
					return big.NewInt(0), nil
				},
			}

			res, err := onCronTriggerWithDeps(cfg, runtime, nil, deps)
			if err != nil {
				t.Fatalf("unexpected error from onCronTriggerWithDeps: %v", err)
			}
			if res == nil {
				t.Fatalf("expected non-nil result")
			}
			updated = res.Updated

			return decision{
				updated:    updated,
				wrote:      writeCalled,
				optimalAPY: optimalAPY,
				currentAPY: currentAPY,
				writeDelta: new(big.Int).Sub(optimalAPY, currentAPY),
			}
		}

		// Run once without shift and once with shift.
		dec1 := runOnce(baseRaw, deltaRaw, 0)
		dec2 := runOnce(baseRaw, deltaRaw, shiftRaw)

		// The delta should be identical in both runs.
		if dec1.writeDelta.Cmp(dec2.writeDelta) != 0 {
			t.Fatalf("expected identical APY deltas; got %s and %s",
				dec1.writeDelta.String(), dec2.writeDelta.String())
		}

		// Property: rebalance decision depends only on delta, not on absolute APY levels.
		if dec1.updated != dec2.updated {
			t.Fatalf("Updated mismatch between runs with same delta: run1=%v run2=%v",
				dec1.updated, dec2.updated)
		}
		if dec1.wrote != dec2.wrote {
			t.Fatalf("WriteRebalance mismatch between runs with same delta: run1=%v run2=%v",
				dec1.wrote, dec2.wrote)
		}
	})
}
