package aaveV3

import (
	"math/big"
	"rebalance/contracts/evm/src/generated/aave_protocol_data_provider"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// getCalculateInterestRatesParams fetches all data needed to build CalculateInterestRatesParams
// for calling the strategy contract's CalculateInterestRates function.
//
// This function:
// 1. Gets reserve data from ProtocolDataProvider (includes unbacked, totalDebt)
// 2. Gets virtualUnderlyingBalance from ProtocolDataProvider contract
// 3. Gets reserve configuration (for reserveFactor)
// 4. Builds and returns CalculateInterestRatesParams
//
// (Arg0 from ProtocolDataProvider.getReserveData()). The contract calculates available
// liquidity internally as: unbacked + liquidityAdded - liquidityTaken.
//
// The liquidityAdded parameter is the deposit amount (0 for current APY, deposit amount for projected APY).
func getCalculateInterestRatesParams(
	runtime cre.Runtime,
	protocolDataProvider AaveProtocolDataProviderInterface,
	reserveAddress common.Address,
	liquidityAdded *big.Int,
) cre.Promise[*CalculateInterestRatesParams] {
	// logger := runtime.Logger()
	// logger.Info("Fetching CalculateInterestRatesParams", "reserve", reserveAddress.Hex(), "liquidityAdded", liquidityAdded.String())

	// Get reserve data from ProtocolDataProvider
	// Arg0 is unbacked
	reserveDataPromise := protocolDataProvider.GetReserveData(
		runtime,
		aave_protocol_data_provider.GetReserveDataInput{Asset: reserveAddress},
		nil,
	)

	return cre.ThenPromise(reserveDataPromise, func(reserveData aave_protocol_data_provider.GetReserveDataOutput) cre.Promise[*CalculateInterestRatesParams] {
		// Extract unbacked (Arg0) and totalDebt
		unbacked := reserveData.Arg0        // Portal unbacked amount
		totalStableDebt := reserveData.Arg3 // Unnamed field in ABI (totalStableDebt)
		totalVariableDebt := reserveData.TotalVariableDebt

		totalDebt := new(big.Int).Add(totalStableDebt, totalVariableDebt)

		// logger.Info("Got reserve data from ProtocolDataProvider",
		// 	"unbacked", unbacked.String(),
		// 	"totalDebt", totalDebt.String())

		// Get virtualUnderlyingBalance from ProtocolDataProvider contract
		virtualBalancePromise := protocolDataProvider.GetVirtualUnderlyingBalance(
			runtime,
			aave_protocol_data_provider.GetVirtualUnderlyingBalanceInput{Asset: reserveAddress},
			nil,
		)

		return cre.ThenPromise(virtualBalancePromise, func(virtualUnderlyingBalance *big.Int) cre.Promise[*CalculateInterestRatesParams] {
			// logger.Info("Got virtualUnderlyingBalance from contract",
			// 	"virtualUnderlyingBalance", virtualUnderlyingBalance.String())

			// Get reserve configuration (for reserveFactor)
			configPromise := protocolDataProvider.GetReserveConfigurationData(
				runtime,
				aave_protocol_data_provider.GetReserveConfigurationDataInput{Asset: reserveAddress},
				nil,
			)

			return cre.Then(configPromise, func(configResult aave_protocol_data_provider.GetReserveConfigurationDataOutput) (*CalculateInterestRatesParams, error) {
				reserveFactor := configResult.ReserveFactor

				// logger.Info("Got reserve configuration", "reserveFactor", reserveFactor.String())

				// Build CalculateInterestRatesParams
				// IMPORTANT: usingVirtualBalance must be true for non-mintable assets (like USDC)
				// If false, the contract returns (0, baseVariableBorrowRate) immediately
				// virtualUnderlyingBalance is fetched from the contract (not calculated)
				// liquidityTaken = 0 (we're not simulating withdrawals/borrows)
				return &CalculateInterestRatesParams{
					Unbacked:                 unbacked,
					LiquidityAdded:           liquidityAdded,
					LiquidityTaken:           big.NewInt(0),
					TotalDebt:                totalDebt,
					ReserveFactor:            reserveFactor,
					Reserve:                  reserveAddress,
					UsingVirtualBalance:      true,                     // Must be true for non-mintable assets
					VirtualUnderlyingBalance: virtualUnderlyingBalance, // Fetched from contract
				}, nil
			})
		})
	})
}
