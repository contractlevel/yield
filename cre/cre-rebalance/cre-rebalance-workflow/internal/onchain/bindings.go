package onchain

import (
	"cre-rebalance/contracts/evm/src/generated/parent_peer"
	"cre-rebalance/contracts/evm/src/generated/rebalancer"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
)

// NewParentPeer constructs the parent peer binding.
// It satisfies ParentPeerInterface (and thus YieldPeerInterface via embedding).
func NewParentPeer(client *evm.Client, addr common.Address) (ParentPeerInterface, error) {
	return parent_peer.NewParentPeer(client, addr, nil)
}

// NewChildPeer constructs the child peer binding.
// It satisfies YieldPeerInterface.
func NewChildPeer(client *evm.Client, addr common.Address) (YieldPeerInterface, error) {
	// @review still using parent_peer binding; underlying contract could be a child.
	return parent_peer.NewParentPeer(client, addr, nil)
}

// NewRebalancer constructs the rebalancer binding.
func NewRebalancer(client *evm.Client, addr common.Address) (RebalancerInterface, error) {
	return rebalancer.NewRebalancer(client, addr, nil)
}
