package main

import (
	"fmt"
	"log/slog"
	"math/big"
	"strings"
	"testing"
	"time"

	"cre-rebalance/cre-rebalance-workflow/internal/onchain"
	"cre-rebalance/cre-rebalance-workflow/internal/helper"

	"github.com/ethereum/go-ethereum/crypto"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"google.golang.org/protobuf/types/known/timestamppb"
)

/*//////////////////////////////////////////////////////////////
                   TESTS FOR ON CRON TRIGGER (PUBLIC)
//////////////////////////////////////////////////////////////*/

func Test_onCronTrigger_errorWhen_noEvmConfigsProvided(t *testing.T) {
	config := &helper.Config{Evms: []helper.EvmConfig{}}
	runtime := testutils.NewRuntime(t, nil)
	scheduled := time.Date(2025, 1, 2, 3, 4, 5, 0, time.UTC)
	payload := &cron.Payload{
		ScheduledExecutionTime: timestamppb.New(scheduled),
	}

	res, err := onCronTrigger(config, runtime, payload)

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
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:        "ethereum-testnet-sepolia",
				ChainSelector:    1,
				YieldPeerAddress: "invalid",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)
	scheduled := time.Date(2025, 1, 2, 3, 4, 5, 0, time.UTC)
	payload := &cron.Payload{
		ScheduledExecutionTime: timestamppb.New(scheduled),
	}

	res, err := onCronTrigger(config, runtime, payload)

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
           TESTS FOR ON CRON TRIGGER WITH INJECTED DEPS
//////////////////////////////////////////////////////////////*/

func newPayloadNow() *cron.Payload {
	return &cron.Payload{ScheduledExecutionTime: timestamppb.Now()}
}

// Error when ReadCurrentStrategy fails
func Test_onCronTriggerWithDeps_errorWhen_ReadCurrentStrategyFails(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:        "ethereum-testnet-sepolia",
				ChainSelector:    1,
				YieldPeerAddress: "0x0000000000000000000000000000000000000001",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)
	deps := OnCronDeps{
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return onchain.Strategy{}, fmt.Errorf("read-strategy-failed")
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			t.Fatalf("ReadTVL should not be called when ReadCurrentStrategy fails")
			return nil, nil
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			t.Fatalf("WriteRebalance should not be called when ReadCurrentStrategy fails")
			return nil
		},
	}

	res, err := onCronTriggerWithDeps(config, runtime, newPayloadNow(), deps)

	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if res != nil {
		t.Fatalf("expected nil result, got %+v", res)
	}
	if !strings.Contains(err.Error(), "failed to read strategy from ParentPeer: read-strategy-failed") {
		t.Fatalf("unexpected error: %v", err)
	}
}

// Error when strategy lives on different chain and no config exists
func Test_onCronTriggerWithDeps_errorWhen_NoConfigForStrategyChain(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:        "parent-chain",
				ChainSelector:    1,
				YieldPeerAddress: "0x0000000000000000000000000000000000000001",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	deps := OnCronDeps{
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return onchain.Strategy{
				ProtocolId:    [32]byte{1},
				ChainSelector: 999, // no matching EvmConfig
			}, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			t.Fatalf("ReadTVL should not be called when no strategy-chain config exists")
			return nil, nil
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			t.Fatalf("WriteRebalance should not be called when no strategy-chain config exists")
			return nil
		},
	}

	res, err := onCronTriggerWithDeps(config, runtime, newPayloadNow(), deps)

	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if res != nil {
		t.Fatalf("expected nil result, got %+v", res)
	}
	if !strings.Contains(err.Error(), "no EVM config found for strategy chainSelector 999") {
		t.Fatalf("unexpected error: %v", err)
	}
}

// Error when strategy YieldPeer address is invalid (different chain)
func Test_onCronTriggerWithDeps_errorWhen_invalidStrategyYieldPeerAddress(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:        "parent-chain",
				ChainSelector:    1,
				YieldPeerAddress: "0x0000000000000000000000000000000000000001",
			},
			{
				ChainName:        "strategy-chain",
				ChainSelector:    2,
				YieldPeerAddress: "invalid", // invalid address
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	deps := OnCronDeps{
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return onchain.Strategy{
				ProtocolId:    [32]byte{1},
				ChainSelector: 2,
			}, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			t.Fatalf("ReadTVL should not be called when strategy YieldPeer address is invalid")
			return nil, nil
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			t.Fatalf("WriteRebalance should not be called when strategy YieldPeer address is invalid")
			return nil
		},
	}

	res, err := onCronTriggerWithDeps(config, runtime, newPayloadNow(), deps)

	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if res != nil {
		t.Fatalf("expected nil result, got %+v", res)
	}
	if !strings.Contains(err.Error(), "invalid YieldPeer address: invalid") {
		t.Fatalf("unexpected error: %v", err)
	}
}

// Error when ReadTVL fails (same chain → reuse parent peer)
func Test_onCronTriggerWithDeps_errorWhen_ReadTVLFails(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:        "parent-chain",
				ChainSelector:    1,
				YieldPeerAddress: "0x0000000000000000000000000000000000000001",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	deps := OnCronDeps{
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return onchain.Strategy{
				ProtocolId:    [32]byte{1},
				ChainSelector: 1, // same chain as parent
			}, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			return nil, fmt.Errorf("tvl-failed")
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			t.Fatalf("WriteRebalance should not be called when ReadTVL fails")
			return nil
		},
	}

	res, err := onCronTriggerWithDeps(config, runtime, newPayloadNow(), deps)

	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if res != nil {
		t.Fatalf("expected nil result, got %+v", res)
	}
	if !strings.Contains(err.Error(), "failed to get total value from strategy YieldPeer: tvl-failed") {
		t.Fatalf("unexpected error: %v", err)
	}
}

