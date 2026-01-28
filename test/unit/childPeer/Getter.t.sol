// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";

contract GetterTest is BaseTest {
    function setUp() public override {
        super.setUp();
        /// @dev Select the Optimism fork where ChildPeer is deployed
        _selectFork(optFork);
    }

    function test_yield_child_getParentChainSelector_returnsSelector() public view {
        // Arrange & Act
        uint64 selector = optChildPeer.getParentChainSelector();

        // Assert
        assertEq(selector, baseChainSelector);
    }

    function test_yield_child_getVersion_returnsVersion() public view {
        // Arrange & Act
        string memory version = optChildPeer.getVersion();

        // Assert
        assertEq(version, "1.0.0");
    }
}
