// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {YieldPeer, Client, IRouterClient, CCIPOperations, IERC20, SafeERC20, Roles} from "./YieldPeer.sol";

/// @title YieldCoin ParentPeer
/// @author @contractlevel
/// @notice This contract is the ParentPeer of the Contract Level Yield system
/// @notice This contract is deployed on only one chain
/// @notice Users can deposit and withdraw USDC to/from the system via this contract
/// @notice This contract tracks system wide state and acts as a system wide hub for forwarding CCIP messages to the Strategy
contract ParentPeer is Initializable, UUPSUpgradeable, YieldPeer {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ParentPeer__OnlyRebalancer();
    error ParentPeer__InitialActiveStrategyAlreadySet();
    /// @dev indicates activeStrategyAdapter not set when parent state shows s_strategy.chainSelector == thisChainSelector
    /// activeStrategyAdapter is updated when rebalance TVL transit concludes
    error ParentPeer__InactiveStrategyAdapter();

    /*//////////////////////////////////////////////////////////////
                           NAMESPACED STORAGE
    //////////////////////////////////////////////////////////////*/
    /// @custom:storage-location erc7201:yieldcoin.storage.ParentPeer
    struct ParentPeerStorage {
        /// @dev total share tokens (YieldCoin) minted across all chains
        // @invariant s_totalShares == ghost_totalSharesMinted - ghost_totalSharesBurned
        uint256 s_totalShares;
        /// @dev This address handles automated CCIP rebalance calls with Log-trigger Automation, based on Function request callbacks
        /// @notice See ./src/modules/Rebalancer.sol
        address s_rebalancer;
        /// @dev Whether the initial active strategy adapter has been set
        bool s_initialActiveStrategySet;
    }

    /// @custom:storage-location erc7201:yieldcoin.storage.StrategyStorage
    struct StrategyStorage {
        /// @dev The current strategy: chainSelector and protocol
        Strategy s_strategy;
    }

    // keccak256(abi.encode(uint256(keccak256("yieldcoin.storage.ParentPeer")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ParentPeerStorageLocation =
        0x603686382b15940b5fa7ef449162bde228a5948ce3b6bdf08bd833ec6ae79500; // @review double check the hash

    // keccak256(abi.encode(uint256(keccak256("yieldcoin.storage.StrategyStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant StrategyStorageLocation =
        0x5202e425b34b6c95645915a460de54125f03aa25697774e32ad8f29e0d7eab00; // @review double check the hash

    function _getParentPeerStorage() private pure returns (ParentPeerStorage storage $) {
        assembly {
            $.slot := ParentPeerStorageLocation
        }
    }

    function _getStrategyStorage() private pure returns (StrategyStorage storage $) {
        assembly {
            $.slot := StrategyStorageLocation
        }
    }

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
    /// @notice Emitted when a deposit is ping-pong'd to a child
    event DepositPingPongToChild(uint256 indexed depositAmount, uint64 indexed destChainSelector);
    /// @notice Emitted when a withdraw is pingpong'd to a child
    event WithdrawPingPongToChild(uint256 indexed shareBurnAmount, uint64 indexed destChainSelector);

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
    {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                              INITIALIZER
    //////////////////////////////////////////////////////////////*/
    /// @notice Initializes the contract and its abstracts
    /// @dev This replaces the logic that would normally be in a constructor for state variables
    function initialize(address owner) external initializer {
        // This sets up AccessControl, Pausable, and YieldFees
        __YieldPeer_init(owner);
        _grantRole(Roles.UPGRADER_ROLE, owner);
    }

    /*//////////////////////////////////////////////////////////////
                           UUPS AUTHORIZATION
    //////////////////////////////////////////////////////////////*/
    /// @notice Authorizes an upgrade to a new implementation
    /// @param newImplementation The address of the new implementation
    /// @dev Revert if msg.sender does not have UPGRADER_ROLE
    /// @dev Required by UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(Roles.UPGRADER_ROLE) {}

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Users can deposit USDC into the system via this function
    /// @notice As this is the ParentPeer, we handle two deposit cases:
    /// 1. This Parent is the Strategy
    /// 2. This Parent is not the Strategy
    /// @param amountToDeposit The amount of USDC to deposit into the system
    /// @dev Revert if amountToDeposit is less than 1e6 (1 USDC)
    /// @dev Revert if peer is paused
    function deposit(uint256 amountToDeposit) external override whenNotPaused {
        /// @dev takes a fee
        amountToDeposit = _initiateDeposit(amountToDeposit);

        /// @dev load StrategyStorage
        StrategyStorage storage $ = _getStrategyStorage();
        Strategy memory strategy = $.s_strategy;

        // 1. This Parent is the Strategy. Therefore the deposit is handled here and shares can be minted here.
        if (strategy.chainSelector == i_thisChainSelector) {
            /// @dev load ParentPeerStorage
            ParentPeerStorage storage p$ = _getParentPeerStorage(); // @review p$ because $ already declared earlier

            /// @dev cache active strategy adapter
            address activeStrategyAdapter = _getActiveStrategyAdapter();
            /// @dev this is for the edgecase activeStrategyAdapter hasn't been updated yet, even though Parent state says it is strategy,
            /// TVL rebalance is still in transit
            if (activeStrategyAdapter == address(0)) revert ParentPeer__InactiveStrategyAdapter();

            /// @dev get total value from strategy
            uint256 totalValue = _getTotalValueFromStrategy(activeStrategyAdapter, address(i_usdc));

            /// @dev calculate share mint amount for total deposit (includes storage read of s_totalShares)
            uint256 shareMintAmount = _calculateMintAmount(totalValue, amountToDeposit);

            /// @dev update total shares (only once)
            p$.s_totalShares += shareMintAmount;
            emit ShareMintUpdate(shareMintAmount, i_thisChainSelector, p$.s_totalShares);

            /// @dev deposit to strategy
            //slither-disable-next-line reentrancy-events
            _depositToStrategy(activeStrategyAdapter, amountToDeposit);

            /// @dev mint share tokens (YieldCoin) to msg.sender based on amount deposited and total value of the system
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
    /// @dev Revert if msg.sender is not the YieldCoin/share token
    /// @dev Revert if shareBurnAmount is 0
    /// @dev Revert if peer is paused
    /// @dev Update s_totalShares and burn shares from msg.sender
    /// @dev Handle the case where the parent is the strategy
    /// @dev Handle the case where the parent is not the strategy
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

        /// @dev load StrategyStorage
        StrategyStorage storage $ = _getStrategyStorage();
        /// @dev load ParentPeerStorage
        ParentPeerStorage storage p$ = _getParentPeerStorage();

        /// @dev cache totalShares before updating
        uint256 totalShares = p$.s_totalShares;

        /// @dev update s_totalShares and burn shares from msg.sender
        p$.s_totalShares -= shareBurnAmount;
        emit ShareBurnUpdate(shareBurnAmount, i_thisChainSelector, totalShares - shareBurnAmount);
        emit WithdrawInitiated(withdrawer, shareBurnAmount, i_thisChainSelector);
        _burnShares(withdrawer, shareBurnAmount);

        Strategy memory strategy = $.s_strategy;

        // 1. This Parent is the Strategy. Therefore the usdcWithdrawAmount is calculated and withdrawal is handled here.
        if (strategy.chainSelector == i_thisChainSelector) {
            address activeStrategyAdapter = _getActiveStrategyAdapter();
            /// @dev this is for the edgecase activeStrategyAdapter hasn't been updated yet, even though Parent state says it is strategy,
            /// TVL rebalance is still in transit
            if (activeStrategyAdapter == address(0)) revert ParentPeer__InactiveStrategyAdapter();

            uint256 totalValue = _getTotalValueFromStrategy(activeStrategyAdapter, address(i_usdc));

            uint256 usdcWithdrawAmount = _calculateWithdrawAmount(totalValue, totalShares, shareBurnAmount);

            //slither-disable-next-line reentrancy-events
            if (usdcWithdrawAmount != 0) _withdrawFromStrategy(activeStrategyAdapter, usdcWithdrawAmount);

            /// @dev we emit this event when we complete the withdrawal and transfer the stablecoin to the withdrawer
            /// @dev it gets emitted in the WithdrawCallback too
            emit WithdrawCompleted(withdrawer, usdcWithdrawAmount);
            if (usdcWithdrawAmount != 0) _transferUsdcTo(withdrawer, usdcWithdrawAmount);
        }
        // 2. This Parent is not the Strategy. Therefore the shareBurnAmount is sent to the strategy and the USDC tokens usdcWithdrawAmount is sent back.
        else {
            WithdrawData memory withdrawData = _buildWithdrawData(withdrawer, shareBurnAmount, i_thisChainSelector);
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
        if (txType == CcipTxType.DepositToParent || txType == CcipTxType.DepositPingPong) {
            _handleCCIPDepositToParent(tokenAmounts, data);
        }
        //slither-disable-next-line reentrancy-no-eth
        if (txType == CcipTxType.DepositCallbackParent) _handleCCIPDepositCallbackParent(data);
        if (txType == CcipTxType.WithdrawToParent) _handleCCIPWithdrawToParent(data, sourceChainSelector);
        if (txType == CcipTxType.WithdrawPingPong) _handleCCIPWithdrawPingPong(data);
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
        /// @dev load StrategyStorage
        StrategyStorage storage $ = _getStrategyStorage();

        DepositData memory depositData = abi.decode(encodedDepositData, (DepositData));
        Strategy memory strategy = $.s_strategy;

        CCIPOperations._validateTokenAmounts(tokenAmounts, address(i_usdc), depositData.amount);

        /// @dev If Strategy is on this Parent, deposit into strategy and get totalValue
        if (strategy.chainSelector == i_thisChainSelector) {
            /// @dev cache active strategy adapter
            address activeStrategyAdapter = _getActiveStrategyAdapter();

            if (activeStrategyAdapter != address(0)) {
                /// @dev load ParentPeerStorage
                ParentPeerStorage storage p$ = _getParentPeerStorage();

                /// @dev get total value from strategy and calculate share mint amount
                depositData.totalValue = _getTotalValueFromStrategy(activeStrategyAdapter, address(i_usdc));
                depositData.shareMintAmount = _calculateMintAmount(depositData.totalValue, depositData.amount);
                /// @dev update s_totalShares
                p$.s_totalShares += depositData.shareMintAmount;
                emit ShareMintUpdate(depositData.shareMintAmount, depositData.chainSelector, p$.s_totalShares);
                /// @dev deposit to strategy
                _depositToStrategy(activeStrategyAdapter, depositData.amount);

                _ccipSend(
                    depositData.chainSelector,
                    CcipTxType.DepositCallbackChild,
                    abi.encode(depositData),
                    ZERO_BRIDGE_AMOUNT
                );
            }
            /// @dev handling edgecase where activeStrategyAdapter hasn't been updated, even though parent state has, because tvl in transit
            else {
                /// @dev ping pong back to deposit chain
                emit DepositPingPongToChild(depositData.amount, depositData.chainSelector);
                _ccipSend(depositData.chainSelector, CcipTxType.DepositPingPong, encodedDepositData, depositData.amount);
            }
        }
        /// @dev If Strategy is on third chain, forward deposit to strategy
        else {
            emit DepositForwardedToStrategy(depositData.amount, strategy.chainSelector);
            _ccipSend(strategy.chainSelector, CcipTxType.DepositToStrategy, encodedDepositData, depositData.amount);
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
        /// @dev load ParentPeerStorage
        ParentPeerStorage storage p$ = _getParentPeerStorage();

        /// @dev decode the deposit data and total value in the system
        DepositData memory depositData = _decodeDepositData(data);

        /// @dev calculate shareMintAmount based on depositData.totalValue and depositData.amount
        depositData.shareMintAmount = _calculateMintAmount(depositData.totalValue, depositData.amount);
        /// @dev update s_totalShares += shareMintAmount
        p$.s_totalShares += depositData.shareMintAmount;

        /// @dev emit ShareMintUpdate to help track system wide mints for formal verification later
        /// @dev emitted regardless of if the mint happens on this parent or a child
        emit ShareMintUpdate(depositData.shareMintAmount, depositData.chainSelector, p$.s_totalShares);

        /// @dev handle the case where the deposit was made on this parent chain
        if (depositData.chainSelector == i_thisChainSelector) {
            // @review DepositCompleted event? we want to emit a DepositCompleted event every where we mint shares at the end of a deposit
            // DepositCompleted(depositData.depositor, depositData.shareMintAmount, depositData.amount);
            // although, we do emit a shares minted event
            //slither-disable-next-line reentrancy-events
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
    /// If this Parent is not the strategy, we forward the withdrawData to the strategy
    /// @dev Updates s_totalShares and emits ShareBurnUpdate
    /// @param data The encoded WithdrawData
    /// @param sourceChainSelector The chain selector of the chain where the withdraw originated from and shares were burned
    function _handleCCIPWithdrawToParent(bytes memory data, uint64 sourceChainSelector) internal {
        /// @dev load StrategyStorage
        StrategyStorage storage $ = _getStrategyStorage();

        /// @dev load ParentPeerStorage
        ParentPeerStorage storage p$ = _getParentPeerStorage();

        WithdrawData memory withdrawData = _decodeWithdrawData(data);
        withdrawData.totalShares = p$.s_totalShares;
        p$.s_totalShares -= withdrawData.shareBurnAmount;

        emit ShareBurnUpdate(
            withdrawData.shareBurnAmount, sourceChainSelector, withdrawData.totalShares - withdrawData.shareBurnAmount
        );

        _handleCCIPWithdraw($.s_strategy, withdrawData);
    }

    /// @notice This function handles the withdraw flow logic that is used by both _handleCCIPWithdrawToParent and _handleCCIPWithdrawPingPong
    /// @notice We need this so that we aren't repeating ourselves in both functions and so we are not updating state again in _handleCCIPWithdrawPingPong (because it would have been updated during the _handleCCIPWithdrawToParent stage of the flow)
    /// @param strategy The active strategy state
    /// @param withdrawData The withdraw data for the tx
    function _handleCCIPWithdraw(Strategy memory strategy, WithdrawData memory withdrawData) internal {
        // 1. If the parent is the strategy, we want to use the totalShares and shareBurnAmount to calculate the usdcWithdrawAmount then withdraw it and ccipSend it back to the withdrawer
        if (strategy.chainSelector == i_thisChainSelector) {
            address activeStrategyAdapter = _getActiveStrategyAdapter();
            if (activeStrategyAdapter != address(0)) {
                withdrawData.usdcWithdrawAmount =
                    _withdrawFromStrategyAndGetUsdcWithdrawAmount(activeStrategyAdapter, withdrawData);

                _ccipSend(
                    withdrawData.chainSelector,
                    CcipTxType.WithdrawCallback,
                    abi.encode(withdrawData),
                    withdrawData.usdcWithdrawAmount
                );
            } else {
                emit WithdrawPingPongToChild(withdrawData.shareBurnAmount, withdrawData.chainSelector);
                /// @dev Encode the updated withdrawData (with correct totalShares) instead of using stale encodedWithdrawData
                _ccipSend(
                    withdrawData.chainSelector,
                    CcipTxType.WithdrawPingPong,
                    abi.encode(withdrawData),
                    ZERO_BRIDGE_AMOUNT
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

    /// @notice This function handles a pingpong withdraw from a child to this parent
    /// @notice Forwards withdraw to active strategy without updating state (already updated in original flow)
    /// @notice This only happens when parent is NOT the strategy (if parent were strategy, withdraw would complete in _handleCCIPWithdrawToParent)
    function _handleCCIPWithdrawPingPong(bytes memory data) internal {
        StrategyStorage storage $ = _getStrategyStorage();
        WithdrawData memory withdrawData = _decodeWithdrawData(data);
        _handleCCIPWithdraw($.s_strategy, withdrawData);
    }

    /// @notice This function sets the strategy on the parent and triggers appropriate strategy change
    /// @notice Called by Rebalancer::_onReport after getting CRE report from Keystone Forwarder
    /// @notice Triggers appropriate strategy rebalance (local, parent to child, child to other)
    /// @param chainSelector The chain selector of the new strategy
    /// @param protocolId The protocol ID of the new strategy
    function _setAndHandleStrategyChange(uint64 chainSelector, bytes32 protocolId) internal {
        /// @dev load StrategyStorage
        StrategyStorage storage $ = _getStrategyStorage();

        Strategy memory oldStrategy = $.s_strategy;
        Strategy memory newStrategy = Strategy({chainSelector: chainSelector, protocolId: protocolId});

        /// @dev Compare strategies and return early if optimal
        if (oldStrategy.chainSelector == newStrategy.chainSelector && oldStrategy.protocolId == newStrategy.protocolId)
        {
            emit CurrentStrategyOptimal(newStrategy.chainSelector, newStrategy.protocolId);
            return;
        }

        /// @dev Update Strategy state and emit StrategyUpdated event
        $.s_strategy = newStrategy;
        emit StrategyUpdated(newStrategy.chainSelector, newStrategy.protocolId, oldStrategy.chainSelector);

        /// @dev Handle local strategy change on this parent chain
        if (newStrategy.chainSelector == i_thisChainSelector && oldStrategy.chainSelector == i_thisChainSelector) {
            _rebalanceParentToParent(newStrategy);
        }
        /// @dev Handle strategy change from parent to child
        else if (newStrategy.chainSelector != i_thisChainSelector && oldStrategy.chainSelector == i_thisChainSelector) {
            _rebalanceParentToChild(newStrategy);
        }
        /// @dev Handle strategy change from a child to other
        else if (oldStrategy.chainSelector != i_thisChainSelector) {
            _rebalanceChildToOther(oldStrategy.chainSelector, newStrategy);
        }
    }

    /// @notice Handles strategy change when both old and new strategies are on this chain
    /// @param newStrategy The new strategy
    function _rebalanceParentToParent(Strategy memory newStrategy) internal {
        address oldActiveStrategyAdapter = _getActiveStrategyAdapter();

        address newActiveStrategyAdapter =
            _updateActiveStrategyAdapter(newStrategy.chainSelector, newStrategy.protocolId);

        uint256 totalValue = _getTotalValueFromStrategy(oldActiveStrategyAdapter, address(i_usdc));
        if (totalValue != 0) _withdrawFromStrategy(oldActiveStrategyAdapter, totalValue);

        //slither-disable-next-line reentrancy-events
        _depositToStrategy(newActiveStrategyAdapter, totalValue);
    }

    /// @dev Handle moving strategy (both funds & new strategy info) from this parent chain to a child chain
    /// @notice Called when the strategy is on this chain and is being moved to a child chain
    /// @param newStrategy The new strategy
    function _rebalanceParentToChild(Strategy memory newStrategy) internal {
        address oldActiveStrategyAdapter = _getActiveStrategyAdapter();
        uint256 totalValue = _getTotalValueFromStrategy(oldActiveStrategyAdapter, address(i_usdc));

        // @review unused-return, returns newActiveStrategyAdapter
        _updateActiveStrategyAdapter(newStrategy.chainSelector, newStrategy.protocolId);

        if (totalValue != 0) _withdrawFromStrategy(oldActiveStrategyAdapter, totalValue);

        _ccipSend(newStrategy.chainSelector, CcipTxType.RebalanceNewStrategy, abi.encode(newStrategy), totalValue);
    }

    /// @dev Handle rebalancing on a child chain by sending it new Strategy info
    /// @notice This is called when the old strategy is on a child chain and needs to be rebalanaced (either to another local protocol or chain)
    /// @param oldChainSelector The chain selector of the old strategy
    /// @param newStrategy The new strategy
    function _rebalanceChildToOther(uint64 oldChainSelector, Strategy memory newStrategy) internal {
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
        /// @dev load ParentPeerStorage
        ParentPeerStorage storage p$ = _getParentPeerStorage();
        uint256 totalShares = p$.s_totalShares;

        if (totalShares != 0) {
            shareMintAmount = (_convertUsdcToShare(amount) * totalShares) / _convertUsdcToShare(totalValue);
        } else {
            shareMintAmount = amount * INITIAL_SHARE_PRECISION;
        }

        if (shareMintAmount == 0) shareMintAmount = 1;
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Called by Rebalancer::_onReport when it gets a CRE report from a Keystone Forwarder
    /// @notice _setAndHandleStrategyChange() will do the following:
    /// @notice 1. Update the active s_strategy and emit StrategyUpdated() event
    /// @notice 2. Trigger appropriate strategy change (local, parent to child, child to other)
    /// @dev Revert if msg.sender is not the Rebalancer
    /// @dev Set the strategy
    /// @param chainSelector The chain selector of the new strategy
    /// @param protocolId The protocol ID of the new strategy
    // @review Do we want to make this Pausable?
    function setStrategy(uint64 chainSelector, bytes32 protocolId) external {
        /// @dev load ParentPeerStorage
        ParentPeerStorage storage p$ = _getParentPeerStorage();
        if (msg.sender != p$.s_rebalancer) revert ParentPeer__OnlyRebalancer();
        _setAndHandleStrategyChange(chainSelector, protocolId);
    }

    /// @notice Sets the initial active strategy
    /// @notice Can only be called once by the owner
    /// @notice This is needed because the strategy adapters are deployed separately from the parent peer
    /// @dev Revert if msg.sender is not the default admin
    /// @dev Revert if already called
    /// @dev Called in deploy script, immediately after deploying initial strategy adapters, and setting them in YieldPeer::setStrategyAdapter
    /// @param protocolId The protocol ID of the initial active strategy
    function setInitialActiveStrategy(bytes32 protocolId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        /// @dev load StrategyStorage
        StrategyStorage storage $ = _getStrategyStorage();
        /// @dev load ParentPeerStorage
        ParentPeerStorage storage p$ = _getParentPeerStorage();

        if (p$.s_initialActiveStrategySet) revert ParentPeer__InitialActiveStrategyAlreadySet();
        p$.s_initialActiveStrategySet = true;
        $.s_strategy = Strategy({chainSelector: i_thisChainSelector, protocolId: protocolId});
        // @review unused-return, returns newActiveStrategyAdapter
        _updateActiveStrategyAdapter(i_thisChainSelector, protocolId);
    }

    /// @notice Sets the rebalancer
    /// @dev Revert if msg.sender is not the config admin
    /// @param rebalancer The address of the rebalancer
    //slither-disable-next-line missing-zero-check
    function setRebalancer(address rebalancer) external onlyRole(Roles.CONFIG_ADMIN_ROLE) {
        /// @dev load ParentPeerStorage
        ParentPeerStorage storage p$ = _getParentPeerStorage();

        p$.s_rebalancer = rebalancer;
        emit RebalancerSet(rebalancer);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Get the current strategy
    /// @return strategy The current strategy - chainSelector and protocol
    function getStrategy() external view returns (Strategy memory) {
        /// @dev load StrategyStorage
        StrategyStorage storage $ = _getStrategyStorage();
        return $.s_strategy;
    }

    /// @notice Get the total shares minted across all chains
    /// @return totalShares The total shares minted across all chains
    function getTotalShares() external view returns (uint256) {
        /// @dev load ParentPeerStorage
        ParentPeerStorage storage p$ = _getParentPeerStorage();
        return p$.s_totalShares;
    }

    /// @notice Get the current rebalancer
    /// @return rebalancer The current rebalancer
    function getRebalancer() external view returns (address) {
        /// @dev load ParentPeerStorage
        ParentPeerStorage storage p$ = _getParentPeerStorage();
        return p$.s_rebalancer;
    }
}
