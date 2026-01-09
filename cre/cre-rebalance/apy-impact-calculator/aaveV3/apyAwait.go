package aaveV3

import (
	"fmt"
	"math/big"

	"cre-rebalance/apy-impact-calculator/internal/helper"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// GetAPYAwait calculates the APY for AaveV3 on a specific chain.
// This version uses sequential .Await() calls instead of cre.ThenPromise chaining.
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
func GetAPYAwait(config *helper.Config, runtime cre.Runtime, liquidityAdded *big.Int, chainSelector uint64, blockNumber *big.Int) (float64, error) {
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

	logger.Info("GetAPYAwait: Starting APY calculation",
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

	// Step 3: Get ProtocolDataProvider binding
	protocolDataProviderPromise := getProtocolDataProviderBinding(runtime, evmClient, poolAddressesProvider, evmCfg.ChainName, blockNumber)
	protocolDataProvider, err := protocolDataProviderPromise.Await()
	if err != nil {
		return 0, fmt.Errorf("failed to get ProtocolDataProvider for chain %s: %w", evmCfg.ChainName, err)
	}

	// Step 4: Get USDC address
	usdcAddress := common.HexToAddress(evmCfg.USDCAddress)

	// Step 5: Get Strategy binding
	strategyPromise := getStrategyBinding(runtime, evmClient, protocolDataProvider, usdcAddress, evmCfg.ChainName, blockNumber)
	strategyV2, err := strategyPromise.Await()
	if err != nil {
		return 0, fmt.Errorf("failed to get Strategy binding for chain %s: %w", evmCfg.ChainName, err)
	}

	// Step 6: Fetch CalculateInterestRatesParams
	paramsPromise := FetchCalculateInterestRatesParams(
		runtime,
		protocolDataProvider,
		usdcAddress,
		liquidityAdded,
		blockNumber,
	)
	params, err := paramsPromise.Await()
	if err != nil {
		return 0, fmt.Errorf("failed to fetch CalculateInterestRatesParams for chain %s: %w", evmCfg.ChainName, err)
	}

	logger.Info("GetAPYAwait: Got CalculateInterestRatesParams",
		"chain", evmCfg.ChainName,
		"totalDebt", params.TotalDebt.String(),
		"virtualUnderlyingBalance", params.VirtualUnderlyingBalance.String())

	// Step 7: Calculate APY using the strategy contract
	apyPromise := CalculateAPYFromContract(runtime, strategyV2, params, blockNumber)
	apy, err := apyPromise.Await()
	if err != nil {
		return 0, fmt.Errorf("failed to calculate APY for chain %s: %w", evmCfg.ChainName, err)
	}

	logger.Info("GetAPYAwait: Calculated APY",
		"chain", evmCfg.ChainName,
		"apy", apy)

	return apy, nil
}
