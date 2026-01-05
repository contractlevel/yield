package aavev3

import (
	"fmt"
	"math/big"

	"cre-rebalance/contracts/evm/src/generated/aave_protocol_data_provider"

	"github.com/ethereum/go-ethereum/common"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/blockchain/evm"
	"github.com/smartcontractkit/cre-sdk-go/cre"
)

// GetAPY calculates the APY for a given asset on a specific chain after adding liquidity.
//
// Parameters:
//   - runtime: CRE runtime for contract calls (required for all contract interactions)
//   - chainCfg: Chain configuration containing chainSelector and PoolAddressesProvider address
//   - assetAddress: The reserve asset address (e.g., USDC address)
//   - liquidityAdded: Amount of liquidity being added (use big.NewInt(0) for current APY)
//
// Returns:
//   - APY as *big.Rat (e.g., 0.0523 = 5.23%)
//   - Error if any contract call fails
//
// Example:
//
//	chainCfg := aavev3.ChainConfig{
//	    ChainName:             "ethereum-mainnet",
//	    ChainSelector:         5009297550715157269,
//	    PoolAddressesProvider: "0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e",
//	    USDCAddress:           "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
//	}
//	usdcAddress := common.HexToAddress(chainCfg.USDCAddress)
//	apy, err := aavev3.GetAPY(runtime, chainCfg, usdcAddress, big.NewInt(1000000)).Await()
func GetAPY(
	runtime cre.Runtime,
	chainCfg ChainConfig,
	assetAddress common.Address,
	liquidityAdded *big.Int,
) cre.Promise[*big.Rat] {
	logger := runtime.Logger()
	logger.Info("GetAPY: Starting APY calculation",
		"chain", chainCfg.ChainName,
		"asset", assetAddress.Hex(),
		"liquidityAdded", liquidityAdded.String())

	// Step 1: Create EVM client for this chain
	evmClient := &evm.Client{
		ChainSelector: chainCfg.ChainSelector,
	}

	// Step 2: Create PoolAddressesProvider binding (most immutable contract)
	poolAddressesProvider, err := NewPoolAddressesProviderBinding(evmClient, chainCfg.PoolAddressesProvider)
	if err != nil {
		return cre.PromiseFromResult[*big.Rat](nil, fmt.Errorf("failed to create PoolAddressesProvider binding for chain %s: %w", chainCfg.ChainName, err))
	}

	// Step 3: Fetch ProtocolDataProvider address dynamically from PoolAddressesProvider
	protocolDataProviderAddrPromise := poolAddressesProvider.GetPoolDataProvider(runtime, nil)

	return cre.ThenPromise(protocolDataProviderAddrPromise, func(protocolDataProviderAddr common.Address) cre.Promise[*big.Rat] {
		logger.Info("GetAPY: Got ProtocolDataProvider address",
			"chain", chainCfg.ChainName,
			"address", protocolDataProviderAddr.Hex())

		// Step 4: Create ProtocolDataProvider binding with dynamically fetched address
		protocolDataProvider, err := NewAaveProtocolDataProviderBinding(evmClient, protocolDataProviderAddr.Hex())
		if err != nil {
			return cre.PromiseFromResult[*big.Rat](nil, fmt.Errorf("failed to create ProtocolDataProvider binding for chain %s: %w", chainCfg.ChainName, err))
		}

		// Step 5: Fetch strategy address dynamically from ProtocolDataProvider
		strategyAddrPromise := protocolDataProvider.GetInterestRateStrategyAddress(
			runtime,
			aave_protocol_data_provider.GetInterestRateStrategyAddressInput{Arg0: assetAddress},
			nil,
		)

		return cre.ThenPromise(strategyAddrPromise, func(strategyAddr common.Address) cre.Promise[*big.Rat] {
			logger.Info("GetAPY: Got strategy address",
				"chain", chainCfg.ChainName,
				"strategy", strategyAddr.Hex())

			// Step 6: Create Strategy V2 binding with dynamically fetched address
			strategyV2, err := NewDefaultReserveInterestRateStrategyV2Binding(evmClient, strategyAddr.Hex())
			if err != nil {
				return cre.PromiseFromResult[*big.Rat](nil, fmt.Errorf("failed to create Strategy V2 binding for chain %s: %w", chainCfg.ChainName, err))
			}

			// Step 7: Fetch CalculateInterestRatesParams (includes unbacked, totalDebt, virtualUnderlyingBalance, reserveFactor)
			paramsPromise := FetchCalculateInterestRatesParams(
				runtime,
				protocolDataProvider,
				assetAddress,
				liquidityAdded,
			)

			// Step 8: Calculate APY using the strategy contract
			return cre.ThenPromise(paramsPromise, func(params *CalculateInterestRatesParams) cre.Promise[*big.Rat] {
				logger.Info("GetAPY: Got CalculateInterestRatesParams",
					"chain", chainCfg.ChainName,
					"totalDebt", params.TotalDebt.String(),
					"virtualUnderlyingBalance", params.VirtualUnderlyingBalance.String())

				apyPromise := CalculateAPYFromContract(runtime, strategyV2, params)

				return cre.Then(apyPromise, func(apy *big.Rat) (*big.Rat, error) {
					logger.Info("GetAPY: Calculated APY",
						"chain", chainCfg.ChainName,
						"apy", BigRatToString(apy))
					return apy, nil
				})
			})
		})
	})
}
