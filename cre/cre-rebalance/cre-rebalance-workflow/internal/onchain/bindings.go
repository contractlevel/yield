package onchain

import (
	"fmt"

	"cre-rebalance/contracts/evm/src/generated/parent_peer"
	"cre-rebalance/contracts/evm/src/generated/rebalancer"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
)

// NewParentPeer constructs the parent peer binding.
// It satisfies ParentPeerInterface (and thus YieldPeerInterface via embedding).
func NewParentPeerBinding(client *evm.Client, addr string) (ParentPeerInterface, error) {
	if !common.IsHexAddress(addr) {
		return nil, fmt.Errorf("invalid ParentPeer address: %s", addr)
	}
	parentPeerAddr := common.HexToAddress(addr)

	return parent_peer.NewParentPeer(client, parentPeerAddr, nil)
}

// NewChildPeer constructs the child peer binding.
// It satisfies YieldPeerInterface.
func NewChildPeerBinding(client *evm.Client, addr string) (YieldPeerInterface, error) {
	if !common.IsHexAddress(addr) {
		return nil, fmt.Errorf("invalid ChildPeer address: %s", addr)
	}
	childPeerAddr := common.HexToAddress(addr)
	
	// @review still using parent_peer binding; underlying contract should beå child.
	return parent_peer.NewParentPeer(client, childPeerAddr, nil)
}

// NewRebalancer constructs the rebalancer binding.
func NewRebalancerBinding(client *evm.Client, addr string) (RebalancerInterface, error) {
	if !common.IsHexAddress(addr) {
		return nil, fmt.Errorf("invalid Rebalancer address: %s", addr)
	}
	rebalancerAddr := common.HexToAddress(addr)

	return rebalancer.NewRebalancer(client, rebalancerAddr, nil)
}
