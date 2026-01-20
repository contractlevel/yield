package compoundV3

import (
	"strings"
	"testing"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
)

func Test_newCometBinding_success(t *testing.T) {
	var client *evm.Client = nil
	addr := "0x0000000000000000000000000000000000000001"

	binding, err := newCometBinding(client, addr)
	if err != nil {
		t.Fatalf("expected nil error, got: %v", err)
	}
	if binding == nil {
		t.Fatalf("expected non-nil binding, got nil")
	}

	// Compile-time check: binding implements CometInterface.
	var _ CometInterface = binding
}

func Test_newCometBinding_errorWhen_invalidAddress(t *testing.T) {
	var client *evm.Client = nil
	addr := "not-an-address"

	binding, err := newCometBinding(client, addr)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if binding != nil {
		t.Fatalf("expected nil binding on error, got non-nil")
	}
	if !strings.Contains(err.Error(), "invalid Comet address: "+addr) {
		t.Fatalf("unexpected error: %v", err)
	}
}

func Test_newCometBinding_errorWhen_emptyAddress(t *testing.T) {
	var client *evm.Client = nil
	addr := ""

	binding, err := newCometBinding(client, addr)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if binding != nil {
		t.Fatalf("expected nil binding on error, got non-nil")
	}
	if !strings.Contains(err.Error(), "invalid Comet address: ") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func Test_newCometBinding_errorWhen_addressTooShort(t *testing.T) {
	var client *evm.Client = nil
	addr := "0x1234"

	binding, err := newCometBinding(client, addr)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if binding != nil {
		t.Fatalf("expected nil binding on error, got non-nil")
	}
	if !strings.Contains(err.Error(), "invalid Comet address: "+addr) {
		t.Fatalf("unexpected error: %v", err)
	}
}

func Test_newCometBinding_errorWhen_addressTooLong(t *testing.T) {
	var client *evm.Client = nil
	addr := "0x00000000000000000000000000000000000000000000000000000000000000001"

	binding, err := newCometBinding(client, addr)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if binding != nil {
		t.Fatalf("expected nil binding on error, got non-nil")
	}
	if !strings.Contains(err.Error(), "invalid Comet address: "+addr) {
		t.Fatalf("unexpected error: %v", err)
	}
}