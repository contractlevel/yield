package uniswapV3

import "github.com/ethereum/go-ethereum/common"

// Uniswap V3 fee tiers (in hundredths of a basis point)
const (
	// FeeTier001Percent is 0.01% fee tier (100 = 0.01%)
	FeeTier001Percent uint32 = 100
	// FeeTier005Percent is 0.05% fee tier (500 = 0.05%) - default for stablecoins
	FeeTier005Percent uint32 = 500
	// FeeTier030Percent is 0.30% fee tier (3000 = 0.30%)
	FeeTier030Percent uint32 = 3000
	// FeeTier100Percent is 1.00% fee tier (10000 = 1.00%)
	FeeTier100Percent uint32 = 10000

	// DefaultStablecoinFeeTier is the default fee tier for stablecoin swaps
	DefaultStablecoinFeeTier = FeeTier005Percent

	// DefaultMaxSlippageBps is the default maximum slippage in basis points (50 bps = 0.5%)
	DefaultMaxSlippageBps uint32 = 50

	// BpsDenominator is the basis points denominator
	BpsDenominator uint32 = 10000
)

// Stablecoin IDs (keccak256 hashes of stablecoin names)
var (
	// UsdcId is keccak256("USDC")
	UsdcId = [32]byte(common.HexToHash("0xd6aca1be9729c13d677335161321649cccae6a591554772516700f986f942eaa"))
	// UsdtId is keccak256("USDT")
	UsdtId = [32]byte(common.HexToHash("0x8b1a1d9c2b109e527c9134b25b1a1833b16b6594f92daa9f6d9b7a6024bce9d0"))
	// GhoId is keccak256("GHO")
	GhoId = [32]byte(common.HexToHash("0x89e8b9b34729373f6e100fab106bfc0a1e41df9e1d7194f4f19add5de2da7772"))
)

// UniswapV3QuoterV2Addresses contains the QuoterV2 addresses per chain
// These are the canonical Uniswap V3 QuoterV2 deployments
var UniswapV3QuoterV2Addresses = map[uint64]string{
	// Ethereum Mainnet
	5009297550715157269: "0x61fFE014bA17989E743c5F6cB21bF9697530B21e",
	// Avalanche
	6433500567565415381: "0xbe0F5544EC67e9B3b2D979aaA43f18Fd87E6257F",
	// Base
	15971525489660198786: "0x3d4e44Eb1374240CE5F1B871ab261CD16335B76a",
	// Arbitrum
	4949039107694359620: "0x61fFE014bA17989E743c5F6cB21bF9697530B21e",
	// Optimism
	3734403246176062136: "0x61fFE014bA17989E743c5F6cB21bF9697530B21e",
	// Polygon
	4051577828743386545: "0x61fFE014bA17989E743c5F6cB21bF9697530B21e",
}

// UniswapV3SwapRouterAddresses contains the SwapRouter02 addresses per chain
var UniswapV3SwapRouterAddresses = map[uint64]string{
	// Ethereum Mainnet
	5009297550715157269: "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45",
	// Avalanche
	6433500567565415381: "0xbb00FF08d01D300023C629E8fFfFcb65A5a578cE",
	// Base
	15971525489660198786: "0x2626664c2603336E57B271c5C0b26F421741e481",
	// Arbitrum
	4949039107694359620: "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45",
	// Optimism
	3734403246176062136: "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45",
	// Polygon
	4051577828743386545: "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45",
}
