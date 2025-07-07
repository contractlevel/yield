// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {StrategyAdapter} from "../modules/StrategyAdapter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IComet} from "../interfaces/IComet.sol";

/// @title CompoundV3
/// @author @contractlevel
/// @notice Adapter for Compound V3
contract CompoundV3 is StrategyAdapter {
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
        IERC20(usdc).approve(i_comet, amount);
        IComet(i_comet).supply(usdc, amount);
    }

    /// @notice Withdraws USDC from the Compound V3 pool
    /// @param usdc The USDC token address
    /// @param amount The amount of USDC to withdraw
    /// @dev Transfers the USDC to the yield peer
    function withdraw(address usdc, uint256 amount) external onlyYieldPeer {
        IComet(i_comet).withdraw(usdc, amount);
        IERC20(usdc).transfer(i_yieldPeer, amount);
    }

    /// @notice Gets the total value of the asset in the Compound V3 pool
    /// @return totalValue The total value of the asset in the Compound V3 pool
    function getTotalValue(address /* asset */ ) external view returns (uint256 totalValue) {
        totalValue = IComet(i_comet).balanceOf(address(this));
    }
}
