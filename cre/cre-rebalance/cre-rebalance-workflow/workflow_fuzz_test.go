package main

import (
	"testing"
	"math/big"

	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
)

func Fuzz_decideAndMaybeRebalance(f *testing.F) {
	runtime := testutils.NewRuntime(f, nil)
	logger := runtime.Logger()

	// Seed corpus with a couple of deterministic examples
	f.Add(uint8(1), uint64(10), uint8(1), uint64(10)) // equal
	f.Add(uint8(1), uint64(10), uint8(2), uint64(10)) // different

	f.Fuzz(func(t *testing.T, protocolA uint8, chainSelectorA uint64, protocolB uint8, chainSelectorB uint64) {
		// Simple way to build ProtocolId from a byte; rest zero.
		var idA, idB [32]byte
		idA[0] = protocolA
		idB[0] = protocolB

		current := Strategy{
			ProtocolId:    idA,
			ChainSelector: chainSelectorA,
		}
		optimal := Strategy{
			ProtocolId:    idB,
			ChainSelector: chainSelectorB,
		}

		callCount := 0
		writeFn := func(opt Strategy) error {
			callCount++
			return nil
		}

		res, err := decideAndMaybeRebalance(logger, current, optimal, writeFn)
		if err != nil {
			// By construction, decideAndMaybeRebalance only returns an error
			// from writeFn; our writeFn never errors.
			t.Fatalf("unexpected error: %v", err)
		}
		if res == nil {
			t.Fatalf("expected non-nil result")
		}

		if current == optimal {
			if callCount != 0 {
				t.Fatalf("writeFn called %d times when strategies equal", callCount)
			}
			if res.Updated {
				t.Fatalf("Updated should be false when strategies equal")
			}
		} else {
			if callCount != 1 {
				t.Fatalf("writeFn called %d times when strategies differ", callCount)
			}
			if !res.Updated {
				t.Fatalf("Updated should be true when strategies differ")
			}
		}
	})
}

func Fuzz_findEvmConfigByChainSelector(f *testing.F) {
	// Seed some simple examples
	f.Add(uint64(1), uint64(2), uint64(3), uint64(2)) // hit middle
	f.Add(uint64(1), uint64(2), uint64(3), uint64(9)) // miss all
	f.Add(uint64(5), uint64(5), uint64(5), uint64(5)) // all same, hit first

	f.Fuzz(func(t *testing.T, a, b, c, target uint64) {
		// Build a small slice with up to 3 possible matches.
		evms := []EvmConfig{
			{ChainName: "a", ChainSelector: a},
			{ChainName: "b", ChainSelector: b},
			{ChainName: "c", ChainSelector: c},
		}

		cfg, err := findEvmConfigByChainSelector(evms, target)

		// Compute the expected "first match" by scanning ourselves.
		var want *EvmConfig
		for i := range evms {
			evm := evms[i]
			if evm.ChainSelector == target {
				want = &evm
				break
			}
		}

		if want != nil {
			// We expect a match.
			if err != nil {
				t.Fatalf("expected nil error, got %v", err)
			}
			if cfg == nil {
				t.Fatalf("expected non-nil cfg when selector present")
			}
			if cfg.ChainSelector != want.ChainSelector || cfg.ChainName != want.ChainName {
				t.Fatalf("unexpected cfg: got %+v, want %+v", cfg, want)
			}
		} else {
			// We expect no match.
			if err == nil {
				t.Fatalf("expected error when selector missing, got nil")
			}
			if cfg != nil {
				t.Fatalf("expected nil cfg when selector missing, got %+v", cfg)
			}
		}
	})
}

func Fuzz_calculateOptimalStrategy(f *testing.F) {
	runtime := testutils.NewRuntime(f, nil)
	logger := runtime.Logger()

	// Seed example inputs (protocol byte, chain selector, tvl)
	f.Add(uint8(1), uint64(10), int64(0))
	f.Add(uint8(2), uint64(42), int64(100))
	f.Add(uint8(255), uint64(0), int64(-12345)) // negative tvl to exercise normalization

	f.Fuzz(func(t *testing.T, protoByte uint8, chainSel uint64, tvlRaw int64) {
		// Build a Strategy whose ProtocolId is derived from a single byte.
		var id [32]byte
		id[0] = protoByte

		current := Strategy{
			ProtocolId:    id,
			ChainSelector: chainSel,
		}

		// Ensure tvl is non-negative; real-world TVL should not be negative.
		if tvlRaw < 0 {
			tvlRaw = -tvlRaw
		}
		tvl := big.NewInt(tvlRaw)

		optimal := calculateOptimalStrategy(logger, current, tvl)

		// Invariant: chain selector must not change.
		if optimal.ChainSelector != current.ChainSelector {
			t.Fatalf("calculateOptimalStrategy changed chain selector: current=%d optimal=%d",
				current.ChainSelector, optimal.ChainSelector)
		}

		// Basic sanity: tvl should remain non-negative; if we ever change the function
		// to mutate tvl, this guards against silly mistakes.
		if tvl.Sign() < 0 {
			t.Fatalf("tvl became negative unexpectedly: %s", tvl.String())
		}

		// We deliberately do NOT assert on ProtocolId, because your implementation
		// is free to change how it computes the "dummy-protocol-v1" hash later.
	})
}
