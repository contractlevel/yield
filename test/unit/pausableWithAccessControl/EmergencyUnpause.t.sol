// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, Roles} from "../../BaseTest.t.sol";

contract EmergencyUnpauseTest is BaseTest {
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
    function test_yield_pausableWithAccessControlRebalancer_emergencyUnpause_revertsWhen_noUnpauserRole() public {
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
    function test_yield_pausableWithAccessControlYieldPeer_emergencyUnpause_revertsWhen_noUnpauserRole() public {
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
    function test_yield_pausableWithAccessControlRebalancer_emergencyUnpause_revertWhen_notPaused() public {
        _changePrank(emergency_unpauser);
        vm.expectRevert(abi.encode("ExpectedPause()"));
        baseRebalancer.emergencyUnpause();
    }

    /// @dev emergency unpausing correctly reverts on yield peer if not paused
    function test_yield_pausableWithAccessControlYieldPeer_emergencyUnpause_revertsWhen_notPaused() public {
        _changePrank(emergency_unpauser);
        vm.expectRevert(abi.encode("ExpectedPause()"));
        baseParentPeer.emergencyUnpause();
    }
}
