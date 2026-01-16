package offchain

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func Test_offchain_AllowlistMappings(t *testing.T) {
	// 1. Chain Mapping Tests
	t.Run("AllowedChains", func(t *testing.T) {
		tests := []struct {
			chain    string
			expected bool
		}{
			{"Arbitrum", true},
			{"Base", true},
			{"Ethereum", true},
			{"Optimism", true},
			{"Solana", false},
			{"Unknown", false},
		}
		for _, tc := range tests {
			assert.Equal(t, tc.expected, AllowedChain[tc.chain], "Chain: %s", tc.chain)
		}
	})

	// 2. Project Mapping Tests
	t.Run("AllowedProjects", func(t *testing.T) {
		tests := []struct {
			project  string
			expected bool
		}{
			{"aave-v3", true},
			{"compound-v3", true},
			{"uniswap", false},
			{"unknown-dex", false},
		}
		for _, tc := range tests {
			assert.Equal(t, tc.expected, AllowedProject[tc.project], "Project: %s", tc.project)
		}
	})

	// 3. Symbol Mapping Tests
	t.Run("AllowedSymbols", func(t *testing.T) {
		tests := []struct {
			symbol   string
			expected bool
		}{
			{"USDC", true},
			{"ETH", false},
			{"LINK", false},
		}
		for _, tc := range tests {
			assert.Equal(t, tc.expected, AllowedSymbol[tc.symbol], "Symbol: %s", tc.symbol)
		}
	})
}
