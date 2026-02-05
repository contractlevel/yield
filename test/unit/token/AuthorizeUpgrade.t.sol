// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Share} from "../../BaseTest.t.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract AuthorizeUpgradeTest is BaseTest {
    ShareV2Mock newImplementation;

    function setUp() public override {
        super.setUp();
        _selectFork(baseFork);
        // Deploy the new implementation logic
        newImplementation = new ShareV2Mock();
    }

    function test_yield_share_authorizeUpgrade_success() public {
        // Arrange
        address proxy = address(baseShare);

        // Sanity check: verify V2 function doesn't exist yet
        vm.expectRevert();
        ShareV2Mock(proxy).isV2();

        // Act
        vm.prank(baseShare.owner());
        // Call the standard UUPS upgrade function
        UUPSUpgradeable(proxy).upgradeToAndCall(address(newImplementation), "");

        // Assert
        // Verify logic has switched by calling the new function
        bool isV2 = ShareV2Mock(proxy).isV2();
        assertTrue(isV2);
    }

    function test_yield_share_authorizeUpgrade_revertsWhen_noUpgraderRole() public {
        // Arrange
        address attacker = makeAddr("attacker");
        address proxy = address(baseShare);
        bytes32 upgraderRole = baseShare.UPGRADER_ROLE();

        // Act & Assert
        vm.startPrank(attacker);

        // We expect the AccessControl error with arguments: (attacker, upgraderRole)
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, attacker, upgraderRole)
        );

        // Attempt upgrade
        UUPSUpgradeable(proxy).upgradeToAndCall(address(newImplementation), "");
        vm.stopPrank();
    }
}

/// @dev Mock implementation V2 to verify upgrade success
contract ShareV2Mock is Share {
    function isV2() external pure returns (bool) {
        return true;
    }
}
