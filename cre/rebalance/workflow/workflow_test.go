package main

import (
	"fmt"
	"log/slog"
	"math/big"
	"strings"
	"testing"

	"rebalance/workflow/internal/helper"
	"rebalance/workflow/internal/onchain"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"
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

	require.Error(t, err)
	require.Nil(t, res)
	require.True(t, strings.HasPrefix(err.Error(), "no EVM configs provided"),
		"unexpected error: %v", err)
}

func Test_onCronTriggerWithDeps_errorWhen_InitSupportedStrategiesFails(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{{
			ChainName:        "parent-chain",
			ChainSelector:    1,
			YieldPeerAddress: "0xparent",
		}},
	}
	runtime := testutils.NewRuntime(t, nil)

	expectedErr := fmt.Errorf("init-strategies-failed")

	deps := OnCronDeps{
		InitSupportedStrategies: func(_ *helper.Config) error {
			return expectedErr
		},
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			require.FailNow(t, "NewParentPeerBinding should not be called when InitSupportedStrategies fails")
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			require.FailNow(t, "ReadCurrentStrategy should not be called when InitSupportedStrategies fails")
			return onchain.Strategy{}, nil
		},
	}

	res, err := onCronTriggerWithDeps(config, runtime, newPayloadNow(), deps)

	require.Error(t, err)
	require.Nil(t, res)
	require.Contains(t, err.Error(), "failed to initialize supported strategies: init-strategies-failed")
}

func Test_onCronTriggerWithDeps_errorWhen_ParentPeerBindingFails(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{{
			ChainName:        "parent-chain",
			ChainSelector:    1,
			YieldPeerAddress: "0xparent",
		}},
	}
	runtime := testutils.NewRuntime(t, nil)

	deps := OnCronDeps{
		InitSupportedStrategies: func(_ *helper.Config) error {
			return nil
		},
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, fmt.Errorf("parent-binding-failed")
		},
	}

	res, err := onCronTriggerWithDeps(config, runtime, newPayloadNow(), deps)

	require.Error(t, err)
	require.Nil(t, res)
	require.Contains(t, err.Error(), "failed to create ParentPeer binding: parent-binding-failed")
}

func Test_onCronTriggerWithDeps_errorWhen_ReadCurrentStrategyFails(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{{
			ChainName:        "parent-chain",
			ChainSelector:    1,
			YieldPeerAddress: "0xparent",
		}},
	}
	runtime := testutils.NewRuntime(t, nil)

	deps := OnCronDeps{
		InitSupportedStrategies: func(_ *helper.Config) error {
			return nil
		},
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return onchain.Strategy{}, fmt.Errorf("read-strategy-failed")
		},
	}

	res, err := onCronTriggerWithDeps(config, runtime, newPayloadNow(), deps)

	require.Error(t, err)
	require.Nil(t, res)
	require.Contains(t, err.Error(), "failed to read strategy from ParentPeer: read-strategy-failed")
}

func Test_onCronTriggerWithDeps_errorWhen_GetOptimalAndCurrentStrategyWithAPYFails(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{{
			ChainName:        "parent-chain",
			ChainSelector:    1,
			YieldPeerAddress: "0xparent",
		}},
	}
	runtime := testutils.NewRuntime(t, nil)

	cur := onchain.Strategy{ChainSelector: 1}

	deps := OnCronDeps{
		InitSupportedStrategies: func(_ *helper.Config) error {
			return nil
		},
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return cur, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			return big.NewInt(1000), nil
		},
		GetOptimalAndCurrentStrategyWithAPY: func(_ *helper.Config, _ cre.Runtime, _ onchain.Strategy, _ *big.Int) (onchain.StrategyWithAPY, onchain.StrategyWithAPY, error) {
			return onchain.StrategyWithAPY{}, onchain.StrategyWithAPY{}, fmt.Errorf("optimal-failed")
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			require.FailNow(t, "WriteRebalance should not be called when GetOptimalAndCurrentStrategyWithAPY fails")
			return nil
		},
	}

	res, err := onCronTriggerWithDeps(config, runtime, newPayloadNow(), deps)

	require.Error(t, err)
	require.Nil(t, res)
	require.Contains(t, err.Error(), "failed to get optimal and current strategy with APY: optimal-failed")
}

