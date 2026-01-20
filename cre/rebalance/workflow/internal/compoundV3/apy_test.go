package compoundV3

import (
	"fmt"
	"math/big"
	"testing"

	"rebalance/workflow/internal/constants"
	"rebalance/workflow/internal/helper"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"
)

/*//////////////////////////////////////////////////////////////
                          ERROR PATHS
//////////////////////////////////////////////////////////////*/

func TestGetAPY_error_chainConfigNotFound(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{},
	}
	runtime := testutils.NewRuntime(t, nil)

	apy, err := GetAPY(cfg, runtime, big.NewInt(0), 999)

	require.Error(t, err)
	require.Contains(t, err.Error(), "failed to find evm config")
	require.Equal(t, 0.0, apy)
}

func TestGetAPY_error_cometBindingFails(t *testing.T) {
	cfg := &helper.Config{
		BlockNumber: 0,
		Evms: []helper.EvmConfig{
			{
				ChainName:                 "test-chain",
				ChainSelector:             1,
				CompoundV3CometUSDCAddress: "0x0000000000000000000000000000000000000001",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	orig := newCometBindingFunc
	newCometBindingFunc = func(_ *evm.Client, _ string) (CometInterface, error) {
		return nil, fmt.Errorf("binding-failed")
	}
	defer func() { newCometBindingFunc = orig }()

	apy, err := GetAPY(cfg, runtime, big.NewInt(0), 1)

	require.Error(t, err)
	require.Contains(t, err.Error(), "failed to create comet binding")
	require.Contains(t, err.Error(), "binding-failed")
	require.Equal(t, 0.0, apy)
}

func TestGetAPY_error_totalSupplyFails(t *testing.T) {
	cfg := &helper.Config{
		BlockNumber: 10,
		Evms: []helper.EvmConfig{
			{
				ChainName:                 "test-chain",
				ChainSelector:             1,
				CompoundV3CometUSDCAddress: "0x0000000000000000000000000000000000000001",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	fc := &fakeComet{
		totalSupplyErr: fmt.Errorf("supply-failed"),
	}

	orig := newCometBindingFunc
	newCometBindingFunc = func(_ *evm.Client, _ string) (CometInterface, error) {
		return fc, nil
	}
	defer func() { newCometBindingFunc = orig }()

	apy, err := GetAPY(cfg, runtime, big.NewInt(0), 1)

	require.Error(t, err)
	require.Contains(t, err.Error(), "failed to get total supply")
	require.Contains(t, err.Error(), "supply-failed")
	require.Equal(t, 0.0, apy)
}

func TestGetAPY_error_totalBorrowFails(t *testing.T) {
	cfg := &helper.Config{
		BlockNumber: 10,
		Evms: []helper.EvmConfig{
			{
				ChainName:                 "test-chain",
				ChainSelector:             1,
				CompoundV3CometUSDCAddress: "0x0000000000000000000000000000000000000001",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	fc := &fakeComet{
		totalSupply:    big.NewInt(1000),
		totalBorrowErr: fmt.Errorf("borrow-failed"),
	}

	orig := newCometBindingFunc
	newCometBindingFunc = func(_ *evm.Client, _ string) (CometInterface, error) {
		return fc, nil
	}
	defer func() { newCometBindingFunc = orig }()

	apy, err := GetAPY(cfg, runtime, big.NewInt(0), 1)

	require.Error(t, err)
	require.Contains(t, err.Error(), "failed to get total borrow")
	require.Contains(t, err.Error(), "borrow-failed")
	require.Equal(t, 0.0, apy)
}

func TestGetAPY_error_supplyRateFails(t *testing.T) {
	cfg := &helper.Config{
		BlockNumber: 10,
		Evms: []helper.EvmConfig{
			{
				ChainName:                 "test-chain",
				ChainSelector:             1,
				CompoundV3CometUSDCAddress: "0x0000000000000000000000000000000000000001",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	fc := &fakeComet{
		totalSupply:    big.NewInt(1_000_000),
		totalBorrow:    big.NewInt(500_000),
		supplyRateErr:  fmt.Errorf("supply-rate-failed"),
	}

	orig := newCometBindingFunc
	newCometBindingFunc = func(_ *evm.Client, _ string) (CometInterface, error) {
		return fc, nil
	}
	defer func() { newCometBindingFunc = orig }()

	apy, err := GetAPY(cfg, runtime, big.NewInt(0), 1)

	require.Error(t, err)
	require.Contains(t, err.Error(), "failed to get supply rate")
	require.Contains(t, err.Error(), "supply-rate-failed")
	require.Equal(t, 0.0, apy)
}

/*//////////////////////////////////////////////////////////////
                         SUCCESS PATHS
//////////////////////////////////////////////////////////////*/

func TestGetAPY_success_noLiquidityAdded(t *testing.T) {
	cfg := &helper.Config{
		BlockNumber: 123,
		Evms: []helper.EvmConfig{
			{
				ChainName:                 "test-chain",
				ChainSelector:             42,
				CompoundV3CometUSDCAddress: "0x0000000000000000000000000000000000000001",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	baseSupply := big.NewInt(1_000_000)
	baseBorrow := big.NewInt(500_000)
	supplyRate := uint64(1_000_000_000)

	fc := &fakeComet{
		totalSupply: baseSupply,
		totalBorrow: baseBorrow,
		supplyRate:  supplyRate,
	}

	var gotClientChainSelector uint64

	orig := newCometBindingFunc
	newCometBindingFunc = func(client *evm.Client, _ string) (CometInterface, error) {
		gotClientChainSelector = client.ChainSelector
		return fc, nil
	}
	defer func() { newCometBindingFunc = orig }()

	// liquidityAdded == nil → branch where we do NOT add to totalSupply.
	var liquidityAdded *big.Int = nil

	apy, err := GetAPY(cfg, runtime, liquidityAdded, 42)

	require.NoError(t, err)

	// APY should be calculated via the helper.
	expectedAPY := calculateAPYFromSupplyRate(supplyRate)
	require.Equal(t, expectedAPY, apy)

	// Utilization = (borrow * WAD) / supply (no liquidity added).
	expectedUtilization := new(big.Int).Mul(baseBorrow, big.NewInt(constants.WAD))
	expectedUtilization.Div(expectedUtilization, baseSupply)

	require.NotNil(t, fc.lastUtilization)
	require.Equal(t, expectedUtilization.String(), fc.lastUtilization.String())

	// Ensure the EVM client used the passed chainSelector.
	require.Equal(t, uint64(42), gotClientChainSelector)
}

func TestGetAPY_success_withLiquidityAdded(t *testing.T) {
	cfg := &helper.Config{
		BlockNumber: 456,
		Evms: []helper.EvmConfig{
			{
				ChainName:                 "test-chain",
				ChainSelector:             99,
				CompoundV3CometUSDCAddress: "0x0000000000000000000000000000000000000002",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	baseSupply := big.NewInt(2_000_000)
	baseBorrow := big.NewInt(1_000_000)
	liquidityAdded := big.NewInt(500_000)
	supplyRate := uint64(2_000_000_000)

	fc := &fakeComet{
		totalSupply: baseSupply,
		totalBorrow: baseBorrow,
		supplyRate:  supplyRate,
	}

	orig := newCometBindingFunc
	newCometBindingFunc = func(_ *evm.Client, _ string) (CometInterface, error) {
		return fc, nil
	}
	defer func() { newCometBindingFunc = orig }()

	apy, err := GetAPY(cfg, runtime, liquidityAdded, 99)

	require.NoError(t, err)

	expectedAPY := calculateAPYFromSupplyRate(supplyRate)
	require.Equal(t, expectedAPY, apy)

	// totalSupply used in utilization should be baseSupply + liquidityAdded.
	totalSupplyWithAdded := new(big.Int).Add(baseSupply, liquidityAdded)

	expectedUtilization := new(big.Int).Mul(baseBorrow, big.NewInt(constants.WAD))
	expectedUtilization.Div(expectedUtilization, totalSupplyWithAdded)

	require.NotNil(t, fc.lastUtilization)
	require.Equal(t, expectedUtilization.String(), fc.lastUtilization.String())
}
