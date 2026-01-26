package uniswapV3

import (
	"math/big"
)

// CalculatePriceImpact calculates the price impact of a swap in basis points
// priceImpact = |1 - (amountOut / amountIn)| * 10000
// For stablecoins, amountIn and amountOut should be roughly equal
func CalculatePriceImpact(amountIn, amountOut *big.Int) uint32 {
	if amountIn == nil || amountIn.Sign() == 0 || amountOut == nil {
		return 0
	}

	// Calculate ratio: amountOut / amountIn
	// We use fixed-point arithmetic with 18 decimals for precision
	precision := new(big.Int).Exp(big.NewInt(10), big.NewInt(18), nil)

	// (amountOut * precision) / amountIn
	ratio := new(big.Int).Mul(amountOut, precision)
	ratio.Div(ratio, amountIn)

	// Calculate |1 - ratio| in basis points
	// 1 in precision terms = precision
	diff := new(big.Int).Sub(precision, ratio)
	if diff.Sign() < 0 {
		diff.Abs(diff)
	}

	// Convert to basis points: (diff * 10000) / precision
	bps := new(big.Int).Mul(diff, big.NewInt(int64(BpsDenominator)))
	bps.Div(bps, precision)

	return uint32(bps.Uint64())
}

// CalculateMinAmountOut calculates the minimum amount out given slippage tolerance
// minAmountOut = amountIn * (1 - slippageBps / 10000)
func CalculateMinAmountOut(amountIn *big.Int, slippageBps uint32) *big.Int {
	if amountIn == nil || amountIn.Sign() == 0 {
		return big.NewInt(0)
	}

	// Calculate (BpsDenominator - slippageBps)
	multiplier := BpsDenominator - slippageBps

	// minAmountOut = amountIn * multiplier / BpsDenominator
	result := new(big.Int).Mul(amountIn, big.NewInt(int64(multiplier)))
	result.Div(result, big.NewInt(int64(BpsDenominator)))

	return result
}

// IsSwapViable checks if a swap is viable given the expected output and slippage constraints
func IsSwapViable(amountIn, expectedAmountOut *big.Int, maxSlippageBps uint32) *SwapViability {
	if amountIn == nil || amountIn.Sign() == 0 {
		return &SwapViability{
			IsViable: false,
			Reason:   "amount in is zero or nil",
		}
	}

	if expectedAmountOut == nil || expectedAmountOut.Sign() == 0 {
		return &SwapViability{
			IsViable: false,
			Reason:   "expected amount out is zero or nil",
		}
	}

	priceImpactBps := CalculatePriceImpact(amountIn, expectedAmountOut)
	minAmountOut := CalculateMinAmountOut(amountIn, maxSlippageBps)

	// Check if expected output meets minimum requirements
	if expectedAmountOut.Cmp(minAmountOut) < 0 {
		return &SwapViability{
			IsViable:          false,
			ExpectedAmountOut: expectedAmountOut,
			PriceImpactBps:    priceImpactBps,
			Reason:            "expected amount out below minimum with slippage tolerance",
		}
	}

	// Check if price impact exceeds maximum allowed
	if priceImpactBps > maxSlippageBps {
		return &SwapViability{
			IsViable:          false,
			ExpectedAmountOut: expectedAmountOut,
			PriceImpactBps:    priceImpactBps,
			Reason:            "price impact exceeds maximum slippage",
		}
	}

	return &SwapViability{
		IsViable:          true,
		ExpectedAmountOut: expectedAmountOut,
		PriceImpactBps:    priceImpactBps,
	}
}

// AdjustAPYForSwapCost adjusts the APY to account for swap costs
// Returns the effective APY after accounting for the swap cost
// swapCostBps is typically 2x the fee tier (buy + sell) plus price impact
func AdjustAPYForSwapCost(rawAPY float64, swapCostBps uint32) float64 {
	// Convert basis points to decimal (e.g., 50 bps = 0.005)
	swapCostDecimal := float64(swapCostBps) / float64(BpsDenominator)

	// Adjusted APY = rawAPY - swapCost
	// This is a simplified model; a more accurate model would consider hold time
	adjustedAPY := rawAPY - swapCostDecimal

	// Don't return negative APY
	if adjustedAPY < 0 {
		return 0
	}

	return adjustedAPY
}

// EstimateSwapCost estimates the total swap cost in basis points
// This includes the pool fee and estimated price impact
func EstimateSwapCost(feeTier, priceImpactBps uint32, isRoundTrip bool) uint32 {
	// For a round trip (e.g., USDC -> USDT -> USDC), we pay fees twice
	multiplier := uint32(1)
	if isRoundTrip {
		multiplier = 2
	}

	// Total cost = (fee * multiplier) + (priceImpact * multiplier)
	// fee is in hundredths of a bps, need to convert to bps
	feeInBps := feeTier / 100

	return (feeInBps * multiplier) + (priceImpactBps * multiplier)
}
