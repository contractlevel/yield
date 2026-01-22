package onchain

import (
	"testing"
	"fmt"

	"github.com/stretchr/testify/require"
)

func Test_sameStrategy(t *testing.T) {
	a := Strategy{
		ProtocolId:    AaveV3ProtocolId,
		ChainSelector: 123,
	}
	b := Strategy{
		ProtocolId:    AaveV3ProtocolId,
		ChainSelector: 123,
	}
	c := Strategy{
		ProtocolId:    CompoundV3ProtocolId,
		ChainSelector: 123,
	}
	d := Strategy{
		ProtocolId:    AaveV3ProtocolId,
		ChainSelector: 456,
	}

	tests := []struct {
		name string
		x, y Strategy
		want bool
	}{
		{"identical", a, b, true},
		{"different_protocol", a, c, false},
		{"different_chain", a, d, false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := sameStrategy(tt.x, tt.y)
			require.Equal(t, tt.want, got)
		})
	}
}

func Test_protocolIDToString(t *testing.T) {
	t.Run("aave_v3", func(t *testing.T) {
		got := protocolIDToString(AaveV3ProtocolId)
		require.Equal(t, "aave-v3", got)
	})

	t.Run("compound_v3", func(t *testing.T) {
		got := protocolIDToString(CompoundV3ProtocolId)
		require.Equal(t, "compound-v3", got)
	})

	t.Run("unknown_protocol", func(t *testing.T) {
		var unknown [32]byte // zero value; guaranteed != the known IDs
		got := protocolIDToString(unknown)

		expected := fmt.Sprintf("unknown(%x)", unknown)
		require.Equal(t, expected, got)
	})
}