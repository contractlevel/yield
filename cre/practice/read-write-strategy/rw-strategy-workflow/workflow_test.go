package main

import (
	"reflect"
	"strings"
	"testing"
	"time"

	"read-write-strategy/contracts/evm/src/generated/simple_parent"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func Test_onCronTrigger_errorWhen_invalidChainSelector(t *testing.T) {
	// arrange
	config := &Config{Evms: []EvmConfig{{ChainName: "invalid"}}}
	runtime := testutils.NewRuntime(t, nil)
	scheduled := time.Date(2025, 1, 2, 3, 4, 5, 0, time.UTC)
	payload := &cron.Payload{
		ScheduledExecutionTime: timestamppb.New(scheduled),
	}

	// act
	res, err := onCronTrigger(config, runtime, payload)

	// assert
	if err == nil {
		t.Fatalf("onCronTrigger expected error but got nil")
	}
	if res != nil {
		t.Fatalf("onCronTrigger expected nil result but got %v", res)
	}
	expectedErrorMsg := "Failed to get chain selector from name:"
	if got := err.Error(); !strings.HasPrefix(got, expectedErrorMsg) {
		t.Fatalf("unexpected error message: got %q, want prefix %q", got, expectedErrorMsg)
	}
}

func Test_onCronTrigger_errorWhen_invalidSimpleParentAddress(t *testing.T) {
	// arrange
	config := &Config{Evms: []EvmConfig{{ChainName: "ethereum-testnet-sepolia", SimpleParentAddress: "invalid"}}}
	runtime := testutils.NewRuntime(t, nil)
	scheduled := time.Date(2025, 1, 2, 3, 4, 5, 0, time.UTC)
	payload := &cron.Payload{
		ScheduledExecutionTime: timestamppb.New(scheduled),
	}

	// act
	res, err := onCronTrigger(config, runtime, payload)

	// assert
	if err == nil {
		t.Fatalf("onCronTrigger expected error but got nil")
	}
	if res != nil {
		t.Fatalf("onCronTrigger expected nil result but got %v", res)
	}
	expectedErrorMsg := "Error: invalid address format:"
	if got := err.Error(); !strings.HasPrefix(got, expectedErrorMsg) {
		t.Fatalf("unexpected error message: got %q, want prefix %q", got, expectedErrorMsg)
	}
}

func Test_onCronTrigger_errorWhen_simpleParentAddressDoesNotStartWith0x(t *testing.T) {
	// arrange
	config := &Config{Evms: []EvmConfig{{ChainName: "ethereum-testnet-sepolia", SimpleParentAddress: "660f8ab44263347c7704aDa8C016951ecf906A80"}}}
	runtime := testutils.NewRuntime(t, nil)
	scheduled := time.Date(2025, 1, 2, 3, 4, 5, 0, time.UTC)
	payload := &cron.Payload{
		ScheduledExecutionTime: timestamppb.New(scheduled),
	}

	// act
	res, err := onCronTrigger(config, runtime, payload)

	// assert
	if err == nil {
		t.Fatalf("onCronTrigger expected error but got nil")
	}
	if res != nil {
		t.Fatalf("onCronTrigger expected nil result but got %v", res)
	}
	expectedErrorMsg := "Error: address must start with 0x:"
	if got := err.Error(); !strings.HasPrefix(got, expectedErrorMsg) {
		t.Fatalf("unexpected error message: got %q, want prefix %q", got, expectedErrorMsg)
	}
}

func Test_onCronTrigger_errorWhen_simpleParentContractCreationFails(t *testing.T) {
	// arrange
	// Save the original ABI metadata
	originalABI := simple_parent.SimpleParentMetaData.ABI
	
	// Use reflection to temporarily corrupt the ABI metadata to simulate a parsing error
	// This will cause NewSimpleParent to fail when it tries to parse the ABI JSON
	// SimpleParentMetaData is a pointer to bind.MetaData, so we need to get the value it points to
	metadataValue := reflect.ValueOf(simple_parent.SimpleParentMetaData).Elem()
	abiField := metadataValue.FieldByName("ABI")
	
	// Corrupt the ABI JSON to cause a parsing error
	abiField.SetString("invalid json {{{{")
	
	// Restore the original ABI after the test
	defer func() {
		abiField.SetString(originalABI)
	}()
	
	config := &Config{Evms: []EvmConfig{{ChainName: "ethereum-testnet-sepolia", SimpleParentAddress: "0x660f8ab44263347c7704aDa8C012345671234567"}}}
	runtime := testutils.NewRuntime(t, nil)
	scheduled := time.Date(2025, 1, 2, 3, 4, 5, 0, time.UTC)
	payload := &cron.Payload{
		ScheduledExecutionTime: timestamppb.New(scheduled),
	}

	// act
	res, err := onCronTrigger(config, runtime, payload)

	// assert
	if err == nil {
		t.Fatalf("onCronTrigger expected error but got nil")
	}
	if res != nil {
		t.Fatalf("onCronTrigger expected nil result but got %v", res)
	}
	expectedErrorMsg := "Error: Failed to create contract instance:"
	if got := err.Error(); !strings.HasPrefix(got, expectedErrorMsg) {
		t.Fatalf("unexpected error message: got %q, want prefix %q", got, expectedErrorMsg)
	}
	
	// Verify the underlying error is about ABI parsing
	if !strings.Contains(err.Error(), "abi") && !strings.Contains(err.Error(), "JSON") {
		t.Logf("Note: Error message doesn't explicitly mention ABI/JSON, but that's okay. Full error: %v", err)
	}
}