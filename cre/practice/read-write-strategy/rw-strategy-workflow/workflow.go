package main

import (
	"fmt"
	"log/slog"
	"math/big"
	"strings"

	"read-write-strategy/contracts/evm/src/generated/simple_parent"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

/*
	"simple_parent.Strategy" is:
	type Strategy struct {
		ProtocolId    [32]byte
		ChainSelector uint64
	}
*/

type CurrentStrategy simple_parent.Strategy
type NewStrategy simple_parent.Strategy

type EvmConfig struct {
	ChainName           string `json:"chainName"`
	SimpleParentAddress string `json:"simpleParentAddress"`
	GasLimit            uint64 `json:"gasLimit"`
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

func onCronTrigger(config *Config, runtime cre.Runtime, trigger *cron.Payload) (*CurrentStrategy, error) {
	logger := runtime.Logger()

	// Create evm Client
	evmConfig := config.Evms[0]
	chainSelector, err := evm.ChainSelectorFromName(evmConfig.ChainName)
	if err != nil {
		return nil, fmt.Errorf("Failed to get chain selector from name: %w", err)
	}
	evmClient := &evm.Client{ChainSelector: chainSelector}

	// Validate Simple Parent Address
	if !common.IsHexAddress(evmConfig.SimpleParentAddress) {
		return nil, fmt.Errorf("Error: invalid address format: %s", evmConfig.SimpleParentAddress)
	}
	if !strings.HasPrefix(evmConfig.SimpleParentAddress, "0x") {
		return nil, fmt.Errorf("Error: address must start with 0x: %s", evmConfig.SimpleParentAddress)
	}
	// Create instance of Simple Parent contract
	parentAddress := common.HexToAddress(evmConfig.SimpleParentAddress)
	simpleParentContract, err := simple_parent.NewSimpleParent(evmClient, parentAddress, nil)
	if err != nil {
		return nil, fmt.Errorf("Error: Failed to create contract instance: %w", err)
	}

	// Get Strategy on Parent
	logger.Info("Getting current strategy...")
	currentStrategy, err := simpleParentContract.GetStrategy(runtime, big.NewInt(-3)).Await()

	// Show Strategy
	logger.Info("Strategy read.", "ProtocolId", common.Bytes2Hex(currentStrategy.ProtocolId[:]), "ChainSelector", currentStrategy.ChainSelector)

	// Create new Strategy - simulating getting new one from API
	protocol := "compound-v3"
	hashedProtocolId := crypto.Keccak256([]byte(protocol))
	var newChainSel uint64 = 10344971235874465080 // base sepolia
	newStrategy := NewStrategy{
		ProtocolId:    [32]byte(hashedProtocolId),
		ChainSelector: newChainSel,
	}

	// Show newly created Strategy
	logger.Info("Created new Strategy.", "ProtocolId", common.Bytes2Hex(newStrategy.ProtocolId[:]), "ChainSelector", newStrategy.ChainSelector)

	// Compare Strategies
	logger.Info("Comparing strategies")
	if currentStrategy.ChainSelector == newStrategy.ChainSelector {
		logger.Info("Chain selectors match")
	} else if currentStrategy.ChainSelector != newStrategy.ChainSelector {
		logger.Info("Chain selectors dont match")
	}

	if currentStrategy.ProtocolId == newStrategy.ProtocolId {
		logger.Info("ProtocolIds match")
	} else if currentStrategy.ProtocolId != newStrategy.ProtocolId {
		logger.Info("ProtocolIds don't match")
	}

	// Write report
	gasConfig := &evm.GasConfig{
		GasLimit: evmConfig.GasLimit,
	}
	resp, err := simpleParentContract.WriteReportFromStrategy(runtime, simple_parent.Strategy(newStrategy), gasConfig).Await()
	if err != nil {
		return nil, fmt.Errorf("failed to await write report: %w", err)
	}

	// Log Tx
	txHash := fmt.Sprintf("0x%x", resp.TxHash)
	logger.Info("Write report transaction succeeded", "txHash", txHash)
	logger.Info("View transaction at", "url", fmt.Sprintf("https://sepolia.etherscan.io/tx/%s", txHash))

	// Read + show Strategy again to see that it's the new one
	// @review George: I'm not sure this read again works because the tx above is sent as report
	logger.Info("Getting current strategy...")
	curStra, err := simpleParentContract.GetStrategy(runtime, big.NewInt(-3)).Await()
	logger.Info("Strategy read.", "ProtocolId", common.Bytes2Hex(curStra.ProtocolId[:]), "ChainSelector", curStra.ChainSelector)

	// The Protocolid in this return will be displayed as a base64 encoding in terminal
	return &CurrentStrategy{
		ChainSelector: curStra.ChainSelector,
		ProtocolId:    curStra.ProtocolId,
	}, nil
}
