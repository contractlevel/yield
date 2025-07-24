// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, console2, ParentPeer, ChildPeer, Share, IYieldPeer, Rebalancer} from "../../BaseTest.t.sol";

contract SetterTest is BaseTest {
    // --- setUpkeepAddress --- //
    function test_yield_rebalancer_setUpkeepAddress_revertsWhen_notOwner() public {
        _changePrank(holder);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", holder));
        baseRebalancer.setUpkeepAddress(address(0));
    }

    function test_yield_rebalancer_setUpkeepAddress_success() public {
        address newUpkeepAddress = makeAddr("newUpkeepAddress");
        _changePrank(baseRebalancer.owner());
        baseRebalancer.setUpkeepAddress(newUpkeepAddress);
        assertEq(baseRebalancer.getUpkeepAddress(), newUpkeepAddress);
    }

    // --- setForwarder --- //
    function test_yield_rebalancer_setForwarder_revertsWhen_notOwner() public {
        _changePrank(holder);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", holder));
        baseRebalancer.setForwarder(address(forwarder));
    }

    function test_yield_rebalancer_setForwarder_success() public {
        address newForwarder = makeAddr("newForwarder");
        _changePrank(baseRebalancer.owner());
        baseRebalancer.setForwarder(newForwarder);
        assertEq(baseRebalancer.getForwarder(), newForwarder);
    }

    // --- setParentPeer --- //
    function test_yield_rebalancer_setParentPeer_revertsWhen_notOwner() public {
        address newParentPeer = makeAddr("newParentPeer");
        _changePrank(holder);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", holder));
        baseRebalancer.setParentPeer(newParentPeer);
    }

    function test_yield_rebalancer_setParentPeer_success() public {
        address newParentPeer = makeAddr("newParentPeer");
        _changePrank(baseRebalancer.owner());
        baseRebalancer.setParentPeer(newParentPeer);
        assertEq(baseRebalancer.getParentPeer(), newParentPeer);
    }

    // --- setStrategyRegistry --- //
    function test_yield_rebalancer_setStrategyRegistry_revertsWhen_notOwner() public {
        address newStrategyRegistry = makeAddr("newStrategyRegistry");
        _changePrank(holder);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", holder));
        baseRebalancer.setStrategyRegistry(newStrategyRegistry);
    }

    function test_yield_rebalancer_setStrategyRegistry_success() public {
        address newStrategyRegistry = makeAddr("newStrategyRegistry");
        _changePrank(baseRebalancer.owner());
        baseRebalancer.setStrategyRegistry(newStrategyRegistry);
        assertEq(baseRebalancer.getStrategyRegistry(), newStrategyRegistry);
    }

    // @review - these should be moved
    function test_yield_rebalanceNewStrategy_revertsWhen_notParentRebalancer() public {
        vm.expectRevert(abi.encodeWithSignature("ParentPeer__OnlyRebalancer()"));
        baseParentPeer.rebalanceNewStrategy(
            address(0), 0, IYieldPeer.Strategy({chainSelector: 0, protocolId: keccak256(abi.encodePacked("aave-v3"))})
        );
    }

    function test_yield_rebalanceOldStrategy_revertsWhen_notParentRebalancer() public {
        vm.expectRevert(abi.encodeWithSignature("ParentPeer__OnlyRebalancer()"));
        baseParentPeer.rebalanceOldStrategy(
            0, IYieldPeer.Strategy({chainSelector: 0, protocolId: keccak256(abi.encodePacked("aave-v3"))})
        );
    }
}
