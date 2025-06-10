// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MockUsdc} from "../../mocks/MockUsdc.sol";

contract MockUsdcTest is Test {
    MockUsdc public mockUsdc;

    function setUp() public {
        mockUsdc = new MockUsdc();
    }

    function test_mockUsdc_constructor() public view {
        assertEq(mockUsdc.name(), "MockUsdc");
        assertEq(mockUsdc.symbol(), "USDC");
        assertEq(mockUsdc.decimals(), 6);
    }
}
