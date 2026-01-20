package aaveV3

import (
	"errors"
	"math/big"
	"testing"

	"rebalance/contracts/evm/src/generated/aave_protocol_data_provider"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"
)

/*//////////////////////////////////////////////////////////////
                    TEST HELPERS / MOCKS
//////////////////////////////////////////////////////////////*/

type mockProtocolDataProviderForRead struct {
	getReserveDataFunc                 func(cre.Runtime, aave_protocol_data_provider.GetReserveDataInput, *big.Int) cre.Promise[aave_protocol_data_provider.GetReserveDataOutput]
	getVirtualUnderlyingBalanceFunc    func(cre.Runtime, aave_protocol_data_provider.GetVirtualUnderlyingBalanceInput, *big.Int) cre.Promise[*big.Int]
	getReserveConfigurationDataFunc    func(cre.Runtime, aave_protocol_data_provider.GetReserveConfigurationDataInput, *big.Int) cre.Promise[aave_protocol_data_provider.GetReserveConfigurationDataOutput]
	getInterestRateStrategyAddressFunc func(cre.Runtime, aave_protocol_data_provider.GetInterestRateStrategyAddressInput, *big.Int) cre.Promise[common.Address]
}

func (m *mockProtocolDataProviderForRead) GetReserveData(runtime cre.Runtime, input aave_protocol_data_provider.GetReserveDataInput, blockNumber *big.Int) cre.Promise[aave_protocol_data_provider.GetReserveDataOutput] {
	if m.getReserveDataFunc != nil {
		return m.getReserveDataFunc(runtime, input, blockNumber)
	}
	return cre.PromiseFromResult(aave_protocol_data_provider.GetReserveDataOutput{}, errors.New("not implemented"))
}

func (m *mockProtocolDataProviderForRead) GetReserveConfigurationData(runtime cre.Runtime, input aave_protocol_data_provider.GetReserveConfigurationDataInput, blockNumber *big.Int) cre.Promise[aave_protocol_data_provider.GetReserveConfigurationDataOutput] {
	if m.getReserveConfigurationDataFunc != nil {
		return m.getReserveConfigurationDataFunc(runtime, input, blockNumber)
	}
	return cre.PromiseFromResult(aave_protocol_data_provider.GetReserveConfigurationDataOutput{}, errors.New("not implemented"))
}

func (m *mockProtocolDataProviderForRead) GetInterestRateStrategyAddress(runtime cre.Runtime, input aave_protocol_data_provider.GetInterestRateStrategyAddressInput, blockNumber *big.Int) cre.Promise[common.Address] {
	if m.getInterestRateStrategyAddressFunc != nil {
		return m.getInterestRateStrategyAddressFunc(runtime, input, blockNumber)
	}
	return cre.PromiseFromResult(common.Address{}, errors.New("not implemented"))
}

func (m *mockProtocolDataProviderForRead) GetVirtualUnderlyingBalance(runtime cre.Runtime, input aave_protocol_data_provider.GetVirtualUnderlyingBalanceInput, blockNumber *big.Int) cre.Promise[*big.Int] {
	if m.getVirtualUnderlyingBalanceFunc != nil {
		return m.getVirtualUnderlyingBalanceFunc(runtime, input, blockNumber)
	}
	return cre.PromiseFromResult[*big.Int](nil, errors.New("not implemented"))
}

/*//////////////////////////////////////////////////////////////
         FETCH CALCULATE INTEREST RATES PARAMS TESTS
//////////////////////////////////////////////////////////////*/

