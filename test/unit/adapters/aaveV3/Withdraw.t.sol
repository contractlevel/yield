// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../../BaseTest.t.sol";

contract WithdrawTest is BaseTest {
    function test_yield_aaveV3Adapter_withdraw_revertsWhen_notYieldPeer() public {
        vm.expectRevert(abi.encodeWithSignature("StrategyAdapter__OnlyYieldPeer()"));
        baseAaveV3Adapter.withdraw(address(baseUsdc), DEPOSIT_AMOUNT);
    }

    function test_yield_aaveV3Adapter_withdraw_success() public {
        deal(address(baseUsdc), address(baseAaveV3Adapter), DEPOSIT_AMOUNT);

        _changePrank(address(baseParentPeer));
        baseAaveV3Adapter.deposit(address(baseUsdc), DEPOSIT_AMOUNT);

        uint256 yieldPeerBalanceBefore = baseUsdc.balanceOf(address(baseParentPeer));

        _changePrank(address(baseParentPeer));
        baseAaveV3Adapter.withdraw(address(baseUsdc), baseAaveV3Adapter.getTotalValue(address(baseUsdc)));

        uint256 yieldPeerBalanceAfter = baseUsdc.balanceOf(address(baseParentPeer));
        assertApproxEqAbs(yieldPeerBalanceAfter, yieldPeerBalanceBefore + DEPOSIT_AMOUNT, BALANCE_TOLERANCE);
    }

    function test_yield_aaveV3Adapter_withdraw_maxSentinel_success() public {
        deal(address(baseUsdc), address(baseAaveV3Adapter), DEPOSIT_AMOUNT);

        _changePrank(address(baseParentPeer));
        baseAaveV3Adapter.deposit(address(baseUsdc), DEPOSIT_AMOUNT);

        uint256 totalValue = baseAaveV3Adapter.getTotalValue(address(baseUsdc));
        uint256 yieldPeerBalanceBefore = baseUsdc.balanceOf(address(baseParentPeer));

        _changePrank(address(baseParentPeer));
        baseAaveV3Adapter.withdraw(address(baseUsdc), type(uint256).max);

        uint256 yieldPeerBalanceAfter = baseUsdc.balanceOf(address(baseParentPeer));
        uint256 actualWithdrawn = yieldPeerBalanceAfter - yieldPeerBalanceBefore;

        assertApproxEqAbs(actualWithdrawn, totalValue, BALANCE_TOLERANCE);
        assertEq(
            baseAaveV3Adapter.getTotalValue(address(baseUsdc)),
            0,
            "Adapter should have zero balance after MAX withdrawal"
        );
    }

    function test_yield_aaveV3Adapter_getTotalValue_works() public {
        deal(address(baseUsdc), address(baseAaveV3Adapter), DEPOSIT_AMOUNT);

        _changePrank(address(baseParentPeer));
        baseAaveV3Adapter.deposit(address(baseUsdc), DEPOSIT_AMOUNT);

        uint256 totalValue = baseAaveV3Adapter.getTotalValue(address(baseUsdc));
        assertApproxEqAbs(totalValue, DEPOSIT_AMOUNT, BALANCE_TOLERANCE);
    }

    function test_yield_aaveV3Adapter_withdraw_allowsInterestAccrual() public {
        deal(address(baseUsdc), address(baseAaveV3Adapter), DEPOSIT_AMOUNT);

        _changePrank(address(baseParentPeer));
        baseAaveV3Adapter.deposit(address(baseUsdc), DEPOSIT_AMOUNT);

        // Warp time to accrue interest
        vm.warp(block.timestamp + 365 days);

        uint256 yieldPeerBalanceBefore = baseUsdc.balanceOf(address(baseParentPeer));

        _changePrank(address(baseParentPeer));
        baseAaveV3Adapter.withdraw(address(baseUsdc), DEPOSIT_AMOUNT / 2); // Withdraw less than total

        uint256 yieldPeerBalanceAfter = baseUsdc.balanceOf(address(baseParentPeer));
        uint256 actualWithdrawn = yieldPeerBalanceAfter - yieldPeerBalanceBefore;

        // Should withdraw the requested amount even with interest accrued
        assertApproxEqAbs(actualWithdrawn, DEPOSIT_AMOUNT / 2, BALANCE_TOLERANCE);
    }

    function test_yield_aaveV3Adapter_withdraw_revertsWhen_incorrectWithdrawAmount() public {
        IncorrectWithdrawAmountPool incorrectWithdrawAmountPool = new IncorrectWithdrawAmountPool();
        vm.etch(address(baseAaveV3Adapter.getStrategyPool()), address(incorrectWithdrawAmountPool).code);

        _changePrank(address(baseParentPeer));
        vm.expectRevert(abi.encodeWithSignature("AaveV3Adapter__IncorrectWithdrawAmount()"));
        baseAaveV3Adapter.withdraw(address(baseUsdc), DEPOSIT_AMOUNT);
    }
}

contract IncorrectWithdrawAmountPool {
    function withdraw(address, uint256 amount, address) external pure returns (uint256) {
        return amount - 1;
    }
}
