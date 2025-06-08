// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {YieldPeer, Client, IRouterClient, CCIPOperations} from "./YieldPeer.sol";

/// @title CLY ParentPeer
/// @author @contractlevel
/// @notice This contract is the ParentPeer of the Contract Level Yield system
/// @notice This contract is deployed on only one chain
/// @notice Users can deposit and withdraw USDC to/from the system via this contract
/// @notice This contract tracks system wide state and acts as a system wide hub for forwarding CCIP messages to the Strategy
/// @notice This version of ParentPeer is incomplete - ParentCLF must be used as it inherits this and implements Automation and Functions
contract ParentPeer is YieldPeer {
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev total SHAREs minted across all chains
    // @invariant s_totalShares == ghost_totalSharesMinted - ghost_totalSharesBurned
    uint256 internal s_totalShares;
    /// @dev The current strategy - chainSelector and protocol
    // @review could this be just a s_strategyChainSelector?
    Strategy internal s_strategy;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when the current strategy is optimal
    event CurrentStrategyOptimal(uint64 indexed chainSelector, Protocol indexed protocol);
    /// @notice Emitted when the amount of shares minted is updated
    event ShareMintUpdate(uint256 indexed shareMintAmount, uint64 indexed chainSelector, uint256 indexed totalShares);
    /// @notice Emitted when the amount of shares burned is updated
    event ShareBurnUpdate(uint256 indexed shareBurnAmount, uint64 indexed chainSelector, uint256 indexed totalShares);
    /// @notice Emitted when a deposit is forwarded to the strategy
    event DepositForwardedToStrategy(uint256 indexed depositAmount, uint64 indexed chainSelector);
    /// @notice Emitted when a withdraw is forwarded to the strategy
    event WithdrawForwardedToStrategy(uint256 indexed withdrawAmount, uint64 indexed chainSelector);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param ccipRouter The address of the CCIP router
    /// @param link The address of the LINK token
    /// @param thisChainSelector The selector of the chain this contract is deployed on
    /// @param usdc The address of the USDC token
    /// @param aavePoolAddressesProvider The address of the Aave pool addresses provider
    /// @param comet The address of the Compound v3 cUSDCv3 contract
    /// @param share The address of the SHARE token native to this system that is minted in exchange for USDC deposits
    /// @dev Initial Strategy is set to Aave on this chain
    constructor(
        address ccipRouter,
        address link,
        uint64 thisChainSelector,
        address usdc,
        address aavePoolAddressesProvider,
        address comet,
        address share
    ) YieldPeer(ccipRouter, link, thisChainSelector, usdc, aavePoolAddressesProvider, comet, share) {
        // @review modularize this
        // @review CHANGE THIS TO COMPOUND IF PARENT IS BASE SEPOLIA - AAVE V3 IS NOT ON BASE SEPOLIA
        s_strategy = Strategy({chainSelector: thisChainSelector, protocol: Protocol.Aave});
        _updateStrategyPool(thisChainSelector, Protocol.Aave);
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Users can deposit USDC into the system via this function
    /// @notice As this is the ParentPeer, we handle two deposit cases:
    /// 1. This Parent is the Strategy
    /// 2. This Parent is not the Strategy
    /// @param amountToDeposit The amount of USDC to deposit into the system
    /// @dev Revert if amountToDeposit is 0
    function deposit(uint256 amountToDeposit) external override {
        _initiateDeposit(amountToDeposit);

        Strategy memory strategy = s_strategy;

        // 1. This Parent is the Strategy. Therefore the deposit is handled here and shares can be minted here.
        if (strategy.chainSelector == i_thisChainSelector) {
            uint256 totalValue = _depositToStrategyAndGetTotalValue(amountToDeposit);

            uint256 shareMintAmount = _calculateMintAmount(totalValue, amountToDeposit);
            s_totalShares += shareMintAmount;

            /// @dev mint SHAREs to msg.sender based on amount deposited and total value of the system
            _mintShares(msg.sender, shareMintAmount);
            emit ShareMintUpdate(shareMintAmount, i_thisChainSelector, s_totalShares);
        }
        // 2. This Parent is not the Strategy. Therefore the deposit must be sent to the strategy and get totalValue.
        else {
            DepositData memory depositData = _buildDepositData(amountToDeposit);
            _ccipSend(strategy.chainSelector, CcipTxType.DepositToStrategy, abi.encode(depositData), amountToDeposit);
            emit DepositForwardedToStrategy(amountToDeposit, strategy.chainSelector);
        }
    }

    /// @notice This function is called when SHAREs are transferred to this peer
    /// @notice This function is used to withdraw USDC from the system
    /// @param withdrawer The address that transferred the SHAREs to withdraw their USDC from the system
    /// @param shareBurnAmount The amount of SHAREs transferred to be burned
    /// @param encodedWithdrawChainSelector The encoded chain selector to withdraw USDC to. If this is empty, the withdrawn USDC will be sent back to this chain
    /// @dev Revert if encodedWithdrawChainSelector doesn't decode to an allowed chain selector
    /// @dev Revert if msg.sender is not the SHARE token
    /// @dev Revert if shareBurnAmount is 0
    /// @dev Update s_totalShares and burn shares from msg.sender
    /// @dev Handle the case where the parent is the strategy
    /// @dev Handle the case where the parent is not the strategy
    function onTokenTransfer(address withdrawer, uint256 shareBurnAmount, bytes calldata encodedWithdrawChainSelector)
        external
        override
    {
        _revertIfMsgSenderIsNotShare();

        _revertIfZeroAmount(shareBurnAmount);

        uint64 withdrawChainSelector = _decodeWithdrawChainSelector(encodedWithdrawChainSelector);

        /// @dev cache totalShares before updating
        uint256 totalShares = s_totalShares;

        /// @dev update s_totalShares and burn shares from msg.sender
        s_totalShares -= shareBurnAmount;
        _burnShares(withdrawer, shareBurnAmount);
        emit ShareBurnUpdate(shareBurnAmount, i_thisChainSelector, totalShares - shareBurnAmount);
        emit WithdrawInitiated(withdrawer, shareBurnAmount, i_thisChainSelector);

        Strategy memory strategy = s_strategy;

        // 1. This Parent is the Strategy. Therefore the usdcWithdrawAmount is calculated and withdrawal is handled here.
        if (strategy.chainSelector == i_thisChainSelector) {
            address strategyPool = _getStrategyPool();
            uint256 totalValue = _getTotalValueFromStrategy(strategyPool);

            uint256 usdcWithdrawAmount = _calculateWithdrawAmount(totalValue, totalShares, shareBurnAmount);

            _withdrawFromStrategy(strategyPool, usdcWithdrawAmount);

            if (withdrawChainSelector == i_thisChainSelector) {
                _transferUsdcTo(withdrawer, usdcWithdrawAmount);
                emit WithdrawCompleted(withdrawer, usdcWithdrawAmount);
            } else {
                WithdrawData memory withdrawData =
                    _buildWithdrawData(withdrawer, shareBurnAmount, withdrawChainSelector);
                withdrawData.usdcWithdrawAmount = usdcWithdrawAmount;
                _ccipSend(
                    withdrawChainSelector, CcipTxType.WithdrawCallback, abi.encode(withdrawData), usdcWithdrawAmount
                );
            }
        }
        // 2. This Parent is not the Strategy. Therefore the shareBurnAmount is sent to the strategy and the USDC tokens usdcWithdrawAmount is sent back.
        else {
            WithdrawData memory withdrawData = _buildWithdrawData(withdrawer, shareBurnAmount, withdrawChainSelector);
            withdrawData.totalShares = totalShares;
            _ccipSend(
                strategy.chainSelector, CcipTxType.WithdrawToStrategy, abi.encode(withdrawData), ZERO_BRIDGE_AMOUNT
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Receives a CCIP message from a peer
    /// The CCIP message received
    /// - CcipTxType DepositToParent: A tx from child to parent to deposit USDC in strategy
    /// - CcipTxType DepositCallbackParent: A tx from the strategy to parent to calculate shareMintAmount and mint shares to the depositor on this chain or another child chain
    /// - CcipTxType WithdrawCallback: A tx from the strategy chain to send USDC to the withdrawer
    /// - CcipTxType WithdrawToParent: A tx from the withdraw chain to forward to the strategy chain
    /// - CcipTxType RebalanceNewStrategy: A tx from the old strategy, sending rebalanced funds to the new strategy
    function _handleCCIPMessage(CcipTxType txType, Client.EVMTokenAmount[] memory tokenAmounts, bytes memory data)
        internal
        override
    {
        if (txType == CcipTxType.DepositToParent) _handleCCIPDepositToParent(tokenAmounts, data);
        if (txType == CcipTxType.DepositCallbackParent) _handleCCIPDepositCallbackParent(data);
        if (txType == CcipTxType.WithdrawToParent) _handleCCIPWithdrawToParent(data);
        if (txType == CcipTxType.WithdrawCallback) _handleCCIPWithdrawCallback(tokenAmounts, data);
        if (txType == CcipTxType.RebalanceNewStrategy) _handleCCIPRebalanceNewStrategy(data);
    }

    /// @notice This function handles a deposit from a child to this parent and the 3 strategy cases:
    /// 1. This Parent is the Strategy
    /// 2. The Child where the deposit was made is the Strategy
    /// 3. The Strategy is on a third chain
    /// @notice Deposit txs need to be handled via the parent to read the state containing the strategy
    function _handleCCIPDepositToParent(Client.EVMTokenAmount[] memory tokenAmounts, bytes memory encodedDepositData)
        internal
    {
        DepositData memory depositData = abi.decode(encodedDepositData, (DepositData));
        Strategy memory strategy = s_strategy;

        /// @dev Validate token amounts for all cases except when strategy is on deposit chain
        if (strategy.chainSelector != depositData.chainSelector) {
            CCIPOperations._validateTokenAmounts(tokenAmounts, address(i_usdc), depositData.amount);
        }

        /// @dev If Strategy is on this Parent, deposit into strategy and get totalValue
        if (strategy.chainSelector == i_thisChainSelector) {
            depositData.totalValue = _depositToStrategyAndGetTotalValue(depositData.amount);
        }
        /// @dev If the Strategy is this Parent or where the deposit originated, calculate and CCIP send shareMintAmount
        if (strategy.chainSelector == i_thisChainSelector || strategy.chainSelector == depositData.chainSelector) {
            depositData.shareMintAmount = _calculateMintAmount(depositData.totalValue, depositData.amount);
            s_totalShares += depositData.shareMintAmount;
            emit ShareMintUpdate(depositData.shareMintAmount, i_thisChainSelector, s_totalShares);

            _ccipSend(
                depositData.chainSelector, CcipTxType.DepositCallbackChild, abi.encode(depositData), ZERO_BRIDGE_AMOUNT
            );
        }
        /// @dev If Strategy is on third chain, forward deposit to strategy
        if (strategy.chainSelector != i_thisChainSelector && strategy.chainSelector != depositData.chainSelector) {
            _ccipSend(strategy.chainSelector, CcipTxType.DepositToStrategy, encodedDepositData, depositData.amount);
            emit DepositForwardedToStrategy(depositData.amount, strategy.chainSelector);
        }
    }

    /// @notice This function handles a deposit callback from the strategy to this parent
    /// deposit on child -> parent -> strategy -> callback to parent (HERE) -> callback to child
    /// @notice DepositData should include totalValue at this point because this is callback from strategy
    /// @notice The two cases being handled here are:
    /// 1. Deposit was made on this parent chain, but strategy is on another chain, so share minting is done here after getting totalValue from strategy
    /// 2. Deposit was made on a child chain, so calculated shareMintAmount is passed to that child after getting totalValue from strategy
    function _handleCCIPDepositCallbackParent(bytes memory data) internal {
        /// @dev decode the deposit data and total value in the system
        DepositData memory depositData = _decodeDepositData(data);

        /// @dev calculate shareMintAmount based on depositData.totalValue and depositData.amount
        depositData.shareMintAmount = _calculateMintAmount(depositData.totalValue, depositData.amount);
        /// @dev update s_totalShares += shareMintAmount
        s_totalShares += depositData.shareMintAmount;

        /// @dev handle the case where the deposit was made on this parent chain
        if (depositData.chainSelector == i_thisChainSelector) {
            _mintShares(depositData.depositor, depositData.shareMintAmount);
        }
        /// @dev handle the case where the deposit was made on a child chain
        else {
            /// @dev ccipSend the shareMintAmount to the child chain
            _ccipSend(
                depositData.chainSelector, CcipTxType.DepositCallbackChild, abi.encode(depositData), ZERO_BRIDGE_AMOUNT
            );
        }

        emit ShareMintUpdate(depositData.shareMintAmount, i_thisChainSelector, s_totalShares);
    }

    /// @notice This function handles a withdraw tx that initiated on another chain.
    /// If this Parent is the strategy, we withdraw and send the USDC back to the withdrawer
    /// If this Parent is the strategy AND the withdrawer wants the USDC on this chain, we transfer it directly
    /// If this Parent is not the strategy, we forward the withdrawData to the strategy
    /// @dev Updates s_totalShares and emits ShareBurnUpdate
    function _handleCCIPWithdrawToParent(bytes memory data) internal {
        WithdrawData memory withdrawData = _decodeWithdrawData(data);
        withdrawData.totalShares = s_totalShares;
        s_totalShares -= withdrawData.shareBurnAmount;
        emit ShareBurnUpdate(
            withdrawData.shareBurnAmount, i_thisChainSelector, withdrawData.totalShares - withdrawData.shareBurnAmount
        );

        Strategy memory strategy = s_strategy;

        // 1. If the parent is the strategy, we want to use the totalShares and shareBurnAmount to calculate the usdcWithdrawAmount then withdraw it and ccipSend it back to the withdrawer
        if (strategy.chainSelector == i_thisChainSelector) {
            withdrawData.usdcWithdrawAmount = _withdrawFromStrategyAndGetUsdcWithdrawAmount(withdrawData);

            if (withdrawData.chainSelector == i_thisChainSelector) {
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
        // 2. If the parent is not the strategy, we want to forward the withdrawData to the strategy
        else {
            _ccipSend(
                strategy.chainSelector, CcipTxType.WithdrawToStrategy, abi.encode(withdrawData), ZERO_BRIDGE_AMOUNT
            );
            emit WithdrawForwardedToStrategy(withdrawData.usdcWithdrawAmount, strategy.chainSelector);
        }
    }

    /// @notice This function sets the strategy on the parent
    /// @notice This function uses ccipSend to send the rebalance message to the old strategy
    /// @notice Rebalances funds from the old strategy to the new strategy
    /// @notice Handles the case where both the old and new strategy are on this chain
    /// @notice Handles the case where the old or new strategies are on different chains with ccipSend
    /// @param chainSelector The chain selector of the new strategy
    /// @param protocol The protocol of the new strategy
    function _setStrategy(uint64 chainSelector, Protocol protocol) internal {
        Strategy memory oldStrategy = s_strategy;
        Strategy memory newStrategy = Strategy({chainSelector: chainSelector, protocol: protocol});

        // Early return if strategy hasn't changed
        if (!_updateStrategy(newStrategy, oldStrategy)) {
            return;
        }
        // Handle strategy changes on the this parent chain
        if (
            chainSelector == i_thisChainSelector && oldStrategy.chainSelector == i_thisChainSelector
                && protocol != oldStrategy.protocol
        ) {
            _handleLocalStrategyChange(newStrategy);
        }
        // Handle moving strategy from this parent chain to a different chain
        else if (oldStrategy.chainSelector == i_thisChainSelector && chainSelector != i_thisChainSelector) {
            _handleStrategyMoveToNewChain(newStrategy);
        }
        // Handle rebalancing from a different chain (a child)
        else {
            _handleRebalanceFromDifferentChain(oldStrategy, newStrategy);
        }
    }

    /// @notice Internal helper to handle strategy updates
    /// @param newStrategy The new strategy to set
    /// @param oldStrategy The current strategy
    /// @return bool Whether the strategy was actually changed
    function _updateStrategy(Strategy memory newStrategy, Strategy memory oldStrategy) internal returns (bool) {
        if (oldStrategy.chainSelector == newStrategy.chainSelector && oldStrategy.protocol == newStrategy.protocol) {
            emit CurrentStrategyOptimal(newStrategy.chainSelector, newStrategy.protocol);
            return false;
        }
        s_strategy = newStrategy;
        return true;
    }

    /// @notice Handles strategy change when both old and new strategies are on this chain
    /// @param newStrategy The new strategy
    function _handleLocalStrategyChange(Strategy memory newStrategy) internal {
        address oldStrategyPool = _getStrategyPool();
        uint256 totalValue = _getTotalValueFromStrategy(oldStrategyPool);
        if (totalValue != 0) _withdrawFromStrategy(oldStrategyPool, totalValue);
        address newStrategyPool = _updateStrategyPool(newStrategy.chainSelector, newStrategy.protocol);
        _depositToStrategy(newStrategyPool, i_usdc.balanceOf(address(this)));
    }

    /// @notice Handles moving strategy to a different chain
    /// @param newStrategy The new strategy
    function _handleStrategyMoveToNewChain(Strategy memory newStrategy) internal {
        address oldStrategyPool = _getStrategyPool();
        uint256 totalValue = _getTotalValueFromStrategy(oldStrategyPool);
        if (totalValue != 0) _withdrawFromStrategy(oldStrategyPool, totalValue);
        _updateStrategyPool(newStrategy.chainSelector, newStrategy.protocol);
        _ccipSend(
            newStrategy.chainSelector,
            CcipTxType.RebalanceNewStrategy,
            abi.encode(newStrategy),
            i_usdc.balanceOf(address(this))
        );
    }

    /// @notice Handles rebalancing when strategy is on a different chain
    /// @param oldStrategy The current strategy
    /// @param newStrategy The new strategy
    function _handleRebalanceFromDifferentChain(Strategy memory oldStrategy, Strategy memory newStrategy) internal {
        _ccipSend(
            oldStrategy.chainSelector, CcipTxType.RebalanceOldStrategy, abi.encode(newStrategy), ZERO_BRIDGE_AMOUNT
        );
    }

    /*//////////////////////////////////////////////////////////////
                             INTERNAL VIEW
    //////////////////////////////////////////////////////////////*/
    /// @param totalValue The total value of the system to 6 decimals
    /// @param amount The amount of USDC deposited
    /// @return shareMintAmount The amount of SHAREs to mint
    /// @notice Returns amount * (SHARE_DECIMALS / USDC_DECIMALS) if there are no shares minted yet
    /// @dev Revert if totalValue is 0 (should never happen, but just in case)
    function _calculateMintAmount(uint256 totalValue, uint256 amount) internal view returns (uint256 shareMintAmount) {
        uint256 totalShares = s_totalShares;
        // @review if totalShares isn't 0, then totalValue shouldn't be either.
        if (totalShares == 0 || totalValue == 0) shareMintAmount = amount * INITIAL_SHARE_PRECISION;
        else shareMintAmount = (amount * totalShares) / totalValue;
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    function getStrategy() external view returns (Strategy memory) {
        return s_strategy;
    }

    function getTotalShares() external view returns (uint256) {
        return s_totalShares;
    }
}
