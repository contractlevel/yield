// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, CREReceiver} from "../../BaseTest.t.sol";

/// @dev CREReceiver inherited by Rebalancer
contract RemoveWorkflowTest is BaseTest {
    function test_yield_creReceiver_removeWorkflow_revertsWhen_notOwner() public {
        vm.prank(depositor);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", depositor));
        baseRebalancer.removeWorkflow(workflowId);
    }

    function test_yield_creReceiver_removeWorkflow_emitsEvent() public {
        bytes10 workflowName = _createWorkflowName(workflowNameRaw);

        _changePrank(baseRebalancer.owner());
        vm.recordLogs();
        baseRebalancer.removeWorkflow(workflowId);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool workflowRemovedLogFound;
        bytes32 wfId;
        address wfOwner;
        bytes10 wfName;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256(("WorkflowRemoved(bytes32,address,bytes10)"))) {
                wfId = logs[i].topics[1];
                wfOwner = address(uint160(uint256(logs[i].topics[2])));
                wfName = bytes10(logs[i].topics[3]);
                workflowRemovedLogFound = true;
                break;
            }
        }

        assertEq(workflowRemovedLogFound, true);
        assertEq(wfId, workflowId);
        assertEq(wfOwner, workflowOwner);
        assertEq(wfName, workflowName);
    }

    function test_yield_creReceiver_removeWorkflow_updatesStorage() public {
        bytes10 workflowName = _createWorkflowName(workflowNameRaw);

        CREReceiver.Workflow memory workflow = baseRebalancer.getWorkflow(workflowId);
        /// @dev confirm workflow exists before removal
        assertEq(workflow.owner, workflowOwner);
        assertEq(workflow.name, workflowName);

        _changePrank(baseRebalancer.owner());
        baseRebalancer.removeWorkflow(workflowId);

        workflow = baseRebalancer.getWorkflow(workflowId);
        /// @dev we are not checking the workflow id itself because it is stored as a mapping
        /// @dev we are confirming, by inference, that the workflow has been removed
        assertEq(workflow.owner, address(0));
        assertEq(workflow.name, bytes10(0));
    }
}
