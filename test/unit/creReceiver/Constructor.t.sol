// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";

/// @dev CREReceiver inherited by Rebalancer
contract ConstructorTest is BaseTest {
    /// @notice 'owner' should be 'DEFAULT_SENDER' from forge-std TestBase
    /// @notice sanity check to make sure owner is set correctly
    function test_yield_creReceiver_constructor() public view {
        assertEq(baseRebalancer.owner(), DEFAULT_SENDER);
    }
}
