package helper

import (
	"math"
	"testing"

	"rebalance/workflow/internal/constants"

	"github.com/stretchr/testify/require"
)

func TestAPYFromPerSecondRate_Zero(t *testing.T) {
	got := APYFromPerSecondRate(0)
	require.Equal(t, 0.0, got, "zero per-second rate should yield zero APY")
}

func TestAPYFromPerSecondRate_PositiveRate(t *testing.T) {
	// Example: 5% APR expressed as a per-second rate.
	apr := 0.05
	r := apr / float64(constants.SecondsPerYear)

	got := APYFromPerSecondRate(r)

	// Expected uses the same mathematical formula:
	want := math.Pow(1.0+r, float64(constants.SecondsPerYear)) - 1

	require.InDelta(t, want, got, 1e-15, "APY should match discrete compounding formula for positive rate")
	require.Greater(t, got, 0.0, "APY should be positive for positive rate")
}

func TestAPYFromPerSecondRate_NegativeRate(t *testing.T) {
	// Example: -1% APR expressed as a per-second rate.
	apr := -0.01
	r := apr / float64(constants.SecondsPerYear)

	got := APYFromPerSecondRate(r)

	// Expected again uses the same formula:
	want := math.Pow(1.0+r, float64(constants.SecondsPerYear)) - 1

	require.InDelta(t, want, got, 1e-15, "APY should match discrete compounding formula for negative rate")
	require.Less(t, got, 0.0, "APY should be negative for negative rate")
}
