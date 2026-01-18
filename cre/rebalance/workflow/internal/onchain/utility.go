package onchain

import "fmt"

func sameStrategy(a, b Strategy) bool {
	return a.ProtocolId == b.ProtocolId &&
		a.ChainSelector == b.ChainSelector
}

// protocolIDToString converts a protocol ID byte array to its human-readable string name.
func protocolIDToString(protocolId [32]byte) string {
	switch protocolId {
	case AaveV3ProtocolId:
		return "aave-v3"
	case CompoundV3ProtocolId:
		return "compound-v3"
	default:
		return fmt.Sprintf("unknown(%x)", protocolId)
	}
}