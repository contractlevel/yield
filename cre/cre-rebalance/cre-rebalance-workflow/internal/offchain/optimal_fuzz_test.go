package offchain

import (
	"context"
	"testing"

	"cre-rebalance/cre-rebalance-workflow/internal/helper"

	"github.com/smartcontractkit/chainlink-protos/cre/go/sdk"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils/registry"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// --- FUZZ TESTS: GetOptimalStrategy ---

func Fuzz_offchain_GetOptimalStrategy(f *testing.F) {
	// --- SEED CORPUS ---
	// Providing a mix of valid structures and raw noise.

	// 1. Valid JSON with a clear winner
	f.Add([]byte(`{"data": [{"symbol": "USDC", "chain": "Ethereum", "project": "aave-v3", "apy": 5.5}]}`))

	// 2. Valid JSON with no eligible data (testing the "no strategy found" path)
	f.Add([]byte(`{"data": []}`))

	// 3. Raw noise / Malformed JSON
	f.Add([]byte(`garbage_data`))
	f.Add([]byte(`{"data": [{"symbol": "USDC", "chain":`)) // Truncated

	// --- FUZZER EXECUTION ---
	f.Fuzz(func(t *testing.T, data []byte) {
		// 1. SETUP: Mocking the environment
		rt := testutils.NewRuntime(t, nil)

		// Mock the HTTP capability to return the raw fuzzed bytes
		registry.GetRegistry(t).RegisterCapability(&mockHttpCapability{
			id: "http-actions@1.0.0-alpha",
			fn: func(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse {
				// StatusOK (200) is used here to ensure the fuzzer hits the parsing logic.
				// Error code fuzzing is handled in unit tests.
				return MockResponse(StatusOK, data)
			},
		})

		// 2. ACTION: Invoke the top-level orchestration function
		strategy, err := GetOptimalStrategy(&helper.Config{}, rt)

		// 3. INVARIANTS: Truths that must remain true for any 'data' input

		// Invariant A: Panic Safety
		// (The fuzzer implicitly checks this; if the code panics, the test fails)

		if err != nil {
			// Invariant B: Error Containment
			// If an error is returned, the strategy must be nil (no partial/corrupt state).
			assert.Nil(t, strategy, "Strategy must be nil if an error occurs")
			return
		}

		// Invariant C: Structural Integrity (Happy Path)
		// If no error, the strategy must be fully formed.
		require.NotNil(t, strategy)

		// Check that the ProtocolID (hashed identifier) was actually generated.
		assert.NotEqual(t, [32]byte{}, strategy.ProtocolId, "ProtocolID must not be an empty byte array")

		// Invariant D: Value Domain Constrainment
		// The ChainSelector must strictly be one of our supported Chainlink CCIP selectors.
		// This validates that the mapping from "Ethereum" -> 5009297550715157269 is robust.
		knownSelectors := map[uint64]bool{
			4949039107694359620:  true, // Arbitrum
			15971525489660198786: true, // Base
			5009297550715157269:  true, // Ethereum
			3734403246176062136:  true, // Optimism
		}

		assert.True(t, knownSelectors[strategy.ChainSelector],
			"ChainSelector %d generated from fuzzed data is not in the supported allowlist",
			strategy.ChainSelector)
	})
}
