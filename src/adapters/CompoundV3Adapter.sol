// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {StrategyAdapter} from "../modules/StrategyAdapter.sol";
import {IComet} from "../interfaces/IComet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title CompoundV3Adapter
/// @author @contractlevel
/// @notice Adapter for Compound V3
contract CompoundV3Adapter is StrategyAdapter {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error CompoundV3Adapter__InsufficientSupply();
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @notice The address of the Compound V3 pool
    address internal immutable i_comet;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param yieldPeer The address of the yield peer
    /// @param comet The address of the Compound V3 pool
    //slither-disable-next-line missing-zero-check
    constructor(address yieldPeer, address comet) StrategyAdapter(yieldPeer) {
        i_comet = comet;
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Deposits USDC to the Compound V3 pool
    /// @param usdc The USDC token address
    /// @param amount The amount of USDC to deposit
    /// @dev Deposits the USDC to the Compound V3 pool
    function deposit(address usdc, uint256 amount) external onlyYieldPeer {
        emit Deposit(usdc, amount);

        _approveToken(usdc, i_comet, amount);
        IComet(i_comet).supply(usdc, amount);
    }

    /// @notice Withdraws USDC from the Compound V3 pool
    /// @param usdc The USDC token address
    /// @param amount The amount of USDC to withdraw (use type(uint256).max to withdraw all)
    /// @dev Transfers the actual withdrawn amount to the yield peer
    /// @dev Prevents borrowing by ensuring amount <= balance when not using MAX sentinel
    function withdraw(address usdc, uint256 amount) external onlyYieldPeer {
        // Get balance before withdraw to calculate actual withdrawn amount
        uint256 balanceBefore = IERC20(usdc).balanceOf(address(this));

        // Case 1: Rebalance Withdraw (MAX sentinel)
        if (amount == type(uint256).max) {
            uint256 totalValue = _getTotalValue();

            // Comet will set amount to balanceOf(address(this)) internally
            IComet(i_comet).withdraw(usdc, amount);

            // Get actual amount received (Comet transfers to adapter)
            uint256 balanceAfter = IERC20(usdc).balanceOf(address(this));
            uint256 actualWithdrawn = balanceAfter - balanceBefore;

            // Verify we got at least the expected total value
            if (actualWithdrawn < totalValue) revert CompoundV3Adapter__InsufficientSupply();
            emit Withdraw(usdc, actualWithdrawn);
            _transferTokenTo(usdc, i_yieldPeer, actualWithdrawn);
        }
        // Case 2: User Withdraw
        else {
            // Ensure we don't withdraw more than supply to prevent borrowing
            uint256 supplyBalance = _getTotalValue();
            if (amount > supplyBalance) {
                revert CompoundV3Adapter__InsufficientSupply();
            }

            // Comet transfers directly to this adapter (msg.sender)
            IComet(i_comet).withdraw(usdc, amount);

            // Get actual amount received (Comet transfers to adapter)
            uint256 balanceAfter = IERC20(usdc).balanceOf(address(this));
            uint256 actualWithdrawn = balanceAfter - balanceBefore;
            if (actualWithdrawn < amount) revert CompoundV3Adapter__InsufficientSupply();
            emit Withdraw(usdc, actualWithdrawn);
            // Transfer actual withdrawn amount to yield peer
            _transferTokenTo(usdc, i_yieldPeer, actualWithdrawn);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Internal function to get total value
    /// @return totalValue The total value of the asset in the Compound V3 pool
    function _getTotalValue() internal view returns (uint256 totalValue) {
        totalValue = IComet(i_comet).balanceOf(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Gets the total value of the asset in the Compound V3 pool
    /// @return totalValue The total value of the asset in the Compound V3 pool
    function getTotalValue(
        address /* asset */
    )
        external
        view
        returns (uint256 totalValue)
    {
        totalValue = _getTotalValue();
    }

    /// @notice Gets the Compound V3 pool address
    /// @return comet The Compound V3 pool address
    function getStrategyPool() external view returns (address comet) {
        return i_comet;
    }
}
