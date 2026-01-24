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
    /// @dev keccak256("CONFIG_ADMIN_ROLE")
    bytes32 public constant CONFIG_ADMIN_ROLE = 0xb92d52e77ebaa0cae5c23e882d85609efbcb44029214147dd132daf9ef1018af; // @review double check this hash

    /// @notice Role for setting of cross chain settings, Chainlink CCIP and other (possible future) cross chain settings.
    /// - setAllowedChain - (in peers/YieldPeer.sol)
    /// - setAllowedPeer - (in peers/YieldPeer.sol)
    /// - setCCIPGasLimit - (in peers/YieldPeer.sol)
    /// @dev keccak256("CROSS_CHAIN_ADMIN_ROLE")
    bytes32 public constant CROSS_CHAIN_ADMIN_ROLE = 0xb28dc5efd345f3bec5c16749590c736fbb2ba9912d8680cac4da7a59f918a760; // @review double check this hash

    /// @notice Role for pausing and unpausing the system in case of emergency.
    /// @dev keccak256("EMERGENCY_PAUSER_ROLE")
    bytes32 public constant EMERGENCY_PAUSER_ROLE = 0x3b72b77b3d95d9b831cca52b36d7a9c3758f77be6c47ebd087c47739c743d369; // @review double check this hash
    /// @dev keccak256("EMERGENCY_UNPAUSER_ROLE")
    bytes32 public constant EMERGENCY_UNPAUSER_ROLE =
        0x7bd03e5eb4ee9007f85634e07fc4bb1fbe96d33e9f2d1644bc6bda2b6b8a3169; // @review double check this hash

    /// @notice Role for withdrawing fees from the system.
    /// - withdrawFees - (in modules/YieldFees.sol)
    /// @dev keccak256("FEE_WITHDRAWER_ROLE")
    bytes32 public constant FEE_WITHDRAWER_ROLE = 0xcecef922ac6ded813804bed2d5fdf033decf4a090fa3c9b9f529302a0aff6455; // @review double check this hash

    /// @notice Role for setting the protocol fee rate.
    /// - setFeeRate - (in modules/YieldFees.sol)
    /// @dev keccak256("FEE_RATE_SETTER_ROLE")
    bytes32 public constant FEE_RATE_SETTER_ROLE = 0x658e71518b7b5afc52c60427d525dee00a59b3720f918587414f669096f77bee; // @review double check this hash

    /// @dev keccak256("UPGRADER_ROLE")
    bytes32 public constant UPGRADER_ROLE = 0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3; // @review double check this hash
}
