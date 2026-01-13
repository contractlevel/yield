package aaveV3

import (
	"errors"
	"math"
	"math/big"
	"testing"

	"rebalance/contracts/evm/src/generated/default_reserve_interest_rate_strategy_v2"

	"github.com/ethereum/go-ethereum/common"
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

/*//////////////////////////////////////////////////////////////
              CONVERT APR TO APY (PURE FUNCTION - DIRECT TEST)
//////////////////////////////////////////////////////////////*/

func Test_convertAPRToAPY_nilInput(t *testing.T) {
	// Test with nil aprRat - should return error, not panic
	apy, err := convertAPRToAPY(nil)
	require.Error(t, err)
	require.ErrorContains(t, err, "aprRat cannot be nil")
	require.Equal(t, 0.0, apy)
}

func Test_convertAPRToAPY_zeroAPR(t *testing.T) {
	aprRat := big.NewRat(0, 1)
	apy, err := convertAPRToAPY(aprRat)
	require.NoError(t, err)
	require.Equal(t, 0.0, apy)
}

func Test_convertAPRToAPY_typicalAPR(t *testing.T) {
	// Test 5% APR = 0.05
	// Expected APY ≈ 0.0512 (5.12%) due to compounding
	aprRat := big.NewRat(5, 100) // 5% = 0.05
	apy, err := convertAPRToAPY(aprRat)
	require.NoError(t, err)
	require.Greater(t, apy, 0.05) // APY should be slightly higher than APR due to compounding
	require.Less(t, apy, 0.06)
	require.InDelta(t, 0.0512, apy, 0.001) // Approximately 5.12%
}

func Test_convertAPRToAPY_highAPR(t *testing.T) {
	// Test 10% APR
	aprRat := big.NewRat(10, 100) // 10% = 0.10
	apy, err := convertAPRToAPY(aprRat)
	require.NoError(t, err)
	require.Greater(t, apy, 0.10)
	require.Less(t, apy, 0.11)
	require.InDelta(t, 0.1051, apy, 0.001) // Approximately 10.51%
}

func Test_convertAPRToAPY_veryHighAPR(t *testing.T) {
	// Test 100% APR (should still work)
	aprRat := big.NewRat(100, 100) // 100% = 1.0
	apy, err := convertAPRToAPY(aprRat)
	require.NoError(t, err)
	require.Greater(t, apy, 1.0)
	require.Less(t, apy, 2.0)
}

func Test_convertAPRToAPY_exceeds1000Percent(t *testing.T) {
	// Test > 1000% APR (should return error? For stables that's infeasible but for other assets(absolute casino shitcoins) in the future? we'll see)
	aprRat := big.NewRat(1100, 100) // 1100% = 11.0
	apy, err := convertAPRToAPY(aprRat)
	require.Error(t, err)
	require.ErrorContains(t, err, "APR exceeds 1000%")
	require.Equal(t, 0.0, apy)
}

func Test_convertAPRToAPY_smallAPR(t *testing.T) {
	// Test 0.1% APR
	aprRat := big.NewRat(1, 1000) // 0.1% = 0.001
	apy, err := convertAPRToAPY(aprRat)
	require.NoError(t, err)
	require.Greater(t, apy, 0.001)
	require.Less(t, apy, 0.002)
}

func Test_convertAPRToAPY_maxValidAPR(t *testing.T) {
	// Test with maximum valid APR (just under 1000% limit)
	// Using a value with high precision just under the boundary
	maxValidAPR := big.NewRat(999999, 100000) // 9.99999 = 999.999%
	apy, err := convertAPRToAPY(maxValidAPR)

	require.NoError(t, err)
	// Verify it's a valid number (not NaN or Inf)
	require.False(t, math.IsNaN(apy), "APY should not be NaN")
	require.False(t, math.IsInf(apy, 0), "APY should not be Inf")
	require.GreaterOrEqual(t, apy, 0.0, "APY should be >= 0")
	// With 999.999% APR, the APY will be extremely high due to compounding
	require.Greater(t, apy, 9.0)
}

func Test_convertAPRToAPY_veryLargeButValidAPR(t *testing.T) {
	// Test with maximum valid APR (just under 1000%)
	// 999% APR = 9.99
	aprRat := big.NewRat(999, 100) // 9.99 = 999%
	apy, err := convertAPRToAPY(aprRat)
	require.NoError(t, err)
	// With 999% APR, the APY will be extremely high due to compounding
	require.Greater(t, apy, 9.0)
	// Verify it's a valid number (not NaN or Inf)
	require.False(t, apy != apy, "APY should not be NaN")
	require.GreaterOrEqual(t, apy, 0.0, "APY should be >= 0")
}

/*//////////////////////////////////////////////////////////////
         CALCULATE APY FROM CONTRACT (WITH MOCKS)
//////////////////////////////////////////////////////////////*/

type mockStrategyContract struct {
	calculateInterestRatesFunc func(cre.Runtime, default_reserve_interest_rate_strategy_v2.CalculateInterestRatesInput, *big.Int) cre.Promise[default_reserve_interest_rate_strategy_v2.CalculateInterestRatesOutput]
}

func (m *mockStrategyContract) CalculateInterestRates(
	runtime cre.Runtime,
	input default_reserve_interest_rate_strategy_v2.CalculateInterestRatesInput,
	blockNumber *big.Int,
) cre.Promise[default_reserve_interest_rate_strategy_v2.CalculateInterestRatesOutput] {
	if m.calculateInterestRatesFunc != nil {
		return m.calculateInterestRatesFunc(runtime, input, blockNumber)
	}
	return cre.PromiseFromResult(
		default_reserve_interest_rate_strategy_v2.CalculateInterestRatesOutput{},
		nil,
	)
}

func Test_CalculateAPYFromContract_success(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	// 5% APR in RAY = 0.05 * 1e27 = 5e25
	liquidityRateRAY := new(big.Int).Mul(big.NewInt(5), new(big.Int).Exp(big.NewInt(10), big.NewInt(25), nil))
	expectedAPY := 0.0512 // Approximately 5.12% APY

	mockStrategy := &mockStrategyContract{
		calculateInterestRatesFunc: func(_ cre.Runtime, _ default_reserve_interest_rate_strategy_v2.CalculateInterestRatesInput, _ *big.Int) cre.Promise[default_reserve_interest_rate_strategy_v2.CalculateInterestRatesOutput] {
			return cre.PromiseFromResult(default_reserve_interest_rate_strategy_v2.CalculateInterestRatesOutput{
				Arg0: liquidityRateRAY, // liquidityRate
				Arg1: big.NewInt(0),    // variableBorrowRate (not used)
			}, nil)
		},
	}

	params := &CalculateInterestRatesParams{
		Unbacked:                 big.NewInt(1000000),
		LiquidityAdded:           big.NewInt(0),
		LiquidityTaken:           big.NewInt(0),
		TotalDebt:                big.NewInt(500000),
		ReserveFactor:            big.NewInt(1000), // 10% in basis points
		Reserve:                  common.HexToAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"),
		UsingVirtualBalance:      true,
		VirtualUnderlyingBalance: big.NewInt(1000000),
	}

	apyPromise := CalculateAPYFromContract(runtime, mockStrategy, params)
	apy, err := apyPromise.Await()

	require.NoError(t, err)
	require.InDelta(t, expectedAPY, apy, 0.01) // Allow 1% tolerance
}

func Test_CalculateAPYFromContract_zeroLiquidityRate(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	// Zero liquidityRate is valid (underutilized pool) - should return 0 APY
	mockStrategy := &mockStrategyContract{
		calculateInterestRatesFunc: func(_ cre.Runtime, _ default_reserve_interest_rate_strategy_v2.CalculateInterestRatesInput, _ *big.Int) cre.Promise[default_reserve_interest_rate_strategy_v2.CalculateInterestRatesOutput] {
			return cre.PromiseFromResult(default_reserve_interest_rate_strategy_v2.CalculateInterestRatesOutput{
				Arg0: big.NewInt(0), // Zero liquidity rate (underutilized pool)
				Arg1: big.NewInt(0),
			}, nil)
		},
	}

	params := &CalculateInterestRatesParams{
		Unbacked:                 big.NewInt(1000000),
		LiquidityAdded:           big.NewInt(0),
		LiquidityTaken:           big.NewInt(0),
		TotalDebt:                big.NewInt(0),
		ReserveFactor:            big.NewInt(1000),
		Reserve:                  common.HexToAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"),
		UsingVirtualBalance:      true,
		VirtualUnderlyingBalance: big.NewInt(1000000),
	}

	apyPromise := CalculateAPYFromContract(runtime, mockStrategy, params)
	apy, err := apyPromise.Await()

	require.NoError(t, err)
	require.Equal(t, 0.0, apy)
}

func Test_CalculateAPYFromContract_veryHighAPR(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	// 1100% APR in RAY = 11.0 * 1e27 = 11e27
	veryHighRateRAY := new(big.Int).Mul(big.NewInt(11), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))

	mockStrategy := &mockStrategyContract{
		calculateInterestRatesFunc: func(_ cre.Runtime, _ default_reserve_interest_rate_strategy_v2.CalculateInterestRatesInput, _ *big.Int) cre.Promise[default_reserve_interest_rate_strategy_v2.CalculateInterestRatesOutput] {
			return cre.PromiseFromResult(default_reserve_interest_rate_strategy_v2.CalculateInterestRatesOutput{
				Arg0: veryHighRateRAY,
				Arg1: big.NewInt(0),
			}, nil)
		},
	}

	params := &CalculateInterestRatesParams{
		Unbacked:                 big.NewInt(1000000),
		LiquidityAdded:           big.NewInt(0),
		LiquidityTaken:           big.NewInt(0),
		TotalDebt:                big.NewInt(500000),
		ReserveFactor:            big.NewInt(1000),
		Reserve:                  common.HexToAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"),
		UsingVirtualBalance:      true,
		VirtualUnderlyingBalance: big.NewInt(1000000),
	}

	apyPromise := CalculateAPYFromContract(runtime, mockStrategy, params)
	apy, err := apyPromise.Await()

	require.Error(t, err)
	require.ErrorContains(t, err, "APR exceeds 1000%")
	require.Equal(t, 0.0, apy)
}

