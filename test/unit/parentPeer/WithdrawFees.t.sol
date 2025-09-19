// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, console2, IYieldPeer, Log} from "../../BaseTest.t.sol";
import {Share} from "../../../src/token/Share.sol";
import {
    ERC20,
    IERC20
} from "@chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/ERC20.sol";

contract WithdrawFeesTest is BaseTest {
    function setUp() public override {
        super.setUp();
        _selectFork(baseFork);
        deal(address(baseUsdc), depositor, DEPOSIT_AMOUNT);

        _setFeeRate(INITIAL_FEE_RATE);
    }

    function test_yield_parent_withdrawFees_revertsWhen_notOwner() public {
        _changePrank(holder);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", holder));
        baseParentPeer.withdrawFees();
    }

    function test_yield_parent_withdrawFees_success() public {
        _changePrank(depositor);
        baseUsdc.approve(address(baseParentPeer), DEPOSIT_AMOUNT);
        baseParentPeer.deposit(DEPOSIT_AMOUNT);

        uint256 expectedShareMintAmount = DEPOSIT_AMOUNT * INITIAL_SHARE_PRECISION;

        _changePrank(baseParentPeer.owner());
        baseParentPeer.withdrawFees();

        assertEq(
            baseShare.balanceOf(baseParentPeer.owner()), _getFeeShareMintAmount(expectedShareMintAmount, DEPOSIT_AMOUNT)
        );
    }

    function test_yield_parent_withdrawFees_revertsWhen_noFeesToWithdraw() public {
        _changePrank(baseParentPeer.owner());
        vm.expectRevert(abi.encodeWithSignature("ParentPeer__NoFeesToWithdraw()"));
        baseParentPeer.withdrawFees();
    }
}
