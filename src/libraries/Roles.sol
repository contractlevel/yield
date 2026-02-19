// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title Roles
/// @author @contractlevel
/// @notice Library for roles in the Yieldcoin system
library Roles {
    /// @notice Role for pausing the system in case of emergency.
    bytes32 internal constant EMERGENCY_PAUSER_ROLE = keccak256("EMERGENCY_PAUSER_ROLE");
    /// @notice Role for unpausing the system in case of emergency.
    bytes32 internal constant EMERGENCY_UNPAUSER_ROLE = keccak256("EMERGENCY_UNPAUSER_ROLE");
    /// @notice Role for general configuration settings.
    bytes32 internal constant CONFIG_ADMIN_ROLE = keccak256("CONFIG_ADMIN_ROLE");
    /// @notice Role for cross-chain settings.
    bytes32 internal constant CROSS_CHAIN_ADMIN_ROLE = keccak256("CROSS_CHAIN_ADMIN_ROLE");
    /// @notice Role for withdrawing fees from the system in YieldFees.sol.
    bytes32 internal constant FEE_WITHDRAWER_ROLE = keccak256("FEE_WITHDRAWER_ROLE");
    /// @notice Role for setting the fee rate in YieldFees.sol.
    bytes32 internal constant FEE_RATE_SETTER_ROLE = keccak256("FEE_RATE_SETTER_ROLE");
}
