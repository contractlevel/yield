package main

import (
	"fmt"
	"log/slog"
	"math/big"
	"strings"
	"testing"

	"cre-rebalance/cre-rebalance-workflow/internal/helper"
	"cre-rebalance/cre-rebalance-workflow/internal/onchain"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"google.golang.org/protobuf/types/known/timestamppb"
)

/*//////////////////////////////////////////////////////////////
                   TEST HELPERS
//////////////////////////////////////////////////////////////*/

func newPayloadNow() *cron.Payload {
	return &cron.Payload{
		ScheduledExecutionTime: timestamppb.Now(),
	}
}

/*//////////////////////////////////////////////////////////////
                   TESTS FOR ON CRON TRIGGER
//////////////////////////////////////////////////////////////*/

func Test_onCronTrigger_errorWhen_noEvmConfigsProvided(t *testing.T) {
	config := &helper.Config{Evms: []helper.EvmConfig{}}
	runtime := testutils.NewRuntime(t, nil)

	res, err := onCronTrigger(config, runtime, newPayloadNow())
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if res != nil {
		t.Fatalf("expected nil result, got %v", res)
	}
	if got, want := err.Error(), "no EVM configs provided"; !strings.HasPrefix(got, want) {
		t.Fatalf("unexpected error: got %q, want prefix %q", got, want)
	}
}

