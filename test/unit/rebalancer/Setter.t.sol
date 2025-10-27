// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {
    BaseTest,
    Vm,
    console2,
    ParentPeer,
    ChildPeer,
    Share,
    IYieldPeer,
    Rebalancer,
    Roles
} from "../../BaseTest.t.sol";

contract SetterTest is BaseTest {
    // --- setUpkeepAddress --- //
    function test_yield_rebalancer_setUpkeepAddress_revertsWhen_notConfigAdmin() public {
        _changePrank(holder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", holder, Roles.CONFIG_ADMIN_ROLE
            )
        );
        baseRebalancer.setUpkeepAddress(address(0));
    }

    function test_yield_rebalancer_setUpkeepAddress_success() public {
        address newUpkeepAddress = makeAddr("newUpkeepAddress");
        _changePrank(config_admin);
        baseRebalancer.setUpkeepAddress(newUpkeepAddress);
        assertEq(baseRebalancer.getUpkeepAddress(), newUpkeepAddress);
    }

    // --- setForwarder --- //
    function test_yield_rebalancer_setForwarder_revertsWhen_notConfigAdmin() public {
        _changePrank(holder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", holder, Roles.CONFIG_ADMIN_ROLE
            )
        );
        baseRebalancer.setForwarder(address(forwarder));
    }

    function test_yield_rebalancer_setForwarder_success() public {
        address newForwarder = makeAddr("newForwarder");
        _changePrank(config_admin);
        baseRebalancer.setForwarder(newForwarder);
        assertEq(baseRebalancer.getForwarder(), newForwarder);
    }

    // --- setParentPeer --- //
    function test_yield_rebalancer_setParentPeer_revertsWhen_notConfigAdmin() public {
        address newParentPeer = makeAddr("newParentPeer");
        _changePrank(holder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", holder, Roles.CONFIG_ADMIN_ROLE
            )
        );
        baseRebalancer.setParentPeer(newParentPeer);
    }

    function test_yield_rebalancer_setParentPeer_success() public {
        address newParentPeer = makeAddr("newParentPeer");
        _changePrank(config_admin);
        baseRebalancer.setParentPeer(newParentPeer);
        assertEq(baseRebalancer.getParentPeer(), newParentPeer);
    }

    // --- setStrategyRegistry --- //
    function test_yield_rebalancer_setStrategyRegistry_revertsWhen_notConfigAdmin() public {
        address newStrategyRegistry = makeAddr("newStrategyRegistry");
        _changePrank(holder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", holder, Roles.CONFIG_ADMIN_ROLE
            )
        );
        baseRebalancer.setStrategyRegistry(newStrategyRegistry);
    }

    function test_yield_rebalancer_setStrategyRegistry_success() public {
        address newStrategyRegistry = makeAddr("newStrategyRegistry");
        _changePrank(config_admin);
        baseRebalancer.setStrategyRegistry(newStrategyRegistry);
        assertEq(baseRebalancer.getStrategyRegistry(), newStrategyRegistry);
    }
}
