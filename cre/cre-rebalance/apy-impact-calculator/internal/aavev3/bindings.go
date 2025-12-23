package aavev3

import (
	"fmt"

	"cre-rebalance/contracts/evm/src/generated/aave_protocol_data_provider"
	"cre-rebalance/contracts/evm/src/generated/default_reserve_interest_rate_strategy_v2"

	// "cre-rebalance/contracts/evm/src/generated/pool" // Unused - NewPoolBinding is commented out
	// "cre-rebalance/contracts/evm/src/generated/pool_addresses_provider" // Unused - NewPoolAddressesProviderBinding is commented out

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
)

// NewAaveProtocolDataProviderBinding constructs the Aave Protocol Data Provider binding.
// It validates the address and returns an interface for testability.
func NewAaveProtocolDataProviderBinding(
	client *evm.Client,
	addr string,
) (AaveProtocolDataProviderInterface, error) {
	if !common.IsHexAddress(addr) {
		return nil, fmt.Errorf("invalid AaveProtocolDataProvider address: %s", addr)
	}
	providerAddr := common.HexToAddress(addr)

	return aave_protocol_data_provider.NewAaveProtocolDataProvider(
		client,
		providerAddr,
		nil, // No filter options needed for reads
	)
}

// NewDefaultReserveInterestRateStrategyV2Binding constructs the Interest Rate Strategy V2 binding.
// It validates the address and returns an interface for testability.
// This is the preferred binding for new code as it supports CalculateInterestRates.
func NewDefaultReserveInterestRateStrategyV2Binding(
	client *evm.Client,
	addr string,
) (DefaultReserveInterestRateStrategyV2Interface, error) {
	if !common.IsHexAddress(addr) {
		return nil, fmt.Errorf("invalid DefaultReserveInterestRateStrategyV2 address: %s", addr)
	}
	strategyAddr := common.HexToAddress(addr)

	return default_reserve_interest_rate_strategy_v2.NewDefaultReserveInterestRateStrategyV2(
		client,
		strategyAddr,
		nil, // No filter options needed for reads
	)
}

// NewPoolAddressesProviderBinding constructs the Pool Addresses Provider binding.
// NOTE: Currently unused - we no longer need Pool address since all data comes from ProtocolDataProvider
// func NewPoolAddressesProviderBinding(
// 	client *evm.Client,
// 	addr string,
// ) (PoolAddressesProviderInterface, error) {
// 	if !common.IsHexAddress(addr) {
// 		return nil, fmt.Errorf("invalid PoolAddressesProvider address: %s", addr)
// 	}
// 	providerAddr := common.HexToAddress(addr)
//
// 	return pool_addresses_provider.NewPoolAddressesProvider(
// 		client,
// 		providerAddr,
// 		nil, // No filter options needed for reads
// 	)
// }

// NewPoolBinding constructs the Pool contract binding.
// NOTE: Currently unused - we get unbacked from ProtocolDataProvider.getReserveData().Arg0 instead
// func NewPoolBinding(
// 	client *evm.Client,
// 	poolAddr common.Address,
// ) (PoolInterface, error) {
// 	// Validate that address is not zero (uninitialized/invalid)
// 	if poolAddr == (common.Address{}) {
// 		return nil, fmt.Errorf("invalid Pool address: zero address")
// 	}
//
// 	return pool.NewPool(
// 		client,
// 		poolAddr,
// 		nil, // No filter options needed for reads
// 	)
// }
