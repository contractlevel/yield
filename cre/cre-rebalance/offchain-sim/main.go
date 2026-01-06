//go:build wasip1

package main

import (
	"fmt"
	"log/slog"

	"cre-rebalance/offchain-sim/internal/offchain"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/wasm"
)

func InitWorkflow(config *offchain.Config, logger *slog.Logger, secretsProvider cre.SecretsProvider) (cre.Workflow[*offchain.Config], error) {
	cronTrigger := cron.Trigger(&cron.Config{Schedule: config.Schedule})

	return cre.Workflow[*offchain.Config]{
		cre.Handler(cronTrigger, onCronTrigger),
	}, nil
}

func onCronTrigger(config *offchain.Config, runtime cre.Runtime, trigger *cron.Payload) (*offchain.Strategy, error) {
	logger := runtime.Logger()

	logger.Info("Getting optimal strategy from offchain package")
	strategy, err := offchain.GetOptimalStrategy(config, runtime)

	if strategy == nil {
		return nil, fmt.Errorf("no optimal strategy found")
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get optimal strategy: %w", err)
	}

	return strategy, nil
}

func main() {
	wasm.NewRunner(cre.ParseJSON[offchain.Config]).Run(InitWorkflow)
}
