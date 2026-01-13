//go:build wasip1

package main

import (
	"cre-rebalance/cre-rebalance-workflow/internal/helper"

	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/wasm"
)

func main() {
	wasm.NewRunner(cre.ParseJSON[helper.Config]).Run(InitWorkflow)
}
