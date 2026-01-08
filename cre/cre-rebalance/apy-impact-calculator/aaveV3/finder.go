package aaveV3

import (
	"fmt"
	"strconv"
)

// FindBestChain finds the chain with the highest projected APY (NewAPY) from the results.
func FindBestChain(results []ChainResult, chainConfigs []ChainConfig) (*TargetChain, error) {
	if len(results) == 0 {
		return nil, fmt.Errorf("no results to find best chain")
	}

	var bestResult ChainResult
	var bestConfig ChainConfig
	var bestAPY float64
	found := false

	// Find the result with the highest NewAPY
	for _, result := range results {
		newAPY, err := strconv.ParseFloat(result.NewAPY, 64)
		if err != nil {
			continue
		}

		if !found || newAPY > bestAPY {
			bestAPY = newAPY
			bestResult = result
			found = true
		}
	}

	if !found {
		return nil, fmt.Errorf("no valid results found")
	}

	// Find the matching chain config
	for _, cfg := range chainConfigs {
		if cfg.ChainName == bestResult.ChainName {
			bestConfig = cfg
			break
		}
	}

	if bestConfig.ChainName == "" {
		return nil, fmt.Errorf("chain config not found for chain: %s", bestResult.ChainName)
	}

	stablecoinId := "USDC"

	return &TargetChain{
		ChainSelector:     bestConfig.ChainSelector,
		StablecoinId:      stablecoinId,
		StablecoinAddress: bestConfig.USDCAddress,
		NewAPY:            bestResult.NewAPY,
		ChainName:         bestResult.ChainName,
	}, nil
}
