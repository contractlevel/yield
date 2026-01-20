package aaveV3

import(
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