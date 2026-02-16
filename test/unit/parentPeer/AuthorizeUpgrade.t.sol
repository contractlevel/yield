// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, ParentPeer, Vm} from "../../BaseTest.t.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Roles} from "../../../src/libraries/Roles.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

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
        /// @dev Sanity check: verify V2 function doesn't exist yet
        vm.expectRevert();
        ParentPeerV2Mock(proxy).isV2();

        // Act
        vm.prank(upgrader);
        vm.recordLogs();
        /// @dev Call the standard UUPS upgrade function
        UUPSUpgradeable(proxy).upgradeToAndCall(address(newImplementation), "");
        /// @dev Call reinitializer modifier function
        ParentPeerV2Mock(proxy).initializeNew();
        Vm.Log[] memory logs = vm.getRecordedLogs();

        /// @dev Sanity check: verify reinitialize function can't be called again
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        ParentPeerV2Mock(proxy).initializeNew();
        vm.stopPrank();

        /// @dev Handles logs
        bytes32 upgradeEventSig = keccak256("Upgraded(address)");
        bytes32 initializeEventSig = keccak256("Initialized(uint64)");
        bool upgradeLogFound;
        bool initializeLogFound;
        address emittedImplAddress;
        uint64 emittedVersion;

        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == upgradeEventSig) {
                upgradeLogFound = true;
                // Parse indexed address from topics[1]
                emittedImplAddress = address(uint160(uint256(logs[i].topics[1])));
            }
            if (logs[i].topics[0] == initializeEventSig) {
                initializeLogFound = true;
                // Parse uint64 from data (properly with abi.decode)
                (emittedVersion) = abi.decode(logs[i].data, (uint64));
            }
        }

        // Assert
        /// @dev Verify logic has switched by calling the new function
        bool isV2 = ParentPeerV2Mock(proxy).isV2();
        assertTrue(isV2);
        /// @dev Verify logs found and emitted values correct
        assertTrue(upgradeLogFound);
        assertTrue(initializeLogFound);
        assertEq(emittedImplAddress, address(newImplementation));
        assertEq(emittedVersion, ParentPeerV2Mock(proxy).VERSION_2());
    }

    function test_yield_parent_authorizeUpgrade_revertsWhen_missingRole() public {
        // Arrange
        address proxy = address(baseParentPeer);
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
contract ParentPeerV2Mock is ParentPeer {
    constructor(address ccipRouter, address link, uint64 thisChainSelector, address usdc, address share)
        ParentPeer(ccipRouter, link, thisChainSelector, usdc, share)
    {
        _disableInitializers();
    }

    uint64 public constant VERSION_2 = 2;

    function initializeNew() external reinitializer(VERSION_2) {}

    function isV2() external pure returns (bool) {
        return true;
    }
}
