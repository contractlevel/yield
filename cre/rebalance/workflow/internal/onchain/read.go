package onchain

import (
	"math/big"

	"github.com/smartcontractkit/cre-sdk-go/cre"

	"rebalance/workflow/internal/helper"
)

// ReadCurrentStrategy reads the current strategy from a parent peer using the runtime
func ReadCurrentStrategy(config *helper.Config, runtime cre.Runtime, peer ParentPeerInterface) (Strategy, error) {
	strategy, err := peer.GetStrategy(runtime, big.NewInt(config.BlockNumber)).Await()
	if err != nil {
		return Strategy{}, err
	}
	return Strategy{ProtocolId: strategy.ProtocolId, ChainSelector: strategy.ChainSelector}, nil
}

// ReadTVL reads the total value locked from a yield peer using the runtime
func ReadTVL(config *helper.Config, runtime cre.Runtime, peer YieldPeerInterface) (*big.Int, error) {
	return peer.GetTotalValue(runtime, big.NewInt(config.BlockNumber)).Await()
}