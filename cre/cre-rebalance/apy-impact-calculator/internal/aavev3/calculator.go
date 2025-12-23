package aavev3

import (
	"fmt"
	"math"
	"math/big"

	"cre-rebalance/contracts/evm/src/generated/default_reserve_interest_rate_strategy_v2"

	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// CalculateAPYFromContract calculates APY using the contract's CalculateInterestRates function.
// This is the preferred method as it uses the exact on-chain calculation logic.
//
// Parameters:
//   - runtime: CRE runtime for contract calls
//   - strategyContract: The DefaultReserveInterestRateStrategyV2 contract interface
//   - params: Parameters for CalculateInterestRates (fetched by read.go)
//
// Returns:
//   - APY
//   - Error 
//
// The function:
// 1. Calls CalculateInterestRates on the contract (returns liquidityRate and variableBorrowRate in RAY)
// 2. Extracts liquidityRate (Arg0) which is the supply APR in RAY
// 3. Converts APR (in RAY) to decimal ratio
// 4. Converts APR to APY using discrete compounding: APY = (1 + APR/SECONDS_PER_YEAR)^SECONDS_PER_YEAR - 1
func CalculateAPYFromContract(
	runtime cre.Runtime,
	strategyContract DefaultReserveInterestRateStrategyV2Interface,
	params *CalculateInterestRatesParams,
) cre.Promise[*big.Rat] {
	logger := runtime.Logger()
	logger.Info("Calculating APY using contract CalculateInterestRates",
		"unbacked", params.Unbacked.String(),
		"liquidityAdded", params.LiquidityAdded.String(),
		"liquidityTaken", params.LiquidityTaken.String(),
		"totalDebt", params.TotalDebt.String(),
		"reserveFactor", params.ReserveFactor.String(),
		"reserve", params.Reserve.Hex(),
		"usingVirtualBalance", params.UsingVirtualBalance,
		"virtualUnderlyingBalance", params.VirtualUnderlyingBalance.String())

	// Build input struct for CalculateInterestRates
	input := default_reserve_interest_rate_strategy_v2.CalculateInterestRatesInput{
		Params: default_reserve_interest_rate_strategy_v2.DataTypesCalculateInterestRatesParams{
			Unbacked:                 params.Unbacked,
			LiquidityAdded:           params.LiquidityAdded,
			LiquidityTaken:           params.LiquidityTaken,
			TotalDebt:                params.TotalDebt,
			ReserveFactor:            params.ReserveFactor,
			Reserve:                  params.Reserve,
			UsingVirtualBalance:      params.UsingVirtualBalance,
			VirtualUnderlyingBalance: params.VirtualUnderlyingBalance,
		},
	}

	// Call CalculateInterestRates on the contract
	resultPromise := strategyContract.CalculateInterestRates(runtime, input, nil)

	// Process the result
	return cre.Then(resultPromise, func(result default_reserve_interest_rate_strategy_v2.CalculateInterestRatesOutput) (*big.Rat, error) {
		// Arg0 is liquidityRate (supply APR) in RAY
		// Arg1 is variableBorrowRate in RAY (we don't need this for supply APY)
		liquidityRateRAY := result.Arg0

		logger.Info("Got liquidity rate from contract", "liquidityRateRAY", liquidityRateRAY.String())

		// Convert liquidityRate from RAY to decimal ratio
		// liquidityRateRAY is in RAY (27 decimals), so APR = liquidityRateRAY / RAY
		rayBigInt := getRAYBigInt()
		aprRat := new(big.Rat).Quo(
			new(big.Rat).SetInt(liquidityRateRAY),
			new(big.Rat).SetInt(rayBigInt),
		)

		// Convert APR to APY using discrete compounding: APY = (1 + APR/SECONDS_PER_YEAR)^SECONDS_PER_YEAR - 1
		apyRat, err := convertAPRToAPY(aprRat)
		if err != nil {
			return nil, fmt.Errorf("failed to convert APR to APY: %w", err)
		}

		return apyRat, nil
	})
}

// convertAPRToAPY converts APR to APY using discrete compounding.
// Formula: APY = (1 + APR/SECONDS_PER_YEAR)^SECONDS_PER_YEAR - 1
// This compounds interest per second over a year.
func convertAPRToAPY(aprRat *big.Rat) (*big.Rat, error) {
	// Check for zero or negative APR
	if aprRat.Sign() <= 0 {
		return big.NewRat(0, 1), nil
	}

	// Convert APR to float64 for math.Pow (we need exponentiation)
	aprFloat, _ := aprRat.Float64()

	// Sanity check: very high APR (> 1000%)
	if aprFloat > 10 {
		return nil, fmt.Errorf("APR exceeds 1000%%: %v", aprFloat)
	}

	// Calculate per-second rate: APR / SECONDS_PER_YEAR
	perSecondRate := aprFloat / float64(SECONDS_PER_YEAR)
	onePlusRate := 1.0 + perSecondRate

	// Calculate (1 + APR/SECONDS_PER_YEAR)^SECONDS_PER_YEAR
	compounded := math.Pow(onePlusRate, float64(SECONDS_PER_YEAR))

	// Subtract 1 to get APY
	apyFloat := compounded - 1

	// Handle edge cases
	if apyFloat < 0 {
		return big.NewRat(0, 1), nil
	}
	if math.IsNaN(apyFloat) || math.IsInf(apyFloat, 0) {
		return big.NewRat(0, 1), nil
	}

	// Convert back to big.Rat for exact representation
	// Use high precision: convert float64 to string, then to big.Rat
	apyStr := fmt.Sprintf("%.18f", apyFloat)
	apyRat := new(big.Rat)
	apyRat.SetString(apyStr)

	return apyRat, nil
}

// FindBestChain compares all chain results and returns the chain with the highest NewAPY.
// It matches the best result with its corresponding chain configuration and returns
// a TargetChain struct containing all information needed by other workflows.
//
// APY values are compared using big.Rat for exact precision (no float64 conversions).
//
// Returns an error if:
//   - No chain results are provided
//   - The best chain's configuration cannot be found
//   - APY values cannot be parsed
//
// The returned TargetChain includes:
//   - ChainSelector, StablecoinId, StablecoinAddress: For use by other workflows
//   - NewAPY, ChainName: For verification/debugging purposes only
func FindBestChain(results []ChainResult, chainConfigs []ChainConfig) (*TargetChain, error) {
	if len(results) == 0 {
		return nil, fmt.Errorf("no chain results provided")
	}

	// Parse all APY values to big.Rat for exact comparison
	apyRats := make([]*big.Rat, len(results))
	for i, result := range results {
		apyRat := new(big.Rat)
		if _, ok := apyRat.SetString(result.NewAPY); !ok {
			return nil, fmt.Errorf("failed to parse APY for chain %s: %s", result.ChainName, result.NewAPY)
		}
		apyRats[i] = apyRat
	}

	// Find the result with highest NewAPY using big.Rat comparison
	bestIdx := 0
	bestAPY := apyRats[0]
	for i := 1; i < len(results); i++ {
		if apyRats[i].Cmp(bestAPY) > 0 {
			bestIdx = i
			bestAPY = apyRats[i]
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

	// Determine stablecoin ID (currently always USDC, but will support USDT in the future)
	stablecoinId := "USDC"

	return &TargetChain{
		// Fields for use by other workflows:
		ChainSelector:     chainCfg.ChainSelector,
		StablecoinId:      stablecoinId,
		StablecoinAddress: chainCfg.USDCAddress,
		// Fields for verification/debugging:
		NewAPY:    bestResult.NewAPY, // Already a string, preserves precision
		ChainName: chainCfg.ChainName,
	}, nil
}

