// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, Roles} from "../../BaseTest.t.sol";

contract GrantRoleTest is BaseTest {
    uint256 internal constant ROLE_MEMBER_EMPTY = 0; /// @dev count for getRoleMember - 0 since role index is initially empty
    uint256 internal constant ROLE_MEMBER_INDEX = 0; /// @dev index used for getRoleMember - 0 since only one member is being added (to empty role index)
    uint256 internal constant ROLE_MEMBER_COUNT = 1; /// @dev count used for getRoleMemberCount - 1 since only one member is being added (to empty role index)
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    address newConfigAdmin = makeAddr("newConfigAdmin");
    address configAdminRoleAdmin = makeAddr("configAdminRoleAdmin");

    function setUp() public override {
        super.setUp();

        /// @dev Revoke role from 'configAdmin' in BaseTest to have clean slate
        _changePrank(baseParentPeer.owner());
        baseParentPeer.revokeRole(Roles.CONFIG_ADMIN_ROLE, configAdmin);
        assertEq(baseParentPeer.getRoleMemberCount(Roles.CONFIG_ADMIN_ROLE), ROLE_MEMBER_EMPTY);
        assertEq(baseParentPeer.hasRole(Roles.CONFIG_ADMIN_ROLE, configAdmin), false);
    }

    function test_yield_pausableWithAccessControlYieldPeer_grantRole_emitsRoleGrantedEvent() public {
        vm.recordLogs();
        _changePrank(baseParentPeer.owner());
        baseParentPeer.grantRole(Roles.CONFIG_ADMIN_ROLE, newConfigAdmin);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool grantRoleLogFound;
        bytes32 emittedRole;
        address emittedConfigAdmin;
        address emittedGranter;

        for (uint256 i = 0; i < logs.length; i++) {
            /// @dev event: RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
            if (logs[i].topics[0] == keccak256(("RoleGranted(bytes32,address,address)"))) {
                emittedRole = logs[i].topics[1];
                emittedConfigAdmin = address(uint160(uint256(logs[i].topics[2])));
                emittedGranter = address(uint160(uint256(logs[i].topics[3])));
                grantRoleLogFound = true;
                break;
            }
        }

        assertEq(grantRoleLogFound, true);
        assertEq(emittedRole, Roles.CONFIG_ADMIN_ROLE);
        assertEq(emittedConfigAdmin, newConfigAdmin);
        assertEq(emittedGranter, baseParentPeer.owner());
    }

    function test_yield_pausableWithAccessControlYieldPeer_grantRole_updatesRoleStorage() public {
        /// @dev Roles are stored in two places:
        /*
        struct RoleData {
            mapping(address account => bool) hasRole;
            bytes32 adminRole;
        }
        mapping(bytes32 role => RoleData) private _roles;

        mapping(bytes32 role => EnumerableSet.AddressSet) private s_roleMembers;
        */
        /// @dev _roles mapping shows if address has role for access control
        /// @dev s_roleMembers mapping keeps track of role members for enumeration

        address[] memory expectedConfigAdminRoleMembers = new address[](1);
        expectedConfigAdminRoleMembers[0] = newConfigAdmin;

        _changePrank(baseParentPeer.owner());
        baseParentPeer.grantRole(Roles.CONFIG_ADMIN_ROLE, newConfigAdmin);

        assertEq(baseParentPeer.hasRole(Roles.CONFIG_ADMIN_ROLE, newConfigAdmin), true); /// -------------------- @dev Check hasRole in _roles mapping updated
        assertEq(baseParentPeer.getRoleMember(Roles.CONFIG_ADMIN_ROLE, ROLE_MEMBER_INDEX), newConfigAdmin); /// - @dev Check s_roleMembers updated
        assertEq(baseParentPeer.getRoleMemberCount(Roles.CONFIG_ADMIN_ROLE), ROLE_MEMBER_COUNT); /// ------------ @dev Check s_roleMembers updated
        assertEq(baseParentPeer.getRoleMembers(Roles.CONFIG_ADMIN_ROLE), expectedConfigAdminRoleMembers); /// --- @dev Check s_roleMembers updated
    }

    function test_yield_pausableWithAccessControlYieldPeer_grantRole_revertsWhen_notDefaultAdmin() public {
        _changePrank(emergencyPauser);
        /// @dev error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", emergencyPauser, DEFAULT_ADMIN_ROLE
            )
        );
        baseParentPeer.grantRole(Roles.CONFIG_ADMIN_ROLE, newConfigAdmin);
    }
}
