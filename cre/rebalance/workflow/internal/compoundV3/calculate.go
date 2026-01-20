package compoundV3

import ( 
	"rebalance/workflow/internal/constants"
	"math"
)

// @review compoundV3 maths

// calculateAPYFromSupplyRate converts a per-second WAD-scaled supply rate from Comet
// into an annual percentage yield (APY) as a float.
//
// Assumptions:
//   - supplyRateInWad is a per-second rate scaled by 1e18 (WAD).
//   - APY formula: (1 + r)^secondsPerYear - 1
//     where r = supplyRateInWad / 1e18.
func calculateAPYFromSupplyRate(supplyRateInWad uint64) float64 {
	// Zero rate -> zero APY
	if supplyRateInWad == 0 {
		return 0
	}

	// Convert WAD-scaled per-second rate to float
	rPerSecond := float64(supplyRateInWad) / constants.WAD

	// For small r, (1 + r)^n can lose precision if done directly.
	// Use exp(n * log1p(r)) for better numerical stability:
	// (1 + r)^n = exp(n * log(1 + r)).
	apy := math.Exp(float64(constants.SecondsPerYear)*math.Log1p(rPerSecond)) - 1

	return apy
}
