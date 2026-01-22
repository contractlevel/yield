package onchain

import (
	"errors"
	"testing"

	"rebalance/contracts/evm/src/generated/rebalancer"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"
)

/*//////////////////////////////////////////////////////////////
                           MOCKS
//////////////////////////////////////////////////////////////*/

// mockRebalancer is a mock implementation of RebalancerInterface for testing.
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

/*//////////////////////////////////////////////////////////////
                             TESTS
//////////////////////////////////////////////////////////////*/

func Test_WriteRebalance_success(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	gasLimit := uint64(500_000)
	optimal := Strategy{
		ProtocolId:    [32]byte{1, 2, 3},
		ChainSelector: 12_345,
	}

	expectedTxHash := []byte{0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0}
	expectedReply := &evm.WriteReportReply{
		TxHash: expectedTxHash,
	}

	mockRb := &mockRebalancer{
		writeReportFunc: func(_ cre.Runtime, input rebalancer.IYieldPeerStrategy, gasConfig *evm.GasConfig) cre.Promise[*evm.WriteReportReply] {
			require.Equal(t, optimal.ProtocolId, input.ProtocolId, "ProtocolId should match optimal strategy")
			require.Equal(t, optimal.ChainSelector, input.ChainSelector, "ChainSelector should match optimal strategy")

			require.NotNil(t, gasConfig, "gasConfig should be non-nil")
			require.Equal(t, gasLimit, gasConfig.GasLimit, "GasLimit should match provided value")

			return cre.PromiseFromResult(expectedReply, nil)
		},
	}

	err := WriteRebalance(mockRb, runtime, gasLimit, optimal)
	require.NoError(t, err, "WriteRebalance should not return error in success case")
}

func Test_WriteRebalance_error(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	gasLimit := uint64(500_000)
	optimal := Strategy{
		ProtocolId:    [32]byte{1, 2, 3},
		ChainSelector: 12_345,
	}

	expectedError := errors.New("transaction failed")

	mockRb := &mockRebalancer{
		writeReportFunc: func(_ cre.Runtime, _ rebalancer.IYieldPeerStrategy, _ *evm.GasConfig) cre.Promise[*evm.WriteReportReply] {
			return cre.PromiseFromResult[*evm.WriteReportReply](nil, expectedError)
		},
	}

	err := WriteRebalance(mockRb, runtime, gasLimit, optimal)
	require.Error(t, err, "WriteRebalance should return error when underlying call fails")
	require.ErrorIs(t, err, expectedError, "error should wrap the underlying transaction error")
	require.Contains(t, err.Error(), "failed to update strategy on Rebalancer", "error message should include context")
}

func Test_WriteRebalance_withDifferentStrategy(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	gasLimit := uint64(1_000_000)

	var protocolId [32]byte
	copy(protocolId[:], []byte("test-protocol-id-123456789012"))

	optimal := Strategy{
		ProtocolId:    protocolId,
		ChainSelector: 99_999,
	}

	expectedTxHash := []byte{0xff, 0xee, 0xdd, 0xcc, 0xbb, 0xaa, 0x99, 0x88}
	expectedReply := &evm.WriteReportReply{
		TxHash: expectedTxHash,
	}

	mockRb := &mockRebalancer{
		writeReportFunc: func(_ cre.Runtime, input rebalancer.IYieldPeerStrategy, gasConfig *evm.GasConfig) cre.Promise[*evm.WriteReportReply] {
			require.Equal(t, optimal.ProtocolId, input.ProtocolId, "ProtocolId should match optimal strategy")
			require.Equal(t, optimal.ChainSelector, input.ChainSelector, "ChainSelector should match optimal strategy")
			require.Equal(t, gasLimit, gasConfig.GasLimit, "GasLimit should match provided value")

			return cre.PromiseFromResult(expectedReply, nil)
		},
	}

	err := WriteRebalance(mockRb, runtime, gasLimit, optimal)
	require.NoError(t, err, "WriteRebalance should succeed with different strategy values")
}
