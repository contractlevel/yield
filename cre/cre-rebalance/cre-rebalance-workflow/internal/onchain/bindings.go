package onchain

import (
	"fmt"

	"cre-rebalance/contracts/evm/src/generated/parent_peer"
	"cre-rebalance/contracts/evm/src/generated/child_peer"
	"cre-rebalance/contracts/evm/src/generated/rebalancer"
	"cre-rebalance/contracts/evm/src/generated/strategy_helper"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
)

// NewParentPeerBinding constructs the parent peer binding.
// It satisfies ParentPeerInterface (and thus YieldPeerInterface via embedding).
func NewParentPeerBinding(client *evm.Client, addr string) (ParentPeerInterface, error) {
	if !common.IsHexAddress(addr) {
		return nil, fmt.Errorf("invalid ParentPeer address: %s", addr)
	}
	parentPeerAddr := common.HexToAddress(addr)

	return parent_peer.NewParentPeer(client, parentPeerAddr, nil)
}

// NewChildPeerBinding constructs the child peer binding.
// It satisfies YieldPeerInterface.
func NewChildPeerBinding(client *evm.Client, addr string) (YieldPeerInterface, error) {
	if !common.IsHexAddress(addr) {
		return nil, fmt.Errorf("invalid ChildPeer address: %s", addr)
	}
	childPeerAddr := common.HexToAddress(addr)
	
	return child_peer.NewChildPeer(client, childPeerAddr, nil)
}

// NewRebalancerBinding constructs the rebalancer binding.
// It satisfies RebalancerInterface.
func NewRebalancerBinding(client *evm.Client, addr string) (RebalancerInterface, error) {
	if !common.IsHexAddress(addr) {
		return nil, fmt.Errorf("invalid Rebalancer address: %s", addr)
	}
	rebalancerAddr := common.HexToAddress(addr)

	return rebalancer.NewRebalancer(client, rebalancerAddr, nil)
}

// NewStrategyHelperBinding constructs the strategy helper binding.
// It satisfies StrategyHelperInterface.
func NewStrategyHelperBinding(client *evm.Client, addr string) (StrategyHelperInterface, error) {
	if !common.IsHexAddress(addr) {
		return nil, fmt.Errorf("invalid StrategyHelper address: %s", addr)
	}
	strategyHelperAddr := common.HexToAddress(addr)

	return strategy_helper.NewStrategyHelper(client, strategyHelperAddr, nil)
}