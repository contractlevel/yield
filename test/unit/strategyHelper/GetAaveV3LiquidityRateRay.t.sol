// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";
import {console2} from "forge-std/Test.sol";
import {IPool} from "@aave/v3-origin/src/contracts/interfaces/IPool.sol";
import {DataTypes} from "@aave/v3-origin/src/contracts/protocol/libraries/types/DataTypes.sol";
import {IPoolAddressesProvider} from "@aave/v3-origin/src/contracts/interfaces/IPoolAddressesProvider.sol";

contract GetAaveV3LiquidityRateRayTest is BaseTest {
    function test_yield_strategyHelper_getAaveV3LiquidityRateRay_success() public view {
        bool usingVirtualBalance = true;
        uint256 liquidityAdded = 0;

        uint256 liquidityRateRay =
            baseStrategyHelper.getAaveV3LiquidityRateRay(liquidityAdded, address(baseUsdc), usingVirtualBalance);

        assertGt(liquidityRateRay, 0);
        console2.log("liquidityRateRay", liquidityRateRay);
    }

    function test_yield_strategyHelper_getAaveV3LiquidityRateRay_consistency() public view {
        bool usingVirtualBalance = true;
        uint256 liquidityAdded = 0;

        uint256 liquidityRateRay =
            baseStrategyHelper.getAaveV3LiquidityRateRay(liquidityAdded, address(baseUsdc), usingVirtualBalance);

        address pool = IPoolAddressesProvider(baseNetworkConfig.protocols.aavePoolAddressesProvider).getPool();

        uint256 liquidityRateRayTwo = IPool(pool).getReserveData(address(baseUsdc)).currentLiquidityRate;

        // @review failing
        assertEq(liquidityRateRay, liquidityRateRayTwo); // 45621376242723826919368091 != 45621372050301973552261001
    }
}
