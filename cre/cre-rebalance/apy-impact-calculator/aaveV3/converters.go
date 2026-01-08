package aaveV3

import (
	"math/big"
)

// BigRatToString converts a *big.Rat to a decimal string with up to 18 decimal places.
func BigRatToString(r *big.Rat) string {
	if r == nil {
		return "0"
	}
	return r.FloatString(18)
}

// Float64ToString converts a float64 to a decimal string with up to 18 decimal places.
func Float64ToString(f float64) string {
	rat := new(big.Rat)
	rat.SetFloat64(f)
	return rat.FloatString(18)
}

// BigIntToUSDCString converts a big.Int (in USDC raw units with 6 decimals) to a decimal string.
func BigIntToUSDCString(amount *big.Int) string {
	if amount == nil || amount.Sign() == 0 {
		return "0"
	}
	rat := new(big.Rat).SetInt(amount)
	divisor := big.NewInt(USDC_DECIMALS_DIVISOR)
	rat.Quo(rat, new(big.Rat).SetInt(divisor))
	return rat.FloatString(6)
}
