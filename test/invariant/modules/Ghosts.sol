// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @notice Ghost variables for the Yieldcoin invariant handler
/// @dev These are used to track state changes and event emissions in the system for invariant testing
abstract contract Ghosts {
    /*//////////////////////////////////////////////////////////////
                            YIELDPEER STATE
    //////////////////////////////////////////////////////////////*/
    /// @dev YieldPeer::s_ccipGasLimit
    uint256 public ghost_yieldPeer_state_ccipGasLimit;
    /// @dev YieldPeer::s_allowedChains
    mapping(uint64 chainSelector => bool isAllowed) public ghost_yieldPeer_state_allowedChains;
    /// @dev YieldPeer::s_peers
    mapping(uint64 chainSelector => address peer) public ghost_yieldPeer_state_peers;
    /// @dev YieldPeer::s_strategyRegistry
    address public ghost_yieldPeer_state_strategyRegistry;
    /// @dev YieldPeer::s_activeStrategyAdapter
    address public ghost_yieldPeer_state_activeStrategyAdapter;

    /*//////////////////////////////////////////////////////////////
                            YIELDPEER EVENTS
    //////////////////////////////////////////////////////////////*/
    // --- AllowedChainSet event --- //
    /// @dev incremented everytime an AllowedChainSet event is emitted
    uint256 public ghost_yieldPeer_event_AllowedChainSet_emissions;
    /// @dev the chain selector emitted by the AllowedChainSet event
    uint64 public ghost_yieldPeer_event_AllowedChainSet_param_chainSelector;
    /// @dev the isAllowed flag emitted by the AllowedChainSet event
    bool public ghost_yieldPeer_event_AllowedChainSet_param_isAllowed;

    // --- AllowedPeerSet event --- //
    /// @dev incremented everytime an AllowedPeerSet event is emitted
    uint256 public ghost_yieldPeer_event_AllowedPeerSet_emissions;
    /// @dev the chain selector emitted by the AllowedPeerSet event
    uint64 public ghost_yieldPeer_event_AllowedPeerSet_param_chainSelector;
    /// @dev the peer emitted by the AllowedPeerSet event
    address public ghost_yieldPeer_event_AllowedPeerSet_param_peer;

    // --- CCIPGasLimitSet event --- //
    /// @dev incremented everytime a CCIPGasLimitSet event is emitted
    uint256 public ghost_yieldPeer_event_CCIPGasLimitSet_emissions;
    /// @dev the gas limit emitted by the CCIPGasLimitSet event
    uint256 public ghost_yieldPeer_event_CCIPGasLimitSet_param_gasLimit;

    // --- StrategyRegistrySet event --- //
    /// @dev incremented everytime a StrategyRegistrySet event is emitted
    uint256 public ghost_yieldPeer_event_StrategyRegistrySet_emissions;
    /// @dev the strategy registry emitted by the StrategyRegistrySet event
    address public ghost_yieldPeer_event_StrategyRegistrySet_param_strategyRegistry;

    // --- ActiveStrategyAdapterUpdated event --- //
    /// @dev incremented everytime an ActiveStrategyAdapterUpdated event is emitted
    uint256 public ghost_yieldPeer_event_ActiveStrategyAdapterUpdated_emissions;
    /// @dev the active strategy adapter emitted by the ActiveStrategyAdapterUpdated event
    address public ghost_yieldPeer_event_ActiveStrategyAdapterUpdated_param_activeStrategyAdapter;

    // --- DepositToStrategy event --- //
    /// @dev incremented everytime a DepositToStrategy event is emitted
    uint256 public ghost_yieldPeer_event_DepositToStrategy_emissions;
    /// @dev the strategy adapter emitted by the DepositToStrategy event
    address public ghost_yieldPeer_event_DepositToStrategy_param_strategyAdapter;
    /// @dev the amount emitted by the DepositToStrategy event
    uint256 public ghost_yieldPeer_event_DepositToStrategy_param_amount;
    /// @dev the total sum of all amounts emitted by DepositToStrategy events
    uint256 public ghost_yieldPeer_event_DepositToStrategy_param_amount_totalSum;

    // --- WithdrawFromStrategy event --- //
    /// @dev incremented everytime a WithdrawFromStrategy event is emitted
    uint256 public ghost_yieldPeer_event_WithdrawFromStrategy_emissions;
    /// @dev the strategy adapter emitted by the WithdrawFromStrategy event
    address public ghost_yieldPeer_event_WithdrawFromStrategy_param_strategyAdapter;
    /// @dev the amount emitted by the WithdrawFromStrategy event
    uint256 public ghost_yieldPeer_event_WithdrawFromStrategy_param_amount;
    /// @dev the total sum of all amounts emitted by WithdrawFromStrategy events
    uint256 public ghost_yieldPeer_event_WithdrawFromStrategy_param_amount_totalSum;

    // --- DepositInitiated event --- //
    /// @dev incremented everytime a DepositInitiated event is emitted
    uint256 public ghost_yieldPeer_event_DepositInitiated_emissions;
    /// @dev the depositor emitted by the DepositInitiated event
    address public ghost_yieldPeer_event_DepositInitiated_param_depositor;
    /// @dev the amount emitted by the DepositInitiated event
    uint256 public ghost_yieldPeer_event_DepositInitiated_param_amount;
    /// @dev the chain selector emitted by the DepositInitiated event
    uint64 public ghost_yieldPeer_event_DepositInitiated_param_chainSelector;
    /// @dev the total sum of all amounts emitted by DepositInitiated events
    uint256 public ghost_yieldPeer_event_DepositInitiated_param_amount_totalSum;

    // --- WithdrawInitiated event --- //
    /// @dev incremented everytime a WithdrawInitiated event is emitted
    uint256 public ghost_yieldPeer_event_WithdrawInitiated_emissions;
    /// @dev the withdrawer emitted by the WithdrawInitiated event
    address public ghost_yieldPeer_event_WithdrawInitiated_param_withdrawer;
    /// @dev the amount emitted by the WithdrawInitiated event
    uint256 public ghost_yieldPeer_event_WithdrawInitiated_param_amount;
    /// @dev the chain selector emitted by the WithdrawInitiated event
    uint64 public ghost_yieldPeer_event_WithdrawInitiated_param_chainSelector;
    /// @dev the total sum of all amounts emitted by WithdrawInitiated events
    uint256 public ghost_yieldPeer_event_WithdrawInitiated_param_amount_totalSum;

    // --- WithdrawCompleted event --- //
    /// @dev incremented everytime a WithdrawCompleted event is emitted
    uint256 public ghost_yieldPeer_event_WithdrawCompleted_emissions;
    /// @dev the withdrawer emitted by the WithdrawCompleted event
    address public ghost_yieldPeer_event_WithdrawCompleted_param_withdrawer;
    /// @dev the amount emitted by the WithdrawCompleted event
    uint256 public ghost_yieldPeer_event_WithdrawCompleted_param_amount;
    /// @dev the total sum of all amounts emitted by WithdrawCompleted events
    uint256 public ghost_yieldPeer_event_WithdrawCompleted_param_amount_totalSum;

    // --- CCIPMessageSent event --- //
    /// @dev incremented everytime a CCIPMessageSent event is emitted
    uint256 public ghost_yieldPeer_event_CCIPMessageSent_emissions;
    /// @dev the message id emitted by the CCIPMessageSent event
    bytes32 public ghost_yieldPeer_event_CCIPMessageSent_param_messageId;
    /// @dev the tx type emitted by the CCIPMessageSent event
    CcipTxType public ghost_yieldPeer_event_CCIPMessageSent_param_txType;
    /// @dev the amount emitted by the CCIPMessageSent event
    uint256 public ghost_yieldPeer_event_CCIPMessageSent_param_amount;
    /// @dev the total sum of all amounts emitted by CCIPMessageSent events
    uint256 public ghost_yieldPeer_event_CCIPMessageSent_param_amount_totalSum;

    // --- CCIPMessageReceived event --- //
    /// @dev incremented everytime a CCIPMessageReceived event is emitted
    uint256 public ghost_yieldPeer_event_CCIPMessageReceived_emissions;
    /// @dev the message id emitted by the CCIPMessageReceived event
    bytes32 public ghost_yieldPeer_event_CCIPMessageReceived_param_messageId;
    /// @dev the tx type emitted by the CCIPMessageReceived event
    CcipTxType public ghost_yieldPeer_event_CCIPMessageReceived_param_txType;
    /// @dev the source chain selector emitted by the CCIPMessageReceived event
    uint64 public ghost_yieldPeer_event_CCIPMessageReceived_param_sourceChainSelector;
    // @review CCIPMessageReceived event doesn't emit an amountReceived

    // --- SharesMinted event --- //
    /// @dev incremented everytime a SharesMinted event is emitted
    uint256 public ghost_yieldPeer_event_SharesMinted_emissions;
    /// @dev the to emitted by the SharesMinted event
    address public ghost_yieldPeer_event_SharesMinted_param_to;
    /// @dev the amount emitted by the SharesMinted event
    uint256 public ghost_yieldPeer_event_SharesMinted_param_amount;
    /// @dev the total sum of all amounts emitted by SharesMinted events
    uint256 public ghost_yieldPeer_event_SharesMinted_param_amount_totalSum;

    // --- SharesBurned event --- //
    /// @dev incremented everytime a SharesBurned event is emitted
    uint256 public ghost_yieldPeer_event_SharesBurned_emissions;
    /// @dev the from emitted by the SharesBurned event
    address public ghost_yieldPeer_event_SharesBurned_param_from;
    /// @dev the amount emitted by the SharesBurned event
    uint256 public ghost_yieldPeer_event_SharesBurned_param_amount;
    /// @dev the total sum of all amounts emitted by SharesBurned events
    uint256 public ghost_yieldPeer_event_SharesBurned_param_amount_totalSum;

    /*//////////////////////////////////////////////////////////////
                              PARENT STATE
    //////////////////////////////////////////////////////////////*/
    /// @dev ParentPeer::s_totalShares
    uint256 public ghost_parent_state_totalShares;
    /// @dev ParentPeer::s_strategy
    Strategy public ghost_parent_state_strategy;
    /// @dev ParentPeer::s_rebalancer
    address public ghost_parent_state_rebalancer;
    /// @dev ParentPeer::s_initialActiveStrategySet
    bool public ghost_parent_state_initialActiveStrategySet;
    /// @dev ParentPeer::s_supportedProtocols
    mapping(bytes32 protocolId => bool isSupported) public ghost_parent_state_supportedProtocols;

    /*//////////////////////////////////////////////////////////////
                             PARENT EVENTS
    //////////////////////////////////////////////////////////////*/
    // --- StrategyUpdated event --- //
    /// @dev incremented everytime a StrategyUpdated event is emitted
    uint256 public ghost_parent_event_StrategyUpdated_emissions;
    /// @dev the chain selector emitted by the StrategyUpdated event
    uint64 public ghost_parent_event_StrategyUpdated_param_chainSelector;
    /// @dev the protocol id emitted by the StrategyUpdated event
    bytes32 public ghost_parent_event_StrategyUpdated_param_protocolId;
    /// @dev the old chain selector emitted by the StrategyUpdated event
    uint64 public ghost_parent_event_StrategyUpdated_param_oldChainSelector;

    // --- ShareMintUpdate event --- //
    /// @dev incremented everytime a ShareMintUpdate event is emitted
    uint256 public ghost_parent_event_ShareMintUpdate_emissions;
    /// @dev the amount emitted by the ShareMintUpdate event
    uint256 public ghost_parent_event_ShareMintUpdate_param_amount;
    /// @dev the chain selector emitted by the ShareMintUpdate event
    uint64 public ghost_parent_event_ShareMintUpdate_param_chainSelector;
    /// @dev the total sum of all amounts emitted by ShareMintUpdate events
    uint256 public ghost_parent_event_ShareMintUpdate_param_amount_totalSum;

    // --- ShareBurnUpdate event --- //
    /// @dev incremented everytime a ShareBurnUpdate event is emitted
    uint256 public ghost_parent_event_ShareBurnUpdate_emissions;
    /// @dev the amount emitted by the ShareBurnUpdate event
    uint256 public ghost_parent_event_ShareBurnUpdate_param_amount;
    /// @dev the chain selector emitted by the ShareBurnUpdate event
    uint64 public ghost_parent_event_ShareBurnUpdate_param_chainSelector;
    /// @dev the total sum of all amounts emitted by ShareBurnUpdate events
    uint256 public ghost_parent_event_ShareBurnUpdate_param_amount_totalSum;

    // --- DepositForwardedToStrategy event --- //
    /// @dev incremented everytime a DepositForwardedToStrategy event is emitted
    uint256 public ghost_parent_event_DepositForwardedToStrategy_emissions;
    /// @dev the amount emitted by the DepositForwardedToStrategy event
    uint256 public ghost_parent_event_DepositForwardedToStrategy_param_amount;
    /// @dev the chain selector emitted by the DepositForwardedToStrategy event
    uint64 public ghost_parent_event_DepositForwardedToStrategy_param_chainSelector;
    /// @dev the total sum of all amounts emitted by DepositForwardedToStrategy events
    uint256 public ghost_parent_event_DepositForwardedToStrategy_param_amount_totalSum;

    // --- WithdrawForwardedToStrategy event --- //
    /// @dev incremented everytime a WithdrawForwardedToStrategy event is emitted
    uint256 public ghost_parent_event_WithdrawForwardedToStrategy_emissions;
    /// @dev the amount emitted by the WithdrawForwardedToStrategy event
    uint256 public ghost_parent_event_WithdrawForwardedToStrategy_param_amount;
    /// @dev the chain selector emitted by the WithdrawForwardedToStrategy event
    uint64 public ghost_parent_event_WithdrawForwardedToStrategy_param_chainSelector;
    /// @dev the total sum of all amounts emitted by WithdrawForwardedToStrategy events
    uint256 public ghost_parent_event_WithdrawForwardedToStrategy_param_amount_totalSum;

    // --- DepositPingPongToChild event --- //
    /// @dev incremented everytime a DepositPingPongToChild event is emitted
    uint256 public ghost_parent_event_DepositPingPongToChild_emissions;
    /// @dev the amount emitted by the DepositPingPongToChild event
    uint256 public ghost_parent_event_DepositPingPongToChild_param_amount;
    /// @dev the chain selector emitted by the DepositPingPongToChild event
    uint64 public ghost_parent_event_DepositPingPongToChild_param_chainSelector;
    /// @dev the total sum of all amounts emitted by DepositPingPongToChild events
    uint256 public ghost_parent_event_DepositPingPongToChild_param_amount_totalSum;

    // --- WithdrawPingPongToChild event --- //
    /// @dev incremented everytime a WithdrawPingPongToChild event is emitted
    uint256 public ghost_parent_event_WithdrawPingPongToChild_emissions;
    /// @dev the amount emitted by the WithdrawPingPongToChild event
    uint256 public ghost_parent_event_WithdrawPingPongToChild_param_amount;
    /// @dev the chain selector emitted by the WithdrawPingPongToChild event
    uint64 public ghost_parent_event_WithdrawPingPongToChild_param_chainSelector;
    /// @dev the total sum of all amounts emitted by WithdrawPingPongToChild events
    uint256 public ghost_parent_event_WithdrawPingPongToChild_param_amount_totalSum;

    // --- RebalancerSet event --- //
    /// @dev incremented everytime a RebalancerSet event is emitted
    uint256 public ghost_parent_event_RebalancerSet_emissions;
    /// @dev the rebalancer emitted by the RebalancerSet event
    address public ghost_parent_event_RebalancerSet_param_rebalancer;

    // --- SupportedProtocolSet event --- //
    /// @dev incremented everytime a SupportedProtocolSet event is emitted
    uint256 public ghost_parent_event_SupportedProtocolSet_emissions;
    /// @dev the protocol id emitted by the SupportedProtocolSet event
    bytes32 public ghost_parent_event_SupportedProtocolSet_param_protocolId;
    /// @dev the isSupported flag emitted by the SupportedProtocolSet event
    bool public ghost_parent_event_SupportedProtocolSet_param_isSupported;

    /*//////////////////////////////////////////////////////////////
                              CHILD EVENTS
    //////////////////////////////////////////////////////////////*/
    // --- DepositPingPongToParent event --- //
    /// @dev incremented everytime a DepositPingPongToParent event is emitted
    uint256 public ghost_child_event_DepositPingPongToParent_emissions;
    /// @dev the amount emitted by the DepositPingPongToParent event
    uint256 public ghost_child_event_DepositPingPongToParent_param_amount;
    /// @dev the total sum of all amounts emitted by DepositPingPongToParent events
    uint256 public ghost_child_event_DepositPingPongToParent_param_amount_totalSum;

    // --- WithdrawPingPongToParent event --- //
    /// @dev incremented everytime a WithdrawPingPongToParent event is emitted
    uint256 public ghost_child_event_WithdrawPingPongToParent_emissions;
    /// @dev the amount emitted by the WithdrawPingPongToParent event
    uint256 public ghost_child_event_WithdrawPingPongToParent_param_amount;
    /// @dev the total sum of all amounts emitted by WithdrawPingPongToParent events
    uint256 public ghost_child_event_WithdrawPingPongToParent_param_amount_totalSum;

    /*//////////////////////////////////////////////////////////////
                           REBALANCER EVENTS
    //////////////////////////////////////////////////////////////*/
    // --- ReportDecoded event --- //
    /// @dev incremented everytime a ReportDecoded event is emitted
    uint256 public ghost_rebalancer_event_ReportDecoded_emissions;
    /// @dev the chain selector emitted by the ReportDecoded event
    uint64 public ghost_rebalancer_event_ReportDecoded_param_chainSelector;
    /// @dev the protocol id emitted by the ReportDecoded event
    bytes32 public ghost_rebalancer_event_ReportDecoded_param_protocolId;

    /*//////////////////////////////////////////////////////////////
                                 SHARE
    //////////////////////////////////////////////////////////////*/
    // something here for the total balances of share token across chains
    // /// @dev track the total sum of all shares minted based on crosschain balances of share/yieldcoin token
    // uint256 public ghost_share_total;

    /// @dev track the Share.balanceOf for a user
    mapping(address user => uint256 balance) public ghost_share_state_balanceOf_totalAcrossChains;

    /// @
    uint256 public ghost_share_state_crosschain_totalSupply;
}
