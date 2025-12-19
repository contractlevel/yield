// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, CREReceiver, WorkflowHelpers} from "../../BaseTest.t.sol";

/// @dev CREReceiver inherited by Rebalancer
contract RemoveWorkflowTest is BaseTest {
    function test_yield_creReceiver_removeWorkflow_revertsWhen_notOwner() public {
        // Arrange
        vm.prank(depositor);

        // Act & Assert
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", depositor));
        baseRebalancer.removeWorkflow(workflowId);
    }

    function test_yield_creReceiver_removeWorkflow_emitsEvent() public {
        // Arrange
        _changePrank(baseRebalancer.owner());
        vm.recordLogs();

        // Act
        baseRebalancer.removeWorkflow(workflowId);

        // Handle log for WorkflowRemoved event
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool workflowRemovedEventFound;
        bytes32 decodedWorkflowId;
        address decodedWorkflowOwner;
        bytes10 decodedWorkflowName;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256(("WorkflowRemoved(bytes32,address,bytes10)"))) {
                decodedWorkflowId = bytes32(logs[i].topics[1]);
                decodedWorkflowOwner = address(uint160(uint256(logs[i].topics[2])));
                decodedWorkflowName = bytes10(logs[i].topics[3]);
                workflowRemovedEventFound = true;
                break;
            }
        }

        // Assert
        assertEq(workflowRemovedEventFound, true);
        assertEq(decodedWorkflowId, workflowId);
        assertEq(decodedWorkflowOwner, workflowOwner);
        assertEq(decodedWorkflowName, workflowName);
    }

    function test_yield_creReceiver_removeWorkflow_updatesStorage() public {
        // Arrange
        /// @dev confirm workflow exists before removal
        CREReceiver.Workflow memory workflow = baseRebalancer.getWorkflow(workflowId);
        assertEq(workflow.owner, workflowOwner);
        assertEq(workflow.name, workflowName);

        // Act
        _changePrank(baseRebalancer.owner());
        baseRebalancer.removeWorkflow(workflowId);

        // Assert
        /// @dev we are not checking the workflow id itself because it is stored as a mapping
        /// @dev we are confirming, by inference, that the workflow has been removed
        workflow = baseRebalancer.getWorkflow(workflowId);
        assertEq(workflow.owner, address(0));
        assertEq(workflow.name, bytes10(0));
    }
}
