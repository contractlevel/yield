package main

import (
	"strings"
	"testing"
	"time"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func Test_onCronTrigger_errorWhen_noEvmConfigsProvided(t *testing.T) {
	// arrange
	config := &Config{Evms: []EvmConfig{}}
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
	expectedErrorMsg := "no EVM configs provided"
	if got := err.Error(); !strings.HasPrefix(got, expectedErrorMsg) {
		t.Fatalf("unexpected error message: got %q, want prefix %q", got, expectedErrorMsg)
	}
}