func Test_getCalculateInterestRatesParams_success(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)
	reserveAddress := common.HexToAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")
	liquidityAdded := big.NewInt(1000000) // 1 USDC (6 decimals)

	unbacked := big.NewInt(5000000)
	totalStableDebt := big.NewInt(10000000)
	totalVariableDebt := big.NewInt(20000000)
	virtualUnderlyingBalance := big.NewInt(50000000)
	reserveFactor := big.NewInt(1000) // 10% in basis points

	mockProvider := &mockProtocolDataProviderForRead{
		getReserveDataFunc: func(_ cre.Runtime, input aave_protocol_data_provider.GetReserveDataInput, _ *big.Int) cre.Promise[aave_protocol_data_provider.GetReserveDataOutput] {
			require.Equal(t, reserveAddress, input.Asset, "should pass correct reserve address")
			return cre.PromiseFromResult(aave_protocol_data_provider.GetReserveDataOutput{
				Arg0:              unbacked,
				Arg3:              totalStableDebt, // Unnamed field (totalStableDebt)
				TotalVariableDebt: totalVariableDebt,
			}, nil)
		},
		getVirtualUnderlyingBalanceFunc: func(_ cre.Runtime, input aave_protocol_data_provider.GetVirtualUnderlyingBalanceInput, _ *big.Int) cre.Promise[*big.Int] {
			require.Equal(t, reserveAddress, input.Asset, "should pass correct reserve address")
			return cre.PromiseFromResult(virtualUnderlyingBalance, nil)
		},
		getReserveConfigurationDataFunc: func(_ cre.Runtime, input aave_protocol_data_provider.GetReserveConfigurationDataInput, _ *big.Int) cre.Promise[aave_protocol_data_provider.GetReserveConfigurationDataOutput] {
			require.Equal(t, reserveAddress, input.Asset, "should pass correct reserve address")
			return cre.PromiseFromResult(aave_protocol_data_provider.GetReserveConfigurationDataOutput{
				ReserveFactor: reserveFactor,
			}, nil)
		},
	}

	promise := getCalculateInterestRatesParams(runtime, mockProvider, reserveAddress, liquidityAdded)
	params, err := promise.Await()

	require.NoError(t, err)
	require.NotNil(t, params)
	require.Equal(t, unbacked, params.Unbacked)
	require.Equal(t, liquidityAdded, params.LiquidityAdded)
	require.Equal(t, big.NewInt(0), params.LiquidityTaken)
	require.Equal(t, big.NewInt(30000000), params.TotalDebt) // totalStableDebt + totalVariableDebt
	require.Equal(t, reserveFactor, params.ReserveFactor)
	require.Equal(t, reserveAddress, params.Reserve)
	require.True(t, params.UsingVirtualBalance)
	require.Equal(t, virtualUnderlyingBalance, params.VirtualUnderlyingBalance)
}

func Test_getCalculateInterestRatesParams_zeroLiquidityAdded(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)
	reserveAddress := common.HexToAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")
	liquidityAdded := big.NewInt(0) // Current APY scenario

	unbacked := big.NewInt(5000000)
	totalStableDebt := big.NewInt(10000000)
	totalVariableDebt := big.NewInt(20000000)
	virtualUnderlyingBalance := big.NewInt(50000000)
	reserveFactor := big.NewInt(1000)

	mockProvider := &mockProtocolDataProviderForRead{
		getReserveDataFunc: func(_ cre.Runtime, _ aave_protocol_data_provider.GetReserveDataInput, _ *big.Int) cre.Promise[aave_protocol_data_provider.GetReserveDataOutput] {
			return cre.PromiseFromResult(aave_protocol_data_provider.GetReserveDataOutput{
				Arg0:              unbacked,
				Arg3:              totalStableDebt,
				TotalVariableDebt: totalVariableDebt,
			}, nil)
		},
		getVirtualUnderlyingBalanceFunc: func(_ cre.Runtime, _ aave_protocol_data_provider.GetVirtualUnderlyingBalanceInput, _ *big.Int) cre.Promise[*big.Int] {
			return cre.PromiseFromResult(virtualUnderlyingBalance, nil)
		},
		getReserveConfigurationDataFunc: func(_ cre.Runtime, _ aave_protocol_data_provider.GetReserveConfigurationDataInput, _ *big.Int) cre.Promise[aave_protocol_data_provider.GetReserveConfigurationDataOutput] {
			return cre.PromiseFromResult(aave_protocol_data_provider.GetReserveConfigurationDataOutput{
				ReserveFactor: reserveFactor,
			}, nil)
		},
	}

	promise := getCalculateInterestRatesParams(runtime, mockProvider, reserveAddress, liquidityAdded)
	params, err := promise.Await()

	require.NoError(t, err)
	require.NotNil(t, params)
	require.Equal(t, big.NewInt(0), params.LiquidityAdded)
}

func Test_getCalculateInterestRatesParams_zeroDebt(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)
	reserveAddress := common.HexToAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")
	liquidityAdded := big.NewInt(1000000)

	unbacked := big.NewInt(5000000)
	virtualUnderlyingBalance := big.NewInt(50000000)
	reserveFactor := big.NewInt(1000)

	mockProvider := &mockProtocolDataProviderForRead{
		getReserveDataFunc: func(_ cre.Runtime, _ aave_protocol_data_provider.GetReserveDataInput, _ *big.Int) cre.Promise[aave_protocol_data_provider.GetReserveDataOutput] {
			return cre.PromiseFromResult(aave_protocol_data_provider.GetReserveDataOutput{
				Arg0:              unbacked,
				Arg3:              big.NewInt(0), // Zero stable debt
				TotalVariableDebt: big.NewInt(0), // Zero variable debt
			}, nil)
		},
		getVirtualUnderlyingBalanceFunc: func(_ cre.Runtime, _ aave_protocol_data_provider.GetVirtualUnderlyingBalanceInput, _ *big.Int) cre.Promise[*big.Int] {
			return cre.PromiseFromResult(virtualUnderlyingBalance, nil)
		},
		getReserveConfigurationDataFunc: func(_ cre.Runtime, _ aave_protocol_data_provider.GetReserveConfigurationDataInput, _ *big.Int) cre.Promise[aave_protocol_data_provider.GetReserveConfigurationDataOutput] {
			return cre.PromiseFromResult(aave_protocol_data_provider.GetReserveConfigurationDataOutput{
				ReserveFactor: reserveFactor,
			}, nil)
		},
	}

	promise := getCalculateInterestRatesParams(runtime, mockProvider, reserveAddress, liquidityAdded)
	params, err := promise.Await()

	require.NoError(t, err)
	require.NotNil(t, params)
	require.Equal(t, big.NewInt(0), params.TotalDebt)
}

