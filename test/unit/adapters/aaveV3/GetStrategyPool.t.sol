// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../../BaseTest.t.sol";
import {IPoolAddressesProvider} from "@aave/v3-origin/src/contracts/interfaces/IPoolAddressesProvider.sol";

contract GetStrategyPoolTest is BaseTest {
    function test_yield_aaveV3Adapter_getStrategyPool_success() public view {
        address aavePoolAddressesProvider = baseNetworkConfig.protocols.aavePoolAddressesProvider;
        address aavePool = IPoolAddressesProvider(aavePoolAddressesProvider).getPool();
        assertEq(baseAaveV3Adapter.getStrategyPool(), aavePool);
    }
}
