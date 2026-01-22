package aaveV3

import (
	"fmt"
	"math/big"

	"rebalance/workflow/internal/helper"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// GetAPYPromise calculates the APY for AaveV3 on a specific chain and returns a Promise.
// This version returns a Promise instead of awaiting, allowing callers to chain or await as needed. [Needs .Await() after this is called ]
// Parameters:
//   - config: The helper.Config containing all chain configurations
//   - runtime: CRE runtime for contract calls
//   - liquidityAdded: Amount of liquidity being added (use big.NewInt(0) for current APY)
//   - chainSelector: Chain selector to identify which chain config to use
//
// Returns:
//   - Promise of APY as float64 (e.g., 0.0523 = 5.23%)
//   - Error will be returned when Promise is awaited if chain not found or APY calculation fails
func GetAPYPromise(config *helper.Config, runtime cre.Runtime, liquidityAdded *big.Int, chainSelector uint64) cre.Promise[float64] {
	// logger := runtime.Logger()

	// Find the chain config by chainSelector
	evmCfg, err := helper.FindEvmConfigByChainSelector(config.Evms, chainSelector)
	if err != nil {
		return cre.PromiseFromResult(0.0, fmt.Errorf("chain config not found for chainSelector %d: %w", chainSelector, err))
	}

	// Validate required fields
	if evmCfg.AaveV3PoolAddressesProviderAddress == "" {
		return cre.PromiseFromResult(0.0, fmt.Errorf("AaveV3PoolAddressesProviderAddress not configured for chain %s", evmCfg.ChainName))
	}
	if evmCfg.USDCAddress == "" {
		return cre.PromiseFromResult(0.0, fmt.Errorf("USDCAddress not configured for chain %s", evmCfg.ChainName))
	}

	// Validate liquidityAdded is not nil (can be nil if contract call returns nil)
	if liquidityAdded == nil {
		return cre.PromiseFromResult(0.0, fmt.Errorf("liquidityAdded cannot be nil (use big.NewInt(0) for zero value)"))
	}

	// logger.Info("GetAPYPromise: Starting APY calculation",
	// 	"chain", evmCfg.ChainName,
	// 	"chainSelector", chainSelector,
	// 	"asset", evmCfg.USDCAddress,
	// 	"liquidityAdded", liquidityAdded.String())

	// Step 1: Create EVM client for this chain
	evmClient := &evm.Client{
		ChainSelector: evmCfg.ChainSelector,
	}

	// Step 2: Create PoolAddressesProvider binding
	poolAddressesProvider, err := newPoolAddressesProviderBindingFunc(evmClient, evmCfg.AaveV3PoolAddressesProviderAddress)
	if err != nil {
		return cre.PromiseFromResult(0.0, fmt.Errorf("failed to create PoolAddressesProvider binding for chain %s: %w", evmCfg.ChainName, err))
	}

	// Step 3: Get ProtocolDataProvider binding
	protocolDataProviderPromise := getProtocolDataProviderBindingFunc(runtime, evmClient, poolAddressesProvider, evmCfg.ChainName)

	// Step 4: Chain promises to build the full calculation pipeline
	return cre.ThenPromise(protocolDataProviderPromise, func(protocolDataProvider AaveProtocolDataProviderInterface) cre.Promise[float64] {
		// Get USDC address
		usdcAddress := common.HexToAddress(evmCfg.USDCAddress)

		// Step 5: Get Strategy binding
		strategyPromise := getStrategyBindingFunc(runtime, evmClient, protocolDataProvider, usdcAddress, evmCfg.ChainName)

		// Step 6: Fetch params and calculate APY
		return cre.ThenPromise(strategyPromise, func(strategyV2 DefaultReserveInterestRateStrategyV2Interface) cre.Promise[float64] {
			// Step 7: Fetch CalculateInterestRatesParams
			paramsPromise := getCalculateInterestRatesParamsFunc(
				runtime,
				protocolDataProvider,
				usdcAddress,
				liquidityAdded,
			)

			// Step 8: Calculate APY using the strategy contract
			return cre.ThenPromise(paramsPromise, func(params *CalculateInterestRatesParams) cre.Promise[float64] {
				// logger.Info("GetAPYPromise: Got CalculateInterestRatesParams",
				// 	"chain", evmCfg.ChainName,
				// 	"totalDebt", params.TotalDebt.String(),
				// 	"virtualUnderlyingBalance", params.VirtualUnderlyingBalance.String())

				return calculateAPYFromContractFunc(runtime, strategyV2, params)
			})
		})
	})
}
