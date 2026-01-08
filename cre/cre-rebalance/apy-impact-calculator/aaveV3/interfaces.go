package aaveV3

import (
	"math/big"

	"cre-rebalance/contracts/evm/src/generated/aave_protocol_data_provider"
	"cre-rebalance/contracts/evm/src/generated/default_reserve_interest_rate_strategy_v2"
	"cre-rebalance/contracts/evm/src/generated/pool"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

type PoolAddressesProviderInterface interface {
	GetPool(runtime cre.Runtime, blockNumber *big.Int) cre.Promise[common.Address]
	GetPoolDataProvider(runtime cre.Runtime, blockNumber *big.Int) cre.Promise[common.Address]
}

type PoolInterface interface {
	GetReserveData(runtime cre.Runtime, input pool.GetReserveDataInput, blockNumber *big.Int) cre.Promise[pool.GetReserveDataOutput]
}

// AaveProtocolDataProviderInterface abstracts the Aave Protocol Data Provider contract
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

	GetVirtualUnderlyingBalance(
		runtime cre.Runtime,
		input aave_protocol_data_provider.GetVirtualUnderlyingBalanceInput,
		blockNumber *big.Int,
	) cre.Promise[*big.Int]

	GetTotalDebt(
		runtime cre.Runtime,
		input aave_protocol_data_provider.GetTotalDebtInput,
		blockNumber *big.Int,
	) cre.Promise[*big.Int]
}

// DefaultReserveInterestRateStrategyV2Interface abstracts the Interest Rate Strategy contract
type DefaultReserveInterestRateStrategyV2Interface interface {
	CalculateInterestRates(
		runtime cre.Runtime,
		input default_reserve_interest_rate_strategy_v2.CalculateInterestRatesInput,
		blockNumber *big.Int,
	) cre.Promise[default_reserve_interest_rate_strategy_v2.CalculateInterestRatesOutput]
}
