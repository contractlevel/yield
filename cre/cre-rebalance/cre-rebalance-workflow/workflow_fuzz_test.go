// workflow_fuzz_test.go
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
		// This makes delta = optimal - current, same as in workflow.go.
		delta := big.NewInt(deltaRaw)
		currentAPY := big.NewInt(0)
		optimalAPY := new(big.Int).Add(currentAPY, delta)

		runtime := testutils.NewRuntime(t, nil)

		// Two EVM configs: parent and child.
		cfg := &helper.Config{
			Evms: []helper.EvmConfig{
				{
					ChainName:         "parent-chain",
					ChainSelector:     1,
					YieldPeerAddress:  "0xparent",
					RebalancerAddress: "0xrebalancer-parent",
					GasLimit:          500_000,
				},
				{
					ChainName:        "child-chain",
					ChainSelector:    2,
					YieldPeerAddress: "0xchild",
					GasLimit:         777_000,
				},
			},
		}
		parentCfg := cfg.Evms[0]
		childCfg := cfg.Evms[1]

		// Decide which chain the CURRENT strategy is on.
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
				// TVL doesn't affect the rebalance decision in workflow.go,
				// so we just return a constant.
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
					// Not used in this test; return a benign value.
					return big.NewInt(0), nil
				}
			},
		}

		// trigger is currently unused by onCronTriggerWithDeps, so nil is fine.
		res, err := onCronTriggerWithDeps(cfg, runtime, nil, deps)
		if err != nil {
			t.Fatalf("unexpected error from onCronTriggerWithDeps: %v", err)
		}
		if res == nil {
			t.Fatalf("expected non-nil result")
		}

		// Property under test: rebalance should happen iff delta >= threshold.
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
