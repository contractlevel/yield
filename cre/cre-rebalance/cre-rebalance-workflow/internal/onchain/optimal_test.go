package onchain

import (
	"fmt"
	"math"
	"math/big"
	"strings"
	"testing"

	"cre-rebalance/cre-rebalance-workflow/internal/helper"

	"github.com/smartcontractkit/cre-sdk-go/cre"
)

/*//////////////////////////////////////////////////////////////
                          SAME STRATEGY
//////////////////////////////////////////////////////////////*/

func Test_sameStrategy(t *testing.T) {
	a := Strategy{
		ProtocolId:    AaveV3ProtocolId,
		ChainSelector: 123,
	}
	b := Strategy{
		ProtocolId:    AaveV3ProtocolId,
		ChainSelector: 123,
	}
	c := Strategy{
		ProtocolId:    CompoundV3ProtocolId,
		ChainSelector: 123,
	}
	d := Strategy{
		ProtocolId:    AaveV3ProtocolId,
		ChainSelector: 456,
	}

	if !sameStrategy(a, b) {
		t.Fatalf("expected sameStrategy to return true for identical strategies")
	}
	if sameStrategy(a, c) {
		t.Fatalf("expected sameStrategy to return false for different protocolIds")
	}
	if sameStrategy(a, d) {
		t.Fatalf("expected sameStrategy to return false for different chainSelectors")
	}
}

/*//////////////////////////////////////////////////////////////
              CALCULATE APY FOR STRATEGY (WITH DEPS)
//////////////////////////////////////////////////////////////*/

func Test_CalculateAPYForStrategy_UnsupportedProtocol(t *testing.T) {
	cfg := &helper.Config{}
	liquidityAdded := big.NewInt(0)

	// ProtocolId that is neither AaveV3ProtocolId nor CompoundV3ProtocolId.
	strategy := Strategy{
		ProtocolId:    [32]byte{0xFF},
		ChainSelector: 123,
	}

	apy, err := CalculateAPYForStrategy(cfg, nil, strategy, liquidityAdded)
	if err == nil {
		t.Fatalf("expected error for unsupported protocolId, got nil")
	}
	if apy != 0 {
		t.Fatalf("expected APY=0 on error, got %v", apy)
	}
}

func Test_calculateAPYForStrategyWithDeps_RoutesToAave(t *testing.T) {
	cfg := &helper.Config{}
	liquidity := big.NewInt(42)

	strategy := Strategy{
		ProtocolId:    AaveV3ProtocolId,
		ChainSelector: 111,
	}

	var (
		aaveCalled     bool
		compoundCalled bool
		gotLiq         *big.Int
		gotChain       uint64
	)

	deps := apyDeps{
		AaveV3GetAPY: func(c *helper.Config, r cre.Runtime, liq *big.Int, chain uint64) (float64, error) {
			aaveCalled = true
			gotLiq = new(big.Int).Set(liq)
			gotChain = chain
			return 0.123, nil
		},
		CompoundV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			compoundCalled = true
			return 0.0, nil
		},
	}

	apy, err := calculateAPYForStrategyWithDeps(cfg, nil, strategy, liquidity, deps)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !aaveCalled {
		t.Fatalf("expected AaveV3GetAPY to be called")
	}
	if compoundCalled {
		t.Fatalf("did not expect CompoundV3GetAPY to be called")
	}
	if apy != 0.123 {
		t.Fatalf("unexpected APY: got %v, want %v", apy, 0.123)
	}
	if gotChain != strategy.ChainSelector {
		t.Fatalf("unexpected chainSelector passed: got %d, want %d", gotChain, strategy.ChainSelector)
	}
	if gotLiq.Cmp(liquidity) != 0 {
		t.Fatalf("unexpected liquidity passed: got %s, want %s", gotLiq.String(), liquidity.String())
	}
}

