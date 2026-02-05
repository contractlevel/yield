// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Rebalancer} from "../../BaseTest.t.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AuthorizeUpgradeTest is BaseTest {
    RebalancerV2Mock newImplementation;

    function setUp() public override {
        super.setUp();

        // select fork where Rebalancer is deployed
        _selectFork(baseFork);
        newImplementation = new RebalancerV2Mock();
    }

    function test_yield_rebalancer_authorizeUpgrade_success() public {
        // Arrange
        address proxy = address(baseRebalancer); /// @dev Get the Rebalancer proxy address

        /// @dev Sanity check: Verify that the new function does not exist before upgrade
        vm.expectRevert();
        RebalancerV2Mock(proxy).isV2();

        // Act
        vm.prank(baseRebalancer.owner());
        /// @dev Cast proxy to UUPS interface and call upgrade
        UUPSUpgradeable(proxy).upgradeToAndCall(address(newImplementation), "");

        // Assert
        // 1. Cast the proxy address to the V2 interface
        // 2. Call the new function to verify logic has switched
        bool isV2 = RebalancerV2Mock(proxy).isV2();
        assertTrue(isV2);
    }

    function test_yield_rebalancer_upgrade_revertsWhen_notOwner() public {
        // Arrange
        address proxy = address(baseRebalancer);
        address unauthorizedUser = makeAddr("unauthorized");

        // Act & Assert
        vm.startPrank(unauthorizedUser);

        // Expect OwnableUnauthorizedAccount(account)
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, unauthorizedUser));

        UUPSUpgradeable(proxy).upgradeToAndCall(address(newImplementation), "");
        vm.stopPrank();
    }
}

/// @dev Mock "V2" Rebalancer implementation to verify upgrade success
contract RebalancerV2Mock is Rebalancer {
    /// @notice We verify the upgrade by adding a new function 'isV2'
    function isV2() external pure returns (bool) {
        return true;
    }
}
