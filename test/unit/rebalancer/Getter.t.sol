// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, IYieldPeer} from "../../BaseTest.t.sol";

contract GetterTest is BaseTest {
    function test_yield_rebalancer_getParentPeer_returnsParentPeer() public view {
        address returnedParentPeer = baseRebalancer.getParentPeer();
        assertEq(returnedParentPeer, address(baseParentPeer));
    }

    function test_yield_rebalancer_getStrategyRegistry_returnsStrategyRegistry() public view {
        address returnedStrategyRegistry = baseRebalancer.getStrategyRegistry();
        assertEq(returnedStrategyRegistry, address(baseStrategyRegistry));
    }

    function test_yield_rebalancer_getCurrentStrategy_returnsStrategy() public view {
        IYieldPeer.Strategy memory returnedStrategy = baseRebalancer.getCurrentStrategy();
        IYieldPeer.Strategy memory expectedStrategy = baseParentPeer.getStrategy();

        assertEq(returnedStrategy.chainSelector, expectedStrategy.chainSelector);
        assertEq(returnedStrategy.protocolId, expectedStrategy.protocolId);
    }
}
