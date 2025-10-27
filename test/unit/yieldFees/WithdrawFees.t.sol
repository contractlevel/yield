// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Roles} from "../../BaseTest.t.sol";

contract WithdrawFeesTest is BaseTest {
    function setUp() public override {
        super.setUp();
        /// @dev set the fee rate
        _setFeeRate(INITIAL_FEE_RATE);

        /// @dev baseFork is the parent chain
        _selectFork(baseFork);
        deal(address(baseUsdc), depositor, DEPOSIT_AMOUNT);
    }

    function test_yield_parent_withdrawFees_revertsWhen_notFeeWithdrawer() public {
        _changePrank(holder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", holder, Roles.FEE_WITHDRAWER_ROLE
            )
        );
        baseParentPeer.withdrawFees(address(baseUsdc));
    }

    function test_yield_parent_withdrawFees_success() public {
        /// @dev arrange
        _changePrank(depositor);
        baseUsdc.approve(address(baseParentPeer), DEPOSIT_AMOUNT);
        baseParentPeer.deposit(DEPOSIT_AMOUNT);

        uint256 feeWithdrawerBalanceBefore = baseUsdc.balanceOf(fee_withdrawer);

        /// @dev act
        _changePrank(fee_withdrawer);
        baseParentPeer.withdrawFees(address(baseUsdc));

        uint256 feeWithdrawerBalanceAfter = baseUsdc.balanceOf(fee_withdrawer);

        /// @dev assert
        assertEq(feeWithdrawerBalanceAfter - feeWithdrawerBalanceBefore, _getFee(DEPOSIT_AMOUNT));
    }

    function test_yield_parent_withdrawFees_revertsWhen_noFeesToWithdraw() public {
        _changePrank(fee_withdrawer);
        vm.expectRevert(abi.encodeWithSignature("YieldFees__NoFeesToWithdraw()"));
        baseParentPeer.withdrawFees(address(baseUsdc));
    }
}
