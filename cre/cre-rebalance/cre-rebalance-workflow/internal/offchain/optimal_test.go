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

func TestGetOptimalStrategy_TableDriven(t *testing.T) {
	// 1. Force-reset global maps to known values for this test suite
	// This ensures we aren't relying on whatever happens to be in allowed.go
	// AllowedSymbol = map[string]bool{"USDC": true}
	// AllowedProject = map[string]bool{"aave-v3": true}
	// AllowedChain = map[string]bool{
	//     "Ethereum": true,
	//     "Arbitrum": true,
	//     "Base":     true,
	//     "Optimism": true,
	//     "Solana":   true, // Needed for the failure case
	// }
	AllowedChain["Solana"] = true
	defer delete(AllowedChain, "Solana") // Clean up when the test finishes!

	tests := []struct {
		name                  string
		mockJson              string
		expectCapabilityError bool
		expectError           bool
		errorContains         string
		expectedChain         uint64
	}{
		{
			name: "Success - Ethereum",
			// Notice: project is now "aave-v3" to match allowed.go
			mockJson:      `{"data": [{"symbol": "USDC", "chain": "Ethereum", "project": "aave-v3", "apy": 10.0}]}`,
			expectedChain: 5009297550715157269,
		},
		{
			name:          "Success - Arbitrum Strategy",
			mockJson:      `{"data": [{"symbol": "USDC", "chain": "Arbitrum", "project": "aave-v3", "apy": 12.0}]}`,
			expectError:   false,
			expectedChain: 4949039107694359620,
		},
		{
			name:          "Success - Base Strategy",
			mockJson:      `{"data": [{"symbol": "USDC", "chain": "Base", "project": "aave-v3", "apy": 14.5}]}`,
			expectError:   false,
			expectedChain: 15971525489660198786,
		},
		{
			name:          "Success - Optimism Strategy",
			mockJson:      `{"data": [{"symbol": "USDC", "chain": "Optimism", "project": "aave-v3", "apy": 11.0}]}`,
			expectError:   false,
			expectedChain: 3734403246176062136,
		},
		{
			name:                  "Failure - Network/Capability Error",
			expectCapabilityError: true,
			expectError:           true,
			errorContains:         "failed to get API response",
		},
		{
			name:          "Failure - No Pool Found (Wrong Symbol)",
			mockJson:      `{"data": [{"symbol": "LINK", "chain": "Ethereum", "project": "aave-v3", "apy": 5.0}]}`,
			expectError:   true,
			errorContains: "no approved strategy pool found",
		},
		{
			name:          "Failure - Unsupported Chain (Solana is allowed but no selector exists)",
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
