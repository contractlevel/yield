package onchain

import (
	"errors"
	"math/big"
	"testing"

	"cre-rebalance/contracts/evm/src/generated/parent_peer"
	"cre-rebalance/contracts/evm/src/generated/strategy_helper"

	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"github.com/ethereum/go-ethereum/common"
)

/*//////////////////////////////////////////////////////////////
                             MOCKS
//////////////////////////////////////////////////////////////*/
// mockParentPeer is a mock implementation of ParentPeerInterface for testing
type mockParentPeer struct {
	getStrategyFunc  func(cre.Runtime, *big.Int) cre.Promise[parent_peer.IYieldPeerStrategy]
	getTotalValueFunc func(cre.Runtime, *big.Int) cre.Promise[*big.Int]
}

func (m *mockParentPeer) GetStrategy(
	runtime cre.Runtime,
	blockNumber *big.Int,
) cre.Promise[parent_peer.IYieldPeerStrategy] {
	if m.getStrategyFunc != nil {
		return m.getStrategyFunc(runtime, blockNumber)
	}
	return cre.PromiseFromResult[parent_peer.IYieldPeerStrategy](parent_peer.IYieldPeerStrategy{}, errors.New("getStrategyFunc not set"))
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

// mockYieldPeer is a mock implementation of YieldPeerInterface for testing
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

// mockStrategyHelper is a mock implementation of StrategyHelperInterface for testing.
type mockStrategyHelper struct {
	getAaveAPRFunc func(cre.Runtime, strategy_helper.GetAaveAPRInput, *big.Int) cre.Promise[*big.Int]
}

func (m *mockStrategyHelper) GetAaveAPR(
	runtime cre.Runtime,
	args strategy_helper.GetAaveAPRInput,
	blockNumber *big.Int,
) cre.Promise[*big.Int] {
	if m.getAaveAPRFunc != nil {
		return m.getAaveAPRFunc(runtime, args, blockNumber)
	}
	return cre.PromiseFromResult[*big.Int](nil, errors.New("getAaveAPRFunc not set"))
}

/*//////////////////////////////////////////////////////////////
                             TESTS
//////////////////////////////////////////////////////////////*/
func Test_ReadCurrentStrategy_Success(t *testing.T) {
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
			// Verify the block number is LatestBlock
			expectedBlock := big.NewInt(LatestBlock)
			if blockNumber.Cmp(expectedBlock) != 0 {
				t.Errorf("expected blockNumber %v, got %v", expectedBlock, blockNumber)
			}

			return cre.PromiseFromResult(expectedStrategy, nil)
		},
	}

	strategy, err := ReadCurrentStrategy(mockPeer, runtime)
	if err != nil {
		t.Fatalf("ReadCurrentStrategy returned unexpected error: %v", err)
	}

	if strategy.ProtocolId != expectedProtocolId {
		t.Errorf("expected ProtocolId %v, got %v", expectedProtocolId, strategy.ProtocolId)
	}

	if strategy.ChainSelector != expectedChainSelector {
		t.Errorf("expected ChainSelector %d, got %d", expectedChainSelector, strategy.ChainSelector)
	}
}

func Test_ReadCurrentStrategy_Error(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	expectedError := errors.New("failed to read strategy")

	mockPeer := &mockParentPeer{
		getStrategyFunc: func(_ cre.Runtime, _ *big.Int) cre.Promise[parent_peer.IYieldPeerStrategy] {
			return cre.PromiseFromResult[parent_peer.IYieldPeerStrategy](parent_peer.IYieldPeerStrategy{}, expectedError)
		},
	}

	strategy, err := ReadCurrentStrategy(mockPeer, runtime)
	if err == nil {
		t.Fatal("ReadCurrentStrategy expected error but got nil")
	}

	if !errors.Is(err, expectedError) {
		t.Errorf("expected error %v, got %v", expectedError, err)
	}

	// Verify that an empty strategy is returned on error
	emptyStrategy := Strategy{}
	if strategy != emptyStrategy {
		t.Errorf("expected empty strategy on error, got %v", strategy)
	}
}

func Test_ReadCurrentStrategy_WithDifferentValues(t *testing.T) {
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
	if err != nil {
		t.Fatalf("ReadCurrentStrategy returned unexpected error: %v", err)
	}

	if strategy.ProtocolId != protocolId {
		t.Errorf("expected ProtocolId %v, got %v", protocolId, strategy.ProtocolId)
	}

	if strategy.ChainSelector != chainSelector {
		t.Errorf("expected ChainSelector %d, got %d", chainSelector, strategy.ChainSelector)
	}
}

func Test_ReadTVL_Success(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	expectedTVL := big.NewInt(1000000000000000000) // 1 ETH in wei

	mockPeer := &mockYieldPeer{
		getTotalValueFunc: func(_ cre.Runtime, blockNumber *big.Int) cre.Promise[*big.Int] {
			// Verify the block number is LatestBlock
			expectedBlock := big.NewInt(LatestBlock)
			if blockNumber.Cmp(expectedBlock) != 0 {
				t.Errorf("expected blockNumber %v, got %v", expectedBlock, blockNumber)
			}

			return cre.PromiseFromResult(expectedTVL, nil)
		},
	}

	tvl, err := ReadTVL(mockPeer, runtime)
	if err != nil {
		t.Fatalf("ReadTVL returned unexpected error: %v", err)
	}

	if tvl == nil {
		t.Fatal("ReadTVL returned nil TVL")
	}

	if tvl.Cmp(expectedTVL) != 0 {
		t.Errorf("expected TVL %v, got %v", expectedTVL, tvl)
	}
}

