package offchain

import (
	"testing"
	"math/big"
	"cre-rebalance/cre-rebalance-workflow/internal/onchain"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
)

func Fuzz_CalculateOptimalStrategy(f *testing.F) {
	runtime := testutils.NewRuntime(f, nil)
	logger := runtime.Logger()

	// Seed example inputs (protocol byte, chain selector, tvl)
	f.Add(uint8(1), uint64(10), int64(0))
	f.Add(uint8(2), uint64(42), int64(100))
	f.Add(uint8(255), uint64(0), int64(-12345)) // negative tvl to exercise normalization

	f.Fuzz(func(t *testing.T, protoByte uint8, chainSel uint64, tvlRaw int64) {
		// Build a Strategy whose ProtocolId is derived from a single byte.
		var id [32]byte
		id[0] = protoByte

		current := onchain.Strategy{
			ProtocolId:    id,
			ChainSelector: chainSel,
		}

		// Ensure tvl is non-negative; real-world TVL should not be negative.
		if tvlRaw < 0 {
			tvlRaw = -tvlRaw
		}
		tvl := big.NewInt(tvlRaw)

		optimal := CalculateOptimalStrategy(logger, current, tvl)

		// Invariant: chain selector must not change.
		if optimal.ChainSelector != current.ChainSelector {
			t.Fatalf("calculateOptimalStrategy changed chain selector: current=%d optimal=%d",
				current.ChainSelector, optimal.ChainSelector)
		}

		// Basic sanity: tvl should remain non-negative; if we ever change the function
		// to mutate tvl, this guards against silly mistakes.
		if tvl.Sign() < 0 {
			t.Fatalf("tvl became negative unexpectedly: %s", tvl.String())
		}

		// @review this needs to be revisited when we have a real APY model
	})
}