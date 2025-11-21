// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {
    AccessControlDefaultAdminRules
} from "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {IAccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/IAccessControlEnumerable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IPausable} from "src/interfaces/IPausable.sol";
import {Roles} from "src/libraries/Roles.sol";

/// @notice Abstract base contract that enables pausing and access control functionality.
abstract contract PausableWithAccessControl is
    Pausable,
    AccessControlDefaultAdminRules,
    IPausable,
    IAccessControlEnumerable
{
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using EnumerableSet for EnumerableSet.AddressSet;

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @notice The initial delay for transferring the admin role
    uint48 internal constant INITIAL_DEFAULT_ADMIN_ROLE_TRANSFER_DELAY = 259200 seconds; // 3 days

    /// @notice The set of members in each role
    mapping(bytes32 role => EnumerableSet.AddressSet) private s_roleMembers;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address admin) AccessControlDefaultAdminRules(INITIAL_DEFAULT_ADMIN_ROLE_TRANSFER_DELAY, admin) {}

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice This function pauses the contract
    /// @dev Sets the pause flag to true
    /// @dev Revert if caller does not have the EMERGENCY_PAUSER_ROLE
    function emergencyPause() external onlyRole(Roles.EMERGENCY_PAUSER_ROLE) {
        _pause();
    }

    /// @notice This function unpauses the contract
    /// @dev Sets the pause flag to false
    /// @dev Revert if caller does not have the EMERGENCY_UNPAUSER_ROLE
    function emergencyUnpause() external onlyRole(Roles.EMERGENCY_UNPAUSER_ROLE) {
        _unpause();
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc AccessControlDefaultAdminRules
    function _grantRole(bytes32 role, address account) internal virtual override returns (bool granted) {
        granted = super._grantRole(role, account);
        if (granted) s_roleMembers[role].add(account);
    }

    /// @inheritdoc AccessControlDefaultAdminRules
    function _revokeRole(bytes32 role, address account) internal virtual override returns (bool revoked) {
        revoked = super._revokeRole(role, account);
        if (revoked) s_roleMembers[role].remove(account);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc AccessControlDefaultAdminRules
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IAccessControlEnumerable
    function getRoleMember(bytes32 role, uint256 index) external view override returns (address roleMember) {
        roleMember = s_roleMembers[role].at(index);
    }

    /// @inheritdoc IAccessControlEnumerable
    function getRoleMemberCount(bytes32 role) external view override returns (uint256 roleMemberCount) {
        roleMemberCount = s_roleMembers[role].length();
    }

    /// @notice This function returns the members of a role
    /// @param role The role to get the members of
    /// @return roleMembers members of the role
    function getRoleMembers(bytes32 role) public view virtual returns (address[] memory roleMembers) {
        roleMembers = s_roleMembers[role].values();
    }
}
