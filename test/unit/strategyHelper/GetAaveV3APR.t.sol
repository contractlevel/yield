// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";

contract GetAaveV3APRTest is BaseTest {
    function test_strategyHelper_getAaveV3APR_success() public view {
        // @review
        uint256 apr = baseStrategyHelper.getAaveV3APR(0, address(baseUsdc), true);
        assertGt(apr, 0);
    }
}
