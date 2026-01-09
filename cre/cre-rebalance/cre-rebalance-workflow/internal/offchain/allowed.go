package offchain

// Allowed chains, projects and symbols for DefiLlama pools
var AllowedChain = map[string]bool{
	"Ethereum": true,
	"Arbitrum": true,
	"Base":     true,
	"Optimism": true,
}

var AllowedProject = map[string]bool{
	"aave-v3":     true,
	"compound-v3": true,
}

var AllowedSymbol = map[string]bool{
	"USDC": true,
}
