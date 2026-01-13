package onchain

import (
	"fmt"
	"math"
	"math/big"
	"testing"

	"rebalance/workflow/internal/helper"

	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"
)

/*//////////////////////////////////////////////////////////////
                         TEST HELPERS
//////////////////////////////////////////////////////////////*/

func requireBigEqual(t *testing.T, want, got *big.Int) {
	t.Helper()
	require.Zero(t, want.Cmp(got), "big.Int mismatch: want=%s got=%s", want.String(), got.String())
}

// mockAPYPromiseDeps creates a mock dependency set for testing.
func mockAPYPromiseDeps(
	aaveAPY float64,
	compoundAPY float64,
	aaveErr error,
	compoundErr error,
) apyPromiseDeps {
	return apyPromiseDeps{
		AaveV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			if aaveErr != nil {
				return cre.PromiseFromResult(0.0, aaveErr)
			}
			return cre.PromiseFromResult(aaveAPY, nil)
		},
		CompoundV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			if compoundErr != nil {
				return cre.PromiseFromResult(0.0, compoundErr)
			}
			return cre.PromiseFromResult(compoundAPY, nil)
		},
	}
}

// setupConfigWithStrategies creates a config with the specified chain selectors.
func setupConfigWithStrategies(chainSelectors ...uint64) *helper.Config {
	evms := make([]helper.EvmConfig, len(chainSelectors))
	for i, cs := range chainSelectors {
		evms[i] = helper.EvmConfig{
			ChainSelector: cs,
		}
	}
	return &helper.Config{Evms: evms}
}

/*//////////////////////////////////////////////////////////////
              GET OPTIMAL STRATEGY - SUCCESS CASES
//////////////////////////////////////////////////////////////*/

func Test_getOptimalStrategyWithDeps_singleStrategy_success(t *testing.T) {
	cfg := setupConfigWithStrategies(1)
	runtime := testutils.NewRuntime(t, nil)
	currentStrategy := Strategy{ProtocolId: AaveV3ProtocolId, ChainSelector: 1}
	liquidityAdded := big.NewInt(1000)

	// Both strategies will be evaluated, so both need non-zero APYs
	deps := mockAPYPromiseDeps(0.05, 0.03, nil, nil)

	strategy, err := getOptimalStrategyWithDeps(cfg, runtime, currentStrategy, liquidityAdded, deps)
	require.NoError(t, err)
	require.Equal(t, AaveV3ProtocolId, strategy.ProtocolId)
	require.Equal(t, uint64(1), strategy.ChainSelector)
}

func Test_getOptimalStrategyWithDeps_multipleStrategies_picksHighestAPY(t *testing.T) {
	cfg := setupConfigWithStrategies(1)
	runtime := testutils.NewRuntime(t, nil)
	currentStrategy := Strategy{ProtocolId: AaveV3ProtocolId, ChainSelector: 1}
	liquidityAdded := big.NewInt(1000)

	// Aave has higher APY
	deps := mockAPYPromiseDeps(0.08, 0.05, nil, nil)

	strategy, err := getOptimalStrategyWithDeps(cfg, runtime, currentStrategy, liquidityAdded, deps)
	require.NoError(t, err)
	require.Equal(t, AaveV3ProtocolId, strategy.ProtocolId)
	require.Equal(t, uint64(1), strategy.ChainSelector)
}

func Test_getOptimalStrategyWithDeps_multipleStrategies_picksCompoundWhenHigher(t *testing.T) {
	cfg := setupConfigWithStrategies(1)
	runtime := testutils.NewRuntime(t, nil)
	currentStrategy := Strategy{ProtocolId: AaveV3ProtocolId, ChainSelector: 1}
	liquidityAdded := big.NewInt(1000)

	// Compound has higher APY
	deps := mockAPYPromiseDeps(0.05, 0.10, nil, nil)

	strategy, err := getOptimalStrategyWithDeps(cfg, runtime, currentStrategy, liquidityAdded, deps)
	require.NoError(t, err)
	require.Equal(t, CompoundV3ProtocolId, strategy.ProtocolId)
	require.Equal(t, uint64(1), strategy.ChainSelector)
}

