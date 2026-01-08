package aaveV3

import (
	"math/big"

	"github.com/ethereum/go-ethereum/common"
)

// https://github.com/aave-dao/aave-v3-origin/blob/main/src/contracts/protocol/libraries/types/DataTypes.sol#L314
// Used in DefaultReserveInterestRateStrategy.calculateInterestRates
type CalculateInterestRatesParams struct {
	Unbacked                 *big.Int
	LiquidityAdded           *big.Int
	LiquidityTaken           *big.Int
	TotalDebt                *big.Int
	ReserveFactor            *big.Int
	Reserve                  common.Address
	UsingVirtualBalance      bool
	VirtualUnderlyingBalance *big.Int
}

// ChainConfig represents the configuration for a single chain (for workflow config)
type ChainConfig struct {
	ChainName             string `json:"chainName"`
	ChainSelector         uint64 `json:"chainSelector"`
	PoolAddressesProvider string `json:"poolAddressesProvider"`
	USDCAddress           string `json:"usdcAddress"`
}

// ChainResult stores the calculation result for one chain
type ChainResult struct {
	ChainName          string `json:"chainName"`
	CurrentTotalSupply string `json:"currentTotalSupply"`
	CurrentTotalBorrow string `json:"currentTotalBorrow"`
	CurrentUtilization string `json:"currentUtilization"`
	CurrentAPY         string `json:"currentAPY"`
	NewTotalSupply     string `json:"newTotalSupply"`
	NewUtilization     string `json:"newUtilization"`
	NewAPY             string `json:"newAPY"`
	APYChange          string `json:"apyChange"`
	UtilizationChange  string `json:"utilizationChange"`
}

// TargetChain represents the chain with the highest projected APY (NewAPY).
type TargetChain struct {
	// Fields for use by other workflows:
	ChainSelector     uint64 `json:"chainSelector"`     // Chainlink chain selector for routing
	StablecoinId      string `json:"stablecoinId"`      // Stablecoin identifier: "USDC" or "USDT"
	StablecoinAddress string `json:"stablecoinAddress"` // Stablecoin contract address on the target chain

	// Fields for verification/debugging
	NewAPY    string `json:"newAPY"`    // Projected APY after deposit
	ChainName string `json:"chainName"` // Readable chain name
}