func Test_onCronTriggerWithDeps_success_noRebalanceWhenStrategyUnchanged(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{{
			ChainName:        "parent-chain",
			ChainSelector:    1,
			YieldPeerAddress: "0xparent",
		}},
	}
	runtime := testutils.NewRuntime(t, nil)

	strat := onchain.Strategy{ChainSelector: 1}

	deps := OnCronDeps{
		InitSupportedStrategies: func(_ *helper.Config) error {
			return nil
		},
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return strat, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			return big.NewInt(1000), nil
		},
		GetOptimalAndCurrentStrategyWithAPY: func(_ *helper.Config, _ cre.Runtime, _ onchain.Strategy, _ *big.Int) (onchain.StrategyWithAPY, onchain.StrategyWithAPY, error) {
			// Return same strategy for both optimal and current
			return onchain.StrategyWithAPY{Strategy: strat, APY: 0.05}, onchain.StrategyWithAPY{Strategy: strat, APY: 0.05}, nil
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			require.FailNow(t, "WriteRebalance should not be called when strategy is unchanged")
			return nil
		},
	}

	res, err := onCronTriggerWithDeps(config, runtime, newPayloadNow(), deps)

	require.NoError(t, err)
	require.NotNil(t, res)
	require.False(t, res.Updated)
	require.Equal(t, strat, res.Current)
	require.Equal(t, strat, res.Optimal)
}

func Test_onCronTriggerWithDeps_errorWhen_NoConfigForStrategyChain(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{{
			ChainName:        "parent-chain",
			ChainSelector:    1,
			YieldPeerAddress: "0xparent",
		}},
	}
	runtime := testutils.NewRuntime(t, nil)

	cur := onchain.Strategy{
		ProtocolId:    [32]byte{1},
		ChainSelector: 999, // no matching EvmConfig
	}

	deps := OnCronDeps{
		InitSupportedStrategies: func(_ *helper.Config) error {
			return nil
		},
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return cur, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			require.FailNow(t, "ReadTVL should not be called when no EVM config exists for strategy chain")
			return nil, nil
		},
		GetOptimalAndCurrentStrategyWithAPY: func(_ *helper.Config, _ cre.Runtime, _ onchain.Strategy, _ *big.Int) (onchain.StrategyWithAPY, onchain.StrategyWithAPY, error) {
			require.FailNow(t, "GetOptimalAndCurrentStrategyWithAPY should not be called when no EVM config exists for strategy chain")
			return onchain.StrategyWithAPY{}, onchain.StrategyWithAPY{}, nil
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			require.FailNow(t, "WriteRebalance should not be called when no EVM config exists for strategy chain")
			return nil
		},
	}

	res, err := onCronTriggerWithDeps(config, runtime, newPayloadNow(), deps)

	require.Error(t, err)
	require.Nil(t, res)
	require.Contains(t, err.Error(), "no EVM config found for strategy chainSelector 999")
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

	deps := OnCronDeps{
		InitSupportedStrategies: func(_ *helper.Config) error {
			return nil
		},
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		NewChildPeerBinding: func(_ *evm.Client, _ string) (onchain.YieldPeerInterface, error) {
			return nil, fmt.Errorf("child-binding-failed")
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return cur, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			require.FailNow(t, "ReadTVL should not be called when ChildPeer binding fails")
			return nil, nil
		},
		GetOptimalAndCurrentStrategyWithAPY: func(_ *helper.Config, _ cre.Runtime, _ onchain.Strategy, _ *big.Int) (onchain.StrategyWithAPY, onchain.StrategyWithAPY, error) {
			require.FailNow(t, "GetOptimalAndCurrentStrategyWithAPY should not be called when ChildPeer binding fails")
			return onchain.StrategyWithAPY{}, onchain.StrategyWithAPY{}, nil
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			require.FailNow(t, "WriteRebalance should not be called when ChildPeer binding fails")
			return nil
		},
	}

	res, err := onCronTriggerWithDeps(config, runtime, newPayloadNow(), deps)

	require.Error(t, err)
	require.Nil(t, res)
	require.Contains(t, err.Error(), "failed to create strategy YieldPeer binding: child-binding-failed")
}

