// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";

contract SetFeesTest is BaseTest {
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
