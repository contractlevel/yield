package compoundV3

import (
	"rebalance/workflow/internal/constants"
	"rebalance/workflow/internal/helper"
)

// calculateAPYFromSupplyRate converts a per-second WAD-scaled supply rate from Comet
// into an annual percentage yield (APY) as a float.
//
// Assumptions:
//   - supplyRateInWad is a per-second rate scaled by 1e18 (WAD).
//   - APY formula: (1 + r)^SECONDS_PER_YEAR - 1
//     where r = supplyRateInWad / 1e18.
func calculateAPYFromSupplyRate(supplyRateInWad uint64) float64 {
	// Zero rate -> zero APY
	if supplyRateInWad == 0 {
		return 0
	}

	// Convert WAD-scaled per-second rate to float
	rPerSecond := float64(supplyRateInWad) / constants.WAD

	// Use shared helper for discrete compounding
	return helper.APYFromPerSecondRate(rPerSecond)
}