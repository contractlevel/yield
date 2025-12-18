//go:build wasip1

// break into smaller packages/files for testing, minimized exposure, if  not they are publically accessible APIs
// use inside internal-folder, aaveV3 package with logic for calculator, use types.go
// study bindings.go to make bindings for aave contracts (instanciate aave_protocol_data_provider and default_..._..)

package main

import (
	"fmt"
	"log/slog"
	"math"
	"math/big"

	"cre-rebalance/contracts/evm/src/generated/aave_protocol_data_provider"
	"cre-rebalance/contracts/evm/src/generated/default_reserve_interest_rate_strategy"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// [DONE]use in constants.go
// [DONE]usdc decimals
const (
	RAY              = 1e27
	SECONDS_PER_YEAR = 31536000
)

// ChainConfig holds AAVE v3 contract addresses for each chain
// binding together with rest of chain configs inside broader workflow
type ChainConfig struct {
	ChainName        string `json:"chainName"`
	ChainSelector    uint64 `json:"chainSelector"`
	PoolDataProvider string `json:"poolDataProvider"` // For reading data
	USDCAddress      string `json:"usdcAddress"`
}

// Config for the workflow
// [DONE]helper/config.go
type Config struct {
	Schedule    string        `json:"schedule"`
	DepositUSDC string        `json:"depositUSDC"` // Amount in USDC (with 6 decimals)
	Chains      []ChainConfig `json:"chains"`
}

// ReserveData stores data fetched from AAVE contracts
// [DONE]types.go (?)
type ReserveData struct {
	TotalSupply          *big.Int
	TotalBorrow          *big.Int
	ReserveFactor        *big.Int
	OptimalUsage         *big.Int
	BaseRate             *big.Int
	Slope1               *big.Int
	Slope2               *big.Int
	CurrentLiquidityRate *big.Int // Per-second liquidity rate in RAY from contract
}

// ChainResult stores the calculation result for one chain
// [DONE]types.go (?)
type ChainResult struct {
	ChainName          string  `json:"chainName"`
	CurrentTotalSupply float64 `json:"currentTotalSupply"`
	CurrentTotalBorrow float64 `json:"currentTotalBorrow"`
	CurrentUtilization float64 `json:"currentUtilization"`
	CurrentAPY         float64 `json:"currentAPY"`
	NewTotalSupply     float64 `json:"newTotalSupply"`
	NewUtilization     float64 `json:"newUtilization"`
	NewAPY             float64 `json:"newAPY"`
	APYChange          float64 `json:"apyChange"`
	UtilizationChange  float64 `json:"utilizationChange"`
}

// TargetChain represents the chain with the highest projected APY (NewAPY).
// [DONE] types.go
type TargetChain struct {
	// Fields for use by other workflows:
	ChainSelector     uint64 `json:"chainSelector"`     
	StablecoinId      string `json:"stablecoinId"`      
	StablecoinAddress string `json:"stablecoinAddress"` 

	// Fields for verification/debugging (not used by other workflows):
	NewAPY    float64 `json:"newAPY"`    
	ChainName string  `json:"chainName"` 
}

// WorkflowResult is the final output
type WorkflowResult struct {
	DepositAmount float64       `json:"depositAmount"`
	Results       []ChainResult `json:"results"`
	TargetChain   *TargetChain  `json:"targetChain,omitempty"` // Best chain (highest NewAPY)
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

	// Parse deposit amount (amount in USDC with 6 decimals, e.g., "1000000" = 1 USDC)
	depositAmountRaw, ok := new(big.Float).SetString(config.DepositUSDC)
	if !ok {
		return nil, fmt.Errorf("invalid deposit amount: %s", config.DepositUSDC)
	}
	// Convert from raw amount (with 6 decimals) to USDC units
	// make constant
	// e.g., "1000000" (1 USDC in raw) -> 1.0 USDC, "1000000000000" (1M USDC in raw) -> 1000000.0 USDC
	decimalsDivisor := new(big.Float).SetFloat64(1e6)
	depositAmountUSDC := new(big.Float).Quo(depositAmountRaw, decimalsDivisor)
	depositFloat, _ := depositAmountUSDC.Float64()

	// Check for overflow/underflow
	if depositFloat <= 0 {
		return nil, fmt.Errorf("deposit amount must be positive: %f", depositFloat)
	}
	if depositFloat > 1e12 { // Sanity check: 1 trillion USDC is unrealistic
		logger.Warn("Very large deposit amount detected, may cause precision issues", "amount", depositFloat)
	}

	logger.Info("Parsed deposit amount", "raw", config.DepositUSDC, "usdc", depositFloat)

	// Process each chain in parallel using CRE promises

	chainPromises := make([]cre.Promise[*ChainResult], 0, len(config.Chains))

	for _, chainCfg := range config.Chains {
		// Create a promise for each chain calculation
		promise := processChain(runtime, chainCfg, depositFloat)
		chainPromises = append(chainPromises, promise)
	}

	// Await all promises (parallel execution with consensus)
	results := make([]ChainResult, 0, len(chainPromises))
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
	var targetChain *TargetChain
	if len(results) > 0 {
		bestChain, err := findBestChain(results, config.Chains)
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
		DepositAmount: depositFloat,
		Results:       results,
		TargetChain:   targetChain,
	}, nil
}

func processChain(runtime cre.Runtime, chainCfg ChainConfig, depositUSDC float64) cre.Promise[*ChainResult] {
	// Fetch reserve data from AAVE (returns a promise)
	reserveDataPromise := fetchReserveData(runtime, chainCfg)

	// Process the result once fetched
	return cre.Then(reserveDataPromise, func(reserveData *ReserveData) (*ChainResult, error) {
		logger := runtime.Logger()
		logger.Info("Processing chain", "chain", chainCfg.ChainName)

		// Calculate current metrics
		totalSupply := bigIntToFloat(reserveData.TotalSupply, 6)
		totalBorrow := bigIntToFloat(reserveData.TotalBorrow, 6)

		currentUtilization := 0.0
		if totalSupply > 0 {
			currentUtilization = totalBorrow / totalSupply
		}

		// Use actual liquidity rate from contract for current APY (more accurate)
		// Discovered inconsistency, resolved, continuing with manual calculation
		currentAPY := calculateProjectedSupplyAPY(
			totalSupply,
			totalBorrow,
			reserveData.OptimalUsage,
			reserveData.BaseRate,
			reserveData.Slope1,
			reserveData.Slope2,
			reserveData.ReserveFactor,
		)

		// Calculate new metrics after deposit
		// Check for overflow in addition
		if depositUSDC > math.MaxFloat64-totalSupply {
			logger.Error("Deposit amount would cause overflow", "totalSupply", totalSupply, "depositUSDC", depositUSDC)
			return nil, fmt.Errorf("deposit amount too large, would cause overflow")
		}
		newTotalSupply := totalSupply + depositUSDC
		newUtilization := 0.0
		if newTotalSupply > 0 {
			newUtilization = totalBorrow / newTotalSupply
		}

		// Calculate projected APY after deposit using interest rate model
		newAPY := calculateProjectedSupplyAPY(
			newTotalSupply,
			totalBorrow,
			reserveData.OptimalUsage,
			reserveData.BaseRate,
			reserveData.Slope1,
			reserveData.Slope2,
			reserveData.ReserveFactor,
		)

		// Ensure all float64 values are valid (not NaN or Inf) for JSON marshaling
		if math.IsNaN(currentAPY) || math.IsInf(currentAPY, 0) {
			currentAPY = 0
		}
		if math.IsNaN(newAPY) || math.IsInf(newAPY, 0) {
			newAPY = 0
		}
		if math.IsNaN(currentUtilization) || math.IsInf(currentUtilization, 0) {
			currentUtilization = 0
		}
		if math.IsNaN(newUtilization) || math.IsInf(newUtilization, 0) {
			newUtilization = 0
		}

		apyChange := newAPY - currentAPY
		utilizationChange := newUtilization - currentUtilization

		if math.IsNaN(apyChange) || math.IsInf(apyChange, 0) {
			apyChange = 0
		}
		if math.IsNaN(utilizationChange) || math.IsInf(utilizationChange, 0) {
			utilizationChange = 0
		}

		return &ChainResult{
			ChainName:          chainCfg.ChainName,
			CurrentTotalSupply: totalSupply,
			CurrentTotalBorrow: totalBorrow,
			CurrentUtilization: currentUtilization,
			CurrentAPY:         currentAPY,
			NewTotalSupply:     newTotalSupply,
			NewUtilization:     newUtilization,
			NewAPY:             newAPY,
			APYChange:          apyChange,
			UtilizationChange:  utilizationChange,
		}, nil
	})
}

func fetchReserveData(runtime cre.Runtime, chainCfg ChainConfig) cre.Promise[*ReserveData] {
	logger := runtime.Logger()

	// Create EVM client for this chain
	evmClient := &evm.Client{
		ChainSelector: chainCfg.ChainSelector,
	}

	poolDataProviderAddr := common.HexToAddress(chainCfg.PoolDataProvider)
	usdcAddress := common.HexToAddress(chainCfg.USDCAddress)

	logger.Info("Calling AAVE PoolDataProvider",
		"poolDataProvider", poolDataProviderAddr.Hex(),
		"usdcAddress", usdcAddress.Hex())

	// Create contract instance using generated bindings
	poolDataProvider, err := aave_protocol_data_provider.NewAaveProtocolDataProvider(
		evmClient,
		poolDataProviderAddr,
		nil, // No filter options needed for reads
	)
	if err != nil {
		return cre.PromiseFromResult[*ReserveData](nil, fmt.Errorf("failed to create contract instance: %w", err))
	}

	// Call getReserveData - returns Promise with decoded struct
	reserveDataPromise := poolDataProvider.GetReserveData(
		runtime,
		aave_protocol_data_provider.GetReserveDataInput{Asset: usdcAddress},
		nil, // Latest block
	)

	// Chain to process the decoded result
	return cre.ThenPromise(reserveDataPromise, func(reserveDataResult aave_protocol_data_provider.GetReserveDataOutput) cre.Promise[*ReserveData] {
		// Response is already decoded - access fields directly
		totalSupply := reserveDataResult.TotalAToken
		// Arg3 is totalStableDebt (unnamed field in ABI)
		totalStableDebt := reserveDataResult.Arg3
		totalVariableDebt := reserveDataResult.TotalVariableDebt
		totalBorrow := new(big.Int).Add(totalStableDebt, totalVariableDebt)
		currentLiquidityRate := reserveDataResult.LiquidityRate // Per-second rate in RAY

		logger.Info("Received getReserveData",
			"totalSupply", totalSupply.String(),
			"totalBorrow", totalBorrow.String(),
			"currentLiquidityRate", currentLiquidityRate.String())

		// Get reserve configuration to get reserve factor
		configPromise := poolDataProvider.GetReserveConfigurationData(
			runtime,
			aave_protocol_data_provider.GetReserveConfigurationDataInput{Asset: usdcAddress},
			nil,
		)

		return cre.ThenPromise(configPromise, func(configResult aave_protocol_data_provider.GetReserveConfigurationDataOutput) cre.Promise[*ReserveData] {
			// Reserve factor is already decoded
			reserveFactor := configResult.ReserveFactor

			logger.Info("Received getReserveConfigurationData", "reserveFactor", reserveFactor.String())

			// Get interest rate strategy address
			strategyAddrPromise := poolDataProvider.GetInterestRateStrategyAddress(
				runtime,
				aave_protocol_data_provider.GetInterestRateStrategyAddressInput{Arg0: usdcAddress},
				nil,
			)

			return cre.ThenPromise(strategyAddrPromise, func(strategyAddress common.Address) cre.Promise[*ReserveData] {
				logger.Info("Strategy address", "address", strategyAddress.Hex())

				// Fetch interest rate parameters using strategy contract bindings
				paramsPromise := fetchInterestRateParams(runtime, evmClient, strategyAddress, usdcAddress)

				return cre.Then(paramsPromise, func(params *InterestRateParams) (*ReserveData, error) {
					logger.Info("Fetched reserve data",
						"chain", chainCfg.ChainName,
						"totalSupply", totalSupply.String(),
						"totalBorrow", totalBorrow.String())

					return &ReserveData{
						TotalSupply:          totalSupply,
						TotalBorrow:          totalBorrow,
						ReserveFactor:        reserveFactor,
						OptimalUsage:         params.OptimalUsage,
						BaseRate:             params.BaseRate,
						Slope1:               params.Slope1,
						Slope2:               params.Slope2,
						CurrentLiquidityRate: currentLiquidityRate,
					}, nil
				})
			})
		})
	})
}

// InterestRateParams holds interest rate parameters
type InterestRateParams struct {
	OptimalUsage *big.Int
	BaseRate     *big.Int
	Slope1       *big.Int
	Slope2       *big.Int
}

func fetchInterestRateParams(runtime cre.Runtime, evmClient *evm.Client, strategyAddr common.Address, reserveAddr common.Address) cre.Promise[*InterestRateParams] {
	logger := runtime.Logger()
	logger.Info("Fetching interest rate params", "strategyAddr", strategyAddr.Hex(), "reserveAddr", reserveAddr.Hex())

	// Create strategy contract instance using generated bindings
	strategyContract, err := default_reserve_interest_rate_strategy.NewDefaultReserveInterestRateStrategy(
		evmClient,
		strategyAddr,
		nil,
	)
	if err != nil {
		return cre.PromiseFromResult[*InterestRateParams](nil, fmt.Errorf("failed to create strategy contract: %w", err))
	}

	// Call getInterestRateData - returns Promise with decoded struct
	interestRateDataPromise := strategyContract.GetInterestRateData(
		runtime,
		default_reserve_interest_rate_strategy.GetInterestRateDataInput{Reserve: reserveAddr},
		nil, // Latest block
	)

	return cre.Then(interestRateDataPromise, func(result default_reserve_interest_rate_strategy.IDefaultInterestRateStrategyV2InterestRateDataRay) (*InterestRateParams, error) {
		// All fields already decoded - just access them!
		logger.Info("Received getInterestRateData response",
			"optimalUsageRatio", result.OptimalUsageRatio.String(),
			"baseVariableBorrowRate", result.BaseVariableBorrowRate.String())

		return &InterestRateParams{
			OptimalUsage: result.OptimalUsageRatio,
			BaseRate:     result.BaseVariableBorrowRate,
			Slope1:       result.VariableRateSlope1,
			Slope2:       result.VariableRateSlope2,
		}, nil
	})
}

// calculateProjectedSupplyAPY calculates the projected APY after a deposit
// This uses the interest rate model to calculate what the new rate would be
func calculateProjectedSupplyAPY(totalSupply, totalBorrow float64, optimalUsage, baseRate, slope1, slope2, reserveFactor *big.Int) float64 {
	if totalSupply == 0 {
		return 0
	}

	utilization := totalBorrow / totalSupply

	// Handle edge cases for very small utilization
	if utilization < 1e-18 {
		return 0 // Essentially zero utilization means zero APY
	}

	// @review use RAY constant for 27

	optimalRatio := bigIntToFloat(optimalUsage, 27)

	// Calculate borrow rate based on utilization
	var borrowRate float64
	if utilization <= optimalRatio {
		if optimalRatio > 0 {
			borrowRate = bigIntToFloat(baseRate, 27) + (utilization/optimalRatio)*bigIntToFloat(slope1, 27)
		} else {
			borrowRate = bigIntToFloat(baseRate, 27)
		}
	} else {
		denominator := 1 - optimalRatio
		if denominator > 1e-18 { // Avoid division by zero
			borrowRate = bigIntToFloat(baseRate, 27) + bigIntToFloat(slope1, 27) +
				((utilization-optimalRatio)/denominator)*bigIntToFloat(slope2, 27)
		} else {
			borrowRate = bigIntToFloat(baseRate, 27) + bigIntToFloat(slope1, 27) + bigIntToFloat(slope2, 27)
		}
	}

	// Calculate supply rate: borrowRate * utilization * (1 - reserveFactor)
	// Reserve factor in AAVE v3 is stored in basis points (10000 = 100%)
	// e.g., 1000 = 10% = 0.10
	reserveFactorDecimal := bigIntToFloat(reserveFactor, 4) // Convert from basis points (10000 = 100%)
	supplyRateAPR := borrowRate * utilization * (1 - reserveFactorDecimal)

	// Handle very small supply rates
	if supplyRateAPR <= 0 {
		return 0
	}
	if supplyRateAPR > 10 { // Sanity check: 1000% APR is unrealistic
		return math.Inf(1)
	}

	// Convert APR to APY: APY = e^(APR) - 1 (continuous compounding approximation)
	apy := math.Exp(supplyRateAPR) - 1

	if apy < 0 {
		return 0
	}

	// Ensure no NaN or Inf values
	if math.IsNaN(apy) || math.IsInf(apy, 0) {
		return 0
	}

	return apy
}

// findBestChain compares all chain results and returns the chain with the highest NewAPY.
// Returns nil if no valid results are provided.
func findBestChain(results []ChainResult, chainConfigs []ChainConfig) (*TargetChain, error) {
	if len(results) == 0 {
		return nil, fmt.Errorf("no chain results provided")
	}

	// Find the result with highest NewAPY
	bestIdx := 0
	bestAPY := results[0].NewAPY
	for i := 1; i < len(results); i++ {
		if results[i].NewAPY > bestAPY {
			bestIdx = i
			bestAPY = results[i].NewAPY
		}
	}

	// Find corresponding chain config
	bestResult := results[bestIdx]
	var chainCfg *ChainConfig
	for i := range chainConfigs {
		if chainConfigs[i].ChainName == bestResult.ChainName {
			chainCfg = &chainConfigs[i]
			break
		}
	}

	if chainCfg == nil {
		return nil, fmt.Errorf("chain config not found for chain: %s", bestResult.ChainName)
	}

	// Determine stablecoin ID 
	// @review Should maybe be fetched by HTTP Trigger before APY Calc workflow (?)
	stablecoinId := "USDC"

	return &TargetChain{
		// Fields for use by other workflows:
		ChainSelector:     chainCfg.ChainSelector,
		StablecoinId:      stablecoinId,
		StablecoinAddress: chainCfg.USDCAddress,
		// Fields for verification/debugging:
		NewAPY:    bestResult.NewAPY,
		ChainName: chainCfg.ChainName,
	}, nil
}

// internal helpers?
func bigIntToFloat(b *big.Int, decimals int) float64 {
	if b == nil {
		return 0
	}
	f := new(big.Float).SetInt(b)
	divisor := new(big.Float).SetFloat64(math.Pow10(decimals))
	result, _ := new(big.Float).Quo(f, divisor).Float64()
	return result
}
