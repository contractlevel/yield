// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {YieldPeer, Client, IRouterClient, CCIPOperations, IERC20Metadata} from "./YieldPeer.sol";

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
    /// @notice Users can deposit any supported stablecoin into the system
    /// @notice As this is a ChildPeer, we handle two deposit cases:
    /// 1. This Child is the Strategy
    /// 2. This Child is not the Strategy
    /// @param stablecoinId The stablecoin ID (e.g., keccak256("USDC"), keccak256("USDT"))
    /// @param amount The amount of stablecoin to deposit
    /// @dev Revert if stablecoin is not supported
    /// @dev Revert if peer is paused
    function deposit(bytes32 stablecoinId, uint256 amount) external override whenNotPaused {
        /// @dev transfer stablecoin from user and take fee
        address stablecoin;
        (amount, stablecoin) = _initiateDeposit(stablecoinId, amount);

        address activeStrategyAdapter = _getActiveStrategyAdapter();

        // 1. This Child is the Strategy
        if (activeStrategyAdapter != address(0)) {
            address activeStablecoin = s_activeStablecoin;

            /// @dev swap deposited stablecoin to strategy stablecoin if different
            uint256 depositAmountNativeDecimals = amount;
            if (stablecoin != activeStablecoin) {
                depositAmountNativeDecimals = _swapStablecoins(stablecoin, activeStablecoin, amount);
            }

            /// @dev scale depositAmount to USDC decimals (6 dec) for share math
            uint256 depositAmountUsdcDecimals;
            if (activeStablecoin == address(i_usdc)) {
                /// @dev skip scaling if strategy uses USDC (already in system decimals)
                depositAmountUsdcDecimals = depositAmountNativeDecimals;
            } else {
                depositAmountUsdcDecimals =
                    _scaleToUsdcDecimals(depositAmountNativeDecimals, IERC20Metadata(activeStablecoin).decimals());
            }

            // @review - clearly explain why we are using depositAmountUsdcDecimals here
            DepositData memory depositData = _buildDepositData(depositAmountUsdcDecimals);
            /// @dev _depositToStrategyAndGetTotalValue returns totalValue in USDC decimals (has USDC optimization internally)
            // @review - clearly explain why we are using depositAmountNativeDecimals here
            depositData.totalValue = _depositToStrategyAndGetTotalValue(
                activeStrategyAdapter, activeStablecoin, depositAmountNativeDecimals
            );

            _ccipSend(
                i_parentChainSelector, CcipTxType.DepositCallbackParent, abi.encode(depositData), ZERO_BRIDGE_AMOUNT
            );
        }
        // 2. This Child is not the Strategy — bridge USDC
        else {
            /// @dev swap to USDC if needed for CCIP bridging
            uint256 bridgeAmount = amount;
            if (stablecoin != address(i_usdc)) {
                bridgeAmount = _swapStablecoins(stablecoin, address(i_usdc), amount);
            }

            DepositData memory depositData = _buildDepositData(bridgeAmount);
            _ccipSend(i_parentChainSelector, CcipTxType.DepositToParent, abi.encode(depositData), bridgeAmount);
        }
    }

    /// @notice This function is to facilitate USDC withdrawals from the system
    /// @notice This function is called when a YieldCoin/share holder transferAndCall()s to this contract
    // @review currently only supporting withdrawing in USDC
    /// @param withdrawer The address of the YieldCoin holder to send withdrawn USDC to
    /// @param shareBurnAmount The amount of YieldCoin/shares to burn
    /// @dev Revert if msg.sender is not the YieldCoin/share token
    /// @dev Revert if shareBurnAmount is 0
    /// @dev Revert if peer is paused
    /// @dev Burn the YieldCoin tokens and send a message to the parent chain to withdraw USDC from the strategy
    function onTokenTransfer(
        address withdrawer,
        uint256 shareBurnAmount,
        bytes calldata /* data */
    )
        external
        override
        whenNotPaused
    {
        _revertIfMsgSenderIsNotShare();
        _revertIfZeroAmount(shareBurnAmount);
        _burnShares(withdrawer, shareBurnAmount);
        WithdrawData memory withdrawData = _buildWithdrawData(withdrawer, shareBurnAmount, i_thisChainSelector);
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
        if (txType == CcipTxType.RebalanceFromOldStrategy) {
            _handleCCIPRebalanceOldStrategy(data, _getActiveStablecoin());
        }
        if (txType == CcipTxType.RebalanceToNewStrategy) _handleCCIPRebalanceToNewStrategy(tokenAmounts, data);
    }

    /// @notice This function handles a deposit sent from Parent to this Strategy-Child
    /// @notice The purpose of this tx is to deposit in the strategy and return the totalValue so that the parent can calculate the shareMintAmount.
    /// deposit -> parent -> strategy (HERE) -> callback to parent -> possible callback to child
    /// @param tokenAmounts The token amounts received in the CCIP message
    /// @param data The encoded DepositData
    function _handleCCIPDepositToStrategy(Client.EVMTokenAmount[] memory tokenAmounts, bytes memory data) internal {
        DepositData memory depositData = _decodeDepositData(data);
        CCIPOperations._validateTokenAmounts(tokenAmounts, address(i_usdc), depositData.amount);
        address activeStrategyAdapter = _getActiveStrategyAdapter();
        if (activeStrategyAdapter != address(0)) {
            address activeStablecoin = s_activeStablecoin;
            /// @dev depositData.amount is in USDC decimals (from CCIP bridge)
            uint256 depositAmountNativeDecimals = depositData.amount;

            /// @dev swap bridged USDC to strategy stablecoin if needed
            if (activeStablecoin != address(i_usdc)) {
                depositAmountNativeDecimals = _swapStablecoins(address(i_usdc), activeStablecoin, depositData.amount);
            }

            /// @dev _depositToStrategyAndGetTotalValue returns totalValue in USDC decimals (has USDC optimization internally)
            depositData.totalValue = _depositToStrategyAndGetTotalValue(
                activeStrategyAdapter, activeStablecoin, depositAmountNativeDecimals
            );
            /// @dev depositData.amount stays in USDC decimals for share math

            _ccipSend(
                i_parentChainSelector, CcipTxType.DepositCallbackParent, abi.encode(depositData), ZERO_BRIDGE_AMOUNT
            );
        } else {
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
    /// @notice The purpose of this tx is to withdraw from the strategy and then send USDC back to the withdraw chain
    /// withdraw -> parent -> strategy (HERE) -> callback to withdraw chain
    /// @notice If this strategy chain is the same as the withdraw chain, we transfer the USDC to the withdrawer, concluding the withdrawal process.
    /// @param data The encoded WithdrawData
    // @review currently only supporting withdrawing in USDC
    function _handleCCIPWithdrawToStrategy(bytes memory data) internal {
        WithdrawData memory withdrawData = _decodeWithdrawData(data);

        address activeStrategyAdapter = _getActiveStrategyAdapter();
        if (activeStrategyAdapter != address(0)) {
            withdrawData.usdcWithdrawAmount =
                _withdrawFromStrategyAndGetUsdcWithdrawAmount(activeStrategyAdapter, s_activeStablecoin, withdrawData);

            if (i_thisChainSelector == withdrawData.chainSelector) {
                //slither-disable-next-line reentrancy-events
                emit WithdrawCompleted(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount);
                _transferUsdcTo(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount);
            } else {
                _ccipSend(
                    withdrawData.chainSelector,
                    CcipTxType.WithdrawCallback,
                    abi.encode(withdrawData),
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
    /// @notice Handles stablecoin swaps when changing stablecoins
    /// @dev All amounts are in NATIVE DECIMALS until swapping to USDC for bridge
    /// @param data The data to decode - decodes to Strategy (chainSelector, protocolId, stablecoinId)
    /// @param oldStablecoin The stablecoin address of the current (old) strategy
    function _handleCCIPRebalanceOldStrategy(bytes memory data, address oldStablecoin) internal {
        /// @dev cache the old active strategy adapter BEFORE updating
        address oldActiveStrategyAdapter = _getActiveStrategyAdapter();

        /// @dev totalValueNativeDecimals in NATIVE DECIMALS of oldStablecoin
        uint256 totalValueNativeDecimals = _getTotalValueFromStrategy(oldActiveStrategyAdapter, oldStablecoin);

        /// @dev withdraw in NATIVE DECIMALS (must happen before _updateActiveStrategy overwrites adapter)
        if (totalValueNativeDecimals != 0) {
            _withdrawFromStrategy(oldActiveStrategyAdapter, oldStablecoin, totalValueNativeDecimals);
        }

        /// @dev update strategy - sets adapter + stablecoin, or both to address(0) if different chain
        Strategy memory newStrategy = abi.decode(data, (Strategy));
        (address newActiveStrategyAdapter, address newStablecoin) = _updateActiveStrategy(newStrategy);

        /// @dev if new strategy is on this chain, deposit locally (all in NATIVE DECIMALS)
        if (newStrategy.chainSelector == i_thisChainSelector) {
            uint256 depositAmountNativeDecimals = totalValueNativeDecimals;

            /// @dev swap if stablecoins differ: NATIVE(old) → NATIVE(new)
            if (oldStablecoin != newStablecoin && totalValueNativeDecimals != 0) {
                depositAmountNativeDecimals = _swapStablecoins(oldStablecoin, newStablecoin, totalValueNativeDecimals);
            }

            //slither-disable-next-line reentrancy-events
            /// @dev deposit in NATIVE DECIMALS of newStablecoin
            if (depositAmountNativeDecimals != 0) {
                _depositToStrategy(newActiveStrategyAdapter, newStablecoin, depositAmountNativeDecimals);
            }
        }
        /// @dev if new strategy is on different chain, swap to USDC and bridge
        else {
            uint256 bridgeAmountUsdcDecimals = totalValueNativeDecimals;

            /// @dev swap to USDC for CCIP: NATIVE(old) → 6 dec (USDC native = system decimals)
            if (oldStablecoin != address(i_usdc) && totalValueNativeDecimals != 0) {
                bridgeAmountUsdcDecimals = _swapStablecoins(oldStablecoin, address(i_usdc), totalValueNativeDecimals);
            }

            /// @dev CCIP bridge amount in USDC decimals (6)
            _ccipSend(newStrategy.chainSelector, CcipTxType.RebalanceToNewStrategy, data, bridgeAmountUsdcDecimals);
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
