// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, CREReceiver} from "../../BaseTest.t.sol";

/// @dev CREReceiver inherited by Rebalancer
contract GetterTest is BaseTest {
    function test_yield_creReceiver_getKeystoneForwarder_returnsForwarder() public view {
        // Arrange & Act
        address retrievedForwarder = baseRebalancer.getKeystoneForwarder();

        // Assert
        assertEq(retrievedForwarder, keystoneForwarder);
    }

    function test_yield_creReceiver_getWorkflow_returnsWorkflow() public view {
        // Arrange & Act
        CREReceiver.Workflow memory retrievedWorkflow = baseRebalancer.getWorkflow(workflowId);

        // Assert
        assertEq(retrievedWorkflow.owner, workflowOwner);
        assertEq(retrievedWorkflow.name, workflowName);
    }
}
