// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, console2, IYieldPeer, Log} from "../../BaseTest.t.sol";

contract ConstructorTest is BaseTest {
    function test_yield_rebalancer_constructor() public view {
        assertEq(baseRebalancer.getFunctionsRouter(), baseNetworkConfig.clf.functionsRouter);
        assertEq(baseRebalancer.getDonId(), baseNetworkConfig.clf.donId);
        assertEq(baseRebalancer.getClfSubId(), clfSubId);
    }
}
