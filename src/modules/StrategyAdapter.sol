// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IStrategyAdapter} from "../interfaces/IStrategyAdapter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title StrategyAdapter
/// @author @contractlevel
/// @notice Base contract for strategy adapters
abstract contract StrategyAdapter is IStrategyAdapter {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error StrategyAdapter__OnlyYieldPeer();

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    address internal immutable i_yieldPeer;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event Deposit(address indexed usdc, uint256 indexed amount);
    event Withdraw(address indexed usdc, uint256 indexed amount);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyYieldPeer() {
        if (msg.sender != i_yieldPeer) revert StrategyAdapter__OnlyYieldPeer();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address yieldPeer) {
        i_yieldPeer = yieldPeer;
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Transfers a token to an address
    /// @param token The token to transfer
    /// @param to The address to transfer the token to
    /// @param amount The amount of token to transfer
    function _transferTokenTo(address token, address to, uint256 amount) internal {
        IERC20(token).safeTransfer(to, amount);
    }

    /// @notice Approves a token to be spent by an address
    /// @param token The token to approve
    /// @param spender The address to approve the token to
    /// @param amount The amount of token to approve
    function _approveToken(address token, address spender, uint256 amount) internal {
        IERC20(token).safeIncreaseAllowance(spender, amount);
    }
}
