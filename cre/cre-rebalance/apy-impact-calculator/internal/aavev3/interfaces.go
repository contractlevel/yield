package aaveV3

import (
	"math/big"

	"cre-rebalance/contracts/evm/src/generated/aave_protocol_data_provider"
	"cre-rebalance/contracts/evm/src/generated/default_reserve_interest_rate_strategy"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

type PoolAddressesProviderInterface interface {
	GetPool(runtime cre.RunTime, blockNumber *big.Int) cre.Promise[common.Address]
}

type PoolInterface interface {
	GetReserveData(runtime cre.RunTime, input pool.GetReserveDataInput, blockNumber *big.Int) cre.Promise[aave_protocol_data_provider.GetReserveDataOutput]
	GetConfiguration(runtime cre.RunTime, input pool.GetConfigurationInput, blockNumber *big.Int) cre.Promise[aave_protocol_data_provider.GetConfigurationOutput]
}

// AaveProtocolDataProviderInterface abstracts the Aave Protocol Data Provider contract
// @input Asset Address
type AaveProtocolDataProviderInterface interface {
	// @review we probably dont need this
	GetReserveData(
		runtime cre.Runtime,
		input aave_protocol_data_provider.GetReserveDataInput,
		blockNumber *big.Int,
	) cre.Promise[aave_protocol_data_provider.GetReserveDataOutput]

	GetTotalDebt(runtime cre.RunTime, input aave_protocol_data_provider.GetTotalDebtInput, blockNumber *big.Int) cre.Promise[*big.Int]

}

// DefaultReserveInterestRateStrategyV2Interface abstracts the Interest Rate Strategy contract
// @input Asset Address
type DefaultReserveInterestRateStrategyV2Interface interface {
	// @review we probably dont need this
	GetInterestRateData(
		runtime cre.Runtime,
		input default_reserve_interest_rate_strategy.GetInterestRateDataInput,
		blockNumber *big.Int,
	) cre.Promise[default_reserve_interest_rate_strategy.IDefaultInterestRateStrategyV2InterestRateDataRay]

	CalculateInterestRates(
		runtime cre.Runtime,
		input default_reserve_interest_rate_strategy.CalculateInterestRatesInput,
		blockNumber *big.Int,
	) cre.Promise[default_reserve_interest_rate_strategy.CalculateInterestRatesOutput]
}