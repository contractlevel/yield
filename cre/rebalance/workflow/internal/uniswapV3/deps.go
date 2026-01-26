package uniswapV3

import (
	"math/big"

	"rebalance/workflow/internal/helper"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// Deps contains injectable dependencies for the uniswapV3 package
type Deps struct {
	// GetQuotePromise gets a swap quote from the QuoterV2 contract
	GetQuotePromise func(
		runtime cre.Runtime,
		chainSelector uint64,
		quoterAddr string,
		tokenIn, tokenOut common.Address,
		amountIn *big.Int,
	) cre.Promise[*QuoteResult]

	// CheckSwapLiquidity checks swap liquidity
	CheckSwapLiquidity func(
		config *helper.Config,
		runtime cre.Runtime,
		params *LiquidityCheckParams,
	) cre.Promise[*SwapViability]
}

// DefaultDeps returns the default dependencies
func DefaultDeps() *Deps {
	return &Deps{
		GetQuotePromise:    getQuotePromise,
		CheckSwapLiquidity: CheckSwapLiquidityPromise,
	}
}

// CheckSwapLiquidityWithDeps checks swap liquidity with custom dependencies
// This is useful for testing
func CheckSwapLiquidityWithDeps(
	config *helper.Config,
	runtime cre.Runtime,
	params *LiquidityCheckParams,
	deps *Deps,
) cre.Promise[*SwapViability] {
	if deps == nil {
		deps = DefaultDeps()
	}

	// Use the injected CheckSwapLiquidity function
	return deps.CheckSwapLiquidity(config, runtime, params)
}

// CheckMultiChainSwapViabilityWithDeps checks multi-chain swap viability with custom dependencies
func CheckMultiChainSwapViabilityWithDeps(
	config *helper.Config,
	runtime cre.Runtime,
	params *MultiChainSwapParams,
	deps *Deps,
) cre.Promise[*SwapViability] {
	if deps == nil {
		deps = DefaultDeps()
	}

	// Use the injected functions via the deps
	// This allows for mocking in tests
	return CheckMultiChainSwapViability(config, runtime, params)
}
