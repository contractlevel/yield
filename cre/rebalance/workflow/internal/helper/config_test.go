package helper

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func Test_FindEvmConfigByChainSelector_found(t *testing.T) {
	evms := []EvmConfig{
		{ChainName: "chain-a", ChainSelector: 1},
		{ChainName: "chain-b", ChainSelector: 2},
	}

	cfg, err := FindEvmConfigByChainSelector(evms, 2)
	require.NoError(t, err, "expected no error when selector exists")
	require.NotNil(t, cfg, "expected non-nil config when selector exists")
	require.Equal(t, "chain-b", cfg.ChainName, "unexpected ChainName")
}

func Test_FindEvmConfigByChainSelector_notFound(t *testing.T) {
	evms := []EvmConfig{
		{ChainName: "chain-a", ChainSelector: 1},
	}

	cfg, err := FindEvmConfigByChainSelector(evms, 999)
	require.Error(t, err, "expected error when selector does not exist")
	require.Nil(t, cfg, "expected nil config when selector does not exist")
	require.ErrorContains(t, err, "no evm config found for chainSelector 999")
}