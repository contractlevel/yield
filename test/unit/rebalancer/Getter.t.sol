// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, IYieldPeer} from "../../BaseTest.t.sol";

contract GetterTest is BaseTest {
    function test_yield_rebalancer_getParentPeer_returnsParentPeer() public view {
        // Arrange & Act
        address returnedParentPeer = baseRebalancer.getParentPeer();

        // Assert
        assertEq(returnedParentPeer, address(baseParentPeer));
    }

    function test_yield_rebalancer_getCurrentStrategy_returnsStrategy() public view {
        // Arrange & Act
        IYieldPeer.Strategy memory returnedStrategy = baseRebalancer.getCurrentStrategy();
        IYieldPeer.Strategy memory expectedStrategy = baseParentPeer.getStrategy();

        // Assert
        assertEq(returnedStrategy.chainSelector, expectedStrategy.chainSelector);
        assertEq(returnedStrategy.protocolId, expectedStrategy.protocolId);
    }
}
