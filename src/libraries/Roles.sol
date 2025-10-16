// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @notice Library for YieldCoin custom roles
library Roles {
    /// @dev example
    /// bytes32 public constant ROLE = keccak256("ROLE");

    /// @notice Function calls have been included as example of possible controls for each role.

    /// @notice General admin role to grant/revoke roles. Contracts owner?
    /// - setCCIPAdmin - (in token/Share.sol)
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");

    /// @notice Setter of non-cross chain settings across contracts.
    /// - setUpkeepAddress - (in modules/Rebalancer.sol)
    /// - setForwarder --------------------^
    /// - setParentPeer -------------------^
    /// - setStrategyRegistry -------------^
    /// - setStrategyRegistry - (in peers/YieldPeer.sol)
    /// - setRebalancer - (in peers/ParentPeer.sol)
    /// - setStrategyAdapter - (in modules/StrategyRegistry.sol)
    bytes32 public constant INTEGRATION_MANAGER_ROLE = keccak256("INTEGRATION_MANAGER_ROLE");

    /// @notice Role for Chainlink CCIP and other (possible future) cross chain settings.
    /// - setAllowedChain - (in peers/YieldPeer.sol)
    /// - setAllowedPeer - (in peers/YieldPeer.sol)
    /// - setCCIPGasLimit - (in peers/YieldPeer.sol)
    bytes32 public constant CROSS_CHAIN_MANAGER_ROLE = keccak256("CROSS_CHAIN_MANAGER_ROLE");

    /// @notice Role for pausing and unpausing the system in case of emergency.
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE ");

    /// @notice Role for withdrawing fees from each Peer.
    /// - withdrawFees - (in modules/YieldFees.sol)
    bytes32 public constant FEE_WITHDRAWER_ROLE = keccak256("FEE_WITHDRAWER_ROLE");

    /// @notice Role for setting and controller the system fee rate.
    /// - setFeeRate - (in modules/YieldFees.sol)
    bytes32 public constant FEE_RATE_CONTROLLER_ROLE = keccak256("FEE_RATE_CONTROLLER_ROLE");
}
