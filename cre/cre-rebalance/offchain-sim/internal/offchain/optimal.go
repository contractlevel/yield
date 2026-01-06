package offchain

import (
	"fmt"

	"github.com/ethereum/go-ethereum/crypto"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// Fetches the optimal strategy pool from DefiLlama and constructs/returns a Strategy struct
func GetOptimalStrategy(config *Config, runtime cre.Runtime) (*Strategy, error) {
	// Get the optimal pool from DefiLlama
	pool, err := getOptimalPool(config, runtime)
	if pool == nil {
		return nil, fmt.Errorf("no optimal pool found")
	}
	if err != nil {
		return &Strategy{}, err
	}

	// Hash protocol name and create Id
	hashedProtocol := crypto.Keccak256([]byte(pool.Project))
	protocolId := [32]byte(hashedProtocol)

	// Get chain selector from chain name and handle errors
	chainSelector, err := chainSelectorFromChainName(pool.Chain)
	if chainSelector == 0 {
		return nil, fmt.Errorf("unsupported chain name: %s", pool.Chain)
	}
	if err != nil {
		return nil, err
	}

	// Create and return optimal strategy
	optimalStrategy := Strategy{
		ProtocolId:    protocolId,
		ChainSelector: chainSelector,
	}
	return &optimalStrategy, nil
}

// Helper function to get chain selector for a chain name
func chainSelectorFromChainName(chainName string) (uint64, error) {
	switch chainName {
	case "Ethereum":
		return 5009297550715157269, nil
	case "Arbitrum":
		return 4949039107694359620, nil
	case "Base":
		return 15971525489660198786, nil
	case "Optimism":
		return 3734403246176062136, nil
	default:
		return 0, nil
	}
}
