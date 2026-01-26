// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title IStablecoinRegistry
/// @author @contractlevel
/// @notice Interface for the StablecoinRegistry
/// @dev Maps stablecoinId (bytes32) to stablecoin address per chain
interface IStablecoinRegistry {
    /// @notice Get the stablecoin address for a given stablecoin ID
    /// @param stablecoinId The stablecoin ID (e.g., keccak256("USDC"), keccak256("USDT"))
    /// @return stablecoin The stablecoin address
    function getStablecoin(bytes32 stablecoinId) external view returns (address stablecoin);

    /// @notice Check if a stablecoin is supported
    /// @param stablecoinId The stablecoin ID
    /// @return isSupported Whether the stablecoin is supported on this chain
    function isStablecoinSupported(bytes32 stablecoinId) external view returns (bool isSupported);
}
