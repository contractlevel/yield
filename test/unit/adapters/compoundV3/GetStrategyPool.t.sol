// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../../BaseTest.t.sol";

contract GetStrategyPoolTest is BaseTest {
    function test_yield_compoundV3Adapter_getStrategyPool_success() public view {
        assertEq(baseCompoundV3Adapter.getStrategyPool(), baseNetworkConfig.protocols.comet);
    }
}
