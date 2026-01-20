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

func TestGetAPY_error_chainConfigNotFound(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{},
	}
	runtime := testutils.NewRuntime(t, nil)

	apy, err := GetAPY(cfg, runtime, big.NewInt(0), 999)

	require.Error(t, err)
	require.Contains(t, err.Error(), "chain config not found for chainSelector")
	require.Equal(t, 0.0, apy)
}

func TestGetAPY_error_missingPoolAddressesProviderAddress(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:                         "test-chain",
				ChainSelector:                     1,
				AaveV3PoolAddressesProviderAddress: "",
				USDCAddress:                       "0x0000000000000000000000000000000000000001",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	apy, err := GetAPY(cfg, runtime, big.NewInt(0), 1)

	require.Error(t, err)
	require.Contains(t, err.Error(), "AaveV3PoolAddressesProviderAddress not configured for chain test-chain")
	require.Equal(t, 0.0, apy)
}

func TestGetAPY_error_missingUSDCAddress(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:                         "test-chain",
				ChainSelector:                     1,
				AaveV3PoolAddressesProviderAddress: "0x0000000000000000000000000000000000000001",
				USDCAddress:                       "",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	apy, err := GetAPY(cfg, runtime, big.NewInt(0), 1)

	require.Error(t, err)
	require.Contains(t, err.Error(), "USDCAddress not configured for chain test-chain")
	require.Equal(t, 0.0, apy)
}

func TestGetAPY_error_liquidityNil(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:                         "test-chain",
				ChainSelector:                     1,
				AaveV3PoolAddressesProviderAddress: "0x0000000000000000000000000000000000000001",
				USDCAddress:                       "0x0000000000000000000000000000000000000002",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	apy, err := GetAPY(cfg, runtime, nil, 1)

	require.Error(t, err)
	require.Contains(t, err.Error(), "liquidityAdded cannot be nil")
	require.Equal(t, 0.0, apy)
}

func TestGetAPY_error_poolAddressesProviderBindingFails(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:                         "test-chain",
				ChainSelector:                     1,
				AaveV3PoolAddressesProviderAddress: "0x0000000000000000000000000000000000000001",
				USDCAddress:                       "0x0000000000000000000000000000000000000002",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	origProvider := newPoolAddressesProviderBindingFunc
	newPoolAddressesProviderBindingFunc = func(_ *evm.Client, _ string) (PoolAddressesProviderInterface, error) {
		return nil, fmt.Errorf("provider-binding-failed")
	}
	defer func() { newPoolAddressesProviderBindingFunc = origProvider }()

	apy, err := GetAPY(cfg, runtime, big.NewInt(0), 1)

	require.Error(t, err)
	require.Contains(t, err.Error(), "failed to create PoolAddressesProvider binding for chain test-chain")
	require.Contains(t, err.Error(), "provider-binding-failed")
	require.Equal(t, 0.0, apy)
}

func TestGetAPY_error_protocolDataProviderFails(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:                         "test-chain",
				ChainSelector:                     1,
				AaveV3PoolAddressesProviderAddress: "0x0000000000000000000000000000000000000001",
				USDCAddress:                       "0x0000000000000000000000000000000000000002",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	origProvider := newPoolAddressesProviderBindingFunc
	origGetProvider := getProtocolDataProviderBindingFunc

	newPoolAddressesProviderBindingFunc = func(_ *evm.Client, _ string) (PoolAddressesProviderInterface, error) {
		return nil, nil
	}
	getProtocolDataProviderBindingFunc = func(_ cre.Runtime, _ *evm.Client, _ PoolAddressesProviderInterface, _ string) cre.Promise[AaveProtocolDataProviderInterface] {
		return cre.PromiseFromResult[AaveProtocolDataProviderInterface](nil, fmt.Errorf("protocol-provider-failed"))
	}

	defer func() {
		newPoolAddressesProviderBindingFunc = origProvider
		getProtocolDataProviderBindingFunc = origGetProvider
	}()

	apy, err := GetAPY(cfg, runtime, big.NewInt(0), 1)

	require.Error(t, err)
	require.Contains(t, err.Error(), "failed to get ProtocolDataProvider for chain test-chain")
	require.Contains(t, err.Error(), "protocol-provider-failed")
	require.Equal(t, 0.0, apy)
}

