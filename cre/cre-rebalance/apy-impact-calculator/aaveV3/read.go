package aaveV3

import (
	"cre-rebalance/contracts/evm/src/generated/aave_protocol_data_provider"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// FetchCalculateInterestRatesParams fetches all data needed to build CalculateInterestRatesParams
// for calling the strategy contract's CalculateInterestRates function.
//
// This function:
// 1. Gets reserve data from ProtocolDataProvider (includes unbacked, totalDebt)
// 2. Gets virtualUnderlyingBalance from ProtocolDataProvider contract
// 3. Gets reserve configuration (for reserveFactor)
// 4. Builds and returns CalculateInterestRatesParams
//
// IMPORTANT: All contract calls use the same blockNumber to ensure consistency.
// If blockNumber is nil, all calls will query "latest", but they may hit different blocks
// due to sequential execution. For consistent results, pass a specific block number.
//
// (Arg0 from ProtocolDataProvider.getReserveData()). The contract calculates available
// liquidity internally as: unbacked + liquidityAdded - liquidityTaken.
//
// The liquidityAdded parameter is the deposit amount (0 for current APY, deposit amount for projected APY).
func FetchCalculateInterestRatesParams(
	runtime cre.Runtime,
	protocolDataProvider AaveProtocolDataProviderInterface,
	reserveAddress common.Address,
	liquidityAdded *big.Int,
	blockNumber *big.Int, // Use same blockNumber for all calls to ensure consistency
) cre.Promise[*CalculateInterestRatesParams] {
	logger := runtime.Logger()
	logger.Info("Fetching CalculateInterestRatesParams", "reserve", reserveAddress.Hex(), "liquidityAdded", liquidityAdded.String(), "blockNumber", blockNumber)

	// Get reserve data from ProtocolDataProvider
	// Arg0 is unbacked
	reserveDataPromise := protocolDataProvider.GetReserveData(
		runtime,
		aave_protocol_data_provider.GetReserveDataInput{Asset: reserveAddress},
		blockNumber, // Use same blockNumber for all calls
	)

	return cre.ThenPromise(reserveDataPromise, func(reserveData aave_protocol_data_provider.GetReserveDataOutput) cre.Promise[*CalculateInterestRatesParams] {
		// Extract unbacked (Arg0)
		unbacked := reserveData.Arg0 // Portal unbacked amount

		logger.Info("Got reserve data from ProtocolDataProvider",
			"unbacked", unbacked.String())

		// Get totalDebt directly from contract (more accurate than calculating manually)
		// CRITICAL: Use the SAME blockNumber to ensure all values are from the same block
		totalDebtPromise := protocolDataProvider.GetTotalDebt(
			runtime,
			aave_protocol_data_provider.GetTotalDebtInput{Asset: reserveAddress},
			blockNumber, // Use same blockNumber
		)

		return cre.ThenPromise(totalDebtPromise, func(totalDebt *big.Int) cre.Promise[*CalculateInterestRatesParams] {
			logger.Info("Got totalDebt from contract", "totalDebt", totalDebt.String())

			// Get virtualUnderlyingBalance from ProtocolDataProvider contract
			// CRITICAL: Use the SAME blockNumber to ensure all values are from the same block
			virtualBalancePromise := protocolDataProvider.GetVirtualUnderlyingBalance(
				runtime,
				aave_protocol_data_provider.GetVirtualUnderlyingBalanceInput{Asset: reserveAddress},
				blockNumber, // Use same blockNumber
			)

			return cre.ThenPromise(virtualBalancePromise, func(virtualUnderlyingBalance *big.Int) cre.Promise[*CalculateInterestRatesParams] {
				logger.Info("Got virtualUnderlyingBalance from contract",
					"virtualUnderlyingBalance", virtualUnderlyingBalance.String())

				// Get reserve configuration (for reserveFactor)
				// CRITICAL: Use the SAME blockNumber to ensure all values are from the same block
				configPromise := protocolDataProvider.GetReserveConfigurationData(
					runtime,
					aave_protocol_data_provider.GetReserveConfigurationDataInput{Asset: reserveAddress},
					blockNumber, // Use same blockNumber
				)

				return cre.Then(configPromise, func(configResult aave_protocol_data_provider.GetReserveConfigurationDataOutput) (*CalculateInterestRatesParams, error) {
					reserveFactor := configResult.ReserveFactor

					logger.Info("Got reserve configuration", "reserveFactor", reserveFactor.String())

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
	})
}
