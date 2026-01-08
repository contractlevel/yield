package onchain

import (
	"math/big"

	"github.com/smartcontractkit/cre-sdk-go/cre"

	"cre-rebalance/cre-rebalance-workflow/internal/constants"
)

// ReadCurrentStrategy reads the current strategy from a parent peer using the runtime
func ReadCurrentStrategy(peer ParentPeerInterface, runtime cre.Runtime) (Strategy, error) {
	strategy, err := peer.GetStrategy(runtime, big.NewInt(constants.LatestBlock)).Await()
	if err != nil {
		return Strategy{}, err
	}
	return Strategy{ProtocolId: strategy.ProtocolId, ChainSelector: strategy.ChainSelector}, nil
}

// ReadTVL reads the total value locked from a yield peer using the runtime
func ReadTVL(peer YieldPeerInterface, runtime cre.Runtime) (*big.Int, error) {
	return peer.GetTotalValue(runtime, big.NewInt(constants.LatestBlock)).Await()
	// @review err if tvl == 0
}