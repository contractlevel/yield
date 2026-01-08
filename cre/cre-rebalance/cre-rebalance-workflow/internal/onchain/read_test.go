package onchain

import (
	"errors"
	"math/big"
	"testing"

	"cre-rebalance/contracts/evm/src/generated/parent_peer"

	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/stretchr/testify/require"
)

/*//////////////////////////////////////////////////////////////
                             MOCKS
//////////////////////////////////////////////////////////////*/

// mockParentPeer is a mock implementation of ParentPeerInterface for testing.
type mockParentPeer struct {
	getStrategyFunc   func(cre.Runtime, *big.Int) cre.Promise[parent_peer.IYieldPeerStrategy]
	getTotalValueFunc func(cre.Runtime, *big.Int) cre.Promise[*big.Int]
}

func (m *mockParentPeer) GetStrategy(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[parent_peer.IYieldPeerStrategy] {
	if m.getStrategyFunc != nil {
		return m.getStrategyFunc(runtime, blockNumber)
	}
	return cre.PromiseFromResult[parent_peer.IYieldPeerStrategy](
		parent_peer.IYieldPeerStrategy{},
		errors.New("getStrategyFunc not set"),
	)
}

func (m *mockParentPeer) GetTotalValue(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	if m.getTotalValueFunc != nil {
		return m.getTotalValueFunc(runtime, blockNumber)
	}
	return cre.PromiseFromResult[*big.Int](nil, errors.New("getTotalValueFunc not set"))
}

// mockYieldPeer is a mock implementation of YieldPeerInterface for testing.
type mockYieldPeer struct {
	getTotalValueFunc func(cre.Runtime, *big.Int) cre.Promise[*big.Int]
}

func (m *mockYieldPeer) GetTotalValue(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	if m.getTotalValueFunc != nil {
		return m.getTotalValueFunc(runtime, blockNumber)
	}
	return cre.PromiseFromResult[*big.Int](nil, errors.New("getTotalValueFunc not set"))
}

/*//////////////////////////////////////////////////////////////
                             TESTS
//////////////////////////////////////////////////////////////*/

func Test_ReadCurrentStrategy_success(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	var expectedProtocolId [32]byte
	copy(expectedProtocolId[:], []byte("test-protocol-id-123456789012"))
	expectedChainSelector := uint64(12345)

	expectedStrategy := parent_peer.IYieldPeerStrategy{
		ProtocolId:    expectedProtocolId,
		ChainSelector: expectedChainSelector,
	}

	mockPeer := &mockParentPeer{
		getStrategyFunc: func(_ cre.Runtime, blockNumber *big.Int) cre.Promise[parent_peer.IYieldPeerStrategy] {
			expectedBlock := big.NewInt(LatestBlock)
			require.Equal(t, 0, expectedBlock.Cmp(blockNumber), "expected LatestBlock")

			return cre.PromiseFromResult(expectedStrategy, nil)
		},
	}

	strategy, err := ReadCurrentStrategy(mockPeer, runtime)
	require.NoError(t, err)

	require.Equal(t, expectedProtocolId, strategy.ProtocolId)
	require.Equal(t, expectedChainSelector, strategy.ChainSelector)
}

func Test_ReadCurrentStrategy_error(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	expectedError := errors.New("failed to read strategy")

	mockPeer := &mockParentPeer{
		getStrategyFunc: func(_ cre.Runtime, _ *big.Int) cre.Promise[parent_peer.IYieldPeerStrategy] {
			return cre.PromiseFromResult[parent_peer.IYieldPeerStrategy](
				parent_peer.IYieldPeerStrategy{},
				expectedError,
			)
		},
	}

	strategy, err := ReadCurrentStrategy(mockPeer, runtime)
	require.Error(t, err)
	require.ErrorIs(t, err, expectedError)

	require.Equal(t, Strategy{}, strategy, "expected empty strategy on error")
}

func Test_ReadCurrentStrategy_withDifferentValues(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	var protocolId [32]byte
	copy(protocolId[:], []byte("different-protocol-123456789012"))
	chainSelector := uint64(99999)

	expectedStrategy := parent_peer.IYieldPeerStrategy{
		ProtocolId:    protocolId,
		ChainSelector: chainSelector,
	}

	mockPeer := &mockParentPeer{
		getStrategyFunc: func(_ cre.Runtime, _ *big.Int) cre.Promise[parent_peer.IYieldPeerStrategy] {
			return cre.PromiseFromResult(expectedStrategy, nil)
		},
	}

	strategy, err := ReadCurrentStrategy(mockPeer, runtime)
	require.NoError(t, err)

	require.Equal(t, protocolId, strategy.ProtocolId)
	require.Equal(t, chainSelector, strategy.ChainSelector)
}

func Test_ReadTVL_success(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	expectedTVL := big.NewInt(1_000_000_000_000_000_000) // 1 ETH in wei

	mockPeer := &mockYieldPeer{
		getTotalValueFunc: func(_ cre.Runtime, blockNumber *big.Int) cre.Promise[*big.Int] {
			expectedBlock := big.NewInt(LatestBlock)
			require.Equal(t, 0, expectedBlock.Cmp(blockNumber), "expected LatestBlock")

			return cre.PromiseFromResult(expectedTVL, nil)
		},
	}

	tvl, err := ReadTVL(mockPeer, runtime)
	require.NoError(t, err)
	require.NotNil(t, tvl)
	require.Equal(t, 0, expectedTVL.Cmp(tvl))
}

func Test_ReadTVL_error(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	expectedError := errors.New("failed to read TVL")

	mockPeer := &mockYieldPeer{
		getTotalValueFunc: func(_ cre.Runtime, _ *big.Int) cre.Promise[*big.Int] {
			return cre.PromiseFromResult[*big.Int](nil, expectedError)
		},
	}

	tvl, err := ReadTVL(mockPeer, runtime)
	require.Error(t, err)
	require.ErrorIs(t, err, expectedError)
	require.Nil(t, tvl)
}

func Test_ReadTVL_withDifferentValues(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	expectedTVL := big.NewInt(5_000_000_000_000_000_000) // 5 ETH in wei

	mockPeer := &mockYieldPeer{
		getTotalValueFunc: func(_ cre.Runtime, _ *big.Int) cre.Promise[*big.Int] {
			return cre.PromiseFromResult(expectedTVL, nil)
		},
	}

	tvl, err := ReadTVL(mockPeer, runtime)
	require.NoError(t, err)
	require.NotNil(t, tvl)
	require.Equal(t, 0, expectedTVL.Cmp(tvl))
}

func Test_ReadTVL_withZeroValue(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	expectedTVL := big.NewInt(0)

	mockPeer := &mockYieldPeer{
		getTotalValueFunc: func(_ cre.Runtime, _ *big.Int) cre.Promise[*big.Int] {
			return cre.PromiseFromResult(expectedTVL, nil)
		},
	}

	tvl, err := ReadTVL(mockPeer, runtime)
	require.NoError(t, err)
	require.NotNil(t, tvl)
	require.Equal(t, 0, expectedTVL.Cmp(tvl))
}
