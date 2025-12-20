package aaveV3

import (
	"strings"
	"testing"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
)

func Test_NewAaveProtocolDataProviderBinding_success(t *testing.T) {
	var client *evm.Client = nil
	addr := "0x0000000000000000000000000000000000000001"

	binding, err := NewAaveProtocolDataProviderBinding(client, addr)
	if err != nil {
		t.Fatalf("expected nil error, got: %v", err)
	}
	if binding == nil {
		t.Fatalf("expected non-nil binding, got nil")
	}

	var _ AaveProtocolDataProviderInterface = binding
}

func Test_NewAaveProtocolDataProviderBinding_errorWhen_invalidAddress(t *testing.T) {
	var client *evm.Client = nil
	addr := "not-an-address"

	binding, err := NewAaveProtocolDataProviderBinding(client, addr)
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

func Test_NewDefaultReserveInterestRateStrategyBinding_success(t *testing.T) {
	var client *evm.Client = nil
	addr := "0x0000000000000000000000000000000000000002"

	binding, err := NewDefaultReserveInterestRateStrategyBinding(client, addr)
	if err != nil {
		t.Fatalf("expected nil error, got: %v", err)
	}
	if binding == nil {
		t.Fatalf("expected non-nil binding, got nil")
	}
	var _ DefaultReserveInterestRateStrategyInterface = binding
}

func Test_NewDefaultReserveInterestRateStrategyBinding_errorWhen_invalidAddress(t *testing.T) {
	var client *evm.Client = nil
	addr := "still-not-an-address"

	binding, err := NewDefaultReserveInterestRateStrategyBinding(client, addr)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if binding != nil {
		t.Fatalf("expected nil binding on error, got non-nil")
	}
	if !strings.Contains(err.Error(), "invalid DefaultReserveInterestRateStrategy address: "+addr) {
		t.Fatalf("unexpected error: %v", err)
	}
}
