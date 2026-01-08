package helper

import (
	"fmt"
)

// Config is loaded from config.json
type Config struct {
	Schedule string      `json:"schedule"`
	Evms     []EvmConfig `json:"evms"`
}

// EvmConfig represents EVM chain configuration
type EvmConfig struct {
	ChainName                          string `json:"chainName"`
	ChainSelector                      uint64 `json:"chainSelector"`
	USDCAddress                        string `json:"usdcAddress"`
	AaveV3PoolAddressesProviderAddress string `json:"aaveV3PoolAddressesProviderAddress"`
}

func FindEvmConfigByChainSelector(evms []EvmConfig, target uint64) (*EvmConfig, error) {
	for i := range evms {
		if evms[i].ChainSelector == target {
			return &evms[i], nil
		}
	}
	return nil, fmt.Errorf("no evm config found for chainSelector %d", target)
}