func Test_calculateAPYForStrategyWithDeps_RoutesToCompound(t *testing.T) {
	cfg := &helper.Config{}
	liquidity := big.NewInt(99)

	strategy := Strategy{
		ProtocolId:    CompoundV3ProtocolId,
		ChainSelector: 222,
	}

	var (
		aaveCalled     bool
		compoundCalled bool
		gotLiq         *big.Int
		gotChain       uint64
	)

	deps := apyDeps{
		AaveV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			aaveCalled = true
			return 0.0, nil
		},
		CompoundV3GetAPY: func(c *helper.Config, r cre.Runtime, liq *big.Int, chain uint64) (float64, error) {
			compoundCalled = true
			gotLiq = new(big.Int).Set(liq)
			gotChain = chain
			return 0.456, nil
		},
	}

	apy, err := calculateAPYForStrategyWithDeps(cfg, nil, strategy, liquidity, deps)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !compoundCalled {
		t.Fatalf("expected CompoundV3GetAPY to be called")
	}
	if aaveCalled {
		t.Fatalf("did not expect AaveV3GetAPY to be called")
	}
	if apy != 0.456 {
		t.Fatalf("unexpected APY: got %v, want %v", apy, 0.456)
	}
	if gotChain != strategy.ChainSelector {
		t.Fatalf("unexpected chainSelector passed: got %d, want %d", gotChain, strategy.ChainSelector)
	}
	if gotLiq.Cmp(liquidity) != 0 {
		t.Fatalf("unexpected liquidity passed: got %s, want %s", gotLiq.String(), liquidity.String())
	}
}

func Test_calculateAPYForStrategyWithDeps_InvalidAPY_NaN(t *testing.T) {
	cfg := &helper.Config{}
	liquidity := big.NewInt(1)

	strategy := Strategy{
		ProtocolId:    AaveV3ProtocolId,
		ChainSelector: 1,
	}

	deps := apyDeps{
		AaveV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			return math.NaN(), nil
		},
		CompoundV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			return 0.0, nil
		},
	}

	apy, err := calculateAPYForStrategyWithDeps(cfg, nil, strategy, liquidity, deps)
	if err == nil {
		t.Fatalf("expected error for NaN APY, got nil")
	}
	if apy != 0 {
		t.Fatalf("expected APY=0 on error, got %v", apy)
	}
}

/*//////////////////////////////////////////////////////////////
         CALCULATE APY FOR STRATEGY – ERROR WRAPPERS
//////////////////////////////////////////////////////////////*/

func Test_calculateAPYForStrategyWithDeps_AaveErrorWrapped(t *testing.T) {
	cfg := &helper.Config{}
	liquidity := big.NewInt(10)

	strategy := Strategy{
		ProtocolId:    AaveV3ProtocolId,
		ChainSelector: 1,
	}

	deps := apyDeps{
		AaveV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			return 0.0, fmt.Errorf("aave-apy-failed")
		},
		CompoundV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			return 0.0, nil
		},
	}

	apy, err := calculateAPYForStrategyWithDeps(cfg, nil, strategy, liquidity, deps)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if !strings.Contains(err.Error(), "getting APY from AaveV3: aave-apy-failed") {
		t.Fatalf("unexpected error: %v", err)
	}
	if apy != 0 {
		t.Fatalf("expected APY=0 on error, got %v", apy)
	}
}

func Test_calculateAPYForStrategyWithDeps_CompoundErrorWrapped(t *testing.T) {
	cfg := &helper.Config{}
	liquidity := big.NewInt(10)

	strategy := Strategy{
		ProtocolId:    CompoundV3ProtocolId,
		ChainSelector: 1,
	}

	deps := apyDeps{
		AaveV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			return 0.0, nil
		},
		CompoundV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			return 0.0, fmt.Errorf("compound-apy-failed")
		},
	}

	apy, err := calculateAPYForStrategyWithDeps(cfg, nil, strategy, liquidity, deps)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if !strings.Contains(err.Error(), "getting APY from CompoundV3: compound-apy-failed") {
		t.Fatalf("unexpected error: %v", err)
	}
	if apy != 0 {
		t.Fatalf("expected APY=0 on error, got %v", apy)
	}
}

/*//////////////////////////////////////////////////////////////
                     GET OPTIMAL STRATEGY
//////////////////////////////////////////////////////////////*/

