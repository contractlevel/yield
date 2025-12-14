package strategy

import (
	"log/slog"
	"math/big"

	"cre-rebalance/cre-rebalance-workflow/internal/onchain"

	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// StrategyResult is primarily for debugging / testing.
type StrategyResult struct {
	Current onchain.Strategy `json:"current"`
	Optimal onchain.Strategy `json:"optimal"`
	Updated bool             `json:"updated"`
}

type OnCronDeps struct {
	ReadCurrentStrategy func(peer onchain.ParentPeerInterface, runtime cre.Runtime) (onchain.Strategy, error)
	ReadTVL             func(peer onchain.YieldPeerInterface,  runtime cre.Runtime) (*big.Int, error)
	WriteRebalance      func(rb   onchain.RebalancerInterface, runtime cre.Runtime, logger *slog.Logger, gasLimit uint64, optimal onchain.Strategy) error
}