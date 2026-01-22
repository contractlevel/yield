package aaveV3

import (
	"fmt"

	"rebalance/contracts/evm/src/generated/aave_protocol_data_provider"
	"rebalance/contracts/evm/src/generated/default_reserve_interest_rate_strategy_v2"
	"rebalance/contracts/evm/src/generated/pool_addresses_provider"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
)

// newPoolAddressesProviderBinding constructs the Pool Addresses Provider binding.
// It validates the address and returns an interface for testability.
func newPoolAddressesProviderBinding(client *evm.Client, addr string) (PoolAddressesProviderInterface, error) {
	if !common.IsHexAddress(addr) {
		return nil, fmt.Errorf("invalid PoolAddressesProvider address: %s", addr)
	}
	providerAddr := common.HexToAddress(addr)

	return pool_addresses_provider.NewPoolAddressesProvider(
		client,
		providerAddr,
		nil,
	)
}

// newAaveProtocolDataProviderBinding constructs the Aave Protocol Data Provider binding.
// It validates the address and returns an interface for testability.
func newAaveProtocolDataProviderBinding(client *evm.Client, addr string) (AaveProtocolDataProviderInterface, error) {
	if !common.IsHexAddress(addr) {
		return nil, fmt.Errorf("invalid AaveProtocolDataProvider address: %s", addr)
	}
	providerAddr := common.HexToAddress(addr)

	return aave_protocol_data_provider.NewAaveProtocolDataProvider(
		client,
		providerAddr,
		nil,
	)
}

// newDefaultReserveInterestRateStrategyV2Binding constructs the Interest Rate Strategy binding.
// It validates the address and returns an interface for testability.
func newDefaultReserveInterestRateStrategyV2Binding(client *evm.Client, addr string) (DefaultReserveInterestRateStrategyV2Interface, error) {
	if !common.IsHexAddress(addr) {
		return nil, fmt.Errorf("invalid DefaultReserveInterestRateStrategyV2 address: %s", addr)
	}
	strategyAddr := common.HexToAddress(addr)

	return default_reserve_interest_rate_strategy_v2.NewDefaultReserveInterestRateStrategyV2(
		client,
		strategyAddr,
		nil,
	)
}
