// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {YieldPeer, Client, IRouterClient, CCIPOperations, IERC20, SafeERC20} from "./YieldPeer.sol";

/// @title YieldCoin ParentPeer
/// @author @contractlevel
/// @notice This contract is the ParentPeer of the Contract Level Yield system
/// @notice This contract is deployed on only one chain
/// @notice Users can deposit and withdraw USDC to/from the system via this contract
/// @notice This contract tracks system wide state and acts as a system wide hub for forwarding CCIP messages to the Strategy
contract ParentPeer is YieldPeer {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ParentPeer__OnlyRebalancer();
    error ParentPeer__InitialActiveStrategyAlreadySet();

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev total share tokens (YieldCoin) minted across all chains
    // @invariant s_totalShares == ghost_totalSharesMinted - ghost_totalSharesBurned
    uint256 internal s_totalShares;
    /// @dev The current strategy: chainSelector and protocol
    Strategy internal s_strategy;
    /// @dev This address handles automated CCIP rebalance calls with Log-trigger Automation, based on Function request callbacks
    /// @notice See ./src/modules/Rebalancer.sol
    address internal s_rebalancer;
    /// @dev Whether the initial active strategy adapter has been set
    bool internal s_initialActiveStrategySet;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when the current strategy is optimal
    event CurrentStrategyOptimal(uint64 indexed chainSelector, bytes32 indexed protocolId);
    /// @notice Emitted when the strategy is updated
    event StrategyUpdated(uint64 indexed chainSelector, bytes32 indexed protocolId, uint64 indexed oldChainSelector);
    /// @notice Emitted when the amount of shares minted is updated
    event ShareMintUpdate(uint256 indexed shareMintAmount, uint64 indexed chainSelector, uint256 indexed totalShares);
    /// @notice Emitted when the amount of shares burned is updated
    event ShareBurnUpdate(uint256 indexed shareBurnAmount, uint64 indexed chainSelector, uint256 indexed totalShares);
    /// @notice Emitted when a deposit is forwarded to the strategy
    event DepositForwardedToStrategy(uint256 indexed depositAmount, uint64 indexed strategyChainSelector);
    /// @notice Emitted when a withdraw is forwarded to the strategy
    event WithdrawForwardedToStrategy(uint256 indexed shareBurnAmount, uint64 indexed strategyChainSelector);
    /// @notice Emitted when the rebalancer is set
    event RebalancerSet(address indexed rebalancer);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param ccipRouter The address of the CCIP router
    /// @param link The address of the LINK token
    /// @param thisChainSelector The selector of the chain this contract is deployed on
    /// @param usdc The address of the USDC token
    /// @param share The address of the share token native to this system that is minted in exchange for USDC deposits (YieldCoin)
    constructor(address ccipRouter, address link, uint64 thisChainSelector, address usdc, address share)
        YieldPeer(ccipRouter, link, thisChainSelector, usdc, share)
    {}

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
        /// @dev takes a fee
        amountToDeposit = _initiateDeposit(amountToDeposit);

        Strategy memory strategy = s_strategy;

        // 1. This Parent is the Strategy. Therefore the deposit is handled here and shares can be minted here.
        if (strategy.chainSelector == i_thisChainSelector) {
            /// @dev cache active strategy adapter
            address activeStrategyAdapter = _getActiveStrategyAdapter();

            /// @dev get total value from strategy
            uint256 totalValue = _getTotalValueFromStrategy(activeStrategyAdapter, address(i_usdc));

            /// @dev calculate share mint amount for total deposit (includes storage read of s_totalShares)
            uint256 shareMintAmount = _calculateMintAmount(totalValue, amountToDeposit);

            /// @dev update total shares (only once)
            s_totalShares += shareMintAmount;
            emit ShareMintUpdate(shareMintAmount, i_thisChainSelector, s_totalShares);

            /// @dev deposit to strategy
            //slither-disable-next-line reentrancy-events
            _depositToStrategy(activeStrategyAdapter, amountToDeposit);

            /// @dev mint share tokens (YieldCoin) to msg.sender based on amount deposited and total value of the system
            // @review deposit complete event?
            _mintShares(msg.sender, shareMintAmount);
        }
        // 2. This Parent is not the Strategy. Therefore the deposit must be sent to the strategy and get totalValue.
        else {
            DepositData memory depositData = _buildDepositData(amountToDeposit);
            emit DepositForwardedToStrategy(amountToDeposit, strategy.chainSelector);
            _ccipSend(strategy.chainSelector, CcipTxType.DepositToStrategy, abi.encode(depositData), amountToDeposit);
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
        emit ShareBurnUpdate(shareBurnAmount, i_thisChainSelector, totalShares - shareBurnAmount);
        emit WithdrawInitiated(withdrawer, shareBurnAmount, i_thisChainSelector);
        _burnShares(withdrawer, shareBurnAmount);

        Strategy memory strategy = s_strategy;

        // 1. This Parent is the Strategy. Therefore the usdcWithdrawAmount is calculated and withdrawal is handled here.
        if (strategy.chainSelector == i_thisChainSelector) {
            address activeStrategyAdapter = _getActiveStrategyAdapter();
            uint256 totalValue = _getTotalValueFromStrategy(activeStrategyAdapter, address(i_usdc));

            uint256 usdcWithdrawAmount = _calculateWithdrawAmount(totalValue, totalShares, shareBurnAmount);

            //slither-disable-next-line reentrancy-events
            if (usdcWithdrawAmount != 0) _withdrawFromStrategy(activeStrategyAdapter, usdcWithdrawAmount);

            if (withdrawChainSelector == i_thisChainSelector) {
                // @review do we want to emit this event outside of these brackets? need to check if it is also emitted in the ccipSend's receive
                emit WithdrawCompleted(withdrawer, usdcWithdrawAmount);
                if (usdcWithdrawAmount != 0) _transferUsdcTo(withdrawer, usdcWithdrawAmount);
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

    // @review these 2 functions can probably combined into a single one and the naming improved
    /// @dev Revert if msg.sender is not the ParentRebalancer
    /// @dev Handle moving strategy from this parent chain to a different chain
    /// @param oldStrategyAdapter The address of the old strategy adapter
    /// @param totalValue The total value of the system
    /// @param newStrategy The new strategy
    /// @notice This function is called by the ParentRebalancer's Log-trigger Automation performUpkeep
    /// @notice This is called when the strategy is on this chain and is being moved to a different chain
    function rebalanceNewStrategy(address oldStrategyAdapter, uint256 totalValue, Strategy memory newStrategy)
        external
    {
        _revertIfMsgSenderIsNotRebalancer();
        _handleStrategyMoveToNewChain(oldStrategyAdapter, totalValue, newStrategy);
    }

    /// @dev Revert if msg.sender is not the ParentRebalancer
    /// @dev Handle rebalancing from a different chain
    /// @param oldChainSelector The chain selector of the old strategy
    /// @param newStrategy The new strategy
    /// @notice This function is called by the ParentRebalancer's Log-trigger Automation performUpkeep
    /// @notice This is called when the old strategy is on a different chain to this chain, a remote child
    function rebalanceOldStrategy(uint64 oldChainSelector, Strategy memory newStrategy) external {
        _revertIfMsgSenderIsNotRebalancer();
        _handleRebalanceFromDifferentChain(oldChainSelector, newStrategy);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Receives a CCIP message from a peer
    /// @param txType The type of CCIP message received - see IYieldPeer.CcipTxType
    /// The CCIP message received
    /// - CcipTxType DepositToParent: A tx from child to parent to deposit USDC in strategy
    /// - CcipTxType DepositCallbackParent: A tx from the strategy to parent to calculate shareMintAmount and mint shares to the depositor on this chain or another child chain
    /// - CcipTxType WithdrawToParent: A tx from the withdraw chain to forward to the strategy chain
    /// - CcipTxType WithdrawCallback: A tx from the strategy chain to send USDC to the withdrawer
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
        //slither-disable-next-line reentrancy-no-eth
        if (txType == CcipTxType.DepositCallbackParent) _handleCCIPDepositCallbackParent(data);
        if (txType == CcipTxType.WithdrawToParent) _handleCCIPWithdrawToParent(data, sourceChainSelector);
        if (txType == CcipTxType.WithdrawCallback) _handleCCIPWithdrawCallback(tokenAmounts, data);
        //slither-disable-next-line reentrancy-events
        if (txType == CcipTxType.RebalanceNewStrategy) _handleCCIPRebalanceNewStrategy(tokenAmounts, data);
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
            /// @dev cache active strategy adapter
            address activeStrategyAdapter = _getActiveStrategyAdapter();
            /// @dev get total value from strategy and calculate share mint amount
            depositData.totalValue = _getTotalValueFromStrategy(activeStrategyAdapter, address(i_usdc));
            depositData.shareMintAmount = _calculateMintAmount(depositData.totalValue, depositData.amount);
            /// @dev update s_totalShares
            s_totalShares += depositData.shareMintAmount;
            emit ShareMintUpdate(depositData.shareMintAmount, depositData.chainSelector, s_totalShares);
            /// @dev deposit to strategy
            _depositToStrategy(activeStrategyAdapter, depositData.amount);

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

        /// @dev emit ShareMintUpdate to help track system wide mints for formal verification later
        /// @dev emitted regardless of if the mint happens on this parent or a child
        emit ShareMintUpdate(depositData.shareMintAmount, depositData.chainSelector, s_totalShares);

        /// @dev handle the case where the deposit was made on this parent chain
        if (depositData.chainSelector == i_thisChainSelector) {
            //slither-disable-next-line reentrancy-events
            // @review deposit complete event?
            _mintShares(depositData.depositor, depositData.shareMintAmount);
        }
        /// @dev handle the case where the deposit was made on a child chain
        else {
            /// @dev ccipSend the shareMintAmount to the child chain
            _ccipSend(
                depositData.chainSelector, CcipTxType.DepositCallbackChild, abi.encode(depositData), ZERO_BRIDGE_AMOUNT
            );
        }
    }

    /// @notice This function handles a withdraw tx that initiated on another chain.
    /// If this Parent is the strategy, we withdraw and send the USDC back to the withdrawer
    /// If this Parent is the strategy AND the withdrawer wants the USDC on this chain, we transfer it directly
    /// If this Parent is not the strategy, we forward the withdrawData to the strategy
    /// @dev Updates s_totalShares and emits ShareBurnUpdate
    /// @param data The encoded WithdrawData
    /// @param sourceChainSelector The chain selector of the chain where the withdraw originated from and shares were burned
    // @review this has similar functionality to ChildPeer::_handleCCIPWithdrawToStrategy - check for DRY/modular optimizations
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
                // @review would it be better to emit an event outside of these brackets, for both conditions?
                //slither-disable-next-line reentrancy-events
                emit WithdrawCompleted(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount);
                _transferUsdcTo(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount);
            } else {
                // @review emit event here?
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
            emit WithdrawForwardedToStrategy(withdrawData.shareBurnAmount, strategy.chainSelector);
            _ccipSend(
                strategy.chainSelector, CcipTxType.WithdrawToStrategy, abi.encode(withdrawData), ZERO_BRIDGE_AMOUNT
            );
        }
    }

    /// @notice This function sets the strategy on the parent
    /// @notice Called by Chainlink Functions callback - see ParentCLF.sol
    /// @notice Rebalances funds from the old strategy to the new strategy if both are on this chain
    /// @notice Handles the case where both the old and new strategy are on this chain
    /// @param chainSelector The chain selector of the new strategy
    /// @param protocolId The protocol ID of the new strategy
    /// @dev StrategyUpdated event emitted in _updateStrategy will trigger ParentRebalancer::performUpkeep ccip rebalances
    /// @notice performUpkeep handles the case where the old or new strategies are on different chains with ccipSend
    function _setStrategy(uint64 chainSelector, bytes32 protocolId) internal {
        Strategy memory oldStrategy = s_strategy;
        Strategy memory newStrategy = Strategy({chainSelector: chainSelector, protocolId: protocolId});

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
        if (oldStrategy.chainSelector == newStrategy.chainSelector && oldStrategy.protocolId == newStrategy.protocolId)
        {
            emit CurrentStrategyOptimal(newStrategy.chainSelector, newStrategy.protocolId);
            return false;
        }
        s_strategy = newStrategy;
        emit StrategyUpdated(newStrategy.chainSelector, newStrategy.protocolId, oldStrategy.chainSelector);
        return true;
    }

    /// @notice Handles strategy change when both old and new strategies are on this chain
    /// @param newStrategy The new strategy
    function _handleLocalStrategyChange(Strategy memory newStrategy) internal {
        address oldActiveStrategyAdapter = _getActiveStrategyAdapter();

        address newActiveStrategyAdapter =
            _updateActiveStrategyAdapter(newStrategy.chainSelector, newStrategy.protocolId);

        uint256 totalValue = _getTotalValueFromStrategy(oldActiveStrategyAdapter, address(i_usdc));
        if (totalValue != 0) _withdrawFromStrategy(oldActiveStrategyAdapter, totalValue);

        //slither-disable-next-line reentrancy-events
        _depositToStrategy(newActiveStrategyAdapter, totalValue);
    }

    /// @notice Handles moving strategy to a different chain
    /// @param oldStrategyAdapter The address of the old strategy adapter
    /// @param totalValue The total value of the system
    /// @param newStrategy The new strategy
    function _handleStrategyMoveToNewChain(address oldStrategyAdapter, uint256 totalValue, Strategy memory newStrategy)
        internal
    {
        _updateActiveStrategyAdapter(newStrategy.chainSelector, newStrategy.protocolId);
        if (totalValue != 0) _withdrawFromStrategy(oldStrategyAdapter, totalValue);
        _ccipSend(newStrategy.chainSelector, CcipTxType.RebalanceNewStrategy, abi.encode(newStrategy), totalValue);
    }

    /// @notice Handles rebalancing when strategy is on a different chain
    /// @param oldChainSelector The chain selector of the old strategy
    /// @param newStrategy The new strategy
    /// @notice This function is sending a crosschain message to the old strategy to rebalance funds to the new strategy
    function _handleRebalanceFromDifferentChain(uint64 oldChainSelector, Strategy memory newStrategy) internal {
        _ccipSend(oldChainSelector, CcipTxType.RebalanceOldStrategy, abi.encode(newStrategy), ZERO_BRIDGE_AMOUNT);
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
        if (msg.sender != s_rebalancer) revert ParentPeer__OnlyRebalancer();
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice This is called by Rebalancer::_fulfillRequest during a CLF callback
    /// @notice _setStrategy will emit StrategyUpdated() event which CLA Log trigger uses in Rebalancer
    /// @dev Revert if msg.sender is not the Rebalancer
    /// @dev Set the strategy
    /// @param chainSelector The chain selector of the new strategy
    /// @param protocolId The protocol ID of the new strategy
    function setStrategy(uint64 chainSelector, bytes32 protocolId) external {
        _revertIfMsgSenderIsNotRebalancer();
        _setStrategy(chainSelector, protocolId);
    }

    /// @notice Sets the initial active strategy
    /// @notice Can only be called once by the owner
    /// @notice This is needed because the strategy adapters are deployed separately from the parent peer
    /// @dev Revert if msg.sender is not the owner
    /// @dev Revert if already called
    /// @dev Called in deploy script, immediately after deploying initial strategy adapters, and setting them in YieldPeer::setStrategyAdapter
    /// @param protocolId The protocol ID of the initial active strategy
    function setInitialActiveStrategy(bytes32 protocolId) external onlyOwner {
        if (s_initialActiveStrategySet) revert ParentPeer__InitialActiveStrategyAlreadySet();
        s_initialActiveStrategySet = true;
        s_strategy = Strategy({chainSelector: i_thisChainSelector, protocolId: protocolId});
        _updateActiveStrategyAdapter(i_thisChainSelector, protocolId);
    }

    /// @notice Sets the rebalancer
    /// @dev Revert if msg.sender is not the owner
    /// @param rebalancer The address of the rebalancer
    //slither-disable-next-line missing-zero-check
    function setRebalancer(address rebalancer) external onlyOwner {
        s_rebalancer = rebalancer;
        emit RebalancerSet(rebalancer);
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

    /// @notice Get the current rebalancer
    /// @return rebalancer The current rebalancer
    function getRebalancer() external view returns (address) {
        return s_rebalancer;
    }
}
