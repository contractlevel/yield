package offchain

// Allowed chains, projects and symbols for DefiLlama pools
var AllowedChains = map[string]bool{
	"Ethereum": true,
	"Arbitrum": true,
	"Base":     true,
	"Optimism": true,
}

var AllowedProjects = map[string]bool{
	"aave-v3":     true,
	"compound-v3": true,
}

var AllowedSymbols = map[string]bool{
	"USDC": true,
	"USDT": true,
}
