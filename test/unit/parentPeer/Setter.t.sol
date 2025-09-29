// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, console2, IYieldPeer, Log} from "../../BaseTest.t.sol";

contract SetterTest is BaseTest {
    // --- setRebalancer --- //
    function test_yield_parentPeer_setRebalancer_revertsWhen_notOwner() public {
        _changePrank(holder);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", holder));
        baseParentPeer.setRebalancer(address(0));
    }

    function test_yield_parentPeer_setRebalancer_success() public {
        address newRebalancer = makeAddr("newRebalancer");
        _changePrank(baseParentPeer.owner());
        baseParentPeer.setRebalancer(newRebalancer);
        assertEq(baseParentPeer.getRebalancer(), newRebalancer);
    }

    // --- setInitialActiveStrategy --- //
    function test_yield_parentPeer_setInitialActiveStrategy_revertsWhen_notOwner() public {
        _changePrank(holder);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", holder));
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

    // --- setFeeRate --- //
    function test_yield_parentPeer_setFeeRate_revertsWhen_notOwner() public {
        _changePrank(holder);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", holder));
        baseParentPeer.setFeeRate(1);
    }

    function test_yield_parentPeer_setFeeRate_revertsWhen_tooHigh() public {
        _changePrank(baseParentPeer.owner());
        vm.expectRevert(abi.encodeWithSignature("YieldFees__FeeRateTooHigh()"));
        baseParentPeer.setFeeRate(1_000_001);
    }

    function test_yield_parentPeer_setFeeRate_success() public {
        _changePrank(baseParentPeer.owner());
        baseParentPeer.setFeeRate(1);
        assertEq(baseParentPeer.getFeeRate(), 1);
    }
}