func Test_getCalculateInterestRatesParams_getReserveDataError(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)
	reserveAddress := common.HexToAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")
	liquidityAdded := big.NewInt(1000000)

	mockProvider := &mockProtocolDataProviderForRead{
		getReserveDataFunc: func(_ cre.Runtime, _ aave_protocol_data_provider.GetReserveDataInput, _ *big.Int) cre.Promise[aave_protocol_data_provider.GetReserveDataOutput] {
			return cre.PromiseFromResult(aave_protocol_data_provider.GetReserveDataOutput{}, errors.New("contract call failed"))
		},
	}

	promise := getCalculateInterestRatesParams(runtime, mockProvider, reserveAddress, liquidityAdded)
	params, err := promise.Await()

	require.Error(t, err)
	require.Nil(t, params)
	require.ErrorContains(t, err, "contract call failed")
}

func Test_getCalculateInterestRatesParams_getVirtualUnderlyingBalanceError(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)
	reserveAddress := common.HexToAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")
	liquidityAdded := big.NewInt(1000000)

	unbacked := big.NewInt(5000000)
	totalStableDebt := big.NewInt(10000000)
	totalVariableDebt := big.NewInt(20000000)

	mockProvider := &mockProtocolDataProviderForRead{
		getReserveDataFunc: func(_ cre.Runtime, _ aave_protocol_data_provider.GetReserveDataInput, _ *big.Int) cre.Promise[aave_protocol_data_provider.GetReserveDataOutput] {
			return cre.PromiseFromResult(aave_protocol_data_provider.GetReserveDataOutput{
				Arg0:              unbacked,
				Arg3:              totalStableDebt,
				TotalVariableDebt: totalVariableDebt,
			}, nil)
		},
		getVirtualUnderlyingBalanceFunc: func(_ cre.Runtime, _ aave_protocol_data_provider.GetVirtualUnderlyingBalanceInput, _ *big.Int) cre.Promise[*big.Int] {
			return cre.PromiseFromResult[*big.Int](nil, errors.New("virtual balance call failed"))
		},
	}

	promise := getCalculateInterestRatesParams(runtime, mockProvider, reserveAddress, liquidityAdded)
	params, err := promise.Await()

	require.Error(t, err)
	require.Nil(t, params)
	require.ErrorContains(t, err, "virtual balance call failed")
}

func Test_getCalculateInterestRatesParams_getReserveConfigurationDataError(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)
	reserveAddress := common.HexToAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")
	liquidityAdded := big.NewInt(1000000)

	unbacked := big.NewInt(5000000)
	totalStableDebt := big.NewInt(10000000)
	totalVariableDebt := big.NewInt(20000000)
	virtualUnderlyingBalance := big.NewInt(50000000)

	mockProvider := &mockProtocolDataProviderForRead{
		getReserveDataFunc: func(_ cre.Runtime, _ aave_protocol_data_provider.GetReserveDataInput, _ *big.Int) cre.Promise[aave_protocol_data_provider.GetReserveDataOutput] {
			return cre.PromiseFromResult(aave_protocol_data_provider.GetReserveDataOutput{
				Arg0:              unbacked,
				Arg3:              totalStableDebt,
				TotalVariableDebt: totalVariableDebt,
			}, nil)
		},
		getVirtualUnderlyingBalanceFunc: func(_ cre.Runtime, _ aave_protocol_data_provider.GetVirtualUnderlyingBalanceInput, _ *big.Int) cre.Promise[*big.Int] {
			return cre.PromiseFromResult(virtualUnderlyingBalance, nil)
		},
		getReserveConfigurationDataFunc: func(_ cre.Runtime, _ aave_protocol_data_provider.GetReserveConfigurationDataInput, _ *big.Int) cre.Promise[aave_protocol_data_provider.GetReserveConfigurationDataOutput] {
			return cre.PromiseFromResult(aave_protocol_data_provider.GetReserveConfigurationDataOutput{}, errors.New("config call failed"))
		},
	}

	promise := getCalculateInterestRatesParams(runtime, mockProvider, reserveAddress, liquidityAdded)
	params, err := promise.Await()

	require.Error(t, err)
	require.Nil(t, params)
	require.ErrorContains(t, err, "config call failed")
}
