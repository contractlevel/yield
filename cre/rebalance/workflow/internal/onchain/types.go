package onchain

// Strategy represents a yield strategy configuration
type Strategy struct {
	ProtocolId    [32]byte // keccak256("aave-v3"), keccak256("compound-v3"), etc.
	StablecoinId  [32]byte // keccak256("USDC"), keccak256("USDT"), etc.
	ChainSelector uint64
}

type StrategyWithAPY struct {
	Strategy Strategy
	APY      float64
}