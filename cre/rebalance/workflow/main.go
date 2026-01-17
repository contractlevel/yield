//go:build wasip1

package main

import (
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/wasm"
	"rebalance/workflow/internal/helper"
)

func main() {
	wasm.NewRunner(cre.ParseJSON[helper.Config]).Run(InitWorkflow)
}
