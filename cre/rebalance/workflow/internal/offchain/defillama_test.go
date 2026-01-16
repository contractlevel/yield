package offchain

import (
	"context"
	"testing"

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

// --- UNIT TESTS: getBestPool ---

func Test_offchain_getBestPool(t *testing.T) {
	tests := []struct {
		name           string
		mockFn         func(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse
		expectError    bool
		errorContains  string
		expectedSymbol string
	}{
		{
			name: "Success: Valid response returns best pool",
			mockFn: func(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse {
				respAny, _ := anypb.New(&http.Response{
					StatusCode: StatusOK,
					Body:       []byte(`{"data": [{"symbol": "USDC", "chain": "Ethereum", "project": "aave-v3", "apy": 8.0}]}`),
				})
				return &sdk.CapabilityResponse{Response: &sdk.CapabilityResponse_Payload{Payload: respAny}}
			},
			expectError:    false,
			expectedSymbol: "USDC",
		},
		{
			name: "Error: Underlying capability returns error",
			mockFn: func(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse {
				return &sdk.CapabilityResponse{Response: &sdk.CapabilityResponse_Error{Error: "network unreachable"}}
			},
			expectError:   true,
			errorContains: "failed to await promise",
		},
		{
			name: "Error: No pools found in response",
			mockFn: func(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse {
				respAny, _ := anypb.New(&http.Response{StatusCode: StatusOK, Body: []byte(`{"data": []}`)})
				return &sdk.CapabilityResponse{Response: &sdk.CapabilityResponse_Payload{Payload: respAny}}
			},
			expectError: true,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			rt := testutils.NewRuntime(t, nil)
			registry.GetRegistry(t).RegisterCapability(&mockHttpCapability{
				id: "http-actions@1.0.0-alpha",
				fn: tc.mockFn,
			})

			result, err := getBestPool(&helper.Config{}, rt)

			if tc.expectError {
				require.Error(t, err)
				if tc.errorContains != "" {
					assert.Contains(t, err.Error(), tc.errorContains)
				}
				assert.Nil(t, result)
			} else {
				require.NoError(t, err)
				require.NotNil(t, result)
				assert.Equal(t, tc.expectedSymbol, result.Symbol)
			}
		})
	}
}

// --- UNIT TESTS: fetchAndParsePools ---
func Test_offchain_fetchAndParsePools(t *testing.T) {
	tests := []struct {
		name                  string
		statusCode            uint32
		headers               map[string]string
		body                  []byte
		expectCapabilityError bool
		expectError           bool
		errorContains         string
		expectedPool          *Pool
	}{
		// 1. SUCCESS CASES
		{
			name:         "Success: Plain JSON parsing",
			statusCode:   StatusOK,
			body:         []byte(`{"data": [{"symbol": "USDC", "chain": "Ethereum", "project": "aave-v3", "apy": 5.5}]}`),
			expectedPool: &Pool{Symbol: "USDC", Apy: 5.5},
		},
		{
			name:         "Success: Gzipped JSON parsing",
			statusCode:   StatusOK,
			headers:      map[string]string{"Content-Encoding": "gzip"},
			body:         compressGzip(`{"data": [{"symbol": "USDC", "chain": "Ethereum", "project": "aave-v3", "apy": 12.5}]}`),
			expectedPool: &Pool{Symbol: "USDC", Apy: 12.5},
		},
		{
			name:         "Success: Lowercase Gzip header",
			statusCode:   StatusOK,
			headers:      map[string]string{"content-encoding": "gzip"},
			body:         compressGzip(`{"data": [{"symbol": "USDC", "chain": "Ethereum", "project": "aave-v3", "apy": 9.0}]}`),
			expectedPool: &Pool{Symbol: "USDC", Apy: 9.0},
		},

		// 2. HTTP & PROTOCOL ERRORS
		{
			name:          "Error: HTTP 500 from API",
			statusCode:    500,
			body:          []byte(`Internal Server Error`),
			expectError:   true,
			errorContains: "failed to get OK response: 500",
		},
		{
			name:                  "Error: Network failure (Capability level)",
			expectCapabilityError: true,
			expectError:           true,
			errorContains:         "failed to get API response",
		},

		// 3. DATA & FILTERING ERRORS
		{
			name:          "Error: No pools match allowlist",
			statusCode:    StatusOK,
			body:          []byte(`{"data": [{"symbol": "SHIB", "chain": "DogeChain", "project": "MemeSwap", "apy": 999}]}`),
			expectError:   true,
			errorContains: "no approved strategy pool found",
		},
		{
			name:          "Error: Invalid JSON data type for APY",
			statusCode:    StatusOK,
			body:          []byte(`{"data": [{"apy": "not-a-number"}]}`),
			expectError:   true,
			errorContains: "error decoding pool item",
		},

		// 4. STREAMING PARSER EDGE CASES (JSON structure)
		{
			name:          "Error: Missing 'data' key",
			statusCode:    StatusOK,
			body:          []byte(`{"metadata": "none"}`),
			expectError:   true,
			errorContains: "could not find 'data' key",
		},
		{
			name:          "Error: 'data' is not an array",
			statusCode:    StatusOK,
			body:          []byte(`{"data": "invalid"}`),
			expectError:   true,
			errorContains: "expected array start",
		},
		{
			name:          "Error: Malformed Gzip stream",
			statusCode:    StatusOK,
			headers:       map[string]string{"Content-Encoding": "gzip"},
			body:          []byte("not-actually-gzipped"),
			expectError:   true,
			errorContains: "failed to create gzip reader",
		},
		{
			name:          "Error: Truncated JSON stream",
			statusCode:    StatusOK,
			body:          []byte(`{"data": `),
			expectError:   true,
			errorContains: "error reading array start",
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			rt := testutils.NewRuntime(t, nil)

			// Register mock capability with logic specific to the test case
			registry.GetRegistry(t).RegisterCapability(&mockHttpCapability{
				id: "http-actions@1.0.0-alpha",
				fn: func(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse {
					if tc.expectCapabilityError {
						return &sdk.CapabilityResponse{Response: &sdk.CapabilityResponse_Error{Error: "mocked network failure"}}
					}

					respAny, _ := anypb.New(&http.Response{
						StatusCode: tc.statusCode,
						Body:       tc.body,
						Headers:    tc.headers,
					})
					return &sdk.CapabilityResponse{Response: &sdk.CapabilityResponse_Payload{Payload: respAny}}
				},
			})

			// Execute using the Chainlink SDK HTTP SendRequest pattern
			promise := http.SendRequest(&helper.Config{}, rt, &http.Client{}, fetchAndParsePools, cre.ConsensusIdenticalAggregation[*Pool]())
			result, err := promise.Await()

			// Assertions
			if tc.expectError {
				require.Error(t, err)
				assert.Contains(t, err.Error(), tc.errorContains)
				assert.Nil(t, result)
			} else {
				require.NoError(t, err)
				require.NotNil(t, result)
				assert.Equal(t, tc.expectedPool.Symbol, result.Symbol)
				assert.Equal(t, tc.expectedPool.Apy, result.Apy)
			}
		})
	}
}
