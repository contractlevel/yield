// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, StrategyRegistry} from "../../BaseTest.t.sol";

contract InitializationTest is BaseTest {
    // --- PROXY CHECK ---
    /// @dev we expect the proxy to revert when initialize is called again
    function test_yield_strategyRegistry_proxy_initialize_revertsWhen_calledAgain() public {
        // Arrange
        _selectFork(baseFork);

        // Act & Assert
        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        baseStrategyRegistry.initialize();
    }

    // --- IMPLEMENTATION CHECK ---
    /// @dev we expect the implementation contract to revert when initialize is called directly
    function test_yield_strategyRegistry_base_implementation_initialize_reverts() public {
        // Arrange
        _selectFork(baseFork);
        StrategyRegistry impl = StrategyRegistry(baseStrategyRegistryImplAddr);

        // Act & Assert
        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        impl.initialize();
    }
}
