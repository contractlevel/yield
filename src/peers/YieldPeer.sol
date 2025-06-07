// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {CCIPReceiver} from "@chainlink/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IRouterClient, Client} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IERC677Receiver} from "@chainlink/contracts/src/v0.8/shared/interfaces/IERC677Receiver.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {DataTypes} from "@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol";
import {IComet} from "../interfaces/IComet.sol";
import {IShare} from "../interfaces/IShare.sol";
import {IYieldPeer} from "../interfaces/IYieldPeer.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {ProtocolOperations} from "../libraries/ProtocolOperations.sol";
import {DataStructures} from "../libraries/DataStructures.sol";
import {CCIPOperations} from "../libraries/CCIPOperations.sol";

abstract contract YieldPeer is CCIPReceiver, Ownable2Step, IERC677Receiver, IYieldPeer {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error YieldPeer__USDCTransferFailed();
    error YieldPeer__OnlyShare();
    error YieldPeer__ChainNotAllowed(uint64 chainSelector);
    error YieldPeer__PeerNotAllowed(address peer);
    error YieldPeer__NoZeroAmount();
    // error YieldPeer__NotEnoughLink(uint256 linkBalance, uint256 fees);
    error YieldPeer__InvalidToken(address invalidToken);
    // error YieldPeer__InvalidTokenAmount(uint256 invalidAmount);
    error YieldPeer__InvalidStrategyChain(uint64 invalidChainSelector);

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev Constant for the zero bridge amount - some CCIP messages don't need to send any USDC
    uint256 internal constant ZERO_BRIDGE_AMOUNT = 0;
    /// @dev Constant for the USDC decimals
    uint256 internal constant USDC_DECIMALS = 1e6;
    /// @dev Constant for the Share decimals
    uint256 internal constant SHARE_DECIMALS = 1e18;
    /// @dev Constant for the initial share precision used to calculate the mint amount for first deposit
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
    /// @dev This must include the Parent Chain on the ParentPeer!
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
    /// @notice Emitted when a chain is set as allowed
    event AllowedChainSet(uint64 indexed chainSelector, bool indexed isAllowed);
    /// @notice Emitted when a peer is set as allowed for an allowed chain
    event AllowedPeerSet(uint64 indexed chainSelector, address indexed peer);
    /// @notice Emitted when the CCIP gas limit is set
    event CCIPGasLimitSet(uint256 indexed gasLimit);

    /// @notice Emitted when the strategy pool is updated
    event StrategyPoolUpdated(address indexed strategyPool);

    /// @notice Emitted when USDC is deposited to the strategy
    event DepositToStrategy(address indexed strategyPool, uint256 indexed amount);
    /// @notice Emitted when USDC is withdrawn from the strategy
    event WithdrawFromStrategy(address indexed strategyPool, uint256 indexed amount);

    /// @notice Emitted when a user deposits USDC into the system
    event DepositInitiated(address indexed depositor, uint256 indexed amount, uint64 indexed thisChainSelector);
    /// @notice Emitted when a deposit to the strategy is completed
    event DepositCompleted(address indexed strategyPool, uint256 indexed amount, uint256 indexed totalValue);
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
        // @review is the chainSelector check needed?
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
    /// @param aavePoolAddressesProvider The address of the Aave v3 pool addresses provider
    /// @param comet The address of the Compound v3 cUSDCv3 contract
    /// @param share The address of the Share token, native to this system that is minted in return for deposits
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
    /// @dev Redeems/withdraws USDC and sends to withdrawer
    /// @param withdrawer The address that sent the SHARE token to withdraw USDC
    /// @param shareBurnAmount The amount of SHARE token sent
    /// @notice This function is overridden and implemented in the ChildPeer and ParentPeer contracts
    function onTokenTransfer(address withdrawer, uint256 shareBurnAmount, bytes calldata /* data */ )
        external
        virtual;

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Receives a CCIP message from a peer
    /// @dev Revert if message came from a chain that is not allowed
    /// @dev Revert if message came from a contract that is not allowed
    /// @dev _handleCCIPMessage is overridden and implemented in the ChildPeer and ParentPeer contracts
    function _ccipReceive(Client.Any2EVMMessage memory message)
        internal
        override
        onlyAllowed(message.sourceChainSelector, abi.decode(message.sender, (address)))
    {
        (CcipTxType txType, bytes memory data) = abi.decode(message.data, (CcipTxType, bytes));
        emit CCIPMessageReceived(message.messageId, txType, message.sourceChainSelector);

        _handleCCIPMessage(txType, message.destTokenAmounts, data);
    }

    /// @notice Handles CCIP messages based on transaction type
    /// @param txType The type of transaction
    /// @param tokenAmounts The token amounts in the message
    /// @param data The message data - decodes to DepositData, WithdrawData, or Strategy
    /// @notice This function is overridden and implemented in the ChildPeer and ParentPeer contracts
    function _handleCCIPMessage(CcipTxType txType, Client.EVMTokenAmount[] memory tokenAmounts, bytes memory data)
        internal
        virtual;

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

        emit CCIPMessageSent(ccipMessageId, txType, bridgeAmount);
    }

    /// @notice Handles the CCIP message for a withdraw callback
    /// @notice This function is called as the last step in the withdraw flow and sends USDC to the withdrawer
    /// @param tokenAmounts The token amounts in the message
    /// @param data The message data - decodes to WithdrawData
    function _handleCCIPWithdrawCallback(Client.EVMTokenAmount[] memory tokenAmounts, bytes memory data) internal {
        WithdrawData memory withdrawData = _decodeWithdrawData(data);
        CCIPOperations._validateTokenAmounts(tokenAmounts, address(i_usdc), withdrawData.usdcWithdrawAmount);
        _transferUsdcTo(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount);
        emit WithdrawCompleted(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount);
    }

    function _handleCCIPRebalanceOldStrategy(bytes memory data) internal {
        /// @dev withdraw from the old strategy
        address oldStrategyPool = _getStrategyPool();
        uint256 totalValue = _getTotalValueFromStrategy(oldStrategyPool);
        _withdrawFromStrategy(oldStrategyPool, totalValue);

        /// @dev update strategy pool to either protocol on this chain or address(0) if on a different chain
        Strategy memory newStrategy = abi.decode(data, (Strategy));
        address newStrategyPool = _updateStrategyPool(newStrategy.chainSelector, newStrategy.protocol);

        // if the new strategy is this chain, but different protocol, then we need to withdraw from the old strategy and deposit to the new strategy
        if (newStrategy.chainSelector == i_thisChainSelector) {
            _depositToStrategy(newStrategyPool, i_usdc.balanceOf(address(this)));
        }
        // if the new strategy is a different chain, then we need to send the usdc we just withdrew to the new strategy
        else {
            _ccipSend(newStrategy.chainSelector, CcipTxType.RebalanceNewStrategy, data, i_usdc.balanceOf(address(this)));
        }
    }

    function _handleCCIPRebalanceNewStrategy(bytes memory data) internal {
        /// @dev update strategy pool to protocol on this chain
        Strategy memory newStrategy = abi.decode(data, (Strategy));
        if (newStrategy.chainSelector != i_thisChainSelector) {
            revert YieldPeer__InvalidStrategyChain(newStrategy.chainSelector);
        }
        address newStrategyPool = _updateStrategyPool(newStrategy.chainSelector, newStrategy.protocol);

        /// @dev deposit to the new strategy
        uint256 usdcBalance = i_usdc.balanceOf(address(this));
        if (usdcBalance != 0) _depositToStrategy(newStrategyPool, usdcBalance);
    }

    /// @notice Internal helper to handle strategy pool updates
    /// @param chainSelector The chain selector for the strategy
    /// @param protocol The protocol for the strategy
    /// @return strategyPool The new strategy pool address
    function _updateStrategyPool(uint64 chainSelector, Protocol protocol) internal returns (address strategyPool) {
        if (chainSelector == i_thisChainSelector) {
            strategyPool = _getStrategyPoolFromProtocol(protocol);
            s_strategyPool = strategyPool;
        } else {
            s_strategyPool = address(0);
        }
        emit StrategyPoolUpdated(strategyPool);
    }

    function _depositToStrategy(address strategyPool, uint256 amount) internal {
        ProtocolOperations.depositToStrategy(strategyPool, _getProtocolConfig(), amount);
        emit DepositToStrategy(strategyPool, amount);
    }

    function _withdrawFromStrategy(address strategyPool, uint256 amount) internal {
        ProtocolOperations.withdrawFromStrategy(strategyPool, _getProtocolConfig(), amount);
        emit WithdrawFromStrategy(strategyPool, amount);
    }

    /// @notice Deposits USDC to the strategy and returns the total value of the system
    /// @param amount The amount of USDC to deposit
    /// @return totalValue The total value of the system
    function _depositToStrategyAndGetTotalValue(uint256 amount) internal returns (uint256 totalValue) {
        address strategyPool = _getStrategyPool();
        _depositToStrategy(strategyPool, amount);
        totalValue = _getTotalValueFromStrategy(strategyPool);

        emit DepositCompleted(strategyPool, amount, totalValue);
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

    /// @notice Initiates a deposit
    /// @param amountToDeposit The amount of USDC to deposit
    /// @dev Revert if amountToDeposit is 0
    /// @dev Transfer USDC from msg.sender to this contract
    /// @dev Emit DepositInitiated event
    function _initiateDeposit(uint256 amountToDeposit) internal {
        _revertIfZeroAmount(amountToDeposit);
        _transferUsdcFrom(msg.sender, address(this), amountToDeposit);
        emit DepositInitiated(msg.sender, amountToDeposit, i_thisChainSelector);
    }

    /// @notice Transfer USDC to an address
    /// @param to The address to transfer USDC to
    /// @param amount The amount of USDC to transfer
    function _transferUsdcTo(address to, uint256 amount) internal {
        if (!i_usdc.transfer(to, amount)) revert YieldPeer__USDCTransferFailed();
    }

    /// @notice Transfer USDC from an address
    /// @param from The address to transfer USDC from
    /// @param to The address to transfer USDC to
    /// @param amount The amount of USDC to transfer
    function _transferUsdcFrom(address from, address to, uint256 amount) internal {
        if (!i_usdc.transferFrom(from, to, amount)) revert YieldPeer__USDCTransferFailed();
    }

    /// @notice Mints shares
    /// @param to The address to mint shares to
    /// @param amount The amount of shares to mint
    function _mintShares(address to, uint256 amount) internal {
        i_share.mint(to, amount);
        emit SharesMinted(to, amount);
    }

    /// @notice Burns shares
    /// @param from The address who transferAndCall'd the SHAREs to this contract
    /// @param amount The amount of shares to burn
    function _burnShares(address from, uint256 amount) internal {
        i_share.burn(amount);
        emit SharesBurned(from, amount);
    }

    /// @notice Decodes the chain selector to withdraw USDC to from the data
    /// @param data The data to decode
    /// @return withdrawChainSelector The chain selector to withdraw USDC to
    /// @dev Revert if the chain selector is not allowed
    /// @dev If the data is empty, the withdrawn USDC will be sent back to the chain the withdrawal was initiated on
    function _decodeWithdrawChainSelector(bytes calldata data) internal view returns (uint64 withdrawChainSelector) {
        if (data.length > 0) {
            withdrawChainSelector = abi.decode(data, (uint64));
            if (!s_allowedChains[withdrawChainSelector]) revert YieldPeer__ChainNotAllowed(withdrawChainSelector);
        } else {
            withdrawChainSelector = i_thisChainSelector;
        }
    }

    /*//////////////////////////////////////////////////////////////
                             INTERNAL VIEW
    //////////////////////////////////////////////////////////////*/
    function _getProtocolConfig() internal view returns (ProtocolOperations.ProtocolConfig memory protocolConfig) {
        protocolConfig =
            ProtocolOperations.createConfig(address(i_usdc), address(i_aavePoolAddressesProvider), address(i_comet));
    }

    function _buildDepositData(uint256 amount) internal view returns (IYieldPeer.DepositData memory depositData) {
        depositData = DataStructures.buildDepositData(msg.sender, amount, i_thisChainSelector);
    }

    function _buildWithdrawData(address withdrawer, uint256 shareBurnAmount, uint64 withdrawChainSelector)
        internal
        pure
        returns (WithdrawData memory withdrawData)
    {
        withdrawData = DataStructures.buildWithdrawData(withdrawer, shareBurnAmount, withdrawChainSelector);
    }

    function _getTotalValueFromStrategy(address strategyPool) internal view returns (uint256 totalValue) {
        totalValue = ProtocolOperations.getTotalValueFromStrategy(strategyPool, _getProtocolConfig());
    }

    function _getStrategyPoolFromProtocol(IYieldPeer.Protocol protocol) internal view returns (address strategyPool) {
        strategyPool = ProtocolOperations.getStrategyPoolFromProtocol(protocol, _getProtocolConfig());
    }

    function _getStrategyPool() internal view returns (address) {
        return s_strategyPool;
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

    function _decodeDepositData(bytes memory data) internal pure returns (DepositData memory depositData) {
        depositData = abi.decode(data, (DepositData));
    }

    function _decodeWithdrawData(bytes memory data) internal pure returns (WithdrawData memory withdrawData) {
        withdrawData = abi.decode(data, (WithdrawData));
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

    function getCCIPGasLimit() external view returns (uint256) {
        return s_ccipGasLimit;
    }

    function getTotalValue() external view returns (uint256) {
        return _getTotalValueFromStrategy(s_strategyPool);
    }
}
