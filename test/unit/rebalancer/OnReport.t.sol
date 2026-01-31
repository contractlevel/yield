// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, IYieldPeer, WorkflowHelpers} from "../../BaseTest.t.sol";

/// @dev The "_onReport" internal implementation in Rebalancer
contract OnReportTest is BaseTest {
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    // Protocol Ids
    bytes32 internal aaveV3ProtocolId = keccak256(abi.encodePacked("aave-v3"));
    bytes32 internal compoundV3ProtocolId = keccak256(abi.encodePacked("compound-v3"));

    // Events
    bytes32 internal invalidChainSelectorEvent = keccak256("InvalidChainSelectorInReport(uint64)");
    bytes32 internal invalidProtocolIdEvent = keccak256("InvalidProtocolIdInReport(bytes32)");
    bytes32 internal reportDecodedEvent = keccak256("ReportDecoded(uint64,bytes32)");
    bytes32 internal strategyUpdatedEvent = keccak256("StrategyUpdated(uint64,bytes32,uint64)");
    bytes32 internal depositToStrategyEvent = keccak256("DepositToStrategy(address,address,uint256)");
    bytes32 internal ccipMessageSentEvent = keccak256("CCIPMessageSent(bytes32,uint8,uint256)");

    // CCIP Tx Types
    uint8 internal rebalanceNewStrategyTxType = uint8(IYieldPeer.CcipTxType.RebalanceToNewStrategy);
    uint8 internal rebalanceOldStrategyTxType = uint8(IYieldPeer.CcipTxType.RebalanceFromOldStrategy);

    /*//////////////////////////////////////////////////////////////
                                 TESTS
    //////////////////////////////////////////////////////////////*/
    /// @dev We are checking the emitted event from the _onReport call
    /// @dev when the report is valid and decoded successfully
    function test_yield_rebalancer_onReport_decodesReport() public {
        // Arrange
        IYieldPeer.Strategy memory newStrategy = IYieldPeer.Strategy({
            protocolId: compoundV3ProtocolId, stablecoinId: USDC_ID, chainSelector: baseChainSelector
        });
        bytes memory encodedReport =
            WorkflowHelpers.createWorkflowReport(newStrategy.chainSelector, newStrategy.protocolId);

        // Act
        vm.recordLogs();
        vm.prank(keystoneForwarder);
        baseRebalancer.onReport(workflowMetadata, encodedReport);

        // Handle log for ReportDecoded event
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool reportDecodedEventFound = false;
        uint64 emittedChainSelector;
        bytes32 emittedProtocolId;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == reportDecodedEvent) {
                emittedChainSelector = uint64(uint256(logs[i].topics[1]));
                emittedProtocolId = bytes32(logs[i].topics[2]);
                reportDecodedEventFound = true;
            }
        }

        // Assert
        assertTrue(reportDecodedEventFound);
        assertEq(emittedChainSelector, newStrategy.chainSelector);
        assertEq(emittedProtocolId, newStrategy.protocolId);
    }

    /// @dev This serves as a consistency event/state test for onReport:
    /// @dev 1. Check if incoming new strategy matches decoded strategy
    /// @dev 2. Check if decoded strategy matches strategy state
    /// @dev 3. Check if decoded strategy matches strategy updated event (+ old chain)
    /// @dev 3. Check if strategy updated event matches strategy state
    function test_yield_rebalancer_onReport_strategyConsistency() public {
        /// @dev Arrange
        IYieldPeer.Strategy memory newStrategy = IYieldPeer.Strategy({
            protocolId: compoundV3ProtocolId, stablecoinId: USDC_ID, chainSelector: optChainSelector
        });
        bytes memory encodedReport =
            WorkflowHelpers.createWorkflowReport(newStrategy.chainSelector, newStrategy.protocolId);

        // Cache old strategy before onReport for event assertion
        IYieldPeer.Strategy memory oldStrategy = baseParentPeer.getStrategy();

        /// @dev Act
        vm.recordLogs();
        vm.prank(keystoneForwarder);
        baseRebalancer.onReport(workflowMetadata, encodedReport);

        // Get strategy state after onReport
        IYieldPeer.Strategy memory strategyState = baseParentPeer.getStrategy();

        // Set up variables for events checking
        bool reportDecodedEventFound = false;
        uint64 decodedChainSelector; // -------------- ReportDecoded event
        bytes32 decodedProtocolId; // ---------------- ReportDecoded event

        bool strategyUpdatedEventFound = false;
        uint64 emittedStrategyChainSelector; // ------ StrategyUpdated event
        bytes32 emittedStrategyProtocolId; // -------- StrategyUpdated event
        uint64 emittedOldStrategyChainSelector; // --- StrategyUpdated event

        // Handle logs for ReportDecoded and StrategyUpdated events
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == reportDecodedEvent) {
                decodedChainSelector = uint64(uint256(logs[i].topics[1]));
                decodedProtocolId = bytes32(logs[i].topics[2]);
                reportDecodedEventFound = true;
            }
            if (logs[i].topics[0] == strategyUpdatedEvent) {
                emittedStrategyChainSelector = uint64(uint256(logs[i].topics[1]));
                emittedStrategyProtocolId = bytes32(logs[i].topics[2]);
                emittedOldStrategyChainSelector = uint64(uint256(logs[i].topics[3]));
                strategyUpdatedEventFound = true;
            }
        }

        /// @dev Assert
        assertTrue(reportDecodedEventFound, "ReportDecoded log not found");
        assertTrue(strategyUpdatedEventFound, "StrategyUpdated log not found");

        // New incoming strategy should match decoded strategy
        assertEq(newStrategy.chainSelector, decodedChainSelector);
        assertEq(newStrategy.protocolId, decodedProtocolId);

        // Decoded strategy should match strategy state
        assertEq(decodedChainSelector, strategyState.chainSelector);
        assertEq(decodedProtocolId, strategyState.protocolId);

        // Emitted strategy should match decoded strategy (+ cached old strategy)
        assertEq(emittedStrategyChainSelector, decodedChainSelector);
        assertEq(emittedStrategyProtocolId, decodedProtocolId);
        assertEq(emittedOldStrategyChainSelector, oldStrategy.chainSelector);

        // Strategy state should match emitted strategy updated event
        assertEq(strategyState.chainSelector, emittedStrategyChainSelector);
        assertEq(strategyState.protocolId, emittedStrategyProtocolId);
    }

    function test_yield_rebalancer_onReport_rebalanceParentToParent() public {
        /// @dev Arrange: Strategy on Parent, deposit to have TVL
        _selectFork(baseFork);
        deal(address(baseUsdc), depositor, DEPOSIT_AMOUNT);

        _changePrank(depositor);
        baseUsdc.approve(address(baseParentPeer), DEPOSIT_AMOUNT);
        baseParentPeer.deposit(USDC_ID, DEPOSIT_AMOUNT);

        // Create workflow report
        IYieldPeer.Strategy memory newStrategy = IYieldPeer.Strategy({
            protocolId: compoundV3ProtocolId, stablecoinId: USDC_ID, chainSelector: baseChainSelector
        });
        bytes memory encodedReport =
            WorkflowHelpers.createWorkflowReport(newStrategy.chainSelector, newStrategy.protocolId);

        // Cache TVL & strategy adapter for new protocol id for event assertion
        uint256 totalValue = baseParentPeer.getTotalValue();
        address newStrategyAdapter = baseParentPeer.getStrategyAdapter(newStrategy.protocolId);

        /// @dev Act
        _changePrank(keystoneForwarder);
        vm.recordLogs();
        baseRebalancer.onReport(workflowMetadata, encodedReport);

        // Get Strategy state after onReport
        IYieldPeer.Strategy memory strategyState = baseParentPeer.getStrategy();

        // Handle log for DepositToStrategy event
        bool depositToStrategyEventFound = false;
        address emittedStrategyAdapter;
        uint256 emittedValue;
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == depositToStrategyEvent) {
                depositToStrategyEventFound = true;
                emittedStrategyAdapter = address(uint160(uint256(logs[i].topics[1])));
                emittedValue = uint256(logs[i].topics[3]);
            }
        }

        /// @dev Assert
        assertTrue(depositToStrategyEventFound, "DepositToStrategy log not found");
        assertEq(strategyState.chainSelector, newStrategy.chainSelector);
        assertEq(strategyState.protocolId, newStrategy.protocolId);
        assertEq(emittedStrategyAdapter, newStrategyAdapter);
        assertEq(emittedValue, totalValue);
    }

    function test_yield_rebalancer_onReport_rebalanceParentToChild() public {
        /// @dev Arrange: Strategy on parent, deposit on parent to have TVL
        _selectFork(baseFork);
        deal(address(baseUsdc), depositor, DEPOSIT_AMOUNT);
        _changePrank(depositor);
        baseUsdc.approve(address(baseParentPeer), DEPOSIT_AMOUNT);
        baseParentPeer.deposit(USDC_ID, DEPOSIT_AMOUNT);

        // Create workflow report & cache TVL to verify in event
        IYieldPeer.Strategy memory newStrategy =
            IYieldPeer.Strategy({protocolId: aaveV3ProtocolId, stablecoinId: USDC_ID, chainSelector: optChainSelector});
        bytes memory encodedReport =
            WorkflowHelpers.createWorkflowReport(newStrategy.chainSelector, newStrategy.protocolId);
        uint256 totalValue = baseParentPeer.getTotalValue();

        /// @dev Act
        _changePrank(keystoneForwarder);
        vm.recordLogs();
        baseRebalancer.onReport(workflowMetadata, encodedReport);

        // Get Strategy state after onReport
        IYieldPeer.Strategy memory strategyState = baseParentPeer.getStrategy();

        // Handle log for CCIPMessageSent event
        bool ccipMessageSentEventFound = false;
        uint8 emittedTxType;
        uint256 emittedValue;
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == ccipMessageSentEvent) {
                ccipMessageSentEventFound = true;
                emittedTxType = uint8(uint256(logs[i].topics[2]));
                emittedValue = uint256(logs[i].topics[3]);
            }
        }

        /// @dev Assert: Check for CCIPMessageSent event with correct tx type and value
        /// @dev Tx type should be RebalanceNewStrategy as strategy is moving
        /// @dev from Parent > Child and handled by ParentPeer::_rebalanceParentToChild
        assertTrue(ccipMessageSentEventFound, "CCIPMessageSent log not found");
        assertEq(strategyState.chainSelector, newStrategy.chainSelector);
        assertEq(strategyState.protocolId, newStrategy.protocolId);
        assertEq(emittedTxType, rebalanceNewStrategyTxType);
        assertEq(emittedValue, totalValue);
    }

    function test_yield_rebalancer_onReport_rebalanceChildToOther() public {
        /// @dev Arrange: Change Strategy to be on a Child (eth child)
        _setStrategy(ethChainSelector, aaveV3ProtocolId, SET_CROSS_CHAIN);

        // Create workflow report
        IYieldPeer.Strategy memory newStrategy =
            IYieldPeer.Strategy({protocolId: aaveV3ProtocolId, stablecoinId: USDC_ID, chainSelector: optChainSelector});
        bytes memory encodedReport =
            WorkflowHelpers.createWorkflowReport(newStrategy.chainSelector, newStrategy.protocolId);

        /// @dev Act
        _selectFork(baseFork);
        _changePrank(keystoneForwarder);
        vm.recordLogs();
        baseRebalancer.onReport(workflowMetadata, encodedReport);

        // Get Strategy state after onReport
        IYieldPeer.Strategy memory strategyState = baseParentPeer.getStrategy();

        // Handle log for CCIPMessageSent event
        bool ccipMessageSentEventFound = false;
        uint8 emittedTxType;
        uint256 emittedValue;
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == ccipMessageSentEvent) {
                ccipMessageSentEventFound = true;
                emittedTxType = uint8(uint256(logs[i].topics[2]));
                emittedValue = uint256(logs[i].topics[3]);
            }
        }

        /// @dev Assert: Check for CCIPMessageSent event with correct tx type
        /// @dev Tx type should be RebalanceOldStrategy as strategy is moving
        /// @dev from Child > Other (Child) and handled by ParentPeer::_rebalanceChildToOther
        assertTrue(ccipMessageSentEventFound, "CCIPMessageSent log not found");
        assertEq(strategyState.chainSelector, newStrategy.chainSelector);
        assertEq(strategyState.protocolId, newStrategy.protocolId);
        assertEq(emittedTxType, rebalanceOldStrategyTxType);
        assertEq(emittedValue, 0); // No value is sent as TVL is not on Parent
    }
}