func Test_onCronTriggerWithDeps_errorWhen_ParentPeerBindingFails(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:        "parent-chain",
				ChainSelector:    1,
				YieldPeerAddress: "0xparent",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	deps := OnCronDeps{
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, fmt.Errorf("parent-binding-failed")
		},
		// remaining deps are irrelevant because we fail before using them
	}

	res, err := onCronTriggerWithDeps(config, runtime, newPayloadNow(), deps)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if res != nil {
		t.Fatalf("expected nil result, got %v", res)
	}
	if !strings.Contains(err.Error(), "failed to create ParentPeer binding: parent-binding-failed") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func Test_onCronTriggerWithDeps_errorWhen_ReadCurrentStrategyFails(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:        "parent-chain",
				ChainSelector:    1,
				YieldPeerAddress: "0xparent",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	deps := OnCronDeps{
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return onchain.Strategy{}, fmt.Errorf("read-strategy-failed")
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

func Test_onCronTriggerWithDeps_errorWhen_GetOptimalStrategyFails(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:        "parent-chain",
				ChainSelector:    1,
				YieldPeerAddress: "0xparent",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	cur := onchain.Strategy{
		ChainSelector: 1,
	}

	deps := OnCronDeps{
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return cur, nil
		},
		GetOptimalStrategy: func(_ *helper.Config, _ cre.Runtime) (onchain.Strategy, error) {
			return onchain.Strategy{}, fmt.Errorf("optimal-failed")
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			t.Fatalf("ReadTVL should not be called when GetOptimalStrategy fails")
			return nil, nil
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			t.Fatalf("WriteRebalance should not be called when GetOptimalStrategy fails")
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
	if !strings.Contains(err.Error(), "failed to get optimal strategy: optimal-failed") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func Test_onCronTriggerWithDeps_success_noRebalanceWhenStrategyUnchanged(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:        "parent-chain",
				ChainSelector:    1,
				YieldPeerAddress: "0xparent",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	strat := onchain.Strategy{
		ChainSelector: 1,
	}

	deps := OnCronDeps{
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return strat, nil
		},
		GetOptimalStrategy: func(_ *helper.Config, _ cre.Runtime) (onchain.Strategy, error) {
			return strat, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			t.Fatalf("ReadTVL should not be called when strategy is unchanged")
			return nil, nil
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			t.Fatalf("WriteRebalance should not be called when strategy is unchanged")
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
	if res.Current != strat || res.Optimal != strat {
		t.Fatalf("unexpected result: %+v", res)
	}
}

func Test_onCronTriggerWithDeps_errorWhen_NoConfigForStrategyChain(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:        "parent-chain",
				ChainSelector:    1,
				YieldPeerAddress: "0xparent",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	cur := onchain.Strategy{
		ProtocolId:    [32]byte{1},
		ChainSelector: 999, // no matching EvmConfig
	}
	opt := onchain.Strategy{
		ProtocolId:    [32]byte{2},
		ChainSelector: 1,
	}

	deps := OnCronDeps{
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return cur, nil
		},
		GetOptimalStrategy: func(_ *helper.Config, _ cre.Runtime) (onchain.Strategy, error) {
			return opt, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			t.Fatalf("ReadTVL should not be called when no EVM config exists for strategy chain")
			return nil, nil
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			t.Fatalf("WriteRebalance should not be called when no EVM config exists for strategy chain")
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

func Test_onCronTriggerWithDeps_errorWhen_ChildPeerBindingFails(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:        "parent-chain",
				ChainSelector:    1,
				YieldPeerAddress: "0xparent",
			},
			{
				ChainName:        "child-chain",
				ChainSelector:    2,
				YieldPeerAddress: "0xchild",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	cur := onchain.Strategy{
		ProtocolId:    [32]byte{1},
		ChainSelector: 2,
	}
	opt := onchain.Strategy{
		ProtocolId:    [32]byte{2},
		ChainSelector: 1,
	}

	deps := OnCronDeps{
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		NewChildPeerBinding: func(_ *evm.Client, _ string) (onchain.YieldPeerInterface, error) {
			return nil, fmt.Errorf("child-binding-failed")
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return cur, nil
		},
		GetOptimalStrategy: func(_ *helper.Config, _ cre.Runtime) (onchain.Strategy, error) {
			return opt, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			t.Fatalf("ReadTVL should not be called when ChildPeer binding fails")
			return nil, nil
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			t.Fatalf("WriteRebalance should not be called when ChildPeer binding fails")
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
	if !strings.Contains(err.Error(), "failed to create strategy YieldPeer binding: child-binding-failed") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func Test_onCronTriggerWithDeps_errorWhen_ReadTVLFails_sameChain(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:        "parent-chain",
				ChainSelector:    1,
				YieldPeerAddress: "0xparent",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	cur := onchain.Strategy{
		ProtocolId:    [32]byte{1},
		ChainSelector: 1,
	}
	opt := onchain.Strategy{
		ProtocolId:    [32]byte{2},
		ChainSelector: 1,
	}

	deps := OnCronDeps{
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return cur, nil
		},
		GetOptimalStrategy: func(_ *helper.Config, _ cre.Runtime) (onchain.Strategy, error) {
			return opt, nil
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

func Test_onCronTriggerWithDeps_errorWhen_OptimalAPYCalculationFails(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:        "parent-chain",
				ChainSelector:    1,
				YieldPeerAddress: "0xparent",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	cur := onchain.Strategy{ProtocolId: [32]byte{1}, ChainSelector: 1}
	opt := onchain.Strategy{ProtocolId: [32]byte{2}, ChainSelector: 1}

	deps := OnCronDeps{
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return cur, nil
		},
		GetOptimalStrategy: func(_ *helper.Config, _ cre.Runtime) (onchain.Strategy, error) {
			return opt, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			return big.NewInt(123), nil
		},
		CalculateAPYForStrategy: func(_ *helper.Config, _ cre.Runtime, s onchain.Strategy, _ *big.Int) (float64, error) {
			if s == opt {
				return 0.0, fmt.Errorf("optimal-apy-failed")
			}
			return 0.0, nil
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			t.Fatalf("WriteRebalance should not be called when optimal APY calculation fails")
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
	if !strings.Contains(err.Error(), "failed to calculate optimal strategy APY: optimal-apy-failed") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func Test_onCronTriggerWithDeps_errorWhen_CurrentAPYCalculationFails(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:        "parent-chain",
				ChainSelector:    1,
				YieldPeerAddress: "0xparent",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	cur := onchain.Strategy{ProtocolId: [32]byte{1}, ChainSelector: 1}
	opt := onchain.Strategy{ProtocolId: [32]byte{2}, ChainSelector: 1}

	deps := OnCronDeps{
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return cur, nil
		},
		GetOptimalStrategy: func(_ *helper.Config, _ cre.Runtime) (onchain.Strategy, error) {
			return opt, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			return big.NewInt(456), nil
		},
		CalculateAPYForStrategy: func(_ *helper.Config, _ cre.Runtime, s onchain.Strategy, _ *big.Int) (float64, error) {
			if s == cur {
				return 0.0, fmt.Errorf("current-apy-failed")
			}
			return 0.0, nil
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			t.Fatalf("WriteRebalance should not be called when current APY calculation fails")
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
	if !strings.Contains(err.Error(), "failed to calculate current strategy APY: current-apy-failed") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func Test_onCronTriggerWithDeps_success_noRebalanceWhenDeltaBelowThreshold(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:        "parent-chain",
				ChainSelector:    1,
				YieldPeerAddress: "0xparent",
				GasLimit:         500000,
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	cur := onchain.Strategy{ProtocolId: [32]byte{1}, ChainSelector: 1}
	opt := onchain.Strategy{ProtocolId: [32]byte{2}, ChainSelector: 1}

	writeCalled := false

	deps := OnCronDeps{
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return cur, nil
		},
		GetOptimalStrategy: func(_ *helper.Config, _ cre.Runtime) (onchain.Strategy, error) {
			return opt, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			return big.NewInt(1000), nil
		},
		// Choose APYs so that delta = optimal - current = 0.01 - 0.02 = -0.01 < threshold(0.01).
		CalculateAPYForStrategy: func(_ *helper.Config, _ cre.Runtime, s onchain.Strategy, _ *big.Int) (float64, error) {
			if s == opt {
				return 0.01, nil
			}
			if s == cur {
				return 0.02, nil
			}
			return 0.0, nil
		},
		NewRebalancerBinding: func(_ *evm.Client, _ string) (onchain.RebalancerInterface, error) {
			t.Fatalf("NewRebalancerBinding should not be called when delta < threshold")
			return nil, nil
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
		t.Fatalf("expected Updated=false when delta < threshold")
	}
	if writeCalled {
		t.Fatalf("WriteRebalance should not be called when delta < threshold")
	}
	if res.Current != cur || res.Optimal != opt {
		t.Fatalf("unexpected result: %+v", res)
	}
}

func Test_onCronTriggerWithDeps_errorWhen_RebalancerBindingFails(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:         "parent-chain",
				ChainSelector:     1,
				YieldPeerAddress:  "0xparent",
				RebalancerAddress: "0xrebalancer",
				GasLimit:          500000,
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	cur := onchain.Strategy{ProtocolId: [32]byte{1}, ChainSelector: 1}
	opt := onchain.Strategy{ProtocolId: [32]byte{2}, ChainSelector: 1}

	deps := OnCronDeps{
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return cur, nil
		},
		GetOptimalStrategy: func(_ *helper.Config, _ cre.Runtime) (onchain.Strategy, error) {
			return opt, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			return big.NewInt(1000), nil
		},
		// delta = 0.02 - 0.01 = 0.01 >= threshold(0.01)
		CalculateAPYForStrategy: func(_ *helper.Config, _ cre.Runtime, s onchain.Strategy, _ *big.Int) (float64, error) {
			if s == opt {
				return 0.02, nil
			}
			if s == cur {
				return 0.01, nil
			}
			return 0.0, nil
		},
		NewRebalancerBinding: func(_ *evm.Client, _ string) (onchain.RebalancerInterface, error) {
			return nil, fmt.Errorf("rebalancer-binding-failed")
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			t.Fatalf("WriteRebalance should not be called when Rebalancer binding fails")
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
	if !strings.Contains(err.Error(), "failed to create parent Rebalancer binding: rebalancer-binding-failed") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func Test_onCronTriggerWithDeps_errorWhen_WriteRebalanceFails(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:         "parent-chain",
				ChainSelector:     1,
				YieldPeerAddress:  "0xparent",
				RebalancerAddress: "0xrebalancer",
				GasLimit:          500000,
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	cur := onchain.Strategy{ProtocolId: [32]byte{1}, ChainSelector: 1}
	opt := onchain.Strategy{ProtocolId: [32]byte{2}, ChainSelector: 1}

	deps := OnCronDeps{
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return cur, nil
		},
		GetOptimalStrategy: func(_ *helper.Config, _ cre.Runtime) (onchain.Strategy, error) {
			return opt, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			return big.NewInt(1000), nil
		},
		// delta = 0.02 - 0.01 = 0.01 >= threshold(0.01)
		CalculateAPYForStrategy: func(_ *helper.Config, _ cre.Runtime, s onchain.Strategy, _ *big.Int) (float64, error) {
			if s == opt {
				return 0.02, nil
			}
			if s == cur {
				return 0.01, nil
			}
			return 0.0, nil
		},
		NewRebalancerBinding: func(_ *evm.Client, _ string) (onchain.RebalancerInterface, error) {
			return nil, nil
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
	if !strings.Contains(err.Error(), "failed to rebalance: rebalance-failed") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func Test_onCronTriggerWithDeps_success_rebalanceWhenStrategyChanges_sameChain(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:         "parent-chain",
				ChainSelector:     1,
				YieldPeerAddress:  "0xparent",
				RebalancerAddress: "0xrebalancer",
				GasLimit:          500000,
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	cur := onchain.Strategy{ProtocolId: [32]byte{1}, ChainSelector: 1}
	opt := onchain.Strategy{ProtocolId: [32]byte{2}, ChainSelector: 1}

	writeCalls := 0
	var lastOptimal onchain.Strategy
	var lastGasLimit uint64

	deps := OnCronDeps{
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return cur, nil
		},
		GetOptimalStrategy: func(_ *helper.Config, _ cre.Runtime) (onchain.Strategy, error) {
			return opt, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			return big.NewInt(1000), nil
		},
		// delta = 0.02 - 0.01 = 0.01 >= threshold(0.01)
		CalculateAPYForStrategy: func(_ *helper.Config, _ cre.Runtime, s onchain.Strategy, _ *big.Int) (float64, error) {
			if s == opt {
				return 0.02, nil
			}
			if s == cur {
				return 0.01, nil
			}
			return 0.0, nil
		},
		NewRebalancerBinding: func(_ *evm.Client, _ string) (onchain.RebalancerInterface, error) {
			return nil, nil
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, gasLimit uint64, optimal onchain.Strategy) error {
			writeCalls++
			lastGasLimit = gasLimit
			lastOptimal = optimal
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
		t.Fatalf("expected Updated=true when strategies differ and delta >= threshold")
	}
	if writeCalls != 1 {
		t.Fatalf("expected WriteRebalance to be called once, got %d", writeCalls)
	}
	if lastOptimal != opt {
		t.Fatalf("unexpected optimal passed to WriteRebalance: got %+v, want %+v", lastOptimal, opt)
	}
	if lastGasLimit != config.Evms[0].GasLimit {
		t.Fatalf("unexpected gasLimit passed to WriteRebalance: got %d, want %d", lastGasLimit, config.Evms[0].GasLimit)
	}
	if res.Current != cur || res.Optimal != opt {
		t.Fatalf("unexpected result: %+v", res)
	}
}

func Test_onCronTriggerWithDeps_success_rebalanceWhenStrategyChanges_differentChain(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:         "parent-chain",
				ChainSelector:     1,
				YieldPeerAddress:  "0xparent",
				RebalancerAddress: "0xrebalancer",
				GasLimit:          500000,
			},
			{
				ChainName:        "child-chain",
				ChainSelector:    2,
				YieldPeerAddress: "0xchild",
				GasLimit:         777000,
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	cur := onchain.Strategy{ProtocolId: [32]byte{1}, ChainSelector: 2}
	opt := onchain.Strategy{ProtocolId: [32]byte{2}, ChainSelector: 1}

	writeCalls := 0
	var lastOptimal onchain.Strategy
	var lastGasLimit uint64

	deps := OnCronDeps{
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		NewChildPeerBinding: func(_ *evm.Client, _ string) (onchain.YieldPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return cur, nil
		},
		GetOptimalStrategy: func(_ *helper.Config, _ cre.Runtime) (onchain.Strategy, error) {
			return opt, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			return big.NewInt(1000), nil
		},
		// delta = 0.03 - 0.01 = 0.02 >= threshold(0.01)
		CalculateAPYForStrategy: func(_ *helper.Config, _ cre.Runtime, s onchain.Strategy, _ *big.Int) (float64, error) {
			if s == opt {
				return 0.03, nil
			}
			if s == cur {
				return 0.01, nil
			}
			return 0.0, nil
		},
		NewRebalancerBinding: func(_ *evm.Client, _ string) (onchain.RebalancerInterface, error) {
			return nil, nil
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, gasLimit uint64, optimal onchain.Strategy) error {
			writeCalls++
			lastGasLimit = gasLimit
			lastOptimal = optimal
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
		t.Fatalf("expected Updated=true when strategies differ and delta >= threshold")
	}
	if writeCalls != 1 {
		t.Fatalf("expected WriteRebalance to be called once, got %d", writeCalls)
	}
	if lastOptimal != opt {
		t.Fatalf("unexpected optimal passed to WriteRebalance: got %+v, want %+v", lastOptimal, opt)
	}
	if lastGasLimit != config.Evms[1].GasLimit {
		t.Fatalf("unexpected gasLimit passed to WriteRebalance: got %d, want %d", lastGasLimit, config.Evms[1].GasLimit)
	}
	if res.Current != cur || res.Optimal != opt {
		t.Fatalf("unexpected result: %+v", res)
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

	if len(wf) != 1 {
		t.Fatalf("expected 1 handler, got %d", len(wf))
	}
}
