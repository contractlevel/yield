// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, IYieldPeer} from "../../BaseTest.t.sol";

contract GetterTest is BaseTest {
    function setUp() public override {
        super.setUp();
        /// @dev select the fork where ParentPeer is deployed
        _selectFork(baseFork);
    }

    function test_yield_parent_getStrategy_returnsStrategy() public view {
        // Arrange
        bytes32 expectedProtocolId = keccak256(abi.encodePacked("aave-v3"));

        // Act
        IYieldPeer.Strategy memory strategy = baseParentPeer.getStrategy();

        // Assert
        assertEq(strategy.chainSelector, baseChainSelector);
        assertEq(strategy.protocolId, expectedProtocolId);
    }

    function test_yield_parent_getTotalShares_returnsTotalShares() public {
        // Arrange
        deal(address(baseUsdc), depositor, DEPOSIT_AMOUNT);

        // Calculate expected shares by subtracting the fee
        uint256 fee = _getFee(DEPOSIT_AMOUNT);
        uint256 principal = DEPOSIT_AMOUNT - fee;
        uint256 expectedShares = principal * INITIAL_SHARE_PRECISION;

        // Act
        vm.startPrank(depositor);
        baseUsdc.approve(address(baseParentPeer), DEPOSIT_AMOUNT);
        baseParentPeer.deposit(DEPOSIT_AMOUNT);
        vm.stopPrank();
        uint256 totalShares = baseParentPeer.getTotalShares();

        // Assert
        assertEq(totalShares, expectedShares);
    }

    function test_yield_parent_getRebalancer_returnsRebalancer() public view {
        // Arrange & Act
        address rebalancer = baseParentPeer.getRebalancer();

        // Assert
        assertEq(rebalancer, address(baseRebalancer));
    }

    function test_yield_parent_getVersion_returnsVersion() public view {
        // Arrange & Act
        string memory version = baseParentPeer.getVersion();

        // Assert
        assertEq(version, "1.0.0");
    }
}
