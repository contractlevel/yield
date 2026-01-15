//go:build wasip1

package main

import (
	"bytes"
	"compress/gzip"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"strings"

	"github.com/ethereum/go-ethereum/crypto"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/networking/http"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/wasm"
)

// NOTE: Used to run a simulation of the offchain DefiLlama optimal strategy selection

/*//////////////////////////////////////////////////////////////
                         VARS & CONSTS
//////////////////////////////////////////////////////////////*/

// Allowed chains, projects and symbols for DefiLlama pools
var AllowedChain = map[string]bool{
	"Ethereum": true,
	"Arbitrum": true,
	"Base":     true,
	"Optimism": true,
}

var AllowedProject = map[string]bool{
	"aave-v3":     true,
	"compound-v3": true,
}

var AllowedSymbol = map[string]bool{
	"USDC": true,
}

const (
	// DefiLlama API URL
	DefiLlamaApiUrl string = "https://yields.llama.fi/pools"

	// HTTP Status OK code
	StatusOK uint32 = 200
)

/*//////////////////////////////////////////////////////////////
                             TYPES
//////////////////////////////////////////////////////////////*/

// Strategy pool fetched from DefiLlama
type Pool struct {
	Chain   string  `json:"chain"`
	Project string  `json:"project"`
	Symbol  string  `json:"symbol"`
	Apy     float64 `json:"apy"`
}

// DefiLlama API response structure -
type APIResponse struct {
	Data []Pool `json:"data"`
}

// Types used in workflow configuration - should be deleted after moved to real workflow internal
type Config struct {
	Schedule string `json:"schedule"`
}

type Strategy struct {
	ProtocolId    [32]byte
	ChainSelector uint64
}

/*//////////////////////////////////////////////////////////////
             'OPTIMAL.GO' FUNCTIONS IN OFFCHAIN PKG
//////////////////////////////////////////////////////////////*/

// Public func that gets the optimal pool from DefiLlama and transforms it into an on-chain Strategy
func GetOptimalStrategy(config *Config, runtime cre.Runtime) (*Strategy, error) {
	// 1. Get the optimal pool from off-chain
	pool, err := getBestPool(config, runtime)
	if err != nil {
		return nil, fmt.Errorf("failed to get optimal strategy: %w", err)
	}

	// 2. Transform the pool into an on-chain Strategy
	var protocolId [32]byte
	hash := crypto.Keccak256([]byte(pool.Project))
	copy(protocolId[:], hash)

	chainSelector, err := chainSelectorFromChainName(pool.Chain)
	if err != nil {
		// @review not sure of this error name
		return nil, fmt.Errorf("invalid strategy configuration: %w", err)
	}

	// 3. Return the strategy
	return &Strategy{
		ProtocolId:    protocolId,
		ChainSelector: chainSelector,
	}, nil
}

// @review better to have a mapping or is this a shared func we can use elsewhere?
// Helper function to get chain selector from chain name
func chainSelectorFromChainName(chainName string) (uint64, error) {
	switch chainName {
	case "Arbitrum":
		return 4949039107694359620, nil
	case "Base":
		return 15971525489660198786, nil
	case "Ethereum":
		return 5009297550715157269, nil
	case "Optimism":
		return 3734403246176062136, nil
	default:
		return 0, fmt.Errorf("chain selector not found for: %s", chainName)
	}
}

/*//////////////////////////////////////////////////////////////
            'DEFILLAMA.GO' FUNCTIONS IN OFFCHAIN PKG
//////////////////////////////////////////////////////////////*/

// Gets highest APY approved pool from DefiLlama via CRE HTTP capability
func getBestPool(config *Config, runtime cre.Runtime) (*Pool, error) {
	// Initialize logger and HTTP client
	logger := runtime.Logger()
	client := &http.Client{}

	// Send the request via CRE HTTP capability
	// CRE consensus: identical aggregation ensures all nodes agree on the same pool
	poolPromise := http.SendRequest(config, runtime, client, fetchAndParsePools, cre.ConsensusIdenticalAggregation[*Pool]())
	returnedPool, err := poolPromise.Await()
	if err != nil {
		return nil, fmt.Errorf("failed to await promise: %w", err)
	}

	// Log and return pool
	logger.Info("Got highest APY allowed pool", slog.Any("pool", returnedPool))
	return returnedPool, nil
}

