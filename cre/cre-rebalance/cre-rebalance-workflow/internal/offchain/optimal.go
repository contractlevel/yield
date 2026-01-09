package offchain

import (
	"cre-rebalance/cre-rebalance-workflow/internal/helper"
	"cre-rebalance/cre-rebalance-workflow/internal/onchain"
	"fmt"

	"github.com/ethereum/go-ethereum/crypto"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// GetOptimalStrategy fetches the optimal pool and transforms it into an on-chain Strategy
func GetOptimalStrategy(config *helper.Config, runtime cre.Runtime) (*onchain.Strategy, error) {
	pool, err := getOptimalPool(config, runtime)
	if err != nil {
		return nil, fmt.Errorf("failed to get optimal strategy: %w", err)
	}

	// 1. Hash protocol name safely
	// We use 'copy' to ensure we safely move bytes into the fixed-size array
	var protocolId [32]byte
	copy(protocolId[:], crypto.Keccak256([]byte(pool.Project)))

	// 2. Get chain selector
	chainSelector, err := chainSelectorFromChainName(pool.Chain)
	if err != nil {
		return nil, fmt.Errorf("invalid strategy configuration: %w", err)
	}

	return &onchain.Strategy{
		ProtocolId:    protocolId,
		ChainSelector: chainSelector,
	}, nil
}

// Helper function to map chain names to CCIP selectors
func chainSelectorFromChainName(chainName string) (uint64, error) {
	// Professional Tip: Switch statements are compiled efficiently in Go.
	// For a small list, this is actually preferred over a global map for simplicity.
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
		return 0, fmt.Errorf("chain selector not found for: %s", chainName)
	}
}
