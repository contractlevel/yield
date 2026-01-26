package uniswapV3

import (
	"math/big"

	"github.com/ethereum/go-ethereum/common"
)

// PoolState represents the current state of a Uniswap V3 pool
type PoolState struct {
	// Token0 is the address of token0 in the pool
	Token0 common.Address
	// Token1 is the address of token1 in the pool
	Token1 common.Address
	// Fee is the pool's fee tier
	Fee uint32
	// SqrtPriceX96 is the current sqrt price as a Q64.96 value
	SqrtPriceX96 *big.Int
	// Tick is the current tick
	Tick int32
	// Liquidity is the currently in-range liquidity
	Liquidity *big.Int
}

// SwapViability represents whether a swap is viable given liquidity constraints
type SwapViability struct {
	// IsViable indicates whether the swap can be executed within constraints
	IsViable bool
	// ExpectedAmountOut is the expected output amount from the swap
	ExpectedAmountOut *big.Int
	// PriceImpactBps is the estimated price impact in basis points
	PriceImpactBps uint32
	// Reason provides context if the swap is not viable
	Reason string
}

// LiquidityCheckParams contains parameters for checking swap liquidity
type LiquidityCheckParams struct {
	// TokenIn is the address of the token to swap from
	TokenIn common.Address
	// TokenOut is the address of the token to swap to
	TokenOut common.Address
	// AmountIn is the amount of tokenIn to swap
	AmountIn *big.Int
	// MaxSlippageBps is the maximum allowed slippage in basis points
	MaxSlippageBps uint32
	// ChainSelector is the chain selector for the swap
	ChainSelector uint64
}

// QuoteParams contains parameters for getting a swap quote
type QuoteParams struct {
	// TokenIn is the address of the token to swap from
	TokenIn common.Address
	// TokenOut is the address of the token to swap to
	TokenOut common.Address
	// Fee is the pool fee tier
	Fee uint32
	// AmountIn is the amount to swap
	AmountIn *big.Int
	// SqrtPriceLimitX96 is the price limit (0 for no limit)
	SqrtPriceLimitX96 *big.Int
}

// QuoteResult contains the result of a swap quote
type QuoteResult struct {
	// AmountOut is the expected output amount
	AmountOut *big.Int
	// SqrtPriceX96After is the sqrt price after the swap
	SqrtPriceX96After *big.Int
	// InitializedTicksCrossed is the number of initialized ticks crossed
	InitializedTicksCrossed uint32
	// GasEstimate is the estimated gas for the swap
	GasEstimate *big.Int
}

// MultiChainSwapParams contains parameters for checking multi-chain swap viability
type MultiChainSwapParams struct {
	// SourceChainSelector is the chain selector for the source chain
	SourceChainSelector uint64
	// DestChainSelector is the chain selector for the destination chain
	DestChainSelector uint64
	// SourceToken is the token address on the source chain
	SourceToken common.Address
	// DestToken is the token address on the destination chain
	DestToken common.Address
	// Amount is the amount to swap
	Amount *big.Int
	// MaxSlippageBps is the maximum allowed slippage in basis points
	MaxSlippageBps uint32
}
