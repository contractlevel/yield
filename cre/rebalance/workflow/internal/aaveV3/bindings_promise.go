package aaveV3

import (
	"fmt"

	"rebalance/contracts/evm/src/generated/aave_protocol_data_provider"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// getProtocolDataProviderBinding fetches the ProtocolDataProvider address from PoolAddressesProvider
// and creates the binding. This reduces nesting in GetAPY().
//
// Parameters:
//   - runtime: CRE runtime for contract calls
//   - evmClient: EVM client for the chain
//   - poolProvider: PoolAddressesProvider binding
//   - chainName: Chain name for error messages
//
// Returns:
//   - Promise of AaveProtocolDataProviderInterface
func getProtocolDataProviderBinding(
	runtime cre.Runtime,
	evmClient *evm.Client,
	poolProvider PoolAddressesProviderInterface,
	chainName string,
) cre.Promise[AaveProtocolDataProviderInterface] {
	// logger := runtime.Logger()

	// Fetch ProtocolDataProvider address
	protocolDataProviderAddrPromise := poolProvider.GetPoolDataProvider(runtime, nil)

	return cre.Then(protocolDataProviderAddrPromise, func(protocolDataProviderAddr common.Address) (AaveProtocolDataProviderInterface, error) {
		// Validate address
		if protocolDataProviderAddr == (common.Address{}) {
			return nil, fmt.Errorf("invalid ProtocolDataProvider address: zero address for chain %s", chainName)
		}

		// logger.Info("Got ProtocolDataProvider address",
		// 	"chain", chainName,
		// 	"address", protocolDataProviderAddr.Hex())

		// Create ProtocolDataProvider binding
		// Note: .Hex() always returns valid hex, so binding creation will never fail
		protocolDataProvider, err := newAaveProtocolDataProviderBinding(evmClient, protocolDataProviderAddr.Hex())
		return protocolDataProvider, err
	})
}

// getStrategyBinding fetches the InterestRateStrategy address from ProtocolDataProvider
// and creates the binding. This reduces nesting in GetAPY().
//
// Parameters:
//   - runtime: CRE runtime for contract calls
//   - evmClient: EVM client for the chain
//   - protocolProvider: AaveProtocolDataProvider binding
//   - assetAddress: The reserve asset address (e.g., USDC address)
//   - chainName: Chain name for error messages
//
// Returns:
//   - Promise of DefaultReserveInterestRateStrategyV2Interface
func getStrategyBinding(
	runtime cre.Runtime,
	evmClient *evm.Client,
	protocolProvider AaveProtocolDataProviderInterface,
	assetAddress common.Address,
	chainName string,
) cre.Promise[DefaultReserveInterestRateStrategyV2Interface] {
	// logger := runtime.Logger()

	// Fetch strategy address
	strategyAddrPromise := protocolProvider.GetInterestRateStrategyAddress(
		runtime,
		aave_protocol_data_provider.GetInterestRateStrategyAddressInput{Arg0: assetAddress},
		nil,
	)

	return cre.Then(strategyAddrPromise, func(strategyAddr common.Address) (DefaultReserveInterestRateStrategyV2Interface, error) {
		// Validate address
		if strategyAddr == (common.Address{}) {
			return nil, fmt.Errorf("invalid Strategy address: zero address for chain %s", chainName)
		}

		// logger.Info("Got strategy address",
		// 	"chain", chainName,
		// 	"strategy", strategyAddr.Hex())

		// Create Strategy V2 binding
		// Note: .Hex() always returns valid hex, so binding creation will never fail
		strategyV2, err := newDefaultReserveInterestRateStrategyV2Binding(evmClient, strategyAddr.Hex())
		return strategyV2, err
	})
}
