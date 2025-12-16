package onchain

import (
	"strings"
	"testing"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
)

func Test_NewParentPeerBinding_success(t *testing.T) {
	var client *evm.Client = nil
	addr := "0x0000000000000000000000000000000000000001"

	binding, err := NewParentPeerBinding(client, addr)
	if err != nil {
		t.Fatalf("expected nil error, got: %v", err)
	}
	if binding == nil {
		t.Fatalf("expected non-nil binding, got nil")
	}

	// Verify that the binding implements ParentPeerInterface
	// This is a compile-time type check: if binding doesn't implement
	// ParentPeerInterface, this line will fail to compile.
	var _ ParentPeerInterface = binding
}

func Test_NewParentPeerBinding_errorWhen_invalidAddress(t *testing.T) {
	var client *evm.Client = nil
	addr := "not-an-address"

	binding, err := NewParentPeerBinding(client, addr)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if binding != nil {
		t.Fatalf("expected nil binding on error, got non-nil")
	}
	if !strings.Contains(err.Error(), "invalid ParentPeer address: "+addr) {
		t.Fatalf("unexpected error: %v", err)
	}
}

func Test_NewChildPeerBinding_success(t *testing.T) {
	var client *evm.Client = nil
	addr := "0x0000000000000000000000000000000000000002"

	binding, err := NewChildPeerBinding(client, addr)
	if err != nil {
		t.Fatalf("expected nil error, got: %v", err)
	}
	if binding == nil {
		t.Fatalf("expected non-nil binding, got nil")
	}
	var _ YieldPeerInterface = binding
}

func Test_NewChildPeerBinding_errorWhen_invalidAddress(t *testing.T) {
	var client *evm.Client = nil
	addr := "still-not-an-address"

	binding, err := NewChildPeerBinding(client, addr)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if binding != nil {
		t.Fatalf("expected nil binding on error, got non-nil")
	}
	if !strings.Contains(err.Error(), "invalid ChildPeer address: "+addr) {
		t.Fatalf("unexpected error: %v", err)
	}
}

func Test_NewRebalancerBinding_success(t *testing.T) {
	var client *evm.Client = nil
	addr := "0x0000000000000000000000000000000000000003"

	binding, err := NewRebalancerBinding(client, addr)
	if err != nil {
		t.Fatalf("expected nil error, got: %v", err)
	}
	if binding == nil {
		t.Fatalf("expected non-nil binding, got nil")
	}
	var _ RebalancerInterface = binding
}

func Test_NewRebalancerBinding_errorWhen_invalidAddress(t *testing.T) {
	var client *evm.Client = nil
	addr := "bad"

	binding, err := NewRebalancerBinding(client, addr)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if binding != nil {
		t.Fatalf("expected nil binding on error, got non-nil")
	}
	if !strings.Contains(err.Error(), "invalid Rebalancer address: "+addr) {
		t.Fatalf("unexpected error: %v", err)
	}
}

