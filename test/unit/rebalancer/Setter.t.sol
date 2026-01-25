// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm} from "../../BaseTest.t.sol";

contract SetterTest is BaseTest {
    // New addresses for testing
    address newParentPeer = makeAddr("newParentPeer");
    address newStrategyRegistry = makeAddr("newStrategyRegistry");

    /*//////////////////////////////////////////////////////////////
                                SET PARENT
    //////////////////////////////////////////////////////////////*/
    function test_yield_rebalancer_setParentPeer_updatesStorage() public {
        // Arrange & Act
        vm.prank(baseRebalancer.owner());
        baseRebalancer.setParentPeer(newParentPeer);

        // Assert
        address returnedParentPeer = baseRebalancer.getParentPeer();
        assertEq(returnedParentPeer, newParentPeer);
    }

    function test_yield_rebalancer_setParentPeer_emitsEvent() public {
        // Arrange & Act
        vm.prank(baseRebalancer.owner());
        vm.recordLogs();
        baseRebalancer.setParentPeer(newParentPeer);

        // Handle log for ParentPeerSet event
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool parentPeerSetEventFound = false;
        address emittedParentPeer;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256("ParentPeerSet(address)")) {
                emittedParentPeer = address(uint160(uint256(logs[i].topics[1])));
                parentPeerSetEventFound = true;
                break;
            }
        }

        // Assert
        assertTrue(parentPeerSetEventFound);
        assertEq(emittedParentPeer, newParentPeer);
    }

    function test_yield_rebalancer_setParentPeer_revertsWhen_notOwner() public {
        // Arrange
        vm.prank(depositor);

        // Act & Assert
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", depositor));
        baseRebalancer.setParentPeer(newParentPeer);
    }

    function test_yield_rebalancer_setParentPeer_revertsWhen_zeroAddress() public {
        // Arrange
        address zeroAddress = address(0);

        // Act & Assert
        vm.prank(baseRebalancer.owner());
        vm.expectRevert(abi.encodeWithSignature("Rebalancer__NotZeroAddress()"));
        baseRebalancer.setParentPeer(zeroAddress);
    }
}
