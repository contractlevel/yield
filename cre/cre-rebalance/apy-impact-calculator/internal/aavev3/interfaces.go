package aavev3

import (
	"math/big"

	"cre-rebalance/contracts/evm/src/generated/aave_protocol_data_provider"
	"cre-rebalance/contracts/evm/src/generated/default_reserve_interest_rate_strategy"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// AaveProtocolDataProviderInterface abstracts the Aave Protocol Data Provider contract
// @input Asset Address
type AaveProtocolDataProviderInterface interface {
	GetReserveData(
		runtime cre.Runtime,
		input aave_protocol_data_provider.GetReserveDataInput,
		blockNumber *big.Int,
	) cre.Promise[aave_protocol_data_provider.GetReserveDataOutput]

	GetReserveConfigurationData(
		runtime cre.Runtime,
		input aave_protocol_data_provider.GetReserveConfigurationDataInput,
		blockNumber *big.Int,
	) cre.Promise[aave_protocol_data_provider.GetReserveConfigurationDataOutput]

	GetInterestRateStrategyAddress(
		runtime cre.Runtime,
		input aave_protocol_data_provider.GetInterestRateStrategyAddressInput,
		blockNumber *big.Int,
	) cre.Promise[common.Address]
}

// DefaultReserveInterestRateStrategyInterface abstracts the Interest Rate Strategy contract
// @input Asset Address
type DefaultReserveInterestRateStrategyInterface interface {
	GetInterestRateData(
		runtime cre.Runtime,
		input default_reserve_interest_rate_strategy.GetInterestRateDataInput,
		blockNumber *big.Int,
	) cre.Promise[default_reserve_interest_rate_strategy.IDefaultInterestRateStrategyV2InterestRateDataRay]
}
