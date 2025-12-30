// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IPoolAddressesProvider} from "@aave/v3-origin/src/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "@aave/v3-origin/src/contracts/interfaces/IPool.sol";
import {DataTypes} from "@aave/v3-origin/src/contracts/protocol/libraries/types/DataTypes.sol";
import {IReserveInterestRateStrategy} from "@aave/v3-origin/src/contracts/interfaces/IReserveInterestRateStrategy.sol";
import {IPoolDataProvider} from "@aave/v3-origin/src/contracts/interfaces/IPoolDataProvider.sol";

/// @title StrategyHelper
/// @author @contractlevel
/// @notice Helper contract for CRE workflow to read information from strategies
contract StrategyHelper {
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @notice The scale for the ray (1e27)
    uint256 internal constant RAY = 1e27;

    /// @notice The address of the Aave V3 pool addresses provider
    address internal immutable i_poolAddressesProvider;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param poolAddressesProvider The address of the Aave V3 pool addresses provider
    constructor(address poolAddressesProvider) {
        i_poolAddressesProvider = poolAddressesProvider;
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    // @review unit test this!
    function getAaveV3APR(uint256 liquidityAdded, address asset) external view returns (uint256 apr) {
        address pool = IPoolAddressesProvider(i_poolAddressesProvider).getPool();
        address aaveProtocolDataProvider = IPoolAddressesProvider(i_poolAddressesProvider).getPoolDataProvider();

        /// @dev unbacked is deprecated, ie 0, but reading it anyway to be safe because aave docs are inconsistent
        uint256 unbacked = uint256(IPool(pool).getReserveData(asset).unbacked);

        uint256 totalDebt = IPoolDataProvider(aaveProtocolDataProvider).getTotalDebt(asset);
        (,,,, uint256 reserveFactor,,,,,) =
            IPoolDataProvider(aaveProtocolDataProvider).getReserveConfigurationData(asset);
        uint256 virtualUnderlyingBalance =
            IPoolDataProvider(aaveProtocolDataProvider).getVirtualUnderlyingBalance(asset);

        DataTypes.CalculateInterestRatesParams memory interestRatesParams = DataTypes.CalculateInterestRatesParams({
            unbacked: unbacked,
            liquidityAdded: liquidityAdded,
            liquidityTaken: 0,
            totalDebt: totalDebt,
            reserveFactor: reserveFactor,
            reserve: asset,
            usingVirtualBalance: true,
            virtualUnderlyingBalance: virtualUnderlyingBalance
        });

        (uint256 liquidityRate,) = IReserveInterestRateStrategy(IPool(pool).RESERVE_INTEREST_RATE_STRATEGY())
            .calculateInterestRates(interestRatesParams);

        apr = liquidityRate / RAY;
    }

    // @review getter for compound APR too

    // function getCalculateInterestRatesParams(uint256 liquidityAdded, address asset)
    //     external
    //     view
    //     returns (DataTypes.CalculateInterestRatesParams memory)
    // {}

    /// @return poolAddressesProvider The address of the Aave V3 pool addresses provider
    function getPoolAddressesProvider() external view returns (address) {
        return i_poolAddressesProvider;
    }

    /// @return RAY The scale for the ray (1e27)
    function getRAY() external pure returns (uint256) {
        return RAY;
    }
}
