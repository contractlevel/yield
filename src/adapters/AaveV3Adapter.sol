// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {StrategyAdapter} from "../modules/StrategyAdapter.sol";
import {IPoolAddressesProvider} from "@aave/v3-origin/src/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "@aave/v3-origin/src/contracts/interfaces/IPool.sol";
import {DataTypes} from "@aave/v3-origin/src/contracts/protocol/libraries/types/DataTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title AaveV3Adapter
/// @author @contractlevel
/// @notice Adapter for Aave V3
contract AaveV3Adapter is StrategyAdapter {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error AaveV3Adapter__IncorrectWithdrawAmount();

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @notice The address of the Aave V3 pool addresses provider
    address internal immutable i_aavePoolAddressesProvider;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param yieldPeer The address of the yield peer
    /// @param aavePoolAddressesProvider The address of the Aave V3 pool addresses provider
    //slither-disable-next-line missing-zero-check
    constructor(address yieldPeer, address aavePoolAddressesProvider) StrategyAdapter(yieldPeer) {
        i_aavePoolAddressesProvider = aavePoolAddressesProvider;
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Deposits USDC to the Aave V3 pool
    /// @param usdc The USDC token address
    /// @param amount The amount of USDC to deposit
    /// @dev Deposits the USDC to the Aave V3 pool
    function deposit(address usdc, uint256 amount) external onlyYieldPeer {
        emit Deposit(usdc, amount);

        address aavePool = _getAavePool();
        _approveToken(usdc, aavePool, amount);
        IPool(aavePool).supply(usdc, amount, address(this), 0);
    }

    /// @notice Withdraws USDC from the Aave V3 pool
    /// @param usdc The USDC token address
    /// @param amount The amount of USDC to withdraw
    /// @dev Transfers the USDC to the yield peer
    function withdraw(address usdc, uint256 amount) external onlyYieldPeer {
        emit Withdraw(usdc, amount);

        address aavePool = _getAavePool();
        uint256 withdrawnAmount = IPool(aavePool).withdraw(usdc, amount, address(this));
        if (withdrawnAmount != amount) revert AaveV3Adapter__IncorrectWithdrawAmount();
        _transferTokenTo(usdc, i_yieldPeer, amount);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the Aave V3 pool address
    /// @return aavePool The Aave V3 pool address
    function _getAavePool() internal view returns (address aavePool) {
        aavePool = IPoolAddressesProvider(i_aavePoolAddressesProvider).getPool();
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the total value of the USDC in the Aave V3 pool
    /// @param usdc The USDC token address
    /// @return totalValue The total value of the USDC in the Aave V3 pool
    function getTotalValue(address usdc) external view returns (uint256 totalValue) {
        address aavePool = _getAavePool();
        DataTypes.ReserveDataLegacy memory reserveData = IPool(aavePool).getReserveData(usdc);
        address aTokenAddress = reserveData.aTokenAddress;
        totalValue = IERC20(aTokenAddress).balanceOf(address(this));
    }

    /// @notice Gets the pool addresses provider
    /// @return poolAddressesProvider The pool addresses provider
    function getPoolAddressesProvider() external view returns (address poolAddressesProvider) {
        poolAddressesProvider = i_aavePoolAddressesProvider;
    }

    /// @notice Gets the Aave V3 pool address
    /// @return aavePool The Aave V3 pool address
    function getStrategyPool() external view returns (address aavePool) {
        return IPoolAddressesProvider(i_aavePoolAddressesProvider).getPool();
    }
}
