// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @notice Library for YieldCoin system roles
library Roles {
    /// @dev example
    /// bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // @review George: Brain storming roles

    /// @dev setInitialActiveStrategy - probably HAS to be the OWNER who deploys the contracts

    /// @notice Role for adding/remove strategys
    /// - setStrategyAdapter
    bytes32 public constant STRATEGY_MANAGER_ROLE = keccak256("STRATEGY_MANAGER_ROLE");

    /// @notice Role for setting and withdrawing fees
    /// - withdrawFees
    /// - setFeeRate
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");

    /// @notice Role for setting integrating contract addresses - a "system manager" of sorts
    /// - setUpkeepAddress
    /// - setForwarder
    /// - setParentPeer
    /// - setStrategyRegistry
    /// - setRebalancer
    /// - setStrategyRegistry
    bytes32 public constant INTEGRATION_MANAGER_ROLE = keccak256("INTEGRATION_MANAGER_ROLE");

    /// @notice Role for setting CCIP specific settings
    /// - setAllowedChain
    /// - setAllowedPeer
    /// - setCCIPAdmin
    /// - setCCIPGasLimit
    bytes32 public constant CCIP_MANAGER_ROLE = keccak256("CCIP_MANAGER_ROLE");
}
