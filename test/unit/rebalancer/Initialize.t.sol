// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Rebalancer} from "../../BaseTest.t.sol";

contract InitializationTest is BaseTest {
    // --- PROXY CHECK ---
    /// @dev we expect the proxy to revert when initialize is called again
    function test_yield_rebalancer_proxy_initialize_revertsWhen_calledAgain() public {
        // Arrange
        _selectFork(baseFork);

        // Act & Assert
        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        baseRebalancer.initialize();
    }

    // --- IMPLEMENTATION CHECK ---
    /// @dev we expect the implementation contract to revert when initialize is called directly
    function test_yield_rebalancer_implementation_initialize_revertsWhen_calledDirectly() public {
        // Arrange
        _selectFork(baseFork);
        Rebalancer impl = Rebalancer(baseRebalancerImplAddr);

        // Act & Assert
        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        impl.initialize();
    }
}
