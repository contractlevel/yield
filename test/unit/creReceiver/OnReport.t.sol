// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, WorkflowHelpers} from "../../BaseTest.t.sol";

/// @dev CREReceiver inherited by Rebalancer
contract OnReportTest is BaseTest {
    // Zero values for testing
    bytes32 zeroId = bytes32(0);
    address zeroOwner = address(0);
    bytes10 zeroName = bytes10(0);

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

    function test_yield_creReceiver_onReport_revertsWhen_emptyMetadata() public {
        // Arrange
        bytes memory emptyMetadata = WorkflowHelpers.createWorkflowMetadata(zeroId, zeroName, zeroOwner);
        bytes memory report =
            WorkflowHelpers.createWorkflowReport(baseChainSelector, keccak256(abi.encodePacked("aave-v3")));

        // Act & Assert
        vm.prank(keystoneForwarder);
        vm.expectRevert(
            abi.encodeWithSignature("CREReceiver__MetadataZero(bytes32,address,bytes10)", zeroId, zeroOwner, zeroName)
        );
        baseRebalancer.onReport(emptyMetadata, report);
    }

    function test_yield_creReceiver_onReport_revertsWhen_zeroWorkflowId() public {
        // Arrange
        bytes memory newMetadata = WorkflowHelpers.createWorkflowMetadata(zeroId, workflowName, workflowOwner);
        bytes memory report =
            WorkflowHelpers.createWorkflowReport(baseChainSelector, keccak256(abi.encodePacked("aave-v3")));

        // Act & Assert
        vm.prank(keystoneForwarder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "CREReceiver__MetadataZero(bytes32,address,bytes10)", zeroId, workflowOwner, workflowName
            )
        );
        baseRebalancer.onReport(newMetadata, report);
    }

    function test_yield_creReceiver_onReport_revertsWhen_zeroWorkflowOwner() public {
        // Arrange
        bytes memory newMetadata = WorkflowHelpers.createWorkflowMetadata(workflowId, workflowName, zeroOwner);
        bytes memory report =
            WorkflowHelpers.createWorkflowReport(baseChainSelector, keccak256(abi.encodePacked("aave-v3")));

        // Act & Assert
        vm.prank(keystoneForwarder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "CREReceiver__MetadataZero(bytes32,address,bytes10)", workflowId, zeroOwner, workflowName
            )
        );
        baseRebalancer.onReport(newMetadata, report);
    }

    function test_yield_creReceiver_onReport_revertsWhen_zeroWorkflowName() public {
        // Arrange
        bytes memory newMetadata = WorkflowHelpers.createWorkflowMetadata(workflowId, zeroName, workflowOwner);
        bytes memory report =
            WorkflowHelpers.createWorkflowReport(baseChainSelector, keccak256(abi.encodePacked("aave-v3")));

        // Act & Assert
        vm.prank(keystoneForwarder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "CREReceiver__MetadataZero(bytes32,address,bytes10)", workflowId, workflowOwner, zeroName
            )
        );
        baseRebalancer.onReport(newMetadata, report);
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
                "CREReceiver__InvalidWorkflowId(bytes32,address,bytes10)", wrongWorkflowId, zeroOwner, zeroName
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
            abi.encodeWithSignature("CREReceiver__InvalidWorkflowOwner(bytes32,address)", workflowId, depositor)
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
            abi.encodeWithSignature("CREReceiver__InvalidWorkflowName(bytes32,bytes10)", workflowId, wrongWorkflowName)
        );
        baseRebalancer.onReport(newMetadata, report);
    }
}
