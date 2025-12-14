package strategy

import (
	"fmt"
	"log/slog"
	"math/big"

	"cre-rebalance/cre-rebalance-workflow/internal/onchain"

	"github.com/ethereum/go-ethereum/crypto"
)

// CalculateOptimalStrategy is where the "brains" of the strategy selection live.
// For now it's just pseudocode / comments.
func CalculateOptimalStrategy(
	logger *slog.Logger,
	current onchain.Strategy, // @review not doing anything with currentStrategy here
	tvl *big.Int,
) onchain.Strategy {
	// @review this needs to be revisited
	// Placeholder / dummy logic for now:
	// Use a fixed protocol ID as the "optimal" target, to keep the workflow
	// behavior deterministic while you iterate on the real APY model.
	protocol := "dummy-protocol-v1"
	hashedProtocolId := crypto.Keccak256([]byte(protocol))

	var optimalId [32]byte
	copy(optimalId[:], hashedProtocolId)

	optimal := onchain.Strategy{
		ProtocolId:    optimalId,
		ChainSelector: current.ChainSelector,
	}

	logger.Info(
		"Calculated optimal strategy candidate",
		"protocolId", fmt.Sprintf("0x%x", optimal.ProtocolId),
		"chainSelector", optimal.ChainSelector,
		"tvl", tvl.String(),
	)

	return optimal
}