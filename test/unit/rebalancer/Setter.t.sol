// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm} from "../../BaseTest.t.sol";

contract SetterTest is BaseTest {
    address newParentPeer = makeAddr("newParentPeer");
    address newStrategyRegistry = makeAddr("newStrategyRegistry");

    /*//////////////////////////////////////////////////////////////
                                SET PARENT
    //////////////////////////////////////////////////////////////*/
    function test_yield_rebalancer_setParentPeer_updatesStorage() public {
        vm.prank(baseRebalancer.owner());
        baseRebalancer.setParentPeer(newParentPeer);
        address returnedParentPeer = baseRebalancer.getParentPeer();
        assertEq(returnedParentPeer, newParentPeer);
    }

    function test_yield_rebalancer_setParentPeer_emitsEvent() public {
        /// @dev Arrange / Act
        vm.prank(baseRebalancer.owner());
        vm.recordLogs();
        baseRebalancer.setParentPeer(newParentPeer);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bool parentPeerSetLogFound = false;
        address emittedParentPeer;
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("ParentPeerSet(address)")) {
                emittedParentPeer = address(uint160(uint256(entries[i].topics[1])));
                parentPeerSetLogFound = true;
                break;
            }
        }

        /// @dev Assert
        assertTrue(parentPeerSetLogFound);
        assertEq(emittedParentPeer, newParentPeer);
    }

    function test_yield_rebalancer_setParentPeer_revertsWhen_notOwner() public {
        vm.prank(depositor);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", depositor));
        baseRebalancer.setParentPeer(newParentPeer);
    }

    function test_yield_rebalancer_setParentPeer_revertsWhen_zeroAddress() public {
        vm.prank(baseRebalancer.owner());
        vm.expectRevert(abi.encodeWithSignature("Rebalancer__NotZeroAddress()"));
        baseRebalancer.setParentPeer(address(0));
    }

    /*//////////////////////////////////////////////////////////////
                            SET STRATEGY REGISTRY
    //////////////////////////////////////////////////////////////*/
    function test_yield_rebalancer_setStrategyRegistry_updatesStorage() public {
        vm.prank(baseRebalancer.owner());
        baseRebalancer.setStrategyRegistry(newStrategyRegistry);
        address returnedStrategyRegistry = baseRebalancer.getStrategyRegistry();
        assertEq(returnedStrategyRegistry, newStrategyRegistry);
    }

    function test_yield_rebalancer_setStrategyRegistry_emitsEvent() public {
        /// @dev Arrange / Act
        vm.prank(baseRebalancer.owner());
        vm.recordLogs();
        baseRebalancer.setStrategyRegistry(newStrategyRegistry);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bool strategyRegistrySetLogFound = false;
        address emittedStrategyRegistry;
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("StrategyRegistrySet(address)")) {
                emittedStrategyRegistry = address(uint160(uint256(entries[i].topics[1])));
                strategyRegistrySetLogFound = true;
                break;
            }
        }

        /// @dev Assert
        assertTrue(strategyRegistrySetLogFound);
        assertEq(emittedStrategyRegistry, newStrategyRegistry);
    }

    function test_yield_rebalancer_setStrategyRegistry_revertsWhen_zeroAddress() public {
        vm.prank(baseRebalancer.owner());
        vm.expectRevert(abi.encodeWithSignature("Rebalancer__NotZeroAddress()"));
        baseRebalancer.setStrategyRegistry(address(0));
    }

    function test_yield_rebalancer_setStrategyRegistry_revertsWhen_notOwner() public {
        vm.prank(depositor);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", depositor));
        baseRebalancer.setStrategyRegistry(newStrategyRegistry);
    }
}
