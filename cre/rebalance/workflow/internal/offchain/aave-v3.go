package offchain

import (
	"log/slog"
	"rebalance/workflow/internal/helper"

	"encoding/json"
	"fmt"
	"time"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/networking/http"
	"github.com/smartcontractkit/cre-sdk-go/cre"

	"google.golang.org/protobuf/types/known/durationpb"
)

// --- Aave V3 Vars ---
// Aave V3 API URL
const AaveV3ApiUrl string = "https://api.v3.aave.com/graphql"

// GraphQL query to fetch USDC APYs from Aave V3 across multiple chains
const AaveV3Query string = `
	query GetUSDC_APYs {
	  ethereum_usdc: reserve(request: {chainId: 1, market: "0x87870bca3f3fd6335c3f4ce8392d69350b4fa4e2", underlyingToken: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"}) { ...ReserveFields }
	  arbitrum_usdc: reserve(request: {chainId: 42161, market: "0x794a61358D6845594F94dc1DB02A252b5b4814aD", underlyingToken: "0xaf88d065e77c8cC2239327C5EDb3A432268e5831"}) { ...ReserveFields }
	  base_usdc: reserve(request: {chainId: 8453, market: "0xA238Dd80C259a72e81d7e4664a9801593F98d1c5", underlyingToken: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"}) { ...ReserveFields }
	  optimism_usdc: reserve(request: {chainId: 10, market: "0x794a61358D6845594F94dc1DB02A252b5b4814aD", underlyingToken: "0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85"}) { ...ReserveFields }
	}

	fragment ReserveFields on Reserve {
	  underlyingToken { symbol name }
	  supplyInfo { apy { formatted } }
	}
	`

// --- Aave V3 Structs ---
type AaveResponse struct {
	Data struct {
		EthereumUSDC Reserve `json:"ethereum_usdc"`
		ArbitrumUSDC Reserve `json:"arbitrum_usdc"`
		BaseUSDC     Reserve `json:"base_usdc"`
		OptimismUSDC Reserve `json:"optimism_usdc"`
	} `json:"data"`

	// Standard GraphQL error array
	Errors []struct {
		Message string `json:"message"`
	} `json:"errors"`
}

type Reserve struct {
	UnderlyingToken Token      `json:"underlyingToken"`
	SupplyInfo      SupplyInfo `json:"supplyInfo"`
}

type Token struct {
	Symbol string `json:"symbol"`
	Name   string `json:"name"`
}

type SupplyInfo struct {
	APY APY `json:"apy"`
}

type APY struct {
	Formatted string `json:"formatted"`
}

// AaveAPYs is the struct we will return.
// We use consensus_aggregation:"identical" to ensure all nodes agree on the exact string values.
type AaveAPYs struct {
	Ethereum string `json:"ethereum" consensus_aggregation:"identical"`
	Arbitrum string `json:"arbitrum" consensus_aggregation:"identical"`
	Base     string `json:"base" consensus_aggregation:"identical"`
	Optimism string `json:"optimism" consensus_aggregation:"identical"`
}

// GraphQLRequest represents the payload sent to the server
type GraphQLRequest struct {
	Query string `json:"query"`
}

// --- Funcs ---
func getHighestAaveV3Apys(config *helper.Config, runtime cre.Runtime) (*AaveAPYs, error) {
	logger := runtime.Logger()
	client := &http.Client{}

	// Call the fetch function wrapped in http.SendRequest
	// This handles the consensus aggregation automatically
	promise := http.SendRequest(
		config,
		runtime,
		client,
		fetchAaveAPYs,
		cre.ConsensusAggregationFromTags[*AaveAPYs](),
	)

	// Await the result
	apys, err := promise.Await()
	if err != nil {
		logger.Error("Failed to fetch APYs", "error", err)
		return nil, err
	}

	logger.Info("Fetched Aave USDC APYs",
		"Ethereum", apys.Ethereum,
		"Arbitrum", apys.Arbitrum,
		"Base", apys.Base,
		"Optimism", apys.Optimism,
	)

	// Return the data fetched
	return apys, nil
}

func fetchAaveAPYs(config *helper.Config, logger *slog.Logger, sendRequester *http.SendRequester) (*AaveAPYs, error) {
	// 1. Define the GraphQL Query
	// We use a raw string literal (backticks) for cleaner multi-line strings.

	// 2. Prepare JSON Body
	reqBody := GraphQLRequest{Query: AaveV3Query}
	jsonBody, err := json.Marshal(reqBody)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal graphql query: %w", err)
	}

	// 3. Construct the Request
	// Note: We use CacheSettings with Store: true.
	// This ensures only one node in the DON actually calls the Aave API,
	// and the result is shared with others.
	req := &http.Request{
		Url:    AaveV3ApiUrl,
		Method: "POST",
		Body:   jsonBody,
		Headers: map[string]string{
			"Content-Type": "application/json",
		},
		CacheSettings: &http.CacheSettings{
			Store:  true,
			MaxAge: durationpb.New(60 * time.Second), // Reuse data if fetched within last 30s
		},
	}

	// Helper function to convert string to float64 safely
	// not used at the moment
	// parseAPY := func(s string) float64 {
	// 	val, _ := strconv.ParseFloat(s, 64)
	// 	return val
	// }

	// 4. Send Request & Await Response
	resp, err := sendRequester.SendRequest(req).Await()
	if err != nil {
		// This handles network timeouts, DNS issues, or connection refusals
		return nil, fmt.Errorf("network failure interacting with Aave: %w", err)
	}

	// 5. Check HTTP Status (Transport Layer)
	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("Aave API returned non-200 status: %d", resp.StatusCode)
	}

	// 6. Parse Response
	var aaveResp AaveResponse
	if err := json.Unmarshal(resp.Body, &aaveResp); err != nil {
		return nil, fmt.Errorf("failed to parse JSON response: %w", err)
	}

	// 7. Check GraphQL Errors (Application Layer)
	// This is the critical new step
	if len(aaveResp.Errors) > 0 {
		// Log the first error message to help with debugging
		return nil, fmt.Errorf("Aave GraphQL Error: %s", aaveResp.Errors[0].Message)
	}

	// 8. Validate Data Completeness (Optional but recommended)
	// Ensure we actually got data for the fields we care about
	if aaveResp.Data.EthereumUSDC.SupplyInfo.APY.Formatted == "" {
		return nil, fmt.Errorf("received empty data for Ethereum USDC")
	}

	return &AaveAPYs{
		Ethereum: aaveResp.Data.EthereumUSDC.SupplyInfo.APY.Formatted,
		Arbitrum: aaveResp.Data.ArbitrumUSDC.SupplyInfo.APY.Formatted,
		Base:     aaveResp.Data.BaseUSDC.SupplyInfo.APY.Formatted,
		Optimism: aaveResp.Data.OptimismUSDC.SupplyInfo.APY.Formatted,
	}, nil
}
