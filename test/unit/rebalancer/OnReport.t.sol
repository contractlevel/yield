// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, IYieldPeer} from "../../BaseTest.t.sol";

/// @dev The "_onReport" internal implementation in Rebalancer
contract OnReportTest is BaseTest {
    /// @dev We are checking the emitted event from the _onReport call
    /// @dev when the report is valid and decoded successfully
    function test_yield_rebalancer_onReport_decodesReport() public {
        /// @dev Arrange
        bytes10 workflowName = _createWorkflowName(workflowNameRaw);
        bytes memory metadata = _createWorkflowMetadata(workflowId, workflowName, workflowOwner);

        IYieldPeer.Strategy memory newStrategy = IYieldPeer.Strategy({
            chainSelector: baseChainSelector, protocolId: keccak256(abi.encodePacked("compound-v3"))
        });
        bytes memory encodedReport = _createWorkflowReport(newStrategy.chainSelector, newStrategy.protocolId);

        /// @dev Act
        vm.recordLogs();
        vm.prank(keystoneForwarder);
        baseRebalancer.onReport(metadata, encodedReport);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bool eventFound = false;
        uint64 emittedChainSelector;
        bytes32 emittedProtocolId;
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("ReportDecoded(uint64,bytes32)")) {
                emittedChainSelector = uint64(uint256(entries[i].topics[1]));
                emittedProtocolId = bytes32(entries[i].topics[2]);
                eventFound = true;
            }
        }

        /// @dev Assert
        assertTrue(eventFound);
        assertEq(emittedChainSelector, newStrategy.chainSelector);
        assertEq(emittedProtocolId, newStrategy.protocolId);
    }

    function test_yield_rebalancer_onReport_emitsEventWhen_invalidChainSelector() public {
        /// @dev Arrange
        uint64 invalidChainSelector = 9999;
        bytes10 workflowName = _createWorkflowName(workflowNameRaw);
        bytes memory metadata = _createWorkflowMetadata(workflowId, workflowName, workflowOwner);

        IYieldPeer.Strategy memory newStrategy = IYieldPeer.Strategy({
            chainSelector: invalidChainSelector, protocolId: keccak256(abi.encodePacked("compound-v3"))
        });
        bytes memory encodedReport = _createWorkflowReport(newStrategy.chainSelector, newStrategy.protocolId);

        /// @dev Act
        vm.recordLogs();
        vm.prank(keystoneForwarder);
        baseRebalancer.onReport(metadata, encodedReport);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bool invalidChainSelectorEventFound = false;
        uint64 emittedChainSelector;
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("InvalidChainSelectorInReport(uint64)")) {
                emittedChainSelector = uint64(uint256(entries[i].topics[1]));
                invalidChainSelectorEventFound = true;
            }
        }

        /// @dev Assert
        assertTrue(invalidChainSelectorEventFound);
        assertEq(emittedChainSelector, newStrategy.chainSelector);
    }

    function test_yield_rebalancer_onReport_emitsEventWhen_invalidProtocolId() public {
        /// @dev Arrange
        bytes32 invalidProtocolId = keccak256(abi.encodePacked("invalid"));
        bytes10 workflowName = _createWorkflowName(workflowNameRaw);
        bytes memory metadata = _createWorkflowMetadata(workflowId, workflowName, workflowOwner);

        IYieldPeer.Strategy memory newStrategy =
            IYieldPeer.Strategy({chainSelector: baseChainSelector, protocolId: invalidProtocolId});
        bytes memory encodedReport = _createWorkflowReport(newStrategy.chainSelector, newStrategy.protocolId);

        /// @dev Act
        vm.recordLogs();
        vm.prank(keystoneForwarder);
        baseRebalancer.onReport(metadata, encodedReport);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bool invalidProtocolIdEventFound = false;
        bytes32 emittedProtocolId;
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("InvalidProtocolIdInReport(bytes32)")) {
                emittedProtocolId = bytes32(entries[i].topics[1]);
                invalidProtocolIdEventFound = true;
            }
        }

        /// @dev Assert
        assertTrue(invalidProtocolIdEventFound);
        assertEq(emittedProtocolId, newStrategy.protocolId);
    }
}
