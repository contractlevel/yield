//go:build wasip1

package main

import (
	"bytes"
	"compress/gzip"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/networking/http"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/wasm"
)

type Pool struct {
	Chain   string  `json:"chain"`
	Project string  `json:"project"`
	Symbol  string  `json:"symbol"`
	Apy     float64 `json:"apy"`
}

type ApiResponse struct {
	Data []Pool `json:"data"`
}

type Config struct {
	Schedule string `json:"schedule"`
	ApiUrl   string `json:"apiUrl"`
}

// Workflow implementation with a list of capability triggers
func InitWorkflow(config *Config, logger *slog.Logger, secretsProvider cre.SecretsProvider) (cre.Workflow[*Config], error) {
	// Create the trigger
	cronTrigger := cron.Trigger(&cron.Config{Schedule: config.Schedule})

	// Register a handler with the trigger and a callback function
	return cre.Workflow[*Config]{
		cre.Handler(cronTrigger, onCronTrigger),
	}, nil
}

func onCronTrigger(config *Config, runtime cre.Runtime, trigger *cron.Payload) (*Pool, error) {
	logger := runtime.Logger()
	client := &http.Client{}

	poolPromise := http.SendRequest(config, runtime, client, fetchAndParse, cre.ConsensusIdenticalAggregation[*Pool]())

	result, err := poolPromise.Await()
	if err != nil {
		return nil, fmt.Errorf("failed to await promise: %w", err)
	}

	logger.Info("Got highest APY usdc pool")

	return &Pool{
		Chain:   result.Chain,
		Project: result.Project,
		Symbol:  result.Symbol,
		Apy:     result.Apy,
	}, nil
}

func fetchAndParse(config *Config, logger *slog.Logger, sendRequester *http.SendRequester) (*Pool, error) {
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

	var apiResponse ApiResponse
	error := json.Unmarshal(body, &apiResponse)
	if error != nil {
		return nil, fmt.Errorf("error unmarshaling JSON: %w", err)
	}

	var maxApy float64 = -1
	var selectedPool *Pool

	for _, pool := range apiResponse.Data {
		if pool.Symbol == "USDC" && pool.Apy > maxApy {
			maxApy = pool.Apy
			selectedPool = &Pool{
				Chain:   pool.Chain,
				Project: pool.Project,
				Symbol:  pool.Symbol,
				Apy:     pool.Apy,
			}
		}
	}

	if selectedPool == nil {
		return nil, fmt.Errorf("no pool with symbol 'USDC' found")
	}

	return selectedPool, nil
}

func main() {
	wasm.NewRunner(cre.ParseJSON[Config]).Run(InitWorkflow)
}
