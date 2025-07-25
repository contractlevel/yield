// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../../BaseTest.t.sol";

contract DepositTest is BaseTest {
    function test_yield_compoundV3Adapter_deposit_revertsWhen_notYieldPeer() public {
        vm.expectRevert(abi.encodeWithSignature("StrategyAdapter__OnlyYieldPeer()"));
        baseCompoundV3Adapter.deposit(address(baseUsdc), DEPOSIT_AMOUNT);
    }

    function test_yield_compoundV3Adapter_deposit_success() public {
        deal(address(baseUsdc), address(baseCompoundV3Adapter), DEPOSIT_AMOUNT);
        _changePrank(address(baseParentPeer));
        baseCompoundV3Adapter.deposit(address(baseUsdc), DEPOSIT_AMOUNT);
        assertApproxEqAbs(baseCompoundV3Adapter.getTotalValue(address(baseUsdc)), DEPOSIT_AMOUNT, BALANCE_TOLERANCE);
    }
}
