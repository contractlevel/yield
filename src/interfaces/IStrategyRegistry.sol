// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title IStrategyRegistry
/// @author @contractlevel
/// @notice Interface for the StrategyRegistry
/// @dev Maps protocolId (bytes32) to strategy adapter address and stablecoinId (bytes32) to stablecoin address
interface IStrategyRegistry {
    /// @notice Get the strategy adapter for a given protocol ID
    /// @param protocolId The protocol ID (e.g., keccak256("aave-v3"), keccak256("compound-v3"))
    /// @return strategyAdapter The strategy adapter address
    function getStrategyAdapter(bytes32 protocolId) external view returns (address strategyAdapter);

    /// @notice Get the stablecoin address for a given stablecoin ID
    /// @param stablecoinId The stablecoin ID (e.g., keccak256("USDC"), keccak256("USDT"))
    /// @return stablecoin The stablecoin address
    function getStablecoin(bytes32 stablecoinId) external view returns (address stablecoin);

    /// @notice Check if a stablecoin is supported
    /// @param stablecoinId The stablecoin ID
    /// @return isSupported Whether the stablecoin is supported on this chain
    function isStablecoinSupported(bytes32 stablecoinId) external view returns (bool isSupported);
}
