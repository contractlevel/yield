package compoundV3

import (
	"math/big"

	"cre-rebalance/cre-rebalance-workflow/internal/helper"

	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
)

// @review pass this stablecoin as an arg when doing modular stable support task
func GetAPY(config *helper.Config, liquidityAdded *big.Int, chainSelector int64) (*big.Int, error) {
	// instantiate client
	evmClient := &evm.Client{
		ChainSelector: chainSelector,
	}

	// find chain config
	evmConfig, err := helper.FindEvmConfigByChainSelector(config.Evms, chainSelector)
	if err != nil {
		return nil, fmt.Errorf("failed to find evm config: %w", err)
	}

	// instantiate comet
	comet, err := NewCometBinding(evmClient, evmConfig.CometAddr) // @review CometAddr will depend on stablecoin
	if err != nil {
		return nil, fmt.Errorf("failed to create comet binding: %w", err)
	}

	// @review some pseudocode
	totalSupply, err := comet.GetTotalSupply()
	if err != nil {
		return nil, fmt.Errorf("failed to get total supply: %w", err)
	}
	if liquidityAdded != nil {
		totalSupply = new(big.Int).Add(totalSupply, liquidityAdded) // ok if liquidityAdded == 0
	}

	totalBorrow, err := comet.GetTotalBorrow()
	if err != nil {
		return nil, fmt.Errorf("failed to get total borrow: %w", err)
	}

	// @review why do we need the WAD scaling here?
	// utilization = (borrow * 1e18) / supply 
	utilization := new(big.Int).Mul(totalBorrow, WAD)
	utilization.Div(utilization, totalSupply)
	
	supplyRate, err := comet.GetSupplyRate(utilization)
	if err != nil {
		return nil, fmt.Errorf("failed to get supply rate: %w", err)
	}

	// apy = (1 + supplyRate)^secondsPerYear − 1
	apy := APYFromSupplyRate(supplyRate)
	// @review log this and compare to 
	return apy, nil
}

// rpsWad = rate per second in WAD
func APYFromSupplyRate(rpsWad *big.Int) *big.Int {
	base := new(big.Int).Add(WAD, rpsWad)
	growth := powWad(base, SecondsPerYear)
	return new(big.Int).Sub(growth, WAD)
}

func powWad(xWad *big.Int, n uint64) *big.Int {
	res := new(big.Int).Set(WAD)
	base := new(big.Int).Set(xWad)

	for n > 0 {
		if n&1 == 1 {
			res = mulWad(res, base)
		}
		n >>= 1
		if n > 0 {
			base = mulWad(base, base)
		}
	}
	return res
}

func mulWad(a, b *big.Int) *big.Int {
	z := new(big.Int).Mul(a, b)
	z.Div(z, WAD)
	return z
}