func Test_getOptimalStrategyWithDeps_multipleChains_picksBestAcrossChains(t *testing.T) {
	cfg := setupConfigWithStrategies(1, 2)
	runtime := testutils.NewRuntime(t, nil)
	currentStrategy := Strategy{ProtocolId: AaveV3ProtocolId, ChainSelector: 1}
	liquidityAdded := big.NewInt(1000)

	// Mock deps that return different APYs based on chain selector
	// Note: currentStrategy matches AaveV3 on chain 1, so that will use 0 liquidity
	deps := apyPromiseDeps{
		AaveV3GetAPYPromise: func(_ *helper.Config, _ cre.Runtime, liq *big.Int, chain uint64) cre.Promise[float64] {
			var apy float64
			if chain == 1 {
				// Current strategy matches this, so liquidity will be 0
				requireBigEqual(t, big.NewInt(0), liq)
				apy = 0.05
			} else {
				// Not current strategy, so uses full liquidityAdded
				requireBigEqual(t, liquidityAdded, liq)
				apy = 0.07 // Chain 2 has higher APY
			}
			return cre.PromiseFromResult(apy, nil)
		},
		CompoundV3GetAPYPromise: func(_ *helper.Config, _ cre.Runtime, liq *big.Int, chain uint64) cre.Promise[float64] {
			// Compound is not the current strategy, so always uses full liquidity
			requireBigEqual(t, liquidityAdded, liq)
			var apy float64
			if chain == 1 {
				apy = 0.06
			} else {
				apy = 0.04
			}
			return cre.PromiseFromResult(apy, nil)
		},
	}

	strategy, err := getOptimalStrategyWithDeps(cfg, runtime, currentStrategy, liquidityAdded, deps)
	require.NoError(t, err)
	require.Equal(t, AaveV3ProtocolId, strategy.ProtocolId)
	require.Equal(t, uint64(2), strategy.ChainSelector) // Chain 2 has highest APY (0.07)
}

func Test_getOptimalStrategyWithDeps_currentStrategyMatches_usesZeroLiquidity(t *testing.T) {
	cfg := setupConfigWithStrategies(1)
	runtime := testutils.NewRuntime(t, nil)
	currentStrategy := Strategy{ProtocolId: AaveV3ProtocolId, ChainSelector: 1}
	liquidityAdded := big.NewInt(1000)

	var gotLiquidity *big.Int
	deps := apyPromiseDeps{
		AaveV3GetAPYPromise: func(_ *helper.Config, _ cre.Runtime, liq *big.Int, chain uint64) cre.Promise[float64] {
			gotLiquidity = new(big.Int).Set(liq)
			return cre.PromiseFromResult(0.05, nil)
		},
		CompoundV3GetAPYPromise: func(_ *helper.Config, _ cre.Runtime, liq *big.Int, chain uint64) cre.Promise[float64] {
			// Should use full liquidityAdded for non-current strategy
			requireBigEqual(t, liquidityAdded, liq)
			return cre.PromiseFromResult(0.03, nil)
		},
	}

	strategy, err := getOptimalStrategyWithDeps(cfg, runtime, currentStrategy, liquidityAdded, deps)
	require.NoError(t, err)
	require.Equal(t, AaveV3ProtocolId, strategy.ProtocolId)
	requireBigEqual(t, big.NewInt(0), gotLiquidity)
}

/*//////////////////////////////////////////////////////////////
              GET OPTIMAL STRATEGY - ERROR CASES
//////////////////////////////////////////////////////////////*/

func Test_getOptimalStrategyWithDeps_errorWhen_noSupportedStrategies(t *testing.T) {
	cfg := &helper.Config{Evms: []helper.EvmConfig{}}
	runtime := testutils.NewRuntime(t, nil)
	currentStrategy := Strategy{ProtocolId: AaveV3ProtocolId, ChainSelector: 1}
	liquidityAdded := big.NewInt(1000)

	deps := mockAPYPromiseDeps(0.05, 0.0, nil, nil)

	strategy, err := getOptimalStrategyWithDeps(cfg, runtime, currentStrategy, liquidityAdded, deps)
	require.Error(t, err)
	require.ErrorContains(t, err, "no supported strategies configured")
	require.Equal(t, Strategy{}, strategy)
}

