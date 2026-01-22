package aaveV3

import (
	"fmt"
	"math/big"
	"testing"

	"rebalance/workflow/internal/helper"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"
)

/*//////////////////////////////////////////////////////////////
                          ERROR PATHS
//////////////////////////////////////////////////////////////*/

func TestGetAPYPromise_error_chainConfigNotFound(t *testing.T) {
	cfg := &helper.Config{Evms: []helper.EvmConfig{}}
	runtime := testutils.NewRuntime(t, nil)

	p := GetAPYPromise(cfg, runtime, big.NewInt(0), 999)
	apy, err := p.Await()

	require.Error(t, err)
	require.Contains(t, err.Error(), "chain config not found for chainSelector")
	require.Equal(t, 0.0, apy)
}

func TestGetAPYPromise_error_missingPoolAddressesProvider(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:                       "test-chain",
				ChainSelector:                   1,
				AaveV3PoolAddressesProviderAddress: "",
				USDCAddress:                     "0x0000000000000000000000000000000000000001",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	p := GetAPYPromise(cfg, runtime, big.NewInt(0), 1)
	apy, err := p.Await()

	require.Error(t, err)
	require.Contains(t, err.Error(), "AaveV3PoolAddressesProviderAddress not configured for chain test-chain")
	require.Equal(t, 0.0, apy)
}

func TestGetAPYPromise_error_missingUSDCAddress(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:                       "test-chain",
				ChainSelector:                   1,
				AaveV3PoolAddressesProviderAddress: "0x0000000000000000000000000000000000000001",
				USDCAddress:                     "",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	p := GetAPYPromise(cfg, runtime, big.NewInt(0), 1)
	apy, err := p.Await()

	require.Error(t, err)
	require.Contains(t, err.Error(), "USDCAddress not configured for chain test-chain")
	require.Equal(t, 0.0, apy)
}

