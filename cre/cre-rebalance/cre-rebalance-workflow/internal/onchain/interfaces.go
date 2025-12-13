package onchain

import (
	"math/big"

	"cre-rebalance/contracts/evm/src/generated/parent_peer"
	"cre-rebalance/contracts/evm/src/generated/rebalancer"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// ParentPeerInterface defines the subset used to read the current strategy.
type ParentPeerInterface interface {
	GetStrategy(runtime cre.Runtime, blockNumber *big.Int) cre.Promise[parent_peer.IYieldPeerStrategy]
}

// YieldPeerInterface defines the subset used to read TVL.
type YieldPeerInterface interface {
	GetTotalValue(runtime cre.Runtime, blockNumber *big.Int) cre.Promise[*big.Int]
}

// RebalancerInterface defines the subset used to write the rebalance report.
type RebalancerInterface interface {
	WriteReportFromIYieldPeerStrategy(runtime cre.Runtime, input rebalancer.IYieldPeerStrategy, gasConfig *evm.GasConfig) cre.Promise[*evm.WriteReportReply]
}

// @review we will need interfaces for reading Aave contracts