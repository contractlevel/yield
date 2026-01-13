package onchain

import (
	"fmt"
	"math"
	"math/big"
	"testing"

	"rebalance/workflow/internal/helper"

	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/stretchr/testify/require"
)

// @review these tests need to be cleaned up

/*//////////////////////////////////////////////////////////////
                         TEST HELPERS
//////////////////////////////////////////////////////////////*/

func requireBigEqual(t *testing.T, want, got *big.Int) {
	t.Helper()
	require.Zero(t, want.Cmp(got), "big.Int mismatch: want=%s got=%s", want.String(), got.String())
}

func newConfigWithSingleEvm(chainSelector uint64) *helper.Config {
	return &helper.Config{
		Evms: []helper.EvmConfig{
			{ChainSelector: chainSelector},
		},
	}
}

// newConfigAndSupportedStrategies gives you a config plus a copy of the
// strategies that initSupportedStrategies() produced for it. This lets the
// tests reason about ordering and about a "current" strategy that is known
// to be in supportedStrategies.
func newConfigAndSupportedStrategies(t *testing.T) (*helper.Config, []Strategy) {
	t.Helper()

	cfg := newConfigWithSingleEvm(1111)

	// Populate the global supportedStrategies so tests can reason about them.
	initSupportedStrategies(cfg)
	require.NotEmpty(t, supportedStrategies, "supportedStrategies should not be empty for test config")

	stratsCopy := make([]Strategy, len(supportedStrategies))
	copy(stratsCopy, supportedStrategies)

	return cfg, stratsCopy
}

/*//////////////////////////////////////////////////////////////
              CALCULATE APY FOR STRATEGY (WITH DEPS)
//////////////////////////////////////////////////////////////*/

