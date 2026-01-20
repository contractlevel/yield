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

/*//////////////////////////////////////////////////////////////
                          FUZZ SETUP
//////////////////////////////////////////////////////////////*/

// Global pointer used by the fuzz binding override.
// Kept simple on purpose.
var currentComet *fakeComet

// Fuzz_GetAPYPromise_LiquidityAndSupplyRate fuzzes both supplyRate and
// non-negative liquidityAdded and asserts:
//
//   - GetAPYPromise does not error when baseSupply > 0 and liquidityAdded >= 0.
//   - The APY equals calculateAPYFromSupplyRate(supplyRate).
//   - The utilization passed to GetSupplyRate matches:
//       (totalBorrow * WAD) / (totalSupply + liquidityAdded).
//
// This reuses the existing fakeComet used in apy_promise_test.go and
// overrides newCometBindingFunc in the simplest possible way.
func Fuzz_GetAPYPromise_LiquidityAndSupplyRate(f *testing.F) {
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
	f.Add(uint64(0), uint64(0))                    // zero rate, no extra liquidity
	f.Add(uint64(1), uint64(0))                    // tiny rate
	f.Add(uint64(1_000_000_000), uint64(1))        // small rate, small liquidity
	f.Add(uint64(1_000_000_000_000), uint64(1e6))  // moderate rate, moderate liquidity
	f.Add(uint64(1_000_000_000_000), uint64(1e9))  // moderate rate, large liquidity

	f.Fuzz(func(t *testing.T, rawSupplyRate uint64, rawLiq uint64) {
		t.Helper()

		runtime := testutils.NewRuntime(t, nil)

		// Bound supplyRate to a safe range; reuse the constant from calculate_fuzz_test.go
		// if it exists, otherwise just cap it at some reasonable upper bound.
		supplyRate := rawSupplyRate
		if supplyRate > maxFuzzSupplyRateInWad {
			supplyRate = supplyRate % maxFuzzSupplyRateInWad
		}

		// Bound liquidityAdded to a reasonable non-negative range.
		// We keep totalSupply + liquidityAdded in [baseSupply, baseSupply+maxExtra].
		baseSupply := big.NewInt(1_000_000_000) // 1e9
		maxExtra := uint64(2_000_000_000)       // up to +2e9 // @review magic numbers
		liqBound := rawLiq % (maxExtra + 1)

		liquidityAdded := new(big.Int).SetUint64(liqBound)

		// Build a fresh fakeComet for this fuzz input.
		comet := &fakeComet{
			totalSupply: new(big.Int).Set(baseSupply),
			totalBorrow: big.NewInt(400_000_000), // arbitrary positive borrow
			supplyRate:  supplyRate,
		}
		currentComet = comet

		cfg := &helper.Config{
			BlockNumber: 42, // arbitrary; fakeComet just records it
			Evms: []helper.EvmConfig{
				{
					ChainName:                  "test-chain",
					ChainSelector:              123,        // arbitrary
					CompoundV3CometUSDCAddress: "ignored", // not used by fakeComet
				},
			},
		}

		// Call the function under test.
		promise := GetAPYPromise(cfg, runtime, liquidityAdded, cfg.Evms[0].ChainSelector)

		apy, err := promise.Await()
		require.NoError(t, err, "GetAPYPromise should not error when baseSupply > 0 and liquidityAdded >= 0")

		// 1) APY must match calculateAPYFromSupplyRate(supplyRate).
		expectedAPY := calculateAPYFromSupplyRate(supplyRate)
		require.Equal(t, expectedAPY, apy,
			"APY mismatch for supplyRate=%d liquidityAdded=%s: got=%g want=%g",
			supplyRate, liquidityAdded.String(), apy, expectedAPY)

		// 2) Utilization wiring: fakeComet records the last utilization it saw.
		require.NotNil(t, comet.lastUtilization, "expected GetSupplyRate to be called")

		expectedSupply := new(big.Int).Add(baseSupply, liquidityAdded)
		require.Greater(t, expectedSupply.Sign(), 0, "expected total supply > 0")

		expectedUtil := new(big.Int).Mul(comet.totalBorrow, big.NewInt(constants.WAD))
		expectedUtil.Div(expectedUtil, expectedSupply)

		require.Equal(t, 0, comet.lastUtilization.Cmp(expectedUtil),
			"unexpected utilization passed to GetSupplyRate: got=%s want=%s",
			comet.lastUtilization.String(), expectedUtil.String())
	})
}
