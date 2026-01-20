package constants

const (
	// WAD is Compound's fixed-point math unit (18 decimals)
	WAD = 1e18
	// RAY is Aave's fixed-point math unit (27 decimals)
	// Aave stores interest rates as integers with 27 decimal places
	// Example: 1.5% APY = 0.015 * 1e27 = 15000000000000000000000000
	// This avoids floating-point precision issues in Solidity
	RAY = 1e27
	// SecondsPerYear is the number of seconds in a year (365 * 24 * 60 * 60)
	SecondsPerYear = 31536000
	// UsdcDecimals is the number of decimals for USDC (6)
	UsdcDecimals = 6
	// UsdcDecimalsDivisor is 10^6, used for converting raw USDC amounts to units
	UsdcDecimalsDivisor = 1e6
	// RayDecimals is the number of decimals in RAY (27)
	RayDecimals = 27
	// BasisPointsDecimals is the number of decimals for basis points (4)
	// Reserve factor is stored in basis points (10000 = 100%)
	// e.g., 1000 = 10% = 0.10
	BasisPointsDecimals = 4
)