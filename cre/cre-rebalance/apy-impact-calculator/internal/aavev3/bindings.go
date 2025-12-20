package aavev3

import (
	"fmt"

	"cre-rebalance/contracts/evm/src/generated/aave_protocol_data_provider"
	"cre-rebalance/contracts/evm/src/generated/default_reserve_interest_rate_strategy"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
)

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

// NewDefaultReserveInterestRateStrategyBinding constructs the Interest Rate Strategy binding.
// It validates the address (checks for zero address) and returns an interface for testability.
func NewDefaultReserveInterestRateStrategyBinding(client *evm.Client, addr string) (DefaultReserveInterestRateStrategyInterface, error) {
	if !common.IsHexAddress(addr) {
		return nil, fmt.Errorf("invalid DefaultReserveInterestRateStrategy address: %s", addr)
	}
	strategyAddr := common.HexToAddress(addr)

	return default_reserve_interest_rate_strategy.NewDefaultReserveInterestRateStrategy(
		client,
		strategyAddr,
		nil, // No filter options needed for reads
	)
}
