package offchain

import (
	"rebalance/workflow/internal/onchain"
	"rebalance/workflow/internal/helper"

	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// @review placeholder
func GetOptimalStrategy(config *helper.Config, runtime cre.Runtime) (onchain.Strategy, error) {
	return onchain.Strategy{}, nil
}