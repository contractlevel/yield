package onchain

import (
	"fmt"

	"rebalance/contracts/evm/src/generated/rebalancer"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

func WriteRebalance(
	rb RebalancerInterface,
	runtime cre.Runtime,
	gasLimit uint64,
	optimal Strategy,
) error {
	gasConfig := &evm.GasConfig{GasLimit: gasLimit}

	rebalancerStrategy := rebalancer.IYieldPeerStrategy{
		ProtocolId:    optimal.ProtocolId,
		ChainSelector: optimal.ChainSelector,
	}

	resp, err := rb.WriteReportFromIYieldPeerStrategy(runtime, rebalancerStrategy, gasConfig).Await()
	if err != nil {
		return fmt.Errorf("failed to update strategy on Rebalancer: %w", err)
	}

	logger := runtime.Logger()
	logger.Info(
		"Rebalancer update transaction submitted",
		"txHash", fmt.Sprintf("0x%x", resp.TxHash),
	)
	return nil
}