func Test_onCronTriggerWithDeps_errorWhen_ReadTVLFails_sameChain(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{{
			ChainName:        "parent-chain",
			ChainSelector:    1,
			YieldPeerAddress: "0xparent",
		}},
	}
	runtime := testutils.NewRuntime(t, nil)

	cur := onchain.Strategy{
		ProtocolId:    [32]byte{1},
		ChainSelector: 1,
	}

	deps := OnCronDeps{
		InitSupportedStrategies: func(_ *helper.Config) error {
			return nil
		},
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return cur, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			return nil, fmt.Errorf("tvl-failed")
		},
		GetOptimalAndCurrentStrategyWithAPY: func(_ *helper.Config, _ cre.Runtime, _ onchain.Strategy, _ *big.Int) (onchain.StrategyWithAPY, onchain.StrategyWithAPY, error) {
			require.FailNow(t, "GetOptimalAndCurrentStrategyWithAPY should not be called when ReadTVL fails")
			return onchain.StrategyWithAPY{}, onchain.StrategyWithAPY{}, nil
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			require.FailNow(t, "WriteRebalance should not be called when ReadTVL fails")
			return nil
		},
	}

	res, err := onCronTriggerWithDeps(config, runtime, newPayloadNow(), deps)

	require.Error(t, err)
	require.Nil(t, res)
	require.Contains(t, err.Error(), "failed to get total value from strategy YieldPeer: tvl-failed")
}

func Test_onCronTriggerWithDeps_errorWhen_GetOptimalAndCurrentStrategyWithAPYFailsDuringCalculation(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{{
			ChainName:        "parent-chain",
			ChainSelector:    1,
			YieldPeerAddress: "0xparent",
		}},
	}
	runtime := testutils.NewRuntime(t, nil)

	cur := onchain.Strategy{ProtocolId: [32]byte{1}, ChainSelector: 1}

	deps := OnCronDeps{
		InitSupportedStrategies: func(_ *helper.Config) error {
			return nil
		},
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return cur, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			return big.NewInt(123), nil
		},
		GetOptimalAndCurrentStrategyWithAPY: func(_ *helper.Config, _ cre.Runtime, _ onchain.Strategy, _ *big.Int) (onchain.StrategyWithAPY, onchain.StrategyWithAPY, error) {
			return onchain.StrategyWithAPY{}, onchain.StrategyWithAPY{}, fmt.Errorf("apy-calculation-failed")
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			require.FailNow(t, "WriteRebalance should not be called when APY calculation fails")
			return nil
		},
	}

	res, err := onCronTriggerWithDeps(config, runtime, newPayloadNow(), deps)

	require.Error(t, err)
	require.Nil(t, res)
	require.Contains(t, err.Error(), "failed to get optimal and current strategy with APY: apy-calculation-failed")
}

