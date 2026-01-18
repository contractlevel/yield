package compoundV3

import (
	"fmt"
	"math/big"

	"rebalance/workflow/internal/helper"
	"rebalance/workflow/internal/constants"

	"rebalance/contracts/evm/src/generated/comet"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// @review placeholder
func GetAPYPromise(config *helper.Config, runtime cre.Runtime, liquidityAdded *big.Int, chainSelector uint64) cre.Promise[float64] {
	return cre.PromiseFromResult(0.0, nil)
}

// @review pass this stablecoin as an arg when doing modular stable support task
func GetAPY(config *helper.Config, runtime cre.Runtime, liquidityAdded *big.Int, chainSelector uint64) (float64, error) {
	// instantiate client
	evmClient := &evm.Client{
		ChainSelector: chainSelector,
	}

	// find chain config
	evmConfig, err := helper.FindEvmConfigByChainSelector(config.Evms, chainSelector)
	if err != nil {
		return 0, fmt.Errorf("failed to find evm config: %w", err)
	}

	// instantiate comet
	cometUSDC, err := NewCometBinding(evmClient, evmConfig.CompoundV3CometUSDCAddress) // @review CometAddr will depend on stablecoin
	if err != nil {
		return 0, fmt.Errorf("failed to create comet binding: %w", err)
	}

	// @review some pseudocode
	totalSupply, err := cometUSDC.TotalSupply(runtime, big.NewInt(config.BlockNumber)).Await()
	if err != nil {
		return 0, fmt.Errorf("failed to get total supply: %w", err)
	}
	if liquidityAdded != nil {
		totalSupply = new(big.Int).Add(totalSupply, liquidityAdded) // ok if liquidityAdded == 0
	}

	totalBorrow, err := cometUSDC.TotalBorrow(runtime, big.NewInt(config.BlockNumber)).Await()
	if err != nil {
		return 0, fmt.Errorf("failed to get total borrow: %w", err)
	}

	// @review why do we need the WAD scaling here?
	// utilization = (borrow * 1e18) / supply 
	utilization := new(big.Int).Mul(totalBorrow, big.NewInt(constants.WAD))
	utilization.Div(utilization, totalSupply)

	supplyRate, err := cometUSDC.GetSupplyRate(runtime, comet.GetSupplyRateInput{Utilization: utilization}, big.NewInt(config.BlockNumber)).Await()
	if err != nil {
		return 0, fmt.Errorf("failed to get supply rate: %w", err)
	}

	// apy = (1 + supplyRate)^secondsPerYear − 1
	apy := APYFromSupplyRate(supplyRate)
	// @review log this and compare to defillama or some other source
	return apy, nil
}

// @review placeholder
func APYFromSupplyRate(supplyRateInWad uint64) float64 {
	return 1
}

// convert supply rate from WAD to RAY