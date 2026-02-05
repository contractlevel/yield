// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC677} from "@chainlink/contracts/src/v0.8/shared/token/ERC677/IERC677.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IBurnMintERC677
 * @author Judge Finance
 * @notice Interface for a basic burn/mint ERC677 token
 * @dev Burn/mint functions are declared here rather than imported
 * from 'IBurnMintERC20.sol' to avoid inheritance conflicts
 */
interface IBurnMintERC677Upgradeable is IERC677, IERC20 {
    /// @notice Mints new tokens for a given address.
    /// @param account The address to mint the new tokens to.
    /// @param amount The number of tokens to be minted.
    /// @dev this function increases the total supply.
    function mint(address account, uint256 amount) external;

    /// @notice Burns tokens from the sender.
    /// @param amount The number of tokens to be burned.
    /// @dev this function decreases the total supply.
    function burn(uint256 amount) external;

    /// @notice Burns tokens from a given address..
    /// @param account The address to burn tokens from.
    /// @param amount The number of tokens to be burned.
    /// @dev this function decreases the total supply.
    function burn(address account, uint256 amount) external;

    /// @notice Burns tokens from a given address..
    /// @param account The address to burn tokens from.
    /// @param amount The number of tokens to be burned.
    /// @dev this function decreases the total supply.
    function burnFrom(address account, uint256 amount) external;
}
