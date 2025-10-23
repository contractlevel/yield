// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, Roles} from "../../BaseTest.t.sol";

contract PausableWithAccessControlTest is BaseTest {
    address internal config_admin = makeAddr("config_admin");
    address internal cross_chain_admin = makeAddr("config_admin");
    address internal emergency_pauser = makeAddr("emergency_pauser");
    address internal emergency_unpauser = makeAddr("emergency_unpauser");
    address internal no_role_caller = makeAddr("no_role_caller");

    function setUp() public override {
        super.setUp();

        _changePrank(baseRebalancer.owner());
        baseRebalancer.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergency_pauser);
        baseRebalancer.grantRole(Roles.EMERGENCY_UNPAUSER_ROLE, emergency_unpauser);
        baseRebalancer.grantRole(Roles.CONFIG_ADMIN_ROLE, config_admin);
        baseRebalancer.grantRole(Roles.CROSS_CHAIN_ADMIN_ROLE, cross_chain_admin);

        _changePrank(baseParentPeer.owner());
        baseParentPeer.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergency_pauser);
        baseParentPeer.grantRole(Roles.EMERGENCY_UNPAUSER_ROLE, emergency_unpauser);
        baseParentPeer.grantRole(Roles.CONFIG_ADMIN_ROLE, config_admin);
        baseParentPeer.grantRole(Roles.CROSS_CHAIN_ADMIN_ROLE, cross_chain_admin);
    }

    /*-----> Constructor <-----*/
    function test_yield_pausableWithAccessControlRebalancer_constructor() public view {
        /// @dev deployed admin transfer delay value in constructor is correct
        assertEq(baseRebalancer.defaultAdminDelay(), 3 days); // @reviewGeorge : check delay

        /// @dev deploying 'owner' should be 'default admin' role
        assertEq(baseRebalancer.owner(), baseRebalancer.defaultAdmin());
    }

    function test_yield_pausableWithAccessControlYieldPeer_constructor() public view {
        /// @dev deployed admin transfer delay value in constructor is correct
        assertEq(baseParentPeer.defaultAdminDelay(), 3 days); // @reviewGeorge : check delay

        /// @dev deploying 'owner' should be 'default admin' role
        assertEq(baseParentPeer.owner(), baseParentPeer.defaultAdmin());
    }

    /*-----> Emergency Pause <-----*/
    /// @dev emergency pausing correctly pauses rebalancer and emits paused log
    function test_yield_pausableWithAccessControlRebalancer_emergencyPause_success() public {
        vm.recordLogs();
        _changePrank(emergency_pauser);
        baseRebalancer.emergencyPause();
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool pausedLogFound;
        address pauser;

        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256(("Paused(address)"))) {
                pauser = abi.decode(logs[i].data, (address));
                pausedLogFound = true;
                break;
            }
        }

        assertEq(baseRebalancer.paused(), true);
        assertEq(pausedLogFound, true);
        assertEq(pauser, emergency_pauser);
    }

    /// @dev emergency pausing correctly pauses yield peer and emits paused log
    function test_yield_pausableWithAccessControlYieldPeer_emergencyPause_success() public {
        vm.recordLogs();
        _changePrank(emergency_pauser);
        baseParentPeer.emergencyPause();
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool pausedLogFound;
        address pauser;

        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256(("Paused(address)"))) {
                pauser = abi.decode(logs[i].data, (address));
                pausedLogFound = true;
                break;
            }
        }

        assertEq(baseParentPeer.paused(), true);
        assertEq(pausedLogFound, true);
        assertEq(pauser, emergency_pauser);
    }

    /// @dev emergency pausing reverts on rebalancer if caller doesn't have correct pauser role
    function test_yield_pausableWithAccessControlRebalancer_emergencyPauseReverts_ifNoPauserRole() public {
        _changePrank(no_role_caller);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", no_role_caller, Roles.EMERGENCY_PAUSER_ROLE
            )
        );
        baseRebalancer.emergencyPause();
    }

    /// @dev emergency pausing reverts on yield peer if caller doesn't have correct pauser role
    function test_yield_pausableWithAccessControlYieldPeer_emergencyPauseReverts_ifNoPauserRole() public {
        _changePrank(no_role_caller);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", no_role_caller, Roles.EMERGENCY_PAUSER_ROLE
            )
        );
        baseParentPeer.emergencyPause();
    }

    /// @dev emergency pausing correctly reverts on rebalancer if already paused
    function test_yield_pausableWithAccessControlRebalancer_emergencyPauseReverts_ifAlreadyPaused() public {
        _changePrank(emergency_pauser);
        baseRebalancer.emergencyPause();
        vm.expectRevert(abi.encode("EnforcedPause()"));
        baseRebalancer.emergencyPause();
    }

    /// @dev emergency pausing correctly reverts on yield peer if already paused
    function test_yield_pausableWithAccessControlYieldPeer_emergencyPauseReverts_ifAlreadyPaused() public {
        _changePrank(emergency_pauser);
        baseParentPeer.emergencyPause();
        vm.expectRevert(abi.encode("EnforcedPause()"));
        baseParentPeer.emergencyPause();
    }

    /*-----> Emergency Unpause <-----*/
    /// @dev emergency unpausing correctly unpauses rebalancer and emits unpaused log
    function test_yield_pausableWithAccessControlRebalancer_emergencyUnpause_success() public {
        vm.recordLogs();
        _changePrank(emergency_pauser);
        baseRebalancer.emergencyPause();
        _changePrank(emergency_unpauser);
        baseRebalancer.emergencyUnpause();

        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool unpausedLogFound;
        address unpauser;

        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256(("Unpaused(address)"))) {
                unpauser = abi.decode(logs[i].data, (address));
                unpausedLogFound = true;
                break;
            }
        }

        assertEq(baseRebalancer.paused(), false);
        assertEq(unpausedLogFound, true);
        assertEq(unpauser, emergency_unpauser);
    }

    /// @dev emergency unpausing correctly unpauses yield peer and emits unpaused log
    function test_yield_pausableWithAccessControlYieldPeer_emergencyUnpause_success() public {
        vm.recordLogs();
        _changePrank(emergency_pauser);
        baseParentPeer.emergencyPause();
        _changePrank(emergency_unpauser);
        baseParentPeer.emergencyUnpause();

        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool unpausedLogFound;
        address unpauser;

        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256(("Unpaused(address)"))) {
                unpauser = abi.decode(logs[i].data, (address));
                unpausedLogFound = true;
                break;
            }
        }

        assertEq(baseParentPeer.paused(), false);
        assertEq(unpausedLogFound, true);
        assertEq(unpauser, emergency_unpauser);
    }

    /// @dev emergency unpausing reverts on rebalancer if caller doesn't have correct unpauser role
    function test_yield_pausableWithAccessControlRebalancer_emergencyUnpauseReverts_ifNoUnpauserRole() public {
        _changePrank(emergency_pauser);
        baseRebalancer.emergencyPause();
        _changePrank(no_role_caller);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", no_role_caller, Roles.EMERGENCY_UNPAUSER_ROLE
            )
        );
        baseRebalancer.emergencyUnpause();
    }

    /// @dev emergency unpausing reverts on yield peer if caller doesn't have correct unpauser role
    function test_yield_pausableWithAccessControlYieldPeer_emergencyUnpauseReverts_ifNoUnpauserRole() public {
        _changePrank(emergency_pauser);
        baseParentPeer.emergencyPause();
        _changePrank(no_role_caller);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", no_role_caller, Roles.EMERGENCY_UNPAUSER_ROLE
            )
        );
        baseParentPeer.emergencyUnpause();
    }

    /// @dev emergency unpausing correctly reverts on rebalancer if not paused
    function test_yield_pausableWithAccessControlRebalancer_emergencyUnauseReverts_ifNotPaused() public {
        _changePrank(emergency_unpauser);
        vm.expectRevert(abi.encode("ExpectedPause()"));
        baseRebalancer.emergencyUnpause();
    }

    /// @dev emergency unpausing correctly reverts on yield peer if not paused
    function test_yield_pausableWithAccessControlYieldPeer_emergencyUnpauseReverts_ifNotPaused() public {
        _changePrank(emergency_unpauser);
        vm.expectRevert(abi.encode("ExpectedPause()"));
        baseParentPeer.emergencyUnpause();
    }

    /*-----> General Access Control/onlyRole <-----*/
    /// @dev General access control of functions which implemented onlyRole are tested in their respective unit test contracts

    /*-----> Role Member Getters <-----*/
    function test_yield_pausableWithAccessControlRebalancer_getRoleMember_returnsMember() public view {
        address returnedConfigAdmin = baseRebalancer.getRoleMember(Roles.CONFIG_ADMIN_ROLE, 0);
        address returnedCrossChainAdmin = baseRebalancer.getRoleMember(Roles.CROSS_CHAIN_ADMIN_ROLE, 0);
        address returnedEmergencyPauser = baseRebalancer.getRoleMember(Roles.EMERGENCY_PAUSER_ROLE, 0);
        address returnedEmergencyUnpauser = baseRebalancer.getRoleMember(Roles.EMERGENCY_UNPAUSER_ROLE, 0);

        assertEq(returnedConfigAdmin, config_admin);
        assertEq(returnedCrossChainAdmin, cross_chain_admin);
        assertEq(returnedEmergencyPauser, emergency_pauser);
        assertEq(returnedEmergencyUnpauser, emergency_unpauser);
    }

    function test_yield_pausableWithAccessControlYieldPeer_getRoleMember_returnsMember() public view {
        address returnedConfigAdmin = baseParentPeer.getRoleMember(Roles.CONFIG_ADMIN_ROLE, 0);
        address returnedCrossChainAdmin = baseParentPeer.getRoleMember(Roles.CROSS_CHAIN_ADMIN_ROLE, 0);
        address returnedEmergencyPauser = baseParentPeer.getRoleMember(Roles.EMERGENCY_PAUSER_ROLE, 0);
        address returnedEmergencyUnpauser = baseParentPeer.getRoleMember(Roles.EMERGENCY_UNPAUSER_ROLE, 0);

        assertEq(returnedConfigAdmin, config_admin);
        assertEq(returnedCrossChainAdmin, cross_chain_admin);
        assertEq(returnedEmergencyPauser, emergency_pauser);
        assertEq(returnedEmergencyUnpauser, emergency_unpauser);
    }

    function test_yield_pausableWithAccessControlRebalancer_getRoleMemberCount_returnsMemberCount() public {
        /// @dev randomly add more role members
        address config_admin_2 = makeAddr("config_admin_2");
        address emergency_pauser_2 = makeAddr("emergency_pauser_2");
        address emergency_pauser_3 = makeAddr("emergency_pauser_3");
        _changePrank(baseRebalancer.owner());
        baseRebalancer.grantRole(Roles.CONFIG_ADMIN_ROLE, config_admin_2);
        baseRebalancer.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergency_pauser_2);
        baseRebalancer.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergency_pauser_3);

        uint256 returnedConfigAdminRoleMemberCount = baseRebalancer.getRoleMemberCount(Roles.CONFIG_ADMIN_ROLE);
        uint256 returnedCrossChainAdminRoleMemberCount = baseRebalancer.getRoleMemberCount(Roles.CROSS_CHAIN_ADMIN_ROLE);
        uint256 returnedEmergencyPauserRoleMemberCount = baseRebalancer.getRoleMemberCount(Roles.EMERGENCY_PAUSER_ROLE);
        uint256 returnedEmergencyUnpauserRoleMemberCount =
            baseRebalancer.getRoleMemberCount(Roles.EMERGENCY_UNPAUSER_ROLE);

        assertEq(returnedConfigAdminRoleMemberCount, 2);
        assertEq(returnedCrossChainAdminRoleMemberCount, 1);
        assertEq(returnedEmergencyPauserRoleMemberCount, 3);
        assertEq(returnedEmergencyUnpauserRoleMemberCount, 1);
    }

    function test_yield_pausableWithAccessControlYieldPeer_getRoleMemberCount_returnsMemberCount() public {
        /// @dev randomly add more role members
        address config_admin_2 = makeAddr("config_admin_2");
        address emergency_pauser_2 = makeAddr("emergency_pauser_2");
        address emergency_pauser_3 = makeAddr("emergency_pauser_3");
        _changePrank(baseParentPeer.owner());
        baseParentPeer.grantRole(Roles.CONFIG_ADMIN_ROLE, config_admin_2);
        baseParentPeer.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergency_pauser_2);
        baseParentPeer.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergency_pauser_3);

        uint256 returnedConfigAdminRoleMemberCount = baseParentPeer.getRoleMemberCount(Roles.CONFIG_ADMIN_ROLE);
        uint256 returnedCrossChainAdminRoleMemberCount = baseParentPeer.getRoleMemberCount(Roles.CROSS_CHAIN_ADMIN_ROLE);
        uint256 returnedEmergencyPauserRoleMemberCount = baseParentPeer.getRoleMemberCount(Roles.EMERGENCY_PAUSER_ROLE);
        uint256 returnedEmergencyUnpauserRoleMemberCount =
            baseParentPeer.getRoleMemberCount(Roles.EMERGENCY_UNPAUSER_ROLE);

        assertEq(returnedConfigAdminRoleMemberCount, 2);
        assertEq(returnedCrossChainAdminRoleMemberCount, 1);
        assertEq(returnedEmergencyPauserRoleMemberCount, 3);
        assertEq(returnedEmergencyUnpauserRoleMemberCount, 1);
    }

    function test_yield_pausableWithAccessControlRebalancer_getRoleMembers_returnsMembers() public {
        /// @dev randomly add more role members
        address config_admin_2 = makeAddr("config_admin_2");
        address emergency_pauser_2 = makeAddr("emergency_pauser_2");
        address emergency_pauser_3 = makeAddr("emergency_pauser_3");
        _changePrank(baseRebalancer.owner());
        baseRebalancer.grantRole(Roles.CONFIG_ADMIN_ROLE, config_admin_2);
        baseRebalancer.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergency_pauser_2);
        baseRebalancer.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergency_pauser_3);

        address[] memory returnedConfigAdminRoleMembers = baseRebalancer.getRoleMembers(Roles.CONFIG_ADMIN_ROLE);
        address[] memory expectedConfigAdminRoleMembers = new address[](2);
        expectedConfigAdminRoleMembers[0] = config_admin;
        expectedConfigAdminRoleMembers[1] = config_admin_2;

        address[] memory returnedCrossChainAdminRoleMembers =
            baseRebalancer.getRoleMembers(Roles.CROSS_CHAIN_ADMIN_ROLE);
        address[] memory expectedCrossChainAdminRoleMembers = new address[](1);
        expectedCrossChainAdminRoleMembers[0] = cross_chain_admin;

        address[] memory returnedPauserRoleMembers = baseRebalancer.getRoleMembers(Roles.EMERGENCY_PAUSER_ROLE);
        address[] memory expectedPauserRoleMembers = new address[](3);
        expectedPauserRoleMembers[0] = emergency_pauser;
        expectedPauserRoleMembers[1] = emergency_pauser_2;
        expectedPauserRoleMembers[2] = emergency_pauser_3;

        address[] memory returnedUnpauserRoleMembers = baseRebalancer.getRoleMembers(Roles.EMERGENCY_UNPAUSER_ROLE);
        address[] memory expectedUnpauserRoleMembers = new address[](1);
        expectedUnpauserRoleMembers[0] = emergency_unpauser;

        assertEq(returnedConfigAdminRoleMembers, expectedConfigAdminRoleMembers);
        assertEq(returnedCrossChainAdminRoleMembers, expectedCrossChainAdminRoleMembers);
        assertEq(returnedPauserRoleMembers, expectedPauserRoleMembers);
        assertEq(returnedUnpauserRoleMembers, expectedUnpauserRoleMembers);
    }

    function test_yield_pausableWithAccessControlYieldPeer_getRoleMembers_returnsMembers() public {
        /// @dev randomly add more role members
        address config_admin_2 = makeAddr("config_admin_2");
        address emergency_pauser_2 = makeAddr("emergency_pauser_2");
        address emergency_pauser_3 = makeAddr("emergency_pauser_3");
        _changePrank(baseParentPeer.owner());
        baseParentPeer.grantRole(Roles.CONFIG_ADMIN_ROLE, config_admin_2);
        baseParentPeer.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergency_pauser_2);
        baseParentPeer.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergency_pauser_3);

        address[] memory returnedConfigAdminRoleMembers = baseParentPeer.getRoleMembers(Roles.CONFIG_ADMIN_ROLE);
        address[] memory expectedConfigAdminRoleMembers = new address[](2);
        expectedConfigAdminRoleMembers[0] = config_admin;
        expectedConfigAdminRoleMembers[1] = config_admin_2;

        address[] memory returnedCrossChainAdminRoleMembers =
            baseParentPeer.getRoleMembers(Roles.CROSS_CHAIN_ADMIN_ROLE);
        address[] memory expectedCrossChainAdminRoleMembers = new address[](1);
        expectedCrossChainAdminRoleMembers[0] = cross_chain_admin;

        address[] memory returnedPauserRoleMembers = baseParentPeer.getRoleMembers(Roles.EMERGENCY_PAUSER_ROLE);
        address[] memory expectedPauserRoleMembers = new address[](3);
        expectedPauserRoleMembers[0] = emergency_pauser;
        expectedPauserRoleMembers[1] = emergency_pauser_2;
        expectedPauserRoleMembers[2] = emergency_pauser_3;

        address[] memory returnedUnpauserRoleMembers = baseParentPeer.getRoleMembers(Roles.EMERGENCY_UNPAUSER_ROLE);
        address[] memory expectedUnpauserRoleMembers = new address[](1);
        expectedUnpauserRoleMembers[0] = emergency_unpauser;

        assertEq(returnedConfigAdminRoleMembers, expectedConfigAdminRoleMembers);
        assertEq(returnedCrossChainAdminRoleMembers, expectedCrossChainAdminRoleMembers);
        assertEq(returnedPauserRoleMembers, expectedPauserRoleMembers);
        assertEq(returnedUnpauserRoleMembers, expectedUnpauserRoleMembers);
    }
}
