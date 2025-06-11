// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MockAavePool} from "../../mocks/MockAavePool.sol";
import {MockAToken} from "../../mocks/MockAToken.sol";
import {MockUsdc} from "../../mocks/MockUsdc.sol";

contract MockAavePoolTest is Test {
    MockAavePool public mockAavePool;
    MockAToken public mockAToken;
    MockUsdc public mockUsdc;

    function setUp() public {
        mockUsdc = new MockUsdc();
        mockAavePool = new MockAavePool(address(mockUsdc));
        mockAToken = new MockAToken(address(mockAavePool));
        mockAavePool.setATokenAddress(address(mockAToken));
    }

    function test_mockAavePool_setInterestRate_revertsWhen_interestRateTooHigh() public {
        vm.expectRevert();
        mockAavePool.setInterestRate(2001);
    }

    function test_mockAavePool_setInterestRate_updatesInterestRate() public {
        mockAavePool.setInterestRate(1000);
        assertEq(mockAavePool.getInterestRate(), 1000);
    }

    function test_mockAavePool_withdraw_revertsWhen_insufficientBalance() public {
        vm.expectRevert();
        mockAavePool.withdraw(address(mockUsdc), 100, address(this));
    }
}
