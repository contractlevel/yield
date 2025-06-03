// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {CCIPReceiver} from "@chainlink/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IRouterClient, Client} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IERC677Receiver} from "@chainlink/contracts/src/v0.8/shared/interfaces/IERC677Receiver.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {DataTypes} from "@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol";
import {IComet} from "../interfaces/IComet.sol";
import {IShare} from "../interfaces/IShare.sol";
import {IYieldPeer} from "../interfaces/IYieldPeer.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";

abstract contract YieldPeer is CCIPReceiver, Ownable, IERC677Receiver, IYieldPeer {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error YieldPeer__USDCTransferFailed();
    error YieldPeer__OnlyShare();
    error YieldPeer__ChainNotAllowed(uint64 chainSelector);
    error YieldPeer__PeerNotAllowed(address peer);
    error YieldPeer__NoZeroAmount();
    error YieldPeer__NotEnoughLink(uint256 linkBalance, uint256 fees);
    error YieldPeer__InvalidToken(address invalidToken);
    error YieldPeer__InvalidTokenAmount(uint256 invalidAmount);

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 internal constant ZERO_BRIDGE_AMOUNT = 0;
    uint256 internal constant USDC_DECIMALS = 1e6;
    uint256 internal constant SHARE_DECIMALS = 1e18;
    uint256 internal constant INITIAL_SHARE_PRECISION = SHARE_DECIMALS / USDC_DECIMALS;

    /// @dev Chainlink token
    LinkTokenInterface internal immutable i_link;
    /// @dev Chain selector for this chain
    uint64 internal immutable i_thisChainSelector;
    /// @dev USDC token
    IERC20 internal immutable i_usdc;
    /// @dev Aave v3 pool addresses provider
    IPoolAddressesProvider internal immutable i_aavePoolAddressesProvider;
    /// @dev Compound v3 pool
    IComet internal immutable i_comet;
    /// @dev Share token minted in exchange for deposits
    IShare internal immutable i_share;

    /// @dev Gas limit for CCIP
    uint256 internal s_ccipGasLimit;
    /// @dev Mapping of allowed chains
    mapping(uint64 chainSelector => bool isAllowed) internal s_allowedChains;
    /// @dev Mapping of peers (ie other Yield contracts)
    mapping(uint64 chainSelector => address peer) internal s_peers;
    /// @notice We use this as a flag to know if this chain is the strategy
    /// @dev This is either i_aavePool, i_comet, or address(0)
    // @invariant s_strategyPool must be address(0) if this chain is not the strategy
    address internal s_strategyPool;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event AllowedChainSet(uint64 indexed chainSelector, bool indexed isAllowed);
    event AllowedPeerSet(uint64 indexed chainSelector, address indexed peer);
    event CCIPGasLimitSet(uint256 indexed gasLimit);
    event StrategyPoolSet(address indexed strategyPool);
    event DepositToStrategy(address indexed strategyPool, uint256 indexed amount);
    event WithdrawFromStrategy(address indexed strategyPool, uint256 indexed amount);

    /// @notice Emitted when a user deposits USDC into the system
    event DepositInitiated(address indexed depositor, uint256 indexed amount, uint64 indexed thisChainSelector);
    /// @notice Emitted when a CCIP message is sent to the parent chain
    event CCIPMessageSent(bytes32 indexed messageId, CcipTxType indexed txType, uint256 indexed amount);
    /// @notice Emitted when a CCIP message is received from the parent chain
    event CCIPMessageReceived(bytes32 indexed messageId, CcipTxType indexed txType, uint64 indexed sourceChainSelector);

    event SharesMinted(address indexed to, uint256 indexed amount);

    // @review this
    event DepositToStrategyCompleted(address indexed strategyPool, uint256 indexed amount, uint256 indexed totalValue);

    // @review - debug events, remove later
    event DebugWithdrawCalculation(uint256 totalValue, uint256 totalShares, uint256 shareBurnAmount);
    event DebugWithdrawAmount(uint256 usdcWithdrawAmount);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyAllowed(uint64 chainSelector, address peer) {
        // @review is the chainSelector check needed?
        if (!s_allowedChains[chainSelector]) revert YieldPeer__ChainNotAllowed(chainSelector);
        if (peer != s_peers[chainSelector]) revert YieldPeer__PeerNotAllowed(peer);
        _;
    }

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
    ) CCIPReceiver(ccipRouter) Ownable(msg.sender) {
        i_link = LinkTokenInterface(link);
        i_thisChainSelector = thisChainSelector;
        i_usdc = IERC20(usdc);
        i_aavePoolAddressesProvider = IPoolAddressesProvider(aavePoolAddressesProvider);
        i_comet = IComet(comet);
        i_share = IShare(share);
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @dev Depositors must approve address(this) for spending on USDC contract
    /// @notice This function is overridden and implemented in the ChildPeer and ParentPeer contracts
    function deposit(uint256 amountToDeposit) external virtual;

    /// @notice ERC677Receiver interface implementation
    /// @dev This function is called when the Share token is transferAndCall'd to this contract
    /// @dev Redeems/withdraws USDC and sends to sender
    /// @param sender The address that sent the Share token
    /// @param amount The amount of Share token sent
    /// @param data Additional data (not used)
    function onTokenTransfer(address sender, uint256 amount, bytes calldata data) external virtual {
        if (msg.sender != address(i_share)) revert YieldPeer__OnlyShare();

        // redeem `amount` for USDC and send to sender

        // burn `amount` of Share token
        i_share.burn(sender, amount);

        // uint256 usdcWithdrawAmount = _calculateUsdcWithdrawAmount(amount);

        // redeem `amount` for USDC and send to sender
        // i_usdc.transfer(sender, usdcWithdrawAmount);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Send a CCIP message to a peer
    /// @param destChainSelector The chain selector of the peer
    /// @param txType The type of transaction - see ./interfaces/IYieldPeer.sol
    /// @param data The data to send
    /// @param bridgeAmount The amount of USDC to send
    function _ccipSend(uint64 destChainSelector, CcipTxType txType, bytes memory data, uint256 bridgeAmount)
        internal
        returns (bytes32 ccipMessageId)
    {
        Client.EVMTokenAmount[] memory tokenAmounts;
        if (bridgeAmount > 0) {
            tokenAmounts = new Client.EVMTokenAmount[](1);
            tokenAmounts[0] = Client.EVMTokenAmount({token: address(i_usdc), amount: bridgeAmount});
            i_usdc.approve(i_ccipRouter, bridgeAmount);
        } else {
            tokenAmounts = new Client.EVMTokenAmount[](0);
        }

        Client.EVM2AnyMessage memory evm2AnyMessage =
            _buildCCIPMessage(s_peers[destChainSelector], txType, data, tokenAmounts);

        /// @dev handle LINK fees
        _handleCCIPFees(destChainSelector, evm2AnyMessage);

        ccipMessageId = IRouterClient(i_ccipRouter).ccipSend(destChainSelector, evm2AnyMessage);

        emit CCIPMessageSent(ccipMessageId, txType, bridgeAmount);
    }

    function _transferUsdcTo(address to, uint256 amount) internal {
        if (!i_usdc.transfer(to, amount)) revert YieldPeer__USDCTransferFailed();
    }

    function _transferUsdcFrom(address from, address to, uint256 amount) internal {
        if (!i_usdc.transferFrom(from, to, amount)) revert YieldPeer__USDCTransferFailed();
    }

    function _handleCCIPFees(uint64 dstChainSelector, Client.EVM2AnyMessage memory evm2AnyMessage) internal {
        uint256 fees = IRouterClient(i_ccipRouter).getFee(dstChainSelector, evm2AnyMessage);
        uint256 linkBalance = i_link.balanceOf(address(this));
        if (fees > linkBalance) revert YieldPeer__NotEnoughLink(linkBalance, fees);
        i_link.approve(i_ccipRouter, fees);
    }

    function _buildCCIPMessage(
        address receiver,
        CcipTxType txType,
        bytes memory data,
        Client.EVMTokenAmount[] memory tokenAmounts
    ) internal view returns (Client.EVM2AnyMessage memory evm2AnyMessage) {
        evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(txType, data),
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(
                Client.GenericExtraArgsV2({gasLimit: s_ccipGasLimit, allowOutOfOrderExecution: true})
            ),
            feeToken: address(i_link)
        });
    }

    function _buildDepositData(uint256 amount) internal view returns (DepositData memory depositData) {
        depositData.depositor = msg.sender;
        depositData.amount = amount;
        depositData.chainSelector = i_thisChainSelector;
    }

    function _buildWithdrawData(address withdrawer, uint256 shareBurnAmount)
        internal
        view
        returns (WithdrawData memory withdrawData)
    {
        withdrawData.withdrawer = withdrawer;
        withdrawData.shareBurnAmount = shareBurnAmount;
        withdrawData.chainSelector = i_thisChainSelector;
    }

    function _depositToStrategy(address strategyPool, uint256 amount) internal {
        address aavePool = i_aavePoolAddressesProvider.getPool();
        if (strategyPool == address(i_aavePoolAddressesProvider)) _depositToAave(aavePool, amount);
        else if (strategyPool == address(i_comet)) _depositToCompound(amount);
        emit DepositToStrategy(strategyPool, amount);
    }

    function _depositToAave(address aavePool, uint256 amount) internal {
        i_usdc.approve(aavePool, amount);
        IPool(aavePool).supply(address(i_usdc), amount, address(this), 0);
    }

    function _depositToCompound(uint256 amount) internal {
        i_usdc.approve(address(i_comet), amount);
        i_comet.supply(address(i_usdc), amount);
    }

    function _withdrawFromStrategy(address strategyPool, uint256 amount) internal {
        if (strategyPool == address(i_aavePoolAddressesProvider)) _withdrawFromAave(amount);
        else if (strategyPool == address(i_comet)) _withdrawFromCompound(amount);
        emit WithdrawFromStrategy(strategyPool, amount);
    }

    function _withdrawFromAave(uint256 amount) internal {
        address aavePool = i_aavePoolAddressesProvider.getPool();
        IPool(aavePool).withdraw(address(i_usdc), amount, address(this));
    }

    function _withdrawFromCompound(uint256 amount) internal {
        i_comet.withdraw(address(i_usdc), amount);
    }

    /// @notice Deposits USDC to the strategy and returns the total value of the system
    /// @param amount The amount of USDC to deposit
    /// @return totalValue The total value of the system
    function _depositToStrategyAndGetTotalValue(uint256 amount) internal returns (uint256 totalValue) {
        address strategyPool = _getStrategyPool();
        _depositToStrategy(strategyPool, amount);
        totalValue = _getTotalValueFromStrategy(strategyPool);

        emit DepositToStrategyCompleted(strategyPool, amount, totalValue);
    }

    function _withdrawFromStrategyAndGetUsdcWithdrawAmount(WithdrawData memory withdrawData)
        internal
        returns (uint256 usdcWithdrawAmount)
    {
        address strategyPool = _getStrategyPool();
        uint256 totalValue = _getTotalValueFromStrategy(strategyPool);
        usdcWithdrawAmount =
            _calculateWithdrawAmount(totalValue, withdrawData.totalShares, withdrawData.shareBurnAmount);
        _withdrawFromStrategy(strategyPool, usdcWithdrawAmount);
    }

    function _mintShares(address to, uint256 amount) internal {
        i_share.mint(to, amount);
        emit SharesMinted(to, amount);
    }

    function _burnShares(uint256 amount) internal {
        i_share.burn(amount);
    }

    function _handleCCIPWithdrawCallback(Client.EVMTokenAmount[] memory tokenAmounts, bytes memory data) internal {
        WithdrawData memory withdrawData = abi.decode(data, (WithdrawData));
        _validateTokenAmounts(tokenAmounts, withdrawData.usdcWithdrawAmount);
        _transferUsdcTo(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount);
    }

    /*//////////////////////////////////////////////////////////////
                             INTERNAL VIEW
    //////////////////////////////////////////////////////////////*/
    /// @return totalValue The total value of the system to 6 decimals
    function _getTotalValueFromStrategy(address strategyPool) internal view returns (uint256) {
        address aavePool = i_aavePoolAddressesProvider.getPool();
        if (strategyPool == address(i_aavePoolAddressesProvider)) return _getTotalValueFromAave(aavePool);
        else if (strategyPool == address(i_comet)) return _getTotalValueFromCompound();
    }

    function _getTotalValueFromAave(address aavePool) internal view returns (uint256) {
        DataTypes.ReserveData memory reserveData = IPool(aavePool).getReserveData(address(i_usdc));
        address aTokenAddress = reserveData.aTokenAddress;
        return IERC20(aTokenAddress).balanceOf(address(this));
    }

    function _getTotalValueFromCompound() internal view returns (uint256) {
        return i_comet.balanceOf(address(this));
    }

    function _getStrategyPool() internal view returns (address) {
        return s_strategyPool;
    }

    function _validateTokenAmounts(Client.EVMTokenAmount[] memory tokenAmounts, uint256 amount) internal view {
        if (tokenAmounts[0].token != address(i_usdc)) revert YieldPeer__InvalidToken(tokenAmounts[0].token);
        if (tokenAmounts[0].amount != amount) revert YieldPeer__InvalidTokenAmount(tokenAmounts[0].amount);
    }

    function _calculateWithdrawAmount(uint256 totalValue, uint256 totalShares, uint256 shareBurnAmount)
        internal
        pure
        returns (uint256)
    {
        return (shareBurnAmount * totalValue) / totalShares;
    }

    function _revertIfZeroAmount(uint256 amount) internal pure {
        if (amount == 0) revert YieldPeer__NoZeroAmount();
    }

    function _revertIfMsgSenderIsNotShare() internal view {
        if (msg.sender != address(i_share)) revert YieldPeer__OnlyShare();
    }

    function _getStrategyPool(IYieldPeer.Protocol protocol) internal view returns (address) {
        if (protocol == IYieldPeer.Protocol.Aave) return address(i_aavePoolAddressesProvider);
        else if (protocol == IYieldPeer.Protocol.Compound) return address(i_comet);
        // else revert YieldPeer__InvalidProtocol(protocol);
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    function setAllowedChain(uint64 chainSelector, bool isAllowed) external onlyOwner {
        s_allowedChains[chainSelector] = isAllowed;
        emit AllowedChainSet(chainSelector, isAllowed);
    }

    function setAllowedPeer(uint64 chainSelector, address peer) external onlyOwner {
        if (!s_allowedChains[chainSelector]) revert YieldPeer__ChainNotAllowed(chainSelector);
        s_peers[chainSelector] = peer;
        emit AllowedPeerSet(chainSelector, peer);
    }

    function setCCIPGasLimit(uint256 gasLimit) external onlyOwner {
        s_ccipGasLimit = gasLimit;
        emit CCIPGasLimitSet(gasLimit);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    function getThisChainSelector() external view returns (uint64) {
        return i_thisChainSelector;
    }

    function getAllowedChain(uint64 chainSelector) external view returns (bool) {
        return s_allowedChains[chainSelector];
    }

    function getAllowedPeer(uint64 chainSelector) external view returns (address) {
        return s_peers[chainSelector];
    }

    function getLink() external view returns (address) {
        return address(i_link);
    }

    function getUsdc() external view returns (address) {
        return address(i_usdc);
    }

    function getAavePoolAddressesProvider() external view returns (address) {
        return address(i_aavePoolAddressesProvider);
    }

    function getComet() external view returns (address) {
        return address(i_comet);
    }

    function getShare() external view returns (address) {
        return address(i_share);
    }

    function getStrategyPool() external view returns (address) {
        return s_strategyPool;
    }

    // @review double check this later
    function getIsStrategyChain() external view returns (bool) {
        return s_strategyPool != address(0);
    }

    /// @notice Internal helper to handle strategy pool updates
    /// @param chainSelector The chain selector for the strategy
    /// @param protocol The protocol for the strategy
    /// @return strategyPool The new strategy pool address
    function _updateStrategyPool(uint64 chainSelector, Protocol protocol) internal returns (address) {
        address strategyPool;
        if (chainSelector == i_thisChainSelector) {
            strategyPool = _getStrategyPool(protocol);
            s_strategyPool = strategyPool;
        } else {
            s_strategyPool = address(0);
        }
        return strategyPool;
    }

    /// @notice Internal helper to handle CCIP message sending for rebalancing
    /// @param targetChainSelector The target chain selector
    /// @param txType The type of CCIP transaction
    /// @param data The data to send
    /// @param amount The amount to send (if any)
    /// @return messageId The CCIP message ID
    function _sendRebalanceMessage(uint64 targetChainSelector, CcipTxType txType, bytes memory data, uint256 amount)
        internal
        returns (bytes32)
    {
        return _ccipSend(targetChainSelector, txType, data, amount);
    }
}
