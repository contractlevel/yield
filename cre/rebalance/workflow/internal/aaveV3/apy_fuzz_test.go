package aaveV3

import (
	"math"
	"math/big"
	"testing"

	"rebalance/workflow/internal/constants"
	"rebalance/workflow/internal/helper"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"
)

// Fuzz_GetAPY_LiquidityAndAPR fuzzes both a non-negative APR (as a decimal)
// and a non-negative liquidityAdded and asserts:
//
//   - GetAPY does not error when config is valid and liquidityAdded is non-nil.
//   - The APY equals the value derived from the fuzzed APR via helper.APYFromPerSecondRate.
//   - The liquidityAdded passed into getCalculateInterestRatesParamsFunc matches the input.
//   - The asset passed into getCalculateInterestRatesParamsFunc is the configured USDC address.
//
// This uses the function indirection hooks in apy.go to avoid real on-chain calls.
func Fuzz_GetAPY_LiquidityAndAPR(f *testing.F) {
	// Save originals and restore at the end of the fuzz run.
	origProvider := newPoolAddressesProviderBindingFunc
	origGetProvider := getProtocolDataProviderBindingFunc
	origGetStrategy := getStrategyBindingFunc
	origGetParams := getCalculateInterestRatesParamsFunc
	origCalc := calculateAPYFromContractFunc

	defer func() {
		newPoolAddressesProviderBindingFunc = origProvider
		getProtocolDataProviderBindingFunc = origGetProvider
		getStrategyBindingFunc = origGetStrategy
		getCalculateInterestRatesParamsFunc = origGetParams
		calculateAPYFromContractFunc = origCalc
	}()

	const (
		fuzzChainSelector = uint64(42)
		fuzzChainName     = "test-chain"
		poolProviderAddr  = "0x0000000000000000000000000000000000000001"
		usdcAddr          = "0x0000000000000000000000000000000000000002"
	)

	// Shared state captured by hooks.
	var (
		lastParamsAsset     common.Address
		lastParamsLiquidity *big.Int
		currentAPR          float64
	)

	// Hook: no real provider; just return something and no error.
	newPoolAddressesProviderBindingFunc = func(_ *evm.Client, _ string) (PoolAddressesProviderInterface, error) {
		return nil, nil
	}

	// Hook: protocol data provider is unused in this fuzz; return nil, nil.
	getProtocolDataProviderBindingFunc = func(_ cre.Runtime, _ *evm.Client, _ PoolAddressesProviderInterface, _ string) cre.Promise[AaveProtocolDataProviderInterface] {
		return cre.PromiseFromResult[AaveProtocolDataProviderInterface](nil, nil)
	}

	// Hook: strategy binding is also unused by this test; return nil, nil.
	getStrategyBindingFunc = func(_ cre.Runtime, _ *evm.Client, _ AaveProtocolDataProviderInterface, _ common.Address, _ string) cre.Promise[DefaultReserveInterestRateStrategyV2Interface] {
		return cre.PromiseFromResult[DefaultReserveInterestRateStrategyV2Interface](nil, nil)
	}

	// Hook: capture the asset and liquidity passed into params and return dummy params.
	getCalculateInterestRatesParamsFunc = func(_ cre.Runtime, _ AaveProtocolDataProviderInterface, asset common.Address, liq *big.Int) cre.Promise[*CalculateInterestRatesParams] {
		lastParamsAsset = asset
		if liq != nil {
			lastParamsLiquidity = new(big.Int).Set(liq)
		} else {
			lastParamsLiquidity = nil
		}

		params := &CalculateInterestRatesParams{
			TotalDebt:               big.NewInt(1),
			VirtualUnderlyingBalance: big.NewInt(2),
		}
		return cre.PromiseFromResult(params, nil)
	}

	// Hook: compute APY directly from currentAPR using the same helper as the real code.
	calculateAPYFromContractFunc = func(_ cre.Runtime, _ DefaultReserveInterestRateStrategyV2Interface, _ *CalculateInterestRatesParams) cre.Promise[float64] {
		perSecond := currentAPR / float64(constants.SecondsPerYear)
		apy := helper.APYFromPerSecondRate(perSecond)
		return cre.PromiseFromResult(apy, nil)
	}

	// Seed some (APR, liquidity) pairs.
	f.Add(0.0, uint64(0))          // 0% APR, no liquidity
	f.Add(0.0001, uint64(1))       // tiny APR
	f.Add(0.05, uint64(1_000))     // 5% APR, moderate liquidity
	f.Add(1.0, uint64(1_000_000))  // 100% APR, large liquidity
	f.Add(9.99, uint64(1_000_000)) // ~999% APR, large liquidity

	f.Fuzz(func(t *testing.T, rawAPR float64, rawLiq uint64) {
		t.Helper()

		runtime := testutils.NewRuntime(t, nil)

		// Map arbitrary float to APR in [0, 10).
		currentAPR = math.Mod(math.Abs(rawAPR), 10.0)

		// LiquidityAdded is simply the rawLiq as a non-negative big.Int.
		liquidityAdded := new(big.Int).SetUint64(rawLiq)

		cfg := &helper.Config{
			Evms: []helper.EvmConfig{
				{
					ChainName:                          fuzzChainName,
					ChainSelector:                      fuzzChainSelector,
					AaveV3PoolAddressesProviderAddress: poolProviderAddr,
					USDCAddress:                        usdcAddr,
				},
			},
		}

		apy, err := GetAPY(cfg, runtime, liquidityAdded, fuzzChainSelector)
		require.NoError(t, err, "GetAPY should not error for valid config and non-nil liquidityAdded")

		// 1) APY must match what we compute from currentAPR via the helper.
		perSecond := currentAPR / float64(constants.SecondsPerYear)
		expectedAPY := helper.APYFromPerSecondRate(perSecond)
		require.Equal(t, expectedAPY, apy,
			"APY mismatch for APR=%g liquidityAdded=%s: got=%g want=%g",
			currentAPR, liquidityAdded.String(), apy, expectedAPY)

		// 2) USDC address must be propagated into params.
		expectedUSDC := common.HexToAddress(usdcAddr)
		require.Equal(t, expectedUSDC, lastParamsAsset, "USDC asset not propagated correctly")

		// 3) liquidityAdded must be propagated into params.
		require.NotNil(t, lastParamsLiquidity, "expected non-nil liquidity in params")
		require.Equal(t, liquidityAdded.String(), lastParamsLiquidity.String(),
			"liquidityAdded not propagated correctly to getCalculateInterestRatesParamsFunc")
	})
}
