package offchain

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func Test_offchain_allowedChainMapping_tableDriven(t *testing.T) {
	tests := []struct {
		name     string
		chain    string
		expected bool
	}{
		{"Arbitrum allowed", "Arbitrum", true},
		{"Base allowed", "Base", true},
		{"Ethereum allowed", "Ethereum", true},
		{"Optimism allowed", "Optimism", true},
		{"Solana not allowed", "Solana", false},
		{"Unknown chain not allowed", "abcdefg", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := AllowedChain[tt.chain]
			assert.Equal(t, tt.expected, got, "AllowedChain lookup failed for %s", tt.chain)
		})
	}
}

func Test_offchain_allowedProjectMapping_tableDriven(t *testing.T) {
	tests := []struct {
		name     string
		project  string
		expected bool
	}{
		{"aave-v3 allowed", "aave-v3", true},
		{"compound-v3 allowed", "compound-v3", true},
		{"uniswap not allowed", "uniswap", false},
		{"Unknown project not allowed", "curve", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := AllowedProject[tt.project]
			assert.Equal(t, tt.expected, got, "AllowedProject lookup failed for %s", tt.project)
		})
	}
}

func Test_offchain_allowedSymbolMapping_tableDriven(t *testing.T) {
	tests := []struct {
		name     string
		symbol   string
		expected bool
	}{
		{"USDC allowed", "USDC", true},
		{"ETH not allowed", "ETH", false},
		{"Unknown symbol not allowed", "BTC", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := AllowedSymbol[tt.symbol]
			assert.Equal(t, tt.expected, got, "AllowedSymbol lookup failed for %s", tt.symbol)
		})
	}
}

func Fuzz_offchain_allowedChain(f *testing.F) {
	f.Add("Arbitrum")
	f.Add("Ethereum")
	f.Add("Base")
	f.Add("Optimism")

	f.Fuzz(func(t *testing.T, chain string) {
		got, exists := AllowedChain[chain]

		if exists {
			// If it exists in mapping, it MUST be one of the allowed chains
			// and its value must be true.
			if !got {
				t.Errorf("Chain %s exists in map but is set to false", chain)
			}
		} else {
			// If exists is false, 'got' must be the zero-value (false)
			if got {
				t.Errorf("Critical Error: Map returned true for a key %s that doesn't exist", chain)
			}
		}
	})
}

func Fuzz_offchain_allowedProject(f *testing.F) {
	f.Add("aave-v3")
	f.Add("compound-v3")

	f.Fuzz(func(t *testing.T, project string) {
		got, exists := AllowedProject[project]

		if exists {
			// Since  map only contains 'true',
			// any key that 'exists' MUST be true.
			if !got {
				t.Errorf("Project %q exists in map but value is false", project)
			}
		} else {
			// If it doesn't exist, Go's zero-value for bool is false.
			if got {
				t.Errorf("Project %q does not exist but map returned true", project)
			}
		}
	})
}

func Fuzz_offchain_allowedSymbol(f *testing.F) {
	f.Add("USDC")

	f.Fuzz(func(t *testing.T, symbol string) {
		got, exists := AllowedSymbol[symbol]

		if exists {
			if !got {
				t.Errorf("Symbol %q exists but is false", symbol)
			}
		} else {
			if got {
				t.Errorf("Symbol %q missing but got true", symbol)
			}
		}
	})
}
