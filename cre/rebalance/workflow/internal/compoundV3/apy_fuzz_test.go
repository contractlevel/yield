package compoundV3

import (
	"math/big"
	"testing"

	"rebalance/workflow/internal/constants"
	"rebalance/workflow/internal/helper"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"
)

// Fuzz_GetAPY_LiquidityAndSupplyRate fuzzes both supplyRate and
// non-negative liquidityAdded and asserts:
//
//   - GetAPY does not error when baseSupply > 0 and liquidityAdded >= 0.
//   - The APY equals calculateAPYFromSupplyRate(supplyRate).
//   - The utilization passed to GetSupplyRate matches:
//       (totalBorrow * WAD) / (totalSupply + liquidityAdded).
//   - All on-chain reads use the configured block number.
//
// This reuses the existing fakeComet used in apy_promise_test.go and
// overrides newCometBindingFunc in the simplest possible way.
func Fuzz_GetAPY_LiquidityAndSupplyRate(f *testing.F) {
	// Save and restore the original binding function.
	origNew := newCometBindingFunc
	defer func() {
		newCometBindingFunc = origNew
	}()

	// Override binding to always return currentComet.
	newCometBindingFunc = func(_ *evm.Client, _ string) (CometInterface, error) {
		return currentComet, nil
	}

	// Seed some (supplyRate, liquidityAdded) pairs.
	f.Add(uint64(0), uint64(0))                     // zero rate, no extra liquidity
	f.Add(uint64(1), uint64(0))                     // tiny rate
	f.Add(uint64(1_000_000_000), uint64(1))         // small rate, small liquidity
	f.Add(uint64(1_000_000_000_000), uint64(1e6))   // moderate rate, moderate liquidity
	f.Add(uint64(1_000_000_000_000), uint64(1e9))   // moderate rate, larger liquidity

	f.Fuzz(func(t *testing.T, rawSupplyRate uint64, rawLiq uint64) {
		t.Helper()

		runtime := testutils.NewRuntime(t, nil)

		// Bound supplyRate to a safe range; reuse the constant from calculate_fuzz_test.go
		// if it exists, otherwise just cap it at some reasonable upper bound.
		supplyRate := rawSupplyRate
		if supplyRate > maxFuzzSupplyRateInWad {
			supplyRate = supplyRate % maxFuzzSupplyRateInWad
		}

		// Bound liquidityAdded to [0, fuzzMaxExtraLiquidity].
		liqBound := rawLiq % (fuzzMaxExtraLiquidity + 1)
		liquidityAdded := new(big.Int).SetUint64(liqBound)

		baseSupply := big.NewInt(fuzzBaseSupplyWadless)
		baseBorrow := big.NewInt(fuzzBaseBorrowWadless)

		// Build a fresh fakeComet for this fuzz input.
		comet := &fakeComet{
			totalSupply: new(big.Int).Set(baseSupply),
			totalBorrow: new(big.Int).Set(baseBorrow),
			supplyRate:  supplyRate,
		}
		currentComet = comet

		cfg := &helper.Config{
			BlockNumber: fuzzBlockNumber,
			Evms: []helper.EvmConfig{
				{
					ChainName:                  "test-chain",
					ChainSelector:              fuzzChainSelector,
					CompoundV3CometUSDCAddress: "ignored", // not used by fakeComet
				},
			},
		}

		// Call the function under test.
		apy, err := GetAPY(cfg, runtime, liquidityAdded, cfg.Evms[0].ChainSelector)
		require.NoError(t, err, "GetAPY should not error when baseSupply > 0 and liquidityAdded >= 0")

		// 1) APY must match calculateAPYFromSupplyRate(supplyRate).
		expectedAPY := calculateAPYFromSupplyRate(supplyRate)
		require.Equal(t, expectedAPY, apy,
			"APY mismatch for supplyRate=%d liquidityAdded=%s: got=%g want=%g",
			supplyRate, liquidityAdded.String(), apy, expectedAPY)

		// 2) All on-chain reads should use the configured block number.
		expectedBlock := big.NewInt(cfg.BlockNumber)

		require.NotNil(t, comet.lastTotalSupplyBlock, "expected TotalSupply to be called")
		require.Equal(t, 0, comet.lastTotalSupplyBlock.Cmp(expectedBlock),
			"unexpected blockNumber in TotalSupply: got=%s want=%s",
			comet.lastTotalSupplyBlock.String(), expectedBlock.String())

		require.NotNil(t, comet.lastTotalBorrowBlock, "expected TotalBorrow to be called")
		require.Equal(t, 0, comet.lastTotalBorrowBlock.Cmp(expectedBlock),
			"unexpected blockNumber in TotalBorrow: got=%s want=%s",
			comet.lastTotalBorrowBlock.String(), expectedBlock.String())

		require.NotNil(t, comet.lastGetSupplyRateBlock, "expected GetSupplyRate to be called")
		require.Equal(t, 0, comet.lastGetSupplyRateBlock.Cmp(expectedBlock),
			"unexpected blockNumber in GetSupplyRate: got=%s want=%s",
			comet.lastGetSupplyRateBlock.String(), expectedBlock.String())

		// 3) Utilization wiring: fakeComet records the last utilization it saw.
		require.NotNil(t, comet.lastUtilization, "expected GetSupplyRate to be called with utilization")

		expectedSupply := new(big.Int).Add(baseSupply, liquidityAdded)
		require.Greater(t, expectedSupply.Sign(), 0, "expected total supply > 0")

		expectedUtil := new(big.Int).Mul(baseBorrow, big.NewInt(constants.WAD))
		expectedUtil.Div(expectedUtil, expectedSupply)

		require.Equal(t, 0, comet.lastUtilization.Cmp(expectedUtil),
			"unexpected utilization passed to GetSupplyRate: got=%s want=%s",
			comet.lastUtilization.String(), expectedUtil.String())
	})
}
