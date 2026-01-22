package compoundV3

import (
	"fmt"
	"math/big"

	"rebalance/contracts/evm/src/generated/comet"
	"rebalance/workflow/internal/constants"
	"rebalance/workflow/internal/helper"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// GetAPYPromise calculates the APY for Compound V3 (Comet) on a specific chain
// and returns a Promise.
// This version returns a Promise instead of awaiting, allowing callers to
// chain or await as needed. [Needs .Await() after this is called]
//
// Parameters:
//   - config: The helper.Config containing all chain configurations
//   - runtime: CRE runtime for contract calls
//   - liquidityAdded: Amount of liquidity being added (use big.NewInt(0) for current APY)
//   - chainSelector: Chain selector to identify which chain config to use
//
// Returns:
//   - Promise of APY as float64 (e.g., 0.0523 = 5.23%)
//   - Error will be returned when Promise is awaited if chain not found or APY calculation fails
func GetAPYPromise(config *helper.Config, runtime cre.Runtime, liquidityAdded *big.Int, chainSelector uint64) cre.Promise[float64] {
	// Find the chain config by chainSelector
	evmCfg, err := helper.FindEvmConfigByChainSelector(config.Evms, chainSelector)
	if err != nil {
		return cre.PromiseFromResult(0.0, fmt.Errorf("chain config not found for chainSelector %d: %w", chainSelector, err))
	}

	// Validate required fields
	if evmCfg.CompoundV3CometUSDCAddress == "" {
		return cre.PromiseFromResult(0.0, fmt.Errorf("CompoundV3CometUSDCAddress not configured for chain %s", evmCfg.ChainName))
	}

	// We allow liquidityAdded == 0, but not nil (nil would panic on .Sign())
	if liquidityAdded == nil {
		return cre.PromiseFromResult(0.0, fmt.Errorf("liquidityAdded cannot be nil (use big.NewInt(0) for zero value)"))
	}

	// Step 1: Create EVM client for this chain
	evmClient := &evm.Client{
		ChainSelector: evmCfg.ChainSelector,
	}

	// Step 2: Create Comet binding
	cometUSDC, err := newCometBindingFunc(evmClient, evmCfg.CompoundV3CometUSDCAddress) // @review CometAddr will depend on stablecoin
	if err != nil {
		return cre.PromiseFromResult(0.0, fmt.Errorf("failed to create Comet binding for chain %s: %w", evmCfg.ChainName, err))
	}

	blockNumber := big.NewInt(config.BlockNumber)

	// Step 3: TotalSupply at the configured block
	totalSupplyPromise := cometUSDC.TotalSupply(runtime, blockNumber)

	// Step 4+: Chain the rest of the pipeline:
	//   totalSupply -> (optionally + liquidityAdded)
	//   -> totalBorrow
	//   -> utilization
	//   -> supplyRate
	//   -> APY
	return cre.ThenPromise(totalSupplyPromise, func(totalSupply *big.Int) cre.Promise[float64] {
		// Include hypothetical liquidity if non-zero
		if liquidityAdded.Sign() != 0 {
			totalSupply = new(big.Int).Add(totalSupply, liquidityAdded)
		}

		if totalSupply.Sign() == 0 {
			return cre.PromiseFromResult(0.0, fmt.Errorf("total supply is zero, cannot compute utilization"))
		}

		// Fetch total borrow
		totalBorrowPromise := cometUSDC.TotalBorrow(runtime, blockNumber)

		return cre.ThenPromise(totalBorrowPromise, func(totalBorrow *big.Int) cre.Promise[float64] {
			// utilization = (borrow * 1e18) / supply
			utilization := new(big.Int).Mul(totalBorrow, big.NewInt(constants.WAD))
			utilization.Div(utilization, totalSupply)

			// Get supply rate from Comet
			input := comet.GetSupplyRateInput{
				Utilization: utilization,
			}

			supplyRatePromise := cometUSDC.GetSupplyRate(runtime, input, blockNumber)

			return cre.ThenPromise(supplyRatePromise, func(supplyRate uint64) cre.Promise[float64] {
				apy := calculateAPYFromSupplyRate(supplyRate)
				return cre.PromiseFromResult(apy, nil)
			})
		})
	})
}
