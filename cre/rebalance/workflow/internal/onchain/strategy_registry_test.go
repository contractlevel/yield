package onchain

import (
	"testing"

	"rebalance/workflow/internal/helper"

	"github.com/stretchr/testify/require"
)

func Test_initSupportedStrategies_noEvms(t *testing.T) {
	cfg := &helper.Config{
		Evms: nil,
	}

	initSupportedStrategies(cfg)

	require.Len(t, supportedStrategies, 0, "expected 0 supported strategies when no EVMs are configured")
}

func Test_initSupportedStrategies_crossProductAndReset(t *testing.T) {
	// First call: 1 chain -> 2 strategies (2 protocols × 1 chain).
	cfg1 := &helper.Config{
		Evms: []helper.EvmConfig{
			{ChainSelector: 1111},
		},
	}

	initSupportedStrategies(cfg1)

	expectedAfterFirst := []Strategy{
		{
			ProtocolId:    AaveV3ProtocolId,
			ChainSelector: 1111,
		},
		{
			ProtocolId:    CompoundV3ProtocolId,
			ChainSelector: 1111,
		},
	}

	require.Equal(
		t,
		expectedAfterFirst,
		supportedStrategies,
		"after first initSupportedStrategies, unexpected supportedStrategies",
	)

	// Second call: 2 chains -> 4 strategies (2 protocols × 2 chains).
	// This also verifies that the slice is reset, not appended to.
	cfg2 := &helper.Config{
		Evms: []helper.EvmConfig{
			{ChainSelector: 1111},
			{ChainSelector: 2222},
		},
	}

	initSupportedStrategies(cfg2)

	expectedAfterSecond := []Strategy{
		{
			ProtocolId:    AaveV3ProtocolId,
			ChainSelector: 1111,
		},
		{
			ProtocolId:    CompoundV3ProtocolId,
			ChainSelector: 1111,
		},
		{
			ProtocolId:    AaveV3ProtocolId,
			ChainSelector: 2222,
		},
		{
			ProtocolId:    CompoundV3ProtocolId,
			ChainSelector: 2222,
		},
	}

	require.Equal(
		t,
		expectedAfterSecond,
		supportedStrategies,
		"after second initSupportedStrategies, unexpected supportedStrategies (should overwrite, not append)",
	)
}
