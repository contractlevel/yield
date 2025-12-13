package onchain

import (
	"math/big"

	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// ReadCurrentStrategy reads the current strategy from a parent peer using the runtime
func ReadCurrentStrategy(peer ParentPeerInterface, runtime cre.Runtime) (Strategy, error) {
	strategy, err := peer.GetStrategy(runtime, big.NewInt(LatestBlock)).Await()
	if err != nil {
		return Strategy{}, err
	}
	return Strategy{ProtocolId: strategy.ProtocolId, ChainSelector: strategy.ChainSelector}, nil
}

// ReadTVL reads the total value locked from a yield peer using the runtime
func ReadTVL(peer YieldPeerInterface, runtime cre.Runtime) (*big.Int, error) {
	return peer.GetTotalValue(runtime, big.NewInt(LatestBlock)).Await()
}