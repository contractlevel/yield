// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MockComet} from "../../mocks/MockComet.sol";

contract MockCometTest is Test {
    MockComet public mockComet;

    function setUp() public {
        mockComet = new MockComet();
    }

    function test_mockComet_withdraw_revertsWhen_insufficientBalance() public {
        vm.expectRevert();
        mockComet.withdraw(address(this), 100);
    }
}
