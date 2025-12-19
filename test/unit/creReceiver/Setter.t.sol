// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, CREReceiver, WorkflowHelpers} from "../../BaseTest.t.sol";

/// @dev CREReceiver inherited by Rebalancer
contract SetterTest is BaseTest {
    address newKeystoneForwarder = makeAddr("newKeystoneForwarder");
    string newWorkflowNameRaw = "NEWWORKFLOW";
    bytes10 newWorkflowName = WorkflowHelpers.createWorkflowName(newWorkflowNameRaw);
    bytes32 newWorkflowId = keccak256(abi.encodePacked("ANOTHERWORKFLOWID"));

    /*//////////////////////////////////////////////////////////////
                                SET KEYSTONE
    //////////////////////////////////////////////////////////////*/
    function test_yield_creReceiver_setKeystoneForwarder_updatesStorage() public {
        // Arrange & Act
        _changePrank(baseRebalancer.owner());
        baseRebalancer.setKeystoneForwarder(newKeystoneForwarder);

        // Assert
        assertEq(baseRebalancer.getKeystoneForwarder(), newKeystoneForwarder);
    }

    function test_yield_creReceiver_setKeystoneForwarder_emitsEvent() public {
        // Arrange & Act
        _changePrank(baseRebalancer.owner());
        vm.recordLogs();
        baseRebalancer.setKeystoneForwarder(newKeystoneForwarder);

        // Handle log for KeystoneForwarderSet event
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool keystoneForwarderSetEventFound;
        address emittedKeystoneForwarder;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256(("KeystoneForwarderSet(address)"))) {
                emittedKeystoneForwarder = address(uint160(uint256(logs[i].topics[1])));
                keystoneForwarderSetEventFound = true;
                break;
            }
        }

        // Assert
        assertEq(keystoneForwarderSetEventFound, true);
        assertEq(emittedKeystoneForwarder, newKeystoneForwarder);
    }

    function test_yield_creReceiver_setKeystoneForwarder_revertsWhen_notOwner() public {
        // Arrange
        vm.prank(depositor);

        // Act & Assert
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", depositor));
        baseRebalancer.setKeystoneForwarder(newKeystoneForwarder);
    }

    function test_yield_creReceiver_setKeystoneForwarders_revertsWhen_zeroAddress() public {
        // Arrange
        address newKeystoneForwarderZero = address(0);

        // Act & Assert
        _changePrank(baseRebalancer.owner());
        vm.expectRevert(abi.encodeWithSignature("CREReceiver__NotZeroAddress()"));
        baseRebalancer.setKeystoneForwarder(newKeystoneForwarderZero);
    }

    /*//////////////////////////////////////////////////////////////
                                SET WORKFLOW
    //////////////////////////////////////////////////////////////*/
    function test_yield_creReceiver_setWorkflow_emitstEvent() public {
        // Arrange & Act
        vm.recordLogs();
        _changePrank(baseRebalancer.owner());
        baseRebalancer.setWorkflow(newWorkflowId, workflowOwner, newWorkflowNameRaw);

        // Handle log for WorkflowSet event
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool workflowSetEventFound;
        bytes32 emittedWorkflowId;
        address emittedWorkflowOwner;
        bytes10 emittedWorkflowName;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256(("WorkflowSet(bytes32,address,bytes10)"))) {
                emittedWorkflowId = bytes32(logs[i].topics[1]);
                emittedWorkflowOwner = address(uint160(uint256(logs[i].topics[2])));
                emittedWorkflowName = bytes10(logs[i].topics[3]);
                workflowSetEventFound = true;
                break;
            }
        }

        // Assert
        assertEq(workflowSetEventFound, true);
        assertEq(emittedWorkflowId, newWorkflowId);
        assertEq(emittedWorkflowOwner, workflowOwner);
        assertEq(emittedWorkflowName, newWorkflowName);
    }

    function test_yield_creReceiver_setWorkflow_updatesStorage() public {
        // Arrange & Act
        _changePrank(baseRebalancer.owner());
        baseRebalancer.setWorkflow(newWorkflowId, workflowOwner, newWorkflowNameRaw);

        // Assert
        CREReceiver.Workflow memory storedWorkflow = baseRebalancer.getWorkflow(newWorkflowId);
        assertEq(storedWorkflow.name, newWorkflowName);
        assertEq(storedWorkflow.owner, workflowOwner);
    }

    function test_yield_creReceiver_setWorkflow_revertsWhen_workflowIdZero() public {
        // Arrange
        bytes32 emptyWorkflowId = bytes32(0);

        // Act & Assert
        _changePrank(baseRebalancer.owner());
        vm.expectRevert(abi.encodeWithSignature("CREReceiver__NotZeroId()"));
        baseRebalancer.setWorkflow(emptyWorkflowId, workflowOwner, workflowNameRaw);
    }

    function test_yield_creReceiver_setWorkflow_revertsWhen_workflowOwnerZero() public {
        // Arrange
        address emptyWorkflowOwner = address(0);

        // Act & Assert
        _changePrank(baseRebalancer.owner());
        vm.expectRevert(abi.encodeWithSignature("CREReceiver__NotZeroAddress()"));
        baseRebalancer.setWorkflow(workflowId, emptyWorkflowOwner, workflowNameRaw);
    }

    function test_yield_creReceiver_setWorkflow_revertsWhen_workflowNameEmpty() public {
        // Arrange
        string memory emptyWorkflowName = "";

        // Act & Assert
        _changePrank(baseRebalancer.owner());
        vm.expectRevert(abi.encodeWithSignature("CREReceiver__NotEmptyName()"));
        baseRebalancer.setWorkflow(workflowId, workflowOwner, emptyWorkflowName);
    }
}
