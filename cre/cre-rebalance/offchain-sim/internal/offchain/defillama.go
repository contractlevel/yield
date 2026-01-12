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
	logger := runtime.Logger()
	client := &http.Client{}

	// CRE consensus: identical aggregation of optimal pool
	poolPromise := http.SendRequest(config, runtime, client, fetchAndParsePools, cre.ConsensusIdenticalAggregation[*Pool]())

	returnedPool, err := poolPromise.Await()
	if err != nil {
		return nil, fmt.Errorf("failed to await promise: %w", err)
	}

	logger.Info("Got highest APY allowed pool", slog.Any("pool", returnedPool))

	// Improvement: Return the pointer directly. No need to reconstruct the struct.
	return returnedPool, nil
}

// fetchAndParsePools performs the high-performance token-based streaming.
func fetchAndParsePools(config *Config, logger *slog.Logger, sendRequester *http.SendRequester) (*Pool, error) {
	req := &http.Request{
		Url:     DefiLlamaAPIUrl,
		Method:  "GET",
		Headers: map[string]string{"Accept-Encoding": "gzip"},
	}

	resp, err := sendRequester.SendRequest(req).Await()
	if err != nil {
		return nil, fmt.Errorf("failed to get API response: %w", err)
	}

	if resp.StatusCode != StatusOK {
		return nil, fmt.Errorf("failed to get API OK response: %d", resp.StatusCode)
	}

	// 1. Setup the reading pipeline (Body -> Gzip Wrapper -> JSON Decoder)
	var reader io.Reader = bytes.NewReader(resp.Body)
	if resp.Headers["Content-Encoding"] == "gzip" {
		gz, err := gzip.NewReader(reader)
		if err != nil {
			return nil, fmt.Errorf("failed to create gzip reader: %w", err)
		}
		defer gz.Close()
		reader = gz
	}

	decoder := json.NewDecoder(reader)

	// 2. Token-based Navigation: Find the "data" key without loading the whole object
	// This skips any metadata or top-level fields at zero memory cost.
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
		if key, ok := t.(string); ok && key == "data" {
			foundData = true
			break
		}
	}

	if !foundData {
		return nil, fmt.Errorf("could not find 'data' key in response")
	}

	// 3. Ensure the next token is the start of an array '['
	t, err := decoder.Token()
	if err != nil {
		return nil, fmt.Errorf("error reading array start: %w", err)
	}
	if delim, ok := t.(json.Delim); !ok || delim != '[' {
		return nil, fmt.Errorf("expected array start after 'data' key")
	}

	var selectedPool *Pool
	var maxApy = -1.0

	// 4. THE STREAMING LOOP: Decode one pool at a time
	// This is O(1) memory complexity relative to the size of the pool list.
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
			// Only copy the "winner" to the heap
			winner := p
			selectedPool = &winner
		}
	}

	if selectedPool == nil {
		return nil, fmt.Errorf("no approved strategy pool found")
	}

	return selectedPool, nil
}

/*
// Streaming JSON parsing approach (commented out for reference)
func fetchAndParsePools(config *Config, logger *slog.Logger, sendRequester *http.SendRequester) (*Pool, error) {
	req := &http.Request{
		Url:     DefiLlamaAPIUrl,
		Method:  "GET",
		Headers: map[string]string{"Accept-Encoding": "gzip"},
	}

	resp, err := sendRequester.SendRequest(req).Await()
	if err != nil {
		return nil, fmt.Errorf("failed to get API response: %w", err)
	}

	logger.Info("DefiLlama API response", "status", resp.StatusCode)

	if resp.StatusCode != StatusOK {
		return nil, fmt.Errorf("failed to get API OK response: %d", resp.StatusCode)
	}

	// Initialize the reader with the response body
	var reader io.Reader = bytes.NewReader(resp.Body)

	// Wrap with gzip if necessary
	if resp.Headers["Content-Encoding"] == "gzip" {
		gz, err := gzip.NewReader(reader)
		if err != nil {
			return nil, fmt.Errorf("failed to create gzip reader: %w", err)
		}
		defer gz.Close()
		reader = gz
	}

	// STREAMING DECODE: Instead of loading all bytes into memory first,
	// we decode directly from the reader stream.
	var apiResponse APIResponse
	if err := json.NewDecoder(reader).Decode(&apiResponse); err != nil {
		return nil, fmt.Errorf("error decoding JSON stream: %w", err)
	}

	// Find highest APY pool
	var maxApy = -1.0
	var selectedPool *Pool

	for _, pool := range apiResponse.Data {
		if AllowedSymbol[pool.Symbol] &&
			AllowedChain[pool.Chain] &&
			AllowedProject[pool.Project] &&
			pool.Apy > maxApy {

			maxApy = pool.Apy
			currentPool := pool
			selectedPool = &currentPool
		}
	}

	if selectedPool == nil {
		return nil, fmt.Errorf("no approved strategy pool found")
	}

	return selectedPool, nil
}
*/

/*
// fetchAndParse performs a simpler approach by reading the entire body first.
func fetchAndParsePools(config *Config, logger *slog.Logger, sendRequester *http.SendRequester) (*Pool, error) {
	req := &http.Request{
		Url:     "https://yields.llama.fi/pools",
		Method:  "GET",
		Headers: map[string]string{"Accept-Encoding": "gzip"},
	}

	resp, err := sendRequester.SendRequest(req).Await()
	logger.Info("Response result", "response", resp.StatusCode)
	if err != nil {
		return nil, fmt.Errorf("failed to get API response: %w", err)
	}

	var body []byte
	if encoding, ok := resp.Headers["Content-Encoding"]; ok && encoding == "gzip" {
		reader, err := gzip.NewReader(bytes.NewReader(resp.Body))
		if err != nil {
			return nil, fmt.Errorf("failed to create gzip reader: %w", err)
		}
		defer reader.Close()
		body, err = io.ReadAll(reader)
		if err != nil {
			return nil, fmt.Errorf("failed to decompress body: %w", err)
		}
	} else {
		body = resp.Body
	}

	var apiResponse APIResponse
	error := json.Unmarshal(body, &apiResponse)
	if error != nil {
		return nil, fmt.Errorf("error unmarshaling JSON: %w", err)
	}

	// Find highest APY pool
	var maxApy = -1.0
	var selectedPool *Pool

	for _, pool := range apiResponse.Data {
		if AllowedSymbol[pool.Symbol] &&
			AllowedChain[pool.Chain] &&
			AllowedProject[pool.Project] &&
			pool.Apy > maxApy {

			maxApy = pool.Apy
			currentPool := pool
			selectedPool = &currentPool
		}
	}

	if selectedPool == nil {
		return nil, fmt.Errorf("no pool with symbol 'USDC' found")
	}

	return selectedPool, nil
}
*/
