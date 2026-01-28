// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";

contract GetterTest is BaseTest {
    function test_yield_strategyRegistry_getVersion_returnsVersion() public view {
        // Arrange & Act
        string memory version = baseStrategyRegistry.getVersion();

        // Assert
        assertEq(version, "1.0.0");
    }

    function test_yield_strategyRegistry_getStrategyAdapter_returnsAdapter() public {
        // Arrange
        // Setup a dummy adapter for testing read
        address expectedAdapter = address(baseAaveV3Adapter);
        bytes32 protocolId = keccak256(abi.encodePacked("aave-v3"));

        // We need to set it first to ensure we are reading something valid
        vm.prank(baseStrategyRegistry.owner());
        baseStrategyRegistry.setStrategyAdapter(protocolId, expectedAdapter);

        // Act
        address returnedAdapter = baseStrategyRegistry.getStrategyAdapter(protocolId);

        // Assert
        assertEq(returnedAdapter, expectedAdapter);
    }
}
