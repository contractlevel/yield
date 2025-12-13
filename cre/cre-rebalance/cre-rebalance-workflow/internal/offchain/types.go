package offchain

import (
	"cre-rebalance/cre-rebalance-workflow/internal/onchain"

	"github.com/smartcontractkit/cre-sdk-go/cre"
	"log/slog"
	"math/big"
)

// Config is loaded from config.json
//
//	{
//	  "schedule": "0 */1 * * * *",
//	  "evms": [
//	    {
//	      "chainName": "ethereum-testnet-sepolia",
//	      "chainSelector": 16015286601757825753,
//	      "yieldPeerAddress": "0x...",
//	      "rebalancerAddress": "0x...",
//	      "gasLimit": 500000
//	    }
//	  ]
//	}
type Config struct {
	Schedule string 	 `json:"schedule"`
	Evms     []EvmConfig `json:"evms"` // Parent chain is Evms[0]
}

// EvmConfig:
//   - evms[0] is the parent chain: where the Parent YieldPeer is
//     and where we read the currentStrategy from.
//   - currentStrategy.ChainSelector tells us which chain the active strategy
//     adapter lives on.
type EvmConfig struct {
	ChainName string 		 `json:"chainName"`
	ChainSelector uint64 	 `json:"chainSelector"`
	YieldPeerAddress string  `json:"yieldPeerAddress"`
	RebalancerAddress string `json:"rebalancerAddress"`
	GasLimit uint64 	     `json:"gasLimit"`
}

// StrategyResult is primarily for debugging / testing.
type StrategyResult struct {
	Current onchain.Strategy `json:"current"`
	Optimal onchain.Strategy `json:"optimal"`
	Updated bool             `json:"updated"`
}

type OnCronDeps struct {
	ReadCurrentStrategy func(peer onchain.ParentPeerInterface, runtime cre.Runtime) (onchain.Strategy, error)
	ReadTVL             func(peer onchain.YieldPeerInterface, runtime cre.Runtime) (*big.Int, error)
	WriteRebalance      func(rb onchain.RebalancerInterface, runtime cre.Runtime, logger *slog.Logger, gasLimit uint64, optimal onchain.Strategy) error
}