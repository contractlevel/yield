package strategy

import (
	"fmt"
	"log/slog"

	"cre-rebalance/cre-rebalance-workflow/internal/onchain"
)

func RebalanceIfNeeded(
	logger *slog.Logger,
	current onchain.Strategy,
	optimal onchain.Strategy,
	writeFn func(onchain.Strategy) error,
) (*StrategyResult, error) {
	if current == optimal {
		logger.Info("Strategy unchanged; no update needed")
		return &StrategyResult{
			Current: current,
			Optimal: optimal,
			Updated: false,
		}, nil
	}
	// (else) APY logic placeholder – only rebalance when difference is meaningful. ie higher than neglible threshold
	// @review

	logger.Info(
		"Strategy changed and APY improvement deemed worthwhile; rebalancing",
		"currentProtocolId", fmt.Sprintf("0x%x", current.ProtocolId),
		"currentChainSelector", current.ChainSelector,
		"optimalProtocolId", fmt.Sprintf("0x%x", optimal.ProtocolId),
		"optimalChainSelector", optimal.ChainSelector,
	)

	// Execute onchain rebalance tx via injected function.
	if err := writeFn(optimal); err != nil {	
		return nil, err
	}

	return &StrategyResult{
		Current: current,
		Optimal: optimal,
		Updated: true,
	}, nil
}