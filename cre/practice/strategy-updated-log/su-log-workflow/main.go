//go:build wasip1

package main

import (
	"fmt"
	"log/slog"

	"strategy-updated-log/contracts/evm/src/generated/simple_parent"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm/bindings"

	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/wasm"
)

// Workflow configuration loaded from the config.json file
type Config struct {
	Schedule string `json:"schedule"`
	Evms     []EvmConfigs
}

type EvmConfigs struct {
	ChainName           string `json:"chainName"`
	SimpleParentAddress string `json:"simpleParentAddress"`
}

type MyResult struct {
	ProtocolId    string
	ChainSelector uint64
}

func InitWorkflow(config *Config, logger *slog.Logger, secretsProvider cre.SecretsProvider) (cre.Workflow[*Config], error) {
	evmConfig := config.Evms[0]

	// Create EVM client for chain we want to monitor
	chainSelector, err := evm.ChainSelectorFromName(evmConfig.ChainName)
	if err != nil {
		return nil, fmt.Errorf("failed to get chain selector: %w", err)
	}
	evmClient := &evm.Client{ChainSelector: chainSelector}

	// Initialize contract binding
	parentAddress := common.HexToAddress(evmConfig.SimpleParentAddress)
	parentContract, err := simple_parent.NewSimpleParent(evmClient, parentAddress, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create contract binding: %w", err)
	}

	// Use binding to create trigger for StrategyUpdated event
	logTrigger, err := parentContract.LogTriggerStrategyUpdatedLog(chainSelector, evm.ConfidenceLevel_CONFIDENCE_LEVEL_FINALIZED, []simple_parent.StrategyUpdatedTopics{})
	if err != nil {
		return nil, fmt.Errorf("failed to create log trigger: %w", err)
	}

	// Register the handler that will be called when the event is detected
	return cre.Workflow[*Config]{cre.Handler(logTrigger, onEvmTrigger)}, nil
}

func onEvmTrigger(config *Config, runtime cre.Runtime, payload *bindings.DecodedLog[simple_parent.StrategyUpdatedDecoded]) (*MyResult, error) {
	logger := runtime.Logger()

	eventChain := payload.Data.ChainSelector
	eventId := payload.Data.ProtocolId

	logger.Info("StrategyUpdated detected",
		"New Strategy chain", eventChain,
		"New Strategy protocolId", common.Bytes2Hex(eventId[:]),
	)

	return &MyResult{
		ProtocolId:    common.Bytes2Hex(eventId[:]),
		ChainSelector: eventChain,
	}, nil
}

func main() {
	wasm.NewRunner(cre.ParseJSON[Config]).Run(InitWorkflow)
}
