// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, StrategyRegistry} from "../../BaseTest.t.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract AuthorizeUpgradeTest is BaseTest {
    StrategyRegistryV2Mock newImplementation;

    function setUp() public override {
        super.setUp();
        _selectFork(baseFork);
        // Deploy the new implementation logic
        newImplementation = new StrategyRegistryV2Mock();
    }

    function test_yield_strategyRegistry_authorizeUpgrade_success() public {
        // Arrange
        address proxy = address(baseStrategyRegistry);

        // Sanity check: verify V2 function doesn't exist yet
        vm.expectRevert();
        StrategyRegistryV2Mock(proxy).isV2();

        // Act
        vm.prank(baseStrategyRegistry.owner());
        // Call the standard UUPS upgrade function
        UUPSUpgradeable(proxy).upgradeToAndCall(address(newImplementation), "");

        // Assert
        // Verify logic has switched by calling the new function
        bool isV2 = StrategyRegistryV2Mock(proxy).isV2();
        assertTrue(isV2);
    }

    function test_yield_strategyRegistry_authorizeUpgrade_revertsWhen_notOwner() public {
        // Arrange
        address proxy = address(baseStrategyRegistry);

        // Act & Assert
        vm.prank(depositor); // Prank a non-owner address
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", depositor));
        UUPSUpgradeable(proxy).upgradeToAndCall(address(newImplementation), "");
    }
}

/// @dev Mock implementation V2 to verify upgrade success
contract StrategyRegistryV2Mock is StrategyRegistry {
    function isV2() external pure returns (bool) {
        return true;
    }
}
