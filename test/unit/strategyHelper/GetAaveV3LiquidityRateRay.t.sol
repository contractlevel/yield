// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";
import {console2} from "forge-std/Test.sol";

contract GetAaveV3APRTest is BaseTest {
    function test_strategyHelper_getAaveV3LiquidityRateRay_success() public view {
        bool usingVirtualBalance = true;
        uint256 liquidityAdded = 0;

        uint256 liquidityRateRay =
            baseStrategyHelper.getAaveV3LiquidityRateRay(zeroLiquidityAdded, address(baseUsdc), usingVirtualBalance);

        assertGt(liquidityRateRay, 0);
        console2.log("liquidityRateRay", liquidityRateRay);
    }
}
