package offchain

import (
	"bytes"
	"compress/gzip"
	"context"
	"encoding/json"
	"math"
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

/* MOCK & HELPERS */

// Mock HTTP capability for testing
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

/* UNIT TESTS */
func Test_offchain_getBestPool(t *testing.T) {
	tests := []struct {
		name           string
		mockFn         func(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse
		expectError    bool
		errorContains  string
		expectedSymbol string
	}{
		{
			name: "success",
			mockFn: func(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse {
				respAny, _ := anypb.New(&http.Response{
					StatusCode: StatusOK,
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
			name: "errorWhen_promiseReturnsError",
			mockFn: func(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse {
				return &sdk.CapabilityResponse{
					Response: &sdk.CapabilityResponse_Error{Error: "network unreachable"},
				}
			},
			expectError:   true,
			errorContains: "failed to await promise",
		},
		{
			name: "errorWhen_promiseReturnsNilPool",
			mockFn: func(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse {
				respAny, _ := anypb.New(&http.Response{
					StatusCode: StatusOK,
					Body:       []byte(`{"data": []}`),
				})
				return &sdk.CapabilityResponse{
					Response: &sdk.CapabilityResponse_Payload{Payload: respAny},
				}
			},
			expectError: true,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			rt := testutils.NewRuntime(t, nil)
			config := &helper.Config{}

			registry.GetRegistry(t).RegisterCapability(&mockHttpCapability{
				id: "http-actions@1.0.0-alpha",
				fn: tc.mockFn,
			})

			result, err := getBestPool(config, rt)

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

func Test_offchain_fetchAndParsePools(t *testing.T) {
	var serverError uint32 = 500

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
			name:         "successWhen_standardJSON",
			statusCode:   StatusOK,
			body:         []byte(`{"data": [{"symbol": "USDC", "chain": "Ethereum", "project": "aave-v3", "apy": 5.5}]}`),
			expectError:  false,
			expectedPool: &Pool{Symbol: "USDC", Apy: 5.5},
		},
		{
			name:         "successWhen_gzippedJSON",
			statusCode:   StatusOK,
			headers:      map[string]string{"Content-Encoding": "gzip"},
			body:         compressGzip(`{"data": [{"symbol": "USDC", "chain": "Ethereum", "project": "aave-v3", "apy": 12.5}]}`),
			expectError:  false,
			expectedPool: &Pool{Symbol: "USDC", Apy: 12.5},
		},
		{
			name:         "successWhen_gzippedJSON_lowercaseHeader",
			statusCode:   StatusOK,
			headers:      map[string]string{"content-encoding": "gzip"},
			body:         compressGzip(`{"data": [{"symbol": "USDC", "chain": "Ethereum", "project": "aave-v3", "apy": 9.0}]}`),
			expectError:  false,
			expectedPool: &Pool{Symbol: "USDC", Apy: 9.0},
		},
		{
			name:          "errorWhen_httpError",
			statusCode:    serverError,
			body:          []byte(`Internal Server Error`),
			expectError:   true,
			errorContains: "failed to get OK response: 500",
		},
		{
			name:          "errorWhen_invalidJSONFormat",
			statusCode:    StatusOK,
			body:          []byte(`{"data": [{"apy": "not-a-number"}]}`),
			expectError:   true,
			errorContains: "error decoding pool item",
		},
		{
			name:          "errorWhen_noAllowedPoolsFound",
			statusCode:    StatusOK,
			body:          []byte(`{"data": [{"symbol": "SHIB", "chain": "DogeChain", "project": "MemeSwap", "apy": 999}]}`),
			expectError:   true,
			errorContains: "no approved strategy pool found",
		},
		{
			name:                  "errorWhen_noApiResponse",
			expectCapabilityError: true,
			expectError:           true,
			errorContains:         "failed to get API response",
		},
		{
			name:          "errorWhen_malformedGzipHeader",
			statusCode:    StatusOK,
			headers:       map[string]string{"Content-Encoding": "gzip"},
			body:          []byte("not gzipped data"),
			expectError:   true,
			errorContains: "failed to create gzip reader",
		},
		{
			name:          "errorWhen_corruptGzipBody",
			statusCode:    StatusOK,
			headers:       map[string]string{"Content-Encoding": "gzip"},
			body:          compressGzip(`{"data": [ {"symbol": "USDC"`),
			expectError:   true,
			errorContains: "error decoding pool item",
		},
		{
			name:          "errorWhen_missingDataKey",
			statusCode:    StatusOK,
			body:          []byte(`{"metadata": "none"}`),
			expectError:   true,
			errorContains: "could not find 'data' key",
		},
		{
			name:          "errorWhen_dataIsNotAnArray",
			statusCode:    StatusOK,
			body:          []byte(`{"data": "invalid"}`),
			expectError:   true,
			errorContains: "expected array start after 'data' key",
		},
		{
			name:          "errorWhen_malformedJSONInStream",
			statusCode:    StatusOK,
			body:          []byte(`{"data": [ {`), // Ends abruptly after object start
			expectError:   true,
			errorContains: "error decoding pool item",
		},
		{
			name:          "errorWhen_syntaxErrorInTokenStream",
			statusCode:    StatusOK,
			body:          []byte(`{"data": [123, @]}`),
			expectError:   true,
			errorContains: "error decoding pool item",
		},
		{
			name:          "errorWhen_syntaxErrorBeforeDataKey",
			statusCode:    StatusOK,
			body:          []byte(`{ "metadata": @@@ }`), // @ is invalid JSON syntax
			expectError:   true,
			errorContains: "error decoding JSON stream",
		},
		{
			name:          "errorWhen_streamEndsAfterDataKey",
			statusCode:    StatusOK,
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

func Fuzz_offchain_fetchAndParsePools(f *testing.F) {
	// Seed: f.Add must match the (t, []byte, []byte) signature
	f.Add([]byte{0}, []byte(`{"data": [{"symbol": "USDC", "chain": "Ethereum", "project": "aave-v3", "apy": 5.5}]}`))
	f.Add([]byte{1}, []byte(`{"data": []}`))

	f.Fuzz(func(t *testing.T, control []byte, payload []byte) {
		// 1. Setup Environment
		if len(control) == 0 {
			return
		}
		rt := testutils.NewRuntime(t, nil)

		var finalBody []byte
		headers := make(map[string]string)

		// Decide path: 0 = Plain, 1 = Gzip (or any even/odd byte)
		isGzip := control[0]%2 == 0
		if isGzip {
			headers["Content-Encoding"] = "gzip"
			finalBody = compressGzip(string(payload)) // Using helper
		} else {
			finalBody = payload
		}

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

		// 2. Execute
		promise := http.SendRequest(&helper.Config{}, rt, &http.Client{}, fetchAndParsePools, cre.ConsensusIdenticalAggregation[*Pool]())
		result, err := promise.Await()

		// 3. INLINE INVARIANTS
		if err == nil && result != nil {
			// Whitelist Invariant
			if !AllowedChain[result.Chain] || !AllowedProject[result.Project] || !AllowedSymbol[result.Symbol] {
				t.Errorf("Security Violation: Result contained disallowed values: %+v", result)
			}

			// Math Invariant
			if math.IsNaN(result.Apy) || math.IsInf(result.Apy, 0) || result.Apy < -1.0 {
				t.Errorf("Math Error: Invalid APY detected: %f", result.Apy)
			}
		}

		// 4. DIFFERENTIAL INVARIANT (Cross-check)
		if err == nil {
			var wrapper struct{ Data []Pool }
			// We always compare against the raw 'payload', NOT the 'finalBody'
			if json.Unmarshal(payload, &wrapper) == nil {
				var best *Pool
				max := -1.0
				for _, p := range wrapper.Data {
					if AllowedChain[p.Chain] && AllowedProject[p.Project] && AllowedSymbol[p.Symbol] && p.Apy > max {
						max = p.Apy
						best = &p
					}
				}

				// Check if parser and manual loop agree on "winner" presence
				if (result == nil) != (best == nil) {
					t.Errorf("Visibility Mismatch: Parser result exists=%v, Manual loop result exists=%v", result != nil, best != nil)
				} else if result != nil && best != nil && result.Apy != best.Apy {
					t.Errorf("Logic Mismatch: Parser picked %f, Manual loop found %f", result.Apy, best.Apy)
				}
			}
		}
	})
}
