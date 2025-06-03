// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {YieldPeer, Client, IRouterClient} from "./YieldPeer.sol";

contract ParentPeer is YieldPeer {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev total SHAREs minted across all chains
    // @invariant s_totalShares == ghost_totalSharesMinted - ghost_totalSharesBurned
    uint256 internal s_totalShares;
    // @review could change this to just a s_strategyChainSelector
    Strategy internal s_strategy;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event CurrentStrategyOptimal(uint64 indexed chainSelector, Protocol indexed protocol);

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
        address share
    ) YieldPeer(ccipRouter, link, thisChainSelector, usdc, aavePoolAddressesProvider, comet, share) {
        // @review modularize this
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
        _revertIfZeroAmount(amountToDeposit);

        _transferUsdcFrom(msg.sender, address(this), amountToDeposit);

        Strategy memory strategy = s_strategy;

        // 1. This Parent is the Strategy. Therefore the deposit is handled here and shares can be minted here.
        if (strategy.chainSelector == i_thisChainSelector) {
            uint256 totalValue = _depositToStrategyAndGetTotalValue(amountToDeposit);

            uint256 shareMintAmount = _calculateMintAmount(totalValue, amountToDeposit);
            s_totalShares += shareMintAmount;

            /// @dev mint SHAREs to msg.sender based on amount deposited and total value of the system
            _mintShares(msg.sender, shareMintAmount);
        }
        // 2. This Parent is not the Strategy. Therefore the deposit must be sent to the strategy and get totalValue.
        else {
            DepositData memory depositData = _buildDepositData(amountToDeposit);
            bytes32 ccipMessageId = _ccipSend(
                strategy.chainSelector, CcipTxType.DepositToStrategy, abi.encode(depositData), amountToDeposit
            );
        }
    }

    /// @notice This function is called when SHAREs are transferred to this peer
    /// @notice This function is used to withdraw USDC from the system
    /// @param withdrawer The address that transferred the SHAREs to withdraw their USDC from the system
    /// @param shareBurnAmount The amount of SHAREs transferred to be burned
    /// @param data The data passed in the transfer
    function onTokenTransfer(address withdrawer, uint256 shareBurnAmount, bytes calldata data) external override {
        _revertIfMsgSenderIsNotShare();

        _revertIfZeroAmount(shareBurnAmount);

        /// @dev cache totalShares before updating
        uint256 totalShares = s_totalShares;

        /// @dev update s_totalShares and burn shares from msg.sender
        s_totalShares -= shareBurnAmount;
        _burnShares(shareBurnAmount);

        Strategy memory strategy = s_strategy;

        // 1. This Parent is the Strategy. Therefore the usdcWithdrawAmount is calculated and withdrawal is handled here.
        if (strategy.chainSelector == i_thisChainSelector) {
            address strategyPool = _getStrategyPool();
            uint256 totalValue = _getTotalValueFromStrategy(strategyPool);
            emit DebugWithdrawCalculation(totalValue, totalShares, shareBurnAmount);

            uint256 usdcWithdrawAmount = _calculateWithdrawAmount(totalValue, totalShares, shareBurnAmount);
            // emit DebugWithdrawAmount(usdcWithdrawAmount);

            _withdrawFromStrategy(strategyPool, usdcWithdrawAmount);
            _transferUsdcTo(withdrawer, usdcWithdrawAmount);
        }
        // 2. This Parent is not the Strategy. Therefore the shareBurnAmount is sent to the strategy and the USDC tokens usdcWithdrawAmount is sent back.
        else {
            WithdrawData memory withdrawData = _buildWithdrawData(withdrawer, shareBurnAmount);
            withdrawData.totalShares = totalShares;
            bytes32 ccipMessageId = _ccipSend(
                strategy.chainSelector, CcipTxType.WithdrawToStrategy, abi.encode(withdrawData), ZERO_BRIDGE_AMOUNT
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Receives a CCIP message from a peer
    /// @param message The CCIP message received
    /// - CcipTxType DepositToParent: A tx from child to parent to deposit USDC in strategy
    /// - CcipTxType DepositCallbackParent: A tx from the strategy to parent to calculate shareMintAmount and mint shares to the depositor on this chain or another child chain
    function _ccipReceive(Client.Any2EVMMessage memory message)
        internal
        override
        onlyAllowed(message.sourceChainSelector, abi.decode(message.sender, (address)))
    {
        (CcipTxType txType, bytes memory data) = abi.decode(message.data, (CcipTxType, bytes));

        if (txType == CcipTxType.DepositToParent) _handleDepositToParent(message.destTokenAmounts, data);
        if (txType == CcipTxType.DepositCallbackParent) _handleDepositCallbackParent(data);
        if (txType == CcipTxType.WithdrawCallback) _handleCCIPWithdrawCallback(message.destTokenAmounts, data);
        if (txType == CcipTxType.WithdrawToParent) _handleWithdrawToParent(data);

        // rebalance tx type handling
    }

    /// @notice This function handles a deposit from a child to this parent and the 3 strategy cases:
    /// 1. This Parent is the Strategy
    /// 2. The Child where the deposit was made is the Strategy
    /// 3. The Strategy is on a third chain
    /// @notice Deposit txs need to be handled via the parent to read the state containing the strategy
    function _handleDepositToParent(Client.EVMTokenAmount[] memory tokenAmounts, bytes memory encodedDepositData)
        internal
    {
        DepositData memory depositData = abi.decode(encodedDepositData, (DepositData));
        Strategy memory strategy = s_strategy;

        /// @dev Validate token amounts for all cases except when strategy is on deposit chain
        if (strategy.chainSelector != depositData.chainSelector) {
            _validateTokenAmounts(tokenAmounts, depositData.amount);
        }

        /// @dev If Strategy is on this Parent, deposit into strategy and get totalValue
        if (strategy.chainSelector == i_thisChainSelector) {
            depositData.totalValue = _depositToStrategyAndGetTotalValue(depositData.amount);
        }
        /// @dev If the Strategy is this Parent or where the deposit originated, calculate and CCIP send shareMintAmount
        if (strategy.chainSelector == i_thisChainSelector || strategy.chainSelector == depositData.chainSelector) {
            depositData.shareMintAmount = _calculateMintAmount(depositData.totalValue, depositData.amount);
            s_totalShares += depositData.shareMintAmount;

            bytes32 ccipMessageId = _ccipSend(
                depositData.chainSelector, CcipTxType.DepositCallbackChild, abi.encode(depositData), ZERO_BRIDGE_AMOUNT
            );
            // do something with ccipMessageId?
        }
        /// @dev If Strategy is on third chain, forward deposit to strategy
        if (strategy.chainSelector != i_thisChainSelector && strategy.chainSelector != depositData.chainSelector) {
            bytes32 ccipMessageId =
                _ccipSend(strategy.chainSelector, CcipTxType.DepositToStrategy, encodedDepositData, depositData.amount);
            // do something with ccipMessageId?
        }
    }

    /// @notice This function handles a deposit callback from the strategy to this parent
    /// deposit on child -> parent -> strategy -> callback to parent (HERE) -> callback to child
    /// @notice DepositData should include totalValue at this point because this is callback from strategy
    /// @notice The two cases being handled here are:
    /// 1. Deposit was made on this parent chain, but strategy is on another chain, so share minting is done here after getting totalValue from strategy
    /// 2. Deposit was made on a child chain, so calculated shareMintAmount is passed to that child after getting totalValue from strategy
    function _handleDepositCallbackParent(bytes memory data) internal {
        /// @dev decode the deposit data and total value in the system
        DepositData memory depositData = abi.decode(data, (DepositData));

        /// @dev calculate shareMintAmount based on depositData.totalValue and depositData.amount
        depositData.shareMintAmount = _calculateMintAmount(depositData.totalValue, depositData.amount);
        /// @dev update s_totalShares += shareMintAmount
        s_totalShares += depositData.shareMintAmount;

        /// @dev handle the case where the deposit was made on this parent chain
        if (depositData.chainSelector == i_thisChainSelector) {
            _mintShares(depositData.depositor, depositData.shareMintAmount);
            // emit event
        }
        /// @dev handle the case where the deposit was made on a child chain
        else {
            /// @dev ccipSend the shareMintAmount to the child chain
            bytes32 ccipMessageId = _ccipSend(
                depositData.chainSelector, CcipTxType.DepositCallbackChild, abi.encode(depositData), ZERO_BRIDGE_AMOUNT
            );
            // emit event
        }
    }

    function _handleWithdrawToParent(bytes memory data) internal {
        WithdrawData memory withdrawData = abi.decode(data, (WithdrawData));
        withdrawData.totalShares = s_totalShares;
        s_totalShares -= withdrawData.shareBurnAmount;

        Strategy memory strategy = s_strategy;

        // 1. If the parent is the strategy, we want to use the totalShares and shareBurnAmount to calculate the usdcWithdrawAmount
        // then withdraw it and ccipSend it back to the withdrawer
        if (strategy.chainSelector == i_thisChainSelector) {
            withdrawData.usdcWithdrawAmount = _withdrawFromStrategyAndGetUsdcWithdrawAmount(withdrawData);

            bytes32 ccipMessageId = _ccipSend(
                withdrawData.chainSelector,
                CcipTxType.WithdrawCallback,
                abi.encode(withdrawData),
                withdrawData.usdcWithdrawAmount
            );
        }
        // 2. If the parent is not the strategy, we want to forward the withdrawData to the strategy
        else {
            bytes32 ccipMessageId = _ccipSend(
                strategy.chainSelector, CcipTxType.WithdrawToStrategy, abi.encode(withdrawData), ZERO_BRIDGE_AMOUNT
            );
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

        // Handle strategy changes on the same chain
        if (
            chainSelector == i_thisChainSelector && oldStrategy.chainSelector == i_thisChainSelector
                && protocol != oldStrategy.protocol
        ) {
            _handleLocalStrategyChange(oldStrategy, newStrategy);
        }
        // Handle moving strategy to a different chain
        else if (oldStrategy.chainSelector == i_thisChainSelector && chainSelector != i_thisChainSelector) {
            _handleStrategyMoveToNewChain(oldStrategy, newStrategy);
        }
        // Handle rebalancing from a different chain
        else if (oldStrategy.chainSelector != chainSelector) {
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
    /// @param oldStrategy The current strategy
    /// @param newStrategy The new strategy
    function _handleLocalStrategyChange(Strategy memory oldStrategy, Strategy memory newStrategy) internal {
        address oldStrategyPool = _getStrategyPool();
        uint256 totalValue = _getTotalValueFromStrategy(oldStrategyPool);
        _withdrawFromStrategy(oldStrategyPool, totalValue);
        address newStrategyPool = _updateStrategyPool(newStrategy.chainSelector, newStrategy.protocol);
        _depositToStrategy(newStrategyPool, i_usdc.balanceOf(address(this)));
    }

    /// @notice Handles moving strategy to a different chain
    /// @param oldStrategy The current strategy
    /// @param newStrategy The new strategy
    function _handleStrategyMoveToNewChain(Strategy memory oldStrategy, Strategy memory newStrategy) internal {
        address oldStrategyPool = _getStrategyPool();
        uint256 totalValue = _getTotalValueFromStrategy(oldStrategyPool);
        _withdrawFromStrategy(oldStrategyPool, totalValue);
        _updateStrategyPool(newStrategy.chainSelector, newStrategy.protocol);
        _sendRebalanceMessage(
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
        _sendRebalanceMessage(
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
    function _calculateMintAmount(uint256 totalValue, uint256 amount) internal view returns (uint256) {
        uint256 totalShares = s_totalShares;
        if (totalShares == 0) return amount * INITIAL_SHARE_PRECISION;

        _revertIfZeroAmount(totalValue); // @review - is this superfluous?

        uint256 shareMintAmount = (amount * totalShares) / totalValue;
        return shareMintAmount;
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

    // @review REMOVE THIS OR REPLACE IT WITH A WRAPPER
    function setStrategy(uint64 chainSelector, Protocol protocol) external {
        _updateStrategyPool(chainSelector, protocol);
        s_strategy = Strategy({chainSelector: chainSelector, protocol: protocol});
    }
}