func Test_getOptimalStrategyWithDeps_errorWhen_nilLiquidityAdded(t *testing.T) {
	cfg := setupConfigWithStrategies(1)
	runtime := testutils.NewRuntime(t, nil)
	currentStrategy := Strategy{ProtocolId: AaveV3ProtocolId, ChainSelector: 1}

	deps := mockAPYPromiseDeps(0.05, 0.0, nil, nil)

	strategy, err := getOptimalStrategyWithDeps(cfg, runtime, currentStrategy, nil, deps)
	require.Error(t, err)
	require.ErrorContains(t, err, "liquidityAdded must not be nil")
	require.Equal(t, Strategy{}, strategy)
}

func Test_getOptimalStrategyWithDeps_errorWhen_unsupportedProtocol(t *testing.T) {
	cfg := setupConfigWithStrategies(1)
	runtime := testutils.NewRuntime(t, nil)
	liquidityAdded := big.NewInt(1000)

	// Create a config that somehow results in an unsupported protocol
	// This is tricky since initSupportedStrategies only creates AaveV3 and CompoundV3
	// So we'll test the getAPYPromiseFromStrategy function directly instead
	var unsupportedProtocolId [32]byte
	copy(unsupportedProtocolId[:], []byte("unsupported-protocol-123456789012"))
	unsupportedStrategy := Strategy{
		ProtocolId:    unsupportedProtocolId,
		ChainSelector: 1,
	}

	deps := mockAPYPromiseDeps(0.05, 0.0, nil, nil)

	promise := getAPYPromiseFromStrategy(cfg, runtime, unsupportedStrategy, liquidityAdded, deps)
	require.NotNil(t, promise)
	
	_, err := promise.Await()
	require.Error(t, err)
	require.ErrorContains(t, err, "unsupported protocolId")
}

func Test_getOptimalStrategyWithDeps_errorWhen_aavePromiseAwaitFails(t *testing.T) {
	cfg := setupConfigWithStrategies(1)
	runtime := testutils.NewRuntime(t, nil)
	currentStrategy := Strategy{ProtocolId: AaveV3ProtocolId, ChainSelector: 1}
	liquidityAdded := big.NewInt(1000)

	expectedErr := fmt.Errorf("aave promise creation failed")
	deps := mockAPYPromiseDeps(0.05, 0.0, expectedErr, nil)

	strategy, err := getOptimalStrategyWithDeps(cfg, runtime, currentStrategy, liquidityAdded, deps)
	require.Error(t, err)
	require.ErrorContains(t, err, "calculate APY for strategy")
	require.ErrorContains(t, err, "aave promise creation failed")
	require.Equal(t, Strategy{}, strategy)
}

func Test_getOptimalStrategyWithDeps_errorWhen_compoundPromiseAwaitFails(t *testing.T) {
	cfg := setupConfigWithStrategies(1)
	runtime := testutils.NewRuntime(t, nil)
	currentStrategy := Strategy{ProtocolId: AaveV3ProtocolId, ChainSelector: 1}
	liquidityAdded := big.NewInt(1000)

	expectedErr := fmt.Errorf("compound promise creation failed")
	deps := mockAPYPromiseDeps(0.05, 0.0, nil, expectedErr)

	strategy, err := getOptimalStrategyWithDeps(cfg, runtime, currentStrategy, liquidityAdded, deps)
	require.Error(t, err)
	require.ErrorContains(t, err, "calculate APY for strategy")
	require.ErrorContains(t, err, "compound promise creation failed")
	require.Equal(t, Strategy{}, strategy)
}

func Test_getOptimalStrategyWithDeps_errorWhen_apyPromiseAwaitFails(t *testing.T) {
	cfg := setupConfigWithStrategies(1)
	runtime := testutils.NewRuntime(t, nil)
	currentStrategy := Strategy{ProtocolId: AaveV3ProtocolId, ChainSelector: 1}
	liquidityAdded := big.NewInt(1000)

	expectedErr := fmt.Errorf("apy calculation failed")
	deps := apyPromiseDeps{
		AaveV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(0.0, expectedErr)
		},
		CompoundV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(0.0, nil)
		},
	}

	strategy, err := getOptimalStrategyWithDeps(cfg, runtime, currentStrategy, liquidityAdded, deps)
	require.Error(t, err)
	require.ErrorContains(t, err, "calculate APY for strategy")
	require.ErrorContains(t, err, "apy calculation failed")
	require.Equal(t, Strategy{}, strategy)
}

