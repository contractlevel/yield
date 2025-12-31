package aavev3

import (
	"math/big"

	"github.com/ethereum/go-ethereum/common"
)

// ChainResult stores the calculation result for one chain.
// All numeric values are stored as strings to preserve precision.
type ChainResult struct {
	ChainName          string `json:"chainName"`
	CurrentTotalSupply string `json:"currentTotalSupply"` // USDC amount as string
	CurrentTotalBorrow string `json:"currentTotalBorrow"` // USDC amount as string
	CurrentUtilization string `json:"currentUtilization"` // Ratio as string (0-1)
	CurrentAPY         string `json:"currentAPY"`         // APY as string (e.g., "0.0523" = 5.23%)
	NewTotalSupply     string `json:"newTotalSupply"`     // USDC amount as string
	NewUtilization     string `json:"newUtilization"`     // Ratio as string (0-1)
	NewAPY             string `json:"newAPY"`             // APY as string (e.g., "0.0541" = 5.41%)
	APYChange          string `json:"apyChange"`          // APY difference as string
	UtilizationChange  string `json:"utilizationChange"`  // Utilization difference as string
}

// ChainConfig holds AAVE v3 contract addresses for each chain.
// This type is used by FindBestChain to match chain results with their configurations.
// Note: This type is also defined in cre-rebalance-workflow/internal/helper/config.go
// for use in that workflow. Both definitions should remain in sync.
type ChainConfig struct {
	ChainName                            string `json:"chainName"`
	ChainSelector                        uint64 `json:"chainSelector"`
	PoolAddressesProvider                string `json:"poolAddressesProvider"`                          // Pool Addresses Provider address (MOST IMMUTABLE - single hardcoded dependency)
	PoolDataProvider                     string `json:"poolDataProvider,omitempty"`                     // Protocol Data Provider address (DEPRECATED - now fetched dynamically from PoolAddressesProvider)
	DefaultReserveInterestRateStrategyV2 string `json:"defaultReserveInterestRateStrategyV2,omitempty"` // Strategy V2 address (unused, fetched dynamically)
	USDCAddress                          string `json:"usdcAddress"`                                    // USDC token address
}

// TargetChain represents the chain with the highest projected APY (NewAPY).
type TargetChain struct {
	// Fields for use by other workflows:
	ChainSelector     uint64 `json:"chainSelector"`     // Chainlink chain selector for routing
	StablecoinId      string `json:"stablecoinId"`      // Stablecoin identifier: "USDC" or "USDT"
	StablecoinAddress string `json:"stablecoinAddress"` // Stablecoin contract address on the target chain (needed?)

	// Fields for verification/debugging
	NewAPY    string `json:"newAPY"`    // Projected APY after deposit
	ChainName string `json:"chainName"` // Readable chain name
}

// CalculateInterestRatesParams holds parameters for calling CalculateInterestRates on the strategy contract.
// See: https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/libraries/types/DataTypes.sol
type CalculateInterestRatesParams struct {
	Unbacked                 *big.Int       // Unbacked amount (from ProtocolDataProvider.getReserveData().Arg0)
	LiquidityAdded           *big.Int       // Amount of liquidity being added (deposit amount)
	LiquidityTaken           *big.Int       // Amount of liquidity being taken (0 for deposits)
	TotalDebt                *big.Int       // Total debt (from ProtocolDataProvider.getReserveData())
	ReserveFactor            *big.Int       // Reserve factor in basis points (from reserve configuration)
	Reserve                  common.Address // Reserve asset address (USDC)
	UsingVirtualBalance      bool           // Must be true for non-mintable assets (like USDC)
	VirtualUnderlyingBalance *big.Int       // Available liquidity (fetched from ProtocolDataProvider.getVirtualUnderlyingBalance())
}

// ReserveData stores data fetched from AAVE contracts
// NOTE: Currently unused - kept for potential future use or fallback scenarios
// type ReserveData struct {
// 	TotalSupply          *big.Int
// 	TotalBorrow          *big.Int
// 	ReserveFactor        *big.Int
// 	OptimalUsage         *big.Int
// 	BaseRate             *big.Int
// 	Slope1               *big.Int
// 	Slope2               *big.Int
// 	CurrentLiquidityRate *big.Int // Annual liquidity rate (APR) in RAY from contract
// }

// InterestRateParams holds interest rate parameters from the strategy contract
// NOTE: Currently unused - kept for potential future use or fallback scenarios
// type InterestRateParams struct {
// 	OptimalUsage *big.Int
// 	BaseRate     *big.Int
// 	Slope1       *big.Int
// 	Slope2       *big.Int
// }
