package offchain

import (
	"bytes"
	"compress/gzip"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"rebalance/workflow/internal/helper"
	"strings"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/networking/http"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// Gets highest APY approved pool from DefiLlama via CRE HTTP capability
func getBestPool(config *helper.Config, runtime cre.Runtime) (*Pool, error) {
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
func fetchAndParsePools(config *helper.Config, logger *slog.Logger, sendRequester *http.SendRequester) (*Pool, error) {
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
