package aaveV3

const (
	// RAY is Aave's fixed-point math unit (27 decimals)
	// Aave stores interest rates as integers with 27 decimal places
	// Example: 1.5% APY = 0.015 * 1e27 = 15000000000000000000000000
	// This avoids floating-point precision issues in Solidity
	RAY = 1e27

	// SECONDS_PER_YEAR is the number of seconds in a year (365 * 24 * 60 * 60)
	SECONDS_PER_YEAR = 31536000

	// USDC_DECIMALS is the number of decimals for USDC (6)
	USDC_DECIMALS = 6

	// USDC_DECIMALS_DIVISOR is 10^6, used for converting raw USDC amounts to units
	USDC_DECIMALS_DIVISOR = 1e6

	// RAY_DECIMALS is the number of decimals in RAY (27)
	RAY_DECIMALS = 27

	// BASIS_POINTS_DECIMALS is the number of decimals for basis points (4)
	// Reserve factor is stored in basis points (10000 = 100%)
	// e.g., 1000 = 10% = 0.10
	BASIS_POINTS_DECIMALS = 4
)