package helper

import (
	"math"

	"rebalance/workflow/internal/constants"
)

// APYFromPerSecondRate converts a per-second rate r into an annual percentage
// yield using discrete compounding:
//
//   APY = (1 + r)^SECONDS_PER_YEAR - 1
//
// where r is a per-second rate in decimal form.
// Example: for APR = 5%, r = 0.05 / SECONDS_PER_YEAR.
func APYFromPerSecondRate(r float64) float64 {
	if r == 0 {
		return 0
	}

	return math.Pow(1.0+r, float64(constants.SecondsPerYear)) - 1
}