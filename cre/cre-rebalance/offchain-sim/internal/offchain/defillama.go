package offchain

import (
	"bytes"
	"compress/gzip"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/networking/http"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

func getOptimalPool(config *Config, runtime cre.Runtime) (*Pool, error) {
	// Initialize logger and HTTP client
	logger := runtime.Logger()
	client := &http.Client{}

	// Send request to fetch and parse pools
	poolPromise := http.SendRequest(config, runtime, client, fetchAndParsePools, cre.ConsensusIdenticalAggregation[*Pool]())
	returnedPool, err := poolPromise.Await()
	if err != nil {
		return nil, fmt.Errorf("failed to await promise: %w", err)
	}

	// Log and return the highest APY allowed pool
	logger.Info("Got highest APY allowed pool", slog.Any("pool", returnedPool))
	return &Pool{
		Chain:   returnedPool.Chain,
		Project: returnedPool.Project,
		Symbol:  returnedPool.Symbol,
		Apy:     returnedPool.Apy,
	}, nil
}

func fetchAndParsePools(config *Config, logger *slog.Logger, sendRequester *http.SendRequester) (*Pool, error) {
	// Create DefiLlama API request
	defiLlamaAPIRequest := &http.Request{
		Url:     DefiLlamaAPIUrl,
		Method:  "GET",
		Headers: map[string]string{"Accept-Encoding": "gzip"},
	}

	// Send request and await response
	defiLlamaAPIResponse, err := sendRequester.SendRequest(defiLlamaAPIRequest).Await()
	logger.Info("DefiLlama API response result", "response", defiLlamaAPIResponse.StatusCode)
	if defiLlamaAPIResponse.StatusCode != 200 {
		return nil, fmt.Errorf("failed to get API OK response: %d", defiLlamaAPIResponse.StatusCode)
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get API response: %w", err)
	}

	// Handle gzip encoding
	var body []byte
	if encoding, ok := defiLlamaAPIResponse.Headers["Content-Encoding"]; ok && encoding == "gzip" {
		reader, err := gzip.NewReader(bytes.NewReader(defiLlamaAPIResponse.Body))
		if err != nil {
			return nil, fmt.Errorf("failed to create gzip reader: %w", err)
		}
		defer reader.Close()
		body, err = io.ReadAll(reader)
		if err != nil {
			return nil, fmt.Errorf("failed to decompress body: %w", err)
		}
	} else {
		body = defiLlamaAPIResponse.Body
	}

	// Unmarshal JSON response
	var apiResponse APIResponse
	error := json.Unmarshal(body, &apiResponse)
	if error != nil {
		return nil, fmt.Errorf("error unmarshaling JSON: %w", error)
	}

	// Find highest APY pool among allowed pools (by symbol, chain, project)
	var maxApy float64 = -1
	var selectedPool *Pool
	for _, pool := range apiResponse.Data {
		if AllowedSymbol[pool.Symbol] && AllowedChain[pool.Chain] && AllowedProject[pool.Project] && pool.Apy > maxApy {
			maxApy = pool.Apy
			selectedPool = &Pool{
				Chain:   pool.Chain,
				Project: pool.Project,
				Symbol:  pool.Symbol,
				Apy:     pool.Apy,
			}
		}
	}

	// Return the selected pool or an error if none found
	if selectedPool == nil {
		return nil, fmt.Errorf("no approved strategy pool found")
	}
	return selectedPool, nil
}
