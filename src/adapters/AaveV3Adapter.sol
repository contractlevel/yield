// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {StrategyAdapter} from "../modules/StrategyAdapter.sol";
import {IPoolAddressesProvider} from "@aave/v3-origin/src/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "@aave/v3-origin/src/contracts/interfaces/IPool.sol";
import {DataTypes} from "@aave/v3-origin/src/contracts/protocol/libraries/types/DataTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title AaveV3Adapter
/// @author @contractlevel
/// @notice Adapter for Aave V3
contract AaveV3Adapter is StrategyAdapter {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

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
        IERC20(usdc).safeIncreaseAllowance(aavePool, amount);
        IPool(aavePool).supply(usdc, amount, address(this), 0);
    }

    /// @notice Withdraws USDC from the Aave V3 pool
    /// @param usdc The USDC token address
    /// @param amount The amount of USDC to withdraw (use type(uint256).max to withdraw all)
    /// @return actualWithdrawnAmount The actual withdrawn amount
    /// @dev Transfers the actual withdrawn amount to the yield peer
    function withdraw(address usdc, uint256 amount) external onlyYieldPeer returns (uint256 actualWithdrawnAmount) {
        address aavePool = _getAavePool();

        // Case 1: Rebalance Withdraw (MAX sentinel)
        if (amount == type(uint256).max) {
            // Get expected balance before withdraw
            uint256 totalValue = _getTotalValue(usdc, aavePool);

            // Aave handles MAX sentinel internally and withdraws all available balance
            actualWithdrawnAmount = IPool(aavePool).withdraw(usdc, amount, address(this));

            // Verify we got at least the expected total value (allows for interest accrual)
            // Aave should return exactly totalValue, but we allow >= to handle edge cases
            if (actualWithdrawnAmount < totalValue) revert AaveV3Adapter__IncorrectWithdrawAmount();
        }
        // Case 2: User Withdraw
        else {
            actualWithdrawnAmount = IPool(aavePool).withdraw(usdc, amount, address(this));
            // Only revert if we got less than requested (allows for interest accrual)
            if (actualWithdrawnAmount < amount) revert AaveV3Adapter__IncorrectWithdrawAmount();
        }
        emit Withdraw(usdc, actualWithdrawnAmount);
        IERC20(usdc).safeTransfer(i_yieldPeer, actualWithdrawnAmount);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the Aave V3 pool address
    /// @return aavePool The Aave V3 pool address
    function _getAavePool() internal view returns (address aavePool) {
        aavePool = IPoolAddressesProvider(i_aavePoolAddressesProvider).getPool();
    }

    /// @notice Internal function to get total value
    /// @param usdc The USDC token address
    /// @param aavePool The Aave pool address
    /// @return totalValue The total value of USDC in the Aave V3 pool
    function _getTotalValue(address usdc, address aavePool) internal view returns (uint256 totalValue) {
        DataTypes.ReserveDataLegacy memory reserveData = IPool(aavePool).getReserveData(usdc);
        address aTokenAddress = reserveData.aTokenAddress;
        totalValue = IERC20(aTokenAddress).balanceOf(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the total value of the USDC in the Aave V3 pool
    /// @param usdc The USDC token address
    /// @return totalValue The total value of the USDC in the Aave V3 pool
    function getTotalValue(address usdc) external view returns (uint256 totalValue) {
        totalValue = _getTotalValue(usdc, _getAavePool());
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
