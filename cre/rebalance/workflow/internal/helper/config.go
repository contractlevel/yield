package helper

import (
	"fmt"
)

// Config is loaded from config.json
//
//	{
//	  "schedule": "0 */1 * * * *",
//	  "evms": [
//	    {
//	      "chainName": "ethereum-testnet-sepolia",
//	      "chainSelector": 16015286601757825753,
//	      "yieldPeerAddress": "0x...",
//	      "rebalancerAddress": "0x...",
//	      "gasLimit": 500000
//	    }
//	  ]
//	}
type Config struct {
	Schedule    string      `json:"schedule"`
	BlockNumber int64       `json:"blockNumber"`
	Evms        []EvmConfig `json:"evms"` // Parent chain is Evms[0]
}

// EvmConfig:
//   - evms[0] is the parent chain: where the Parent YieldPeer is
//     and where we read the currentStrategy from.
//   - currentStrategy.ChainSelector tells us which chain the active strategy
//     adapter lives on.
type EvmConfig struct {
	ChainName         				   string `json:"chainName"`
	ChainSelector     				   uint64 `json:"chainSelector"`
	YieldPeerAddress  				   string `json:"yieldPeerAddress"`
	RebalancerAddress 				   string `json:"rebalancerAddress"`
	GasLimit                           uint64 `json:"gasLimit"`
	USDCAddress       				   string `json:"usdcAddress"`
	AaveV3PoolAddressesProviderAddress string `json:"aaveV3PoolAddressesProviderAddress"`
	CompoundV3CometUSDCAddress         string `json:"compoundV3CometUSDCAddress"`
}

func FindEvmConfigByChainSelector(evms []EvmConfig, target uint64) (*EvmConfig, error) {
	for i := range evms {
		if evms[i].ChainSelector == target {
			return &evms[i], nil
		}
	}
	return nil, fmt.Errorf("no evm config found for chainSelector %d", target)
}
