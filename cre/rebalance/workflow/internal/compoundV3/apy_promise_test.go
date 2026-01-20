package compoundV3

import (
	"math/big"
	"testing"

	"rebalance/contracts/evm/src/generated/comet"
	"rebalance/workflow/internal/constants"
	"rebalance/workflow/internal/helper"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"
)

/*//////////////////////////////////////////////////////////////
                            UTILITY
//////////////////////////////////////////////////////////////*/

type fakeComet struct {
	totalSupply *big.Int
	totalBorrow *big.Int
	supplyRate  uint64

	lastTotalSupplyBlock   *big.Int
	lastTotalBorrowBlock   *big.Int
	lastGetSupplyRateBlock *big.Int
	lastUtilization        *big.Int
}

func (f *fakeComet) TotalSupply(runtime cre.Runtime, blockNumber *big.Int) cre.Promise[*big.Int] {
	if blockNumber != nil {
		f.lastTotalSupplyBlock = new(big.Int).Set(blockNumber)
	}
	return cre.PromiseFromResult(new(big.Int).Set(f.totalSupply), nil)
}

func (f *fakeComet) TotalBorrow(runtime cre.Runtime, blockNumber *big.Int) cre.Promise[*big.Int] {
	if blockNumber != nil {
		f.lastTotalBorrowBlock = new(big.Int).Set(blockNumber)
	}
	return cre.PromiseFromResult(new(big.Int).Set(f.totalBorrow), nil)
}

func (f *fakeComet) GetSupplyRate(runtime cre.Runtime, input comet.GetSupplyRateInput, blockNumber *big.Int) cre.Promise[uint64] {
	if input.Utilization != nil {
		f.lastUtilization = new(big.Int).Set(input.Utilization)
	}
	if blockNumber != nil {
		f.lastGetSupplyRateBlock = new(big.Int).Set(blockNumber)
	}
	return cre.PromiseFromResult(f.supplyRate, nil)
}

var _ CometInterface = (*fakeComet)(nil)

/*//////////////////////////////////////////////////////////////
                          ERROR PATHS
//////////////////////////////////////////////////////////////*/

func TestGetAPYPromise_error_whenChainConfigNotFound(t *testing.T) {
	cfg := &helper.Config{Evms: []helper.EvmConfig{}}
	runtime := testutils.NewRuntime(t, nil)

	p := GetAPYPromise(cfg, runtime, big.NewInt(0), 123)
	apy, err := p.Await()

	require.Error(t, err)
	require.Contains(t, err.Error(), "chain config not found for chainSelector")
	require.Equal(t, 0.0, apy)
}

func TestGetAPYPromise_error_whenCometAddressMissing(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:                  "test-chain",
				ChainSelector:              1,
				CompoundV3CometUSDCAddress: "",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	p := GetAPYPromise(cfg, runtime, big.NewInt(0), 1)
	apy, err := p.Await()

	require.Error(t, err)
	require.Contains(t, err.Error(), "CompoundV3CometUSDCAddress not configured for chain")
	require.Equal(t, 0.0, apy)
}

func TestGetAPYPromise_error_whenLiquidityNil(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:                  "test-chain",
				ChainSelector:              1,
				CompoundV3CometUSDCAddress: "0x0000000000000000000000000000000000000001",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	p := GetAPYPromise(cfg, runtime, nil, 1)
	apy, err := p.Await()

	require.Error(t, err)
	require.Contains(t, err.Error(), "liquidityAdded cannot be nil")
	require.Equal(t, 0.0, apy)
}

func TestGetAPYPromise_error_whenCometBindingFails(t *testing.T) {
	// Use an invalid hex address to force NewCometBinding to fail.
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:                  "test-chain",
				ChainSelector:              1,
				CompoundV3CometUSDCAddress: "not-a-valid-address",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	// Ensure we use the real binding for this test.
	orig := injectedNewCometBinding
	injectedNewCometBinding = newCometBinding
	defer func() { injectedNewCometBinding = orig }()

	p := GetAPYPromise(cfg, runtime, big.NewInt(0), 1)
	apy, err := p.Await()

	require.Error(t, err)
	require.Contains(t, err.Error(), "failed to create Comet binding for chain")
	require.Equal(t, 0.0, apy)
}

