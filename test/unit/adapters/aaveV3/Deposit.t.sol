// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../../BaseTest.t.sol";

contract DepositTest is BaseTest {
    function test_yield_aaveV3Adapter_deposit_revertsWhen_notYieldPeer() public {
        vm.expectRevert(abi.encodeWithSignature("StrategyAdapter__OnlyYieldPeer()"));
        baseAaveV3Adapter.deposit(address(baseUsdc), DEPOSIT_AMOUNT);
    }

    function test_yield_aaveV3Adapter_deposit_success() public {
        deal(address(baseUsdc), address(baseAaveV3Adapter), DEPOSIT_AMOUNT);
        _changePrank(address(baseParentPeer));
        baseAaveV3Adapter.deposit(address(baseUsdc), DEPOSIT_AMOUNT);
        assertApproxEqAbs(baseAaveV3Adapter.getTotalValue(address(baseUsdc)), DEPOSIT_AMOUNT, BALANCE_TOLERANCE);
    }
}
