// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, Roles} from "../../BaseTest.t.sol";

contract EmergencyPauseTest is BaseTest {
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
    function test_yield_pausableWithAccessControlRebalancer_emergencyPause_revertsWhen_noPauserRole() public {
        _changePrank(holder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", holder, Roles.EMERGENCY_PAUSER_ROLE
            )
        );
        baseRebalancer.emergencyPause();
    }

    /// @dev emergency pausing reverts on yield peer if caller doesn't have correct pauser role
    function test_yield_pausableWithAccessControlYieldPeer_emergencyPause_revertsWhen_noPauserRole() public {
        _changePrank(holder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", holder, Roles.EMERGENCY_PAUSER_ROLE
            )
        );
        baseParentPeer.emergencyPause();
    }

    /// @dev emergency pausing correctly reverts on rebalancer if already paused
    function test_yield_pausableWithAccessControlRebalancer_emergencyPause_revertsWhen_alreadyPaused() public {
        _changePrank(emergency_pauser);
        baseRebalancer.emergencyPause();
        vm.expectRevert(abi.encode("EnforcedPause()"));
        baseRebalancer.emergencyPause();
    }

    /// @dev emergency pausing correctly reverts on yield peer if already paused
    function test_yield_pausableWithAccessControlYieldPeer_emergencyPause_revertsWhen_alreadyPaused() public {
        _changePrank(emergency_pauser);
        baseParentPeer.emergencyPause();
        vm.expectRevert(abi.encode("EnforcedPause()"));
        baseParentPeer.emergencyPause();
    }
}
