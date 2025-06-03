// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {YieldPeer, Client, IRouterClient} from "./YieldPeer.sol";

contract ChildPeer is YieldPeer {
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint64 internal immutable i_parentChainSelector;

    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/
    event StrategyDepositCompleted(
        bytes32 indexed ccipMessageId, address indexed strategyPool, DepositData indexed depositData
    );

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        address ccipRouter,
        address link,
        uint64 thisChainSelector,
        address usdc,
        address aavePoolAddressesProvider,
        address comet,
        address share,
        uint64 parentChainSelector
    ) YieldPeer(ccipRouter, link, thisChainSelector, usdc, aavePoolAddressesProvider, comet, share) {
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
    /// @dev Revert if amountToDeposit is 0
    function deposit(uint256 amountToDeposit) external override {
        _revertIfZeroAmount(amountToDeposit);
        _transferUsdcFrom(msg.sender, address(this), amountToDeposit);

        address strategyPool = _getStrategyPool();
        DepositData memory depositData = _buildDepositData(amountToDeposit);

        emit DepositInitiated(msg.sender, amountToDeposit, i_thisChainSelector);

        // 1. This Child is the Strategy
        if (strategyPool != address(0)) {
            // @review we could modularize these two lines into a function
            /// @dev deposit USDC in strategy pool
            _depositToStrategy(strategyPool, amountToDeposit);
            /// @dev get totalValue from strategyPool and update depositData
            depositData.totalValue = _getTotalValueFromStrategy(strategyPool);

            /// @dev send a message to parent contract to request shareMintAmount
            bytes32 ccipMessageId = _ccipSend(
                i_parentChainSelector, CcipTxType.DepositCallbackParent, abi.encode(depositData), ZERO_BRIDGE_AMOUNT
            );
        }
        // 2. This Child is not the Strategy
        else {
            /// @dev send a message to parent contract to deposit to strategy and request shareMintAmount
            bytes32 ccipMessageId =
                _ccipSend(i_parentChainSelector, CcipTxType.DepositToParent, abi.encode(depositData), amountToDeposit);
        }
    }

    // function withdraw(uint256 shareBurnAmount) external override {}

    function onTokenTransfer(address withdrawer, uint256 shareBurnAmount, bytes calldata data) external override {
        _revertIfMsgSenderIsNotShare();
        _revertIfZeroAmount(shareBurnAmount);
        _burnShares(shareBurnAmount);
        WithdrawData memory withdrawData = _buildWithdrawData(withdrawer, shareBurnAmount);
        _ccipSend(i_parentChainSelector, CcipTxType.WithdrawToParent, abi.encode(withdrawData), ZERO_BRIDGE_AMOUNT);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Receives a CCIP message from a peer
    /// @param message The CCIP message received
    /// - CcipTxType DepositToStrategy: A tx from parent to this-child-strategy to deposit USDC in strategy and get totalValue
    /// - CcipTxType DepositCallbackChild: A tx from parent to this-child to mint shares to the depositor
    /// - CcipTxType WithdrawToStrategy: A tx from parent to this-child-strategy to withdraw USDC from strategy and get usdcWithdrawAmount
    function _ccipReceive(Client.Any2EVMMessage memory message)
        internal
        override
        onlyAllowed(message.sourceChainSelector, abi.decode(message.sender, (address)))
    {
        (CcipTxType txType, bytes memory data) = abi.decode(message.data, (CcipTxType, bytes));

        emit CCIPMessageReceived(message.messageId, txType, message.sourceChainSelector);

        if (txType == CcipTxType.DepositToStrategy) {
            DepositData memory depositData = abi.decode(data, (DepositData));
            _validateTokenAmounts(message.destTokenAmounts, depositData.amount);
            _handleCCIPDepositToStrategy(depositData);
        }
        if (txType == CcipTxType.DepositCallbackChild) {
            DepositData memory depositData = abi.decode(data, (DepositData));
            _handleCCIPDepositCallbackChild(depositData);
        }
        if (txType == CcipTxType.WithdrawToStrategy) {
            WithdrawData memory withdrawData = abi.decode(data, (WithdrawData));
            _handleCCIPWithdrawToStrategy(withdrawData);
        }
        if (txType == CcipTxType.WithdrawCallback) {
            _handleCCIPWithdrawCallback(message.destTokenAmounts, data);
        }
        if (txType == CcipTxType.RebalanceOldStrategy) {
            _handleCCIPRebalanceOldStrategy(data);
        }
        if (txType == CcipTxType.RebalanceNewStrategy) {
            _handleCCIPRebalanceNewStrategy(data);
        }
        // add withdraw and rebalance tx type handling
    }

    /// @notice This function handles a deposit sent from Parent to this Strategy-Child
    /// @notice The purpose of this tx is to deposit USDC in the strategy and return the totalValue so that the parent can calculate the shareMintAmount.
    /// deposit -> parent -> strategy (HERE) -> callback to parent -> possible callback to child
    function _handleCCIPDepositToStrategy(DepositData memory depositData) internal {
        depositData.totalValue = _depositToStrategyAndGetTotalValue(depositData.amount);

        /// @dev send a message to parent with totalValue to calculate shareMintAmount
        bytes32 ccipMessageId = _ccipSend(
            i_parentChainSelector, CcipTxType.DepositCallbackParent, abi.encode(depositData), ZERO_BRIDGE_AMOUNT
        );
    }

    /// @notice This function handles a deposit callback from the parent chain
    /// @notice The purpose of this callback is to mint shares to the depositor on this chain
    /// deposit on this chain -> parent -> strategy -> callback to parent -> callback to child (HERE)
    function _handleCCIPDepositCallbackChild(DepositData memory depositData) internal {
        _mintShares(depositData.depositor, depositData.shareMintAmount);
    }

    /// @notice This function handles a withdraw request from the parent chain to this Strategy-Child
    /// @notice The purpose of this tx is to withdraw USDC from the strategy and then send it back to the withdraw chain
    /// withdraw -> parent -> strategy (HERE) -> callback to withdraw chain
    /// @notice If this strategy chain is the same as the withdraw chain, we transfer the USDC to the withdrawer, concluding the withdrawal process.
    function _handleCCIPWithdrawToStrategy(WithdrawData memory withdrawData) internal {
        withdrawData.usdcWithdrawAmount = _withdrawFromStrategyAndGetUsdcWithdrawAmount(withdrawData);

        if (i_thisChainSelector == withdrawData.chainSelector) {
            _transferUsdcTo(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount);
        } else {
            bytes32 ccipMessageId = _ccipSend(
                withdrawData.chainSelector,
                CcipTxType.WithdrawCallback,
                abi.encode(withdrawData),
                withdrawData.usdcWithdrawAmount
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    function getParentChainSelector() external view returns (uint64) {
        return i_parentChainSelector;
    }

    // @review REMOVE THIS OR REPLACE IT WITH A WRAPPER
    function setStrategy(uint64 chainSelector, Protocol protocol) external {
        _updateStrategyPool(chainSelector, protocol);
    }
}
