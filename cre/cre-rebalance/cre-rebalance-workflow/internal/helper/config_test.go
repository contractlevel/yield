package helper

import (
	"strings"
	"testing"
)

func Test_FindEvmConfigByChainSelector_found(t *testing.T) {
	evms := []EvmConfig{
		{ChainName: "chain-a", ChainSelector: 1},
		{ChainName: "chain-b", ChainSelector: 2},
	}

	cfg, err := FindEvmConfigByChainSelector(evms, 2)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg == nil {
		t.Fatalf("expected non-nil config")
	}
	if cfg.ChainName != "chain-b" {
		t.Fatalf("expected chain-b, got %s", cfg.ChainName)
	}
}

func Test_FindEvmConfigByChainSelector_notFound(t *testing.T) {
	evms := []EvmConfig{
		{ChainName: "chain-a", ChainSelector: 1},
	}

	cfg, err := FindEvmConfigByChainSelector(evms, 999)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if cfg != nil {
		t.Fatalf("expected nil config when not found, got %+v", cfg)
	}
	if !strings.Contains(err.Error(), "no evm config found for chainSelector 999") {
		t.Fatalf("unexpected error message: %v", err)
	}
}

func Fuzz_FindEvmConfigByChainSelector(f *testing.F) {
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

		cfg, err := FindEvmConfigByChainSelector(evms, target)

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