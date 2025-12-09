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

    function test_yield_rebalancer_onReport_rebalanceParentToChild() public {
        /// @dev Arrange: Strategy on parent, deposit on parent to have TVL
        _selectFork(baseFork);

        deal(address(baseUsdc), depositor, DEPOSIT_AMOUNT);
        _changePrank(depositor);
        baseUsdc.approve(address(baseParentPeer), DEPOSIT_AMOUNT);
        baseParentPeer.deposit(DEPOSIT_AMOUNT);

        // Store TVL to verify in event
        uint256 totalValue = baseParentPeer.getTotalValue();

        // Create workflow metadata and report
        bytes10 workflowName = _createWorkflowName(workflowNameRaw);
        bytes memory metadata = _createWorkflowMetadata(workflowId, workflowName, workflowOwner);
        IYieldPeer.Strategy memory newStrategy =
            IYieldPeer.Strategy({chainSelector: optChainSelector, protocolId: keccak256(abi.encodePacked("aave-v3"))});
        bytes memory encodedReport = _createWorkflowReport(newStrategy.chainSelector, newStrategy.protocolId);

        /// @dev Act
        _changePrank(keystoneForwarder);
        vm.recordLogs();
        baseRebalancer.onReport(metadata, encodedReport);

        /// @dev Assert: Check for CCIPMessageSent event with correct tx type and value
        /// @dev Tx type should be RebalanceNewStrategy as strategy is moving
        /// @dev from Parent > Child and handled by ParentPeer::_rebalanceParentToChild
        bytes32 ccipMessageSentEvent = keccak256("CCIPMessageSent(bytes32,uint8,uint256)");
        bool ccipMessageSentEventFound = false;
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == ccipMessageSentEvent) {
                ccipMessageSentEventFound = true;
                assertEq(uint8(uint256(logs[i].topics[2])), uint8(IYieldPeer.CcipTxType.RebalanceNewStrategy));
                assertEq(uint256(logs[i].topics[3]), totalValue);
            }
        }
        assertTrue(ccipMessageSentEventFound, "CCIPMessageSent log not found");
    }

    function test_yield_rebalancer_onReport_rebalanceChildToOther() public {
        /// @dev Arrange: Change Strategy to be on a Child (eth child)
        _setStrategy(ethChainSelector, keccak256(abi.encodePacked("aave-v3")), SET_CROSS_CHAIN);

        // Create workflow metadata and report
        bytes10 workflowName = _createWorkflowName(workflowNameRaw);
        bytes memory metadata = _createWorkflowMetadata(workflowId, workflowName, workflowOwner);
        IYieldPeer.Strategy memory newStrategy =
            IYieldPeer.Strategy({chainSelector: optChainSelector, protocolId: keccak256(abi.encodePacked("aave-v3"))});
        bytes memory encodedReport = _createWorkflowReport(newStrategy.chainSelector, newStrategy.protocolId);

        /// @dev Act
        _selectFork(baseFork);
        _changePrank(keystoneForwarder);
        vm.recordLogs();
        baseRebalancer.onReport(metadata, encodedReport);

        /// @dev Assert: Check for CCIPMessageSent event with correct tx type
        /// @dev Tx type should be RebalanceOldStrategy as strategy is moving
        /// @dev from Child > Other (Child) and handled by ParentPeer::_rebalanceChildToOther
        bytes32 ccipMessageSentEvent = keccak256("CCIPMessageSent(bytes32,uint8,uint256)");
        bool ccipMessageSentEventFound = false;
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == ccipMessageSentEvent) {
                ccipMessageSentEventFound = true;
                assertEq(uint8(uint256(logs[i].topics[2])), uint8(IYieldPeer.CcipTxType.RebalanceOldStrategy));
                assertEq(uint256(logs[i].topics[3]), 0);
            }
        }
        assertTrue(ccipMessageSentEventFound, "CCIPMessageSent log not found");
    }
}
