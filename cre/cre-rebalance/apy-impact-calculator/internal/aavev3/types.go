package aaveV3

import "math/big"

// ReserveData stores data fetched from AAVE contracts
type ReserveData struct {
	TotalSupply          *big.Int
	TotalBorrow          *big.Int
	ReserveFactor        *big.Int
	OptimalUsage         *big.Int
	BaseRate             *big.Int
	Slope1               *big.Int
	Slope2               *big.Int
	CurrentLiquidityRate *big.Int // Annual liquidity rate (APR) in RAY from contract
}

// InterestRateParams holds interest rate parameters from the strategy contract
type InterestRateParams struct {
	OptimalUsage *big.Int
	BaseRate     *big.Int
	Slope1       *big.Int
	Slope2       *big.Int
}

// ChainResult stores the calculation result for one chain
type ChainResult struct {
	ChainName          string  `json:"chainName"`
	CurrentTotalSupply float64 `json:"currentTotalSupply"`
	CurrentTotalBorrow float64 `json:"currentTotalBorrow"`
	CurrentUtilization float64 `json:"currentUtilization"`
	CurrentAPY         float64 `json:"currentAPY"`
	NewTotalSupply     float64 `json:"newTotalSupply"`
	NewUtilization     float64 `json:"newUtilization"`
	NewAPY             float64 `json:"newAPY"`
	APYChange          float64 `json:"apyChange"`
	UtilizationChange  float64 `json:"utilizationChange"`
}

// TargetChain represents the chain with the highest projected APY (NewAPY).
// Fields marked "for other workflows" are the only ones that should be used by downstream workflows.
// Other fields (newAPY, chainName) are included for verification/debugging purposes only.
type TargetChain struct {
	// Fields for use by other workflows:
	ChainSelector     uint64 `json:"chainSelector"`     // Chainlink chain selector for routing
	StablecoinId      string `json:"stablecoinId"`      // Stablecoin identifier: "USDC" or "USDT"
	StablecoinAddress string `json:"stablecoinAddress"` // Stablecoin contract address on the target chain (needed?)

	// Fields for verification/debugging
	NewAPY    float64 `json:"newAPY"`    // Projected APY after deposit
	ChainName string  `json:"chainName"` // Readable chain name
}
