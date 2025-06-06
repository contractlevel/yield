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
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param ccipRouter The address of the CCIP router
    /// @param link The address of the LINK token
    /// @param thisChainSelector The CCIP selector of the chain this peer is deployed on
    /// @param usdc The address of the USDC token
    /// @param aavePoolAddressesProvider The address of the Aave pool addresses provider
    /// @param comet The address of the Compound v3 cUSDCv3 contract
    /// @param share The address of the Share token, native to this system that is minted in return for deposits
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
        _initiateDeposit(amountToDeposit);

        address strategyPool = _getStrategyPool();
        DepositData memory depositData = _buildDepositData(amountToDeposit);

        // 1. This Child is the Strategy
        if (strategyPool != address(0)) {
            /// @dev deposit USDC in strategy pool
            _depositToStrategy(strategyPool, amountToDeposit);
            /// @dev get totalValue from strategyPool and update depositData
            depositData.totalValue = _getTotalValueFromStrategy(strategyPool);

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
    /// @notice This function is called when a SHARE holder transferAndCall()s to this contract
    /// @param withdrawer The address of the SHARE holder to send withdrawn USDC to
    /// @param shareBurnAmount The amount of SHARE to burn
    /// @param encodedWithdrawChainSelector The encoded chain selector to withdraw USDC to. If this is empty, the withdrawn USDC will be sent back to this chain
    /// @dev Revert if encodedWithdrawChainSelector doesn't decode to an allowed chain selector
    /// @dev Revert if msg.sender is not the SHARE token
    /// @dev Revert if shareBurnAmount is 0
    /// @dev Burn the SHARE tokens and send a message to the parent chain to withdraw USDC from the strategy
    function onTokenTransfer(address withdrawer, uint256 shareBurnAmount, bytes calldata encodedWithdrawChainSelector)
        external
        override
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
    ///  The CCIP message received
    /// - CcipTxType DepositToStrategy: A tx from parent to this-child-strategy to deposit USDC in strategy and get totalValue
    /// - CcipTxType DepositCallbackChild: A tx from parent to this-child to mint shares to the depositor
    /// - CcipTxType WithdrawToStrategy: A tx from parent to this-child-strategy to withdraw USDC from strategy and get usdcWithdrawAmount
    function _handleCCIPMessage(CcipTxType txType, Client.EVMTokenAmount[] memory tokenAmounts, bytes memory data)
        internal
        override
    {
        if (txType == CcipTxType.DepositToStrategy) _handleCCIPDepositToStrategy(tokenAmounts, data);
        if (txType == CcipTxType.DepositCallbackChild) _handleCCIPDepositCallbackChild(data);
        if (txType == CcipTxType.WithdrawToStrategy) _handleCCIPWithdrawToStrategy(data);
        if (txType == CcipTxType.WithdrawCallback) _handleCCIPWithdrawCallback(tokenAmounts, data);
        if (txType == CcipTxType.RebalanceOldStrategy) _handleCCIPRebalanceOldStrategy(data);
        if (txType == CcipTxType.RebalanceNewStrategy) _handleCCIPRebalanceNewStrategy(data);
    }

    /// @notice This function handles a deposit sent from Parent to this Strategy-Child
    /// @notice The purpose of this tx is to deposit USDC in the strategy and return the totalValue so that the parent can calculate the shareMintAmount.
    /// deposit -> parent -> strategy (HERE) -> callback to parent -> possible callback to child
    function _handleCCIPDepositToStrategy(Client.EVMTokenAmount[] memory tokenAmounts, bytes memory data) internal {
        DepositData memory depositData = _decodeDepositData(data);
        CCIPOperations._validateTokenAmounts(tokenAmounts, address(i_usdc), depositData.amount);

        depositData.totalValue = _depositToStrategyAndGetTotalValue(depositData.amount);

        /// @dev send a message to parent with totalValue to calculate shareMintAmount
        _ccipSend(i_parentChainSelector, CcipTxType.DepositCallbackParent, abi.encode(depositData), ZERO_BRIDGE_AMOUNT);
    }

    /// @notice This function handles a deposit callback from the parent chain
    /// @notice The purpose of this callback is to mint shares to the depositor on this chain
    /// deposit on this chain -> parent -> strategy -> callback to parent -> callback to child (HERE)
    function _handleCCIPDepositCallbackChild(bytes memory data) internal {
        DepositData memory depositData = _decodeDepositData(data);
        _mintShares(depositData.depositor, depositData.shareMintAmount);
    }

    /// @notice This function handles a withdraw request from the parent chain to this Strategy-Child
    /// @notice The purpose of this tx is to withdraw USDC from the strategy and then send it back to the withdraw chain
    /// withdraw -> parent -> strategy (HERE) -> callback to withdraw chain
    /// @notice If this strategy chain is the same as the withdraw chain, we transfer the USDC to the withdrawer, concluding the withdrawal process.
    function _handleCCIPWithdrawToStrategy(bytes memory data) internal {
        WithdrawData memory withdrawData = _decodeWithdrawData(data);
        withdrawData.usdcWithdrawAmount = _withdrawFromStrategyAndGetUsdcWithdrawAmount(withdrawData);

        if (i_thisChainSelector == withdrawData.chainSelector) {
            _transferUsdcTo(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount);
            emit WithdrawCompleted(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount);
        } else {
            _ccipSend(
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
}
