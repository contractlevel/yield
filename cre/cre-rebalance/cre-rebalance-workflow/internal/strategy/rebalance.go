package strategy

import (
	"fmt"
	"log/slog"

	"cre-rebalance/cre-rebalance-workflow/internal/onchain"
)

func Rebalance(optimal onchain.Strategy, writeFn func(onchain.Strategy) error) error {
	if err := writeFn(optimal); err != nil {
		return err
	}
	return nil
}