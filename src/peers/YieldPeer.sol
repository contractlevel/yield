// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {CCIPReceiver, IAny2EVMMessageReceiver} from "@chainlink/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IRouterClient, Client} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IERC677Receiver} from "@chainlink/contracts/src/v0.8/shared/interfaces/IERC677Receiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PausableWithAccessControl, Roles, IAccessControlEnumerable} from "../modules/PausableWithAccessControl.sol";
import {IShare} from "../interfaces/IShare.sol";
import {IYieldPeer} from "../interfaces/IYieldPeer.sol";
import {DataStructures} from "../libraries/DataStructures.sol";
import {CCIPOperations} from "../libraries/CCIPOperations.sol";
import {IStrategyAdapter} from "../interfaces/IStrategyAdapter.sol";
import {IStrategyRegistry} from "../interfaces/IStrategyRegistry.sol";
import {ISwapper} from "../interfaces/ISwapper.sol";
import {YieldFees} from "../modules/YieldFees.sol";

/// @title YieldPeer
/// @author @contractlevel
/// @notice YieldPeer is the base contract for the Parent and Child Peers in the Contract Level Yield system
abstract contract YieldPeer is
    IAny2EVMMessageReceiver,
    CCIPReceiver,
    PausableWithAccessControl,
    IERC677Receiver,
    IYieldPeer,
    YieldFees
{
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;
    using SafeERC20 for IShare;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error YieldPeer__OnlyShare();
    error YieldPeer__ChainNotAllowed(uint64 chainSelector);
    error YieldPeer__PeerNotAllowed(address peer);
    error YieldPeer__NoZeroAmount();
    error YieldPeer__NotStrategyChain();
    error YieldPeer__InsufficientAmount();
    error YieldPeer__StablecoinNotSupported(bytes32 stablecoinId);

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev Constant for the zero bridge amount - some CCIP messages don't need to send any USDC
    uint256 internal constant ZERO_BRIDGE_AMOUNT = 0;
    /// @dev Constant for the USDC scaling factor
    uint256 internal constant USDC_SCALING_FACTOR = 1e6;
    /// @dev Constant for the Share scaling factor
    uint256 internal constant SHARE_SCALING_FACTOR = 1e18;
    /// @dev Constant for the USDC decimals
    uint8 internal constant USDC_DECIMALS = 6;
    /// @dev Constant for the Share decimals
    uint8 internal constant SHARE_DECIMALS = 18;
    /// @dev Constant for the initial share precision used to calculate the mint amount for first deposit
    uint256 internal constant INITIAL_SHARE_PRECISION = SHARE_SCALING_FACTOR / USDC_SCALING_FACTOR;
    /// @dev Constant for the USDC stablecoin ID - keccak256("usdc")
    bytes32 internal constant USDC_ID = 0xd6aca1be9729c13d677335161321649cccae6a591554772516700f986f942eaa;
    /// @dev Maximum slippage in basis points for stablecoin swaps (50 bps = 0.5%)
    uint256 internal constant MAX_SLIPPAGE_BPS = 50;
    /// @dev Basis points denominator
    uint256 internal constant BPS_DENOMINATOR = 10_000;

    /// @dev Chainlink token
    LinkTokenInterface internal immutable i_link;
    /// @dev Chain selector for this chain
    uint64 internal immutable i_thisChainSelector;
    /// @dev USDC token
    IERC20 internal immutable i_usdc;
    /// @dev Share token minted in exchange for deposits
    IShare internal immutable i_share;

    /// @dev Gas limit for CCIP
    uint256 internal s_ccipGasLimit;
    /// @dev Mapping of allowed chains
    /// @dev This must include the Parent Chain on the ParentPeer because it is checked when a rebalance occurs
    mapping(uint64 chainSelector => bool isAllowed) internal s_allowedChains;
    /// @dev Mapping of peers (ie other Yield contracts)
    mapping(uint64 chainSelector => address peer) internal s_peers;

    /// @dev The strategy registry
    address internal s_strategyRegistry;
    /// @dev The active strategy adapter
    address internal s_activeStrategyAdapter;
    /// @dev The active stablecoin address for the current strategy (resolved from registry on update)
    address internal s_activeStablecoin;
    /// @dev The swapper contract for stablecoin swaps
    address internal s_swapper;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a chain is set as allowed
    event AllowedChainSet(uint64 indexed chainSelector, bool indexed isAllowed);
    /// @notice Emitted when a peer is set as allowed for an allowed chain
    event AllowedPeerSet(uint64 indexed chainSelector, address indexed peer);
    /// @notice Emitted when the CCIP gas limit is set
    event CCIPGasLimitSet(uint256 indexed gasLimit);

    /// @notice Emitted when the strategy registry is set
    event StrategyRegistrySet(address indexed strategyRegistry);
    /// @notice Emitted when the swapper is set
    event SwapperSet(address indexed swapper);
    /// @notice Emitted when stablecoins are swapped
    event StablecoinsSwapped(address indexed tokenIn, address indexed tokenOut, uint256 indexed amountOut);

    /// @notice Emitted when the active strategy adapter and stablecoin are updated
    event ActiveStrategyUpdated(address indexed newStrategyAdapter, address indexed newStablecoin);

    /// @notice Emitted when a user deposits USDC into the system
    event DepositInitiated(address indexed depositor, uint256 indexed amount, uint64 indexed thisChainSelector);
    // @review DepositCompleted event?

    /// @notice Emitted when a user initiates a withdrawal of USDC from the system
    event WithdrawInitiated(address indexed withdrawer, uint256 indexed amount, uint64 indexed thisChainSelector);
    /// @notice Emitted when a withdrawal is completed and the USDC is sent to the user
    event WithdrawCompleted(address indexed withdrawer, uint256 indexed amount);

    /// @notice Emitted when a CCIP message is sent to the parent chain
    event CCIPMessageSent(bytes32 indexed messageId, CcipTxType indexed txType, uint256 indexed amount);
    /// @notice Emitted when a CCIP message is received from the parent chain
    event CCIPMessageReceived(bytes32 indexed messageId, CcipTxType indexed txType, uint64 indexed sourceChainSelector);

    /// @notice Emitted when shares are minted
    event SharesMinted(address indexed to, uint256 indexed amount);
    /// @notice Emitted when shares are burned
    event SharesBurned(address indexed from, uint256 indexed amount);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Modifier to check if the chain selector and peer are allowed to send CCIP messages
    /// @param chainSelector The chain selector to check
    /// @param peer The peer to check
    modifier onlyAllowed(uint64 chainSelector, address peer) {
        if (!s_allowedChains[chainSelector]) revert YieldPeer__ChainNotAllowed(chainSelector);
        if (peer != s_peers[chainSelector]) revert YieldPeer__PeerNotAllowed(peer);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param ccipRouter The address of the CCIP router
    /// @param link The address of the Chainlink token
    /// @param thisChainSelector The chain selector for this chain
    /// @param usdc The address of the USDC token
    /// @param share The address of the YieldCoin Share token, native to this system that is minted in return for deposits
    //slither-disable-next-line missing-zero-check
    constructor(address ccipRouter, address link, uint64 thisChainSelector, address usdc, address share)
        CCIPReceiver(ccipRouter)
        PausableWithAccessControl(msg.sender)
    {
        i_link = LinkTokenInterface(link);
        i_thisChainSelector = thisChainSelector;
        i_usdc = IERC20(usdc);
        i_share = IShare(share);
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @dev Depositors must approve address(this) for spending on the stablecoin contract
    /// @notice This function is overridden and implemented in the ChildPeer and ParentPeer contracts
    /// @param stablecoinId The stablecoin ID (e.g., keccak256("USDC"), keccak256("USDT"))
    /// @param amount The amount of stablecoin to deposit
    function deposit(bytes32 stablecoinId, uint256 amount) external virtual;

    /// @notice ERC677Receiver interface implementation
    /// @dev This function is called when the Share token is transferAndCall'd to this contract
    /// @dev Redeems/withdraws USDC and sends to withdrawer
    /// @param withdrawer The address that sent the SHARE token to withdraw USDC
    /// @param shareBurnAmount The amount of SHARE token sent
    /// @notice This function is overridden and implemented in the ChildPeer and ParentPeer contracts
    // @review currently only supporting withdrawing in USDC for the end user
    function onTokenTransfer(
        address withdrawer,
        uint256 shareBurnAmount,
        bytes calldata /* data */
    )
        external
        virtual;

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Receives a CCIP message from a peer
    /// @dev Revert if message came from a chain that is not allowed
    /// @dev Revert if message came from a contract that is not allowed
    /// @dev _handleCCIPMessage is overridden and implemented in the ChildPeer and ParentPeer contracts
    /// @param message The CCIP message received
    function _ccipReceive(Client.Any2EVMMessage memory message)
        internal
        override
        onlyAllowed(message.sourceChainSelector, abi.decode(message.sender, (address)))
    {
        (CcipTxType txType, bytes memory data) = abi.decode(message.data, (CcipTxType, bytes));
        emit CCIPMessageReceived(message.messageId, txType, message.sourceChainSelector);

        _handleCCIPMessage(txType, message.destTokenAmounts, data, message.sourceChainSelector);
    }

    /// @notice Handles CCIP messages based on transaction type
    /// @param txType The type of transaction
    /// @param tokenAmounts The token amounts in the message
    /// @param data The message data - decodes to DepositData, WithdrawData, or Strategy
    /// @param sourceChainSelector The chain selector of the chain where the tx originated from
    /// @notice This function is overridden and implemented in the ChildPeer and ParentPeer contracts
    function _handleCCIPMessage(
        CcipTxType txType,
        Client.EVMTokenAmount[] memory tokenAmounts,
        bytes memory data,
        uint64 sourceChainSelector
    ) internal virtual;

    /// @notice Send a CCIP message to a peer
    /// @param destChainSelector The chain selector of the peer
    /// @param txType The type of transaction - see ./interfaces/IYieldPeer.sol
    /// @param data The data to send
    /// @param bridgeAmount The amount of USDC to send
    function _ccipSend(uint64 destChainSelector, CcipTxType txType, bytes memory data, uint256 bridgeAmount) internal {
        Client.EVMTokenAmount[] memory tokenAmounts =
            CCIPOperations._prepareTokenAmounts(i_usdc, bridgeAmount, i_ccipRouter);

        Client.EVM2AnyMessage memory evm2AnyMessage = CCIPOperations._buildCCIPMessage(
            s_peers[destChainSelector], txType, data, tokenAmounts, s_ccipGasLimit, address(i_link)
        );

        CCIPOperations._handleCCIPFees(i_ccipRouter, address(i_link), destChainSelector, evm2AnyMessage);

        bytes32 ccipMessageId = IRouterClient(i_ccipRouter).ccipSend(destChainSelector, evm2AnyMessage);

        //slither-disable-next-line reentrancy-events
        emit CCIPMessageSent(ccipMessageId, txType, bridgeAmount);
    }

    /// @notice Handles the CCIP message for a withdraw callback
    /// @notice This function is called as the last step in the withdraw flow and sends USDC to the withdrawer
    /// @param tokenAmounts The token amounts in the message
    /// @param data The message data - decodes to WithdrawData
    function _handleCCIPWithdrawCallback(Client.EVMTokenAmount[] memory tokenAmounts, bytes memory data) internal {
        WithdrawData memory withdrawData = _decodeWithdrawData(data);
        if (withdrawData.usdcWithdrawAmount != 0) {
            CCIPOperations._validateTokenAmounts(tokenAmounts, address(i_usdc), withdrawData.usdcWithdrawAmount);
            _transferUsdcTo(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount);
        }
        emit WithdrawCompleted(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount);
    }

    /// @notice Handles the CCIP message for a rebalance to a new strategy
    /// @notice The message this function handles is sent by the old strategy when the strategy is updated
    /// @dev Updates the strategy pool to the new strategy
    /// @dev Swaps USDC to target stablecoin if needed, then deposits into the new strategy
    /// @param tokenAmounts The token amounts received in the CCIP message (USDC from CCIP bridge)
    /// @param data The data to decode - decodes to Strategy (chainSelector, protocolId, stablecoinId)
    function _handleCCIPRebalanceToNewStrategy(Client.EVMTokenAmount[] memory tokenAmounts, bytes memory data)
        internal
    {
        Strategy memory newStrategy = abi.decode(data, (Strategy));
        /// @dev update active strategy and stablecoin
        (address strategyAdapter, address stablecoin) = _updateActiveStrategy(newStrategy);

        /// @dev this amount is in USDC decimals because USDC is the bridge currency // @review VERIFY THIS!
        uint256 amountToDeposit = tokenAmounts[0].amount;
        if (amountToDeposit > 0) {
            if (stablecoin != address(i_usdc)) {
                // @review does scaling happen in the _swapStablecoins function?
                amountToDeposit = _swapStablecoins(address(i_usdc), stablecoin, amountToDeposit);
            }
            _depositToStrategy(strategyAdapter, stablecoin, amountToDeposit);
        }
    }

    /// @notice Internal helper to update the active strategy and stablecoin
    /// @param newStrategy The new strategy
    /// @return newActiveStrategyAdapter The new active strategy adapter address
    /// @return newActiveStablecoin The new active stablecoin address
    function _updateActiveStrategy(Strategy memory newStrategy)
        internal
        returns (address newActiveStrategyAdapter, address newActiveStablecoin)
    {
        /// @dev update active strategy adapter and stablecoin if the new strategy is on this chain
        if (newStrategy.chainSelector == i_thisChainSelector) {
            newActiveStrategyAdapter = _getStrategyAdapterFromProtocol(newStrategy.protocolId);
            newActiveStablecoin = _getStablecoinAddress(newStrategy.stablecoinId);
            s_activeStrategyAdapter = newActiveStrategyAdapter;
            s_activeStablecoin = newActiveStablecoin;
        }
        /// @dev update active strategy adapter and stablecoin to address(0) if the new strategy is on a different chain
        else {
            s_activeStrategyAdapter = address(0);
            s_activeStablecoin = address(0);
        }

        // @review certora verification
        emit ActiveStrategyUpdated(newActiveStrategyAdapter, newActiveStablecoin);
    }

    /// @notice Internal helper to deposit to the strategy
    /// @param strategyAdapter The active strategy adapter to deposit to
    /// @param stablecoin The stablecoin asset to deposit
    /// @param amount The amount to deposit (in native decimals of the stablecoin)
    function _depositToStrategy(address strategyAdapter, address stablecoin, uint256 amount) internal {
        // @review event - where is it declared and check where it is verified in certora
        emit DepositToStrategy(strategyAdapter, stablecoin, amount);
        IERC20(stablecoin).safeTransfer(strategyAdapter, amount);
        IStrategyAdapter(strategyAdapter).deposit(stablecoin, amount);
    }

    /// @notice Internal helper to withdraw from the strategy
    /// @param strategyAdapter The active strategy adapter to withdraw from
    /// @param stablecoin The stablecoin asset to withdraw
    /// @param amount The amount to withdraw (in native decimals of the stablecoin)
    function _withdrawFromStrategy(address strategyAdapter, address stablecoin, uint256 amount) internal {
        // @review event - where is it declared and check where it is verified in certora
        emit WithdrawFromStrategy(strategyAdapter, stablecoin, amount);
        IStrategyAdapter(strategyAdapter).withdraw(stablecoin, amount);
    }

    /// @notice Internal helper to swap stablecoins using the configured swapper
    /// @param tokenIn The address of the token to swap from
    /// @param tokenOut The address of the token to swap to
    /// @param amountIn The amount of tokenIn to swap
    /// @return amountOut The actual amount of tokenOut received
    function _swapStablecoins(address tokenIn, address tokenOut, uint256 amountIn)
        internal
        returns (uint256 amountOut)
    {
        if (tokenIn == tokenOut || amountIn == 0) return amountIn;

        address swapper = s_swapper;
        if (swapper == address(0)) revert YieldPeer__NoZeroAmount();

        // Cross-decimal slippage: normalize to system (USDC) decimals, denormalize to output decimals, then apply BPS
        uint8 tokenInDecimals = IERC20Metadata(tokenIn).decimals();
        uint8 tokenOutDecimals = IERC20Metadata(tokenOut).decimals();
        uint256 normalizedAmountIn = _scaleToUsdcDecimals(amountIn, tokenInDecimals);
        uint256 expectedAmountOut = _scaleFromUsdcDecimals(normalizedAmountIn, tokenOutDecimals);
        uint256 amountOutMin = (expectedAmountOut * (BPS_DENOMINATOR - MAX_SLIPPAGE_BPS)) / BPS_DENOMINATOR;

        IERC20(tokenIn).safeIncreaseAllowance(swapper, amountIn);
        amountOut = ISwapper(swapper).swapAssets(tokenIn, tokenOut, amountIn, amountOutMin);

        emit StablecoinsSwapped(tokenIn, tokenOut, amountOut);
    }

    /// @notice Internal helper to get a stablecoin address from its ID
    /// @param stablecoinId The stablecoin ID (e.g., keccak256("USDC"))
    /// @return stablecoin The stablecoin address
    function _getStablecoinAddress(bytes32 stablecoinId) internal view returns (address stablecoin) {
        /// @dev If it's USDC, return the immutable USDC address
        if (stablecoinId == USDC_ID) stablecoin = address(i_usdc);
        /// @dev Otherwise, look it up in the strategy registry
        else stablecoin = IStrategyRegistry(s_strategyRegistry).getStablecoin(stablecoinId);
    }

    /// @notice Deposits to the strategy and returns the total value scaled to USDC decimals
    /// @param strategyAdapter The active strategy adapter
    /// @param stablecoin The stablecoin asset to deposit
    /// @param amount The amount to deposit (in native decimals of the stablecoin)
    /// @return totalValueUsdcDecimals The total value in USDC decimals (6)
    function _depositToStrategyAndGetTotalValue(address strategyAdapter, address stablecoin, uint256 amount)
        internal
        returns (uint256 totalValueUsdcDecimals)
    {
        /// @dev if the stablecoin is USDC, the total value is already in USDC decimals
        if (stablecoin == address(i_usdc)) {
            totalValueUsdcDecimals = _getTotalValueFromStrategy(strategyAdapter, stablecoin);
        }
        /// @dev if the stablecoin is not USDC, we need to scale the total value to USDC decimals
        else {
            uint256 totalValueNativeDecimals = _getTotalValueFromStrategy(strategyAdapter, stablecoin);
            totalValueUsdcDecimals =
                _scaleToUsdcDecimals(totalValueNativeDecimals, IERC20Metadata(stablecoin).decimals());
        }
        /// @dev we do not need to scale the amount because it is already in the decimals native to the stablecoin
        _depositToStrategy(strategyAdapter, stablecoin, amount);
    }

    /// @notice Withdraws from the strategy and returns the USDC withdraw amount
    /// @notice Handles normalization(scaling to USDC decimals) for share math and swaps to USDC if needed
    /// @param strategyAdapter The active strategy adapter to withdraw from
    /// @param stablecoin The active stablecoin to withdraw from the strategy
    /// @param withdrawData The withdraw data
    /// @return usdcWithdrawAmount The USDC withdraw amount (in 6 dec)
    function _withdrawFromStrategyAndGetUsdcWithdrawAmount(
        address strategyAdapter,
        address stablecoin,
        WithdrawData memory withdrawData
    ) internal returns (uint256 usdcWithdrawAmount) {
        uint256 totalValueUsdcDecimals;
        uint8 decimals;
        /// @dev if the stablecoin is USDC, the total value is already in USDC decimals
        if (stablecoin == address(i_usdc)) {
            totalValueUsdcDecimals = _getTotalValueFromStrategy(strategyAdapter, stablecoin);
        }
        /// @dev if the stablecoin is not USDC, we need to scale the total value to USDC decimals
        else {
            decimals = IERC20Metadata(stablecoin).decimals();
            uint256 totalValueNativeDecimals = _getTotalValueFromStrategy(strategyAdapter, stablecoin);
            totalValueUsdcDecimals = _scaleToUsdcDecimals(totalValueNativeDecimals, decimals);
        }

        uint256 withdrawAmountUsdcDecimals =
            _calculateWithdrawAmount(totalValueUsdcDecimals, withdrawData.totalShares, withdrawData.shareBurnAmount);

        /// @dev zero check for edgecase we have no value in the system
        if (withdrawAmountUsdcDecimals != 0) {
            /// @dev if the stablecoin is USDC, we can just withdraw the amount
            if (stablecoin == address(i_usdc)) {
                _withdrawFromStrategy(strategyAdapter, stablecoin, withdrawAmountUsdcDecimals);
                usdcWithdrawAmount = withdrawAmountUsdcDecimals;
            }
            /// @dev if the stablecoin is not USDC, we need to scale the withdraw amount to that token's native decimals and then swap to USDC
            else {
                uint256 withdrawAmountNativeDecimals = _scaleFromUsdcDecimals(withdrawAmountUsdcDecimals, decimals);
                _withdrawFromStrategy(strategyAdapter, stablecoin, withdrawAmountNativeDecimals);

                usdcWithdrawAmount = _swapStablecoins(stablecoin, address(i_usdc), withdrawAmountNativeDecimals);
            }
        }
    }

    /// @notice Initiates a deposit of any supported stablecoin
    /// @param stablecoinId The stablecoin ID (e.g., keccak256("USDC"))
    /// @param amount The amount of stablecoin to deposit
    /// @dev Revert if stablecoin is not supported (address(0) in registry)
    /// @dev Revert if amount is less than 1 unit of the stablecoin
    /// @dev Transfer stablecoin from msg.sender to this contract
    /// @dev Takes a fee and emits FeeTaken event (if fee rate is not 0)
    /// @return amountMinusFee The amount deposited minus the fee
    /// @return stablecoin The resolved stablecoin address
    function _initiateDeposit(bytes32 stablecoinId, uint256 amount)
        internal
        returns (uint256 amountMinusFee, address stablecoin)
    {
        stablecoin = _getStablecoinAddress(stablecoinId);
        if (stablecoin == address(0)) revert YieldPeer__StablecoinNotSupported(stablecoinId);
        if (amount < 10 ** IERC20Metadata(stablecoin).decimals()) revert YieldPeer__InsufficientAmount();

        IERC20(stablecoin).safeTransferFrom(msg.sender, address(this), amount);

        uint256 fee = _calculateFee(amount);
        amountMinusFee = amount - fee;
        if (fee > 0) emit FeeTaken(fee);

        emit DepositInitiated(msg.sender, amountMinusFee, i_thisChainSelector);
    }

    /// @notice Transfer USDC to an address
    /// @param to The address to transfer USDC to
    /// @param amount The amount of USDC to transfer
    function _transferUsdcTo(address to, uint256 amount) internal {
        i_usdc.safeTransfer(to, amount);
    }

    /// @notice Transfer USDC from an address
    /// @param from The address to transfer USDC from
    /// @param to The address to transfer USDC to
    /// @param amount The amount of USDC to transfer
    function _transferUsdcFrom(address from, address to, uint256 amount) internal {
        i_usdc.safeTransferFrom(from, to, amount);
    }

    /// @notice Mints shares
    /// @param to The address to mint shares to
    /// @param amount The amount of shares to mint
    function _mintShares(address to, uint256 amount) internal {
        emit SharesMinted(to, amount);
        i_share.mint(to, amount);
    }

    /// @notice Burns shares
    /// @param from The address who transferAndCall'd the SHAREs to this contract
    /// @param amount The amount of shares to burn
    function _burnShares(address from, uint256 amount) internal {
        emit SharesBurned(from, amount);
        i_share.burn(amount);
    }

    /*//////////////////////////////////////////////////////////////
                             INTERNAL VIEW
    //////////////////////////////////////////////////////////////*/
    /// @notice Builds DepositData struct, which gets used in CCIP deposit messages
    /// @param amount The amount of USDC to deposit
    /// @return depositData Struct containing depositor, amount, and chain selector
    function _buildDepositData(uint256 amount) internal view returns (IYieldPeer.DepositData memory depositData) {
        depositData = DataStructures.buildDepositData(msg.sender, amount, i_thisChainSelector);
    }

    /// @notice Builds WithdrawData struct, which gets used in CCIP withdraw messages
    /// @param withdrawer The address that initiated the withdrawal
    /// @param shareBurnAmount The amount of shares the withdrawer burned
    /// @param withdrawChainSelector The chain selector to withdraw USDC to
    /// @return withdrawData Struct containing withdrawer, share burn amount, and chain selector
    function _buildWithdrawData(address withdrawer, uint256 shareBurnAmount, uint64 withdrawChainSelector)
        internal
        pure
        returns (WithdrawData memory withdrawData)
    {
        withdrawData = DataStructures.buildWithdrawData(withdrawer, shareBurnAmount, withdrawChainSelector);
    }

    /// @notice Helper function to get the total value from the strategy
    /// @param strategyAdapter The strategy adapter to get the total value from
    /// @param asset The asset to get the total value from
    /// @return totalValue The total value in the Contract Level Yield system
    function _getTotalValueFromStrategy(address strategyAdapter, address asset)
        internal
        view
        returns (uint256 totalValue)
    {
        totalValue = IStrategyAdapter(strategyAdapter).getTotalValue(asset);
    }

    /// @notice Helper function to get the strategy adapter from the protocol
    /// @param protocolId The protocol ID to get the strategy adapter from
    /// @return strategyAdapter The strategy adapter address
    function _getStrategyAdapterFromProtocol(bytes32 protocolId) internal view returns (address strategyAdapter) {
        strategyAdapter = IStrategyRegistry(s_strategyRegistry).getStrategyAdapter(protocolId);
    }

    /// @notice Helper function to get the active strategy adapter
    /// @return activeStrategyAdapter The active strategy adapter address
    function _getActiveStrategyAdapter() internal view returns (address activeStrategyAdapter) {
        activeStrategyAdapter = s_activeStrategyAdapter;
    }

    /// @notice Helper function to calculate the USDC withdraw amount
    /// @param totalValueUsdcDecimals The total value in the Contract Level Yield system
    /// @param totalShares The total shares in the Contract Level Yield system
    /// @param shareBurnAmount The amount of shares the withdrawer burned
    /// @return usdcWithdrawAmount The USDC withdraw amount
    function _calculateWithdrawAmount(uint256 totalValueUsdcDecimals, uint256 totalShares, uint256 shareBurnAmount)
        internal
        pure
        returns (uint256 usdcWithdrawAmount)
    {
        uint256 shareWithdrawAmount = ((_convertUsdcToShare(totalValueUsdcDecimals) * shareBurnAmount) / totalShares);
        usdcWithdrawAmount = _convertShareToUsdc(shareWithdrawAmount);
    }

    /// @notice Convert USDC decimals to Share decimals
    /// @param amountInUsdc The amount in USDC decimals
    /// @return amountInShare The amount in Share decimals
    function _convertUsdcToShare(uint256 amountInUsdc) internal pure returns (uint256 amountInShare) {
        amountInShare = amountInUsdc * INITIAL_SHARE_PRECISION;
    }

    /// @notice Convert Share decimals to USDC decimals
    /// @param amountInShare The amount in Share decimals
    /// @return amountInUsdc The amount in USDC decimals
    function _convertShareToUsdc(uint256 amountInShare) internal pure returns (uint256 amountInUsdc) {
        amountInUsdc = amountInShare / INITIAL_SHARE_PRECISION;
    }

    /// @notice Normalize an amount from native decimals to system decimals (6 dec)
    /// @param amount The amount in native decimals
    /// @param fromDecimals The native decimal count
    /// @return The amount in system decimals (6 dec)
    // @review verify this never overflows
    function _scaleToUsdcDecimals(uint256 amount, uint8 fromDecimals) internal pure returns (uint256 scaledAmount) {
        if (fromDecimals == USDC_DECIMALS) scaledAmount = amount;
        else if (fromDecimals > USDC_DECIMALS) scaledAmount = amount / (10 ** (fromDecimals - USDC_DECIMALS));
        else scaledAmount = amount * (10 ** (USDC_DECIMALS - fromDecimals));
    }

    /// @notice Denormalize an amount from system decimals (6 dec) to native decimals
    /// @param amount The amount in system decimals
    /// @param toDecimals The target decimal count
    /// @return The amount in native decimals
    // @review verify this never overflows
    function _scaleFromUsdcDecimals(uint256 amount, uint8 toDecimals) internal pure returns (uint256 scaledAmount) {
        if (toDecimals == USDC_DECIMALS) scaledAmount = amount;
        else if (toDecimals > USDC_DECIMALS) scaledAmount = amount * (10 ** (toDecimals - USDC_DECIMALS));
        else scaledAmount = amount / (10 ** (USDC_DECIMALS - toDecimals));
    }

    /// @dev Revert if the amount is 0
    /// @param amount The amount to check
    function _revertIfZeroAmount(uint256 amount) internal pure {
        if (amount == 0) revert YieldPeer__NoZeroAmount();
    }

    /// @dev Revert if the msg.sender is not the Share token
    /// @notice This is used to protect ERC677Receiver.onTokenTransfer
    function _revertIfMsgSenderIsNotShare() internal view {
        if (msg.sender != address(i_share)) revert YieldPeer__OnlyShare();
    }

    /// @notice Decodes the DepositData struct from the data
    /// @param data The data to decode
    /// @return depositData Struct containing depositor, amount, totalValue, shareMintAmount, and chainSelector
    function _decodeDepositData(bytes memory data) internal pure returns (DepositData memory depositData) {
        depositData = abi.decode(data, (DepositData));
    }

    /// @notice Decodes the WithdrawData struct from the data
    /// @param data The data to decode
    /// @return withdrawData Struct containing withdrawer, share burn amount, usdc withdraw amount, total shares, and chain selector
    function _decodeWithdrawData(bytes memory data) internal pure returns (WithdrawData memory withdrawData) {
        withdrawData = abi.decode(data, (WithdrawData));
    }

    /// @notice Get the total value of the Contract Level Yield system in system decimals (6 dec)
    /// @return totalValueUsdcDecimals The total value scaled to USDC decimals
    /// @dev Revert if this chain is not the strategy chain because the totalValue will be on another chain
    function _getTotalValue() internal view returns (uint256 totalValueUsdcDecimals) {
        address strategyAdapter = _getActiveStrategyAdapter();
        if (strategyAdapter != address(0)) {
            address stablecoin = s_activeStablecoin;
            if (stablecoin == address(i_usdc)) {
                totalValueUsdcDecimals = _getTotalValueFromStrategy(strategyAdapter, stablecoin);
            } else {
                uint256 totalValueNativeDecimals = _getTotalValueFromStrategy(strategyAdapter, stablecoin);
                totalValueUsdcDecimals =
                    _scaleToUsdcDecimals(totalValueNativeDecimals, IERC20Metadata(stablecoin).decimals());
            }
        } else {
            revert YieldPeer__NotStrategyChain();
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Set chains that are allowed to send CCIP messages to this peer
    /// @param chainSelector The chain selector to set
    /// @param isAllowed Whether the chain is allowed to send CCIP messages to this peer
    /// @dev Access control: CROSS_CHAIN_ADMIN_ROLE
    function setAllowedChain(uint64 chainSelector, bool isAllowed) external onlyRole(Roles.CROSS_CHAIN_ADMIN_ROLE) {
        s_allowedChains[chainSelector] = isAllowed;
        emit AllowedChainSet(chainSelector, isAllowed);
    }

    /// @notice Set the peer contract for an allowed chain selector
    /// @param chainSelector The chain selector to set
    /// @param peer The peer to set
    /// @dev Access control: CROSS_CHAIN_ADMIN_ROLE
    function setAllowedPeer(uint64 chainSelector, address peer) external onlyRole(Roles.CROSS_CHAIN_ADMIN_ROLE) {
        if (!s_allowedChains[chainSelector]) {
            revert YieldPeer__ChainNotAllowed(chainSelector);
        }
        s_peers[chainSelector] = peer;
        emit AllowedPeerSet(chainSelector, peer);
    }

    /// @notice Set the CCIP gas limit
    /// @param gasLimit The gas limit to set
    /// @dev Access control: CROSS_CHAIN_ADMIN_ROLE
    function setCCIPGasLimit(uint256 gasLimit) external onlyRole(Roles.CROSS_CHAIN_ADMIN_ROLE) {
        s_ccipGasLimit = gasLimit;
        emit CCIPGasLimitSet(gasLimit);
    }

    /// @notice Set the strategy registry
    /// @param strategyRegistry The strategy registry to set
    /// @dev Access control: CONFIG_ADMIN_ROLE
    //slither-disable-next-line missing-zero-check
    function setStrategyRegistry(address strategyRegistry) external onlyRole(Roles.CONFIG_ADMIN_ROLE) {
        s_strategyRegistry = strategyRegistry;
        emit StrategyRegistrySet(strategyRegistry);
    }

    /// @notice Set the swapper contract
    /// @param swapper The swapper contract to set
    /// @dev Access control: CONFIG_ADMIN_ROLE
    //slither-disable-next-line missing-zero-check
    function setSwapper(address swapper) external onlyRole(Roles.CONFIG_ADMIN_ROLE) {
        s_swapper = swapper;
        emit SwapperSet(swapper);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Get the chain selector for this chain
    /// @return thisChainSelector The chain selector for this chain
    function getThisChainSelector() external view returns (uint64) {
        return i_thisChainSelector;
    }

    /// @notice Get whether a chain is allowed to send CCIP messages to this peer
    /// @param chainSelector The chain selector to check
    /// @return isAllowed Whether the chain is allowed to send CCIP messages to this peer
    function getAllowedChain(uint64 chainSelector) external view returns (bool) {
        return s_allowedChains[chainSelector];
    }

    /// @notice Get the peer contract for an allowed chain selector
    /// @param chainSelector The chain selector to check
    /// @return peer The peer contract for the chain selector
    function getAllowedPeer(uint64 chainSelector) external view returns (address) {
        return s_peers[chainSelector];
    }

    /// @notice Get the Chainlink token address
    /// @return link The Chainlink token address
    function getLink() external view returns (address) {
        return address(i_link);
    }

    /// @notice Get the USDC token address
    /// @return usdc The USDC token address
    function getUsdc() external view returns (address) {
        return address(i_usdc);
    }

    /// @notice Get the Share token address native to this system
    /// @return share The Share token address
    function getShare() external view returns (address) {
        return address(i_share);
    }

    /// @notice Get whether this chain is the strategy chain
    /// @return isStrategyChain Whether this chain is the strategy chain
    function getIsStrategyChain() external view returns (bool) {
        return s_activeStrategyAdapter != address(0);
    }

    /// @notice Get the CCIP gas limit
    /// @return ccipGasLimit The CCIP gas limit
    function getCCIPGasLimit() external view returns (uint256) {
        return s_ccipGasLimit;
    }

    /// @dev Reverts if this chain is not the strategy chain
    /// @return totalValue The total value in the Contract Level Yield system
    function getTotalValue() external view returns (uint256 totalValue) {
        totalValue = _getTotalValue();
    }

    /// @notice Get the strategy adapter for a protocol
    /// @param protocolId The protocol ID to get the strategy adapter for
    /// @return strategyAdapter The strategy adapter address
    function getStrategyAdapter(bytes32 protocolId) external view returns (address strategyAdapter) {
        strategyAdapter = _getStrategyAdapterFromProtocol(protocolId);
    }

    /// @notice Get the active strategy adapter
    /// @return activeStrategyAdapter The active strategy adapter address
    function getActiveStrategyAdapter() external view returns (address activeStrategyAdapter) {
        activeStrategyAdapter = _getActiveStrategyAdapter();
    }

    /// @notice Get the active strategy stablecoin address
    /// @return activeStablecoin The active stablecoin address
    function getActiveStablecoin() external view returns (address activeStablecoin) {
        activeStablecoin = s_activeStablecoin;
    }

    /// @notice Get the strategy registry
    /// @return strategyRegistry The strategy registry address
    function getStrategyRegistry() external view returns (address strategyRegistry) {
        strategyRegistry = s_strategyRegistry;
    }

    /// @notice Get the swapper contract
    /// @return swapper The swapper contract address
    function getSwapper() external view returns (address swapper) {
        swapper = s_swapper;
    }

    /// @dev Used to override/resolve conflict of multiple contracts implementing this.
    /// @dev Should indicate whether the contract implements IAny2EVMMessageReceiver.
    /// @notice Checks if interface supported
    /// @param interfaceId The interfaceId to check.
    /// @return true if the interfaceId is supported.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(CCIPReceiver, PausableWithAccessControl)
        returns (bool)
    {
        return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || super.supportsInterface(interfaceId);
    }
}
