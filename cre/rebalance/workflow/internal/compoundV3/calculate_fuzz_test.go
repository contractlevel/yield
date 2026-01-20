package compoundV3

import (
	"math"
	"testing"

	"github.com/stretchr/testify/require"
)

// We bound the fuzzed per-second WAD rate to avoid absurdly large exponents.
// With WAD = 1e18 and maxFuzzSupplyRateInWad = 1e12,
//   rPerSecond <= 1e12 / 1e18 = 1e-6
// so secondsPerYear * rPerSecond ~ 3e7 * 1e-6 ≈ 30,
// and exp(30) is comfortably finite in float64.
const maxFuzzSupplyRateInWad = uint64(1_000_000_000_000) // 1e12

// Fuzz_calculateAPYFromSupplyRate_Properties fuzzes the per-second WAD rate and
// checks core properties:
//
//   - APY is finite (not NaN, not Inf).
//   - APY is non-negative.
//   - Zero rate => zero APY.
//   - APY is (numerically) non-decreasing as the rate increases by 1 WAD unit.
func Fuzz_calculateAPYFromSupplyRate_Properties(f *testing.F) {
	// Seeds: zero, tiny, and moderate per-second rates.
	f.Add(uint64(0))
	f.Add(uint64(1))
	f.Add(uint64(1_000_000_000))      // very small r
	f.Add(uint64(1_000_000_000_000))  // at upper bound
	f.Add(uint64(10_000_000_000_000)) // will be reduced modulo maxFuzzSupplyRateInWad

	f.Fuzz(func(t *testing.T, raw uint64) {
		t.Helper()

		// Bound the fuzzed rate to a safe, realistic range.
		supplyRateInWad := raw % maxFuzzSupplyRateInWad

		apy := calculateAPYFromSupplyRate(supplyRateInWad)

		// 1) Basic sanity.
		require.False(t, math.IsNaN(apy), "APY must not be NaN")
		require.False(t, math.IsInf(apy, 0), "APY must not be Inf")
		require.GreaterOrEqual(t, apy, 0.0, "APY must be non-negative")

		// 2) Zero rate => zero APY.
		if supplyRateInWad == 0 {
			require.Equal(t, 0.0, apy, "zero rate must yield zero APY")
		}

		// 3) Monotonicity (up to tiny floating-point noise):
		// A slightly higher rate (rate+1) should not produce a significantly lower APY.
		if supplyRateInWad+1 < maxFuzzSupplyRateInWad {
			apy2 := calculateAPYFromSupplyRate(supplyRateInWad + 1)

			require.False(t, math.IsNaN(apy2), "APY(rate+1) must not be NaN")
			require.False(t, math.IsInf(apy2, 0), "APY(rate+1) must not be Inf")

			// Allow a very small epsilon for floating-point quirks.
			const monoEps = 1e-12

			require.GreaterOrEqual(t, apy2+monoEps, apy,
				"APY should be (numerically) non-decreasing with rate: rate=%d apy=%g apy(rate+1)=%g",
				supplyRateInWad, apy, apy2)
		}
	})
}
