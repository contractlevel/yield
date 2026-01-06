package onchain

import "cre-rebalance/cre-rebalance-workflow/internal/helper"

var supportedStrategies []Strategy

// initSupportedStrategies builds the cross-product of
//   all configured chains × all hardcoded protocols.
// Call this once at startup, after config is loaded.
func initSupportedStrategies(cfg *helper.Config) {
    // 2 protocols right now; pre-allocate capacity for less GC.
    supportedStrategies = make([]Strategy, 0, len(cfg.Evms)*2)

    // @review do we want to add a bool to config for whether a strategy is supported on that chain?
    for _, evm := range cfg.Evms {
        // AaveV3 on this chain
        supportedStrategies = append(supportedStrategies, Strategy{
            ProtocolId:    AaveV3ProtocolId,
            ChainSelector: evm.ChainSelector,
        })

        // CompoundV3 on this chain
        supportedStrategies = append(supportedStrategies, Strategy{
            ProtocolId:    CompoundV3ProtocolId,
            ChainSelector: evm.ChainSelector,
        })
    }
}
