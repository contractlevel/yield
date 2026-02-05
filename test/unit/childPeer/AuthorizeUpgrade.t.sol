// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, ChildPeer} from "../../BaseTest.t.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Roles} from "../../../src/libraries/Roles.sol";

contract AuthorizeUpgradeTest is BaseTest {
    ChildPeerV2Mock newImplementation;
    address upgrader = makeAddr("upgrader");

    function setUp() public override {
        super.setUp();

        // select fork where ChildPeer is deployed
        _selectFork(optFork);
        newImplementation = new ChildPeerV2Mock(
            optNetworkConfig.ccip.ccipRouter,
            optNetworkConfig.tokens.link,
            optChainSelector,
            address(optUsdc),
            address(optShare),
            baseChainSelector
        );

        vm.prank(optChildPeer.owner());
        optChildPeer.grantRole(Roles.UPGRADER_ROLE, upgrader);
    }

    function test_yield_child_authorizeUpgrade_success() public {
        // Arrange
        address proxy = address(optChildPeer);

        // Sanity check: verify V2 function doesn't exist yet
        vm.expectRevert();
        ChildPeerV2Mock(proxy).isV2();

        // Act
        vm.prank(upgrader);
        // Call the standard UUPS upgrade function
        UUPSUpgradeable(proxy).upgradeToAndCall(address(newImplementation), "");

        // Assert
        // Verify logic has switched by calling the new function
        bool isV2 = ChildPeerV2Mock(proxy).isV2();
        assertTrue(isV2);
    }

    function test_yield_child_authorizeUpgrade_revertsWhen_missingRole() public {
        // Arrange
        address proxy = address(optChildPeer);
        address unauthorizedUser = makeAddr("unauthorized");

        // Act & Assert
        vm.startPrank(unauthorizedUser);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, unauthorizedUser, Roles.UPGRADER_ROLE
            )
        );

        UUPSUpgradeable(proxy).upgradeToAndCall(address(newImplementation), "");
        vm.stopPrank();
    }
}

/// @dev Mock implementation V2 to verify upgrade success
contract ChildPeerV2Mock is ChildPeer {
    constructor(
        address ccipRouter,
        address link,
        uint64 thisChainSelector,
        address usdc,
        address share,
        uint64 parentChainSelector
    ) ChildPeer(ccipRouter, link, thisChainSelector, usdc, share, parentChainSelector) {}

    function isV2() external pure returns (bool) {
        return true;
    }
}