func Test_GetOptimalStrategy_NoSupportedStrategies(t *testing.T) {
	cfg := &helper.Config{
		Evms: nil, // no chains configured
	}
	liquidityAdded := big.NewInt(1)
	current := Strategy{} // value doesn't matter here

	_, err := GetOptimalStrategy(cfg, nil, current, liquidityAdded)
	if err == nil {
		t.Fatalf("expected error when no supported strategies are configured, got nil")
	}
}

func Test_GetOptimalStrategy_NilLiquidityAdded(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{ChainSelector: 1111},
		},
	}

	current := Strategy{
		ProtocolId:    AaveV3ProtocolId,
		ChainSelector: 1111,
	}

	_, err := GetOptimalStrategy(cfg, nil, current, nil)
	if err == nil {
		t.Fatalf("expected error when liquidityAdded is nil, got nil")
	}
}

func Test_getOptimalStrategyWithDeps_SelectsHighestAPYProtocol(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{ChainSelector: 1111},
		},
	}

	// Current strategy is arbitrary; deps decide which protocol has higher APY.
	current := Strategy{
		ProtocolId:    AaveV3ProtocolId,
		ChainSelector: cfg.Evms[0].ChainSelector,
	}

	liquidityAdded := big.NewInt(100)

	deps := apyDeps{
		AaveV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			// Make Aave strictly better.
			return 0.05, nil
		},
		CompoundV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			return 0.03, nil
		},
	}

	best, err := getOptimalStrategyWithDeps(cfg, nil, current, liquidityAdded, deps)
	if err != nil {
		t.Fatalf("unexpected error in happy path: %v", err)
	}

	if best.ProtocolId != AaveV3ProtocolId {
		t.Fatalf("expected best strategy to be AaveV3, got protocolId %x", best.ProtocolId)
	}
	if best.ChainSelector != cfg.Evms[0].ChainSelector {
		t.Fatalf("unexpected ChainSelector in best strategy: got %d, want %d",
			best.ChainSelector, cfg.Evms[0].ChainSelector)
	}
}

/*//////////////////////////////////////////////////////////////
        GET OPTIMAL STRATEGY – ERROR / ZERO APY WRAPPERS
//////////////////////////////////////////////////////////////*/

func Test_getOptimalStrategyWithDeps_ErrorWhenAPYCalculationFails(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{ChainSelector: 1111},
		},
	}

	current := Strategy{
		ProtocolId:    AaveV3ProtocolId,
		ChainSelector: cfg.Evms[0].ChainSelector,
	}
	liquidityAdded := big.NewInt(50)

	// Both protocols fail so the loop will hit the wrapped error:
	// "calculate APY for strategy %+v: %w".
	deps := apyDeps{
		AaveV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			return 0.0, fmt.Errorf("aave-apy-failed")
		},
		CompoundV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			return 0.0, fmt.Errorf("compound-apy-failed")
		},
	}

	_, err := getOptimalStrategyWithDeps(cfg, nil, current, liquidityAdded, deps)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if !strings.Contains(err.Error(), "calculate APY for strategy") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func Test_getOptimalStrategyWithDeps_ErrorWhenZeroAPY(t *testing.T) {
	cfg := &helper.Config{
		Evms: []helper.EvmConfig{
			{ChainSelector: 1111},
		},
	}

	current := Strategy{
		ProtocolId:    AaveV3ProtocolId,
		ChainSelector: cfg.Evms[0].ChainSelector,
	}
	liquidityAdded := big.NewInt(50)

	// Both protocols return 0 without error, so the first one will trigger:
	// "0 APY returned for strategy %+v".
	deps := apyDeps{
		AaveV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			return 0.0, nil
		},
		CompoundV3GetAPY: func(*helper.Config, cre.Runtime, *big.Int, uint64) (float64, error) {
			return 0.0, nil
		},
	}

	_, err := getOptimalStrategyWithDeps(cfg, nil, current, liquidityAdded, deps)
	if err == nil {
		t.Fatalf("expected error for 0 APY, got nil")
	}
	if !strings.Contains(err.Error(), "0 APY returned for strategy") {
		t.Fatalf("unexpected error: %v", err)
	}
}
