package offchain

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func Test_AllowedChainMapping(t *testing.T) {
	tests := []struct {
		name     string
		chain    string
		expected bool
	}{
		{"Ethereum allowed", "Ethereum", true},
		{"Arbitrum allowed", "Arbitrum", true},
		{"Base allowed", "Base", true},
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

func Test_AllowedProjectMapping(t *testing.T) {
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

func Test_AllowedSymbolMapping(t *testing.T) {
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

func Fuzz_AllowedChain(f *testing.F) {
	f.Add("Ethereum")
	f.Add("Solana")
	f.Add("")

	f.Fuzz(func(t *testing.T, chain string) {
		got, exists := AllowedChain[chain]
		if exists {
			assert.True(t, got, "Key exists in AllowedChain but returned false")
		} else {
			assert.False(t, got, "Key does not exist in AllowedChain but returned true")
		}
	})
}

func Fuzz_AllowedProject(f *testing.F) {
	f.Add("aave-v3")
	f.Add("uniswap")
	f.Add("")

	f.Fuzz(func(t *testing.T, project string) {
		got, exists := AllowedProject[project]
		if exists {
			assert.True(t, got, "Key exists in AllowedProject but returned false")
		} else {
			assert.False(t, got, "Key does not exist in AllowedProject but returned true")
		}
	})
}

func Fuzz_AllowedSymbol(f *testing.F) {
	f.Add("USDC")
	f.Add("ETH")
	f.Add("")

	f.Fuzz(func(t *testing.T, symbol string) {
		got, exists := AllowedSymbol[symbol]
		if exists {
			assert.True(t, got, "Key exists in AllowedSymbol but returned false")
		} else {
			assert.False(t, got, "Key does not exist in AllowedSymbol but returned true")
		}
	})
}
