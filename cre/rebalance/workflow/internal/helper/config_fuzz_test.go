package helper

import (
	"testing"

	"github.com/stretchr/testify/require"
)


func Fuzz_FindEvmConfigByChainSelector(f *testing.F) {
	// Seed some simple examples.
	f.Add(uint64(1), uint64(2), uint64(3), uint64(2)) // hit middle
	f.Add(uint64(1), uint64(2), uint64(3), uint64(9)) // miss all
	f.Add(uint64(5), uint64(5), uint64(5), uint64(5)) // all same, hit first

	f.Fuzz(func(t *testing.T, a, b, c, target uint64) {
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
				// Capture value of evm, not pointer to loop var.
				copy := evm
				want = &copy
				break
			}
		}

		if want != nil {
			// We expect a match.
			require.NoError(t, err, "expected no error when selector present")
			require.NotNil(t, cfg, "expected non-nil cfg when selector present")
			require.Equal(t, want.ChainSelector, cfg.ChainSelector, "unexpected ChainSelector")
			require.Equal(t, want.ChainName, cfg.ChainName, "unexpected ChainName")
		} else {
			// We expect no match.
			require.Error(t, err, "expected error when selector missing")
			require.Nil(t, cfg, "expected nil cfg when selector missing")
		}
	})
}
