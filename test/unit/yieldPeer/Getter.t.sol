// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";

contract GetterTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_yield_yieldPeer_getStrategyAdapter_success() public view {
        address strategyAdapter = baseParentPeer.getStrategyAdapter(keccak256(abi.encodePacked("aave-v3")));
        assertEq(strategyAdapter, address(baseAaveV3Adapter));
    }
}
