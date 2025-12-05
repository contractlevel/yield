package main

import (
	"strings"
	"testing"
	"time"

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
	expectedErrorMsg := "Failed to create contract instance: invalid address format:"
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
	expectedErrorMsg := "Failed to create contract instance: address must start with 0x:"
	if got := err.Error(); !strings.HasPrefix(got, expectedErrorMsg) {
		t.Fatalf("unexpected error message: got %q, want prefix %q", got, expectedErrorMsg)
	}
}