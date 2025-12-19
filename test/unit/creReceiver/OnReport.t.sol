// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, WorkflowHelpers} from "../../BaseTest.t.sol";

/// @dev CREReceiver inherited by Rebalancer
contract OnReportTest is BaseTest {
    function test_yield_creReceiver_onReport_revertsWhen_notKeystoneForwarder() public {
        // Arrange
        bytes memory metadata;
        bytes memory report;

        // Act & Assert
        vm.prank(configAdmin);
        vm.expectRevert(
            abi.encodeWithSignature(
                "CREReceiver__InvalidKeystoneForwarder(address,address)", configAdmin, keystoneForwarder
            )
        );
        baseRebalancer.onReport(metadata, report);
    }

    function test_yield_creReceiver_onReport_revertsWhen_wrongWorkflowId() public {
        // Arrange
        bytes32 wrongWorkflowId = keccak256(abi.encodePacked("WRONG_ID"));
        bytes memory newMetadata = WorkflowHelpers.createWorkflowMetadata(wrongWorkflowId, workflowName, workflowOwner);
        bytes memory report =
            WorkflowHelpers.createWorkflowReport(baseChainSelector, keccak256(abi.encodePacked("aave-v3")));

        // Act & Assert
        vm.prank(keystoneForwarder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "CREReceiver__InvalidWorkflow(bytes32,address,bytes10)", wrongWorkflowId, workflowOwner, workflowName
            )
        );
        baseRebalancer.onReport(newMetadata, report);
    }

    function test_yield_creReceiver_onReport_revertsWhen_wrongWorkflowOwner() public {
        // Arrange
        bytes memory newMetadata = WorkflowHelpers.createWorkflowMetadata(workflowId, workflowName, depositor);
        bytes memory report =
            WorkflowHelpers.createWorkflowReport(baseChainSelector, keccak256(abi.encodePacked("aave-v3")));

        // Act & Assert
        vm.prank(keystoneForwarder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "CREReceiver__InvalidWorkflow(bytes32,address,bytes10)", workflowId, depositor, workflowName
            )
        );
        baseRebalancer.onReport(newMetadata, report);
    }

    function test_yield_creReceiver_onReport_revertsWhen_wrongWorkflowName() public {
        // Arrange
        bytes10 wrongWorkflowName = WorkflowHelpers.createWorkflowName("WRONGNAME");
        bytes memory newMetadata = WorkflowHelpers.createWorkflowMetadata(workflowId, wrongWorkflowName, workflowOwner);
        bytes memory report =
            WorkflowHelpers.createWorkflowReport(baseChainSelector, keccak256(abi.encodePacked("aave-v3")));

        // Act & Assert
        vm.prank(keystoneForwarder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "CREReceiver__InvalidWorkflow(bytes32,address,bytes10)", workflowId, workflowOwner, wrongWorkflowName
            )
        );
        baseRebalancer.onReport(newMetadata, report);
    }

    function test_yield_creReceiver_onReport_success_emitsSecurityChecksPassed() public {
        // Arrange
        bytes memory report =
            WorkflowHelpers.createWorkflowReport(baseChainSelector, keccak256(abi.encodePacked("aave-v3")));
        vm.recordLogs();

        // Act
        vm.prank(keystoneForwarder);
        baseRebalancer.onReport(workflowMetadata, report);

        // Handle log for OnReportSecurityChecksPassed event
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool securityChecksPassedEventFound;
        bytes32 decodedWorkflowId;
        address decodedWorkflowOwner;
        bytes10 decodedWorkflowfName;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256(("OnReportSecurityChecksPassed(bytes32,address,bytes10)"))) {
                decodedWorkflowId = bytes32(logs[i].topics[1]);
                decodedWorkflowOwner = address(uint160(uint256(logs[i].topics[2])));
                decodedWorkflowfName = bytes10(logs[i].topics[3]);
                securityChecksPassedEventFound = true;
                break;
            }
        }

        // Assert
        assertEq(securityChecksPassedEventFound, true);
        assertEq(decodedWorkflowId, workflowId);
        assertEq(decodedWorkflowOwner, workflowOwner);
        assertEq(decodedWorkflowfName, workflowName);
    }
}
