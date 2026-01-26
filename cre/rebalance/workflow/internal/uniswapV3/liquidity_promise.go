package uniswapV3

import (
	"fmt"
	"math/big"

	"rebalance/workflow/internal/helper"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// CheckSwapLiquidityPromise checks if a swap is viable given liquidity constraints
// This is the main entry point for checking swap viability on a single chain
func CheckSwapLiquidityPromise(
	config *helper.Config,
	runtime cre.Runtime,
	params *LiquidityCheckParams,
) cre.Promise[*SwapViability] {
	// Validate inputs
	if params == nil {
		return cre.PromiseFromResult[*SwapViability](nil, fmt.Errorf("params cannot be nil"))
	}

	if params.AmountIn == nil || params.AmountIn.Sign() == 0 {
		return cre.PromiseFromResult(&SwapViability{
			IsViable: true,
			Reason:   "zero amount - no swap needed",
		}, nil)
	}

	// If tokens are the same, no swap needed
	if params.TokenIn == params.TokenOut {
		return cre.PromiseFromResult(&SwapViability{
			IsViable:          true,
			ExpectedAmountOut: params.AmountIn,
			Reason:            "same token - no swap needed",
		}, nil)
	}

	// Find chain config
	evmCfg, err := helper.FindEvmConfigByChainSelector(config.Evms, params.ChainSelector)
	if err != nil {
		return cre.PromiseFromResult[*SwapViability](nil, fmt.Errorf("chain config not found: %w", err))
	}

	// Get QuoterV2 address for this chain
	quoterAddr, ok := UniswapV3QuoterV2Addresses[params.ChainSelector]
	if !ok {
		return cre.PromiseFromResult[*SwapViability](nil, fmt.Errorf("no QuoterV2 address for chain %s", evmCfg.ChainName))
	}

	// Use default slippage if not specified
	maxSlippage := params.MaxSlippageBps
	if maxSlippage == 0 {
		maxSlippage = DefaultMaxSlippageBps
	}

	// Get quote from QuoterV2
	quotePromise := getQuotePromise(runtime, params.ChainSelector, quoterAddr, params.TokenIn, params.TokenOut, params.AmountIn)

	return cre.ThenPromise(quotePromise, func(quote *QuoteResult) cre.Promise[*SwapViability] {
		if quote == nil || quote.AmountOut == nil {
			return cre.PromiseFromResult(&SwapViability{
				IsViable: false,
				Reason:   "failed to get quote from QuoterV2",
			}, nil)
		}

		viability := IsSwapViable(params.AmountIn, quote.AmountOut, maxSlippage)
		return cre.PromiseFromResult(viability, nil)
	})
}

// CheckMultiChainSwapViability checks swap viability for a cross-chain transfer
// This considers:
// 1. Source chain: swap from source token to USDC (if not already USDC)
// 2. Dest chain: swap from USDC to dest token (if not USDC)
func CheckMultiChainSwapViability(
	config *helper.Config,
	runtime cre.Runtime,
	params *MultiChainSwapParams,
) cre.Promise[*SwapViability] {
	if params == nil {
		return cre.PromiseFromResult[*SwapViability](nil, fmt.Errorf("params cannot be nil"))
	}

	if params.Amount == nil || params.Amount.Sign() == 0 {
		return cre.PromiseFromResult(&SwapViability{
			IsViable: true,
			Reason:   "zero amount - no swap needed",
		}, nil)
	}

	// Find USDC address on source chain
	sourceEvmCfg, err := helper.FindEvmConfigByChainSelector(config.Evms, params.SourceChainSelector)
	if err != nil {
		return cre.PromiseFromResult[*SwapViability](nil, fmt.Errorf("source chain config not found: %w", err))
	}
	sourceUsdc := common.HexToAddress(sourceEvmCfg.USDCAddress)

	// Find USDC address on dest chain
	destEvmCfg, err := helper.FindEvmConfigByChainSelector(config.Evms, params.DestChainSelector)
	if err != nil {
		return cre.PromiseFromResult[*SwapViability](nil, fmt.Errorf("dest chain config not found: %w", err))
	}
	destUsdc := common.HexToAddress(destEvmCfg.USDCAddress)

	maxSlippage := params.MaxSlippageBps
	if maxSlippage == 0 {
		maxSlippage = DefaultMaxSlippageBps
	}

	// Check source swap (sourceToken -> USDC) if needed
	sourceSwapNeeded := params.SourceToken != sourceUsdc
	var sourceSwapPromise cre.Promise[*SwapViability]

	if sourceSwapNeeded {
		sourceSwapPromise = CheckSwapLiquidityPromise(config, runtime, &LiquidityCheckParams{
			TokenIn:        params.SourceToken,
			TokenOut:       sourceUsdc,
			AmountIn:       params.Amount,
			MaxSlippageBps: maxSlippage,
			ChainSelector:  params.SourceChainSelector,
		})
	} else {
		sourceSwapPromise = cre.PromiseFromResult(&SwapViability{
			IsViable:          true,
			ExpectedAmountOut: params.Amount,
			Reason:            "no source swap needed",
		}, nil)
	}

	// Chain the dest swap check
	return cre.ThenPromise(sourceSwapPromise, func(sourceViability *SwapViability) cre.Promise[*SwapViability] {
		if sourceViability == nil || !sourceViability.IsViable {
			return cre.PromiseFromResult(sourceViability, nil)
		}

		// Amount after source swap (USDC amount)
		usdcAmount := sourceViability.ExpectedAmountOut
		if usdcAmount == nil {
			usdcAmount = params.Amount
		}

		// Check dest swap (USDC -> destToken) if needed
		destSwapNeeded := params.DestToken != destUsdc
		if !destSwapNeeded {
			// No dest swap needed, combine results
			return cre.PromiseFromResult(&SwapViability{
				IsViable:          true,
				ExpectedAmountOut: usdcAmount,
				PriceImpactBps:    sourceViability.PriceImpactBps,
				Reason:            "viable - no dest swap needed",
			}, nil)
		}

		destSwapPromise := CheckSwapLiquidityPromise(config, runtime, &LiquidityCheckParams{
			TokenIn:        destUsdc,
			TokenOut:       params.DestToken,
			AmountIn:       usdcAmount,
			MaxSlippageBps: maxSlippage,
			ChainSelector:  params.DestChainSelector,
		})

		return cre.ThenPromise(destSwapPromise, func(destViability *SwapViability) cre.Promise[*SwapViability] {
			if destViability == nil || !destViability.IsViable {
				return cre.PromiseFromResult(destViability, nil)
			}

			// Combine price impacts
			totalPriceImpact := sourceViability.PriceImpactBps + destViability.PriceImpactBps

			return cre.PromiseFromResult(&SwapViability{
				IsViable:          true,
				ExpectedAmountOut: destViability.ExpectedAmountOut,
				PriceImpactBps:    totalPriceImpact,
				Reason:            "viable - both swaps passed",
			}, nil)
		})
	})
}

// getQuotePromise gets a swap quote from the QuoterV2 contract
// This is a simplified implementation that uses the QuoterV2 interface
func getQuotePromise(
	runtime cre.Runtime,
	chainSelector uint64,
	quoterAddr string,
	tokenIn, tokenOut common.Address,
	amountIn *big.Int,
) cre.Promise[*QuoteResult] {
	// In a real implementation, this would:
	// 1. Create an EVM client for the chain
	// 2. Create a QuoterV2 binding
	// 3. Call quoteExactInputSingle

	// For now, return a simplified estimate for stablecoins
	// Stablecoins should trade near 1:1, minus the 0.05% fee

	// Calculate expected output: amountIn * (1 - 0.0005) for 0.05% fee tier
	feeMultiplier := big.NewInt(int64(BpsDenominator - DefaultStablecoinFeeTier/100))
	expectedOut := new(big.Int).Mul(amountIn, feeMultiplier)
	expectedOut.Div(expectedOut, big.NewInt(int64(BpsDenominator)))

	return cre.PromiseFromResult(&QuoteResult{
		AmountOut:   expectedOut,
		GasEstimate: big.NewInt(150000), // Typical gas for a swap
	}, nil)
}