func Test_onCronTriggerWithDeps_success_noRebalanceWhenDeltaBelowThreshold(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{{
			ChainName:        "parent-chain",
			ChainSelector:    1,
			YieldPeerAddress: "0xparent",
			GasLimit:         500000,
		}},
	}
	runtime := testutils.NewRuntime(t, nil)

	cur := onchain.Strategy{ProtocolId: [32]byte{1}, ChainSelector: 1}
	opt := onchain.Strategy{ProtocolId: [32]byte{2}, ChainSelector: 1}

	writeCalled := false

	deps := OnCronDeps{
		InitSupportedStrategies: func(_ *helper.Config) error {
			return nil
		},
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return cur, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			return big.NewInt(1000), nil
		},
		// delta = 0.01 - 0.02 = -0.01 < threshold(0.01)
		GetOptimalAndCurrentStrategyWithAPY: func(_ *helper.Config, _ cre.Runtime, _ onchain.Strategy, _ *big.Int) (onchain.StrategyWithAPY, onchain.StrategyWithAPY, error) {
			return onchain.StrategyWithAPY{Strategy: opt, APY: 0.01}, onchain.StrategyWithAPY{Strategy: cur, APY: 0.02}, nil
		},
		NewRebalancerBinding: func(_ *evm.Client, _ string) (onchain.RebalancerInterface, error) {
			require.FailNow(t, "NewRebalancerBinding should not be called when delta < threshold")
			return nil, nil
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			writeCalled = true
			return nil
		},
	}

	res, err := onCronTriggerWithDeps(config, runtime, newPayloadNow(), deps)

	require.NoError(t, err)
	require.NotNil(t, res)
	require.False(t, res.Updated)
	require.False(t, writeCalled, "WriteRebalance should not be called when delta < threshold")
	require.Equal(t, cur, res.Current)
	require.Equal(t, opt, res.Optimal)
}

func Test_onCronTriggerWithDeps_errorWhen_RebalancerBindingFails(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{{
			ChainName:         "parent-chain",
			ChainSelector:     1,
			YieldPeerAddress:  "0xparent",
			RebalancerAddress: "0xrebalancer",
			GasLimit:          500000,
		}},
	}
	runtime := testutils.NewRuntime(t, nil)

	cur := onchain.Strategy{ProtocolId: [32]byte{1}, ChainSelector: 1}
	opt := onchain.Strategy{ProtocolId: [32]byte{2}, ChainSelector: 1}

	deps := OnCronDeps{
		InitSupportedStrategies: func(_ *helper.Config) error {
			return nil
		},
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return cur, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			return big.NewInt(1000), nil
		},
		// delta = 0.02 - 0.01 = 0.01 >= threshold(0.01)
		GetOptimalAndCurrentStrategyWithAPY: func(_ *helper.Config, _ cre.Runtime, _ onchain.Strategy, _ *big.Int) (onchain.StrategyWithAPY, onchain.StrategyWithAPY, error) {
			return onchain.StrategyWithAPY{Strategy: opt, APY: 0.02}, onchain.StrategyWithAPY{Strategy: cur, APY: 0.01}, nil
		},
		NewRebalancerBinding: func(_ *evm.Client, _ string) (onchain.RebalancerInterface, error) {
			return nil, fmt.Errorf("rebalancer-binding-failed")
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			require.FailNow(t, "WriteRebalance should not be called when Rebalancer binding fails")
			return nil
		},
	}

	res, err := onCronTriggerWithDeps(config, runtime, newPayloadNow(), deps)

	require.Error(t, err)
	require.Nil(t, res)
	require.Contains(t, err.Error(), "failed to create parent Rebalancer binding: rebalancer-binding-failed")
}

func Test_onCronTriggerWithDeps_errorWhen_WriteRebalanceFails(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{{
			ChainName:         "parent-chain",
			ChainSelector:     1,
			YieldPeerAddress:  "0xparent",
			RebalancerAddress: "0xrebalancer",
			GasLimit:          500000,
		}},
	}
	runtime := testutils.NewRuntime(t, nil)

	cur := onchain.Strategy{ProtocolId: [32]byte{1}, ChainSelector: 1}
	opt := onchain.Strategy{ProtocolId: [32]byte{2}, ChainSelector: 1}

	deps := OnCronDeps{
		InitSupportedStrategies: func(_ *helper.Config) error {
			return nil
		},
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return cur, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			return big.NewInt(1000), nil
		},
		// delta = 0.02 - 0.01 = 0.01 >= threshold(0.01)
		GetOptimalAndCurrentStrategyWithAPY: func(_ *helper.Config, _ cre.Runtime, _ onchain.Strategy, _ *big.Int) (onchain.StrategyWithAPY, onchain.StrategyWithAPY, error) {
			return onchain.StrategyWithAPY{Strategy: opt, APY: 0.02}, onchain.StrategyWithAPY{Strategy: cur, APY: 0.01}, nil
		},
		NewRebalancerBinding: func(_ *evm.Client, _ string) (onchain.RebalancerInterface, error) {
			return nil, nil
		},
		WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
			return fmt.Errorf("rebalance-failed")
		},
	}

	res, err := onCronTriggerWithDeps(config, runtime, newPayloadNow(), deps)

	require.Error(t, err)
	require.Nil(t, res)
	require.Contains(t, err.Error(), "failed to rebalance: rebalance-failed")
}

