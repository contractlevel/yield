package onchain

import (
	"testing"

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