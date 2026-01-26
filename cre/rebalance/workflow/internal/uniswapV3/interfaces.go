package uniswapV3

import (
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// UniswapV3PoolInterface defines the interface for Uniswap V3 Pool contract interactions
type UniswapV3PoolInterface interface {
	// Slot0 returns the pool's slot0 data (sqrtPriceX96, tick, etc.)
	Slot0() cre.Promise[Slot0Result]
	// Liquidity returns the pool's current liquidity
	Liquidity() cre.Promise[*big.Int]
	// Token0 returns the address of token0
	Token0() cre.Promise[common.Address]
	// Token1 returns the address of token1
	Token1() cre.Promise[common.Address]
	// Fee returns the pool's fee tier
	Fee() cre.Promise[uint32]
}

// Slot0Result represents the result of calling slot0 on a Uniswap V3 pool
type Slot0Result struct {
	SqrtPriceX96               *big.Int
	Tick                       int32
	ObservationIndex           uint16
	ObservationCardinality     uint16
	ObservationCardinalityNext uint16
	FeeProtocol                uint8
	Unlocked                   bool
}

// QuoterV2Interface defines the interface for Uniswap V3 QuoterV2 contract interactions
type QuoterV2Interface interface {
	// QuoteExactInputSingle returns a quote for a single-hop exact input swap
	QuoteExactInputSingle(params QuoteExactInputSingleParams) cre.Promise[*QuoteResult]
}

// QuoteExactInputSingleParams contains parameters for quoteExactInputSingle
type QuoteExactInputSingleParams struct {
	TokenIn           common.Address
	TokenOut          common.Address
	AmountIn          *big.Int
	Fee               uint32
	SqrtPriceLimitX96 *big.Int
}
