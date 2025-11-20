// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @notice Library for YieldCoin custom roles
library Roles {
    /// @dev example for creating a role
    // bytes32 public constant ROLE = keccak256("ROLE");

    /// @notice Current existing function calls have been included as example of possible controls for each role.
    /// @notice General admin role, owner of contracts and can grant/revoke roles.
    /// @notice This role comes with OZ's AccessControl, put here as note of role.
    /// - setCCIPAdmin - (in token/Share.sol)
    // bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");

    /// @notice Role for general setting of (non-cross chain) settings across contracts.
    /// - setUpkeepAddress - (in modules/Rebalancer.sol)
    /// - setForwarder --------------------^
    /// - setParentPeer -------------------^
    /// - setStrategyRegistry -------------^
    /// - setStrategyRegistry - (in peers/YieldPeer.sol)
    /// - setRebalancer - (in peers/ParentPeer.sol)
    /// - setStrategyAdapter - (in modules/StrategyRegistry.sol)
    bytes32 public constant CONFIG_ADMIN_ROLE = keccak256("CONFIG_ADMIN_ROLE");

    /// @notice Role for setting of cross chain settings, Chainlink CCIP and other (possible future) cross chain settings.
    /// - setAllowedChain - (in peers/YieldPeer.sol)
    /// - setAllowedPeer - (in peers/YieldPeer.sol)
    /// - setCCIPGasLimit - (in peers/YieldPeer.sol)
    bytes32 public constant CROSS_CHAIN_ADMIN_ROLE = keccak256("CROSS_CHAIN_ADMIN_ROLE");

    /// @notice Role for pausing and unpausing the system in case of emergency.
    bytes32 public constant EMERGENCY_PAUSER_ROLE = keccak256("EMERGENCY_PAUSER_ROLE");
    bytes32 public constant EMERGENCY_UNPAUSER_ROLE = keccak256("EMERGENCY_UNPAUSER_ROLE");

    /// @notice Role for withdrawing fees from the system.
    /// - withdrawFees - (in modules/YieldFees.sol)
    bytes32 public constant FEE_WITHDRAWER_ROLE = keccak256("FEE_WITHDRAWER_ROLE");

    /// @notice Role for setting the protocol fee rate.
    /// - setFeeRate - (in modules/YieldFees.sol)
    bytes32 public constant FEE_RATE_SETTER_ROLE = keccak256("FEE_RATE_SETTER_ROLE");
}
