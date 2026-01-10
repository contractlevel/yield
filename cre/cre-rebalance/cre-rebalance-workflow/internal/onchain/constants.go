package onchain

import "github.com/ethereum/go-ethereum/common"

var (
    // These are runtime vars, not compile-time consts.
	// keccak256("aave-v3")
    AaveV3ProtocolId     = [32]byte(common.HexToHash("0xbbbf88eb3aaea499bd8961e51ce38087d4dda7879001b87ead64f8a7a3d0b2da"))
	// keccak256("compound-v3")
    CompoundV3ProtocolId = [32]byte(common.HexToHash("0x3af167fff8b2aadd8bc497987eee3c5c291f8d6741dda2249d1df61732ddfda1"))
)