package onchain

import (
	"errors"
	"testing"

	"cre-rebalance/contracts/evm/src/generated/rebalancer"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
)

// mockRebalancer is a mock implementation of RebalancerInterface for testing
type mockRebalancer struct {
	writeReportFunc func(cre.Runtime, rebalancer.IYieldPeerStrategy, *evm.GasConfig) cre.Promise[*evm.WriteReportReply]
}

func (m *mockRebalancer) WriteReportFromIYieldPeerStrategy(
	runtime cre.Runtime,
	input rebalancer.IYieldPeerStrategy,
	gasConfig *evm.GasConfig,
) cre.Promise[*evm.WriteReportReply] {
	if m.writeReportFunc != nil {
		return m.writeReportFunc(runtime, input, gasConfig)
	}
	return cre.PromiseFromResult[*evm.WriteReportReply](nil, errors.New("writeReportFunc not set"))
}

func Test_WriteRebalance_Success(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)
	logger := runtime.Logger()

	gasLimit := uint64(500000)
	optimal := Strategy{
		ProtocolId:    [32]byte{1, 2, 3},
		ChainSelector: 12345,
	}

	expectedTxHash := []byte{0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0}
	expectedReply := &evm.WriteReportReply{
		TxHash: expectedTxHash,
	}

	mockRb := &mockRebalancer{
		writeReportFunc: func(_ cre.Runtime, input rebalancer.IYieldPeerStrategy, gasConfig *evm.GasConfig) cre.Promise[*evm.WriteReportReply] {
			// Verify the input parameters
			if input.ProtocolId != optimal.ProtocolId {
				t.Errorf("expected ProtocolId %v, got %v", optimal.ProtocolId, input.ProtocolId)
			}
			if input.ChainSelector != optimal.ChainSelector {
				t.Errorf("expected ChainSelector %d, got %d", optimal.ChainSelector, input.ChainSelector)
			}
			if gasConfig == nil {
				t.Error("expected gasConfig to be non-nil")
			} else if gasConfig.GasLimit != gasLimit {
				t.Errorf("expected GasLimit %d, got %d", gasLimit, gasConfig.GasLimit)
			}

			return cre.PromiseFromResult(expectedReply, nil)
		},
	}

	err := WriteRebalance(mockRb, runtime, logger, gasLimit, optimal)
	if err != nil {
		t.Fatalf("WriteRebalance returned unexpected error: %v", err)
	}
}

func Test_WriteRebalance_Error(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)
	logger := runtime.Logger()

	gasLimit := uint64(500000)
	optimal := Strategy{
		ProtocolId:    [32]byte{1, 2, 3},
		ChainSelector: 12345,
	}

	expectedError := errors.New("transaction failed")

	mockRb := &mockRebalancer{
		writeReportFunc: func(_ cre.Runtime, _ rebalancer.IYieldPeerStrategy, _ *evm.GasConfig) cre.Promise[*evm.WriteReportReply] {
			return cre.PromiseFromResult[*evm.WriteReportReply](nil, expectedError)
		},
	}

	err := WriteRebalance(mockRb, runtime, logger, gasLimit, optimal)
	if err == nil {
		t.Fatal("WriteRebalance expected error but got nil")
	}

	if !errors.Is(err, expectedError) && err.Error() != "failed to update strategy on Rebalancer: "+expectedError.Error() {
		t.Errorf("expected error to wrap %v, got %v", expectedError, err)
	}
}

func Test_WriteRebalance_WithDifferentStrategy(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)
	logger := runtime.Logger()

	gasLimit := uint64(1000000)
	var protocolId [32]byte
	copy(protocolId[:], []byte("test-protocol-id-123456789012"))
	optimal := Strategy{
		ProtocolId:    protocolId,
		ChainSelector: 99999,
	}

	expectedTxHash := []byte{0xff, 0xee, 0xdd, 0xcc, 0xbb, 0xaa, 0x99, 0x88}
	expectedReply := &evm.WriteReportReply{
		TxHash: expectedTxHash,
	}

	mockRb := &mockRebalancer{
		writeReportFunc: func(_ cre.Runtime, input rebalancer.IYieldPeerStrategy, gasConfig *evm.GasConfig) cre.Promise[*evm.WriteReportReply] {
			// Verify different values are passed correctly
			if input.ProtocolId != optimal.ProtocolId {
				t.Errorf("expected ProtocolId %v, got %v", optimal.ProtocolId, input.ProtocolId)
			}
			if input.ChainSelector != optimal.ChainSelector {
				t.Errorf("expected ChainSelector %d, got %d", optimal.ChainSelector, input.ChainSelector)
			}
			if gasConfig.GasLimit != gasLimit {
				t.Errorf("expected GasLimit %d, got %d", gasLimit, gasConfig.GasLimit)
			}

			return cre.PromiseFromResult(expectedReply, nil)
		},
	}

	err := WriteRebalance(mockRb, runtime, logger, gasLimit, optimal)
	if err != nil {
		t.Fatalf("WriteRebalance returned unexpected error: %v", err)
	}
}