func Test_ReadTVL_Error(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	expectedError := errors.New("failed to read TVL")

	mockPeer := &mockYieldPeer{
		getTotalValueFunc: func(_ cre.Runtime, _ *big.Int) cre.Promise[*big.Int] {
			return cre.PromiseFromResult[*big.Int](nil, expectedError)
		},
	}

	tvl, err := ReadTVL(mockPeer, runtime)
	if err == nil {
		t.Fatal("ReadTVL expected error but got nil")
	}

	if !errors.Is(err, expectedError) {
		t.Errorf("expected error %v, got %v", expectedError, err)
	}

	if tvl != nil {
		t.Errorf("expected nil TVL on error, got %v", tvl)
	}
}

func Test_ReadTVL_WithDifferentValues(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	expectedTVL := big.NewInt(5000000000000000000) // 5 ETH in wei

	mockPeer := &mockYieldPeer{
		getTotalValueFunc: func(_ cre.Runtime, _ *big.Int) cre.Promise[*big.Int] {
			return cre.PromiseFromResult(expectedTVL, nil)
		},
	}

	tvl, err := ReadTVL(mockPeer, runtime)
	if err != nil {
		t.Fatalf("ReadTVL returned unexpected error: %v", err)
	}

	if tvl.Cmp(expectedTVL) != 0 {
		t.Errorf("expected TVL %v, got %v", expectedTVL, tvl)
	}
}

func Test_ReadTVL_WithZeroValue(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	expectedTVL := big.NewInt(0)

	mockPeer := &mockYieldPeer{
		getTotalValueFunc: func(_ cre.Runtime, _ *big.Int) cre.Promise[*big.Int] {
			return cre.PromiseFromResult(expectedTVL, nil)
		},
	}

	tvl, err := ReadTVL(mockPeer, runtime)
	if err != nil {
		t.Fatalf("ReadTVL returned unexpected error: %v", err)
	}

	if tvl.Cmp(expectedTVL) != 0 {
		t.Errorf("expected TVL %v, got %v", expectedTVL, tvl)
	}
}

func Test_ReadAaveAPR_Success(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	liquidityAdded := big.NewInt(0) // current APR path
	asset := common.HexToAddress("0x00000000000000000000000000000000000000Aa")
	expectedAPR := big.NewInt(123456789)

	mockHelper := &mockStrategyHelper{
		getAaveAPRFunc: func(_ cre.Runtime, args strategy_helper.GetAaveAPRInput, blockNumber *big.Int) cre.Promise[*big.Int] {
			// Verify block number
			expectedBlock := big.NewInt(LatestBlock)
			if blockNumber.Cmp(expectedBlock) != 0 {
				t.Errorf("expected blockNumber %v, got %v", expectedBlock, blockNumber)
			}

			// Verify args passthrough
			if args.LiquidityAdded == nil || args.LiquidityAdded.Cmp(liquidityAdded) != 0 {
				t.Errorf("expected LiquidityAdded %v, got %v", liquidityAdded, args.LiquidityAdded)
			}
			if args.Asset != asset {
				t.Errorf("expected Asset %v, got %v", asset, args.Asset)
			}

			return cre.PromiseFromResult(expectedAPR, nil)
		},
	}

	apr, err := ReadAaveAPR(mockHelper, runtime, liquidityAdded, asset)
	if err != nil {
		t.Fatalf("ReadAaveAPR returned unexpected error: %v", err)
	}
	if apr == nil {
		t.Fatal("ReadAaveAPR returned nil apr")
	}
	if apr.Cmp(expectedAPR) != 0 {
		t.Errorf("expected apr %v, got %v", expectedAPR, apr)
	}
}

func Test_ReadAaveAPR_Error(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)

	liquidityAdded := big.NewInt(1000) // simulate deposit
	asset := common.HexToAddress("0x00000000000000000000000000000000000000Bb")
	expectedErr := errors.New("failed to read apr")

	mockHelper := &mockStrategyHelper{
		getAaveAPRFunc: func(_ cre.Runtime, _ strategy_helper.GetAaveAPRInput, _ *big.Int) cre.Promise[*big.Int] {
			return cre.PromiseFromResult[*big.Int](nil, expectedErr)
		},
	}

	apr, err := ReadAaveAPR(mockHelper, runtime, liquidityAdded, asset)
	if err == nil {
		t.Fatal("ReadAaveAPR expected error but got nil")
	}
	if !errors.Is(err, expectedErr) {
		t.Errorf("expected error %v, got %v", expectedErr, err)
	}
	if apr != nil {
		t.Errorf("expected nil apr on error, got %v", apr)
	}
}