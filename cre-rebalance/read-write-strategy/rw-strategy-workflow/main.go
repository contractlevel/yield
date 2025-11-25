//go:build wasip1

package main

import (
	"encoding/hex"
	"fmt"
	"log/slog"
	"math/big"

	"read-write-strategy/contracts/evm/src/generated/simple_parent"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/wasm"
)

// type Strategy struct {
// 	ProtocolId    [32]byte
// 	ChainSelector uint64
// }

type Output struct {
	ProtocolId    string `json:"ProtocolId"`
	ChainSelector uint64 `json:"ChainSelector"`
}

type CurrentStrategy simple_parent.Strategy

type EvmConfig struct {
	ChainName           string `json:"chainName"`
	SimpleParentAddress string `json:"simpleParentAddress"`
}

// Workflow configuration loaded from the config.json file
type Config struct {
	Schedule string `json:"schedule"`
	Evms     []EvmConfig
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

func onCronTrigger(config *Config, runtime cre.Runtime, trigger *cron.Payload) (*Output, error) {
	logger := runtime.Logger()
	logger.Info("Reading current Strategy")

	evmConfig := config.Evms[0]

	logger.Info("Getting chain selector")
	chainSelector, err := evm.ChainSelectorFromName(evmConfig.ChainName)
	if err != nil {
		return nil, fmt.Errorf("invalid chain selector: %w", err)
	}

	logger.Info("Getting Parent address")
	parentAddress := common.HexToAddress(evmConfig.SimpleParentAddress)

	logger.Info("Creating client")
	evmClient := &evm.Client{ChainSelector: chainSelector}

	logger.Info("Creating instance of Parent")
	simpleParent, err := simple_parent.NewSimpleParent(evmClient, parentAddress, nil)
	if err != nil {
		return nil, fmt.Errorf("couldn't get contract instance: %w", err)
	}

	logger.Info("Getting current strategy")
	currentStrategy, err := simpleParent.GetStrategy(runtime, big.NewInt(-3)).Await()
	if err != nil {
		return nil, fmt.Errorf("error getting strategy: %w", err)
	}

	logger.Info("Current strategy", "strategy", currentStrategy)

	return &Output{
		ProtocolId:    "0x" + hex.EncodeToString(currentStrategy.ProtocolId[:]),
		ChainSelector: currentStrategy.ChainSelector,
	}, nil
}

func main() {
	wasm.NewRunner(cre.ParseJSON[Config]).Run(InitWorkflow)
}
