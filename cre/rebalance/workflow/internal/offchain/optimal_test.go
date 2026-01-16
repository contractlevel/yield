package offchain

import (
	"context"
	"testing"

	"rebalance/workflow/internal/helper"

	"github.com/smartcontractkit/chainlink-protos/cre/go/sdk"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/networking/http"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils/registry"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/types/known/anypb"
)

// --- UNIT TESTS: GetOptimalStrategy ---

func Test_offchain_GetOptimalStrategy(t *testing.T) {
	// Setup: Temporarily allow a chain that exists in the data but might not have a selector mapping
	// to test the "Unsupported Chain" error path logic.
	AllowedChain["Solana"] = true
	defer delete(AllowedChain, "Solana")

	// Chainlink CCIP Selectors
	const (
		arbitrumSelector uint64 = 4949039107694359620
		baseSelector     uint64 = 15971525489660198786
		ethereumSelector uint64 = 5009297550715157269
		optimismSelector uint64 = 3734403246176062136
	)

	tests := []struct {
		name                  string
		mockJson              string
		expectCapabilityError bool
		expectError           bool
		errorContains         string
		expectedChain         uint64
	}{
		// 1. SUCCESS PATHS: Verifying correct Chain Selector mapping
		{
			name:          "Success: Arbitrum selection",
			mockJson:      `{"data": [{"symbol": "USDC", "chain": "Arbitrum", "project": "aave-v3", "apy": 12.0}]}`,
			expectedChain: arbitrumSelector,
		},
		{
			name:          "Success: Base selection",
			mockJson:      `{"data": [{"symbol": "USDC", "chain": "Base", "project": "compound-v3", "apy": 14.5}]}`,
			expectedChain: baseSelector,
		},
		{
			name:          "Success: Ethereum selection",
			mockJson:      `{"data": [{"symbol": "USDC", "chain": "Ethereum", "project": "aave-v3", "apy": 10.0}]}`,
			expectedChain: ethereumSelector,
		},
		{
			name:          "Success: Optimism selection",
			mockJson:      `{"data": [{"symbol": "USDC", "chain": "Optimism", "project": "compound-v3", "apy": 11.0}]}`,
			expectedChain: optimismSelector,
		},

		// 2. ERROR PATHS: Networking and Capability failures
		{
			name:                  "Error: HTTP Capability failure",
			expectCapabilityError: true,
			expectError:           true,
			errorContains:         "failed to get API response",
		},

		// 3. ERROR PATHS: Logic and Mapping failures
		{
			name:          "Error: No strategy found (Filtered by symbol)",
			mockJson:      `{"data": [{"symbol": "LINK", "chain": "Ethereum", "project": "aave-v3", "apy": 5.0}]}`,
			expectError:   true,
			errorContains: "no approved strategy pool found",
		},
		{
			name:          "Error: Chain exists in data but lacks CCIP selector mapping",
			mockJson:      `{"data": [{"symbol": "USDC", "chain": "Solana", "project": "aave-v3", "apy": 20.0}]}`,
			expectError:   true,
			errorContains: "chain selector not found for: Solana",
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			// Initialize Registry and Runtime
			rt := testutils.NewRuntime(t, nil)

			// Register Mock HTTP Capability
			registry.GetRegistry(t).RegisterCapability(&mockHttpCapability{
				id: "http-actions@1.0.0-alpha",
				fn: func(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse {
					// Simulate capability-level error if specified
					if tc.expectCapabilityError {
						return &sdk.CapabilityResponse{Response: &sdk.CapabilityResponse_Error{Error: "mock failure"}}
					}

					// Otherwise, return the mock JSON response
					mockResp := &http.Response{StatusCode: StatusOK, Body: []byte(tc.mockJson)}
					respAny, _ := anypb.New(mockResp)
					return &sdk.CapabilityResponse{Response: &sdk.CapabilityResponse_Payload{Payload: respAny}}
				},
			})

			// Execute function under test
			strategy, err := GetOptimalStrategy(&helper.Config{}, rt)

			// Validation
			if tc.expectError {
				require.Error(t, err)
				assert.Contains(t, err.Error(), tc.errorContains)
				assert.Nil(t, strategy)
			} else {
				require.NoError(t, err)
				require.NotNil(t, strategy)
				assert.Equal(t, tc.expectedChain, strategy.ChainSelector)
				assert.NotEqual(t, [32]byte{}, strategy.ProtocolId)
			}
		})
	}
}