func Test_CalculateAPYFromContract_contractError(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	mockStrategy := &mockStrategyContract{
		calculateInterestRatesFunc: func(_ cre.Runtime, _ default_reserve_interest_rate_strategy_v2.CalculateInterestRatesInput, _ *big.Int) cre.Promise[default_reserve_interest_rate_strategy_v2.CalculateInterestRatesOutput] {
			return cre.PromiseFromResult(
				default_reserve_interest_rate_strategy_v2.CalculateInterestRatesOutput{},
				errors.New("contract call failed"),
			)
		},
	}

	params := &CalculateInterestRatesParams{
		Unbacked:                 big.NewInt(1000000),
		LiquidityAdded:           big.NewInt(0),
		LiquidityTaken:           big.NewInt(0),
		TotalDebt:                big.NewInt(500000),
		ReserveFactor:            big.NewInt(1000),
		Reserve:                  common.HexToAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"),
		UsingVirtualBalance:      true,
		VirtualUnderlyingBalance: big.NewInt(1000000),
	}

	apyPromise := CalculateAPYFromContract(runtime, mockStrategy, params)
	apy, err := apyPromise.Await()

	require.Error(t, err)
	require.Equal(t, 0.0, apy)
}

func Test_CalculateAPYFromContract_conversionError(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	// Test that conversion error is properly wrapped
	mockStrategy := &mockStrategyContract{
		calculateInterestRatesFunc: func(_ cre.Runtime, _ default_reserve_interest_rate_strategy_v2.CalculateInterestRatesInput, _ *big.Int) cre.Promise[default_reserve_interest_rate_strategy_v2.CalculateInterestRatesOutput] {
			// Return a very high APR that exceeds 1000% to trigger the error path
			veryHighRateRAY := new(big.Int).Mul(big.NewInt(11), new(big.Int).Exp(big.NewInt(10), big.NewInt(27), nil))
			return cre.PromiseFromResult(default_reserve_interest_rate_strategy_v2.CalculateInterestRatesOutput{
				Arg0: veryHighRateRAY,
				Arg1: big.NewInt(0),
			}, nil)
		},
	}

	params := &CalculateInterestRatesParams{
		Unbacked:                 big.NewInt(1000000),
		LiquidityAdded:           big.NewInt(0),
		LiquidityTaken:           big.NewInt(0),
		TotalDebt:                big.NewInt(500000),
		ReserveFactor:            big.NewInt(1000),
		Reserve:                  common.HexToAddress("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"),
		UsingVirtualBalance:      true,
		VirtualUnderlyingBalance: big.NewInt(1000000),
	}

	apyPromise := CalculateAPYFromContract(runtime, mockStrategy, params)
	apy, err := apyPromise.Await()

	require.Error(t, err)
	require.ErrorContains(t, err, "failed to convert APR to APY")
	require.ErrorContains(t, err, "APR exceeds 1000%")
	require.Equal(t, 0.0, apy)
}
