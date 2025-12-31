//go:build wasip1

package main

import (
	"fmt"
	"log/slog"
	"math/big"

	"cre-rebalance/apy-impact-calculator/internal/aavev3"
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
	Results       []aavev3.ChainResult `json:"results"`
	TargetChain   *aavev3.TargetChain  `json:"targetChain,omitempty"` // Best chain (highest NewAPY)
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

	// Process each chain in parallel using CRE promises
	chainPromises := make([]cre.Promise[*aavev3.ChainResult], 0, len(config.Chains))

	for _, chainCfg := range config.Chains {
		// Create a promise for each chain calculation
		promise := processChain(runtime, chainCfg, depositAmountRaw)
		chainPromises = append(chainPromises, promise)
	}

	// Await all promises (parallel execution with consensus)
	results := make([]aavev3.ChainResult, 0, len(chainPromises))
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
	var targetChain *aavev3.TargetChain
	if len(results) > 0 {
		bestChain, err := aavev3.FindBestChain(results, config.Chains)
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


func processChain(runtime cre.Runtime, chainCfg aavev3.ChainConfig, depositAmountRaw *big.Int) cre.Promise[*aavev3.ChainResult] {
	logger := runtime.Logger()

	// Create EVM client for this chain
	evmClient := &evm.Client{
		ChainSelector: chainCfg.ChainSelector,
	}

	usdcAddress := common.HexToAddress(chainCfg.USDCAddress)

	logger.Info("Processing chain", "chain", chainCfg.ChainName, "usdcAddress", usdcAddress.Hex())

	// Start with PoolAddressesProvider (most immutable contract)
	// This is the single hardcoded dependency - all other contracts are derived from it
	poolAddressesProvider, err := aavev3.NewPoolAddressesProviderBinding(evmClient, chainCfg.PoolAddressesProvider)
	if err != nil {
		return cre.PromiseFromResult[*aavev3.ChainResult](nil, fmt.Errorf("failed to create PoolAddressesProvider binding: %w", err))
	}

	// Fetch ProtocolDataProvider address dynamically from PoolAddressesProvider
	protocolDataProviderAddrPromise := poolAddressesProvider.GetPoolDataProvider(runtime, nil)

	return cre.ThenPromise(protocolDataProviderAddrPromise, func(protocolDataProviderAddr common.Address) cre.Promise[*aavev3.ChainResult] {
		logger.Info("Got ProtocolDataProvider address", "address", protocolDataProviderAddr.Hex())

		// Create ProtocolDataProvider binding with dynamically fetched address
		protocolDataProvider, err := aavev3.NewAaveProtocolDataProviderBinding(evmClient, protocolDataProviderAddr.Hex())
		if err != nil {
			return cre.PromiseFromResult[*aavev3.ChainResult](nil, fmt.Errorf("failed to create ProtocolDataProvider binding: %w", err))
		}

		// Fetch strategy address dynamically from ProtocolDataProvider
		strategyAddrPromise := protocolDataProvider.GetInterestRateStrategyAddress(
			runtime,
			aave_protocol_data_provider.GetInterestRateStrategyAddressInput{Arg0: usdcAddress},
			nil,
		)

		return cre.ThenPromise(strategyAddrPromise, func(strategyAddr common.Address) cre.Promise[*aavev3.ChainResult] {
			logger.Info("Got strategy address", "strategy", strategyAddr.Hex())

			// Create Strategy V2 binding with dynamically fetched address
			strategyV2, err := aavev3.NewDefaultReserveInterestRateStrategyV2Binding(evmClient, strategyAddr.Hex())
			if err != nil {
				return cre.PromiseFromResult[*aavev3.ChainResult](nil, fmt.Errorf("failed to create Strategy V2 binding: %w", err))
			}

			// Fetch reserve data from ProtocolDataProvider for totalSupply/totalBorrow (for display)
			reserveDataPromise := protocolDataProvider.GetReserveData(
				runtime,
				aave_protocol_data_provider.GetReserveDataInput{Asset: usdcAddress},
				nil,
			)

			return cre.ThenPromise(reserveDataPromise, func(reserveData aave_protocol_data_provider.GetReserveDataOutput) cre.Promise[*aavev3.ChainResult] {
				// Extract totalSupply and totalBorrow for ChainResult display
				// @review maybe redundant?
				totalSupply := reserveData.TotalAToken
				totalStableDebt := reserveData.Arg3 // Unnamed field in ABI
				totalVariableDebt := reserveData.TotalVariableDebt
				totalBorrow := new(big.Int).Add(totalStableDebt, totalVariableDebt)

				logger.Info("Got reserve data",
					"totalSupply", totalSupply.String(),
					"totalBorrow", totalBorrow.String())

				// FIRST CALL: CalculateInterestRates with liquidityAdded = 0 (current APY)
				//@review  Maybe confusing, because from the workflow POV
				// it looks like we are fetching from protocolDataProvider
				currentParamsPromise := aavev3.FetchCalculateInterestRatesParams(
					runtime,
					protocolDataProvider,
					usdcAddress,
					big.NewInt(0), // No deposit for current APY
				)

				return cre.ThenPromise(currentParamsPromise, func(currentParams *aavev3.CalculateInterestRatesParams) cre.Promise[*aavev3.ChainResult] {
					// Call CalculateInterestRates for current state
					currentAPYPromise := aavev3.CalculateAPYFromContract(runtime, strategyV2, currentParams)

					return cre.ThenPromise(currentAPYPromise, func(currentAPY *big.Rat) cre.Promise[*aavev3.ChainResult] {
						// SECOND CALL: CalculateInterestRates with liquidityAdded = depositAmountRaw (projected APY)
						newParamsPromise := aavev3.FetchCalculateInterestRatesParams(
							runtime,
							protocolDataProvider,
							usdcAddress,
							depositAmountRaw, // Deposit amount for projected APY
						)

						return cre.ThenPromise(newParamsPromise, func(newParams *aavev3.CalculateInterestRatesParams) cre.Promise[*aavev3.ChainResult] {
							// Call CalculateInterestRates for projected state
							newAPYPromise := aavev3.CalculateAPYFromContract(runtime, strategyV2, newParams)

							//@review Just for display purposes at this moment
							return cre.Then(newAPYPromise, func(newAPY *big.Rat) (*aavev3.ChainResult, error) {
								// Calculate current utilization using contract's formula:
								// borrowUsageRatio = totalDebt / (availableLiquidity + totalDebt)
								// where availableLiquidity = virtualUnderlyingBalance + liquidityAdded - liquidityTaken
								// For current: liquidityAdded = 0, liquidityTaken = 0
								currentUtilization := big.NewRat(0, 1)
								if currentParams.TotalDebt.Sign() > 0 {
									// availableLiquidity = virtualUnderlyingBalance + 0 - 0
									availableLiquidity := currentParams.VirtualUnderlyingBalance
									// availableLiquidityPlusDebt = availableLiquidity + totalDebt
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
									// availableLiquidity = virtualUnderlyingBalance + depositAmount - 0
									availableLiquidity := new(big.Int).Add(newParams.VirtualUnderlyingBalance, depositAmountRaw)
									// availableLiquidityPlusDebt = availableLiquidity + totalDebt
									availableLiquidityPlusDebt := new(big.Int).Add(availableLiquidity, newParams.TotalDebt)
									if availableLiquidityPlusDebt.Sign() > 0 {
										newUtilization = new(big.Rat).Quo(
											new(big.Rat).SetInt(newParams.TotalDebt),
											new(big.Rat).SetInt(availableLiquidityPlusDebt),
										)
									}
								}

								// Calculate changes as big.Rat
								apyChange := new(big.Rat).Sub(newAPY, currentAPY)
								utilizationChange := new(big.Rat).Sub(newUtilization, currentUtilization)

								// Convert all values to strings for JSON output
								return &aavev3.ChainResult{
									ChainName:          chainCfg.ChainName,
									CurrentTotalSupply: aavev3.BigIntToUSDCString(totalSupply),
									CurrentTotalBorrow: aavev3.BigIntToUSDCString(totalBorrow),
									CurrentUtilization: aavev3.BigRatToString(currentUtilization),
									CurrentAPY:         aavev3.BigRatToString(currentAPY),
									NewTotalSupply:     aavev3.BigIntToUSDCString(newTotalSupply),
									NewUtilization:     aavev3.BigRatToString(newUtilization),
									NewAPY:             aavev3.BigRatToString(newAPY),
									APYChange:          aavev3.BigRatToString(apyChange),
									UtilizationChange:  aavev3.BigRatToString(utilizationChange),
								}, nil
							})
						})
					})
				})
			})
		})
	})
}
