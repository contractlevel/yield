package onchain

// Strategy represents a yield strategy configuration
type Strategy struct {
	ProtocolId    [32]byte
	ChainSelector uint64
}

type StrategyWithAPY struct {
	Strategy Strategy
	APY      float64
}