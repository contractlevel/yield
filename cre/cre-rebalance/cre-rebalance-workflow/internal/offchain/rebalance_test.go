package offchain

import (
	"fmt"
	"strings"
	"testing"

	"cre-rebalance/cre-rebalance-workflow/internal/onchain"
	"cre-rebalance/cre-rebalance-workflow/internal/offchain"
)

func Test_RebalanceIfNeeded_writeFn_notCalledWhen_currentStrategyIsOptimal(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)
	logger := runtime.Logger()

	current := onchain.Strategy{
		ProtocolId:    [32]byte{1},
		ChainSelector: 10,
	}
	optimal := current

	called := false
	writeFn := func(opt onchain.Strategy) error {
		called = true
		return nil
	}

	res, err := RebalanceIfNeeded(logger, current, optimal, writeFn)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if called {
		t.Fatalf("writeFn should not be called when strategies are equal")
	}
	if res == nil {
		t.Fatalf("expected non-nil result")
	}
	if res.Updated {
		t.Fatalf("expected Updated=false when strategies are equal")
	}
	if res.Current != current || res.Optimal != optimal {
		t.Fatalf("unexpected result strategies: got %+v", res)
	}
}

func Test_RebalanceIfNeeded_writeFn_calledWhen_currentStrategyIsDifferentFromOptimal(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)
	logger := runtime.Logger()

	current := onchain.Strategy{
		ProtocolId:    [32]byte{1},
		ChainSelector: 10,
	}
	optimal := onchain.Strategy{
		ProtocolId:    [32]byte{2},
		ChainSelector: 10,
	}

	callCount := 0
	var received onchain.Strategy

	writeFn := func(opt onchain.Strategy) error {
		callCount++
		received = opt
		return nil
	}

	res, err := RebalanceIfNeeded(logger, current, optimal, writeFn)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if callCount != 1 {
		t.Fatalf("expected writeFn to be called once, got %d", callCount)
	}
	if received != optimal {
		t.Fatalf("writeFn received unexpected strategy: got %+v, want %+v", received, optimal)
	}
	if res == nil {
		t.Fatalf("expected non-nil result")
	}
	if !res.Updated {
		t.Fatalf("expected Updated=true when strategies differ")
	}
	if res.Current != current || res.Optimal != optimal {
		t.Fatalf("unexpected result strategies: got %+v", res)
	}
}

func Test_RebalanceIfNeeded_writeFn_errorIsPropagated(t *testing.T) {
	runtime := testutils.NewRuntime(t, nil)
	logger := runtime.Logger()

	current := onchain.Strategy{
		ProtocolId:    [32]byte{1},
		ChainSelector: 10,
	}
	optimal := onchain.Strategy{
		ProtocolId:    [32]byte{2},
		ChainSelector: 10,
	}

	expectedErr := fmt.Errorf("boom")
	writeFn := func(opt onchain.Strategy) error {
		return expectedErr
	}

	res, err := RebalanceIfNeeded(logger, current, optimal, writeFn)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if !strings.Contains(err.Error(), "boom") {
		t.Fatalf("unexpected error: %v", err)
	}
	if res != nil {
		t.Fatalf("expected nil result when writeFn fails, got %+v", res)
	}
}

func Fuzz_decideAndMaybeRebalance(f *testing.F) {
	runtime := testutils.NewRuntime(f, nil)
	logger := runtime.Logger()

	// Seed corpus with a couple of deterministic examples
	f.Add(uint8(1), uint64(10), uint8(1), uint64(10)) // equal
	f.Add(uint8(1), uint64(10), uint8(2), uint64(10)) // different

	f.Fuzz(func(t *testing.T, protocolA uint8, chainSelectorA uint64, protocolB uint8, chainSelectorB uint64) {
		// Simple way to build ProtocolId from a byte; rest zero.
		var idA, idB [32]byte
		idA[0] = protocolA
		idB[0] = protocolB

		current := onchain.Strategy{
			ProtocolId:    idA,
			ChainSelector: chainSelectorA,
		}
		optimal := onchain.Strategy{
			ProtocolId:    idB,
			ChainSelector: chainSelectorB,
		}

		callCount := 0
		writeFn := func(opt onchain.Strategy) error {
			callCount++
			return nil
		}

		res, err := RebalanceIfNeeded(logger, current, optimal, writeFn)
		if err != nil {
			// By construction, RebalanceIfNeeded only returns an error
			// from writeFn; our writeFn never errors.
			t.Fatalf("unexpected error: %v", err)
		}
		if res == nil {
			t.Fatalf("expected non-nil result")
		}

		if current == optimal {
			if callCount != 0 {
				t.Fatalf("writeFn called %d times when strategies equal", callCount)
			}
			if res.Updated {
				t.Fatalf("Updated should be false when strategies equal")
			}
		} else {
			if callCount != 1 {
				t.Fatalf("writeFn called %d times when strategies differ", callCount)
			}
			if !res.Updated {
				t.Fatalf("Updated should be true when strategies differ")
			}
		}
	})
}