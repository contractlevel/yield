package aaveV3

import (
	"errors"
	"math/big"
	"testing"

	"rebalance/contracts/evm/src/generated/aave_protocol_data_provider"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"
)

/*//////////////////////////////////////////////////////////////
                    TEST HELPERS / MOCKS
//////////////////////////////////////////////////////////////*/

type mockPoolAddressesProvider struct {
	getPoolDataProviderFunc func(cre.Runtime, *big.Int) cre.Promise[common.Address]
}

func (m *mockPoolAddressesProvider) GetPool(runtime cre.Runtime, blockNumber *big.Int) cre.Promise[common.Address] {
	return cre.PromiseFromResult(common.Address{}, errors.New("not implemented"))
}

func (m *mockPoolAddressesProvider) GetPoolDataProvider(runtime cre.Runtime, blockNumber *big.Int) cre.Promise[common.Address] {
	if m.getPoolDataProviderFunc != nil {
		return m.getPoolDataProviderFunc(runtime, blockNumber)
	}
	return cre.PromiseFromResult(common.Address{}, errors.New("not implemented"))
}

type mockAaveProtocolDataProvider struct {
	getInterestRateStrategyAddressFunc func(cre.Runtime, aave_protocol_data_provider.GetInterestRateStrategyAddressInput, *big.Int) cre.Promise[common.Address]
}

func (m *mockAaveProtocolDataProvider) GetReserveData(runtime cre.Runtime, input aave_protocol_data_provider.GetReserveDataInput, blockNumber *big.Int) cre.Promise[aave_protocol_data_provider.GetReserveDataOutput] {
	return cre.PromiseFromResult(aave_protocol_data_provider.GetReserveDataOutput{}, errors.New("not implemented"))
}

func (m *mockAaveProtocolDataProvider) GetReserveConfigurationData(runtime cre.Runtime, input aave_protocol_data_provider.GetReserveConfigurationDataInput, blockNumber *big.Int) cre.Promise[aave_protocol_data_provider.GetReserveConfigurationDataOutput] {
	return cre.PromiseFromResult(aave_protocol_data_provider.GetReserveConfigurationDataOutput{}, errors.New("not implemented"))
}

func (m *mockAaveProtocolDataProvider) GetInterestRateStrategyAddress(runtime cre.Runtime, input aave_protocol_data_provider.GetInterestRateStrategyAddressInput, blockNumber *big.Int) cre.Promise[common.Address] {
	if m.getInterestRateStrategyAddressFunc != nil {
		return m.getInterestRateStrategyAddressFunc(runtime, input, blockNumber)
	}
	return cre.PromiseFromResult(common.Address{}, errors.New("not implemented"))
}

func (m *mockAaveProtocolDataProvider) GetVirtualUnderlyingBalance(runtime cre.Runtime, input aave_protocol_data_provider.GetVirtualUnderlyingBalanceInput, blockNumber *big.Int) cre.Promise[*big.Int] {
	return cre.PromiseFromResult[*big.Int](nil, errors.New("not implemented"))
}

/*//////////////////////////////////////////////////////////////
         GET PROTOCOL DATA PROVIDER BINDING TESTS
//////////////////////////////////////////////////////////////*/

func Test_getProtocolDataProviderBinding_success(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)
	evmClient := &evm.Client{ChainSelector: 5009297550715157269}
	chainName := "ethereum-mainnet"

	validAddress := common.HexToAddress("0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3")

	mockPoolProvider := &mockPoolAddressesProvider{
		getPoolDataProviderFunc: func(_ cre.Runtime, _ *big.Int) cre.Promise[common.Address] {
			return cre.PromiseFromResult(validAddress, nil)
		},
	}

	// We need to mock NewAaveProtocolDataProviderBinding to return our mock
	promise := getProtocolDataProviderBinding(runtime, evmClient, mockPoolProvider, chainName)
	result, err := promise.Await()

	require.NoError(t, err)
	require.NotNil(t, result)
	// result is already AaveProtocolDataProviderInterface (returned from getProtocolDataProviderBinding)
}

