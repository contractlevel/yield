// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title IStrategy
/// @author @contractlevel
/// @notice Interface for strategies
interface IStrategy {
    function deposit(address usdc, uint256 amount) external;
    function withdraw(address usdc, uint256 amount) external;
    function getTotalValue(address usdc) external view returns (uint256 totalValue);
}
