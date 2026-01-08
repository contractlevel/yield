//go:build wasip1

package main

import (
	"fmt"
	"log/slog"
	"math/big"

	"cre-rebalance/apy-impact-calculator/aaveV3"
	"cre-rebalance/apy-impact-calculator/internal/helper"

	//@review Could we abstract that too?
	"cre-rebalance/contracts/evm/src/generated/aave_protocol_data_provider"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// WorkflowResult is the final output
// TargetChain contains the chain with the highest projected APY, used by other workflows for on-chain writes
type WorkflowResult struct {
	DepositAmount string               `json:"depositAmount"` // Deposit amount as string (USDC raw units with 6 decimals)
	Results       []aaveV3.ChainResult `json:"results"`
	TargetChain   *aaveV3.TargetChain  `json:"targetChain,omitempty"` // Best chain (highest NewAPY)
}

func InitWorkflow(config *Config, logger *slog.Logger, secretsProvider cre.SecretsProvider) (cre.Workflow[*Config], error) {
	cronTriggerCfg := &cron.Config{
		Schedule: config.Schedule,
	}
	workflow := cre.Workflow[*Config]{
		cre.Handler(
			cron.Trigger(cronTriggerCfg),
			onCronTrigger,
		),
	}
	return workflow, nil
}

func onCronTrigger(config *Config, runtime cre.Runtime, outputs *cron.Payload) (*WorkflowResult, error) {
	logger := runtime.Logger()
	logger.Info("Starting AAVE APY Impact Calculator", "depositUSDC", config.DepositUSDC)

	// Parse deposit amount as big.Int (amount in USDC raw units with 6 decimals, e.g., "1000000" = 1 USDC)
	depositAmountRaw := new(big.Int)
	depositAmountRaw, ok := depositAmountRaw.SetString(config.DepositUSDC, 10)
	if !ok {
		return nil, fmt.Errorf("invalid deposit amount: %s", config.DepositUSDC)
	}

	// Check for zero or negative deposit
	if depositAmountRaw.Sign() <= 0 {
		return nil, fmt.Errorf("deposit amount must be positive: %s", config.DepositUSDC)
	}

	// Sanity check: 1 trillion USDC in raw units = 1e18 (unrealistic)
	maxDeposit := new(big.Int)
	maxDeposit.SetString("1000000000000000000", 10) // 1e18
	if depositAmountRaw.Cmp(maxDeposit) > 0 {
		logger.Warn("Very large deposit amount detected", "amount", depositAmountRaw.String())
	}

	logger.Info("Parsed deposit amount", "raw", depositAmountRaw.String())

	// Convert workflow Config to helper.Config format for GetAPY
	helperConfig := &helper.Config{
		Schedule: config.Schedule,
		Evms:     make([]helper.EvmConfig, len(config.Chains)),
	}
	for i, chainCfg := range config.Chains {
		helperConfig.Evms[i] = helper.EvmConfig{
			ChainName:                          chainCfg.ChainName,
			ChainSelector:                      chainCfg.ChainSelector,
			USDCAddress:                        chainCfg.USDCAddress,
			AaveV3PoolAddressesProviderAddress: chainCfg.PoolAddressesProvider,
		}
	}

	// Process each chain in parallel using CRE promises
	chainPromises := make([]cre.Promise[*aaveV3.ChainResult], 0, len(config.Chains))

	for _, chainCfg := range config.Chains {
		// Create a promise for each chain calculation
		promise := processChain(runtime, helperConfig, chainCfg, depositAmountRaw)
		chainPromises = append(chainPromises, promise)
	}

	// Await all promises (parallel execution with consensus)
	results := make([]aaveV3.ChainResult, 0, len(chainPromises))
	for i, promise := range chainPromises {
		result, err := promise.Await()
		if err != nil {
			logger.Error("Failed to process chain",
				"chain", config.Chains[i].ChainName,
				"error", err)
			continue
		}
		results = append(results, *result)
	}

	// Find the chain with the highest projected APY
	var targetChain *aaveV3.TargetChain
	if len(results) > 0 {
		bestChain, err := aaveV3.FindBestChain(results, config.Chains)
		if err != nil {
			logger.Warn("Failed to determine best chain", "error", err)
		} else {
			targetChain = bestChain
			// Find the corresponding result and chain config to log details
			for _, result := range results {
				for _, chainCfg := range config.Chains {
					if chainCfg.ChainSelector == targetChain.ChainSelector && chainCfg.ChainName == result.ChainName {
						logger.Info("Best chain selected (highest NewAPY)",
							"chainSelector", targetChain.ChainSelector,
							"chainName", targetChain.ChainName,
							"newAPY", targetChain.NewAPY,
							"stablecoinId", targetChain.StablecoinId,
							"stablecoinAddress", targetChain.StablecoinAddress)
						break
					}
				}
			}
		}
	}

	return &WorkflowResult{
		DepositAmount: depositAmountRaw.String(), // Store as string to preserve precision
		Results:       results,
		TargetChain:   targetChain,
	}, nil
}

func processChain(runtime cre.Runtime, helperConfig *helper.Config, chainCfg aaveV3.ChainConfig, depositAmountRaw *big.Int) cre.Promise[*aaveV3.ChainResult] {
	logger := runtime.Logger()
	usdcAddress := common.HexToAddress(chainCfg.USDCAddress)

	logger.Info("Processing chain", "chain", chainCfg.ChainName, "usdcAddress", usdcAddress.Hex())

	// Create EVM client for this chain (needed for fetching reserve data)
	evmClient := &evm.Client{
		ChainSelector: chainCfg.ChainSelector,
	}

	// Step 1: Fetch reserve data for display purposes (totalSupply, totalBorrow)
	// We need to get ProtocolDataProvider to fetch reserve data
	poolAddressesProvider, err := aaveV3.NewPoolAddressesProviderBinding(evmClient, chainCfg.PoolAddressesProvider)
	if err != nil {
		return cre.PromiseFromResult[*aaveV3.ChainResult](nil, fmt.Errorf("failed to create PoolAddressesProvider binding: %w", err))
	}

	protocolDataProviderAddrPromise := poolAddressesProvider.GetPoolDataProvider(runtime, nil)

	return cre.ThenPromise(protocolDataProviderAddrPromise, func(protocolDataProviderAddr common.Address) cre.Promise[*aaveV3.ChainResult] {
		protocolDataProvider, err := aaveV3.NewAaveProtocolDataProviderBinding(evmClient, protocolDataProviderAddr.Hex())
		if err != nil {
			return cre.PromiseFromResult[*aaveV3.ChainResult](nil, fmt.Errorf("failed to create ProtocolDataProvider binding: %w", err))
		}

		// Fetch reserve data for display purposes
		reserveDataPromise := protocolDataProvider.GetReserveData(
			runtime,
			aave_protocol_data_provider.GetReserveDataInput{Asset: usdcAddress},
			nil,
		)

		return cre.ThenPromise(reserveDataPromise, func(reserveData aave_protocol_data_provider.GetReserveDataOutput) cre.Promise[*aaveV3.ChainResult] {
			// Extract totalSupply and totalBorrow for ChainResult display
			totalSupply := reserveData.TotalAToken
			totalStableDebt := reserveData.Arg3 // Unnamed field in ABI
			totalVariableDebt := reserveData.TotalVariableDebt
			totalBorrow := new(big.Int).Add(totalStableDebt, totalVariableDebt)

			logger.Info("Got reserve data",
				"totalSupply", totalSupply.String(),
				"totalBorrow", totalBorrow.String())

			// Step 2: Calculate current APY using GetAPY (liquidityAdded = 0)
			// GetAPY returns (float64, error) synchronously, so we wrap it in a Promise
			// Using nil for blockNumber queries "latest" - all calls within GetAPY will use the same nil reference
			// For consistent results across multiple calls, consider getting a specific block number first
			currentAPY, err := aaveV3.GetAPY(helperConfig, runtime, big.NewInt(0), chainCfg.ChainSelector, nil)
			if err != nil {
				return cre.PromiseFromResult[*aaveV3.ChainResult](nil, fmt.Errorf("failed to calculate current APY: %w", err))
			}

			// Step 3: Calculate projected APY using GetAPY (liquidityAdded = depositAmountRaw)
			// Using nil for blockNumber - same as above
			newAPY, err := aaveV3.GetAPY(helperConfig, runtime, depositAmountRaw, chainCfg.ChainSelector, nil)
			if err != nil {
				return cre.PromiseFromResult[*aaveV3.ChainResult](nil, fmt.Errorf("failed to calculate new APY: %w", err))
			}

			// Step 4: Fetch params for utilization calculation
			// Using nil for blockNumber - all calls within FetchCalculateInterestRatesParams will use the same nil reference
			currentParamsPromise := aaveV3.FetchCalculateInterestRatesParams(
				runtime,
				protocolDataProvider,
				usdcAddress,
				big.NewInt(0),
				nil, // blockNumber: nil = latest, but all internal calls use same nil
			)

			return cre.ThenPromise(currentParamsPromise, func(currentParams *aaveV3.CalculateInterestRatesParams) cre.Promise[*aaveV3.ChainResult] {
				newParamsPromise := aaveV3.FetchCalculateInterestRatesParams(
					runtime,
					protocolDataProvider,
					usdcAddress,
					depositAmountRaw,
					nil, // blockNumber: nil = latest, but all internal calls use same nil
				)

				return cre.ThenPromise(newParamsPromise, func(newParams *aaveV3.CalculateInterestRatesParams) cre.Promise[*aaveV3.ChainResult] {
					// Calculate current utilization using contract's formula:
					// borrowUsageRatio = totalDebt / (availableLiquidity + totalDebt)
					// where availableLiquidity = virtualUnderlyingBalance + liquidityAdded - liquidityTaken
					// For current: liquidityAdded = 0, liquidityTaken = 0
					currentUtilization := big.NewRat(0, 1)
					if currentParams.TotalDebt.Sign() > 0 {
						availableLiquidity := currentParams.VirtualUnderlyingBalance
						availableLiquidityPlusDebt := new(big.Int).Add(availableLiquidity, currentParams.TotalDebt)
						if availableLiquidityPlusDebt.Sign() > 0 {
							currentUtilization = new(big.Rat).Quo(
								new(big.Rat).SetInt(currentParams.TotalDebt),
								new(big.Rat).SetInt(availableLiquidityPlusDebt),
							)
						}
					}

					// Calculate new total supply after deposit (for display purposes)
					newTotalSupply := new(big.Int).Add(totalSupply, depositAmountRaw)

					// Calculate new utilization using contract's formula:
					// For projected: liquidityAdded = depositAmount, liquidityTaken = 0
					newUtilization := big.NewRat(0, 1)
					if newParams.TotalDebt.Sign() > 0 {
						availableLiquidity := new(big.Int).Add(newParams.VirtualUnderlyingBalance, depositAmountRaw)
						availableLiquidityPlusDebt := new(big.Int).Add(availableLiquidity, newParams.TotalDebt)
						if availableLiquidityPlusDebt.Sign() > 0 {
							newUtilization = new(big.Rat).Quo(
								new(big.Rat).SetInt(newParams.TotalDebt),
								new(big.Rat).SetInt(availableLiquidityPlusDebt),
							)
						}
					}

					// Calculate changes
					apyChange := newAPY - currentAPY
					utilizationChange := new(big.Rat).Sub(newUtilization, currentUtilization)

					// Convert all values to strings for JSON output
					return cre.PromiseFromResult(&aaveV3.ChainResult{
						ChainName:          chainCfg.ChainName,
						CurrentTotalSupply: aaveV3.BigIntToUSDCString(totalSupply),
						CurrentTotalBorrow: aaveV3.BigIntToUSDCString(totalBorrow),
						CurrentUtilization: aaveV3.BigRatToString(currentUtilization),
						CurrentAPY:         aaveV3.Float64ToString(currentAPY),
						NewTotalSupply:     aaveV3.BigIntToUSDCString(newTotalSupply),
						NewUtilization:     aaveV3.BigRatToString(newUtilization),
						NewAPY:             aaveV3.Float64ToString(newAPY),
						APYChange:          aaveV3.Float64ToString(apyChange),
						UtilizationChange:  aaveV3.BigRatToString(utilizationChange),
					}, nil)
				})
			})
		})
	})
}
