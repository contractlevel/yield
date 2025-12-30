package main

import (
	"strings"
	"testing"
	"time"
	"fmt"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"google.golang.org/protobuf/types/known/timestamppb"
)

/*//////////////////////////////////////////////////////////////
                   TESTS FOR ON CRON TRIGGER
//////////////////////////////////////////////////////////////*/
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

func Test_onCronTrigger_errorWhen_invalidParentPeerAddress(t *testing.T) {
	// arrange
	config := &Config{Evms: []EvmConfig{{ChainName: "ethereum-testnet-sepolia", YieldPeerAddress: "invalid"}}}
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
	expectedErrorMsg := "invalid YieldPeer address: invalid"
	if got := err.Error(); !strings.HasPrefix(got, expectedErrorMsg) {
		t.Fatalf("unexpected error message: got %q, want prefix %q", got, expectedErrorMsg)
	}
}

/*//////////////////////////////////////////////////////////////
              TESTS FOR DECIDE AND MAYBE REBALANCE
//////////////////////////////////////////////////////////////*/
func Test_decideAndMaybeRebalance_writeFn_notCalledWhen_currentStrategyIsOptimal(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)
	logger := runtime.Logger()

	current := Strategy{
		ProtocolId:    [32]byte{1},
		ChainSelector: 10,
	}
	optimal := current // identical

	called := false
	writeFn := func(opt Strategy) error {
		called = true
		return nil
	}

	res, err := decideAndMaybeRebalance(logger, current, optimal, writeFn)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if called {
		t.Fatalf("writeFn should not be called when strategies are equal")
	}
	if res == nil {
		t.Fatalf("expected non-nil result")
	}
	if res.Updated {
		t.Fatalf("expected Updated=false when strategies are equal")
	}
	if res.Current != current || res.Optimal != optimal {
		t.Fatalf("unexpected result strategies: got %+v", res)
	}
}

func Test_decideAndMaybeRebalance_writeFn_calledWhen_currentStrategyIsDifferentFromOptimal(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)
	logger := runtime.Logger()

	current := Strategy{
		ProtocolId:    [32]byte{1},
		ChainSelector: 10,
	}
	optimal := Strategy{
		ProtocolId:    [32]byte{2},
		ChainSelector: 10,
	}

	callCount := 0
	var received Strategy

	writeFn := func(opt Strategy) error {
		callCount++
		received = opt
		return nil
	}

	res, err := decideAndMaybeRebalance(logger, current, optimal, writeFn)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if callCount != 1 {
		t.Fatalf("expected writeFn to be called once, got %d", callCount)
	}
	if received != optimal {
		t.Fatalf("writeFn received unexpected strategy: got %+v, want %+v", received, optimal)
	}
	if res == nil {
		t.Fatalf("expected non-nil result")
	}
	if !res.Updated {
		t.Fatalf("expected Updated=true when strategies differ")
	}
	if res.Current != current || res.Optimal != optimal {
		t.Fatalf("unexpected result strategies: got %+v", res)
	}
}

func Test_decideAndMaybeRebalance_writeFn_errorIsPropagated(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)
	logger := runtime.Logger()

	current := Strategy{
		ProtocolId:    [32]byte{1},
		ChainSelector: 10,
	}
	optimal := Strategy{
		ProtocolId:    [32]byte{2},
		ChainSelector: 10,
	}

	expectedErr := fmt.Errorf("boom")
	writeFn := func(opt Strategy) error {
		return expectedErr
	}

	res, err := decideAndMaybeRebalance(logger, current, optimal, writeFn)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if !strings.Contains(err.Error(), "boom") {
		t.Fatalf("unexpected error: %v", err)
	}
	if res != nil {
		t.Fatalf("expected nil result when writeFn fails, got %+v", res)
	}
}

/*//////////////////////////////////////////////////////////////
          TESTS FOR FIND EVM CONFIG BY CHAIN SELECTOR
//////////////////////////////////////////////////////////////*/
func Test_findEvmConfigByChainSelector_found(t *testing.T) {
	evms := []EvmConfig{
		{ChainName: "chain-a", ChainSelector: 1},
		{ChainName: "chain-b", ChainSelector: 2},
	}

	cfg, err := findEvmConfigByChainSelector(evms, 2)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg == nil {
		t.Fatalf("expected non-nil config")
	}
	if cfg.ChainName != "chain-b" {
		t.Fatalf("expected chain-b, got %s", cfg.ChainName)
	}
}

func Test_findEvmConfigByChainSelector_notFound(t *testing.T) {
	evms := []EvmConfig{
		{ChainName: "chain-a", ChainSelector: 1},
	}

	cfg, err := findEvmConfigByChainSelector(evms, 999)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if cfg != nil {
		t.Fatalf("expected nil config when not found, got %+v", cfg)
	}
	if !strings.Contains(err.Error(), "no evm config found for chainSelector 999") {
		t.Fatalf("unexpected error message: %v", err)
	}
}
