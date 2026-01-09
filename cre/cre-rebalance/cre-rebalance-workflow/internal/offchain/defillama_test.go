package offchain

import (
	"bytes"
	"compress/gzip"
	"context"
	"testing"

	"cre-rebalance/cre-rebalance-workflow/internal/helper"

	"github.com/smartcontractkit/chainlink-protos/cre/go/sdk"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/networking/http"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils/registry"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/types/known/anypb"
)

// mockHttpCapability now matches the registry.Capability interface exactly
type mockHttpCapability struct {
	id string
	fn func(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse
}

func (m *mockHttpCapability) ID() string {
	return m.id
}

func (m *mockHttpCapability) Invoke(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse {
	return m.fn(ctx, req)
}

// Helper to compress JSON for the Gzip test case
func compressGzip(data string) []byte {
	var buf bytes.Buffer
	gz := gzip.NewWriter(&buf)
	gz.Write([]byte(data))
	gz.Close()
	return buf.Bytes()
}

func TestGetOptimalPool(t *testing.T) {
	// 1. Define the test table
	tests := []struct {
		name           string
		mockFn         func(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse
		expectError    bool
		errorContains  string
		expectedSymbol string
	}{
		{
			name: "Success - Orchestration works",
			mockFn: func(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse {
				respAny, _ := anypb.New(&http.Response{
					StatusCode: 200,
					Body:       []byte(`{"data": [{"symbol": "USDC", "chain": "Ethereum", "project": "aave-v3", "apy": 8.0}]}`),
				})
				return &sdk.CapabilityResponse{
					Response: &sdk.CapabilityResponse_Payload{Payload: respAny},
				}
			},
			expectError:    false,
			expectedSymbol: "USDC",
		},
		{
			name: "Failure - Promise returns error",
			mockFn: func(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse {
				return &sdk.CapabilityResponse{
					Response: &sdk.CapabilityResponse_Error{Error: "network unreachable"},
				}
			},
			expectError:   true,
			errorContains: "failed to await promise",
		},
		{
			name: "Failure - Promise results in nil pool",
			mockFn: func(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse {
				respAny, _ := anypb.New(&http.Response{
					StatusCode: 200,
					Body:       []byte(`{"data": []}`),
				})
				return &sdk.CapabilityResponse{
					Response: &sdk.CapabilityResponse_Payload{Payload: respAny},
				}
			},
			expectError: true,
		},
	}

	// 2. Execute table
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			// Setup standard infrastructure
			rt := testutils.NewRuntime(t, nil)
			config := &helper.Config{}

			// DRY: Centralized registration
			registry.GetRegistry(t).RegisterCapability(&mockHttpCapability{
				id: "http-actions@1.0.0-alpha",
				fn: tc.mockFn,
			})

			// Execute the function under test
			result, err := getOptimalPool(config, rt)

			// Assertions
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

func TestFetchAndParsePools_TableDriven(t *testing.T) {
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
		{
			name:         "Success - Standard JSON",
			statusCode:   200,
			body:         []byte(`{"data": [{"symbol": "USDC", "chain": "Ethereum", "project": "aave-v3", "apy": 5.5}]}`),
			expectError:  false,
			expectedPool: &Pool{Symbol: "USDC", Apy: 5.5},
		},
		{
			name:         "Success - Gzipped JSON",
			statusCode:   200,
			headers:      map[string]string{"Content-Encoding": "gzip"},
			body:         compressGzip(`{"data": [{"symbol": "USDC", "chain": "Ethereum", "project": "aave-v3", "apy": 12.5}]}`),
			expectError:  false,
			expectedPool: &Pool{Symbol: "USDC", Apy: 12.5},
		},
		{
			name:          "Failure - HTTP 500 Error",
			statusCode:    500,
			body:          []byte(`Internal Server Error`),
			expectError:   true,
			errorContains: "failed to get API OK response: 500",
		},
		{
			name:          "Failure - Invalid JSON Format",
			statusCode:    200,
			body:          []byte(`{"data": [{"apy": "not-a-number"}]}`),
			expectError:   true,
			errorContains: "error decoding pool item",
		},
		{
			name:          "Failure - No Allowed Pools Found",
			statusCode:    200,
			body:          []byte(`{"data": [{"symbol": "SHIB", "chain": "DogeChain", "project": "MemeSwap", "apy": 999}]}`),
			expectError:   true,
			errorContains: "no approved strategy pool found",
		},
		{
			name:                  "Failure - Capability Invocation Error",
			expectCapabilityError: true,
			expectError:           true,
			errorContains:         "failed to get API response",
		},
		{
			name:          "Failure - Malformed Gzip Header",
			statusCode:    200,
			headers:       map[string]string{"Content-Encoding": "gzip"},
			body:          []byte("not gzipped data"),
			expectError:   true,
			errorContains: "failed to create gzip reader",
		},
		{
			name:          "Failure - Corrupt Gzip Body",
			statusCode:    200,
			headers:       map[string]string{"Content-Encoding": "gzip"},
			body:          compressGzip(`{"data": [ {"symbol": "USDC"`),
			expectError:   true,
			errorContains: "error decoding pool item",
		},
		{
			name:          "Failure - Missing Data Key",
			statusCode:    200,
			body:          []byte(`{"metadata": "none"}`),
			expectError:   true,
			errorContains: "could not find 'data' key",
		},
		{
			name:          "Failure - Data is not an array",
			statusCode:    200,
			body:          []byte(`{"data": "invalid"}`),
			expectError:   true,
			errorContains: "expected array start after 'data' key",
		},
		{
			name:          "Failure - Malformed JSON in Stream",
			statusCode:    200,
			body:          []byte(`{"data": [ {`), // Ends abruptly after object start
			expectError:   true,
			errorContains: "error decoding pool item",
		},
		{
			name:          "Failure - Syntax Error in Token Stream",
			statusCode:    200,
			body:          []byte(`{"data": [123, @]}`), // @ is invalid JSON
			expectError:   true,
			errorContains: "error decoding pool item",
		},
		{
			name:          "Failure - Syntax Error Before Data Key",
			statusCode:    200,
			body:          []byte(`{ "metadata": @@@ }`), // @ is invalid JSON syntax
			expectError:   true,
			errorContains: "error decoding JSON stream",
		},
		{
			name:          "Failure - Stream Ends After Data Key",
			statusCode:    200,
			body:          []byte(`{"data": `), // No value or delimiter follows the colon
			expectError:   true,
			errorContains: "error reading array start",
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			rt := testutils.NewRuntime(t, nil)

			registry.GetRegistry(t).RegisterCapability(&mockHttpCapability{
				id: "http-actions@1.0.0-alpha",
				fn: func(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse {
					if tc.expectCapabilityError {
						return &sdk.CapabilityResponse{
							Response: &sdk.CapabilityResponse_Error{
								Error: "mocked network failure",
							},
						}
					}

					mockResp := &http.Response{
						StatusCode: tc.statusCode,
						Body:       tc.body,
						Headers:    tc.headers,
					}
					respAny, _ := anypb.New(mockResp)
					return &sdk.CapabilityResponse{
						Response: &sdk.CapabilityResponse_Payload{Payload: respAny},
					}
				},
			})

			client := &http.Client{}
			config := &helper.Config{}
			promise := http.SendRequest(config, rt, client, fetchAndParsePools, cre.ConsensusIdenticalAggregation[*Pool]())

			result, err := promise.Await()

			if tc.expectError {
				require.Error(t, err)
				assert.Contains(t, err.Error(), tc.errorContains)
				assert.Nil(t, result)
			} else {
				require.NoError(t, err)
				assert.Equal(t, tc.expectedPool.Symbol, result.Symbol)
				assert.Equal(t, tc.expectedPool.Apy, result.Apy)
			}
		})
	}
}
