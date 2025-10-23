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

        uint256 ownerBalanceBefore = baseUsdc.balanceOf(baseParentPeer.owner());

        /// @dev act
        _changePrank(baseParentPeer.owner());
        baseParentPeer.grantRole(Roles.FEE_WITHDRAWER_ROLE, baseParentPeer.owner());
        baseParentPeer.withdrawFees(address(baseUsdc));

        uint256 ownerBalanceAfter = baseUsdc.balanceOf(baseParentPeer.owner());

        /// @dev assert
        assertEq(ownerBalanceAfter - ownerBalanceBefore, _getFee(DEPOSIT_AMOUNT));
    }

    function test_yield_parent_withdrawFees_revertsWhen_noFeesToWithdraw() public {
        _changePrank(baseParentPeer.owner());
        baseParentPeer.grantRole(Roles.FEE_WITHDRAWER_ROLE, baseParentPeer.owner());
        vm.expectRevert(abi.encodeWithSignature("YieldFees__NoFeesToWithdraw()"));
        baseParentPeer.withdrawFees(address(baseUsdc));
    }
}
