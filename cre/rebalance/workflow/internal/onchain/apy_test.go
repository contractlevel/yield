package onchain

import (
	"testing"
	"math/big"
	"math"
	"fmt"

	"rebalance/workflow/internal/helper"

	"github.com/stretchr/testify/require"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

/*//////////////////////////////////////////////////////////////
              CALCULATE APY FOR STRATEGY (WITH DEPS)
//////////////////////////////////////////////////////////////*/

func Test_CalculateAPYForStrategy_errorWhen_unsupportedProtocol(t *testing.T) {
	cfg := &helper.Config{}
	liquidityAdded := big.NewInt(0)

	// ProtocolId that is neither AaveV3ProtocolId nor CompoundV3ProtocolId.
	strategy := Strategy{
		ProtocolId:    [32]byte{0xFF},
		ChainSelector: 123,
	}

	apy, err := CalculateAPYForStrategy(cfg, nil, strategy, liquidityAdded)
	require.Error(t, err)
	require.ErrorContains(t, err, "unsupported protocolId")
	require.Equal(t, 0.0, apy)
}

func Test_CalculateAPYForStrategy_usesDefaultDeps(t *testing.T) {
	// Override the package-level defaultAPYDeps to avoid calling real protocol code.
	original := defaultAPYDeps
	defer func() { defaultAPYDeps = original }()

	cfg := &helper.Config{}
	liquidity := big.NewInt(42)

	strategy := Strategy{
		ProtocolId:    AaveV3ProtocolId,
		ChainSelector: 1,
	}

	var (
		calledAave     bool
		calledCompound bool
	)

	defaultAPYDeps = apyDeps{
		AaveV3GetAPY: func(c *helper.Config, r cre.Runtime, liq *big.Int, chain uint64) (float64, error) {
			calledAave = true
			require.Same(t, cfg, c)
			require.Equal(t, strategy.ChainSelector, chain)
			requireBigEqual(t, liquidity, liq)
			return 0.77, nil
		},
		CompoundV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			calledCompound = true
			return 0.0, nil
		},
	}

	apy, err := CalculateAPYForStrategy(cfg, nil, strategy, liquidity)
	require.NoError(t, err)
	require.True(t, calledAave)
	require.False(t, calledCompound)
	require.Equal(t, 0.77, apy)
}

func Test_calculateAPYForStrategyWithDeps_aaveV3_success(t *testing.T) {
	cfg := &helper.Config{}
	liquidity := big.NewInt(42)

	strategy := Strategy{
		ProtocolId:    AaveV3ProtocolId,
		ChainSelector: 111,
	}

	var (
		aaveCalled     bool
		compoundCalled bool
		gotLiq         *big.Int
		gotChain       uint64
	)

	deps := apyDeps{
		AaveV3GetAPY: func(c *helper.Config, r cre.Runtime, liq *big.Int, chain uint64) (float64, error) {
			aaveCalled = true
			gotLiq = new(big.Int).Set(liq)
			gotChain = chain
			return 0.123, nil
		},
		CompoundV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			compoundCalled = true
			return 0.0, nil
		},
	}

	apy, err := calculateAPYForStrategyWithDeps(cfg, nil, strategy, liquidity, deps)
	require.NoError(t, err)

	require.True(t, aaveCalled, "AaveV3GetAPY should be called")
	require.False(t, compoundCalled, "CompoundV3GetAPY should not be called")
	require.Equal(t, 0.123, apy)
	require.Equal(t, strategy.ChainSelector, gotChain)
	requireBigEqual(t, liquidity, gotLiq)
}

