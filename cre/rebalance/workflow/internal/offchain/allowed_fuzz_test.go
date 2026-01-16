package offchain

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

// --- MAPPING INVARIANTS ---
// These fuzz tests ensure that our allowlist maps don't contain 'false' values,
// which would be confusing. They verify that existence in the map EQUALS an allowed state.

func Fuzz_offchain_allowedChain(f *testing.F) {
	f.Add("Arbitrum")
	f.Add("Solana")

	f.Fuzz(func(t *testing.T, input string) {
		val, exists := AllowedChain[input]

		if exists {
			// Invariant: Any key present in the map MUST be set to true.
			assert.True(t, val, "Chain %s present in map but set to false", input)
		} else {
			// Invariant: If not in map, the lookup must return the zero-value (false).
			assert.False(t, val, "Chain %s not in map but lookup returned true", input)
		}
	})
}

func Fuzz_offchain_allowedProject(f *testing.F) {
	f.Add("aave-v3")
	f.Add("uniswap")

	f.Fuzz(func(t *testing.T, input string) {
		val, exists := AllowedProject[input]

		if exists {
			assert.True(t, val, "Project %s present in map but set to false", input)
		} else {
			assert.False(t, val, "Project %s not in map but lookup returned true", input)
		}
	})
}

func Fuzz_offchain_allowedSymbol(f *testing.F) {
	f.Add("USDC")
	f.Add("WETH")

	f.Fuzz(func(t *testing.T, input string) {
		val, exists := AllowedSymbol[input]

		if exists {
			assert.True(t, val, "Symbol %s present in map but set to false", input)
		} else {
			assert.False(t, val, "Symbol %s not in map but lookup returned true", input)
		}
	})
}