func TestGetAPY_error_strategyBindingFails(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:                         "test-chain",
				ChainSelector:                     1,
				AaveV3PoolAddressesProviderAddress: "0x0000000000000000000000000000000000000001",
				USDCAddress:                       "0x0000000000000000000000000000000000000002",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	origProvider := newPoolAddressesProviderBindingFunc
	origGetProvider := getProtocolDataProviderBindingFunc
	origGetStrategy := getStrategyBindingFunc

	newPoolAddressesProviderBindingFunc = func(_ *evm.Client, _ string) (PoolAddressesProviderInterface, error) {
		return nil, nil
	}
	getProtocolDataProviderBindingFunc = func(_ cre.Runtime, _ *evm.Client, _ PoolAddressesProviderInterface, _ string) cre.Promise[AaveProtocolDataProviderInterface] {
		return cre.PromiseFromResult[AaveProtocolDataProviderInterface](nil, nil)
	}
	getStrategyBindingFunc = func(_ cre.Runtime, _ *evm.Client, _ AaveProtocolDataProviderInterface, _ common.Address, _ string) cre.Promise[DefaultReserveInterestRateStrategyV2Interface] {
		return cre.PromiseFromResult[DefaultReserveInterestRateStrategyV2Interface](nil, fmt.Errorf("strategy-binding-failed"))
	}

	defer func() {
		newPoolAddressesProviderBindingFunc = origProvider
		getProtocolDataProviderBindingFunc = origGetProvider
		getStrategyBindingFunc = origGetStrategy
	}()

	apy, err := GetAPY(cfg, runtime, big.NewInt(0), 1)

	require.Error(t, err)
	require.Contains(t, err.Error(), "failed to get Strategy binding for chain test-chain")
	require.Contains(t, err.Error(), "strategy-binding-failed")
	require.Equal(t, 0.0, apy)
}

func TestGetAPY_error_fetchParamsFails(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:                         "test-chain",
				ChainSelector:                     1,
				AaveV3PoolAddressesProviderAddress: "0x0000000000000000000000000000000000000001",
				USDCAddress:                       "0x0000000000000000000000000000000000000002",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	origProvider := newPoolAddressesProviderBindingFunc
	origGetProvider := getProtocolDataProviderBindingFunc
	origGetStrategy := getStrategyBindingFunc
	origGetParams := getCalculateInterestRatesParamsFunc

	newPoolAddressesProviderBindingFunc = func(_ *evm.Client, _ string) (PoolAddressesProviderInterface, error) {
		return nil, nil
	}
	getProtocolDataProviderBindingFunc = func(_ cre.Runtime, _ *evm.Client, _ PoolAddressesProviderInterface, _ string) cre.Promise[AaveProtocolDataProviderInterface] {
		return cre.PromiseFromResult[AaveProtocolDataProviderInterface](nil, nil)
	}
	getStrategyBindingFunc = func(_ cre.Runtime, _ *evm.Client, _ AaveProtocolDataProviderInterface, _ common.Address, _ string) cre.Promise[DefaultReserveInterestRateStrategyV2Interface] {
		return cre.PromiseFromResult[DefaultReserveInterestRateStrategyV2Interface](nil, nil)
	}
	getCalculateInterestRatesParamsFunc = func(_ cre.Runtime, _ AaveProtocolDataProviderInterface, _ common.Address, _ *big.Int) cre.Promise[*CalculateInterestRatesParams] {
		return cre.PromiseFromResult[*CalculateInterestRatesParams](nil, fmt.Errorf("params-failed"))
	}

	defer func() {
		newPoolAddressesProviderBindingFunc = origProvider
		getProtocolDataProviderBindingFunc = origGetProvider
		getStrategyBindingFunc = origGetStrategy
		getCalculateInterestRatesParamsFunc = origGetParams
	}()

	apy, err := GetAPY(cfg, runtime, big.NewInt(0), 1)

	require.Error(t, err)
	require.Contains(t, err.Error(), "failed to fetch CalculateInterestRatesParams for chain test-chain")
	require.Contains(t, err.Error(), "params-failed")
	require.Equal(t, 0.0, apy)
}

