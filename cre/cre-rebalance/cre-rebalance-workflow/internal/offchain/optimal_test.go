package offchain

import (
	"context"
	"testing"

	"cre-rebalance/cre-rebalance-workflow/internal/helper"

	"github.com/smartcontractkit/chainlink-protos/cre/go/sdk"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/networking/http"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils/registry"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/types/known/anypb"
)

func Test_offchain_GetOptimalStrategy(t *testing.T) {
	AllowedChain["Solana"] = true        // Temporarily allow Solana for this test
	defer delete(AllowedChain, "Solana") // Clean up when the test finishes!

	var arbitrumSelector uint64 = 4949039107694359620
	var baseSelector uint64 = 15971525489660198786
	var ethereumSelector uint64 = 5009297550715157269
	var optimismSelector uint64 = 3734403246176062136

	tests := []struct {
		name                  string
		mockJson              string
		expectCapabilityError bool
		expectError           bool
		errorContains         string
		expectedChain         uint64
	}{
		{
			name:          "aribitrum_success",
			mockJson:      `{"data": [{"symbol": "USDC", "chain": "Arbitrum", "project": "aave-v3", "apy": 12.0}]}`,
			expectError:   false,
			expectedChain: arbitrumSelector,
		},
		{
			name:          "base_success",
			mockJson:      `{"data": [{"symbol": "USDC", "chain": "Base", "project": "compound-v3", "apy": 14.5}]}`,
			expectError:   false,
			expectedChain: baseSelector,
		},
		{
			name:          "ethereum_success",
			mockJson:      `{"data": [{"symbol": "USDC", "chain": "Ethereum", "project": "aave-v3", "apy": 10.0}]}`,
			expectError:   false,
			expectedChain: ethereumSelector,
		},
		{
			name:          "optimism_success",
			mockJson:      `{"data": [{"symbol": "USDC", "chain": "Optimism", "project": "compound-v3", "apy": 11.0}]}`,
			expectError:   false,
			expectedChain: optimismSelector,
		},
		{
			name:                  "errorWhen_noApiResponse",
			expectCapabilityError: true,
			expectError:           true,
			errorContains:         "failed to get API response",
		},
		{
			name:          "errorWhen_failedToGetStrategy",
			mockJson:      `{"data": [{"symbol": "LINK", "chain": "Ethereum", "project": "aave-v3", "apy": 5.0}]}`,
			expectError:   true,
			errorContains: "failed to get optimal strategy: failed to await promise: no approved strategy pool found",
		},
		{
			name:          "errorWhen_unsupportedChain",
			mockJson:      `{"data": [{"symbol": "USDC", "chain": "Solana", "project": "aave-v3", "apy": 20.0}]}`,
			expectError:   true,
			errorContains: "invalid strategy configuration: chain selector not found for: Solana",
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
							Response: &sdk.CapabilityResponse_Error{Error: "mock failure"},
						}
					}
					mockResp := &http.Response{StatusCode: 200, Body: []byte(tc.mockJson)}
					respAny, _ := anypb.New(mockResp)
					return &sdk.CapabilityResponse{Response: &sdk.CapabilityResponse_Payload{Payload: respAny}}
				},
			})

			strategy, err := GetOptimalStrategy(&helper.Config{}, rt)

			if tc.expectError {
				require.Error(t, err)
				assert.Contains(t, err.Error(), tc.errorContains)
			} else {
				require.NoError(t, err)
				assert.Equal(t, tc.expectedChain, strategy.ChainSelector)
				assert.NotEqual(t, [32]byte{}, strategy.ProtocolId)
			}
		})
	}
}
