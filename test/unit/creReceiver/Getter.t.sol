// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm} from "../../BaseTest.t.sol";

/// @dev CREReceiver inherited by Rebalancer
contract GetterTest is BaseTest {
    function test_yield_creReceiver_getKeystoneForwarder_returnsForwarder() public view {
        address retrievedForwarder = baseRebalancer.getKeystoneForwarder();
        assertEq(retrievedForwarder, keystoneForwarder);
    }

    function test_yield_creReceiver_getWorkflow_returnsWorkflowInfo() public view {
        bytes10 workflowName = _createWorkflowName(workflowNameRaw);

        (bytes32 retrievedWorkflowId, address retrievedWorkflowOwner, bytes10 retrievedWorkflowName) =
            baseRebalancer.getWorkflow(workflowId);

        assertEq(retrievedWorkflowId, workflowId);
        assertEq(retrievedWorkflowOwner, workflowOwner);
        assertEq(retrievedWorkflowName, workflowName);
    }

    function test_yield_creReceiver_getWorkflowOwner_returnsWorkflowOwner() public view {
        address retrievedWorkflowOwner = baseRebalancer.getWorkflowOwner(workflowId);
        assertEq(retrievedWorkflowOwner, workflowOwner);
    }

    function test_yield_creReceiver_getWorkflowName_returnsWorkflowName() public view {
        bytes10 retrievedWorkflowName = baseRebalancer.getWorkflowName(workflowId);
        assertEq(retrievedWorkflowName, _createWorkflowName(workflowNameRaw));
    }
}
