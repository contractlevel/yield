package offchain

import (
	"fmt"
)

func FindEvmConfigByChainSelector(evms []EvmConfig, target uint64) (*EvmConfig, error) {
	for i := range evms {
		if evms[i].ChainSelector == target {
			return &evms[i], nil
		}
	}
	return nil, fmt.Errorf("no evm config found for chainSelector %d", target)
}
