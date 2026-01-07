package aaveV3

import (
	"math/big"

	"cre-rebalance/cre-rebalance-workflow/internal/helper"

	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// @review placeholder
func GetAPY(config *helper.Config, runtime cre.Runtime, liquidityAdded *big.Int, chainSelector uint64) (float64, error) {
	return 0, nil
}

// func CalculateAPY(config *helper.Config, liquidityAdded *big.Int, reserve common.Address) (*big.Int, error) {
// 	interestRatesParams, err := getCalculateInterestRatesParams(config, liquidityAdded, reserve)
// 	if err != nil {
// 		return nil, fmt.Errorf("failed to get calculate interest rates params: %w", err)
// 	}
	
// 	// instantiate DefaultReserveInterestRateStrategyV2 - this will be optimized later
// 	defaultReserveInterestRateStrategyV2, err := NewDefaultReserveInterestRateStrategyV2Binding(evmClient, config.DefaultReserveInterestRateStrategyV2Addr)
// 	if err != nil {
// 		return nil, fmt.Errorf("failed to create defaultReserveInterestRateStrategyV2 binding: %w", err)
// 	}

// 	// @review i dont think the second param is an error... is it? something else gets returned by calculateInterestRates besides the liquidity rate
// 	liquidityRate, err := defaultReserveInterestRateStrategyV2.CalculateInterestRates(evmClient, interestRatesParams, nil)
// 	if err != nil {
// 		return nil, fmt.Errorf("failed to calculate interest rates: %w", err)
// 	}

// 	apr := liquidityRate / RAY

// 	// @review this needs review
// 	apy := (1 + apr / SECONDS_PER_YEAR) ^ SECONDS_PER_YEAR - 1

// 	return apy, nil
// }

// func getCalculateInterestRatesParams(config *helper.Config, liquidityAdded *big.Int, reserve common.Address) (CalculateInterestRatesParams, error) {

// 	// this will be optimized later
// 	evmClient := &evm.Client{
// 		ChainSelector: config.Evms[0].ChainSelector, // @review which evm is being used
// 	}

// 	// instantiate pool and protocolDataProvider - this will be optimized later
// 	poolAddressesProvider, err := NewPoolAddressesProviderBinding(evmClient, config.PoolAddressesProviderAddr)
// 	if err != nil {
// 		return nil, fmt.Errorf("failed to create poolAddressesProvider binding: %w", err)
// 	}
// 	poolAddress, err := poolAddressesProvider.GetPool(evmClient, nil)
// 	if err != nil {
// 		return nil, fmt.Errorf("failed to get pool address: %w", err)
// 	}
// 	pool, err := NewPoolBinding(evmClient, poolAddress)
// 	if err != nil {
// 		return nil, fmt.Errorf("failed to create pool binding: %w", err)
// 	}
// 	// @review does the AaveProtocolDataProvider address change like pool or is it immutable like PoolAddressesProvider?
// 	protocolDataProvider, err := NewAaveProtocolDataProviderBinding(evmClient, config.ProtocolDataProviderAddr)
// 	if err != nil {
// 		return nil, fmt.Errorf("failed to create protocolDataProvider binding: %w", err)
// 	}

// 	// create CalculateInterestRatesParams
// 	reserveData, err := pool.GetReserveData(evmClient, pool.GetReserveDataInput{Asset: reserve}, nil)
// 	if err != nil {
// 		return nil, fmt.Errorf("failed to get reserve data: %w", err)
// 	}
// 	unbacked := reserveData.Unbacked
// 	liquidityTaken := big.NewInt(0)
// 	totalDebt, err := protocolDataProvider.GetTotalDebt(evmClient, protocolDataProvider.GetTotalDebtInput{Asset: reserve}, nil)
// 	if err != nil {
// 		return nil, fmt.Errorf("failed to get total debt: %w", err)
// 	}
// 	reserveConfigurationData, err := protocolDataProvider.GetReserveConfigurationData(evmClient, protocolDataProvider.GetReserveConfigurationDataInput{Asset: reserve}, nil)
// 	if err != nil {
// 		return nil, fmt.Errorf("failed to get reserve configuration data: %w", err)
// 	}
// 	reserveFactor := reserveConfigurationData.ReserveFactor
// 	usingVirtualBalance := false
// 	virtualUnderlyingBalance := big.NewInt(0)

// 	return CalculateInterestRatesParams{
// 		Unbacked: unbacked,
// 		LiquidityAdded: liquidityAdded,
// 		LiquidityTaken: liquidityTaken,
// 		TotalDebt: totalDebt,
// 		ReserveFactor: reserveFactor,
// 		Reserve: reserve,
// 		UsingVirtualBalance: usingVirtualBalance,
// 		VirtualUnderlyingBalance: virtualUnderlyingBalance,
// 	}, nil


// }

	// unbacked = pool.getReserveData(asset).unbacked
	// liquidityAdded = 0 for current APY, amount we are depositing for new APY
	// liquidityTaken = 0 (we arent simulating withdraws/borrows)
	// totalDebt = protocolDataProvider.getReserveData(asset) totalVariableDebt + totalStableDebt (totalStableDebt is deprecated)
	// reserveFactor = protocolDataProvider.getReserveConfigurationData(asset).reserveFactor (thing we already got that gets taken away) 
	// reserve = stablecoin address (USDC)
	// usingVirtualBalance = deprecated
	// virtualUnderlyingBalance = deprecated

	// Unbacked                 *big.Int
	// LiquidityAdded           *big.Int
	// LiquidityTaken           *big.Int
	// TotalDebt                *big.Int
	// ReserveFactor            *big.Int
	// Reserve                  common.Address
	// UsingVirtualBalance      bool
	// VirtualUnderlyingBalance *big.Int