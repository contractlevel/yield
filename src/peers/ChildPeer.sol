// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {YieldPeer, Client, IRouterClient, CCIPOperations} from "./YieldPeer.sol";

/// @title CLY ChildPeer
/// @author @contractlevel
/// @notice This contract is a ChildPeer of the Contract Level Yield system
/// @notice This contract is deployed on every chain in the system except for the one the ParentPeer is deployed on
/// @notice Users can deposit and withdraw USDC to/from the system via this contract
contract ChildPeer is YieldPeer {
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev The CCIP selector of the parent chain
    uint64 internal immutable i_parentChainSelector;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a DepositToStrategy needs to be pingpong'd with the Parent
    event DepositPingPongToParent(uint256 indexed depositAmount);
    /// @notice Emitted when a WithdrawToStrategy needs to be pingpong'd with the Parent
    event WithdrawPingPongToParent(uint256 indexed shareBurnAmount);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param ccipRouter The address of the CCIP router
    /// @param link The address of the LINK token
    /// @param thisChainSelector The CCIP selector of the chain this peer is deployed on
    /// @param usdc The address of the USDC token
    /// @param share The address of the Share token, native to this system that is minted in return for deposits
    constructor(
        address ccipRouter,
        address link,
        uint64 thisChainSelector,
        address usdc,
        address share,
        uint64 parentChainSelector
    ) YieldPeer(ccipRouter, link, thisChainSelector, usdc, share) {
        i_parentChainSelector = parentChainSelector;
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Users can deposit USDC into the system via this function
    /// @notice As this is a ChildPeer, we handle two deposit cases:
    /// 1. This Child is the Strategy
    /// 2. This Child is not the Strategy
    /// @param amountToDeposit The amount of USDC to deposit into the system
    /// @dev Revert if amountToDeposit is less than 1e6 (1 USDC)
    /// @dev Revert if peer is paused
    /// @notice User must approve this contract to spend their stablecoin
    function deposit(uint256 amountToDeposit) external override whenNotPaused {
        /// @dev takes a fee
        /// same var name ==== confusing!
        amountToDeposit = _initiateDeposit(amountToDeposit);

        address activeStrategyAdapter = _getActiveStrategyAdapter();
        DepositData memory depositData = _buildDepositData(amountToDeposit);

        // 1. This Child is the Strategy
        if (activeStrategyAdapter != address(0)) {
            /// @dev deposit USDC in strategy pool and get totalValue
            depositData.totalValue = _depositToStrategyAndGetTotalValue(activeStrategyAdapter, amountToDeposit);

            /// @dev send a message to parent contract to request shareMintAmount
            _ccipSend(
                i_parentChainSelector, CcipTxType.DepositCallbackParent, abi.encode(depositData), ZERO_BRIDGE_AMOUNT
            );
        }
        // 2. This Child is not the Strategy
        else {
            /// @dev send a message to parent contract to deposit to strategy and request shareMintAmount
            _ccipSend(i_parentChainSelector, CcipTxType.DepositToParent, abi.encode(depositData), amountToDeposit);
        }
    }

    /// @notice This function is to facilitate USDC withdrawals from the system
    /// @notice This function is called when a YieldCoin/share holder transferAndCall()s to this contract
    /// @param withdrawer The address of the YieldCoin holder to send withdrawn USDC to
    /// @param shareBurnAmount The amount of YieldCoin/shares to burn
    /// @param encodedWithdrawChainSelector The encoded chain selector to withdraw USDC to. If this is empty, the withdrawn USDC will be sent back to this chain
    /// @dev Revert if encodedWithdrawChainSelector doesn't decode to an allowed chain selector
    /// @dev Revert if msg.sender is not the YieldCoin/share token
    /// @dev Revert if shareBurnAmount is 0
    /// @dev Revert if peer is paused
    /// @dev Burn the YieldCoin tokens and send a message to the parent chain to withdraw USDC from the strategy
    function onTokenTransfer(address withdrawer, uint256 shareBurnAmount, bytes calldata encodedWithdrawChainSelector)
        external
        override
        whenNotPaused
    {
        _revertIfMsgSenderIsNotShare();
        _revertIfZeroAmount(shareBurnAmount);
        _burnShares(withdrawer, shareBurnAmount);
        WithdrawData memory withdrawData =
            _buildWithdrawData(withdrawer, shareBurnAmount, _decodeWithdrawChainSelector(encodedWithdrawChainSelector));
        _ccipSend(i_parentChainSelector, CcipTxType.WithdrawToParent, abi.encode(withdrawData), ZERO_BRIDGE_AMOUNT);
        emit WithdrawInitiated(withdrawer, shareBurnAmount, i_thisChainSelector);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Receives a CCIP message from a peer
    /// @param txType The type of CCIP message received - see IYieldPeer.CcipTxType
    ///  The CCIP message received
    /// - CcipTxType DepositToStrategy: A tx from parent to this-child-strategy to deposit USDC in strategy and get totalValue
    /// - CcipTxType DepositCallbackChild: A tx from parent to this-child to mint shares to the depositor
    /// - CcipTxType WithdrawToStrategy: A tx from parent to this-child-strategy to withdraw USDC from strategy and get usdcWithdrawAmount
    /// - CcipTxType WithdrawCallback: A tx from strategy to this-child to transfer USDC to withdrawer
    /// - CcipTxType RebalanceOldStrategy: A tx from parent to this-old-strategy to rebalance funds to the new strategy
    /// - CcipTxType RebalanceNewStrategy: A tx from the old strategy, sending rebalanced funds to this new strategy
    /// @param tokenAmounts The token amounts received in the CCIP message
    /// @param data The data received in the CCIP message. It will be either DepositData, WithdrawData, or the encoded Strategy struct.
    function _handleCCIPMessage(
        CcipTxType txType,
        Client.EVMTokenAmount[] memory tokenAmounts,
        bytes memory data,
        uint64 /* sourceChainSelector */
    ) internal override {
        if (txType == CcipTxType.DepositToStrategy || txType == CcipTxType.DepositPingPong) {
            _handleCCIPDepositToStrategy(tokenAmounts, data);
        }
        //slither-disable-next-line reentrancy-events
        if (txType == CcipTxType.DepositCallbackChild) _handleCCIPDepositCallbackChild(data);
        if (txType == CcipTxType.WithdrawToStrategy || txType == CcipTxType.WithdrawPingPong) {
            _handleCCIPWithdrawToStrategy(data);
        }
        if (txType == CcipTxType.WithdrawCallback) _handleCCIPWithdrawCallback(tokenAmounts, data);
        //slither-disable-next-line reentrancy-no-eth
        if (txType == CcipTxType.RebalanceOldStrategy) _handleCCIPRebalanceOldStrategy(data);
        if (txType == CcipTxType.RebalanceNewStrategy) _handleCCIPRebalanceNewStrategy(tokenAmounts, data);
    }

    /// @notice This function handles a deposit sent from Parent to this Strategy-Child
    /// @notice The purpose of this tx is to deposit USDC in the strategy and return the totalValue so that the parent can calculate the shareMintAmount.
    /// deposit -> parent -> strategy (HERE) -> callback to parent -> possible callback to child
    /// @param tokenAmounts The token amounts received in the CCIP message
    /// @param data The encoded DepositData
    function _handleCCIPDepositToStrategy(Client.EVMTokenAmount[] memory tokenAmounts, bytes memory data) internal {
        DepositData memory depositData = _decodeDepositData(data);
        CCIPOperations._validateTokenAmounts(tokenAmounts, address(i_usdc), depositData.amount);
        address activeStrategyAdapter = _getActiveStrategyAdapter();
        if (activeStrategyAdapter != address(0)) {
            depositData.totalValue = _depositToStrategyAndGetTotalValue(activeStrategyAdapter, depositData.amount);

            /// @dev send a message to parent with totalValue to calculate shareMintAmount
            _ccipSend(
                i_parentChainSelector, CcipTxType.DepositCallbackParent, abi.encode(depositData), ZERO_BRIDGE_AMOUNT
            );
        } else {
            // consider adding event for ping pong, pros/cons of emitting it here
            emit DepositPingPongToParent(depositData.amount);
            _ccipSend(i_parentChainSelector, CcipTxType.DepositPingPong, abi.encode(depositData), depositData.amount);
        }
    }

    /// @notice This function handles a deposit callback from the parent chain
    /// @notice The purpose of this callback is to mint shares to the depositor on this chain
    /// deposit on this chain -> parent -> strategy -> callback to parent -> callback to child (HERE)
    /// @param data The encoded DepositData
    function _handleCCIPDepositCallbackChild(bytes memory data) internal {
        // @review DepositCompleted event?
        DepositData memory depositData = _decodeDepositData(data);
        _mintShares(depositData.depositor, depositData.shareMintAmount);
    }

    /// @notice This function handles a withdraw request from the parent chain to this Strategy-Child
    /// @notice The purpose of this tx is to withdraw USDC from the strategy and then send it back to the withdraw chain
    /// withdraw -> parent -> strategy (HERE) -> callback to withdraw chain
    /// @notice If this strategy chain is the same as the withdraw chain, we transfer the USDC to the withdrawer, concluding the withdrawal process.
    /// @param data The encoded WithdrawData
    function _handleCCIPWithdrawToStrategy(bytes memory data) internal {
        WithdrawData memory withdrawData = _decodeWithdrawData(data);

        address activeStrategyAdapter = _getActiveStrategyAdapter();
        if (activeStrategyAdapter != address(0)) {
            withdrawData.usdcWithdrawAmount =
                _withdrawFromStrategyAndGetUsdcWithdrawAmount(activeStrategyAdapter, withdrawData);

            if (i_thisChainSelector == withdrawData.chainSelector) {
                //slither-disable-next-line reentrancy-events
                emit WithdrawCompleted(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount);
                _transferUsdcTo(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount);
            } else {
                _ccipSend(
                    withdrawData.chainSelector,
                    CcipTxType.WithdrawCallback,
                    abi.encode(withdrawData), // @review solady calldata compression for all encoded crosschain data?
                    withdrawData.usdcWithdrawAmount
                );
            }
        } else {
            emit WithdrawPingPongToParent(withdrawData.shareBurnAmount);
            _ccipSend(i_parentChainSelector, CcipTxType.WithdrawPingPong, abi.encode(withdrawData), ZERO_BRIDGE_AMOUNT);
        }
    }

    /// @notice Handles the CCIP message for a rebalance old strategy
    /// @notice The message this function handles is sent by the Parent when the Strategy is updated
    /// @notice This function should only be executed when this chain is the (old) strategy
    /// @dev Rebalances funds from the old strategy to the new strategy
    /// @param data The data to decode - decodes to Strategy (chainSelector, protocolId)
    function _handleCCIPRebalanceOldStrategy(bytes memory data) internal {
        /// @dev cache the old active strategy adapter
        address oldActiveStrategyAdapter = _getActiveStrategyAdapter();

        /// @dev update strategy pool to either protocol on this chain or address(0) if on a different chain
        Strategy memory newStrategy = abi.decode(data, (Strategy));
        address newActiveStrategyAdapter =
            _updateActiveStrategyAdapter(newStrategy.chainSelector, newStrategy.protocolId);

        /// @dev withdraw from the old strategy
        uint256 totalValue = _getTotalValueFromStrategy(oldActiveStrategyAdapter, address(i_usdc));
        if (totalValue != 0) _withdrawFromStrategy(oldActiveStrategyAdapter, totalValue);

        // if the new strategy is this chain, but different protocol, then we need to deposit to the new strategy
        if (newStrategy.chainSelector == i_thisChainSelector) {
            //slither-disable-next-line reentrancy-events
            _depositToStrategy(newActiveStrategyAdapter, totalValue);
        }
        // if the new strategy is a different chain, then we need to send the usdc we just withdrew to the new strategy
        else {
            _ccipSend(newStrategy.chainSelector, CcipTxType.RebalanceNewStrategy, data, totalValue);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @return The parent chain selector
    function getParentChainSelector() external view returns (uint64) {
        return i_parentChainSelector;
    }
}
