package aaveV3

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
//   - APY as float64 (e.g., 0.0523 = 5.23%)
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
	blockNumber *big.Int, // Use same blockNumber as params were fetched at
) cre.Promise[float64] {
	logger := runtime.Logger()
	logger.Info("Calculating APY using contract CalculateInterestRates",
		"unbacked", params.Unbacked.String(),
		"liquidityAdded", params.LiquidityAdded.String(),
		"liquidityTaken", params.LiquidityTaken.String(),
		"totalDebt", params.TotalDebt.String(),
		"reserveFactor", params.ReserveFactor.String(),
		"reserve", params.Reserve.Hex(),
		"usingVirtualBalance", params.UsingVirtualBalance,
		"virtualUnderlyingBalance", params.VirtualUnderlyingBalance.String(),
		"blockNumber", blockNumber)

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
	// Use same blockNumber as params were fetched at to ensure consistency
	resultPromise := strategyContract.CalculateInterestRates(runtime, input, blockNumber)

	// Process the result
	return cre.Then(resultPromise, func(result default_reserve_interest_rate_strategy_v2.CalculateInterestRatesOutput) (float64, error) {
		// Arg0 is liquidityRate (supply APR) in RAY
		// Arg1 is variableBorrowRate in RAY
		liquidityRateRAY := result.Arg0

		logger.Info("Got liquidity rate from contract", "liquidityRateRAY", liquidityRateRAY.String())

		// Convert liquidityRate from RAY to decimal ratio
		// liquidityRateRAY is in RAY (27 decimals), so APR = liquidityRateRAY / RAY
		aprRat := new(big.Rat).Quo(
			new(big.Rat).SetInt(liquidityRateRAY),
			new(big.Rat).SetInt(RAYBigInt),
		)

		// Convert APR to APY using discrete compounding: APY = (1 + APR/SECONDS_PER_YEAR)^SECONDS_PER_YEAR - 1
		apyFloat, err := convertAPRToAPY(aprRat)
		if err != nil {
			return 0.0, fmt.Errorf("failed to convert APR to APY: %w", err)
		}

		return apyFloat, nil
	})
}

// convertAPRToAPY converts APR to APY using discrete compounding.
// Formula: APY = (1 + APR/SECONDS_PER_YEAR)^SECONDS_PER_YEAR - 1
// This compounds interest per second over a year.
// Returns float64
func convertAPRToAPY(aprRat *big.Rat) (float64, error) {
	// Check for zero or negative APR
	if aprRat.Sign() <= 0 {
		return 0.0, nil
	}

	// Convert APR to float64 for math.Pow (we need exponentiation)
	aprFloat, _ := aprRat.Float64()

	// Sanity check: very high APR (> 1000%)
	if aprFloat > 10 {
		return 0.0, fmt.Errorf("APR exceeds 1000%%: %v", aprFloat)
	}

	// Calculate per-second rate: APR / SECONDS_PER_YEAR
	perSecondRate := aprFloat / float64(SECONDS_PER_YEAR)
	onePlusRate := 1.0 + perSecondRate

	// Calculate (1 + APR/SECONDS_PER_YEAR)^SECONDS_PER_YEAR
	compounded := math.Pow(onePlusRate, float64(SECONDS_PER_YEAR))

	// Formula: APY = (1 + APR/SECONDS_PER_YEAR)^SECONDS_PER_YEAR - 1
	// Subtract 1 to get APY
	apyFloat := compounded - 1

	// Handle edge cases
	if apyFloat < 0 {
		return 0.0, nil
	}
	if math.IsNaN(apyFloat) || math.IsInf(apyFloat, 0) {
		return 0.0, nil
	}

	return apyFloat, nil
}
