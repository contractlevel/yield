package aavev3

import (
	"math/big"

	"cre-rebalance/contracts/evm/src/generated/aave_protocol_data_provider"
	"cre-rebalance/contracts/evm/src/generated/default_reserve_interest_rate_strategy_v2"

	// "cre-rebalance/contracts/evm/src/generated/pool" // Unused - PoolInterface is commented out

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

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

	// GetTotalDebt is currently unused - we get totalDebt from GetReserveData() instead
	// GetTotalDebt(
	// 	runtime cre.Runtime,
	// 	input aave_protocol_data_provider.GetTotalDebtInput,
	// 	blockNumber *big.Int,
	// ) cre.Promise[*big.Int]
}

// DefaultReserveInterestRateStrategyV2Interface abstracts the Interest Rate Strategy V2 contract
type DefaultReserveInterestRateStrategyV2Interface interface {
	CalculateInterestRates(
		runtime cre.Runtime,
		input default_reserve_interest_rate_strategy_v2.CalculateInterestRatesInput,
		blockNumber *big.Int,
	) cre.Promise[default_reserve_interest_rate_strategy_v2.CalculateInterestRatesOutput]

	// GetInterestRateData is currently unused - we use CalculateInterestRates instead
	// GetInterestRateData(
	// 	runtime cre.Runtime,
	// 	input default_reserve_interest_rate_strategy_v2.GetInterestRateDataInput,
	// 	blockNumber *big.Int,
	// ) cre.Promise[default_reserve_interest_rate_strategy_v2.IDefaultInterestRateStrategyV2InterestRateDataRay]
}

// PoolAddressesProviderInterface abstracts the Pool Addresses Provider contract
// NOTE: Currently unused - we no longer need Pool address since all data comes from ProtocolDataProvider
// type PoolAddressesProviderInterface interface {
// 	GetPool(runtime cre.Runtime, blockNumber *big.Int) cre.Promise[common.Address]
// }

// PoolInterface abstracts the Pool contract
// NOTE: Currently unused - we get unbacked from ProtocolDataProvider.getReserveData().Arg0 instead
// type PoolInterface interface {
// 	GetReserveData(
// 		runtime cre.Runtime,
// 		input pool.GetReserveDataInput,
// 		blockNumber *big.Int,
// 	) cre.Promise[pool.GetReserveDataOutput]
// }