func Test_getProtocolDataProviderBinding_zeroAddress(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)
	evmClient := &evm.Client{ChainSelector: 5009297550715157269}
	chainName := "ethereum-mainnet"

	mockPoolProvider := &mockPoolAddressesProvider{
		getPoolDataProviderFunc: func(_ cre.Runtime, _ *big.Int) cre.Promise[common.Address] {
			return cre.PromiseFromResult(common.Address{}, nil) // Zero address
		},
	}

	promise := getProtocolDataProviderBinding(runtime, evmClient, mockPoolProvider, chainName)
	result, err := promise.Await()

	require.Error(t, err)
	require.Nil(t, result)
	require.ErrorContains(t, err, "invalid ProtocolDataProvider address: zero address")
	require.ErrorContains(t, err, chainName)
}

func Test_getProtocolDataProviderBinding_contractCallError(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)
	evmClient := &evm.Client{ChainSelector: 5009297550715157269}
	chainName := "ethereum-mainnet"

	mockPoolProvider := &mockPoolAddressesProvider{
		getPoolDataProviderFunc: func(_ cre.Runtime, _ *big.Int) cre.Promise[common.Address] {
			return cre.PromiseFromResult(common.Address{}, errors.New("contract call failed"))
		},
	}

	promise := getProtocolDataProviderBinding(runtime, evmClient, mockPoolProvider, chainName)
	result, err := promise.Await()

	require.Error(t, err)
	require.Nil(t, result)
	require.ErrorContains(t, err, "contract call failed")
}

/*//////////////////////////////////////////////////////////////
              GET STRATEGY BINDING TESTS
//////////////////////////////////////////////////////////////*/

func Test_getStrategyBinding_success(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)
	evmClient := &evm.Client{ChainSelector: 5009297550715157269}
	chainName := "ethereum-mainnet"
	assetAddress := common.HexToAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")

	validStrategyAddress := common.HexToAddress("0x24701A00ba4631705502380704D3c1278a6b5E8D")

	mockProtocolProvider := &mockAaveProtocolDataProvider{
		getInterestRateStrategyAddressFunc: func(_ cre.Runtime, input aave_protocol_data_provider.GetInterestRateStrategyAddressInput, _ *big.Int) cre.Promise[common.Address] {
			require.Equal(t, assetAddress, input.Arg0, "should pass correct asset address")
			return cre.PromiseFromResult(validStrategyAddress, nil)
		},
	}

	promise := getStrategyBinding(runtime, evmClient, mockProtocolProvider, assetAddress, chainName)
	result, err := promise.Await()

	require.NoError(t, err)
	require.NotNil(t, result)
	// result is already DefaultReserveInterestRateStrategyV2Interface (returned from getStrategyBinding)
}

func Test_getStrategyBinding_zeroAddress(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)
	evmClient := &evm.Client{ChainSelector: 5009297550715157269}
	chainName := "ethereum-mainnet"
	assetAddress := common.HexToAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")

	mockProtocolProvider := &mockAaveProtocolDataProvider{
		getInterestRateStrategyAddressFunc: func(_ cre.Runtime, _ aave_protocol_data_provider.GetInterestRateStrategyAddressInput, _ *big.Int) cre.Promise[common.Address] {
			return cre.PromiseFromResult(common.Address{}, nil) // Zero address
		},
	}

	promise := getStrategyBinding(runtime, evmClient, mockProtocolProvider, assetAddress, chainName)
	result, err := promise.Await()

	require.Error(t, err)
	require.Nil(t, result)
	require.ErrorContains(t, err, "invalid Strategy address: zero address")
	require.ErrorContains(t, err, chainName)
}

func Test_getStrategyBinding_contractCallError(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)
	evmClient := &evm.Client{ChainSelector: 5009297550715157269}
	chainName := "ethereum-mainnet"
	assetAddress := common.HexToAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48")

	mockProtocolProvider := &mockAaveProtocolDataProvider{
		getInterestRateStrategyAddressFunc: func(_ cre.Runtime, _ aave_protocol_data_provider.GetInterestRateStrategyAddressInput, _ *big.Int) cre.Promise[common.Address] {
			return cre.PromiseFromResult(common.Address{}, errors.New("contract call failed"))
		},
	}

	promise := getStrategyBinding(runtime, evmClient, mockProtocolProvider, assetAddress, chainName)
	result, err := promise.Await()

	require.Error(t, err)
	require.Nil(t, result)
	require.ErrorContains(t, err, "contract call failed")
}
