package onchain

import (
	"fmt"
	"rebalance/workflow/internal/helper"
)

const numberOfProtocols = 2 // @review this needs to be updated when new protocols are added

var supportedStrategies []Strategy
var initialized bool

// InitSupportedStrategies builds the cross-product of
//   all configured chains × all hardcoded protocols.
// Call this once at startup, after config is loaded.
func InitSupportedStrategies(cfg *helper.Config) error {
    if initialized {
        return fmt.Errorf("InitSupportedStrategies called more than once")
    }
    initialized = true

    // pre-allocate capacity for less GC.
    supportedStrategies = make([]Strategy, 0, len(cfg.Evms)*numberOfProtocols)

    for _, evm := range cfg.Evms {
        if evm.AaveV3PoolAddressesProviderAddress != "" {
            // AaveV3 on this chain
            supportedStrategies = append(supportedStrategies, Strategy{
                ProtocolId:    AaveV3ProtocolId,
                ChainSelector: evm.ChainSelector,
            })
        }

        if evm.CompoundV3CometUSDCAddress != "" {
            // CompoundV3 on this chain
            supportedStrategies = append(supportedStrategies, Strategy{
                ProtocolId:    CompoundV3ProtocolId,
                ChainSelector: evm.ChainSelector,
            })
        }
    }

    return nil
}
