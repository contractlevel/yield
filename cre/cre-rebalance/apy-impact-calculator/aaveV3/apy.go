package aaveV3

import (
	"fmt"
	"math/big"

	"cre-rebalance/apy-impact-calculator/internal/helper"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// GetAPY calculates the APY for AaveV3 on a specific chain.
// Parameters:
//   - config: The helper.Config containing all chain configurations
//   - runtime: CRE runtime for contract calls
//   - liquidityAdded: Amount of liquidity being added (use big.NewInt(0) for current APY)
//   - chainSelector: Chain selector to identify which chain config to use
//   - blockNumber: Block number to query at (nil = latest, but may cause inconsistencies due to sequential calls)
//
// Returns:
//   - APY as float64 (e.g., 0.0523 = 5.23%)
//   - Error if chain not found or APY calculation fails
//
// IMPORTANT: If blockNumber is nil, sequential contract calls may query different "latest" blocks,
// causing inconsistent values. For consistent results, pass a specific block number.
func GetAPY(config *helper.Config, runtime cre.Runtime, liquidityAdded *big.Int, chainSelector uint64, blockNumber *big.Int) (float64, error) {
	logger := runtime.Logger()

	// Find the chain config by chainSelector
	evmCfg, err := helper.FindEvmConfigByChainSelector(config.Evms, chainSelector)
	if err != nil {
		return 0, fmt.Errorf("chain config not found for chainSelector %d: %w", chainSelector, err)
	}

	// Validate required fields
	if evmCfg.AaveV3PoolAddressesProviderAddress == "" {
		return 0, fmt.Errorf("AaveV3PoolAddressesProviderAddress not configured for chain %s", evmCfg.ChainName)
	}
	if evmCfg.USDCAddress == "" {
		return 0, fmt.Errorf("USDCAddress not configured for chain %s", evmCfg.ChainName)
	}

	logger.Info("GetAPY: Starting APY calculation",
		"chain", evmCfg.ChainName,
		"chainSelector", chainSelector,
		"asset", evmCfg.USDCAddress,
		"liquidityAdded", liquidityAdded.String())

	// Step 1: Create EVM client for this chain
	evmClient := &evm.Client{
		ChainSelector: evmCfg.ChainSelector,
	}

	// Step 2: Create PoolAddressesProvider binding
	poolAddressesProvider, err := NewPoolAddressesProviderBinding(evmClient, evmCfg.AaveV3PoolAddressesProviderAddress)
	if err != nil {
		return 0, fmt.Errorf("failed to create PoolAddressesProvider binding for chain %s: %w", evmCfg.ChainName, err)
	}

	// Step 3: Get ProtocolDataProvider binding (helper reduces nesting)
	// Pass blockNumber to ensure consistency
	protocolDataProviderPromise := getProtocolDataProviderBinding(runtime, evmClient, poolAddressesProvider, evmCfg.ChainName, blockNumber)

	// Step 4: Get Strategy binding and pass ProtocolDataProvider through for params
	apyPromise := cre.ThenPromise(protocolDataProviderPromise, func(protocolDataProvider AaveProtocolDataProviderInterface) cre.Promise[float64] {
		// Get USDC address
		usdcAddress := common.HexToAddress(evmCfg.USDCAddress)

		// Get Strategy binding
		// Pass blockNumber to ensure consistency
		strategyPromise := getStrategyBinding(runtime, evmClient, protocolDataProvider, usdcAddress, evmCfg.ChainName, blockNumber)

		// Step 5: Fetch params and calculate APY
		return cre.ThenPromise(strategyPromise, func(strategyV2 DefaultReserveInterestRateStrategyV2Interface) cre.Promise[float64] {
			// Step 6: Fetch CalculateInterestRatesParams
			// Pass blockNumber to ensure all contract calls use the same block
			paramsPromise := FetchCalculateInterestRatesParams(
				runtime,
				protocolDataProvider,
				usdcAddress,
				liquidityAdded,
				blockNumber, // Use same blockNumber for all calls
			)

			// Step 7: Calculate APY using the strategy contract
			return cre.ThenPromise(paramsPromise, func(params *CalculateInterestRatesParams) cre.Promise[float64] {
				logger.Info("GetAPY: Got CalculateInterestRatesParams",
					"chain", evmCfg.ChainName,
					"totalDebt", params.TotalDebt.String(),
					"virtualUnderlyingBalance", params.VirtualUnderlyingBalance.String(),
					"blockNumber", blockNumber)

				// Pass blockNumber to ensure CalculateInterestRates uses same block as params
				return CalculateAPYFromContract(runtime, strategyV2, params, blockNumber)
			})
		})
	})

	// Await the promise to convert to synchronous return
	apy, err := apyPromise.Await()
	if err != nil {
		return 0, fmt.Errorf("failed to calculate APY for chain %s: %w", evmCfg.ChainName, err)
	}

	logger.Info("GetAPY: Calculated APY",
		"chain", evmCfg.ChainName,
		"apy", apy)

	return apy, nil
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
