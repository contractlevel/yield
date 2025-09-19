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
