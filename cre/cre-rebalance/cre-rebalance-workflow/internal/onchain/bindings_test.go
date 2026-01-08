package onchain

import (
	"testing"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/stretchr/testify/require"
)

func Test_NewParentPeerBinding_success(t *testing.T) {
	var client *evm.Client
	addr := "0x0000000000000000000000000000000000000001"

	binding, err := NewParentPeerBinding(client, addr)
	require.NoError(t, err)
	require.NotNil(t, binding)

	// Compile-time check: binding implements ParentPeerInterface.
	var _ ParentPeerInterface = binding
}

func Test_NewParentPeerBinding_errorWhen_invalidAddress(t *testing.T) {
	var client *evm.Client
	addr := "not-an-address"

	binding, err := NewParentPeerBinding(client, addr)
	require.Error(t, err)
	require.Nil(t, binding)
	require.ErrorContains(t, err, "invalid ParentPeer address: "+addr)
}

func Test_NewChildPeerBinding_success(t *testing.T) {
	var client *evm.Client
	addr := "0x0000000000000000000000000000000000000002"

	binding, err := NewChildPeerBinding(client, addr)
	require.NoError(t, err)
	require.NotNil(t, binding)

	// Compile-time check: binding implements YieldPeerInterface.
	var _ YieldPeerInterface = binding
}

func Test_NewChildPeerBinding_errorWhen_invalidAddress(t *testing.T) {
	var client *evm.Client
	addr := "still-not-an-address"

	binding, err := NewChildPeerBinding(client, addr)
	require.Error(t, err)
	require.Nil(t, binding)
	require.ErrorContains(t, err, "invalid ChildPeer address: "+addr)
}

func Test_NewRebalancerBinding_success(t *testing.T) {
	var client *evm.Client
	addr := "0x0000000000000000000000000000000000000003"

	binding, err := NewRebalancerBinding(client, addr)
	require.NoError(t, err)
	require.NotNil(t, binding)

	// Compile-time check: binding implements RebalancerInterface.
	var _ RebalancerInterface = binding
}

func Test_NewRebalancerBinding_errorWhen_invalidAddress(t *testing.T) {
	var client *evm.Client
	addr := "bad"

	binding, err := NewRebalancerBinding(client, addr)
	require.Error(t, err)
	require.Nil(t, binding)
	require.ErrorContains(t, err, "invalid Rebalancer address: "+addr)
}
