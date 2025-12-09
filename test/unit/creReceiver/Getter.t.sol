// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm} from "../../BaseTest.t.sol";
import {CREReceiver} from "../../../src/modules/CREReceiver.sol";

/// @dev CREReceiver inherited by Rebalancer
contract GetterTest is BaseTest {
    function test_yield_creReceiver_getKeystoneForwarder_returnsForwarder() public view {
        address retrievedForwarder = baseRebalancer.getKeystoneForwarder();
        assertEq(retrievedForwarder, keystoneForwarder);
    }

    function test_yield_creReceiver_getWorkflow_returnsWorkflowInfo() public view {
        bytes10 workflowName = _createWorkflowName(workflowNameRaw);

        CREReceiver.Workflow memory retrievedWorkflow = baseRebalancer.getWorkflow(workflowId);

        assertEq(retrievedWorkflow.owner, workflowOwner);
        assertEq(retrievedWorkflow.name, workflowName);
    }
}