func TestGetAPYPromise_error_liquidityNil(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:                       "test-chain",
				ChainSelector:                   1,
				AaveV3PoolAddressesProviderAddress: "0x0000000000000000000000000000000000000001",
				USDCAddress:                     "0x0000000000000000000000000000000000000002",
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

func TestGetAPYPromise_error_poolAddressesProviderBindingFails(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:                       "test-chain",
				ChainSelector:                   1,
				AaveV3PoolAddressesProviderAddress: "0x0000000000000000000000000000000000000001",
				USDCAddress:                     "0x0000000000000000000000000000000000000002",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	orig := newPoolAddressesProviderBindingFunc
	newPoolAddressesProviderBindingFunc = func(_ *evm.Client, _ string) (PoolAddressesProviderInterface, error) {
		return nil, fmt.Errorf("provider-binding-failed")
	}
	defer func() { newPoolAddressesProviderBindingFunc = orig }()

	p := GetAPYPromise(cfg, runtime, big.NewInt(0), 1)
	apy, err := p.Await()

	require.Error(t, err)
	require.Contains(t, err.Error(), "failed to create PoolAddressesProvider binding for chain test-chain")
	require.Contains(t, err.Error(), "provider-binding-failed")
	require.Equal(t, 0.0, apy)
}

/*//////////////////////////////////////////////////////////////
                         SUCCESS PATHS
//////////////////////////////////////////////////////////////*/

func TestGetAPYPromise_success_happyPath(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:                       "test-chain",
				ChainSelector:                   42,
				AaveV3PoolAddressesProviderAddress: "0x0000000000000000000000000000000000000001",
				USDCAddress:                     "0x0000000000000000000000000000000000000002",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	liquidity := big.NewInt(1234)

	// Capture arguments passed through the pipeline.
	var (
		gotClientChainSelector uint64

		gotProviderChainName string

		gotStrategyAsset    common.Address
		gotStrategyChain    string
		gotParamsAsset      common.Address
		gotParamsLiquidity  *big.Int
		gotCalcStrategy     DefaultReserveInterestRateStrategyV2Interface
		gotCalcParams       *CalculateInterestRatesParams
		expectedStrategy    DefaultReserveInterestRateStrategyV2Interface = nil
		expectedParams                                      = &CalculateInterestRatesParams{}
		expectedAPY        float64                         = 0.123
	)

	origProvider := newPoolAddressesProviderBindingFunc
	origGetProvider := getProtocolDataProviderBindingFunc
	origGetStrategy := getStrategyBindingFunc
	origGetParams := getCalculateInterestRatesParamsFunc
	origCalcAPY := calculateAPYFromContractFunc

	newPoolAddressesProviderBindingFunc = func(client *evm.Client, _ string) (PoolAddressesProviderInterface, error) {
		gotClientChainSelector = client.ChainSelector
		// We don't need a real provider instance; nil is enough since we stub the next step.
		return nil, nil
	}

	getProtocolDataProviderBindingFunc = func(_ cre.Runtime, _ *evm.Client, _ PoolAddressesProviderInterface, chainName string) cre.Promise[AaveProtocolDataProviderInterface] {
		gotProviderChainName = chainName
		// We don't need a concrete implementation; nil interface is fine, as we stub strategy next.
		return cre.PromiseFromResult[AaveProtocolDataProviderInterface](nil, nil)
	}

	getStrategyBindingFunc = func(_ cre.Runtime, _ *evm.Client, _ AaveProtocolDataProviderInterface, asset common.Address, chainName string) cre.Promise[DefaultReserveInterestRateStrategyV2Interface] {
		gotStrategyAsset = asset
		gotStrategyChain = chainName
		return cre.PromiseFromResult[DefaultReserveInterestRateStrategyV2Interface](expectedStrategy, nil)
	}

	getCalculateInterestRatesParamsFunc = func(_ cre.Runtime, _ AaveProtocolDataProviderInterface, asset common.Address, liq *big.Int) cre.Promise[*CalculateInterestRatesParams] {
		gotParamsAsset = asset
		gotParamsLiquidity = new(big.Int).Set(liq)
		return cre.PromiseFromResult(expectedParams, nil)
	}

	calculateAPYFromContractFunc = func(_ cre.Runtime, strategy DefaultReserveInterestRateStrategyV2Interface, params *CalculateInterestRatesParams) cre.Promise[float64] {
		gotCalcStrategy = strategy
		gotCalcParams = params
		return cre.PromiseFromResult(expectedAPY, nil)
	}

	defer func() {
		newPoolAddressesProviderBindingFunc = origProvider
		getProtocolDataProviderBindingFunc = origGetProvider
		getStrategyBindingFunc = origGetStrategy
		getCalculateInterestRatesParamsFunc = origGetParams
		calculateAPYFromContractFunc = origCalcAPY
	}()

	p := GetAPYPromise(cfg, runtime, liquidity, 42)
	apy, err := p.Await()

	require.NoError(t, err)
	require.Equal(t, expectedAPY, apy)

	// Validate that evm.Client was created with the correct selector.
	require.Equal(t, cfg.Evms[0].ChainSelector, gotClientChainSelector)

	// Validate chain name propagation.
	require.Equal(t, cfg.Evms[0].ChainName, gotProviderChainName)
	require.Equal(t, cfg.Evms[0].ChainName, gotStrategyChain)

	// Validate USDC address is passed consistently.
	expectedUSDCAddr := common.HexToAddress(cfg.Evms[0].USDCAddress)
	require.Equal(t, expectedUSDCAddr, gotStrategyAsset)
	require.Equal(t, expectedUSDCAddr, gotParamsAsset)

	// Validate liquidity is passed through correctly.
	require.Equal(t, liquidity.String(), gotParamsLiquidity.String())

	// Validate CalculateAPYFromContract receives the same strategy and params produced upstream.
	require.Equal(t, expectedStrategy, gotCalcStrategy)
	require.Equal(t, expectedParams, gotCalcParams)
}
