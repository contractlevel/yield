package aaveV3

import (
	"fmt"
	"math"
	"math/big"

	"cre-rebalance/contracts/evm/src/generated/default_reserve_interest_rate_strategy_v2"

	"github.com/ethereum/go-ethereum/common"
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

// @review If needed, we can refactor to Promise-less execution
func CalculateAPYFromContract(
	runtime cre.Runtime,
	strategyContract DefaultReserveInterestRateStrategyV2Interface,
	params *CalculateInterestRatesParams,
) cre.Promise[float64] {

	// Might be redundant but defensive:
	// Might indicate AAVE shenanigans
	// Validate inputs - check for nil pointers (uninitialized fields)
	// Note: 0 values are valid (e.g., Unbacked = 0, LiquidityAdded = 0, etc.)
	// We only check that pointers are not nil, not that values are non-zero
	if params == nil {
		return cre.PromiseFromResult(0.0, fmt.Errorf("params cannot be nil"))
	}
	if params.Unbacked == nil {
		return cre.PromiseFromResult(0.0, fmt.Errorf("params.Unbacked cannot be nil (use big.NewInt(0) for zero value)"))
	}
	if params.LiquidityAdded == nil {
		return cre.PromiseFromResult(0.0, fmt.Errorf("params.LiquidityAdded cannot be nil (use big.NewInt(0) for zero value)"))
	}
	if params.LiquidityTaken == nil {
		return cre.PromiseFromResult(0.0, fmt.Errorf("params.LiquidityTaken cannot be nil (use big.NewInt(0) for zero value)"))
	}
	if params.TotalDebt == nil {
		return cre.PromiseFromResult(0.0, fmt.Errorf("params.TotalDebt cannot be nil (use big.NewInt(0) for zero value)"))
	}
	if params.ReserveFactor == nil {
		return cre.PromiseFromResult(0.0, fmt.Errorf("params.ReserveFactor cannot be nil (use big.NewInt(0) for zero value)"))
	}
	if params.VirtualUnderlyingBalance == nil {
		return cre.PromiseFromResult(0.0, fmt.Errorf("params.VirtualUnderlyingBalance cannot be nil (use big.NewInt(0) for zero value)"))
	}
	if params.Reserve == (common.Address{}) {
		return cre.PromiseFromResult(0.0, fmt.Errorf("params.Reserve cannot be zero address"))
	}

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
	return cre.Then(resultPromise, func(result default_reserve_interest_rate_strategy_v2.CalculateInterestRatesOutput) (float64, error) {
		// Arg0 is liquidityRate (supply APR) in RAY
		// Arg1 is variableBorrowRate in RAY
		liquidityRateRAY := result.Arg0

		// Validate contract response
		if liquidityRateRAY == nil {
			return 0.0, fmt.Errorf("contract returned nil liquidityRate")
		}
		if liquidityRateRAY.Sign() < 0 {
			return 0.0, fmt.Errorf("contract returned negative liquidityRate: %s", liquidityRateRAY.String())
		}

		logger.Info("Got liquidity rate from contract", "liquidityRateRAY", liquidityRateRAY.String())

		// Handle zero liquidity rate (underutilized pool) - return 0 APY
		if liquidityRateRAY.Sign() == 0 {
			return 0.0, nil
		}

		// Note: RAYBigInt is a constant (10^27), so it can never be zero
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
	// Validate input
	if aprRat == nil {
		return 0.0, fmt.Errorf("aprRat cannot be nil")
	}

	// Check for zero or negative APR
	if aprRat.Sign() <= 0 {
		return 0.0, nil
	}

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

	return apyFloat, nil
}
