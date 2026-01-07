package onchain

import (
	"reflect"
	"testing"

	"cre-rebalance/cre-rebalance-workflow/internal/helper"
)

func TestInitSupportedStrategies_NoEvms(t *testing.T) {
	cfg := &helper.Config{
		Evms: nil,
	}

	initSupportedStrategies(cfg)

	if got := len(supportedStrategies); got != 0 {
		t.Fatalf("expected 0 supported strategies, got %d", got)
	}
}

func TestInitSupportedStrategies_CrossProductAndReset(t *testing.T) {
	// First call: 1 chain -> 2 strategies (2 protocols × 1 chain)
	cfg1 := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainSelector: 1111,
			},
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

	if !reflect.DeepEqual(supportedStrategies, expectedAfterFirst) {
		t.Fatalf("after first initSupportedStrategies, got %+v, want %+v", supportedStrategies, expectedAfterFirst)
	}

	// Second call: 2 chains -> 4 strategies (2 protocols × 2 chains)
	// This also verifies that the slice is reset, not appended to.
	cfg2 := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainSelector: 1111,
			},
			{
				ChainSelector: 2222,
			},
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

	if !reflect.DeepEqual(supportedStrategies, expectedAfterSecond) {
		t.Fatalf("after second initSupportedStrategies, got %+v, want %+v", supportedStrategies, expectedAfterSecond)
	}
}