func Test_getOptimalStrategyWithDeps_errorWhen_apyIsZero(t *testing.T) {
	cfg := setupConfigWithStrategies(1)
	runtime := testutils.NewRuntime(t, nil)
	currentStrategy := Strategy{ProtocolId: AaveV3ProtocolId, ChainSelector: 1}
	liquidityAdded := big.NewInt(1000)

	deps := mockAPYPromiseDeps(0.0, 0.0, nil, nil)

	strategy, err := getOptimalStrategyWithDeps(cfg, runtime, currentStrategy, liquidityAdded, deps)
	require.Error(t, err)
	require.ErrorContains(t, err, "0 APY returned for strategy")
	require.Equal(t, Strategy{}, strategy)
}

func Test_getOptimalStrategyWithDeps_errorWhen_apyIsNaN(t *testing.T) {
	cfg := setupConfigWithStrategies(1)
	runtime := testutils.NewRuntime(t, nil)
	currentStrategy := Strategy{ProtocolId: AaveV3ProtocolId, ChainSelector: 1}
	liquidityAdded := big.NewInt(1000)

	deps := apyPromiseDeps{
		AaveV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(math.NaN(), nil)
		},
		CompoundV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(0.0, nil)
		},
	}

	strategy, err := getOptimalStrategyWithDeps(cfg, runtime, currentStrategy, liquidityAdded, deps)
	require.Error(t, err)
	require.ErrorContains(t, err, "invalid APY value (NaN/Inf)")
	require.Equal(t, Strategy{}, strategy)
}

func Test_getOptimalStrategyWithDeps_errorWhen_apyIsInf(t *testing.T) {
	cfg := setupConfigWithStrategies(1)
	runtime := testutils.NewRuntime(t, nil)
	currentStrategy := Strategy{ProtocolId: AaveV3ProtocolId, ChainSelector: 1}
	liquidityAdded := big.NewInt(1000)

	deps := apyPromiseDeps{
		AaveV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(math.Inf(1), nil)
		},
		CompoundV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(0.0, nil)
		},
	}

	strategy, err := getOptimalStrategyWithDeps(cfg, runtime, currentStrategy, liquidityAdded, deps)
	require.Error(t, err)
	require.ErrorContains(t, err, "invalid APY value (NaN/Inf)")
	require.Equal(t, Strategy{}, strategy)
}

/*//////////////////////////////////////////////////////////////
              GET APY PROMISE FROM STRATEGY
//////////////////////////////////////////////////////////////*/

func Test_getAPYPromiseFromStrategy_aaveV3_success(t *testing.T) {
	cfg := &helper.Config{}
	runtime := testutils.NewRuntime(t, nil)
	strategy := Strategy{ProtocolId: AaveV3ProtocolId, ChainSelector: 1}
	liquidity := big.NewInt(1000)

	var called bool
	deps := apyPromiseDeps{
		AaveV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			called = true
			return cre.PromiseFromResult(0.05, nil)
		},
		CompoundV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(0.0, fmt.Errorf("should not be called"))
		},
	}

	promise := getAPYPromiseFromStrategy(cfg, runtime, strategy, liquidity, deps)
	require.NotNil(t, promise)
	require.True(t, called)

	apy, err := promise.Await()
	require.NoError(t, err)
	require.Equal(t, 0.05, apy)
}

func Test_getAPYPromiseFromStrategy_compoundV3_success(t *testing.T) {
	cfg := &helper.Config{}
	runtime := testutils.NewRuntime(t, nil)
	strategy := Strategy{ProtocolId: CompoundV3ProtocolId, ChainSelector: 1}
	liquidity := big.NewInt(1000)

	var called bool
	deps := apyPromiseDeps{
		AaveV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(0.0, fmt.Errorf("should not be called"))
		},
		CompoundV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			called = true
			return cre.PromiseFromResult(0.10, nil)
		},
	}

	promise := getAPYPromiseFromStrategy(cfg, runtime, strategy, liquidity, deps)
	require.NotNil(t, promise)
	require.True(t, called)

	apy, err := promise.Await()
	require.NoError(t, err)
	require.Equal(t, 0.10, apy)
}