func Test_onCronTriggerWithDeps_success_rebalanceWhenStrategyChanges_sameChain(t *testing.T) {
	config := &helper.Config{
		Evms: []helper.EvmConfig{{
			ChainName:         "parent-chain",
			ChainSelector:     1,
			YieldPeerAddress:  "0xparent",
			RebalancerAddress: "0xrebalancer",
			GasLimit:          500000,
		}},
	}
	runtime := testutils.NewRuntime(t, nil)

	cur := onchain.Strategy{ProtocolId: [32]byte{1}, ChainSelector: 1}
	opt := onchain.Strategy{ProtocolId: [32]byte{2}, ChainSelector: 1}

	writeCalls := 0
	var lastOptimal onchain.Strategy
	var lastGasLimit uint64

	deps := OnCronDeps{
		InitSupportedStrategies: func(_ *helper.Config) error {
			return nil
		},
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return cur, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			return big.NewInt(1000), nil
		},
		// delta = 0.02 - 0.01 = 0.01 >= threshold(0.01)
		GetOptimalAndCurrentStrategyWithAPY: func(_ *helper.Config, _ cre.Runtime, _ onchain.Strategy, _ *big.Int) (onchain.StrategyWithAPY, onchain.StrategyWithAPY, error) {
			return onchain.StrategyWithAPY{Strategy: opt, APY: 0.02}, onchain.StrategyWithAPY{Strategy: cur, APY: 0.01}, nil
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

	require.NoError(t, err)
	require.NotNil(t, res)
	require.True(t, res.Updated)
	require.Equal(t, 1, writeCalls)
	require.Equal(t, opt, lastOptimal)
	require.Equal(t, config.Evms[0].GasLimit, lastGasLimit)
	require.Equal(t, cur, res.Current)
	require.Equal(t, opt, res.Optimal)
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
		InitSupportedStrategies: func(_ *helper.Config) error {
			return nil
		},
		NewParentPeerBinding: func(_ *evm.Client, _ string) (onchain.ParentPeerInterface, error) {
			return nil, nil
		},
		NewChildPeerBinding: func(_ *evm.Client, _ string) (onchain.YieldPeerInterface, error) {
			return nil, nil
		},
		ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
			return cur, nil
		},
		ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
			return big.NewInt(1000), nil
		},
		// delta = 0.03 - 0.01 = 0.02 >= threshold(0.01)
		GetOptimalAndCurrentStrategyWithAPY: func(_ *helper.Config, _ cre.Runtime, _ onchain.Strategy, _ *big.Int) (onchain.StrategyWithAPY, onchain.StrategyWithAPY, error) {
			return onchain.StrategyWithAPY{Strategy: opt, APY: 0.03}, onchain.StrategyWithAPY{Strategy: cur, APY: 0.01}, nil
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

	require.NoError(t, err)
	require.NotNil(t, res)
	require.True(t, res.Updated)
	require.Equal(t, 1, writeCalls)
	require.Equal(t, opt, lastOptimal)
	require.Equal(t, config.Evms[1].GasLimit, lastGasLimit)
	require.Equal(t, cur, res.Current)
	require.Equal(t, opt, res.Optimal)
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

	require.NoError(t, err)
	require.Len(t, wf, 1)
}