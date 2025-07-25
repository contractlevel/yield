// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title IStrategyAdapter
/// @author @contractlevel
/// @notice Interface for strategy adapters
interface IStrategyAdapter {
    function deposit(address usdc, uint256 amount) external;
    function withdraw(address usdc, uint256 amount) external;
    function getTotalValue(address usdc) external view returns (uint256 totalValue);
    function getStrategyPool() external returns (address);
}
