// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, ParentPeer} from "../../BaseTest.t.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Roles} from "../../../src/libraries/Roles.sol";

contract AuthorizeUpgradeTest is BaseTest {
    ParentPeerV2Mock newImplementation;
    address upgrader = makeAddr("upgrader");

    function setUp() public override {
        super.setUp();

        // select fork where ParentPeer is deployed
        _selectFork(baseFork);
        newImplementation = new ParentPeerV2Mock(
            baseNetworkConfig.ccip.ccipRouter,
            baseNetworkConfig.tokens.link,
            baseChainSelector,
            address(baseUsdc),
            address(baseShare)
        );

        vm.prank(baseParentPeer.owner());
        baseParentPeer.grantRole(Roles.UPGRADER_ROLE, upgrader);
    }

    function test_yield_parent_authorizeUpgrade_success() public {
        // Arrange
        address proxy = address(baseParentPeer);

        // Sanity check: verify V2 function doesn't exist yet
        vm.expectRevert();
        ParentPeerV2Mock(proxy).isV2();

        // Act
        vm.prank(upgrader);
        // Call the standard UUPS upgrade function
        UUPSUpgradeable(proxy).upgradeToAndCall(address(newImplementation), "");

        // Assert
        // Verify logic has switched by calling the new function
        bool isV2 = ParentPeerV2Mock(proxy).isV2();
        assertTrue(isV2);
    }

    function test_yield_parent_authorizeUpgrade_revertsWhen_missingRole() public {
        // Arrange
        address proxy = address(baseParentPeer);
        address unauthorizedUser = makeAddr("unauthorized");

        // Act & Assert
        vm.prank(unauthorizedUser);

        // Expect AccessControlUnauthorizedAccount(account, role)
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("AccessControlUnauthorizedAccount(address,bytes32)")),
                unauthorizedUser,
                Roles.UPGRADER_ROLE
            )
        );

        UUPSUpgradeable(proxy).upgradeToAndCall(address(newImplementation), "");
    }
}

/// @dev Mock implementation V2 to verify upgrade success
contract ParentPeerV2Mock is ParentPeer {
    constructor(address ccipRouter, address link, uint64 thisChainSelector, address usdc, address share)
        ParentPeer(ccipRouter, link, thisChainSelector, usdc, share)
    {}

    function isV2() external pure returns (bool) {
        return true;
    }
}
