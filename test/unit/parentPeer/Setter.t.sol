// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {BaseTest, Vm, console2, IYieldPeer, Roles} from "../../BaseTest.t.sol";

contract SetterTest is BaseTest {
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

    // --- setSupportedProtocol --- //
    function test_yield_parentPeer_setSupportedProtocol_revertsWhen_notConfigAdmin() public {
        _changePrank(holder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", holder, Roles.CONFIG_ADMIN_ROLE
            )
        );
        baseParentPeer.setSupportedProtocol(keccak256(abi.encodePacked("aave-v3")), true);
    }

    function test_yield_parentPeer_setSupportedProtocol_success() public {
        bytes32 protocolId = keccak256("protocolId");
        _changePrank(configAdmin);
        baseParentPeer.setSupportedProtocol(protocolId, true);
        assertEq(baseParentPeer.getSupportedProtocol(protocolId), true);
    }
}
