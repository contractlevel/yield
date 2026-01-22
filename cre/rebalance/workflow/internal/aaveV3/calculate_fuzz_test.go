package aaveV3

import (
	"math"
	"math/big"
	"testing"

	"rebalance/workflow/internal/constants"

	"github.com/stretchr/testify/require"
)

// Fuzz_convertAPRToAPY_Properties fuzzes the APR input (as a decimal, e.g. 0.05 = 5%)
// and checks core properties of convertAPRToAPY:
//
//   - For APR > 10 ( > 1000% ) it returns an error and APY = 0.
//   - For APR in [0, 10], it returns a finite, non-negative APY.
//   - For APR == 0, APY == 0.
//   - For APR in (0, 10], APY matches the discrete compounding formula:
//
//       perSecond = APR / SECONDS_PER_YEAR
//       APY = (1 + perSecond)^SECONDS_PER_YEAR - 1
func Fuzz_convertAPRToAPY_Properties(f *testing.F) {
	// Seed with representative APR values (as decimals).
	f.Add(0.0)   // 0%
	f.Add(0.0001) // 0.01%
	f.Add(0.01)  // 1%
	f.Add(0.05)  // 5%
	f.Add(1.0)   // 100%
	f.Add(9.99)  // just below 1000%
	f.Add(11.0)  // above 1000% -> should error

	f.Fuzz(func(t *testing.T, raw float64) {
		// Map raw into a bounded, non-negative APR range [0, 12).
		// This exercises:
		//   - [0, 10]  valid APRs
		//   - (10, 12) APRs that should trigger the "exceeds 1000%" error.
		aprFloat := math.Mod(math.Abs(raw), 12.0)

		// Build a big.Rat from the APR. SetFloat64 never returns nil here.
		aprRat := new(big.Rat).SetFloat64(aprFloat)

		// Convert back to float from the rat, mirroring what convertAPRToAPY does.
		aprFromRat, _ := aprRat.Float64()

		apy, err := convertAPRToAPY(aprRat)

		// If APR > 10 ( > 1000% ), we expect an error and APY = 0.
		if aprFromRat > 10 {
			require.Error(t, err, "APR > 10 should return an error")
			require.Contains(t, err.Error(), "APR exceeds 1000%", "error message should mention APR limit")
			require.Equal(t, 0.0, apy, "on error, APY should be 0")
			return
		}

		// Valid APR region [0, 10].
		require.NoError(t, err, "APR in [0,10] should not error")
		require.False(t, math.IsNaN(apy), "APY must not be NaN")
		require.False(t, math.IsInf(apy, 0), "APY must not be Inf")

		// APR == 0 -> APY == 0
		if aprFromRat == 0 {
			require.Equal(t, 0.0, apy, "zero APR must yield zero APY")
			return
		}

		require.GreaterOrEqual(t, apy, 0.0, "APY should be >= 0 for non-negative APR")

		// Expected APY from the documented formula:
		//
		//   perSecond = APR / SECONDS_PER_YEAR
		//   APY = (1 + perSecond)^SECONDS_PER_YEAR - 1
		perSecond := aprFromRat / float64(constants.SecondsPerYear)
		expected := math.Pow(1.0+perSecond, float64(constants.SecondsPerYear)) - 1

		require.False(t, math.IsNaN(expected), "expected APY must not be NaN")
		require.False(t, math.IsInf(expected, 0), "expected APY must not be Inf")

		// Use a relative tolerance scaled by the magnitude of expected.
		tol := math.Abs(expected) * 1e-12
		if tol < 1e-12 {
			tol = 1e-12
		}

		require.InDelta(t, expected, apy, tol,
			"APY must match discrete compounding formula for APR=%g", aprFromRat)
	})
}
