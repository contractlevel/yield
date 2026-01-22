package aaveV3

import (
	"strings"
	"testing"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
)

func Test_newPoolAddressesProviderBinding_success(t *testing.T) {
	var client *evm.Client = nil
	addr := "0x0000000000000000000000000000000000000001"

	binding, err := newPoolAddressesProviderBinding(client, addr)
	if err != nil {
		t.Fatalf("expected nil error, got: %v", err)
	}
	if binding == nil {
		t.Fatalf("expected non-nil binding, got nil")
	}
	var _ PoolAddressesProviderInterface = binding
}

func Test_newPoolAddressesProviderBinding_errorWhen_invalidAddress(t *testing.T) {
	var client *evm.Client = nil
	addr := "not-an-address"

	binding, err := newPoolAddressesProviderBinding(client, addr)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if binding != nil {
		t.Fatalf("expected nil binding on error, got non-nil")
	}
	if !strings.Contains(err.Error(), "invalid PoolAddressesProvider address: "+addr) {
		t.Fatalf("unexpected error: %v", err)
	}
}

func Test_newAaveProtocolDataProviderBinding_success(t *testing.T) {
	var client *evm.Client = nil
	addr := "0x0000000000000000000000000000000000000001"

	binding, err := newAaveProtocolDataProviderBinding(client, addr)
	if err != nil {
		t.Fatalf("expected nil error, got: %v", err)
	}
	if binding == nil {
		t.Fatalf("expected non-nil binding, got nil")
	}

	var _ AaveProtocolDataProviderInterface = binding
}

func Test_newAaveProtocolDataProviderBinding_errorWhen_invalidAddress(t *testing.T) {
	var client *evm.Client = nil
	addr := "not-an-address"

	binding, err := newAaveProtocolDataProviderBinding(client, addr)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if binding != nil {
		t.Fatalf("expected nil binding on error, got non-nil")
	}
	if !strings.Contains(err.Error(), "invalid AaveProtocolDataProvider address: "+addr) {
		t.Fatalf("unexpected error: %v", err)
	}
}

func Test_newDefaultReserveInterestRateStrategyV2Binding_success(t *testing.T) {
	var client *evm.Client = nil
	addr := "0x0000000000000000000000000000000000000002"

	binding, err := newDefaultReserveInterestRateStrategyV2Binding(client, addr)
	if err != nil {
		t.Fatalf("expected nil error, got: %v", err)
	}
	if binding == nil {
		t.Fatalf("expected non-nil binding, got nil")
	}
	var _ DefaultReserveInterestRateStrategyV2Interface = binding
}

func Test_newDefaultReserveInterestRateStrategyV2Binding_errorWhen_invalidAddress(t *testing.T) {
	var client *evm.Client = nil
	addr := "still-not-an-address"

	binding, err := newDefaultReserveInterestRateStrategyV2Binding(client, addr)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if binding != nil {
		t.Fatalf("expected nil binding on error, got non-nil")
	}
	if !strings.Contains(err.Error(), "invalid DefaultReserveInterestRateStrategyV2 address: "+addr) {
		t.Fatalf("unexpected error: %v", err)
	}
}
