// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
    AccessControlDefaultAdminRulesUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol";
import {IAccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/IAccessControlEnumerable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IPausable} from "src/interfaces/IPausable.sol";
import {Roles} from "src/libraries/Roles.sol";

/// @notice Abstract base contract that enables pausing and access control functionality.
abstract contract PausableWithAccessControl is
    Initializable,
    PausableUpgradeable,
    AccessControlDefaultAdminRulesUpgradeable,
    IPausable,
    IAccessControlEnumerable
{
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @custom:storage-location erc7201:yieldcoin.storage.PausableWithAccessControl
    struct PausableAccessControlStorage {
        /// @notice The set of members in each role
        mapping(bytes32 role => EnumerableSet.AddressSet) s_roleMembers;
    }

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @notice The initial delay for transferring the admin role
    uint48 internal constant INITIAL_DEFAULT_ADMIN_ROLE_TRANSFER_DELAY = 259200 seconds; // 3 days // @review do we want another time delay later?

    // keccak256(abi.encode(uint256(keccak256("yieldcoin.storage.PausableWithAccessControl")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant PAUSABLE_ACCESS_CONTROL_STORAGE_LOCATION =
        0xf31030139dc5ab9c02ef44394b5ae7391974390930648b2264297c3b013d0e00; // @review check hash

    /*//////////////////////////////////////////////////////////////
                                  INIT
    //////////////////////////////////////////////////////////////*/
    /// @dev initialize pausable and access control modules
    function __PausableWithAccessControl_init(address owner) internal onlyInitializing {
        __Pausable_init();
        __AccessControlDefaultAdminRules_init(INITIAL_DEFAULT_ADMIN_ROLE_TRANSFER_DELAY, owner); // @review maybe just msg.sender?
    }

    /*/////////////////////////////////////////////////////////////
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
    /// @inheritdoc AccessControlDefaultAdminRulesUpgradeable
    function _grantRole(bytes32 role, address account) internal virtual override returns (bool granted) {
        granted = super._grantRole(role, account);
        if (granted) {
            // Access storage via the accessor function
            PausableAccessControlStorage storage $ = _getPausableAccessControlStorage();
            $.s_roleMembers[role].add(account);
        }
    }

    /// @inheritdoc AccessControlDefaultAdminRulesUpgradeable
    function _revokeRole(bytes32 role, address account) internal virtual override returns (bool revoked) {
        revoked = super._revokeRole(role, account);
        if (revoked) {
            PausableAccessControlStorage storage $ = _getPausableAccessControlStorage();
            $.s_roleMembers[role].remove(account);
        }
    }

    /*//////////////////////////////////////////////////////////////
                         PRIVATE PURE / STORAGE
    //////////////////////////////////////////////////////////////*/
    function _getPausableAccessControlStorage() private pure returns (PausableAccessControlStorage storage $) {
        assembly {
            $.slot := PAUSABLE_ACCESS_CONTROL_STORAGE_LOCATION
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc AccessControlDefaultAdminRulesUpgradeable
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IAccessControlEnumerable
    function getRoleMember(bytes32 role, uint256 index) external view override returns (address roleMember) {
        PausableAccessControlStorage storage $ = _getPausableAccessControlStorage();
        roleMember = $.s_roleMembers[role].at(index);
    }

    /// @inheritdoc IAccessControlEnumerable
    function getRoleMemberCount(bytes32 role) external view override returns (uint256 roleMemberCount) {
        PausableAccessControlStorage storage $ = _getPausableAccessControlStorage();
        roleMemberCount = $.s_roleMembers[role].length();
    }

    /// @notice This function returns the members of a role
    /// @param role The role to get the members of
    /// @return roleMembers members of the role
    function getRoleMembers(bytes32 role) public view virtual returns (address[] memory roleMembers) {
        PausableAccessControlStorage storage $ = _getPausableAccessControlStorage();
        roleMembers = $.s_roleMembers[role].values();
    }
}
