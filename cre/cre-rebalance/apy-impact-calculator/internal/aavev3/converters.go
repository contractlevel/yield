package aavev3

import (
	"math/big"
)

// getRAYBigInt returns RAY (1e27) as a big.Int to avoid float64 precision issues.
// RAY is Aave's fixed-point math unit with 27 decimals.
func getRAYBigInt() *big.Int {
	ray := new(big.Int)
	ray.SetString("1000000000000000000000000000", 10) // 1e27
	return ray
}

// BigRatToString converts a *big.Rat to a decimal string with up to 18 decimal places.
// This preserves precision while providing a human-readable format.
func BigRatToString(r *big.Rat) string {
	if r == nil {
		return "0"
	}
	return r.FloatString(18)
}

// CompareBigRat compares two *big.Rat values.
// Returns: -1 if a < b, 0 if a == b, 1 if a > b
func CompareBigRat(a, b *big.Rat) int {
	if a == nil && b == nil {
		return 0
	}
	if a == nil {
		return -1
	}
	if b == nil {
		return 1
	}
	return a.Cmp(b)
}

// BigIntToUSDCString converts a big.Int (in USDC raw units with 6 decimals) to a decimal string.
// Example: 1000000 -> "1.000000", 1000000000000 -> "1000000.000000"
func BigIntToUSDCString(amount *big.Int) string {
	if amount == nil || amount.Sign() == 0 {
		return "0"
	}
	// Convert to big.Rat with 6 decimal places
	rat := new(big.Rat).SetInt(amount)
	divisor := big.NewInt(USDC_DECIMALS_DIVISOR)
	rat.Quo(rat, new(big.Rat).SetInt(divisor))
	return rat.FloatString(6)
}

