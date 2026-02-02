// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../../BaseTest.t.sol";

contract WithdrawTest is BaseTest {
    function test_yield_compoundV3Adapter_withdraw_revertsWhen_notYieldPeer() public {
        vm.expectRevert(abi.encodeWithSignature("StrategyAdapter__OnlyYieldPeer()"));
        baseCompoundV3Adapter.withdraw(address(baseUsdc), DEPOSIT_AMOUNT);
    }

    function test_yield_compoundV3Adapter_withdraw_success() public {
        deal(address(baseUsdc), address(baseCompoundV3Adapter), DEPOSIT_AMOUNT);

        _changePrank(address(baseParentPeer));
        baseCompoundV3Adapter.deposit(address(baseUsdc), DEPOSIT_AMOUNT);

        uint256 yieldPeerBalanceBefore = baseUsdc.balanceOf(address(baseParentPeer));

        _changePrank(address(baseParentPeer));
        baseCompoundV3Adapter.withdraw(address(baseUsdc), baseCompoundV3Adapter.getTotalValue(address(baseUsdc)));

        uint256 yieldPeerBalanceAfter = baseUsdc.balanceOf(address(baseParentPeer));
        assertApproxEqAbs(yieldPeerBalanceAfter, yieldPeerBalanceBefore + DEPOSIT_AMOUNT, BALANCE_TOLERANCE);
    }

    function test_yield_compoundV3Adapter_getTotalValue_works() public {
        deal(address(baseUsdc), address(baseCompoundV3Adapter), DEPOSIT_AMOUNT);

        _changePrank(address(baseParentPeer));
        baseCompoundV3Adapter.deposit(address(baseUsdc), DEPOSIT_AMOUNT);

        uint256 totalValue = baseCompoundV3Adapter.getTotalValue(address(baseUsdc));
        assertApproxEqAbs(totalValue, DEPOSIT_AMOUNT, BALANCE_TOLERANCE);
    }

    function test_yield_compoundV3Adapter_withdraw_maxSentinel_success() public {
        deal(address(baseUsdc), address(baseCompoundV3Adapter), DEPOSIT_AMOUNT);

        _changePrank(address(baseParentPeer));
        baseCompoundV3Adapter.deposit(address(baseUsdc), DEPOSIT_AMOUNT);

        uint256 totalValue = baseCompoundV3Adapter.getTotalValue(address(baseUsdc));
        uint256 yieldPeerBalanceBefore = baseUsdc.balanceOf(address(baseParentPeer));

        _changePrank(address(baseParentPeer));
        baseCompoundV3Adapter.withdraw(address(baseUsdc), type(uint256).max);

        uint256 yieldPeerBalanceAfter = baseUsdc.balanceOf(address(baseParentPeer));
        uint256 actualWithdrawn = yieldPeerBalanceAfter - yieldPeerBalanceBefore;

        assertApproxEqAbs(actualWithdrawn, totalValue, BALANCE_TOLERANCE);
    }

    function test_yield_compoundV3Adapter_withdraw_revertsWhen_insufficientSupply() public {
        deal(address(baseUsdc), address(baseCompoundV3Adapter), DEPOSIT_AMOUNT);

        _changePrank(address(baseParentPeer));
        baseCompoundV3Adapter.deposit(address(baseUsdc), DEPOSIT_AMOUNT);

        uint256 supplyBalance = baseCompoundV3Adapter.getTotalValue(address(baseUsdc));
        uint256 requestAmount = supplyBalance + 1;

        _changePrank(address(baseParentPeer));
        vm.expectRevert(abi.encodeWithSignature("CompoundV3Adapter__InsufficientSupply()"));
        baseCompoundV3Adapter.withdraw(address(baseUsdc), requestAmount);
    }

    function test_yield_compoundV3Adapter_withdraw_revertsWhen_incorrectWithdrawAmount() public {
        deal(address(baseUsdc), address(baseCompoundV3Adapter), DEPOSIT_AMOUNT);
        _changePrank(address(baseParentPeer));
        baseCompoundV3Adapter.deposit(address(baseUsdc), DEPOSIT_AMOUNT);

        address comet = baseCompoundV3Adapter.getStrategyPool();
        IncorrectWithdrawAmountPool incorrectPool = new IncorrectWithdrawAmountPool();
        vm.etch(comet, address(incorrectPool).code);
        // Mock balanceOf(adapter) so _getTotalValue() passes; adapter then calls withdraw which returns no USDC -> actualWithdrawn < amount
        vm.store(comet, bytes32(0), bytes32(DEPOSIT_AMOUNT));

        _changePrank(address(baseParentPeer));
        vm.expectRevert(abi.encodeWithSignature("CompoundV3Adapter__InsufficientSupply()"));
        baseCompoundV3Adapter.withdraw(address(baseUsdc), DEPOSIT_AMOUNT);
    }

    function test_yield_compoundV3Adapter_maxSentinelWithdraw_revertsWhen_incorrectWithdrawAmount() public {
        deal(address(baseUsdc), address(baseCompoundV3Adapter), DEPOSIT_AMOUNT);
        _changePrank(address(baseParentPeer));
        baseCompoundV3Adapter.deposit(address(baseUsdc), DEPOSIT_AMOUNT);

        address comet = baseCompoundV3Adapter.getStrategyPool();
        IncorrectWithdrawAmountPool incorrectPool = new IncorrectWithdrawAmountPool();
        vm.etch(comet, address(incorrectPool).code);
        // Mock balanceOf(adapter) so _getTotalValue() passes; adapter then calls withdraw which returns no USDC -> actualWithdrawn < amount
        vm.store(comet, bytes32(0), bytes32(DEPOSIT_AMOUNT));

        _changePrank(address(baseParentPeer));
        vm.expectRevert(abi.encodeWithSignature("CompoundV3Adapter__InsufficientSupply()"));
        baseCompoundV3Adapter.withdraw(address(baseUsdc), type(uint256).max);
    }
}

/// @notice Mock Comet that reports balance via balanceOf but does not transfer USDC on withdraw,
///         so adapter sees actualWithdrawn < amount and reverts CompoundV3Adapter__InsufficientSupply().
contract IncorrectWithdrawAmountPool {
    uint256 internal balance; // slot 0: value returned by balanceOf

    function balanceOf(address) external view returns (uint256) {
        return balance;
    }

    function withdraw(address, uint256 amount) external {
        // Intentionally do not transfer USDC to msg.sender; adapter's balanceAfter - balanceBefore = 0 < amount
    }
}