func Test_getAPYPromiseFromStrategy_aaveV3Error_propagatesError(t *testing.T) {
	cfg := &helper.Config{}
	runtime := testutils.NewRuntime(t, nil)
	strategy := Strategy{ProtocolId: AaveV3ProtocolId, ChainSelector: 1}
	liquidity := big.NewInt(1000)

	expectedErr := fmt.Errorf("aave error")
	deps := apyPromiseDeps{
		AaveV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(0.0, expectedErr)
		},
		CompoundV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(0.0, fmt.Errorf("should not be called"))
		},
	}

	promise := getAPYPromiseFromStrategy(cfg, runtime, strategy, liquidity, deps)
	require.NotNil(t, promise)
	
	_, err := promise.Await()
	require.Error(t, err)
	require.ErrorContains(t, err, "aave error")
}

func Test_getAPYPromiseFromStrategy_compoundV3Error_propagatesError(t *testing.T) {
	cfg := &helper.Config{}
	runtime := testutils.NewRuntime(t, nil)
	strategy := Strategy{ProtocolId: CompoundV3ProtocolId, ChainSelector: 1}
	liquidity := big.NewInt(1000)

	expectedErr := fmt.Errorf("compound error")
	deps := apyPromiseDeps{
		AaveV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(0.0, fmt.Errorf("should not be called"))
		},
		CompoundV3GetAPYPromise: func(*helper.Config, cre.Runtime, *big.Int, uint64) cre.Promise[float64] {
			return cre.PromiseFromResult(0.0, expectedErr)
		},
	}

	promise := getAPYPromiseFromStrategy(cfg, runtime, strategy, liquidity, deps)
	require.NotNil(t, promise)
	
	_, err := promise.Await()
	require.Error(t, err)
	require.ErrorContains(t, err, "compound error")
}

/*//////////////////////////////////////////////////////////////
              GET OPTIMAL STRATEGY - USES DEFAULT DEPS
//////////////////////////////////////////////////////////////*/

func Test_GetOptimalStrategy_usesDefaultDeps(t *testing.T) {
	// Override the package-level defaultAPYPromiseDeps to avoid calling real protocol code.
	original := defaultAPYPromiseDeps
	defer func() { defaultAPYPromiseDeps = original }()

	cfg := setupConfigWithStrategies(1)
	runtime := testutils.NewRuntime(t, nil)
	currentStrategy := Strategy{ProtocolId: AaveV3ProtocolId, ChainSelector: 1}
	liquidityAdded := big.NewInt(1000)

	var (
		calledAave     bool
		calledCompound bool
		gotLiq         *big.Int
		gotChain       uint64
	)

	defaultAPYPromiseDeps = apyPromiseDeps{
		AaveV3GetAPYPromise: func(c *helper.Config, r cre.Runtime, liq *big.Int, chain uint64) cre.Promise[float64] {
			calledAave = true
			require.Same(t, cfg, c)
			require.Equal(t, currentStrategy.ChainSelector, chain)
			// Current strategy matches AaveV3, so liquidity should be 0
			requireBigEqual(t, big.NewInt(0), liq)
			return cre.PromiseFromResult(0.08, nil)
		},
		CompoundV3GetAPYPromise: func(c *helper.Config, r cre.Runtime, liq *big.Int, chain uint64) cre.Promise[float64] {
			calledCompound = true
			gotLiq = new(big.Int).Set(liq)
			gotChain = chain
			// Compound is not the current strategy, so should use full liquidity
			requireBigEqual(t, liquidityAdded, liq)
			return cre.PromiseFromResult(0.05, nil)
		},
	}

	strategy, err := GetOptimalStrategy(cfg, runtime, currentStrategy, liquidityAdded)
	require.NoError(t, err)
	require.True(t, calledAave, "AaveV3GetAPYPromise should be called")
	require.True(t, calledCompound, "CompoundV3GetAPYPromise should be called")
	require.Equal(t, AaveV3ProtocolId, strategy.ProtocolId, "should pick AaveV3 with higher APY")
	require.Equal(t, uint64(1), strategy.ChainSelector)
	requireBigEqual(t, liquidityAdded, gotLiq)
	require.Equal(t, uint64(1), gotChain)
}
