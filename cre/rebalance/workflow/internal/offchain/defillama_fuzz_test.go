package offchain

import (
	"context"
	"encoding/json"
	"math"
	"testing"
	"unicode/utf8"

	"rebalance/workflow/internal/helper"

	"github.com/smartcontractkit/chainlink-protos/cre/go/sdk"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/networking/http"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils/registry"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/types/known/anypb"
)

// @review Not sure about this fuzz test as it's already being implicitly covered in optimal_fuzz_test.go
// Fuzz_offchain_getBestPool focuses on the "Bridge" logic:
// 1. Error wrapping for SDK/Capability failures.
// 2. Structural safety when logging results via slog.
func Fuzz_offchain_getBestPool(f *testing.F) {
	// --- SEED CORPUS ---
	f.Add("consensus timeout", "USDC", "Ethereum")
	f.Add("network unreachable", "LINK", "Arbitrum")
	f.Add("", "USDC", "Base") // Test success path
	f.Add("", "", "")         // Test empty/edge cases

	f.Fuzz(func(t *testing.T, errorMsg string, symbol string, chain string) {
		// --- 1. UTF-8 GUARD ---
		// Protobuf string fields must be valid UTF-8. We skip invalid inputs
		// because the SDK layer will reject them before our code is even called.
		if !utf8.ValidString(errorMsg) || !utf8.ValidString(symbol) || !utf8.ValidString(chain) {
			t.Skip()
		}

		// --- 2. SETUP ---
		rt := testutils.NewRuntime(t, nil)

		registry.GetRegistry(t).RegisterCapability(&mockHttpCapability{
			id: "http-actions@1.0.0-alpha",
			fn: func(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse {
				// Simulate an SDK-level error if the fuzzer provided an error message
				if errorMsg != "" {
					return &sdk.CapabilityResponse{
						Response: &sdk.CapabilityResponse_Error{Error: errorMsg},
					}
				}

				// Otherwise, simulate a success payload with fuzzed data.
				// Note: if 'symbol' contains double quotes, the JSON will be malformed,
				// which is a good test for the error handling in getBestPool.
				respAny, _ := anypb.New(&http.Response{
					StatusCode: StatusOK,
					Body:       []byte(`{"data": [{"symbol": "` + symbol + `", "chain": "` + chain + `", "project": "aave-v3", "apy": 10.0}]}`),
				})
				return &sdk.CapabilityResponse{Response: &sdk.CapabilityResponse_Payload{Payload: respAny}}
			},
		})

		// --- 3. ACTION ---
		result, err := getBestPool(&helper.Config{}, rt)

		// --- 4. INVARIANTS ---

		// Invariant A: Error Wrapping
		// If the mock returned an error, our bridge must wrap it with "failed to await promise".
		if errorMsg != "" {
			require.Error(t, err)
			assert.Contains(t, err.Error(), "failed to await promise")
			assert.Contains(t, err.Error(), errorMsg)
			assert.Nil(t, result)
			return
		}

		// Invariant B: Logic & Logging Safety
		// If there is no errorMsg, getBestPool will either succeed or return a parser error.
		// We ensure it doesn't panic during result handling or logging.
		if err == nil {
			if result != nil {
				// The parser accepted the pool; ensure fields are populated.
				assert.NotEmpty(t, result.Symbol)
				assert.NotEmpty(t, result.Chain)
			}
		} else {
			// If getBestPool returned an error (e.g. malformed JSON from our concatenation),
			// result MUST be nil.
			assert.Nil(t, result)
		}
	})
}

func Fuzz_offchain_fetchAndParsePools(f *testing.F) {
	// --- SEED CORPUS ---
	// Provide known-good and known-bad patterns to give the fuzzer a head start.

	// 1. Success Paths: Standard valid JSON across different chains/projects
	f.Add(true, []byte(`{"data": [{"symbol": "USDC", "chain": "Ethereum", "project": "aave-v3", "apy": 5.5}]}`))
	f.Add(false, []byte(`{"data": [{"symbol": "USDC", "chain": "Base", "project": "compound-v3", "apy": 8.36}]}`))

	// 2. Edge Cases: Empty arrays, invalid types, and truncated JSON
	f.Add(true, []byte(`{"data": []}`))
	f.Add(false, []byte(`{"data": "not an array"}`))
	f.Add(false, []byte(`{"data": [{"symbol": "USDC", "chain": "Eth`))

	// 3. Logic Tests: Multiple pools to verify "Max APY" selection logic
	f.Add(true, []byte(`{"data": [{"symbol": "USDC", "chain": "Ethereum", "project": "aave-v3", "apy": 1.0}, {"symbol": "USDC", "chain": "Ethereum", "project": "aave-v3", "apy": 10.0}]}`))
	f.Add(false, []byte(`{"data": [{"symbol": "USDC", "chain": "Ethereum", "project": "aave-v3", "apy": 0.0}, {"symbol": "USDC", "chain": "Ethereum", "project": "aave-v3", "apy": 100.0}]}`))

	// 4. Filter Tests: Valid JSON containing pools that should be ignored by the allowlist
	f.Add(true, []byte(`{"data": [{"symbol": "SHIB", "chain": "Solana", "project": "Unknown", "apy": 99.0}]}`))

	// --- FUZZER EXECUTION ---
	f.Fuzz(func(t *testing.T, useGzip bool, payload []byte) {
		// 1. SETUP: Mocking the environment and networking capability
		rt := testutils.NewRuntime(t, nil)
		var finalBody []byte
		headers := make(map[string]string)

		// Dynamically handle Gzip compression based on fuzzer input
		if useGzip {
			headers["Content-Encoding"] = "gzip"
			finalBody = compressGzip(string(payload))
		} else {
			finalBody = payload
		}

		// Register the mock HTTP capability to return the fuzzed payload
		registry.GetRegistry(t).RegisterCapability(&mockHttpCapability{
			id: "http-actions@1.0.0-alpha",
			fn: func(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse {
				respAny, _ := anypb.New(&http.Response{
					StatusCode: StatusOK,
					Body:       finalBody,
					Headers:    headers,
				})
				return &sdk.CapabilityResponse{Response: &sdk.CapabilityResponse_Payload{Payload: respAny}}
			},
		})

		// 2. ACTION: Invoke the streaming parser
		promise := http.SendRequest(&helper.Config{}, rt, &http.Client{}, fetchAndParsePools, cre.ConsensusIdenticalAggregation[*Pool]())
		result, err := promise.Await()

		// 3. INVARIANTS: Check universal truths that must hold regardless of input
		if err == nil && result != nil {
			// Whitelist Invariant: Result must always be within defined allowlists
			assert.True(t, AllowedChain[result.Chain], "Disallowed chain: %s", result.Chain)
			assert.True(t, AllowedProject[result.Project], "Disallowed project: %s", result.Project)
			assert.True(t, AllowedSymbol[result.Symbol], "Disallowed symbol: %s", result.Symbol)

			// APY Invariant: APY must be positive
			assert.True(t, result.Apy > 0.0, "APY must be positive: %f", result.Apy)

			// Sanity Invariant: APY must be a valid numerical value
			assert.False(t, math.IsNaN(result.Apy) || math.IsInf(result.Apy, 0), "Invalid APY: %f", result.Apy)
		}

		// 4. DIFFERENTIAL ORACLE: Compare streaming results against standard 'encoding/json'
		// This ensures the optimized parser behaves/decodes like the standard library.
		var wrapper struct{ Data []Pool }
		oracleErr := json.Unmarshal(payload, &wrapper)

		var oracleWinner *Pool
		if oracleErr == nil {
			var max = 0.0
			for _, p := range wrapper.Data {
				// Replicate the filtering logic exactly
				if AllowedChain[p.Chain] && AllowedProject[p.Project] && AllowedSymbol[p.Symbol] && p.Apy > max {
					max = p.Apy
					winner := p
					oracleWinner = &winner
				}
			}
		}

		// Comparison: Only validate if the standard library could also parse the input.
		if oracleErr == nil {
			if oracleWinner != nil {
				// If oracle found a winner, our parser must match it
				require.NoError(t, err)
				require.NotNil(t, result)
				assert.Equal(t, oracleWinner.Symbol, result.Symbol)
				assert.Equal(t, oracleWinner.Chain, result.Chain)
				assert.InDelta(t, oracleWinner.Apy, result.Apy, 0.00001)
			} else {
				// If oracle found nothing valid, our parser must return an error
				assert.Error(t, err)
				assert.Nil(t, result)
			}
		}
	})
}
