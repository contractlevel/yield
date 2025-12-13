package main

import (
	"fmt"
	"log/slog"
	"math/big"
	"strings"
	"testing"

	"cre-rebalance/cre-rebalance-workflow/internal/onchain"
	"cre-rebalance/cre-rebalance-workflow/internal/offchain"

	"github.com/ethereum/go-ethereum/crypto"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/scheduler/cron"
	"github.com/smartcontractkit/cre-sdk-go/cre"
	"github.com/smartcontractkit/cre-sdk-go/cre/testutils"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func Fuzz_calculateOptimalStrategy(f *testing.F) {
	runtime := testutils.NewRuntime(f, nil)
	logger := runtime.Logger()

	// Seed example inputs (protocol byte, chain selector, tvl)
	f.Add(uint8(1), uint64(10), int64(0))
	f.Add(uint8(2), uint64(42), int64(100))
	f.Add(uint8(255), uint64(0), int64(-12345)) // negative tvl to exercise normalization

	f.Fuzz(func(t *testing.T, protoByte uint8, chainSel uint64, tvlRaw int64) {
		// Build a Strategy whose ProtocolId is derived from a single byte.
		var id [32]byte
		id[0] = protoByte

		current := onchain.Strategy{
			ProtocolId:    id,
			ChainSelector: chainSel,
		}

		// Ensure tvl is non-negative; real-world TVL should not be negative.
		if tvlRaw < 0 {
			tvlRaw = -tvlRaw
		}
		tvl := big.NewInt(tvlRaw)

		optimal := calculateOptimalStrategy(logger, current, tvl)

		// Invariant: chain selector must not change.
		if optimal.ChainSelector != current.ChainSelector {
			t.Fatalf("calculateOptimalStrategy changed chain selector: current=%d optimal=%d",
				current.ChainSelector, optimal.ChainSelector)
		}

		// Basic sanity: tvl should remain non-negative; if we ever change the function
		// to mutate tvl, this guards against silly mistakes.
		if tvl.Sign() < 0 {
			t.Fatalf("tvl became negative unexpectedly: %s", tvl.String())
		}

		// @review this needs to be revisited when we have a real APY model
	})
}

func Fuzz_onCronTriggerWithDeps(f *testing.F) {
	runtime := testutils.NewRuntime(f, nil)

	// @review this needs to be revisited when we have a real APY model
	// Precompute the protocolId that calculateOptimalStrategy uses when tvl is read.
	// calculateOptimalStrategy always uses dummy-protocol-v1 => keccak hash.
	hashed := crypto.Keccak256([]byte("dummy-protocol-v1"))
	var optimalID [32]byte
	copy(optimalID[:], hashed)

	// Some deterministic seeds to make sure important branches are explored early.
	// Params:
	// parentChain, strategyChain, includeStrategyCfg,
	// invalidParentAddr, invalidStrategyAddr,
	// readStrategyErr, readTVLErr,
	// currentEqualsOptimal,
	// invalidRebalancerAddr, writeErr
	f.Add(uint64(1), uint64(1), true, false, false, false, false, true, false, false)   // unchanged => no write
	f.Add(uint64(1), uint64(1), true, false, false, false, false, false, false, false)  // changed => write success
	f.Add(uint64(1), uint64(2), false, false, false, false, false, false, false, false) // missing strategy cfg
	f.Add(uint64(1), uint64(2), true, false, true, false, false, false, false, false)   // invalid strategy addr
	f.Add(uint64(1), uint64(1), true, true, false, false, false, false, false, false)   // invalid parent addr
	f.Add(uint64(1), uint64(1), true, false, false, true, false, false, false, false)   // read strategy err
	f.Add(uint64(1), uint64(1), true, false, false, false, true, false, false, false)   // read tvl err
	f.Add(uint64(1), uint64(1), true, false, false, false, false, false, true, false)   // invalid rebalancer
	f.Add(uint64(1), uint64(1), true, false, false, false, false, false, false, true)   // write err

	f.Fuzz(func(
		t *testing.T,
		parentChain uint64,
		strategyChain uint64,
		includeStrategyCfg bool,
		invalidParentAddr bool,
		invalidStrategyAddr bool,
		readStrategyErr bool,
		readTVLErr bool,
		currentEqualsOptimal bool,
		invalidRebalancerAddr bool,
		writeErr bool,
	) {
		// Normalize chains to avoid trivial “0 chain selector”
		// (Not strictly necessary, but reduces noise.)
		if parentChain == 0 {
			parentChain = 1
		}
		if strategyChain == 0 {
			strategyChain = 1
		}

		parentYieldPeerAddr := "0x0000000000000000000000000000000000000001"
		if invalidParentAddr {
			parentYieldPeerAddr = "invalid"
		}

		rebalancerAddr := "0x0000000000000000000000000000000000000002"
		if invalidRebalancerAddr {
			rebalancerAddr = "invalid-rebalancer"
		}

		// Build config: always include parent at index 0.
		cfg := &offchain.Config{
			Schedule: "0 */1 * * * *",
			Evms: []offchain.EvmConfig{
				{
					ChainName:         "parent",
					ChainSelector:     parentChain,
					YieldPeerAddress:  parentYieldPeerAddr,
					RebalancerAddress: rebalancerAddr,
					GasLimit:          500000,
				},
			},
		}

		// Optionally include strategy chain config (if cross-chain path is desired).
		if includeStrategyCfg && strategyChain != parentChain {
			strategyYieldPeerAddr := "0x0000000000000000000000000000000000000003"
			if invalidStrategyAddr {
				strategyYieldPeerAddr = "invalid-strategy"
			}
			cfg.Evms = append(cfg.Evms, offchain.EvmConfig{
				ChainName:        "strategy",
				ChainSelector:    strategyChain,
				YieldPeerAddress: strategyYieldPeerAddr,
			})
		}

		// Track whether a write was attempted.
		writeCalls := 0

		deps := offchain.OnCronDeps{
			ReadCurrentStrategy: func(_ onchain.ParentPeerInterface, _ cre.Runtime) (onchain.Strategy, error) {
				if readStrategyErr {
					return onchain.Strategy{}, fmt.Errorf("read-strategy-failed")
				}

				// Choose protocolId so that current == optimal if requested.
				var pid [32]byte
				if currentEqualsOptimal {
					pid = optimalID
				} else {
					pid = [32]byte{1} // definitely not equal to keccak("dummy-protocol-v1")
				}

				return onchain.Strategy{
					ProtocolId:    pid,
					ChainSelector: strategyChain, // drives whether we go cross-chain
				}, nil
			},
			ReadTVL: func(_ onchain.YieldPeerInterface, _ cre.Runtime) (*big.Int, error) {
				if readTVLErr {
					return nil, fmt.Errorf("read-tvl-failed")
				}
				return big.NewInt(123), nil
			},
			WriteRebalance: func(_ onchain.RebalancerInterface, _ cre.Runtime, _ *slog.Logger, _ uint64, _ onchain.Strategy) error {
				writeCalls++
				if writeErr {
					return fmt.Errorf("write-failed")
				}
				return nil
			},
		}

		payload := &cron.Payload{ScheduledExecutionTime: timestamppb.Now()}

		res, err := onCronTriggerWithDeps(cfg, runtime, payload, deps)

		// Now assert expected outcome based on the earliest branch that should trigger.
		switch {
		case invalidParentAddr:
			if err == nil || !strings.Contains(err.Error(), "invalid YieldPeer address") {
				t.Fatalf("expected invalid parent YieldPeer address error, got res=%+v err=%v", res, err)
			}
			if res != nil {
				t.Fatalf("expected nil result on error, got %+v", res)
			}
			if writeCalls != 0 {
				t.Fatalf("expected no writes on parent addr validation failure, got %d", writeCalls)
			}
			return

		case readStrategyErr:
			if err == nil || !strings.Contains(err.Error(), "failed to read strategy from parent YieldPeer") {
				t.Fatalf("expected read strategy error wrapper, got res=%+v err=%v", res, err)
			}
			if res != nil {
				t.Fatalf("expected nil result on error, got %+v", res)
			}
			if writeCalls != 0 {
				t.Fatalf("expected no writes when ReadCurrentStrategy fails, got %d", writeCalls)
			}
			return

		case strategyChain != parentChain && !includeStrategyCfg:
			if err == nil || !strings.Contains(err.Error(), "no EVM config found for strategy chainSelector") {
				t.Fatalf("expected missing strategy cfg error, got res=%+v err=%v", res, err)
			}
			if res != nil {
				t.Fatalf("expected nil result on error, got %+v", res)
			}
			if writeCalls != 0 {
				t.Fatalf("expected no writes when strategy cfg missing, got %d", writeCalls)
			}
			return

		case strategyChain != parentChain && includeStrategyCfg && invalidStrategyAddr:
			if err == nil || !strings.Contains(err.Error(), "invalid YieldPeer address") {
				t.Fatalf("expected invalid strategy YieldPeer address error, got res=%+v err=%v", res, err)
			}
			if res != nil {
				t.Fatalf("expected nil result on error, got %+v", res)
			}
			if writeCalls != 0 {
				t.Fatalf("expected no writes when strategy addr invalid, got %d", writeCalls)
			}
			return

		case readTVLErr:
			if err == nil || !strings.Contains(err.Error(), "failed to get total value from strategy YieldPeer") {
				t.Fatalf("expected ReadTVL error wrapper, got res=%+v err=%v", res, err)
			}
			if res != nil {
				t.Fatalf("expected nil result on error, got %+v", res)
			}
			if writeCalls != 0 {
				t.Fatalf("expected no writes when ReadTVL fails, got %d", writeCalls)
			}
			return
		}

		// If we got here, reads succeeded and we computed optimal strategy.
		// Now the outcome depends on whether strategies match and whether rebalancer is valid/write fails.

		if currentEqualsOptimal {
			// decideAndMaybeRebalance should skip write
			if err != nil {
				t.Fatalf("expected nil error when unchanged, got %v", err)
			}
			if res == nil {
				t.Fatalf("expected non-nil result when unchanged")
			}
			if res.Updated {
				t.Fatalf("expected Updated=false when unchanged")
			}
			if writeCalls != 0 {
				t.Fatalf("expected no writes when unchanged, got %d", writeCalls)
			}
			return
		}

		// Not equal => write path should be attempted, unless rebalancer address invalid.
		if invalidRebalancerAddr {
			if err == nil || !strings.Contains(err.Error(), "invalid Rebalancer address") {
				t.Fatalf("expected invalid rebalancer address error, got res=%+v err=%v", res, err)
			}
			if res != nil {
				t.Fatalf("expected nil result on error, got %+v", res)
			}
			if writeCalls != 0 {
				t.Fatalf("expected WriteRebalance not called when rebalancer addr invalid, got %d", writeCalls)
			}
			return
		}

		if writeErr {
			if err == nil || !strings.Contains(err.Error(), "write-failed") {
				t.Fatalf("expected write-failed error, got res=%+v err=%v", res, err)
			}
			if res != nil {
				t.Fatalf("expected nil result on write error, got %+v", res)
			}
			if writeCalls != 1 {
				t.Fatalf("expected exactly 1 write call on write error, got %d", writeCalls)
			}
			return
		}

		// Success rebalance
		if err != nil {
			t.Fatalf("expected nil error on success, got %v", err)
		}
		if res == nil {
			t.Fatalf("expected non-nil result on success")
		}
		if !res.Updated {
			t.Fatalf("expected Updated=true on success")
		}
		if writeCalls != 1 {
			t.Fatalf("expected exactly 1 write call on success, got %d", writeCalls)
		}
	})
}
