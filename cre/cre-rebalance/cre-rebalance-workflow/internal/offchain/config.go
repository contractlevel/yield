package workflow

type Config struct {
	Schedule string 	 `json:"schedule"`
	Evms     []EvmConfig `json:"evms"` // Parent chain is Evms[0]
}

type EvmConfig struct {
	ChainName string 		 `json:"chainName"`
	ChainSelector uint64 	 `json:"chainSelector"`
	YieldPeerAddress string  `json:"yieldPeerAddress"`
	RebalancerAddress string `json:"rebalancerAddress"`
	GasLimit uint64 	     `json:"gasLimit"`
}