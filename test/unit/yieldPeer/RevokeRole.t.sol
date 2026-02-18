// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, Roles} from "../../BaseTest.t.sol";

contract RevokeRoleTest is BaseTest {
    uint256 internal constant ROLE_MEMBER_EMPTY = 0; /// @dev count for getRoleMember - 0 since role index is empty after revocation
    uint256 internal constant ROLE_MEMBER_INDEX = 0; /// @dev index used for getRoleMember - 0 since only one member is being removed
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    function test_yield_yieldPeer_revokeRole_emitsRoleRevokedEvent() public {
        vm.recordLogs();
        _changePrank(baseParentPeer.owner());
        baseParentPeer.revokeRole(Roles.CONFIG_ADMIN_ROLE, configAdmin); /// @dev revoke role from configAdmin in BaseTest

        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool revokeRoleLogFound;
        bytes32 emittedRole;
        address emittedConfigAdmin;
        address emittedRevoker;

        for (uint256 i = 0; i < logs.length; i++) {
            /// @dev event: RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
            if (logs[i].topics[0] == keccak256(("RoleRevoked(bytes32,address,address)"))) {
                emittedRole = logs[i].topics[1];
                emittedConfigAdmin = address(uint160(uint256(logs[i].topics[2])));
                emittedRevoker = address(uint160(uint256(logs[i].topics[3])));
                revokeRoleLogFound = true;
                break;
            }
        }

        assertEq(revokeRoleLogFound, true);
        assertEq(emittedRole, Roles.CONFIG_ADMIN_ROLE);
        assertEq(emittedConfigAdmin, configAdmin);
        assertEq(emittedRevoker, baseParentPeer.owner());
    }

    function test_yield_yieldPeer_revokeRole_updatesRoleStorage() public {
        /// @dev Roles are stored in:
        /*
        struct RoleData {
            mapping(address account => bool) hasRole;
            bytes32 adminRole;
        }
        mapping(bytes32 role => RoleData) private _roles;
        */
        /// @dev _roles mapping shows if address has role for access control

        address[] memory emptyMembers = new address[](0); /// @dev empty array since we are revoking the only member

        _changePrank(baseParentPeer.owner());
        baseParentPeer.revokeRole(Roles.CONFIG_ADMIN_ROLE, configAdmin);

        assertEq(baseParentPeer.hasRole(Roles.CONFIG_ADMIN_ROLE, configAdmin), false); /// ---------- @dev Check hasRole in _roles mapping updated
    }

    function test_yield_yieldPeer_revokeRole_revertsWhen_notDefaultAdmin() public {
        _changePrank(emergencyPauser);
        /// @dev error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", emergencyPauser, DEFAULT_ADMIN_ROLE
            )
        );
        baseParentPeer.revokeRole(Roles.CONFIG_ADMIN_ROLE, configAdmin);
    }
}
