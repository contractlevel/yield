package aaveV3

import (
	"fmt"

	"cre-rebalance/contracts/evm/src/generated/aave_protocol_data_provider"
	"cre-rebalance/contracts/evm/src/generated/default_reserve_interest_rate_strategy"
	// @review these need to be added to contracts/evm/src/generated/
	// "cre-rebalance/contracts/evm/src/generated/pool"
	// "cre-rebalance/contracts/evm/src/generated/pool_addresses_provider"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
)

func NewPoolAddressesProviderBinding(client *evm.Client, addr string) (PoolAddressesProviderInterface, error) {
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

func NewPoolBinding(client *evm.Client, poolAddr common.Address) (PoolInterface, error) {
	return pool.NewPool(client, poolAddr, nil)
}

// NewAaveProtocolDataProviderBinding constructs the Aave Protocol Data Provider binding.
// It validates the address and returns an interface for testability.
func NewAaveProtocolDataProviderBinding(client *evm.Client, addr string) (AaveProtocolDataProviderInterface, error) {
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

// NewDefaultReserveInterestRateStrategyV2Binding constructs the Interest Rate Strategy binding.
// It validates the address and returns an interface for testability.
func NewDefaultReserveInterestRateStrategyV2Binding(client *evm.Client, addr string) (DefaultReserveInterestRateStrategyV2Interface, error) {
	if !common.IsHexAddress(addr) {
		return nil, fmt.Errorf("invalid DefaultReserveInterestRateStrategyV2 address: %s", addr)
	}
	strategyAddr := common.HexToAddress(addr)

	return default_reserve_interest_rate_strategy.NewDefaultReserveInterestRateStrategyV2(
		client,
		strategyAddr,
		nil, // No filter options needed for reads
	)
}