func Test_CalculateAPYForStrategy_UnsupportedProtocol(t *testing.T) {
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

func Test_CalculateAPYForStrategy_UsesDefaultDeps(t *testing.T) {
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

func Test_calculateAPYForStrategyWithDeps_RoutesToAave(t *testing.T) {
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

func Test_calculateAPYForStrategyWithDeps_RoutesToCompound(t *testing.T) {
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

func Test_calculateAPYForStrategyWithDeps_InvalidAPY_NaN(t *testing.T) {
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

func Test_calculateAPYForStrategyWithDeps_InvalidAPY_Inf(t *testing.T) {
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

func Test_calculateAPYForStrategyWithDeps_AaveErrorWrapped(t *testing.T) {
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

func Test_calculateAPYForStrategyWithDeps_CompoundErrorWrapped(t *testing.T) {
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

/*//////////////////////////////////////////////////////////////
                     GET OPTIMAL STRATEGY – WRAPPER
//////////////////////////////////////////////////////////////*/

func Test_GetOptimalStrategy_NoSupportedStrategies(t *testing.T) {
	cfg := &helper.Config{
		Evms: nil, // no chains configured
	}
	liquidityAdded := big.NewInt(1)
	current := Strategy{} // value doesn't matter here

	_, err := GetOptimalStrategy(cfg, nil, current, liquidityAdded)
	require.Error(t, err)
	require.ErrorContains(t, err, "no supported strategies configured")
}

func Test_GetOptimalStrategy_NilLiquidityAdded(t *testing.T) {
	cfg := newConfigWithSingleEvm(1111)

	current := Strategy{
		ProtocolId:    AaveV3ProtocolId,
		ChainSelector: cfg.Evms[0].ChainSelector,
	}

	_, err := GetOptimalStrategy(cfg, nil, current, nil)
	require.Error(t, err)
	require.ErrorContains(t, err, "liquidityAdded must not be nil")
}

func Test_GetOptimalStrategy_UsesDefaultPromiseDeps(t *testing.T) {
	cfg, strategies := newConfigAndSupportedStrategies(t)
	current := strategies[0]
	liquidityAdded := big.NewInt(100)

	original := defaultAPYPromiseDeps
	defer func() { defaultAPYPromiseDeps = original }()

	var (
		aaveCalls     int
		compoundCalls int
	)

	defaultAPYPromiseDeps = apyPromiseDeps{
		AaveV3GetAPYPromise: func(c *helper.Config, r cre.Runtime, liq *big.Int, chain uint64) cre.Promise[float64] {
			aaveCalls++
			return cre.PromiseFromResult(0.02, nil)
		},
		CompoundV3GetAPYPromise: func(c *helper.Config, r cre.Runtime, liq *big.Int, chain uint64) cre.Promise[float64] {
			compoundCalls++
			return cre.PromiseFromResult(0.01, nil)
		},
	}

	best, err := GetOptimalStrategy(cfg, nil, current, liquidityAdded)
	require.NoError(t, err)
	require.True(t, aaveCalls+compoundCalls > 0, "expected at least one APY promise to be called")

	// With APYs 0.02 (Aave) and 0.01 (Compound), the best protocol should be Aave.
	require.Equal(t, AaveV3ProtocolId, best.ProtocolId)
}

/*//////////////////////////////////////////////////////////////
      GET OPTIMAL STRATEGY – CORE PARALLEL LOGIC (WITH DEPS)
//////////////////////////////////////////////////////////////*/

func Test_getOptimalStrategyWithDeps_SelectsHighestAPYStrategy(t *testing.T) {
	cfg, strategies := newConfigAndSupportedStrategies(t)
	require.GreaterOrEqual(t, len(strategies), 1)

	current := strategies[0]           // ensures sameStrategy branch is hit at least once
	liquidityAdded := big.NewInt(1000) // non-zero to distinguish sameStrategy behaviour

	// Use strictly increasing APYs in the order strategies are visited.
	var callIndex int
	deps := apyPromiseDeps{
		AaveV3GetAPYPromise: func(c *helper.Config, r cre.Runtime, liq *big.Int, chain uint64) cre.Promise[float64] {
			callIndex++
			return cre.PromiseFromResult(float64(callIndex)*0.01, nil)
		},
		CompoundV3GetAPYPromise: func(c *helper.Config, r cre.Runtime, liq *big.Int, chain uint64) cre.Promise[float64] {
			callIndex++
			return cre.PromiseFromResult(float64(callIndex)*0.01, nil)
		},
	}

	best, err := getOptimalStrategyWithDeps(cfg, nil, current, liquidityAdded, deps)
	require.NoError(t, err)

	// APYs are strictly increasing in the order strategies are visited,
	// so the last strategy should be chosen as optimal.
	expectedBest := strategies[len(strategies)-1]
	require.Equal(t, expectedBest, best)
}

func Test_getOptimalStrategyWithDeps_TiesKeepFirstStrategy(t *testing.T) {
	cfg, strategies := newConfigAndSupportedStrategies(t)
	require.GreaterOrEqual(t, len(strategies), 1)

	current := strategies[0]
	liquidityAdded := big.NewInt(500)

	deps := apyPromiseDeps{
		AaveV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(0.10, nil)
		},
		CompoundV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(0.10, nil)
		},
	}

	best, err := getOptimalStrategyWithDeps(cfg, nil, current, liquidityAdded, deps)
	require.NoError(t, err)

	// With identical APYs, the first strategy in order should be retained.
	require.Equal(t, strategies[0], best)
}

func Test_getOptimalStrategyWithDeps_ZeroLiquidityForCurrentStrategy(t *testing.T) {
	cfg, strategies := newConfigAndSupportedStrategies(t)
	require.GreaterOrEqual(t, len(strategies), 1)

	current := strategies[0]
	liquidityAdded := big.NewInt(123)

	type seenCall struct {
		protocol [32]byte
		chain    uint64
		liq      *big.Int
	}

	var calls []seenCall

	makeRecorder := func(protocol [32]byte) func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
		return func(_ *helper.Config, _ cre.Runtime, liq *big.Int, chain uint64) cre.Promise[float64] {
			calls = append(calls, seenCall{
				protocol: protocol,
				chain:    chain,
				liq:      new(big.Int).Set(liq),
			})
			return cre.PromiseFromResult(0.01, nil)
		}
	}

	deps := apyPromiseDeps{
		AaveV3GetAPYPromise:     makeRecorder(AaveV3ProtocolId),
		CompoundV3GetAPYPromise: makeRecorder(CompoundV3ProtocolId),
	}

	_, err := getOptimalStrategyWithDeps(cfg, nil, current, liquidityAdded, deps)
	require.NoError(t, err)

	var currentCall *seenCall
	for i := range calls {
		if calls[i].chain == current.ChainSelector && calls[i].protocol == current.ProtocolId {
			currentCall = &calls[i]
			break
		}
	}
	require.NotNil(t, currentCall, "expected APY promise for current strategy to be called")
	requireBigEqual(t, big.NewInt(0), currentCall.liq)

	// If we have more than one strategy, at least one non-current strategy
	// should have received the full liquidityAdded.
	if len(strategies) > 1 {
		sawFull := false
		for _, c := range calls {
			if c.chain == current.ChainSelector && c.protocol == current.ProtocolId {
				continue
			}
			if c.liq.Cmp(liquidityAdded) == 0 {
				sawFull = true
				break
			}
		}
		require.True(t, sawFull, "expected at least one non-current strategy to see full liquidityAdded")
	}
}

/*//////////////////////////////////////////////////////////////
        GET OPTIMAL STRATEGY – ERROR / ZERO / INVALID APY
//////////////////////////////////////////////////////////////*/

func Test_getOptimalStrategyWithDeps_ErrorWhenAPYCalculationFails(t *testing.T) {
	cfg, strategies := newConfigAndSupportedStrategies(t)
	require.GreaterOrEqual(t, len(strategies), 1)

	current := strategies[0]
	liquidityAdded := big.NewInt(50)

	deps := apyPromiseDeps{
		AaveV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(0.0, fmt.Errorf("aave-apy-failed"))
		},
		CompoundV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(0.0, fmt.Errorf("compound-apy-failed"))
		},
	}

	_, err := getOptimalStrategyWithDeps(cfg, nil, current, liquidityAdded, deps)
	require.Error(t, err)
	require.ErrorContains(t, err, "calculate APY for strategy")
}

func Test_getOptimalStrategyWithDeps_ErrorWhenZeroAPY(t *testing.T) {
	cfg, strategies := newConfigAndSupportedStrategies(t)
	require.GreaterOrEqual(t, len(strategies), 1)

	current := strategies[0]
	liquidityAdded := big.NewInt(50)

	deps := apyPromiseDeps{
		AaveV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(0.0, nil)
		},
		CompoundV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(0.0, nil)
		},
	}

	_, err := getOptimalStrategyWithDeps(cfg, nil, current, liquidityAdded, deps)
	require.Error(t, err)
	require.ErrorContains(t, err, "0 APY returned for strategy")
}

func Test_getOptimalStrategyWithDeps_ErrorWhenInvalidAPY_NaN(t *testing.T) {
	cfg, strategies := newConfigAndSupportedStrategies(t)
	require.GreaterOrEqual(t, len(strategies), 1)

	current := strategies[0]
	liquidityAdded := big.NewInt(5)

	deps := apyPromiseDeps{
		AaveV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(math.NaN(), nil)
		},
		CompoundV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(0.01, nil)
		},
	}

	_, err := getOptimalStrategyWithDeps(cfg, nil, current, liquidityAdded, deps)
	require.Error(t, err)
	require.ErrorContains(t, err, "invalid APY value")
}

func Test_getOptimalStrategyWithDeps_ErrorWhenInvalidAPY_Inf(t *testing.T) {
	cfg, strategies := newConfigAndSupportedStrategies(t)
	require.GreaterOrEqual(t, len(strategies), 1)

	current := strategies[0]
	liquidityAdded := big.NewInt(5)

	deps := apyPromiseDeps{
		AaveV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(math.Inf(1), nil)
		},
		CompoundV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(0.01, nil)
		},
	}

	_, err := getOptimalStrategyWithDeps(cfg, nil, current, liquidityAdded, deps)
	require.Error(t, err)
	require.ErrorContains(t, err, "invalid APY value")
}
