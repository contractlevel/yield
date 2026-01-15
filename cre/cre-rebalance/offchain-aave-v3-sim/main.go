//go:build wasip1

package main

import (
	"fmt"
	"log/slog"

	"encoding/json"

	"time"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/networking/http"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/wasm"

	"google.golang.org/protobuf/types/known/durationpb"
)

// NOTE: Used to run a simulation of the offchain Aave V3 APY fetching workflow

/*//////////////////////////////////////////////////////////////
                         VARS & CONSTS
//////////////////////////////////////////////////////////////*/

const (
	// Aave V3 API URL
	AaveV3ApiUrl string = "https://api.v3.aave.com/graphql"

	// HTTP Status OK code
	StatusOK uint32 = 200

	// GraphQL Query - raw string literal (backticks) for cleaner multi-line strings
	query = `
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
)

/*//////////////////////////////////////////////////////////////
                             TYPES
//////////////////////////////////////////////////////////////*/

// Structs for Aave V3 GraphQL Response
type AaveResponse struct {
	Data struct {
		EthereumUSDC Reserve `json:"ethereum_usdc"`
		ArbitrumUSDC Reserve `json:"arbitrum_usdc"`
		BaseUSDC     Reserve `json:"base_usdc"`
		OptimismUSDC Reserve `json:"optimism_usdc"`
	} `json:"data"`
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

// Struct for the Function Result
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

// Workflow configuration loaded from the config.json file
type Config struct{}

/*//////////////////////////////////////////////////////////////
                         QUERY FUNCTION
//////////////////////////////////////////////////////////////*/

func fetchAaveAPYs(config *Config, logger *slog.Logger, sendRequester *http.SendRequester) (*AaveAPYs, error) {
	// 1. Prepare JSON Body
	reqBody := GraphQLRequest{Query: query}
	jsonBody, err := json.Marshal(reqBody)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal graphql query: %w", err)
	}

	// 2. Construct the Request
	// Note: We use CacheSettings with Store: true.
	// This ensures only one node in the DON actually calls the Aave API,
	// and the result is shared with others.
	req := &http.Request{
		Url:    "https://api.v3.aave.com/graphql",
		Method: "POST",
		Body:   jsonBody,
		Headers: map[string]string{
			"Content-Type": "application/json",
		},
		CacheSettings: &http.CacheSettings{
			Store:  true,
			MaxAge: durationpb.New(30 * time.Second), // Reuse data if fetched within last 30s
		},
	}

	// 3. Send Request & Await Response
	resp, err := sendRequester.SendRequest(req).Await()
	if err != nil {
		return nil, fmt.Errorf("http request failed: %w", err)
	}

	// 4. Check Status Code
	if resp.StatusCode != StatusOK {
		return nil, fmt.Errorf("unexpected status code: %d, body: %s", resp.StatusCode, string(resp.Body))
	}

	// 5. Parse Response
	var aaveResp AaveResponse
	if err := json.Unmarshal(resp.Body, &aaveResp); err != nil {
		return nil, fmt.Errorf("failed to unmarshal response: %w", err)
	}

	// 6. Extract & Return relevant data
	return &AaveAPYs{
		Ethereum: aaveResp.Data.EthereumUSDC.SupplyInfo.APY.Formatted,
		Arbitrum: aaveResp.Data.ArbitrumUSDC.SupplyInfo.APY.Formatted,
		Base:     aaveResp.Data.BaseUSDC.SupplyInfo.APY.Formatted,
		Optimism: aaveResp.Data.OptimismUSDC.SupplyInfo.APY.Formatted,
	}, nil
}

/*//////////////////////////////////////////////////////////////
                    WORKFLOW SETUP & HANDLER
//////////////////////////////////////////////////////////////*/

// Workflow init
func InitWorkflow(config *Config, logger *slog.Logger, secretsProvider cre.SecretsProvider) (cre.Workflow[*Config], error) {
	// Create the trigger
	cronTrigger := cron.Trigger(&cron.Config{Schedule: "*/30 * * * * *"}) // Fires every 30 seconds

	// Register a handler with the trigger and a callback function
	return cre.Workflow[*Config]{
		cre.Handler(cronTrigger, onCronTrigger),
	}, nil
}

// Cron trigger callback
func onCronTrigger(config *Config, runtime cre.Runtime, trigger *cron.Payload) (*AaveAPYs, error) {
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

func main() {
	wasm.NewRunner(cre.ParseJSON[Config]).Run(InitWorkflow)
}
