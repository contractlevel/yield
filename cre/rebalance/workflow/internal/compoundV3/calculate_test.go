package compoundV3

import (
	"math"
	"testing"

	"rebalance/workflow/internal/constants"

	"github.com/stretchr/testify/require"
)

func Test_calculateAPYFromSupplyRate_Zero(t *testing.T) {
	apy := calculateAPYFromSupplyRate(0)
	require.Equal(t, 0.0, apy, "zero supply rate should yield zero APY")
}

func Test_calculateAPYFromSupplyRate_PositiveMatchesFormula(t *testing.T) {
	// Choose a target simple annual rate (e.g. 5%)
	targetSimple := 0.05

	// r_per_second = targetSimple / secondsPerYear
	rPerSecond := targetSimple / float64(constants.SecondsPerYear)

	// Convert to WAD-scaled per-second rate
	supplyRateInWad := uint64(rPerSecond * constants.WAD)

	// Call function under test
	apy := calculateAPYFromSupplyRate(supplyRateInWad)

	// Expected value using the SAME formula as implementation:
	// APY = (1 + r)^secondsPerYear - 1, where r = supplyRateInWad / WAD.
	rFromWad := float64(supplyRateInWad) / constants.WAD
	expected := math.Pow(1.0+rFromWad, float64(constants.SecondsPerYear)) - 1

	require.InDelta(t, expected, apy, 1e-15, "APY should match discrete compounding formula")
	require.Greater(t, apy, 0.0, "APY should be positive for positive rate")
}

func Test_calculateAPYFromSupplyRate_CompoundingBeatsSimpleRate(t *testing.T) {
	// Use a small annual rate where compounding should be slightly higher
	targetSimple := 0.01 // 1% simple annual

	rPerSecond := targetSimple / float64(constants.SecondsPerYear)
	supplyRateInWad := uint64(rPerSecond * constants.WAD)

	apy := calculateAPYFromSupplyRate(supplyRateInWad)

	// For a positive per-second rate, compounded APY should be > simple rate
	require.Greater(t, apy, targetSimple, "compounded APY should exceed simple rate for positive r")

	// And still be in the same ballpark (within about 1% relative error)
	require.InEpsilon(t, targetSimple, apy, 1e-2, "compounded APY should be close to simple rate for small r")
}

func Test_calculateAPYFromSupplyRate_MonotonicIncreasing(t *testing.T) {
	// Two different positive rates
	lowerRate := uint64(1_000_000_000) // arbitrary small WAD-scaled rate
	higherRate := uint64(2_000_000_000)

	apyLower := calculateAPYFromSupplyRate(lowerRate)
	apyHigher := calculateAPYFromSupplyRate(higherRate)

	require.Greater(t, apyHigher, apyLower, "APY should be monotonic in the supply rate")
}
