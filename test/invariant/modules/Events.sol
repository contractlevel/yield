// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ghosts} from "./Ghosts.sol";

/// @notice Signatures for all events in the Yieldcoin system, as well as internal functions to handle logs and update ghost state
/// @dev These are used to track events in the system for invariant testing
/// @notice This should be updated when events in the system are updated
/// @dev This contract inherits from the Ghosts contract to access ghost state and update it based on events
contract Events is Ghosts {
    /*//////////////////////////////////////////////////////////////
                               YIELDPEER
    //////////////////////////////////////////////////////////////*/
    bytes internal yieldPeer_AllowedChainSet_event = keccak256("AllowedChainSet(uint64,bool)");
    bytes internal yieldPeer_AllowedPeerSet_event = keccak256("AllowedPeerSet(uint64,address)");
    bytes internal yieldPeer_CCIPGasLimitSet_event = keccak256("CCIPGasLimitSet(uint256)");
    bytes internal yieldPeer_StrategyRegistrySet_event = keccak256("StrategyRegistrySet(address)");
    bytes internal yieldPeer_ActiveStrategyAdapterUpdated_event = keccak256("ActiveStrategyAdapterUpdated(address)");
    bytes internal yieldPeer_DepositToStrategy_event = keccak256("DepositToStrategy(address,uint256)");
    bytes internal yieldPeer_WithdrawFromStrategy_event = keccak256("WithdrawFromStrategy(address,uint256)");
    bytes internal yieldPeer_DepositInitiated_event = keccak256("DepositInitiated(address,uint256,uint64)");
    bytes internal yieldPeer_WithdrawInitiated_event = keccak256("WithdrawInitiated(address,uint256,uint64)");
    bytes internal yieldPeer_WithdrawCompleted_event = keccak256("WithdrawCompleted(address,uint256)");
    bytes internal yieldPeer_CCIPMessageSent_event = keccak256("CCIPMessageSent(bytes32,uint8,uint256)");
    bytes internal yieldPeer_CCIPMessageReceived_event = keccak256("CCIPMessageReceived(bytes32,uint8,uint64)");
    bytes internal yieldPeer_SharesMinted_event = keccak256("SharesMinted(address,uint256)");
    bytes internal yieldPeer_SharesBurned_event = keccak256("SharesBurned(address,uint256)");

    /*//////////////////////////////////////////////////////////////
                                 PARENT
    //////////////////////////////////////////////////////////////*/
    bytes internal parent_StrategyUpdated_event = keccak256("StrategyUpdated(uint64,bytes32,uint64)");
    bytes internal parent_ShareMintUpdate_event = keccak256("ShareMintUpdate(uint256,uint64,uint256)");
    bytes internal parent_ShareBurnUpdate_event = keccak256("ShareBurnUpdate(uint256,uint64,uint256)");
    bytes internal parent_DepositForwardedToStrategy_event = keccak256("DepositForwardedToStrategy(uint256,uint64)");
    bytes internal parent_WithdrawForwardedToStrategy_event = keccak256("WithdrawForwardedToStrategy(uint256,uint64)");
    bytes internal parent_DepositPingPongToChild_event = keccak256("DepositPingPongToChild(uint256,uint64)");
    bytes internal parent_WithdrawPingPongToChild_event = keccak256("WithdrawPingPongToChild(uint256,uint64)");
    bytes internal parent_RebalancerSet_event = keccak256("RebalancerSet(address)");
    bytes internal parent_SupportedProtocolSet_event = keccak256("SupportedProtocolSet(bytes32,bool)");

    /*//////////////////////////////////////////////////////////////
                                 CHILD
    //////////////////////////////////////////////////////////////*/
    bytes internal child_DepositPingPongToParent_event = keccak256("DepositPingPongToParent(uint256)");
    bytes internal child_WithdrawPingPongToParent_event = keccak256("WithdrawPingPongToParent(uint256)");

    /*//////////////////////////////////////////////////////////////
                               REBALANCER
    //////////////////////////////////////////////////////////////*/
    bytes internal rebalancer_ReportDecoded_event = keccak256("ReportDecoded(uint64,bytes32)");
    bytes internal rebalancer_ParentPeerSet_event = keccak256("ParentPeerSet(address)");
    bytes internal rebalancer_StrategyRegistrySet_event = keccak256("StrategyRegistrySet(address)");

    /*//////////////////////////////////////////////////////////////
                           STRATEGY REGISTRY
    //////////////////////////////////////////////////////////////*/
    bytes internal strategyRegistry_StrategyAdapterSet_event = keccak256("StrategyAdapterSet(bytes32,address)");

    /*//////////////////////////////////////////////////////////////
                            STRATEGY ADAPTER
    //////////////////////////////////////////////////////////////*/
    bytes internal strategyAdapter_Deposit_event = keccak256("Deposit(address,uint256)");
    bytes internal strategyAdapter_Withdraw_event = keccak256("Withdraw(address,uint256)");

    /*//////////////////////////////////////////////////////////////
                               YIELDFEES
    //////////////////////////////////////////////////////////////*/
    bytes internal yieldFees_FeeRateSet_event = keccak256("FeeRateSet(uint256)");
    bytes internal yieldFees_FeeTaken_event = keccak256("FeeTaken(uint256)");
    bytes internal yieldFees_FeesWithdrawn_event = keccak256("FeesWithdrawn(uint256)");

    /*//////////////////////////////////////////////////////////////
                              CRE RECEIVER
    //////////////////////////////////////////////////////////////*/
    bytes internal creReceiver_OnReportSecurityChecksPassed_event =
        keccak256("OnReportSecurityChecksPassed(bytes32,address,bytes10)");
    bytes internal creReceiver_KeystoneForwarderSet_event = keccak256("KeystoneForwarderSet(address)");
    bytes internal creReceiver_WorkflowSet_event = keccak256("WorkflowSet(bytes32,address,bytes10)");
    bytes internal creReceiver_WorkflowRemoved_event = keccak256("WorkflowRemoved(bytes32,address,bytes10)");

    /*//////////////////////////////////////////////////////////////
                              LOG HANDLING
    //////////////////////////////////////////////////////////////*/
    function _handleLogs() internal {
        Vm.Log[] memory logs = vm.getRecordedLogs();
        _handleDepositLogs(logs);
        _handleWithdrawLogs(logs);
        _handleRebalanceLogs(logs);
        _handleCrosschainLogs(logs);
    }

    function _handleDepositLogs(Vm.Log[] memory logs) internal {
        for (uint256 i = 0; i < logs.length; i++) {
            bytes eventSignature = logs[i].topics[0];
            if (eventSignature == yieldPeer_DepositInitiated_event) {
                ghost_yieldPeer_event_DepositInitiated_emissions++;
                address depositor = address(uint160(uint256(logs[i].topics[1])));
                uint256 amount = uint256(logs[i].topics[2]);
                uint256 chainSelector = uint256(logs[i].topics[3]);
                ghost_yieldPeer_event_DepositInitiated_param_depositor = depositor;
                ghost_yieldPeer_event_DepositInitiated_param_amount = amount;
                ghost_yieldPeer_event_DepositInitiated_param_chainSelector = chainSelector;
                ghost_yieldPeer_event_DepositInitiated_param_amount_totalSum += amount;
            }
            if (eventSignature == yieldPeer_DepositToStrategy_event) {
                ghost_yieldPeer_event_DepositToStrategy_emissions++;
                address strategyAdapter = address(uint160(uint256(logs[i].topics[1])));
                uint256 amount = uint256(logs[i].topics[2]);
                ghost_yieldPeer_event_DepositToStrategy_param_strategyAdapter = strategyAdapter;
                ghost_yieldPeer_event_DepositToStrategy_param_amount = amount;
                ghost_yieldPeer_event_DepositToStrategy_param_amount_totalSum += amount;
            }
            if (eventSignature == yieldPeer_SharesMinted_event) {
                ghost_yieldPeer_event_SharesMinted_emissions++;
                address to = address(uint160(uint256(logs[i].topics[1])));
                uint256 amount = uint256(logs[i].topics[2]);
                ghost_yieldPeer_event_SharesMinted_param_to = to;
                ghost_yieldPeer_event_SharesMinted_param_amount = amount;
                ghost_yieldPeer_event_SharesMinted_param_amount_totalSum += amount;
            }
            if (eventSignature == parent_ShareMintUpdate_event) {
                ghost_parent_event_ShareMintUpdate_emissions++;
                uint256 amount = uint256(logs[i].topics[1]);
                uint256 chainSelector = uint256(logs[i].topics[2]);
                ghost_parent_event_ShareMintUpdate_param_amount = amount;
                ghost_parent_event_ShareMintUpdate_param_chainSelector = chainSelector;
                ghost_parent_event_ShareMintUpdate_param_amount_totalSum += amount;
            }
            if (eventSignature == parent_DepositForwardedToStrategy_event) {
                ghost_parent_event_DepositForwardedToStrategy_emissions++;
                uint256 amount = uint256(logs[i].topics[1]);
                uint256 chainSelector = uint256(logs[i].topics[2]);
                ghost_parent_event_DepositForwardedToStrategy_param_amount = amount;
                ghost_parent_event_DepositForwardedToStrategy_param_chainSelector = chainSelector;
                ghost_parent_event_DepositForwardedToStrategy_param_amount_totalSum += amount;
            }
            if (eventSignature == parent_DepositPingPongToChild_event) {
                ghost_parent_event_DepositPingPongToChild_emissions++;
                uint256 amount = uint256(logs[i].topics[1]);
                uint256 chainSelector = uint256(logs[i].topics[2]);
                ghost_parent_event_DepositPingPongToChild_param_amount = amount;
                ghost_parent_event_DepositPingPongToChild_param_chainSelector = chainSelector;
                ghost_parent_event_DepositPingPongToChild_param_amount_totalSum += amount;
            }
            if (eventSignature == child_DepositPingPongToParent_event) {
                ghost_child_event_DepositPingPongToParent_emissions++;
                uint256 amount = uint256(logs[i].topics[1]);
                ghost_child_event_DepositPingPongToParent_param_amount = amount;
                ghost_child_event_DepositPingPongToParent_param_amount_totalSum += amount;
            }
        }
    }

    function _handleWithdrawLogs(Vm.Log[] memory logs) internal {
        for (uint256 i = 0; i < logs.length; i++) {
            bytes eventSignature = logs[i].topics[0];
            if (eventSignature == yieldPeer_WithdrawInitiated_event) {
                ghost_yieldPeer_event_WithdrawInitiated_emissions++;
                address withdrawer = address(uint160(uint256(logs[i].topics[1])));
                uint256 amount = uint256(logs[i].topics[2]);
                uint256 chainSelector = uint256(logs[i].topics[3]);
                ghost_yieldPeer_event_WithdrawInitiated_param_withdrawer = withdrawer;
                ghost_yieldPeer_event_WithdrawInitiated_param_amount = amount;
                ghost_yieldPeer_event_WithdrawInitiated_param_chainSelector = chainSelector;
                ghost_yieldPeer_event_WithdrawInitiated_param_amount_totalSum += amount;
            }
            if (eventSignature == yieldPeer_WithdrawFromStrategy_event) {
                ghost_yieldPeer_event_WithdrawFromStrategy_emissions++;
                address strategyAdapter = address(uint160(uint256(logs[i].topics[1])));
                uint256 amount = uint256(logs[i].topics[2]);
                ghost_yieldPeer_event_WithdrawFromStrategy_param_strategyAdapter = strategyAdapter;
                ghost_yieldPeer_event_WithdrawFromStrategy_param_amount = amount;
                ghost_yieldPeer_event_WithdrawFromStrategy_param_amount_totalSum += amount;
            }
            if (eventSignature == yieldPeer_WithdrawCompleted_event) {
                ghost_yieldPeer_event_WithdrawCompleted_emissions++;
                address withdrawer = address(uint160(uint256(logs[i].topics[1])));
                uint256 amount = uint256(logs[i].topics[2]);
                ghost_yieldPeer_event_WithdrawCompleted_param_withdrawer = withdrawer;
                ghost_yieldPeer_event_WithdrawCompleted_param_amount = amount;
                ghost_yieldPeer_event_WithdrawCompleted_param_amount_totalSum += amount;
            }
            if (eventSignature == yieldPeer_SharesBurned_event) {
                ghost_yieldPeer_event_SharesBurned_emissions++;
                address from = address(uint160(uint256(logs[i].topics[1])));
                uint256 amount = uint256(logs[i].topics[2]);
                ghost_yieldPeer_event_SharesBurned_param_from = from;
                ghost_yieldPeer_event_SharesBurned_param_amount = amount;
                ghost_yieldPeer_event_SharesBurned_param_amount_totalSum += amount;
            }
            if (eventSignature == parent_ShareBurnUpdate_event) {
                ghost_parent_event_ShareBurnUpdate_emissions++;
                uint256 amount = uint256(logs[i].topics[1]);
                uint256 chainSelector = uint256(logs[i].topics[2]);
                ghost_parent_event_ShareBurnUpdate_param_amount = amount;
                ghost_parent_event_ShareBurnUpdate_param_chainSelector = chainSelector;
                ghost_parent_event_ShareBurnUpdate_param_amount_totalSum += amount;
            }
            if (eventSignature == parent_WithdrawForwardedToStrategy_event) {
                ghost_parent_event_WithdrawForwardedToStrategy_emissions++;
                uint256 amount = uint256(logs[i].topics[1]);
                uint256 chainSelector = uint256(logs[i].topics[2]);
                ghost_parent_event_WithdrawForwardedToStrategy_param_amount = amount;
                ghost_parent_event_WithdrawForwardedToStrategy_param_chainSelector = chainSelector;
                ghost_parent_event_WithdrawForwardedToStrategy_param_amount_totalSum += amount;
            }
            if (eventSignature == parent_WithdrawPingPongToChild_event) {
                ghost_parent_event_WithdrawPingPongToChild_emissions++;
                uint256 amount = uint256(logs[i].topics[1]);
                uint256 chainSelector = uint256(logs[i].topics[2]);
                ghost_parent_event_WithdrawPingPongToChild_param_amount = amount;
                ghost_parent_event_WithdrawPingPongToChild_param_chainSelector = chainSelector;
                ghost_parent_event_WithdrawPingPongToChild_param_amount_totalSum += amount;
            }
            if (eventSignature == child_WithdrawPingPongToParent_event) {
                ghost_child_event_WithdrawPingPongToParent_emissions++;
                uint256 amount = uint256(logs[i].topics[1]);
                ghost_child_event_WithdrawPingPongToParent_param_amount = amount;
                ghost_child_event_WithdrawPingPongToParent_param_amount_totalSum += amount;
            }
        }
    }

    function _handleRebalanceLogs(Vm.Log[] memory logs) internal {
        for (uint256 i = 0; i < logs.length; i++) {
            bytes eventSignature = logs[i].topics[0];
            if (eventSignature == parent_StrategyUpdated_event) {
                ghost_parent_event_StrategyUpdated_emissions++;
                uint64 chainSelector = uint64(logs[i].topics[1]);
                bytes32 protocolId = bytes32(logs[i].topics[2]);
                uint64 oldChainSelector = uint64(logs[i].topics[3]);
                ghost_parent_event_StrategyUpdated_param_chainSelector = chainSelector;
                ghost_parent_event_StrategyUpdated_param_protocolId = protocolId;
                ghost_parent_event_StrategyUpdated_param_oldChainSelector = oldChainSelector;
            }
            if (eventSignature == rebalancer_ReportDecoded_event) {
                ghost_rebalancer_event_ReportDecoded_emissions++;
                uint64 chainSelector = uint64(logs[i].topics[1]);
                bytes32 protocolId = bytes32(logs[i].topics[2]);
                ghost_rebalancer_event_ReportDecoded_param_chainSelector = chainSelector;
                ghost_rebalancer_event_ReportDecoded_param_protocolId = protocolId;
            }
            /// @notice rebalancing should also emit DepositToStrategy and WithdrawFromStrategy events
        }
    }

    function _handleCrosschainLogs(Vm.Log[] memory logs) internal {}
}
