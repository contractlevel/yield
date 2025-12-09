// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm} from "../../BaseTest.t.sol";
import {CREReceiver} from "../../../src/modules/CREReceiver.sol";

/// @dev CREReceiver inherited by Rebalancer
contract SetterTest is BaseTest {
    address newForwarder = makeAddr("newForwarder");

    /*//////////////////////////////////////////////////////////////
                                SET KEYSTONE
    //////////////////////////////////////////////////////////////*/
    function test_yield_creReceiver_setKeystoneForwarder_updatesStorage() public {
        _changePrank(baseRebalancer.owner());
        baseRebalancer.setKeystoneForwarder(newForwarder);

        assertEq(baseRebalancer.getKeystoneForwarder(), newForwarder);
    }

    function test_yield_creReceiver_setKeystoneForwarder_emitsEvent() public {
        _changePrank(baseRebalancer.owner());
        vm.recordLogs();
        baseRebalancer.setKeystoneForwarder(newForwarder);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool forwarderSetLogFound;
        address loggedForwarder;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256(("KeystoneForwarderSet(address)"))) {
                loggedForwarder = address(uint160(uint256(logs[i].topics[1])));
                forwarderSetLogFound = true;
                break;
            }
        }

        assertEq(forwarderSetLogFound, true);
        assertEq(loggedForwarder, newForwarder);
    }

    function test_yield_creReceiver_setKeystoneForwarder_revetsWhen_notOwner() public {
        vm.prank(depositor);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", depositor));
        baseRebalancer.setKeystoneForwarder(newForwarder);
    }

    function test_yield_creReceiver_setKeystoneForwarders_revertsWhen_zeroAddress() public {
        _changePrank(baseRebalancer.owner());
        vm.expectRevert(abi.encodeWithSignature("CREReceiver__NotZeroAddress()"));
        baseRebalancer.setKeystoneForwarder(address(0));
    }

    /*//////////////////////////////////////////////////////////////
                                SET WORKFLOW
    //////////////////////////////////////////////////////////////*/
    function test_yield_creReceiver_setWorkflow_emitstEvent() public {
        string memory newWorkflowNameRaw = "NEWWORKFLOW";
        bytes10 newWorkflowName = _createWorkflowName(newWorkflowNameRaw);
        bytes32 newWorkflowId = keccak256(abi.encodePacked("NEWWORKFLOWID"));

        vm.recordLogs();
        _changePrank(baseRebalancer.owner());
        baseRebalancer.setWorkflow(newWorkflowId, workflowOwner, newWorkflowNameRaw);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool workflowSetLogFound;
        bytes32 wfId;
        address wfOwner;
        bytes10 wfName;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256(("WorkflowSet(bytes32,address,bytes10)"))) {
                wfId = logs[i].topics[1];
                wfOwner = address(uint160(uint256(logs[i].topics[2])));
                wfName = bytes10(logs[i].topics[3]);
                workflowSetLogFound = true;
                break;
            }
        }

        assertEq(workflowSetLogFound, true);
        assertEq(wfId, newWorkflowId);
        assertEq(wfOwner, workflowOwner);
        assertEq(wfName, newWorkflowName);
    }

    function test_yield_creReceiver_setWorkflow_updatesStorage() public {
        string memory newWorkflowNameRaw = "ANOTHERWORKFLOW";
        bytes10 newWorkflowName = _createWorkflowName(newWorkflowNameRaw);
        bytes32 newWorkflowId = keccak256(abi.encodePacked("ANOTHERWORKFLOWID"));

        _changePrank(baseRebalancer.owner());
        baseRebalancer.setWorkflow(newWorkflowId, workflowOwner, newWorkflowNameRaw);

        CREReceiver.Workflow memory storedWorkflow = baseRebalancer.getWorkflow(newWorkflowId);

        assertEq(storedWorkflow.name, newWorkflowName);
        assertEq(storedWorkflow.owner, workflowOwner);
    }

    function test_yield_creReceiver_setWorkflow_revertsWhen_workflowIdZero() public {
        _changePrank(baseRebalancer.owner());
        vm.expectRevert(abi.encodeWithSignature("CREReceiver__NotZeroId()"));
        baseRebalancer.setWorkflow(bytes32(0), workflowOwner, workflowNameRaw);
    }

    function test_yield_creReceiver_setWorkflow_revertsWhen_workflowOwnerZero() public {
        _changePrank(baseRebalancer.owner());
        vm.expectRevert(abi.encodeWithSignature("CREReceiver__NotZeroAddress()"));
        baseRebalancer.setWorkflow(workflowId, address(0), workflowNameRaw);
    }

    function test_yield_creReceiver_setWorkflow_revertsWhen_workflowNameEmpty() public {
        _changePrank(baseRebalancer.owner());
        vm.expectRevert(abi.encodeWithSignature("CREReceiver__NotEmptyName()"));
        baseRebalancer.setWorkflow(workflowId, workflowOwner, "");
    }
}
