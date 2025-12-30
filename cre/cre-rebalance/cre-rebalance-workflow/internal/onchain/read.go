package onchain

import (
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/cre"

	"cre-rebalance/contracts/evm/src/generated/strategy_helper"
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

// ReadAaveAPR reads the Aave APR for a given liquidity added and asset
// liquidityAdded should be 0 for current APR or the amount we are adding to see the new APR
func ReadAaveAPR(strategyHelper StrategyHelperInterface, runtime cre.Runtime, liquidityAdded *big.Int, asset common.Address) (*big.Int, error) {
    args := strategy_helper.GetAaveAPRInput{
        LiquidityAdded: liquidityAdded,
        Asset:          asset,
    }

    apr, err := strategyHelper.GetAaveAPR(runtime, args, big.NewInt(LatestBlock)).Await()
    if err != nil {
        return nil, err
    }
    return apr, nil
}