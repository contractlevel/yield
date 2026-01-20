package compoundV3

import (
	"math"
	"testing"

	"rebalance/workflow/internal/constants"

	"github.com/stretchr/testify/require"
)

func Test_calculateAPYFromSupplyRate_Zero(t *testing.T) {
	apy := calculateAPYFromSupplyRate(0)
	require.Equal(t, 0.0, apy)
}

func Test_calculateAPYFromSupplyRate_PositiveMatchesFormula(t *testing.T) {
	// Choose a target simple annual rate (e.g. 5%)
	targetSimple := 0.05

	// r_per_second = targetSimple / secondsPerYear
	rPerSecond := targetSimple / float64(constants.SecondsPerYear)

	// Convert to WAD-scaled per-second rate
	supplyRateInWad := uint64(rPerSecond * float64(constants.WAD))

	// Call function under test
	apy := calculateAPYFromSupplyRate(supplyRateInWad)

	// Expected value using the same documented formula:
	// (1 + r)^secondsPerYear - 1, where r = supplyRateInWad / WAD.
	rFromWad := float64(supplyRateInWad) / float64(constants.WAD)
	expected := math.Exp(float64(constants.SecondsPerYear)*math.Log1p(rFromWad)) - 1

	require.InEpsilon(t, expected, apy, 1e-12)
	require.Greater(t, apy, 0.0)
}

func Test_calculateAPYFromSupplyRate_CompoundingBeatsSimpleRate(t *testing.T) {
	// Use a small annual rate where compounding should be slightly higher
	targetSimple := 0.01 // 1% simple annual

	rPerSecond := targetSimple / float64(constants.SecondsPerYear)
	supplyRateInWad := uint64(rPerSecond * float64(constants.WAD))

	apy := calculateAPYFromSupplyRate(supplyRateInWad)

	// For a positive per-second rate, compounded APY should be > simple rate
	require.Greater(t, apy, targetSimple)

	// But still in the same ballpark (within about 1% relative error)
	require.InEpsilon(t, targetSimple, apy, 1e-2)
}

func Test_calculateAPYFromSupplyRate_MonotonicIncreasing(t *testing.T) {
	// Two different positive rates
	lowerRate := uint64(1_000_000_000) // arbitrary small WAD-scaled rate
	higherRate := uint64(2_000_000_000)

	apyLower := calculateAPYFromSupplyRate(lowerRate)
	apyHigher := calculateAPYFromSupplyRate(higherRate)

	require.Greater(t, apyHigher, apyLower)
}
