package helper

import (
	"fmt"
)

// Config is the workflow configuration.
// For cre-rebalance-workflow, it includes schedule and EVM configs.
// For apy-impact-calculator, it includes schedule, deposit amount, and chains.
//
// Example for cre-rebalance-workflow:
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
//
// Example for apy-impact-calculator:
//
//	{
//	  "schedule": "0 */6 * * *",
//	  "depositUSDC": "10000000000000",
//	  "chains": [...]
//	}
type Config struct {
	Schedule    string        `json:"schedule"`
	DepositUSDC string        `json:"depositUSDC,omitempty"` // Amount in USDC (with 6 decimals), for apy-impact-calculator
	Chains      []ChainConfig `json:"chains,omitempty"`      // For apy-impact-calculator
	Evms        []EvmConfig   `json:"evms,omitempty"`        // For cre-rebalance-workflow
}

// EvmConfig:
//   - evms[0] is the parent chain: where the Parent YieldPeer is
//     and where we read the currentStrategy from.
//   - currentStrategy.ChainSelector tells us which chain the active strategy
//     adapter lives on.
type EvmConfig struct {
	ChainName         string `json:"chainName"`
	ChainSelector     uint64 `json:"chainSelector"`
	YieldPeerAddress  string `json:"yieldPeerAddress"`
	RebalancerAddress string `json:"rebalancerAddress"`
	GasLimit          uint64 `json:"gasLimit"`
}

// ChainConfig holds AAVE v3 contract addresses for each chain
// This is shared between apy-impact-calculator and cre-rebalance-workflow
type ChainConfig struct {
	ChainName        string `json:"chainName"`
	ChainSelector    uint64 `json:"chainSelector"`
	PoolDataProvider string `json:"poolDataProvider"` // For reading data
	USDCAddress      string `json:"usdcAddress"`      // USDC token address
}

func FindEvmConfigByChainSelector(evms []EvmConfig, target uint64) (*EvmConfig, error) {
	for i := range evms {
		if evms[i].ChainSelector == target {
			return &evms[i], nil
		}
	}
	return nil, fmt.Errorf("no evm config found for chainSelector %d", target)
}
