package offchain

import (
	"bytes"
	"compress/gzip"
	"cre-rebalance/cre-rebalance-workflow/internal/helper"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/networking/http"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// getOptimalPool manages the orchestration of the off-chain data fetch.
func getOptimalPool(config *helper.Config, runtime cre.Runtime) (*Pool, error) {
	logger := runtime.Logger()
	client := &http.Client{}

	// CRE consensus: identical aggregation ensures all nodes agree on the same pool
	poolPromise := http.SendRequest(config, runtime, client, fetchAndParsePools, cre.ConsensusIdenticalAggregation[*Pool]())

	returnedPool, err := poolPromise.Await()
	if err != nil {
		return nil, fmt.Errorf("failed to await promise: %w", err)
	}

	logger.Info("Got highest APY allowed pool", slog.Any("pool", returnedPool))
	return returnedPool, nil
}

// fetchAndParsePools performs the high-performance token-based streaming.
func fetchAndParsePools(config *helper.Config, logger *slog.Logger, sendRequester *http.SendRequester) (*Pool, error) {
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
			AllowedChain[p.Chain] &&
			AllowedProject[p.Project] &&
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
