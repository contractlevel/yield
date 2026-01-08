//go:build wasip1

package main

import (
	"cre-rebalance/apy-impact-calculator/aaveV3"

	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/wasm"
)

// Config is the workflow configuration loaded from config.json
type Config struct {
	Schedule    string               `json:"schedule"`
	DepositUSDC string               `json:"depositUSDC"` // Amount in USDC (with 6 decimals)
	Chains      []aaveV3.ChainConfig `json:"chains"`
}

func main() {
	wasm.NewRunner(cre.ParseJSON[Config]).Run(InitWorkflow)
}
