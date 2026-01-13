package offchain

import (
	"cre-rebalance/cre-rebalance-workflow/internal/helper"
	"cre-rebalance/cre-rebalance-workflow/internal/onchain"
	"fmt"

	"github.com/ethereum/go-ethereum/crypto"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// Public func that gets the optimal pool from DefiLlama and transforms it into an on-chain Strategy
func GetOptimalStrategy(config *helper.Config, runtime cre.Runtime) (*onchain.Strategy, error) {
	// 1. Get the optimal pool from off-chain
	pool, err := getBestPool(config, runtime)
	if err != nil {
		return nil, fmt.Errorf("failed to get optimal strategy: %w", err)
	}

	// 2. Transform the pool into an on-chain Strategy
	var protocolId [32]byte
	hash := crypto.Keccak256([]byte(pool.Project))
	copy(protocolId[:], hash)

	chainSelector, err := chainSelectorFromChainName(pool.Chain)
	if err != nil {
		// @review not sure of this error name
		return nil, fmt.Errorf("invalid strategy configuration: %w", err)
	}

	// 3. Return the strategy
	return &onchain.Strategy{
		ProtocolId:    protocolId,
		ChainSelector: chainSelector,
	}, nil
}

// @review better to have a mapping or is this a shared func we can use elsewhere?
// Helper function to get chain selector from chain name
func chainSelectorFromChainName(chainName string) (uint64, error) {
	switch chainName {
	case "Arbitrum":
		return 4949039107694359620, nil
	case "Base":
		return 15971525489660198786, nil
	case "Ethereum":
		return 5009297550715157269, nil
	case "Optimism":
		return 3734403246176062136, nil
	default:
		return 0, fmt.Errorf("chain selector not found for: %s", chainName)
	}
}