func TestGetAPY_error_calculateAPYFails(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:                         "test-chain",
				ChainSelector:                     1,
				AaveV3PoolAddressesProviderAddress: "0x0000000000000000000000000000000000000001",
				USDCAddress:                       "0x0000000000000000000000000000000000000002",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	params := &CalculateInterestRatesParams{
		TotalDebt:              big.NewInt(1),
		VirtualUnderlyingBalance: big.NewInt(2),
	}

	origProvider := newPoolAddressesProviderBindingFunc
	origGetProvider := getProtocolDataProviderBindingFunc
	origGetStrategy := getStrategyBindingFunc
	origGetParams := getCalculateInterestRatesParamsFunc
	origCalc := calculateAPYFromContractFunc

	newPoolAddressesProviderBindingFunc = func(_ *evm.Client, _ string) (PoolAddressesProviderInterface, error) {
		return nil, nil
	}
	getProtocolDataProviderBindingFunc = func(_ cre.Runtime, _ *evm.Client, _ PoolAddressesProviderInterface, _ string) cre.Promise[AaveProtocolDataProviderInterface] {
		return cre.PromiseFromResult[AaveProtocolDataProviderInterface](nil, nil)
	}
	getStrategyBindingFunc = func(_ cre.Runtime, _ *evm.Client, _ AaveProtocolDataProviderInterface, _ common.Address, _ string) cre.Promise[DefaultReserveInterestRateStrategyV2Interface] {
		return cre.PromiseFromResult[DefaultReserveInterestRateStrategyV2Interface](nil, nil)
	}
	getCalculateInterestRatesParamsFunc = func(_ cre.Runtime, _ AaveProtocolDataProviderInterface, _ common.Address, _ *big.Int) cre.Promise[*CalculateInterestRatesParams] {
		return cre.PromiseFromResult(params, nil)
	}
	calculateAPYFromContractFunc = func(_ cre.Runtime, _ DefaultReserveInterestRateStrategyV2Interface, _ *CalculateInterestRatesParams) cre.Promise[float64] {
		return cre.PromiseFromResult[float64](0, fmt.Errorf("apy-failed"))
	}

	defer func() {
		newPoolAddressesProviderBindingFunc = origProvider
		getProtocolDataProviderBindingFunc = origGetProvider
		getStrategyBindingFunc = origGetStrategy
		getCalculateInterestRatesParamsFunc = origGetParams
		calculateAPYFromContractFunc = origCalc
	}()

	apy, err := GetAPY(cfg, runtime, big.NewInt(0), 1)

	require.Error(t, err)
	require.Contains(t, err.Error(), "failed to calculate APY for chain test-chain")
	require.Contains(t, err.Error(), "apy-failed")
	require.Equal(t, 0.0, apy)
}

/*//////////////////////////////////////////////////////////////
                         SUCCESS PATHS
//////////////////////////////////////////////////////////////*/

