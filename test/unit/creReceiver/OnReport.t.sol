// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm} from "../../BaseTest.t.sol";

/// @dev CREReceiver inherited by Rebalancer
contract OnReportTest is BaseTest {
    function test_yield_creReceiver_onReport_revertsWhen_notKeystoneForwarder() public {
        bytes10 workflowName = _createWorkflowName(workflowNameRaw);

        bytes memory metadata = _createWorkflowMetadata(workflowId, workflowName, workflowOwner);
        bytes memory report = _createWorkflowReport(optChainSelector, keccak256(abi.encodePacked("aave-v3")));

        vm.prank(configAdmin);
        vm.expectRevert(
            abi.encodeWithSignature(
                "CREReceiver__InvalidKeystoneForwarder(address,address)", configAdmin, keystoneForwarder
            )
        );
        baseRebalancer.onReport(metadata, report);
    }

    function test_yield_creReceiver_onReport_revertsWhen_wrongWorkflowId() public {
        bytes10 workflowName = _createWorkflowName(workflowNameRaw);
        bytes32 wrongWorkflowId = keccak256(abi.encodePacked("WRONG_ID"));

        bytes memory metadata = _createWorkflowMetadata(wrongWorkflowId, workflowName, workflowOwner);
        bytes memory report = _createWorkflowReport(baseChainSelector, keccak256(abi.encodePacked("aave-v3")));

        vm.prank(keystoneForwarder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "CREReceiver__InvalidWorkflow(bytes32,address,bytes10)", wrongWorkflowId, workflowOwner, workflowName
            )
        );
        baseRebalancer.onReport(metadata, report);
    }

    function test_yield_creReceiver_onReport_revertsWhen_wrongWorkflowOwner() public {
        bytes10 workflowName = _createWorkflowName(workflowNameRaw);

        bytes memory metadata = _createWorkflowMetadata(workflowId, workflowName, depositor);
        bytes memory report = _createWorkflowReport(baseChainSelector, keccak256(abi.encodePacked("aave-v3")));

        vm.prank(keystoneForwarder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "CREReceiver__InvalidWorkflow(bytes32,address,bytes10)", workflowId, depositor, workflowName
            )
        );
        baseRebalancer.onReport(metadata, report);
    }

    function test_yield_creReceiver_onReport_revertsWhen_wrongWorkflowName() public {
        bytes10 wrongWorkflowName = _createWorkflowName("WRONGNAME");

        bytes memory metadata = _createWorkflowMetadata(workflowId, wrongWorkflowName, workflowOwner);
        bytes memory report = _createWorkflowReport(baseChainSelector, keccak256(abi.encodePacked("aave-v3")));

        vm.prank(keystoneForwarder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "CREReceiver__InvalidWorkflow(bytes32,address,bytes10)", workflowId, workflowOwner, wrongWorkflowName
            )
        );
        baseRebalancer.onReport(metadata, report);
    }

    function test_yield_creReceiver_onReport_success_emitsSecurityChecksPassed() public {
        bytes10 workflowName = _createWorkflowName(workflowNameRaw);

        bytes memory metadata = _createWorkflowMetadata(workflowId, workflowName, workflowOwner);
        bytes memory report = _createWorkflowReport(baseChainSelector, keccak256(abi.encodePacked("aave-v3")));

        vm.prank(keystoneForwarder);
        vm.recordLogs();
        baseRebalancer.onReport(metadata, report);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool securityChecksPassedLogFound;
        bytes32 wfId;
        address wfOwner;
        bytes10 wfName;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256(("OnReportSecurityChecksPassed(bytes32,address,bytes10)"))) {
                wfId = logs[i].topics[1];
                wfOwner = address(uint160(uint256(logs[i].topics[2])));
                wfName = bytes10(logs[i].topics[3]);
                securityChecksPassedLogFound = true;
                break;
            }
        }

        assertEq(securityChecksPassedLogFound, true);
        assertEq(wfId, workflowId);
        assertEq(wfOwner, workflowOwner);
        assertEq(wfName, workflowName);
    }
}