func TestGetAPYPromise_error_whenTotalSupplyZero(t *testing.T) {
	cfg := &helper.Config{
		BlockNumber: 0,
		Evms: []helper.EvmConfig{
			{
				ChainName:                  "test-chain",
				ChainSelector:              1,
				CompoundV3CometUSDCAddress: "0x0000000000000000000000000000000000000001",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	fc := &fakeComet{
		totalSupply: big.NewInt(0),
		totalBorrow: big.NewInt(0),
		supplyRate:  0,
	}

	orig := injectedNewCometBinding
	injectedNewCometBinding = func(_ *evm.Client, _ string) (CometInterface, error) {
		return fc, nil
	}
	defer func() { injectedNewCometBinding = orig }()

	p := GetAPYPromise(cfg, runtime, big.NewInt(0), 1)
	apy, err := p.Await()

	require.Error(t, err)
	require.Contains(t, err.Error(), "total supply is zero, cannot compute utilization")
	require.Equal(t, 0.0, apy)
}

/*//////////////////////////////////////////////////////////////
                         SUCCESS PATHS
//////////////////////////////////////////////////////////////*/

func TestGetAPYPromise_success_noExtraLiquidity(t *testing.T) {
	cfg := &helper.Config{
		BlockNumber: 123,
		Evms: []helper.EvmConfig{
			{
				ChainName:                  "test-chain",
				ChainSelector:              1,
				CompoundV3CometUSDCAddress: "0x0000000000000000000000000000000000000001",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	totalSupply := big.NewInt(1_000_000)
	totalBorrow := big.NewInt(500_000)
	supplyRate := uint64(1_000_000_000)

	fc := &fakeComet{
		totalSupply: totalSupply,
		totalBorrow: totalBorrow,
		supplyRate:  supplyRate,
	}

	orig := injectedNewCometBinding
	injectedNewCometBinding = func(_ *evm.Client, _ string) (CometInterface, error) {
		return fc, nil
	}
	defer func() { injectedNewCometBinding = orig }()

	liquidityAdded := big.NewInt(0)

	p := GetAPYPromise(cfg, runtime, liquidityAdded, 1)
	apy, err := p.Await()

	require.NoError(t, err)

	expectedAPY := calculateAPYFromSupplyRate(supplyRate)
	require.Equal(t, expectedAPY, apy)

	// Utilization = (borrow * WAD) / supply
	expectedUtilization := new(big.Int).Mul(totalBorrow, big.NewInt(constants.WAD))
	expectedUtilization.Div(expectedUtilization, totalSupply)

	require.NotNil(t, fc.lastUtilization)
	require.Equal(t, expectedUtilization.String(), fc.lastUtilization.String())

	// Block number should be passed through to all calls.
	expectedBlock := big.NewInt(cfg.BlockNumber)
	require.Equal(t, expectedBlock.String(), fc.lastTotalSupplyBlock.String())
	require.Equal(t, expectedBlock.String(), fc.lastTotalBorrowBlock.String())
	require.Equal(t, expectedBlock.String(), fc.lastGetSupplyRateBlock.String())
}

func TestGetAPYPromise_success_withExtraLiquidity(t *testing.T) {
	cfg := &helper.Config{
		BlockNumber: 456,
		Evms: []helper.EvmConfig{
			{
				ChainName:                  "test-chain",
				ChainSelector:              99,
				CompoundV3CometUSDCAddress: "0x0000000000000000000000000000000000000002",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	baseSupply := big.NewInt(2_000_000)
	totalBorrow := big.NewInt(1_000_000)
	liquidityAdded := big.NewInt(500_000)
	supplyRate := uint64(2_000_000_000)

	fc := &fakeComet{
		totalSupply: baseSupply,
		totalBorrow: totalBorrow,
		supplyRate:  supplyRate,
	}

	orig := injectedNewCometBinding
	injectedNewCometBinding = func(_ *evm.Client, _ string) (CometInterface, error) {
		return fc, nil
	}
	defer func() { injectedNewCometBinding = orig }()

	p := GetAPYPromise(cfg, runtime, liquidityAdded, 99)
	apy, err := p.Await()

	require.NoError(t, err)

	expectedAPY := calculateAPYFromSupplyRate(supplyRate)
	require.Equal(t, expectedAPY, apy)

	// totalSupply should be baseSupply + liquidityAdded inside the pipeline.
	totalSupplyWithAdded := new(big.Int).Add(baseSupply, liquidityAdded)

	expectedUtilization := new(big.Int).Mul(totalBorrow, big.NewInt(constants.WAD))
	expectedUtilization.Div(expectedUtilization, totalSupplyWithAdded)

	require.NotNil(t, fc.lastUtilization)
	require.Equal(t, expectedUtilization.String(), fc.lastUtilization.String())
}
