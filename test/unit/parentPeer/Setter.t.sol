// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, console2, IYieldPeer, Log, Roles} from "../../BaseTest.t.sol";

contract SetterTest is BaseTest {
    // --- setRebalancer --- //
    function test_yield_parentPeer_setRebalancer_revertsWhen_notConfigAdmin() public {
        _changePrank(holder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", holder, Roles.CONFIG_ADMIN_ROLE
            )
        );
        baseParentPeer.setRebalancer(address(0));
    }

    function test_yield_parentPeer_setRebalancer_success() public {
        address newRebalancer = makeAddr("newRebalancer");
        _changePrank(configAdmin);
        baseParentPeer.setRebalancer(newRebalancer);
        assertEq(baseParentPeer.getRebalancer(), newRebalancer);
    }

    // --- setInitialActiveStrategy --- //
    function test_yield_parentPeer_setInitialActiveStrategy_revertsWhen_notDefaultAdmin() public {
        bytes32 DEFAULT_ADMIN_ROLE = 0x00;

        _changePrank(holder);
        vm.expectRevert(
            abi.encodeWithSignature("AccessControlUnauthorizedAccount(address,bytes32)", holder, DEFAULT_ADMIN_ROLE)
        );
        baseParentPeer.setInitialActiveStrategy(keccak256(abi.encodePacked("aave-v3")));
    }

    function test_yield_parentPeer_setInitialActiveStrategy_revertsWhen_alreadySet() public {
        _changePrank(baseParentPeer.owner());
        vm.expectRevert(abi.encodeWithSignature("ParentPeer__InitialActiveStrategyAlreadySet()"));
        baseParentPeer.setInitialActiveStrategy(keccak256(abi.encodePacked("aave-v3")));
    }

    function test_yield_parentPeer_setInitialActiveStrategy_success() public view {
        assertEq(baseParentPeer.getStrategy().protocolId, keccak256(abi.encodePacked("aave-v3")));
    }
}
