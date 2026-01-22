package helper

import (
	"math"
	"testing"

	"rebalance/workflow/internal/constants"

	"github.com/stretchr/testify/require"
)

// FuzzAPYFromPerSecondRate fuzzes the per-second rate r and checks that
// APYFromPerSecondRate behaves consistently with the discrete compounding
// formula:
//
//   APY = (1 + r)^SECONDS_PER_YEAR - 1
//
// We deliberately map the raw fuzzed float into a small per-second range
// representative of realistic interest rates, to avoid spurious overflows.
func FuzzAPYFromPerSecondRate(f *testing.F) {
	// Seed corpus with a few representative values.
	f.Add(0.0)
	f.Add(1e-9)  // small positive rate
	f.Add(-1e-9) // small negative rate

	f.Fuzz(func(t *testing.T, raw float64) {
		// Skip pathological values.
		if math.IsNaN(raw) || math.IsInf(raw, 0) {
			t.Skip()
		}

		// Map raw into a realistic per-second range using tanh to keep it bounded.
		// This gives r in roughly [-1e-6, 1e-6], which covers a wide range
		// of plausible DeFi rates when compounded over a year.
		r := math.Tanh(raw) * 1e-6

		apy := APYFromPerSecondRate(r)

		// r == 0 should always yield APY == 0.
		if r == 0 {
			require.Equal(t, 0.0, apy, "zero per-second rate must yield zero APY")
			return
		}

		// Direct computation using the defining formula.
		base := 1.0 + r
		// Guard against non-positive base which would make Pow undefined for
		// non-integer exponents in general; with our bounded r this should not happen,
		// but keep the check to make the fuzz harness robust.
		if base <= 0 {
			t.Skip()
		}

		expected := math.Pow(base, float64(constants.SecondsPerYear)) - 1

		// Sanity: helper should never produce NaN/Inf for our domain.
		require.False(t, math.IsNaN(apy) || math.IsInf(apy, 0),
			"APYFromPerSecondRate produced invalid result for r=%v: %v", r, apy)

		// Direct formula should also be finite; otherwise the test case is not useful.
		if math.IsNaN(expected) || math.IsInf(expected, 0) {
			t.Skip()
		}

		// Signs should match.
		require.Equal(t, math.Signbit(expected), math.Signbit(apy),
			"sign mismatch for r=%v: expected=%v got=%v", r, expected, apy)

		// Values should match within a tight epsilon.
		require.InDelta(t, expected, apy, 1e-15,
			"mismatch for r=%v: expected=%v got=%v", r, expected, apy)
	})
}
