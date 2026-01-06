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

// Get the optimal pool from DefiLlama
func getOptimalPool(config *Config, runtime cre.Runtime) (*Pool, error) {
	// Initialize logger and HTTP client
	logger := runtime.Logger()
	client := &http.Client{}

	// Get Promise for pool - CRE consensus: identical aggregation of optimal pool
	poolPromise := http.SendRequest(config, runtime, client, fetchAndParsePools, cre.ConsensusIdenticalAggregation[*Pool]())

	// Await pool Promise result and handle errors
	returnedPool, err := poolPromise.Await()
	if returnedPool == nil {
		return nil, fmt.Errorf("no pool returned from promise")
	}
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

// Fetching func to pass into 'http.SendRequest' to fetch & parse pools for highest allowed APY pool
func fetchAndParsePools(config *Config, logger *slog.Logger, sendRequester *http.SendRequester) (*Pool, error) {
	// Create HTTP header to accept gzip encoding of response
	gzipHeader := map[string]string{"Accept-Encoding": "gzip"}

	// Create DefiLlama API request
	defiLlamaAPIRequest := &http.Request{
		Url:     DefiLlamaAPIUrl,
		Method:  "GET",
		Headers: gzipHeader,
	}

	// Send request and await response
	defiLlamaAPIResponse, err := sendRequester.SendRequest(defiLlamaAPIRequest).Await()

	// Log response status and handle errors
	logger.Info("DefiLlama API response result", "response", defiLlamaAPIResponse.StatusCode)
	if defiLlamaAPIResponse.StatusCode != StatusOK {
		return nil, fmt.Errorf("failed to get API OK response: %d", defiLlamaAPIResponse.StatusCode)
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get API response: %w", err)
	}

	// Handle gzip decompression of response body - if necessary, else use body as is
	var rawRequestBody []byte
	if encoding, ok := defiLlamaAPIResponse.Headers["Content-Encoding"]; ok && encoding == "gzip" {
		// Create gzip reader
		reader, err := gzip.NewReader(bytes.NewReader(defiLlamaAPIResponse.Body))
		if err != nil {
			return nil, fmt.Errorf("failed to create gzip reader: %w", err)
		}

		// Ensure reader is closed after reading
		defer reader.Close()

		// Read decompressed body into rawRequestBody and handle errors
		rawRequestBody, err = io.ReadAll(reader)
		if err != nil {
			return nil, fmt.Errorf("failed to decompress body: %w", err)
		}
	} else {
		rawRequestBody = defiLlamaAPIResponse.Body
	}

	// Unmarshal JSON response into APIResponse struct
	var apiResponse APIResponse
	jsonErr := json.Unmarshal(rawRequestBody, &apiResponse)
	if jsonErr != nil {
		return nil, fmt.Errorf("error unmarshaling JSON: %w", jsonErr)
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

	// Return the selected pool or error if none found
	if selectedPool == nil {
		return nil, fmt.Errorf("no approved strategy pool found")
	}
	return selectedPool, nil
}
