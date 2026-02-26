// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test, Vm} from "forge-std/Test.sol";
import {IYieldPeer} from "../../../src/interfaces/IYieldPeer.sol";
import {Ghosts} from "./Ghosts.t.sol";

/// @notice Event signatures for all events in the Yieldcoin system
/// @notice Internal functions to handle logs and update event ghost state
/// @dev Inherits Ghosts to access and update ghost variables based on emitted events
/// @dev Updates event ghosts only — no assertions, no state ghost updates
abstract contract Events is Test, Ghosts {
    /*//////////////////////////////////////////////////////////////
                               YIELDPEER
    //////////////////////////////////////////////////////////////*/
    bytes32 internal constant yieldPeer_AllowedChainSet_event = keccak256("AllowedChainSet(uint64,bool)");
    bytes32 internal constant yieldPeer_AllowedPeerSet_event = keccak256("AllowedPeerSet(uint64,address)");
    bytes32 internal constant yieldPeer_CCIPGasLimitSet_event = keccak256("CCIPGasLimitSet(uint256)");
    bytes32 internal constant yieldPeer_StrategyRegistrySet_event = keccak256("StrategyRegistrySet(address)");
    bytes32 internal constant yieldPeer_ActiveStrategyAdapterUpdated_event =
        keccak256("ActiveStrategyAdapterUpdated(address)");
    bytes32 internal constant yieldPeer_DepositToStrategy_event = keccak256("DepositToStrategy(address,uint256)");
    bytes32 internal constant yieldPeer_WithdrawFromStrategy_event = keccak256("WithdrawFromStrategy(address,uint256)");
    bytes32 internal constant yieldPeer_DepositInitiated_event = keccak256("DepositInitiated(address,uint256,uint64)");
    bytes32 internal constant yieldPeer_WithdrawInitiated_event =
        keccak256("WithdrawInitiated(address,uint256,uint64)");
    bytes32 internal constant yieldPeer_WithdrawCompleted_event = keccak256("WithdrawCompleted(address,uint256)");
    bytes32 internal constant yieldPeer_CCIPMessageSent_event = keccak256("CCIPMessageSent(bytes32,uint8,uint256)");
    bytes32 internal constant yieldPeer_CCIPMessageReceived_event =
        keccak256("CCIPMessageReceived(bytes32,uint8,uint64)");
    bytes32 internal constant yieldPeer_SharesMinted_event = keccak256("SharesMinted(address,uint256)");
    bytes32 internal constant yieldPeer_SharesBurned_event = keccak256("SharesBurned(address,uint256)");

    /*//////////////////////////////////////////////////////////////
                                 PARENT
    //////////////////////////////////////////////////////////////*/
    bytes32 internal constant parent_StrategyUpdated_event = keccak256("StrategyUpdated(uint64,bytes32,uint64)");
    bytes32 internal constant parent_ShareMintUpdate_event = keccak256("ShareMintUpdate(uint256,uint64,uint256)");
    bytes32 internal constant parent_ShareBurnUpdate_event = keccak256("ShareBurnUpdate(uint256,uint64,uint256)");
    bytes32 internal constant parent_DepositForwardedToStrategy_event =
        keccak256("DepositForwardedToStrategy(uint256,uint64)");
    bytes32 internal constant parent_WithdrawForwardedToStrategy_event =
        keccak256("WithdrawForwardedToStrategy(uint256,uint64)");
    bytes32 internal constant parent_DepositPingPongToChild_event = keccak256("DepositPingPongToChild(uint256,uint64)");
    bytes32 internal constant parent_WithdrawPingPongToChild_event =
        keccak256("WithdrawPingPongToChild(uint256,uint64)");
    bytes32 internal constant parent_RebalancerSet_event = keccak256("RebalancerSet(address)");
    bytes32 internal constant parent_SupportedProtocolSet_event = keccak256("SupportedProtocolSet(bytes32,bool)");

    /*//////////////////////////////////////////////////////////////
                                 CHILD
    //////////////////////////////////////////////////////////////*/
    bytes32 internal constant child_DepositPingPongToParent_event = keccak256("DepositPingPongToParent(uint256)");
    bytes32 internal constant child_WithdrawPingPongToParent_event = keccak256("WithdrawPingPongToParent(uint256)");

    /*//////////////////////////////////////////////////////////////
                               REBALANCER
    //////////////////////////////////////////////////////////////*/
    bytes32 internal constant rebalancer_ReportDecoded_event = keccak256("ReportDecoded(uint64,bytes32)");
    bytes32 internal constant rebalancer_ParentPeerSet_event = keccak256("ParentPeerSet(address)");
    bytes32 internal constant rebalancer_StrategyRegistrySet_event = keccak256("StrategyRegistrySet(address)");

    /*//////////////////////////////////////////////////////////////
                           STRATEGY REGISTRY
    //////////////////////////////////////////////////////////////*/
    bytes32 internal constant strategyRegistry_StrategyAdapterSet_event =
        keccak256("StrategyAdapterSet(bytes32,address)");

    /*//////////////////////////////////////////////////////////////
                            STRATEGY ADAPTER
    //////////////////////////////////////////////////////////////*/
    bytes32 internal constant strategyAdapter_Deposit_event = keccak256("Deposit(address,uint256)");
    bytes32 internal constant strategyAdapter_Withdraw_event = keccak256("Withdraw(address,uint256)");

    /*//////////////////////////////////////////////////////////////
                               YIELDFEES
    //////////////////////////////////////////////////////////////*/
    bytes32 internal constant yieldFees_FeeRateSet_event = keccak256("FeeRateSet(uint256)");
    bytes32 internal constant yieldFees_FeeTaken_event = keccak256("FeeTaken(uint256)");
    bytes32 internal constant yieldFees_FeesWithdrawn_event = keccak256("FeesWithdrawn(uint256)");

    /*//////////////////////////////////////////////////////////////
                              CRE RECEIVER
    //////////////////////////////////////////////////////////////*/
    bytes32 internal constant creReceiver_OnReportSecurityChecksPassed_event =
        keccak256("OnReportSecurityChecksPassed(bytes32,address,bytes10)");
    bytes32 internal constant creReceiver_KeystoneForwarderSet_event = keccak256("KeystoneForwarderSet(address)");
    bytes32 internal constant creReceiver_WorkflowSet_event = keccak256("WorkflowSet(bytes32,address,bytes10)");
    bytes32 internal constant creReceiver_WorkflowRemoved_event = keccak256("WorkflowRemoved(bytes32,address,bytes10)");

    /*//////////////////////////////////////////////////////////////
                              LOG HANDLING
    //////////////////////////////////////////////////////////////*/
    function _handleLogs() internal {
        Vm.Log[] memory logs = vm.getRecordedLogs();
        _handleDepositLogs(logs);
        _handleWithdrawLogs(logs);
        _handleRebalanceLogs(logs);
        _handleCrosschainLogs(logs);
        _handleFeeAndAdminLogs(logs);
    }

    function _handleDepositLogs(Vm.Log[] memory logs) internal {
        for (uint256 i = 0; i < logs.length; i++) {
            bytes32 sig = logs[i].topics[0];
            if (sig == yieldPeer_DepositInitiated_event) {
                ghost_yieldPeer_event_DepositInitiated_emissions++;
                ghost_yieldPeer_event_DepositInitiated_param_depositor = address(uint160(uint256(logs[i].topics[1])));
                ghost_yieldPeer_event_DepositInitiated_param_amount = uint256(logs[i].topics[2]);
                ghost_yieldPeer_event_DepositInitiated_param_chainSelector = uint64(uint256(logs[i].topics[3]));
                ghost_yieldPeer_event_DepositInitiated_param_amount_totalSum += ghost_yieldPeer_event_DepositInitiated_param_amount;
            }
            if (sig == yieldPeer_DepositToStrategy_event) {
                ghost_yieldPeer_event_DepositToStrategy_emissions++;
                ghost_yieldPeer_event_DepositToStrategy_param_strategyAdapter =
                    address(uint160(uint256(logs[i].topics[1])));
                ghost_yieldPeer_event_DepositToStrategy_param_amount = uint256(logs[i].topics[2]);
                ghost_yieldPeer_event_DepositToStrategy_param_amount_totalSum += ghost_yieldPeer_event_DepositToStrategy_param_amount;
            }
            if (sig == yieldPeer_SharesMinted_event) {
                ghost_yieldPeer_event_SharesMinted_emissions++;
                ghost_yieldPeer_event_SharesMinted_param_to = address(uint160(uint256(logs[i].topics[1])));
                ghost_yieldPeer_event_SharesMinted_param_amount = uint256(logs[i].topics[2]);
                ghost_yieldPeer_event_SharesMinted_param_amount_totalSum += ghost_yieldPeer_event_SharesMinted_param_amount;
            }
            if (sig == parent_ShareMintUpdate_event) {
                ghost_parent_event_ShareMintUpdate_emissions++;
                ghost_parent_event_ShareMintUpdate_param_amount = uint256(logs[i].topics[1]);
                ghost_parent_event_ShareMintUpdate_param_chainSelector = uint64(uint256(logs[i].topics[2]));
                ghost_parent_event_ShareMintUpdate_param_amount_totalSum += ghost_parent_event_ShareMintUpdate_param_amount;
                // @review ghost_totalSharesMinted makes more sense, but ghost_parent_event_ShareMintUpdate_param_amount_totalSum fits formatting with other event ghosts
                ghost_totalSharesMinted = ghost_parent_event_ShareMintUpdate_param_amount_totalSum;
            }
            if (sig == parent_DepositForwardedToStrategy_event) {
                ghost_parent_event_DepositForwardedToStrategy_emissions++;
                ghost_parent_event_DepositForwardedToStrategy_param_amount = uint256(logs[i].topics[1]);
                ghost_parent_event_DepositForwardedToStrategy_param_chainSelector = uint64(uint256(logs[i].topics[2]));
                ghost_parent_event_DepositForwardedToStrategy_param_amount_totalSum += ghost_parent_event_DepositForwardedToStrategy_param_amount;
            }
            if (sig == parent_DepositPingPongToChild_event) {
                ghost_parent_event_DepositPingPongToChild_emissions++;
                ghost_parent_event_DepositPingPongToChild_param_amount = uint256(logs[i].topics[1]);
                ghost_parent_event_DepositPingPongToChild_param_chainSelector = uint64(uint256(logs[i].topics[2]));
                ghost_parent_event_DepositPingPongToChild_param_amount_totalSum += ghost_parent_event_DepositPingPongToChild_param_amount;
            }
            if (sig == child_DepositPingPongToParent_event) {
                ghost_child_event_DepositPingPongToParent_emissions++;
                ghost_child_event_DepositPingPongToParent_param_amount = uint256(logs[i].topics[1]);
                ghost_child_event_DepositPingPongToParent_param_amount_totalSum += ghost_child_event_DepositPingPongToParent_param_amount;
            }
            if (sig == strategyAdapter_Deposit_event) {
                ghost_strategyAdapter_event_Deposit_emissions++;
                ghost_strategyAdapter_event_Deposit_param_usdc = address(uint160(uint256(logs[i].topics[1])));
                ghost_strategyAdapter_event_Deposit_param_amount = uint256(logs[i].topics[2]);
                ghost_strategyAdapter_event_Deposit_param_amount_totalSum += ghost_strategyAdapter_event_Deposit_param_amount;
            }
        }
    }

    function _handleWithdrawLogs(Vm.Log[] memory logs) internal {
        for (uint256 i = 0; i < logs.length; i++) {
            bytes32 sig = logs[i].topics[0];
            if (sig == yieldPeer_WithdrawInitiated_event) {
                ghost_yieldPeer_event_WithdrawInitiated_emissions++;
                ghost_yieldPeer_event_WithdrawInitiated_param_withdrawer = address(uint160(uint256(logs[i].topics[1])));
                ghost_yieldPeer_event_WithdrawInitiated_param_amount = uint256(logs[i].topics[2]);
                ghost_yieldPeer_event_WithdrawInitiated_param_chainSelector = uint64(uint256(logs[i].topics[3]));
                ghost_yieldPeer_event_WithdrawInitiated_param_amount_totalSum += ghost_yieldPeer_event_WithdrawInitiated_param_amount;
            }
            if (sig == yieldPeer_WithdrawFromStrategy_event) {
                address adapter = address(uint160(uint256(logs[i].topics[1])));
                uint256 amount = uint256(logs[i].topics[2]);
                ghost_yieldPeer_event_WithdrawFromStrategy_emissions++;
                ghost_yieldPeer_event_WithdrawFromStrategy_param_strategyAdapter = adapter;
                ghost_yieldPeer_event_WithdrawFromStrategy_param_amount = amount;
                /// @dev MAX sentinel signals a full rebalance withdrawal — exclude from totalSum to prevent overflow
                /// @notice YieldPeer::WithdrawFromStrategy DOES emit the max sentinel amount before actually withdrawing
                /// @notice to get the actual withdrawn amount, read the StrategyAdapter::Withdraw event `amount` param
                if (amount == type(uint256).max) {
                    ghost_yieldPeer_event_WithdrawFromStrategy_rebalance_emissions++;
                    ghost_yieldPeer_event_WithdrawFromStrategy_rebalance_param_strategyAdapter = adapter;
                } else {
                    ghost_yieldPeer_event_WithdrawFromStrategy_param_amount_totalSum += amount;
                }
            }
            if (sig == yieldPeer_WithdrawCompleted_event) {
                ghost_yieldPeer_event_WithdrawCompleted_emissions++;
                ghost_yieldPeer_event_WithdrawCompleted_param_withdrawer = address(uint160(uint256(logs[i].topics[1])));
                ghost_yieldPeer_event_WithdrawCompleted_param_amount = uint256(logs[i].topics[2]);
                ghost_yieldPeer_event_WithdrawCompleted_param_amount_totalSum += ghost_yieldPeer_event_WithdrawCompleted_param_amount;
            }
            if (sig == yieldPeer_SharesBurned_event) {
                ghost_yieldPeer_event_SharesBurned_emissions++;
                ghost_yieldPeer_event_SharesBurned_param_from = address(uint160(uint256(logs[i].topics[1])));
                ghost_yieldPeer_event_SharesBurned_param_amount = uint256(logs[i].topics[2]);
                ghost_yieldPeer_event_SharesBurned_param_amount_totalSum += ghost_yieldPeer_event_SharesBurned_param_amount;
            }
            if (sig == parent_ShareBurnUpdate_event) {
                ghost_parent_event_ShareBurnUpdate_emissions++;
                ghost_parent_event_ShareBurnUpdate_param_amount = uint256(logs[i].topics[1]);
                ghost_parent_event_ShareBurnUpdate_param_chainSelector = uint64(uint256(logs[i].topics[2]));
                ghost_parent_event_ShareBurnUpdate_param_amount_totalSum += ghost_parent_event_ShareBurnUpdate_param_amount;
            }
            if (sig == parent_WithdrawForwardedToStrategy_event) {
                ghost_parent_event_WithdrawForwardedToStrategy_emissions++;
                ghost_parent_event_WithdrawForwardedToStrategy_param_amount = uint256(logs[i].topics[1]);
                ghost_parent_event_WithdrawForwardedToStrategy_param_chainSelector = uint64(uint256(logs[i].topics[2]));
                ghost_parent_event_WithdrawForwardedToStrategy_param_amount_totalSum += ghost_parent_event_WithdrawForwardedToStrategy_param_amount;
            }
            if (sig == parent_WithdrawPingPongToChild_event) {
                ghost_parent_event_WithdrawPingPongToChild_emissions++;
                ghost_parent_event_WithdrawPingPongToChild_param_amount = uint256(logs[i].topics[1]);
                ghost_parent_event_WithdrawPingPongToChild_param_chainSelector = uint64(uint256(logs[i].topics[2]));
                ghost_parent_event_WithdrawPingPongToChild_param_amount_totalSum += ghost_parent_event_WithdrawPingPongToChild_param_amount;
            }
            if (sig == child_WithdrawPingPongToParent_event) {
                ghost_child_event_WithdrawPingPongToParent_emissions++;
                ghost_child_event_WithdrawPingPongToParent_param_amount = uint256(logs[i].topics[1]);
                ghost_child_event_WithdrawPingPongToParent_param_amount_totalSum += ghost_child_event_WithdrawPingPongToParent_param_amount;
            }
            if (sig == strategyAdapter_Withdraw_event) {
                ghost_strategyAdapter_event_Withdraw_emissions++;
                ghost_strategyAdapter_event_Withdraw_param_usdc = address(uint160(uint256(logs[i].topics[1])));
                ghost_strategyAdapter_event_Withdraw_param_amount = uint256(logs[i].topics[2]);
                ghost_strategyAdapter_event_Withdraw_param_amount_totalSum += ghost_strategyAdapter_event_Withdraw_param_amount;
            }
        }
    }

    function _handleRebalanceLogs(Vm.Log[] memory logs) internal {
        for (uint256 i = 0; i < logs.length; i++) {
            bytes32 sig = logs[i].topics[0];
            if (sig == parent_StrategyUpdated_event) {
                ghost_parent_event_StrategyUpdated_emissions++;
                ghost_parent_event_StrategyUpdated_param_chainSelector = uint64(uint256(logs[i].topics[1]));
                ghost_parent_event_StrategyUpdated_param_protocolId = logs[i].topics[2];
                ghost_parent_event_StrategyUpdated_param_oldChainSelector = uint64(uint256(logs[i].topics[3]));
            }
            if (sig == rebalancer_ReportDecoded_event) {
                ghost_rebalancer_event_ReportDecoded_emissions++;
                ghost_rebalancer_event_ReportDecoded_param_chainSelector = uint64(uint256(logs[i].topics[1]));
                ghost_rebalancer_event_ReportDecoded_param_protocolId = logs[i].topics[2];
            }
            if (sig == creReceiver_OnReportSecurityChecksPassed_event) {
                ghost_creReceiver_event_OnReportSecurityChecksPassed_emissions++;
                ghost_creReceiver_event_OnReportSecurityChecksPassed_param_workflowId = logs[i].topics[1];
                ghost_creReceiver_event_OnReportSecurityChecksPassed_param_workflowOwner =
                    address(uint160(uint256(logs[i].topics[2])));
                ghost_creReceiver_event_OnReportSecurityChecksPassed_param_workflowName = bytes10(logs[i].topics[3]);
            }
        }
    }

    function _handleCrosschainLogs(Vm.Log[] memory logs) internal {
        for (uint256 i = 0; i < logs.length; i++) {
            bytes32 sig = logs[i].topics[0];
            if (sig == yieldPeer_CCIPMessageSent_event) {
                ghost_yieldPeer_event_CCIPMessageSent_emissions++;
                ghost_yieldPeer_event_CCIPMessageSent_param_messageId = logs[i].topics[1];
                ghost_yieldPeer_event_CCIPMessageSent_param_txType =
                    IYieldPeer.CcipTxType(uint8(uint256(logs[i].topics[2])));
                ghost_yieldPeer_event_CCIPMessageSent_param_amount = uint256(logs[i].topics[3]);
                ghost_yieldPeer_event_CCIPMessageSent_param_amount_totalSum += ghost_yieldPeer_event_CCIPMessageSent_param_amount;
            }
            if (sig == yieldPeer_CCIPMessageReceived_event) {
                ghost_yieldPeer_event_CCIPMessageReceived_emissions++;
                ghost_yieldPeer_event_CCIPMessageReceived_param_messageId = logs[i].topics[1];
                ghost_yieldPeer_event_CCIPMessageReceived_param_txType =
                    IYieldPeer.CcipTxType(uint8(uint256(logs[i].topics[2])));
                ghost_yieldPeer_event_CCIPMessageReceived_param_sourceChainSelector = uint64(uint256(logs[i].topics[3]));
            }
        }
    }

    function _handleFeeAndAdminLogs(Vm.Log[] memory logs) internal {
        for (uint256 i = 0; i < logs.length; i++) {
            bytes32 sig = logs[i].topics[0];
            if (sig == yieldFees_FeeRateSet_event) {
                ghost_yieldFees_event_FeeRateSet_emissions++;
                ghost_yieldFees_event_FeeRateSet_param_feeRate = uint256(logs[i].topics[1]);
            }
            if (sig == yieldFees_FeeTaken_event) {
                ghost_yieldFees_event_FeeTaken_emissions++;
                ghost_yieldFees_event_FeeTaken_param_amount = uint256(logs[i].topics[1]);
                ghost_yieldFees_event_FeeTaken_param_amount_totalSum += ghost_yieldFees_event_FeeTaken_param_amount;
            }
            if (sig == yieldFees_FeesWithdrawn_event) {
                ghost_yieldFees_event_FeesWithdrawn_emissions++;
                ghost_yieldFees_event_FeesWithdrawn_param_amount = uint256(logs[i].topics[1]);
                ghost_yieldFees_event_FeesWithdrawn_param_amount_totalSum += ghost_yieldFees_event_FeesWithdrawn_param_amount;
            }
            if (sig == creReceiver_KeystoneForwarderSet_event) {
                ghost_creReceiver_event_KeystoneForwarderSet_emissions++;
                ghost_creReceiver_event_KeystoneForwarderSet_param_forwarder =
                    address(uint160(uint256(logs[i].topics[1])));
            }
            if (sig == creReceiver_WorkflowSet_event) {
                ghost_creReceiver_event_WorkflowSet_emissions++;
                ghost_creReceiver_event_WorkflowSet_param_workflowId = logs[i].topics[1];
                ghost_creReceiver_event_WorkflowSet_param_workflowOwner = address(uint160(uint256(logs[i].topics[2])));
                ghost_creReceiver_event_WorkflowSet_param_workflowName = bytes10(logs[i].topics[3]);
            }
            if (sig == creReceiver_WorkflowRemoved_event) {
                ghost_creReceiver_event_WorkflowRemoved_emissions++;
                ghost_creReceiver_event_WorkflowRemoved_param_workflowId = logs[i].topics[1];
                ghost_creReceiver_event_WorkflowRemoved_param_workflowOwner =
                    address(uint160(uint256(logs[i].topics[2])));
                ghost_creReceiver_event_WorkflowRemoved_param_workflowName = bytes10(logs[i].topics[3]);
            }
        }
    }

    /// @dev empty test to ignore in coverage report
    function test_emptyTest() public virtual {}
}