// Success path: current strategy already optimal → no rebalance
func Test_onCronTriggerWithDeps_success_noRebalanceWhenStrategyUnchanged(t *testing.T) {
	// Make current == optimal by matching CalculateOptimalStrategy's protocolId.
	// @review this needs to be revisited when we have a real APY model
	protocol := "dummy-protocol-v1"
	hashed := crypto.Keccak256([]byte(protocol))
	var protocolId [32]byte
	copy(protocolId[:], hashed)

	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:         "parent-chain",
				ChainSelector:     1,
				YieldPeerAddress:  "0x0000000000000000000000000000000000000001",
				RebalancerAddress: "0x0000000000000000000000000000000000000002", // valid but unused
				GasLimit:          500000,
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	writeCalled := false

	deps := OnCronDeps{
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return onchain.Strategy{
				ProtocolId:    protocolId,
				ChainSelector: 1,
			}, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			return big.NewInt(123), nil
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			writeCalled = true
			return nil
		},
	}

	res, err := onCronTriggerWithDeps(config, runtime, newPayloadNow(), deps)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if res == nil {
		t.Fatalf("expected non-nil result")
	}
	if res.Updated {
		t.Fatalf("expected Updated=false when strategies are equal")
	}
	if writeCalled {
		t.Fatalf("WriteRebalance should not be called when strategy is unchanged")
	}
}

// Success path: strategy changes and rebalance succeeds
func Test_onCronTriggerWithDeps_success_rebalanceWhenStrategyChanges(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:         "parent-chain",
				ChainSelector:     1,
				YieldPeerAddress:  "0x0000000000000000000000000000000000000001",
				RebalancerAddress: "0x0000000000000000000000000000000000000002",
				GasLimit:          500000,
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	writeCalls := 0
	var lastOptimal onchain.Strategy

	deps := OnCronDeps{
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			// Choose any protocolId that does NOT match the dummy-protocol-v1 hash.
			// @review this needs to be revisited when we have a real APY model
			return onchain.Strategy{
				ProtocolId:    [32]byte{1},
				ChainSelector: 1,
			}, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			return big.NewInt(456), nil
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, opt onchain.Strategy) error {
			writeCalls++
			lastOptimal = opt
			return nil
		},
	}

	res, err := onCronTriggerWithDeps(config, runtime, newPayloadNow(), deps)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if res == nil {
		t.Fatalf("expected non-nil result")
	}
	if !res.Updated {
		t.Fatalf("expected Updated=true when strategies differ")
	}
	if writeCalls != 1 {
		t.Fatalf("expected WriteRebalance to be called once, got %d", writeCalls)
	}
	if lastOptimal != res.Optimal {
		t.Fatalf("WriteRebalance received unexpected optimal strategy: got %+v, want %+v", lastOptimal, res.Optimal)
	}
}

// Error when WriteRebalance fails
func Test_onCronTriggerWithDeps_errorWhen_WriteRebalanceFails(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:         "parent-chain",
				ChainSelector:     1,
				YieldPeerAddress:  "0x0000000000000000000000000000000000000001",
				RebalancerAddress: "0x0000000000000000000000000000000000000002",
				GasLimit:          500000,
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	deps := OnCronDeps{
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return onchain.Strategy{
				ProtocolId:    [32]byte{1},
				ChainSelector: 1,
			}, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			return big.NewInt(789), nil
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			return fmt.Errorf("rebalance-failed")
		},
	}

	res, err := onCronTriggerWithDeps(config, runtime, newPayloadNow(), deps)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if res != nil {
		t.Fatalf("expected nil result, got %+v", res)
	}
	if !strings.Contains(err.Error(), "rebalance-failed") {
		t.Fatalf("unexpected error message: %v", err)
	}
}

// Error when RebalancerAddress is invalid (rebalance path)
func Test_onCronTriggerWithDeps_errorWhen_invalidRebalancerAddress(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:         "parent-chain",
				ChainSelector:     1,
				YieldPeerAddress:  "0x0000000000000000000000000000000000000001",
				RebalancerAddress: "invalid-rebalancer",
				GasLimit:          500000,
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	deps := OnCronDeps{
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return onchain.Strategy{
				ProtocolId:    [32]byte{1},
				ChainSelector: 1,
			}, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			return big.NewInt(111), nil
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			t.Fatalf("WriteRebalance should not be called when RebalancerAddress is invalid")
			return nil
		},
	}

	res, err := onCronTriggerWithDeps(config, runtime, newPayloadNow(), deps)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if res != nil {
		t.Fatalf("expected nil result, got %+v", res)
	}
	if !strings.Contains(err.Error(), "invalid Rebalancer address: invalid-rebalancer") {
		t.Fatalf("unexpected error: %v", err)
	}
}

/*//////////////////////////////////////////////////////////////
                    TESTS FOR INIT WORKFLOW
//////////////////////////////////////////////////////////////*/

func Test_InitWorkflow_setsUpCronHandler(t *testing.T) {
	config := &helper.Config{
		Schedule: "0 */1 * * * *",
	}
	logger := testutils.NewRuntime(t, nil).Logger()

	wf, err := InitWorkflow(config, logger, nil)
	if err != nil {
		t.Fatalf("InitWorkflow returned error: %v", err)
	}

	// Sanity: workflow should have at least one handler
	if len(wf) != 1 {
		t.Fatalf("expected 1 handler, got %d", len(wf))
	}
}
