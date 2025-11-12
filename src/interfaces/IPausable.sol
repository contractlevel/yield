// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @notice Interface for pausable & unpausable contracts
interface IPausable {
    /// @notice This function pauses the contract
    /// @dev Sets the pause flag to true
    /// @dev Revert if caller does not have the EMERGENCY_PAUSER_ROLE
    function emergencyPause() external;

    /// @notice This function unpauses the contract
    /// @dev Sets the pause flag to false
    /// @dev Revert if caller does not have the EMERGENCY_UNPAUSER_ROLE
    function emergencyUnpause() external;
}
