package onchain

import "cre-rebalance/cre-rebalance-workflow/internal/helper"

var SupportedStrategies []Strategy

// InitSupportedStrategies builds the cross-product of
//   all configured chains × all hardcoded protocols.
// Call this once at startup, after config is loaded.
func InitSupportedStrategies(cfg *helper.Config) {
    // 2 protocols right now; pre-allocate capacity for less GC.
    SupportedStrategies = make([]Strategy, 0, len(cfg.Evms)*2)

    for _, evm := range cfg.Evms {
        // AaveV3 on this chain
        SupportedStrategies = append(SupportedStrategies, Strategy{
            ProtocolId:    AaveV3ProtocolId,
            ChainSelector: evm.ChainSelector,
        })

        // CompoundV3 on this chain
        SupportedStrategies = append(SupportedStrategies, Strategy{
            ProtocolId:    CompoundV3ProtocolId,
            ChainSelector: evm.ChainSelector,
        })
    }
}
