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
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ParentPeer__OnlyRebalancer();

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev This address handles automated CCIP rebalance calls with Log-trigger Automation, based on Function request callbacks
    /// @notice See ./src/modules/Rebalancer.sol
    address internal immutable i_rebalancer;

    /// @dev total share tokens (YieldCoin) minted across all chains
    // @invariant s_totalShares == ghost_totalSharesMinted - ghost_totalSharesBurned
    uint256 internal s_totalShares;
    /// @dev The current strategy: chainSelector and protocol
    Strategy internal s_strategy;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when the current strategy is optimal
    event CurrentStrategyOptimal(uint64 indexed chainSelector, Protocol indexed protocol);
    /// @notice Emitted when the strategy is updated
    event StrategyUpdated(uint64 indexed chainSelector, Protocol indexed protocol, uint64 indexed oldChainSelector);
    /// @notice Emitted when the amount of shares minted is updated
    event ShareMintUpdate(uint256 indexed shareMintAmount, uint64 indexed chainSelector, uint256 indexed totalShares);
    /// @notice Emitted when the amount of shares burned is updated
    event ShareBurnUpdate(uint256 indexed shareBurnAmount, uint64 indexed chainSelector, uint256 indexed totalShares);
    /// @notice Emitted when a deposit is forwarded to the strategy
    event DepositForwardedToStrategy(uint256 indexed depositAmount, uint64 indexed strategyChainSelector);
    /// @notice Emitted when a withdraw is forwarded to the strategy
    event WithdrawForwardedToStrategy(uint256 indexed shareBurnAmount, uint64 indexed strategyChainSelector);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param ccipRouter The address of the CCIP router
    /// @param link The address of the LINK token
    /// @param thisChainSelector The selector of the chain this contract is deployed on
    /// @param usdc The address of the USDC token
    /// @param aavePoolAddressesProvider The address of the Aave pool addresses provider
    /// @param comet The address of the Compound v3 cUSDCv3 contract
    /// @param share The address of the share token native to this system that is minted in exchange for USDC deposits (YieldCoin)
    /// @dev Initial Strategy is set to Aave on this chain
    constructor(
        address ccipRouter,
        address link,
        uint64 thisChainSelector,
        address usdc,
        address aavePoolAddressesProvider,
        address comet,
        address share,
        address rebalancer
    ) YieldPeer(ccipRouter, link, thisChainSelector, usdc, aavePoolAddressesProvider, comet, share) {
        s_strategy = Strategy({chainSelector: thisChainSelector, protocol: Protocol.Aave});
        _updateActiveStrategyAdapter(thisChainSelector, Protocol.Aave);
        // slither-disable-next-line missing-zero-check
        i_rebalancer = rebalancer;
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Users can deposit USDC into the system via this function
    /// @notice As this is the ParentPeer, we handle two deposit cases:
    /// 1. This Parent is the Strategy
    /// 2. This Parent is not the Strategy
    /// @param amountToDeposit The amount of USDC to deposit into the system
    /// @dev Revert if amountToDeposit is less than 1e6 (1 USDC)
    function deposit(uint256 amountToDeposit) external override {
        _initiateDeposit(amountToDeposit);

        Strategy memory strategy = s_strategy;

        // 1. This Parent is the Strategy. Therefore the deposit is handled here and shares can be minted here.
        if (strategy.chainSelector == i_thisChainSelector) {
            uint256 totalValue = _depositToStrategyAndGetTotalValue(amountToDeposit);

            uint256 shareMintAmount = _calculateMintAmount(totalValue, amountToDeposit);
            s_totalShares += shareMintAmount;

            /// @dev mint share tokens (YieldCoin) to msg.sender based on amount deposited and total value of the system
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

    /// @notice This function is called when YieldCoin/share tokens are transferred to this peer
    /// @notice This function is used to withdraw USDC from the system
    /// @param withdrawer The address that transferred the YieldCoin to withdraw their USDC from the system
    /// @param shareBurnAmount The amount of YieldCoin transferred to be burned
    /// @param encodedWithdrawChainSelector The encoded chain selector to withdraw USDC to. If this is empty, the withdrawn USDC will be sent back to this chain
    /// @dev Revert if encodedWithdrawChainSelector doesn't decode to an allowed chain selector
    /// @dev Revert if msg.sender is not the YieldCoin/share token
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
            address activeStrategyAdapter = _getActiveStrategyAdapter();
            uint256 totalValue = _getTotalValueFromStrategy(activeStrategyAdapter, address(i_usdc));

            uint256 usdcWithdrawAmount = _calculateWithdrawAmount(totalValue, totalShares, shareBurnAmount);

            if (usdcWithdrawAmount != 0) _withdrawFromStrategy(activeStrategyAdapter, usdcWithdrawAmount);

            if (withdrawChainSelector == i_thisChainSelector) {
                if (usdcWithdrawAmount != 0) _transferUsdcTo(withdrawer, usdcWithdrawAmount);
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

    /// @dev Revert if msg.sender is not the ParentRebalancer
    /// @dev Handle moving strategy from this parent chain to a different chain
    /// @param oldStrategyPool The address of the old strategy pool
    /// @param totalValue The total value of the system
    /// @param newStrategy The new strategy
    /// @notice This function is called by the ParentRebalancer's Log-trigger Automation performUpkeep
    function rebalanceNewStrategy(address oldStrategyPool, uint256 totalValue, Strategy memory newStrategy) external {
        _revertIfMsgSenderIsNotRebalancer();
        _handleStrategyMoveToNewChain(oldStrategyPool, totalValue, newStrategy);
    }

    /// @dev Revert if msg.sender is not the ParentRebalancer
    /// @dev Handle rebalancing from a different chain
    /// @param oldChainSelector The chain selector of the old strategy
    /// @param newStrategy The new strategy
    /// @notice This function is called by the ParentRebalancer's Log-trigger Automation performUpkeep
    function rebalanceOldStrategy(uint64 oldChainSelector, Strategy memory newStrategy) external {
        _revertIfMsgSenderIsNotRebalancer();
        Strategy memory oldStrategy = Strategy({chainSelector: oldChainSelector, protocol: Protocol.Aave});
        _handleRebalanceFromDifferentChain(oldStrategy, newStrategy);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Receives a CCIP message from a peer
    /// @param txType The type of CCIP message received - see IYieldPeer.CcipTxType
    /// The CCIP message received
    /// - CcipTxType DepositToParent: A tx from child to parent to deposit USDC in strategy
    /// - CcipTxType DepositCallbackParent: A tx from the strategy to parent to calculate shareMintAmount and mint shares to the depositor on this chain or another child chain
    /// - CcipTxType WithdrawCallback: A tx from the strategy chain to send USDC to the withdrawer
    /// - CcipTxType WithdrawToParent: A tx from the withdraw chain to forward to the strategy chain
    /// - CcipTxType RebalanceNewStrategy: A tx from the old strategy, sending rebalanced funds to the new strategy
    /// @param tokenAmounts The token amounts received in the CCIP message
    /// @param data The data received in the CCIP message
    /// @param sourceChainSelector The chain selector of the chain where the message originated from
    function _handleCCIPMessage(
        CcipTxType txType,
        Client.EVMTokenAmount[] memory tokenAmounts,
        bytes memory data,
        uint64 sourceChainSelector
    ) internal override {
        if (txType == CcipTxType.DepositToParent) _handleCCIPDepositToParent(tokenAmounts, data);
        if (txType == CcipTxType.DepositCallbackParent) _handleCCIPDepositCallbackParent(data);
        if (txType == CcipTxType.WithdrawToParent) _handleCCIPWithdrawToParent(data, sourceChainSelector);
        if (txType == CcipTxType.WithdrawCallback) _handleCCIPWithdrawCallback(tokenAmounts, data);
        if (txType == CcipTxType.RebalanceNewStrategy) _handleCCIPRebalanceNewStrategy(data);
    }

    /// @notice This function handles a deposit from a child to this parent and the 2 strategy cases:
    /// 1. This Parent is the Strategy
    /// 2. The Strategy is on a third chain
    /// @notice Deposit txs need to be handled via the parent to read the state containing the strategy
    /// @param tokenAmounts The token amounts received in the CCIP message
    /// @param encodedDepositData The encoded deposit data
    function _handleCCIPDepositToParent(Client.EVMTokenAmount[] memory tokenAmounts, bytes memory encodedDepositData)
        internal
    {
        DepositData memory depositData = abi.decode(encodedDepositData, (DepositData));
        Strategy memory strategy = s_strategy;

        CCIPOperations._validateTokenAmounts(tokenAmounts, address(i_usdc), depositData.amount);

        /// @dev If Strategy is on this Parent, deposit into strategy and get totalValue
        if (strategy.chainSelector == i_thisChainSelector) {
            depositData.totalValue = _depositToStrategyAndGetTotalValue(depositData.amount);
            depositData.shareMintAmount = _calculateMintAmount(depositData.totalValue, depositData.amount);
            s_totalShares += depositData.shareMintAmount;
            emit ShareMintUpdate(depositData.shareMintAmount, depositData.chainSelector, s_totalShares);

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
    /// @param data The encoded DepositData
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
            emit ShareMintUpdate(depositData.shareMintAmount, i_thisChainSelector, s_totalShares);
        }
        /// @dev handle the case where the deposit was made on a child chain
        else {
            /// @dev ccipSend the shareMintAmount to the child chain
            _ccipSend(
                depositData.chainSelector, CcipTxType.DepositCallbackChild, abi.encode(depositData), ZERO_BRIDGE_AMOUNT
            );
            emit ShareMintUpdate(depositData.shareMintAmount, depositData.chainSelector, s_totalShares);
        }
    }

    /// @notice This function handles a withdraw tx that initiated on another chain.
    /// If this Parent is the strategy, we withdraw and send the USDC back to the withdrawer
    /// If this Parent is the strategy AND the withdrawer wants the USDC on this chain, we transfer it directly
    /// If this Parent is not the strategy, we forward the withdrawData to the strategy
    /// @dev Updates s_totalShares and emits ShareBurnUpdate
    /// @param data The encoded WithdrawData
    /// @param sourceChainSelector The chain selector of the chain where the withdraw originated from and shares were burned
    function _handleCCIPWithdrawToParent(bytes memory data, uint64 sourceChainSelector) internal {
        WithdrawData memory withdrawData = _decodeWithdrawData(data);
        withdrawData.totalShares = s_totalShares;
        s_totalShares -= withdrawData.shareBurnAmount;

        emit ShareBurnUpdate(
            withdrawData.shareBurnAmount, sourceChainSelector, withdrawData.totalShares - withdrawData.shareBurnAmount
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
            emit WithdrawForwardedToStrategy(withdrawData.shareBurnAmount, strategy.chainSelector);
        }
    }

    /// @notice This function sets the strategy on the parent
    /// @notice Called by Chainlink Functions callback - see ParentCLF.sol
    /// @notice Rebalances funds from the old strategy to the new strategy if both are on this chain
    /// @notice Handles the case where both the old and new strategy are on this chain
    /// @param chainSelector The chain selector of the new strategy
    /// @param protocol The protocol of the new strategy
    /// @dev StrategyUpdated event emitted in _updateStrategy will trigger ParentRebalancer::performUpkeep ccip rebalances
    /// @notice performUpkeep handles the case where the old or new strategies are on different chains with ccipSend
    function _setStrategy(uint64 chainSelector, Protocol protocol) internal {
        Strategy memory oldStrategy = s_strategy;
        Strategy memory newStrategy = Strategy({chainSelector: chainSelector, protocol: protocol});

        // Early return if strategy hasn't changed
        if (!_updateStrategy(newStrategy, oldStrategy)) {
            return;
        }
        // Handle strategy changes on the this parent chain
        if (chainSelector == i_thisChainSelector && oldStrategy.chainSelector == i_thisChainSelector) {
            _handleLocalStrategyChange(newStrategy);
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
        emit StrategyUpdated(newStrategy.chainSelector, newStrategy.protocol, oldStrategy.chainSelector);
        return true;
    }

    /// @notice Handles strategy change when both old and new strategies are on this chain
    /// @param newStrategy The new strategy
    function _handleLocalStrategyChange(Strategy memory newStrategy) internal {
        address oldActiveStrategyAdapter = _getActiveStrategyAdapter();
        uint256 totalValue = _getTotalValueFromStrategy(oldActiveStrategyAdapter, address(i_usdc));
        if (totalValue != 0) _withdrawFromStrategy(oldActiveStrategyAdapter, totalValue);
        address newActiveStrategyAdapter = _updateActiveStrategyAdapter(newStrategy.chainSelector, newStrategy.protocol);
        _depositToStrategy(newActiveStrategyAdapter, i_usdc.balanceOf(address(this)));
    }

    /// @notice Handles moving strategy to a different chain
    /// @param oldStrategyPool The address of the old strategy pool
    /// @param totalValue The total value of the system
    /// @param newStrategy The new strategy
    function _handleStrategyMoveToNewChain(address oldStrategyPool, uint256 totalValue, Strategy memory newStrategy)
        internal
    {
        if (totalValue != 0) _withdrawFromStrategy(oldStrategyPool, totalValue);
        _updateActiveStrategyAdapter(newStrategy.chainSelector, newStrategy.protocol);
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
    /// @return shareMintAmount The amount of shares/YieldCoin to mint
    /// @notice Returns amount * (SHARE_DECIMALS / USDC_DECIMALS) if there are no shares minted yet
    function _calculateMintAmount(uint256 totalValue, uint256 amount) internal view returns (uint256 shareMintAmount) {
        uint256 totalShares = s_totalShares;

        if (totalShares != 0) {
            shareMintAmount = (_convertUsdcToShare(amount) * totalShares) / _convertUsdcToShare(totalValue);
        } else {
            shareMintAmount = amount * INITIAL_SHARE_PRECISION;
        }

        if (shareMintAmount == 0) shareMintAmount = 1;
    }

    /// @dev Revert if msg.sender is not the Rebalancer
    function _revertIfMsgSenderIsNotRebalancer() internal view {
        if (msg.sender != i_rebalancer) revert ParentPeer__OnlyRebalancer();
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @dev Revert if msg.sender is not the ParentRebalancer
    /// @dev Set the strategy
    /// @param chainSelector The chain selector of the new strategy
    /// @param protocol The protocol of the new strategy
    function setStrategy(uint64 chainSelector, Protocol protocol) external {
        _revertIfMsgSenderIsNotRebalancer();
        _setStrategy(chainSelector, protocol);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Get the current strategy
    /// @return strategy The current strategy - chainSelector and protocol
    function getStrategy() external view returns (Strategy memory) {
        return s_strategy;
    }

    /// @notice Get the total shares minted across all chains
    /// @return totalShares The total shares minted across all chains
    function getTotalShares() external view returns (uint256) {
        return s_totalShares;
    }
}
