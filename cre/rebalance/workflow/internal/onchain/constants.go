package onchain

import "github.com/ethereum/go-ethereum/common"

var (
	// Protocol IDs - These are runtime vars, not compile-time consts.
	// keccak256("aave-v3")
	AaveV3ProtocolId = [32]byte(common.HexToHash("0xbbbf88eb3aaea499bd8961e51ce38087d4dda7879001b87ead64f8a7a3d0b2da"))
	// keccak256("compound-v3")
	CompoundV3ProtocolId = [32]byte(common.HexToHash("0x3af167fff8b2aadd8bc497987eee3c5c291f8d6741dda2249d1df61732ddfda1"))

	// Stablecoin IDs
	// keccak256("USDC")
	UsdcId = [32]byte(common.HexToHash("0xd6aca1be9729c13d677335161321649cccae6a591554772516700f986f942eaa"))
	// keccak256("USDT")
	UsdtId = [32]byte(common.HexToHash("0x8b1a1d9c2b109e527c9134b25b1a1833b16b6594f92daa9f6d9b7a6024bce9d0"))
	// keccak256("GHO")
	GhoId = [32]byte(common.HexToHash("0x89e8b9b34729373f6e100fab106bfc0a1e41df9e1d7194f4f19add5de2da7772"))
)