// Fetching func passed into HTTP capability to perform the data retrieval and parsing
// Performs token-based streaming for minimal memory usage
func fetchAndParsePools(config *Config, logger *slog.Logger, sendRequester *http.SendRequester) (*Pool, error) {
	// Initialize HTTP request
	req := &http.Request{
		Url:     DefiLlamaApiUrl,
		Method:  "GET",
		Headers: map[string]string{"Accept-Encoding": "gzip"},
	}

	// Send request and check response
	resp, err := sendRequester.SendRequest(req).Await()
	if err != nil {
		return nil, fmt.Errorf("failed to get API response: %w", err)
	}
	if resp.StatusCode != StatusOK {
		return nil, fmt.Errorf("failed to get OK response: %d", resp.StatusCode)
	}

	// PROCESS RESPONSE
	// - 1. Set up the response reading pipeline (Body -> Gzip Wrapper -> JSON Decoder)
	var reader io.Reader = bytes.NewReader(resp.Body)

	// - Header Check: Headers can be lowercase or Title-Case
	isGzipped := false
	for k, v := range resp.Headers {
		if strings.EqualFold(k, "Content-Encoding") && strings.Contains(strings.ToLower(v), "gzip") {
			isGzipped = true
			break
		}
	}

	// - Gzip Wrapper: Wrap the reader in a gzip reader if needed
	if isGzipped {
		gz, err := gzip.NewReader(reader)
		if err != nil {
			return nil, fmt.Errorf("failed to create gzip reader: %w", err)
		}
		defer gz.Close()
		reader = gz
	}

	// - Create JSON Decoder
	decoder := json.NewDecoder(reader)

	// - 2. Token-based Navigation: Find the "data" key without loading the whole object
	foundData := false
	for {
		t, err := decoder.Token()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, fmt.Errorf("error decoding JSON stream: %w", err)
		}

		// Look for the key "data"
		if key, ok := t.(string); ok && strings.EqualFold(key, "data") {
			foundData = true
			break
		}
	}

	if !foundData {
		return nil, fmt.Errorf("could not find 'data' key in response")
	}

	// - 3. Ensure the next token is the start of an array '['
	t, err := decoder.Token()
	if err != nil {
		return nil, fmt.Errorf("error reading array start: %w", err)
	}
	if delim, ok := t.(json.Delim); !ok || delim != '[' {
		return nil, fmt.Errorf("expected array start after 'data' key")
	}

	// - 4. Streaming Loop: Decode one pool at a time
	var selectedPool *Pool
	var maxApy float64 = 0.0

	for decoder.More() {
		var p Pool
		if err := decoder.Decode(&p); err != nil {
			return nil, fmt.Errorf("error decoding pool item: %w", err)
		}

		// Filter and compare immediately
		if AllowedSymbol[p.Symbol] &&
			AllowedProject[p.Project] &&
			AllowedChain[p.Chain] &&
			p.Apy > maxApy {

			maxApy = p.Apy
			winner := p // Only copy the "winner" pool to the heap
			selectedPool = &winner
		}
	}

	// Check if an approved pool found
	if selectedPool == nil {
		return nil, fmt.Errorf("no approved strategy pool found")
	}

	// Return selected pool
	return selectedPool, nil
}

/*//////////////////////////////////////////////////////////////
                    WORKFLOW SETUP & HANDLER
//////////////////////////////////////////////////////////////*/

func InitWorkflow(config *Config, logger *slog.Logger, secretsProvider cre.SecretsProvider) (cre.Workflow[*Config], error) {
	cronTrigger := cron.Trigger(&cron.Config{Schedule: config.Schedule})

	return cre.Workflow[*Config]{
		cre.Handler(cronTrigger, onCronTrigger),
	}, nil
}

func onCronTrigger(config *Config, runtime cre.Runtime, trigger *cron.Payload) (*Strategy, error) {
	logger := runtime.Logger()

	logger.Info("Getting optimal strategy from defillama")
	strategy, err := GetOptimalStrategy(config, runtime)

	if strategy == nil {
		return nil, fmt.Errorf("no optimal strategy found")
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get optimal strategy: %w", err)
	}

	return strategy, nil
}

func main() {
	wasm.NewRunner(cre.ParseJSON[Config]).Run(InitWorkflow)
}