func TestGetAPY_success_happyPath(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainName:                         "test-chain",
				ChainSelector:                     42,
				AaveV3PoolAddressesProviderAddress: "0x0000000000000000000000000000000000000001",
				USDCAddress:                       "0x0000000000000000000000000000000000000002",
			},
		},
	}
	runtime := testutils.NewRuntime(t, nil)

	liquidity := big.NewInt(1234)
	expectedAPY := 0.123

	params := &CalculateInterestRatesParams{
		TotalDebt:              big.NewInt(10),
		VirtualUnderlyingBalance: big.NewInt(20),
	}

	var (
		gotClientChainSelector uint64
		gotProviderChain       string
		gotStrategyAsset       common.Address
		gotStrategyChain       string
		gotParamsAsset         common.Address
		gotParamsLiquidity     *big.Int
		gotCalcStrategy        DefaultReserveInterestRateStrategyV2Interface
		gotCalcParams          *CalculateInterestRatesParams
	)

	expectedStrategy := DefaultReserveInterestRateStrategyV2Interface(nil)

	origProvider := newPoolAddressesProviderBindingFunc
	origGetProvider := getProtocolDataProviderBindingFunc
	origGetStrategy := getStrategyBindingFunc
	origGetParams := getCalculateInterestRatesParamsFunc
	origCalc := calculateAPYFromContractFunc

	newPoolAddressesProviderBindingFunc = func(client *evm.Client, _ string) (PoolAddressesProviderInterface, error) {
		gotClientChainSelector = client.ChainSelector
		return nil, nil
	}
	getProtocolDataProviderBindingFunc = func(_ cre.Runtime, _ *evm.Client, _ PoolAddressesProviderInterface, chainName string) cre.Promise[AaveProtocolDataProviderInterface] {
		gotProviderChain = chainName
		return cre.PromiseFromResult[AaveProtocolDataProviderInterface](nil, nil)
	}
	getStrategyBindingFunc = func(_ cre.Runtime, _ *evm.Client, _ AaveProtocolDataProviderInterface, asset common.Address, chainName string) cre.Promise[DefaultReserveInterestRateStrategyV2Interface] {
		gotStrategyAsset = asset
		gotStrategyChain = chainName
		return cre.PromiseFromResult(expectedStrategy, nil)
	}
	getCalculateInterestRatesParamsFunc = func(_ cre.Runtime, _ AaveProtocolDataProviderInterface, asset common.Address, liq *big.Int) cre.Promise[*CalculateInterestRatesParams] {
		gotParamsAsset = asset
		gotParamsLiquidity = new(big.Int).Set(liq)
		return cre.PromiseFromResult(params, nil)
	}
	calculateAPYFromContractFunc = func(_ cre.Runtime, strategy DefaultReserveInterestRateStrategyV2Interface, p *CalculateInterestRatesParams) cre.Promise[float64] {
		gotCalcStrategy = strategy
		gotCalcParams = p
		return cre.PromiseFromResult(expectedAPY, nil)
	}

	defer func() {
		newPoolAddressesProviderBindingFunc = origProvider
		getProtocolDataProviderBindingFunc = origGetProvider
		getStrategyBindingFunc = origGetStrategy
		getCalculateInterestRatesParamsFunc = origGetParams
		calculateAPYFromContractFunc = origCalc
	}()

	apy, err := GetAPY(cfg, runtime, liquidity, 42)

	require.NoError(t, err)
	require.Equal(t, expectedAPY, apy)

	// EVM client chain selector
	require.Equal(t, cfg.Evms[0].ChainSelector, gotClientChainSelector)

	// Chain name propagation
	require.Equal(t, cfg.Evms[0].ChainName, gotProviderChain)
	require.Equal(t, cfg.Evms[0].ChainName, gotStrategyChain)

	// USDC address propagation
	expectedUSDC := common.HexToAddress(cfg.Evms[0].USDCAddress)
	require.Equal(t, expectedUSDC, gotStrategyAsset)
	require.Equal(t, expectedUSDC, gotParamsAsset)

	// Liquidity propagation
	require.Equal(t, liquidity.String(), gotParamsLiquidity.String())

	// Strategy/params passed to APY calculation
	require.Equal(t, expectedStrategy, gotCalcStrategy)
	require.Equal(t, params, gotCalcParams)
}
