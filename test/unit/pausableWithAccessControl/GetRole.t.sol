// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Roles} from "../../BaseTest.t.sol";

contract GetRoleTest is BaseTest {
    /// @dev Base test has one of each (config, crosschain, pauser/unpauser role) so we check the 0 index
    uint256 internal constant ROLE_MEMBER_INDEX = 0;

    uint256 internal constant REBALANCER_CONFIG_ADMINS_NUM = 2; // configAdmin (base test), configAdmin_2 (here)
    uint256 internal constant REBALANCER_CROSSCHAIN_ADMINS_NUM = 0; // none set - no role functions in rebalancer for this role
    uint256 internal constant REBALANCER_EMERGENCY_PAUSERS_NUM = 3; // pauser (base test), pauser 2 & 3 (here)
    uint256 internal constant REBALANCER_EMERGENCY_UNPAUSERS_NUM = 1; // unpauser (base test)

    uint256 internal constant YIELDPEER_CONFIG_ADMINS_NUM = 2; // configAdmin (base test), configAdmin_2 (here)
    uint256 internal constant YIELDPEER_CROSSCHAIN_ADMINS_NUM = 1; // crossChainAdmin (base test)
    uint256 internal constant YIELDPEER_EMERGENCY_PAUSERS_NUM = 3; // pauser (base test), pauser 2 & 3 (here)
    uint256 internal constant YIELDPEER_EMERGENCY_UNPAUSERS_NUM = 1; // unpauser (base test)

    /// @dev extra addresses with roles
    address configAdmin_2 = makeAddr("configAdmin_2");
    address emergencyPauser_2 = makeAddr("emergencyPauser_2");
    address emergencyPauser_3 = makeAddr("emergencyPauser_3");

    function setUp() public virtual override {
        super.setUp();

        /// @dev give extra addresses some roles
        _changePrank(baseRebalancer.owner());
        baseRebalancer.grantRole(Roles.CONFIG_ADMIN_ROLE, configAdmin_2);
        baseRebalancer.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser_2);
        baseRebalancer.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser_3);

        _changePrank(baseParentPeer.owner());
        baseParentPeer.grantRole(Roles.CONFIG_ADMIN_ROLE, configAdmin_2);
        baseParentPeer.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser_2);
        baseParentPeer.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser_3);
        _stopPrank();
    }

    function test_yield_pausableWithAccessControlRebalancer_getRoleMember_returnsRoleMember() public view {
        address returnedRebalancerConfigAdmin = baseRebalancer.getRoleMember(Roles.CONFIG_ADMIN_ROLE, ROLE_MEMBER_INDEX);
        address returnedRebalancerEmergencyPauser =
            baseRebalancer.getRoleMember(Roles.EMERGENCY_PAUSER_ROLE, ROLE_MEMBER_INDEX);
        address returnedRebalancerEmergencyUnpauser =
            baseRebalancer.getRoleMember(Roles.EMERGENCY_UNPAUSER_ROLE, ROLE_MEMBER_INDEX);

        assertEq(returnedRebalancerConfigAdmin, configAdmin);
        assertEq(returnedRebalancerEmergencyPauser, emergencyPauser);
        assertEq(returnedRebalancerEmergencyUnpauser, emergencyUnpauser);
    }

    function test_yield_pausableWithAccessControlYieldPeer_getRoleMember_returnsRoleMember() public view {
        address returnedYieldPeerConfigAdmin = baseParentPeer.getRoleMember(Roles.CONFIG_ADMIN_ROLE, ROLE_MEMBER_INDEX);
        address returnedYieldPeerCrossChainAdmin =
            baseParentPeer.getRoleMember(Roles.CROSS_CHAIN_ADMIN_ROLE, ROLE_MEMBER_INDEX);
        address returnedYieldPeerEmergencyPauser =
            baseParentPeer.getRoleMember(Roles.EMERGENCY_PAUSER_ROLE, ROLE_MEMBER_INDEX);
        address returnedYieldPeerEmergencyUnpauser =
            baseParentPeer.getRoleMember(Roles.EMERGENCY_UNPAUSER_ROLE, ROLE_MEMBER_INDEX);

        assertEq(returnedYieldPeerConfigAdmin, configAdmin);
        assertEq(returnedYieldPeerCrossChainAdmin, crossChainAdmin);
        assertEq(returnedYieldPeerEmergencyPauser, emergencyPauser);
        assertEq(returnedYieldPeerEmergencyUnpauser, emergencyUnpauser);
    }

    function test_yield_pausableWithAccessControlRebalancer_getRoleMemberCount_returnsRoleMemberCount() public view {
        uint256 returnedRebalancerConfigAdminRoleMemberCount =
            baseRebalancer.getRoleMemberCount(Roles.CONFIG_ADMIN_ROLE);
        uint256 returnedRebalancerCrossChainAdminRoleMemberCount =
            baseRebalancer.getRoleMemberCount(Roles.CROSS_CHAIN_ADMIN_ROLE);
        uint256 returnedRebalancerPauserRoleMemberCount = baseRebalancer.getRoleMemberCount(Roles.EMERGENCY_PAUSER_ROLE);
        uint256 returnedRebalancerUnpauserRoleMemberCount =
            baseRebalancer.getRoleMemberCount(Roles.EMERGENCY_UNPAUSER_ROLE);

        assertEq(returnedRebalancerConfigAdminRoleMemberCount, REBALANCER_CONFIG_ADMINS_NUM);
        assertEq(returnedRebalancerCrossChainAdminRoleMemberCount, REBALANCER_CROSSCHAIN_ADMINS_NUM);
        assertEq(returnedRebalancerPauserRoleMemberCount, REBALANCER_EMERGENCY_PAUSERS_NUM);
        assertEq(returnedRebalancerUnpauserRoleMemberCount, REBALANCER_EMERGENCY_UNPAUSERS_NUM);
    }

    function test_yield_pausableWithAccessControlYieldPeer_getRoleMemberCount_returnsRoleMemberCount() public view {
        uint256 returnedYieldPeerConfigAdminRoleMemberCount = baseParentPeer.getRoleMemberCount(Roles.CONFIG_ADMIN_ROLE);
        uint256 returnedYieldPeerCrossChainAdminRoleMemberCount =
            baseParentPeer.getRoleMemberCount(Roles.CROSS_CHAIN_ADMIN_ROLE);
        uint256 returnedYieldPeerPauserRoleMemberCount = baseParentPeer.getRoleMemberCount(Roles.EMERGENCY_PAUSER_ROLE);
        uint256 returnedYieldPeerUnpauserRoleMemberCount =
            baseParentPeer.getRoleMemberCount(Roles.EMERGENCY_UNPAUSER_ROLE);

        assertEq(returnedYieldPeerConfigAdminRoleMemberCount, YIELDPEER_CONFIG_ADMINS_NUM);
        assertEq(returnedYieldPeerCrossChainAdminRoleMemberCount, YIELDPEER_CROSSCHAIN_ADMINS_NUM);
        assertEq(returnedYieldPeerPauserRoleMemberCount, YIELDPEER_EMERGENCY_PAUSERS_NUM);
        assertEq(returnedYieldPeerUnpauserRoleMemberCount, YIELDPEER_EMERGENCY_UNPAUSERS_NUM);
    }

    function test_yield_pausableWithAccessControlRebalancer_getRoleMembers_returnsRoleMembers() public view {
        address[] memory returnedRebalancerConfigAdminRoleMembers =
            baseRebalancer.getRoleMembers(Roles.CONFIG_ADMIN_ROLE);
        address[] memory expectedRebalancerConfigAdminRoleMembers = new address[](2);
        expectedRebalancerConfigAdminRoleMembers[0] = configAdmin;
        expectedRebalancerConfigAdminRoleMembers[1] = configAdmin_2;

        address[] memory returnedRebalancerPauserRoleMembers =
            baseRebalancer.getRoleMembers(Roles.EMERGENCY_PAUSER_ROLE);
        address[] memory expectedRebalancerPauserRoleMembers = new address[](3);
        expectedRebalancerPauserRoleMembers[0] = emergencyPauser;
        expectedRebalancerPauserRoleMembers[1] = emergencyPauser_2;
        expectedRebalancerPauserRoleMembers[2] = emergencyPauser_3;

        address[] memory returnedRebalancerUnpauserRoleMembers =
            baseRebalancer.getRoleMembers(Roles.EMERGENCY_UNPAUSER_ROLE);
        address[] memory expectedRebalancerUnpauserRoleMembers = new address[](1);
        expectedRebalancerUnpauserRoleMembers[0] = emergencyUnpauser;

        assertEq(returnedRebalancerConfigAdminRoleMembers, expectedRebalancerConfigAdminRoleMembers);
        assertEq(returnedRebalancerPauserRoleMembers, expectedRebalancerPauserRoleMembers);
        assertEq(returnedRebalancerUnpauserRoleMembers, expectedRebalancerUnpauserRoleMembers);
    }

    function test_yield_pausableWithAccessControlYieldPeer_getRoleMembers_returnsRoleMembers() public view {
        address[] memory returnedYieldPeerConfigAdminRoleMembers =
            baseParentPeer.getRoleMembers(Roles.CONFIG_ADMIN_ROLE);
        address[] memory expectedYieldPeerConfigAdminRoleMembers = new address[](2);
        expectedYieldPeerConfigAdminRoleMembers[0] = configAdmin;
        expectedYieldPeerConfigAdminRoleMembers[1] = configAdmin_2;

        address[] memory returnedYieldPeerCrossChainAdminRoleMembers =
            baseParentPeer.getRoleMembers(Roles.CROSS_CHAIN_ADMIN_ROLE);
        address[] memory expectedYieldPeerCrossChainAdminRoleMembers = new address[](1);
        expectedYieldPeerCrossChainAdminRoleMembers[0] = crossChainAdmin;

        address[] memory returnedYieldPeerPauserRoleMembers = baseParentPeer.getRoleMembers(Roles.EMERGENCY_PAUSER_ROLE);
        address[] memory expectedYieldPeerPauserRoleMembers = new address[](3);
        expectedYieldPeerPauserRoleMembers[0] = emergencyPauser;
        expectedYieldPeerPauserRoleMembers[1] = emergencyPauser_2;
        expectedYieldPeerPauserRoleMembers[2] = emergencyPauser_3;

        address[] memory returnedYieldPeerUnpauserRoleMembers =
            baseParentPeer.getRoleMembers(Roles.EMERGENCY_UNPAUSER_ROLE);
        address[] memory expectedYieldPeerUnpauserRoleMembers = new address[](1);
        expectedYieldPeerUnpauserRoleMembers[0] = emergencyUnpauser;

        assertEq(returnedYieldPeerConfigAdminRoleMembers, expectedYieldPeerConfigAdminRoleMembers);
        assertEq(returnedYieldPeerCrossChainAdminRoleMembers, expectedYieldPeerCrossChainAdminRoleMembers);
        assertEq(returnedYieldPeerPauserRoleMembers, expectedYieldPeerPauserRoleMembers);
        assertEq(returnedYieldPeerUnpauserRoleMembers, expectedYieldPeerUnpauserRoleMembers);
    }

    // --- 'get role' tests for DEFAULT_ADMIN role (for sanity) --- //
    uint256 internal constant DEFAULT_ADMIN_ROLE_INDEX = 0;
    uint256 internal constant DEFAULT_ADMIN_ROLE_COUNT = 1;
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    function test_yield_pausableWithAccessControlRebalancer_getRoleMemberDefaultAdminRole_returnsDefaultAdmin()
        public
        view
    {
        address returnedDefaultAdmin = baseRebalancer.getRoleMember(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE_INDEX);
        assertEq(returnedDefaultAdmin, baseRebalancer.defaultAdmin());
    }

    function test_yield_pausableWithAccessControlYieldPeer_getRoleMemberDefaultAdminRole_returnsDefaultAdmin()
        public
        view
    {
        address returnedDefaultAdmin = baseParentPeer.getRoleMember(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE_INDEX);
        assertEq(returnedDefaultAdmin, baseParentPeer.defaultAdmin());
    }

    function test_yield_pausableWithAccessControlRebalancer_getRoleMemberCountDefaultAdminRole_returnsOne()
        public
        view
    {
        uint256 returnedDefaultAdminRoleCount = baseRebalancer.getRoleMemberCount(DEFAULT_ADMIN_ROLE);
        assertEq(returnedDefaultAdminRoleCount, DEFAULT_ADMIN_ROLE_COUNT);
    }

    function test_yield_pausableWithAccessControlYieldPeer_getRoleMemberCountDefaultAdminRole_returnsOne() public view {
        uint256 returnedDefaultAdminRoleCount = baseParentPeer.getRoleMemberCount(DEFAULT_ADMIN_ROLE);
        assertEq(returnedDefaultAdminRoleCount, DEFAULT_ADMIN_ROLE_COUNT);
    }

    function test_yield_pausableWithAccessControlRebalancer_getRoleMembersDefaultAdminRole_returnsDefaultAdmin()
        public
        view
    {
        address[] memory returnedDefaultAdminRoleMembers = baseRebalancer.getRoleMembers(DEFAULT_ADMIN_ROLE);
        address[] memory expectedDefaultAdminRoleMembers = new address[](1);
        expectedDefaultAdminRoleMembers[0] = baseRebalancer.defaultAdmin();
        assertEq(returnedDefaultAdminRoleMembers, expectedDefaultAdminRoleMembers);
    }

    function test_yield_pausableWithAccessControlYieldPeer_getRoleMembersDefaultAdminRole_returnsDefaultAdmin()
        public
        view
    {
        address[] memory returnedDefaultAdminRoleMembers = baseParentPeer.getRoleMembers(DEFAULT_ADMIN_ROLE);
        address[] memory expectedDefaultAdminRoleMembers = new address[](1);
        expectedDefaultAdminRoleMembers[0] = baseParentPeer.defaultAdmin();
        assertEq(returnedDefaultAdminRoleMembers, expectedDefaultAdminRoleMembers);
    }
}