func Test_calculateAPYForStrategyWithDeps_compoundV3_success(t *testing.T) {
	cfg := &helper.Config{}
	liquidity := big.NewInt(99)

	strategy := Strategy{
		ProtocolId:    CompoundV3ProtocolId,
		ChainSelector: 222,
	}

	var (
		aaveCalled     bool
		compoundCalled bool
		gotLiq         *big.Int
		gotChain       uint64
	)

	deps := apyDeps{
		AaveV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			aaveCalled = true
			return 0.0, nil
		},
		CompoundV3GetAPY: func(c *helper.Config, r cre.Runtime, liq *big.Int, chain uint64) (float64, error) {
			compoundCalled = true
			gotLiq = new(big.Int).Set(liq)
			gotChain = chain
			return 0.456, nil
		},
	}

	apy, err := calculateAPYForStrategyWithDeps(cfg, nil, strategy, liquidity, deps)
	require.NoError(t, err)

	require.True(t, compoundCalled, "CompoundV3GetAPY should be called")
	require.False(t, aaveCalled, "AaveV3GetAPY should not be called")
	require.Equal(t, 0.456, apy)
	require.Equal(t, strategy.ChainSelector, gotChain)
	requireBigEqual(t, liquidity, gotLiq)
}

func Test_calculateAPYForStrategyWithDeps_errorWhen_InvalidAPY_NaN(t *testing.T) {
	cfg := &helper.Config{}
	liquidity := big.NewInt(1)

	strategy := Strategy{
		ProtocolId:    AaveV3ProtocolId,
		ChainSelector: 1,
	}

	deps := apyDeps{
		AaveV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			return math.NaN(), nil
		},
		CompoundV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			return 0.0, nil
		},
	}

	apy, err := calculateAPYForStrategyWithDeps(cfg, nil, strategy, liquidity, deps)
	require.Error(t, err)
	require.ErrorContains(t, err, "invalid APY value")
	require.Equal(t, 0.0, apy)
}

func Test_calculateAPYForStrategyWithDeps_errorWhen_InvalidAPY_Inf(t *testing.T) {
	cfg := &helper.Config{}
	liquidity := big.NewInt(1)

	strategy := Strategy{
		ProtocolId:    CompoundV3ProtocolId,
		ChainSelector: 1,
	}

	deps := apyDeps{
		AaveV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			return 0.0, nil
		},
		CompoundV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			return math.Inf(1), nil
		},
	}

	apy, err := calculateAPYForStrategyWithDeps(cfg, nil, strategy, liquidity, deps)
	require.Error(t, err)
	require.ErrorContains(t, err, "invalid APY value")
	require.Equal(t, 0.0, apy)
}

/*//////////////////////////////////////////////////////////////
         CALCULATE APY FOR STRATEGY – ERROR WRAPPERS
//////////////////////////////////////////////////////////////*/

func Test_calculateAPYForStrategyWithDeps_errorWhen_aaveV3Error(t *testing.T) {
	cfg := &helper.Config{}
	liquidity := big.NewInt(10)

	strategy := Strategy{
		ProtocolId:    AaveV3ProtocolId,
		ChainSelector: 1,
	}

	deps := apyDeps{
		AaveV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			return 0.0, fmt.Errorf("aave-apy-failed")
		},
		CompoundV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			return 0.0, nil
		},
	}

	apy, err := calculateAPYForStrategyWithDeps(cfg, nil, strategy, liquidity, deps)
	require.Error(t, err)
	require.ErrorContains(t, err, "getting APY from AaveV3: aave-apy-failed")
	require.Equal(t, 0.0, apy)
}

func Test_calculateAPYForStrategyWithDeps_errorWhen_compoundV3Error(t *testing.T) {
	cfg := &helper.Config{}
	liquidity := big.NewInt(10)

	strategy := Strategy{
		ProtocolId:    CompoundV3ProtocolId,
		ChainSelector: 1,
	}

	deps := apyDeps{
		AaveV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			return 0.0, nil
		},
		CompoundV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			return 0.0, fmt.Errorf("compound-apy-failed")
		},
	}

	apy, err := calculateAPYForStrategyWithDeps(cfg, nil, strategy, liquidity, deps)
	require.Error(t, err)
	require.ErrorContains(t, err, "getting APY from CompoundV3: compound-apy-failed")
	require.Equal(t, 0.0, apy)
}
