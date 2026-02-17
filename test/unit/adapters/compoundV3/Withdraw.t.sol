// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../../BaseTest.t.sol";

contract WithdrawTest is BaseTest {
    function test_yield_compoundV3Adapter_withdraw_revertsWhen_notYieldPeer() public {
        vm.expectRevert(abi.encodeWithSignature("StrategyAdapter__OnlyYieldPeer()"));
        baseCompoundV3Adapter.withdraw(address(baseUsdc), DEPOSIT_AMOUNT);
    }

    function test_yield_compoundV3Adapter_withdraw_userWithdraw_success() public {
        deal(address(baseUsdc), address(baseCompoundV3Adapter), DEPOSIT_AMOUNT);

        _changePrank(address(baseParentPeer));
        baseCompoundV3Adapter.deposit(address(baseUsdc), DEPOSIT_AMOUNT);

        uint256 yieldPeerBalanceBefore = baseUsdc.balanceOf(address(baseParentPeer));

        _changePrank(address(baseParentPeer));
        uint256 returnedWithdrawnAmount =
            baseCompoundV3Adapter.withdraw(address(baseUsdc), baseCompoundV3Adapter.getTotalValue(address(baseUsdc)));

        uint256 yieldPeerBalanceAfter = baseUsdc.balanceOf(address(baseParentPeer));
        assertApproxEqAbs(yieldPeerBalanceAfter, yieldPeerBalanceBefore + DEPOSIT_AMOUNT, BALANCE_TOLERANCE);
        assertApproxEqAbs(returnedWithdrawnAmount, DEPOSIT_AMOUNT, BALANCE_TOLERANCE);
    }

    function test_yield_compoundV3Adapter_withdraw_rebalanceWithdraw_success() public {
        deal(address(baseUsdc), address(baseCompoundV3Adapter), DEPOSIT_AMOUNT);

        _changePrank(address(baseParentPeer));
        baseCompoundV3Adapter.deposit(address(baseUsdc), DEPOSIT_AMOUNT);

        uint256 totalValue = baseCompoundV3Adapter.getTotalValue(address(baseUsdc));
        uint256 yieldPeerBalanceBefore = baseUsdc.balanceOf(address(baseParentPeer));

        _changePrank(address(baseParentPeer));
        uint256 returnedWithdrawnAmount = baseCompoundV3Adapter.withdraw(address(baseUsdc), type(uint256).max);

        uint256 yieldPeerBalanceAfter = baseUsdc.balanceOf(address(baseParentPeer));
        uint256 actualWithdrawn = yieldPeerBalanceAfter - yieldPeerBalanceBefore;

        assertApproxEqAbs(actualWithdrawn, totalValue, BALANCE_TOLERANCE);
        assertEq(
            baseCompoundV3Adapter.getTotalValue(address(baseUsdc)),
            0,
            "Adapter should have zero balance after MAX withdrawal"
        );
        assertEq(returnedWithdrawnAmount, actualWithdrawn);
    }

    function test_yield_compoundV3Adapter_getTotalValue_success() public {
        deal(address(baseUsdc), address(baseCompoundV3Adapter), DEPOSIT_AMOUNT);

        _changePrank(address(baseParentPeer));
        baseCompoundV3Adapter.deposit(address(baseUsdc), DEPOSIT_AMOUNT);

        uint256 totalValue = baseCompoundV3Adapter.getTotalValue(address(baseUsdc));
        assertApproxEqAbs(totalValue, DEPOSIT_AMOUNT, BALANCE_TOLERANCE);
    }

    function test_yield_compoundV3Adapter_withdraw_userWithdraw_revertsWhen_withdrawAmountExceedsTotalValue() public {
        deal(address(baseUsdc), address(baseCompoundV3Adapter), DEPOSIT_AMOUNT);

        _changePrank(address(baseParentPeer));
        baseCompoundV3Adapter.deposit(address(baseUsdc), DEPOSIT_AMOUNT);

        uint256 totalValue = baseCompoundV3Adapter.getTotalValue(address(baseUsdc));
        uint256 withdrawAmount = totalValue + 1;

        _changePrank(address(baseParentPeer));
        vm.expectRevert(abi.encodeWithSignature("CompoundV3Adapter__WithdrawAmountExceedsTotalValue()"));
        baseCompoundV3Adapter.withdraw(address(baseUsdc), withdrawAmount);
    }

    function test_yield_compoundV3Adapter_withdraw_userWithdraw_revertsWhen_incorrectWithdrawAmount() public {
        deal(address(baseUsdc), address(baseCompoundV3Adapter), DEPOSIT_AMOUNT);

        _changePrank(address(baseParentPeer));
        baseCompoundV3Adapter.deposit(address(baseUsdc), DEPOSIT_AMOUNT);

        address comet = baseCompoundV3Adapter.getStrategyPool();
        IncorrectWithdrawAmountPool incorrectPool = new IncorrectWithdrawAmountPool();
        vm.etch(comet, address(incorrectPool).code);
        // Mock balanceOf(adapter) so _getTotalValue() passes; adapter then calls withdraw which returns no USDC -> actualWithdrawn < amount
        vm.store(comet, bytes32(0), bytes32(DEPOSIT_AMOUNT));

        _changePrank(address(baseParentPeer));
        vm.expectRevert(abi.encodeWithSignature("CompoundV3Adapter__IncorrectWithdrawAmount()"));
        baseCompoundV3Adapter.withdraw(address(baseUsdc), DEPOSIT_AMOUNT);
    }

    function test_yield_compoundV3Adapter_withdraw_rebalanceWithdraw_revertsWhen_incorrectWithdrawAmount() public {
        deal(address(baseUsdc), address(baseCompoundV3Adapter), DEPOSIT_AMOUNT);
        _changePrank(address(baseParentPeer));
        baseCompoundV3Adapter.deposit(address(baseUsdc), DEPOSIT_AMOUNT);

        address comet = baseCompoundV3Adapter.getStrategyPool();
        IncorrectWithdrawAmountPool incorrectPool = new IncorrectWithdrawAmountPool();
        vm.etch(comet, address(incorrectPool).code);
        // Mock balanceOf(adapter) so _getTotalValue() passes; adapter then calls withdraw which returns no USDC -> actualWithdrawn < amount
        vm.store(comet, bytes32(0), bytes32(DEPOSIT_AMOUNT));

        _changePrank(address(baseParentPeer));
        vm.expectRevert(abi.encodeWithSignature("CompoundV3Adapter__IncorrectWithdrawAmount()"));
        baseCompoundV3Adapter.withdraw(address(baseUsdc), type(uint256).max);
    }
}

/// @notice Mock Comet that reports balance via balanceOf but does not transfer USDC on withdraw,
///         so adapter sees actualWithdrawn < amount and reverts CompoundV3Adapter__IncorrectWithdrawAmount().
contract IncorrectWithdrawAmountPool {
    uint256 internal balance; // slot 0: value returned by balanceOf

    function balanceOf(address) external view returns (uint256) {
        return balance;
    }

    function withdraw(address, uint256 amount) external {
        // Intentionally do not transfer USDC to msg.sender; adapter's balanceAfter - balanceBefore = 0 < amount
    }
}
