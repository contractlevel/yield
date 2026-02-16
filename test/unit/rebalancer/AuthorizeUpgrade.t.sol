// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Rebalancer, Vm} from "../../BaseTest.t.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
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
        address proxy = address(baseRebalancer);
        /// @dev Sanity check: Verify that the new function does not exist before upgrade
        vm.expectRevert();
        RebalancerV2Mock(proxy).isV2();

        // Act
        vm.prank(baseRebalancer.owner());
        vm.recordLogs();
        /// @dev Cast proxy to UUPS interface and call upgrade
        UUPSUpgradeable(proxy).upgradeToAndCall(address(newImplementation), "");
        /// @dev Call reinitializer modifier function
        RebalancerV2Mock(proxy).initializeNew();
        Vm.Log[] memory logs = vm.getRecordedLogs();

        /// @dev Sanity check: verify reinitialize function can't be called again
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        RebalancerV2Mock(proxy).initializeNew();
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
        bool isV2 = RebalancerV2Mock(proxy).isV2();
        assertTrue(isV2);
        /// @dev Verify logs found and emitted values correct
        assertTrue(upgradeLogFound);
        assertTrue(initializeLogFound);
        assertEq(emittedImplAddress, address(newImplementation));
        assertEq(emittedVersion, RebalancerV2Mock(proxy).VERSION_2());
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
    constructor() {
        _disableInitializers();
    }

    uint64 public constant VERSION_2 = 2;

    function initializeNew() external reinitializer(VERSION_2) {}

    /// @notice We verify the upgrade by adding a new function 'isV2'
    function isV2() external pure returns (bool) {
        return true;
    }
}
