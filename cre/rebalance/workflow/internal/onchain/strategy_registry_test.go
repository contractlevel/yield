package onchain

import (
	"testing"

	"rebalance/workflow/internal/helper"

	"github.com/stretchr/testify/require"
)

// resetState resets the package-level state for testing.
// This allows tests to run independently.
func resetState() {
	initialized = false
	supportedStrategies = nil
}

func Test_InitSupportedStrategies_noEvms(t *testing.T) {
	resetState()
	cfg := &helper.Config{
		Evms: nil,
	}

	err := InitSupportedStrategies(cfg)
	require.NoError(t, err, "expected no error when no EVMs are configured")
	require.Len(t, supportedStrategies, 0, "expected 0 supported strategies when no EVMs are configured")
}

func Test_InitSupportedStrategies_emptyEvms(t *testing.T) {
	resetState()
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{},
	}

	err := InitSupportedStrategies(cfg)
	require.NoError(t, err, "expected no error when EVMs slice is empty")
	require.Len(t, supportedStrategies, 0, "expected 0 supported strategies when EVMs slice is empty")
}

func Test_InitSupportedStrategies_noAddresses(t *testing.T) {
	resetState()
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{ChainSelector: 1111},
		},
	}

	err := InitSupportedStrategies(cfg)
	require.NoError(t, err, "expected no error when addresses are not set")
	require.Len(t, supportedStrategies, 0, "expected 0 supported strategies when no addresses are configured")
}

func Test_InitSupportedStrategies_onlyAaveV3(t *testing.T) {
	resetState()
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainSelector:                        1111,
				AaveV3PoolAddressesProviderAddress: "0xaave",
			},
		},
	}

	err := InitSupportedStrategies(cfg)
	require.NoError(t, err)
	require.Len(t, supportedStrategies, 1, "expected 1 strategy when only AaveV3 is configured")
	require.Equal(t, AaveV3ProtocolId, supportedStrategies[0].ProtocolId)
	require.Equal(t, uint64(1111), supportedStrategies[0].ChainSelector)
}

func Test_InitSupportedStrategies_onlyCompoundV3(t *testing.T) {
	resetState()
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainSelector:                 2222,
				CompoundV3CometUSDCAddress: "0xcompound",
			},
		},
	}

	err := InitSupportedStrategies(cfg)
	require.NoError(t, err)
	require.Len(t, supportedStrategies, 1, "expected 1 strategy when only CompoundV3 is configured")
	require.Equal(t, CompoundV3ProtocolId, supportedStrategies[0].ProtocolId)
	require.Equal(t, uint64(2222), supportedStrategies[0].ChainSelector)
}

func Test_InitSupportedStrategies_bothProtocols(t *testing.T) {
	resetState()
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainSelector:                        1111,
				AaveV3PoolAddressesProviderAddress: "0xaave",
				CompoundV3CometUSDCAddress:         "0xcompound",
			},
		},
	}

	err := InitSupportedStrategies(cfg)
	require.NoError(t, err)
	require.Len(t, supportedStrategies, 2, "expected 2 strategies when both protocols are configured")

	expected := []Strategy{
		{
			ProtocolId:    AaveV3ProtocolId,
			ChainSelector: 1111,
		},
		{
			ProtocolId:    CompoundV3ProtocolId,
			ChainSelector: 1111,
		},
	}
	require.Equal(t, expected, supportedStrategies)
}

func Test_InitSupportedStrategies_multipleChains(t *testing.T) {
	resetState()
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainSelector:                        1111,
				AaveV3PoolAddressesProviderAddress: "0xaave1",
				CompoundV3CometUSDCAddress:         "0xcompound1",
			},
			{
				ChainSelector:                        2222,
				AaveV3PoolAddressesProviderAddress: "0xaave2",
				CompoundV3CometUSDCAddress:         "0xcompound2",
			},
		},
	}

	err := InitSupportedStrategies(cfg)
	require.NoError(t, err)
	require.Len(t, supportedStrategies, 4, "expected 4 strategies (2 protocols × 2 chains)")

	expected := []Strategy{
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
	require.Equal(t, expected, supportedStrategies)
}

func Test_InitSupportedStrategies_mixedConfigurations(t *testing.T) {
	resetState()
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainSelector:                        1111,
				AaveV3PoolAddressesProviderAddress: "0xaave",
				// No CompoundV3
			},
			{
				ChainSelector:                 2222,
				CompoundV3CometUSDCAddress: "0xcompound",
				// No AaveV3
			},
			{
				ChainSelector: 3333,
				// No protocols
			},
			{
				ChainSelector:                        4444,
				AaveV3PoolAddressesProviderAddress: "0xaave4",
				CompoundV3CometUSDCAddress:         "0xcompound4",
			},
		},
	}

	err := InitSupportedStrategies(cfg)
	require.NoError(t, err)
	require.Len(t, supportedStrategies, 4, "expected 4 strategies (1 + 1 + 0 + 2)")

	expected := []Strategy{
		{
			ProtocolId:    AaveV3ProtocolId,
			ChainSelector: 1111,
		},
		{
			ProtocolId:    CompoundV3ProtocolId,
			ChainSelector: 2222,
		},
		{
			ProtocolId:    AaveV3ProtocolId,
			ChainSelector: 4444,
		},
		{
			ProtocolId:    CompoundV3ProtocolId,
			ChainSelector: 4444,
		},
	}
	require.Equal(t, expected, supportedStrategies)
}

func Test_InitSupportedStrategies_doubleCallError(t *testing.T) {
	resetState()
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{
				ChainSelector:                        1111,
				AaveV3PoolAddressesProviderAddress: "0xaave",
			},
		},
	}

	err := InitSupportedStrategies(cfg)
	require.NoError(t, err, "first call should succeed")
	require.Len(t, supportedStrategies, 1, "first call should initialize strategies")

	// Second call should fail
	err = InitSupportedStrategies(cfg)
	require.Error(t, err, "second call should return an error")
	require.ErrorContains(t, err, "InitSupportedStrategies called more than once")
	require.Len(t, supportedStrategies, 1, "second call should not modify strategies")
}
