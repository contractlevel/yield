// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Roles} from "../../BaseTest.t.sol";

contract SetFeesTest is BaseTest {
    // --- setFeeRate --- //
    function test_yield_parentPeer_setFeeRate_revertsWhen_notFeeRateSetter() public {
        _changePrank(holder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", holder, Roles.FEE_RATE_SETTER_ROLE
            )
        );
        baseParentPeer.setFeeRate(1);
    }

    function test_yield_parentPeer_setFeeRate_revertsWhen_tooHigh() public {
        _changePrank(feeRateSetter);
        vm.expectRevert(abi.encodeWithSignature("YieldFees__FeeRateTooHigh()"));
        baseParentPeer.setFeeRate(1_000_001);
    }

    function test_yield_parentPeer_setFeeRate_success() public {
        _changePrank(feeRateSetter);
        baseParentPeer.setFeeRate(1);
        assertEq(baseParentPeer.getFeeRate(), 1);
    }
}
