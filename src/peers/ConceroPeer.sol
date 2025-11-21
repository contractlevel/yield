// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ConceroClient} from "@concero/v2-messaging/contracts/ConceroClient/ConceroClient.sol";
import {IConceroRouter, ConceroTypes} from "@concero/v2-messaging/contracts/interfaces/IConceroRouter.sol";
import {LancaClient} from "@lanca/bridging/contracts/LancaClient/LancaClient.sol";
import {ILancaBridge} from "@lanca/bridging/contracts/LancaBridge/interfaces/ILancaBridge.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {PausableWithAccessControl, Roles} from "../modules/PausableWithAccessControl.sol";
import {IConceroPeer} from "../interfaces/IConceroPeer.sol";

/// @title ConceroPeer
/// @author @contractlevel
/// @notice Base contract for crosschain messaging and bridging with Concero/Lanca
contract ConceroPeer is ConceroClient, LancaClient, PausableWithAccessControl, IConceroPeer {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ConceroPeer__ChainNotAllowed(uint24 chainSelector);
    error ConceroPeer__PeerNotAllowed(address peer);

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev Constant for the zero bridge amount - some Concero/Lanca messages don't need to send any value
    uint256 internal constant ZERO_BRIDGE_AMOUNT = 0;

    /// @dev The USDC token address
    address internal immutable i_usdc;
    /// @dev The Concero chain selector for this chain
    uint24 internal immutable i_thisChainSelector;

    /// @dev Gas limit for Concero/Lanca messages
    uint256 internal s_conceroGasLimit;
    /// @dev Mapping of allowed chains
    /// @dev This must include the Parent Chain on the ParentPeer!
    mapping(uint24 chainSelector => bool isAllowed) internal s_allowedChains;
    /// @dev Mapping of peers (ie other Yield contracts)
    mapping(uint24 chainSelector => address peer) internal s_peers;
    /// @dev Whether to finalise the source chain for Concero messages
    bool internal s_conceroShouldFinaliseSource;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a chain is set as allowed
    event AllowedChainSet(uint24 indexed chainSelector, bool indexed isAllowed);
    /// @notice Emitted when a peer is set as allowed for an allowed chain
    event AllowedPeerSet(uint24 indexed chainSelector, address indexed peer);
    /// @notice Emitted when the Concero gas limit is set
    event ConceroGasLimitSet(uint256 indexed gasLimit);
    /// @notice Emitted when whether to finalise the source chain for Concero messages is set
    event ConceroShouldFinaliseSourceSet(bool indexed shouldFinaliseSource);

    /// @notice Emitted when a crosschain message is sent
    event CrossChainMessageSent(
        bytes32 indexed conceroMessageId, CrossChainTxType indexed txType, uint256 indexed amount
    );
    /// @notice Emitted when a crosschain message is received
    event CrossChainMessageReceived(
        bytes32 indexed conceroMessageId, CrossChainTxType indexed txType, uint24 indexed sourceChainSelector
    );

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Modifier to check if the chain selector and peer are allowed to send Concero/Lanca messages
    /// @param chainSelector The chain selector to check
    /// @param peer The peer to check
    modifier onlyAllowed(uint24 chainSelector, address peer) {
        if (!s_allowedChains[chainSelector]) revert ConceroPeer__ChainNotAllowed(chainSelector);
        if (peer != s_peers[chainSelector]) revert ConceroPeer__PeerNotAllowed(peer);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param conceroRouter The address of the Concero router for sending crosschain messages with no value
    /// @param lancaPool The address of the Lanca pool for sending crosschain messages with value
    /// @param usdc The address of the USDC token
    /// @param thisChainSelector The *Concero* chain selector for this chain
    constructor(address conceroRouter, address lancaPool, address usdc, uint24 thisChainSelector)
        ConceroClient(conceroRouter)
        LancaClient(lancaPool)
        PausableWithAccessControl(msg.sender)
    {
        i_usdc = usdc;
        i_thisChainSelector = thisChainSelector;
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Send a crosschain message with or without value
    /// @notice This function combines Concero's messaging and Lanca's bridging
    /// @param amountToBridge The amount of tokens to bridge
    /// @param message The message to send
    /// @param dstChainSelector The Concero chain selector of the destination chain
    /// @return conceroMessageId The ID of the Concero message
    function _conceroSend(uint256 amountToBridge, bytes memory message, uint24 dstChainSelector)
        internal
        returns (bytes32 conceroMessageId)
    {
        address receiver = s_peers[dstChainSelector];
        uint256 gasLimit = s_conceroGasLimit;

        /// @dev If there is an amount to bridge, we need to use Lanca
        if (amountToBridge > 0) {
            uint256 fee = ILancaBridge(i_lancaPool).getBridgeNativeFee(dstChainSelector, gasLimit);

            IERC20(i_usdc).safeIncreaseAllowance(i_lancaPool, amountToBridge);

            conceroMessageId = ILancaBridge(i_lancaPool).bridge{value: fee}(
                receiver, amountToBridge, dstChainSelector, gasLimit, message
            );
        }
        /// @dev If there is no amount to bridge, we need to use Concero
        else {
            ConceroTypes.EvmDstChainData conceroExtraArgs =
                ConceroTypes.EvmDstChainData{receiver: receiver, gasLimit: gasLimit};
            bool shouldFinaliseSource = s_conceroShouldFinaliseSource;

            uint256 feeToken = address(0); // native, would prefer USDC

            uint256 fee = IConceroRouter(i_conceroRouter)
                .getMessageFee(dstChainSelector, shouldFinaliseSource, feeToken, conceroExtraArgs);

            conceroMessageId = IConceroRouter(i_conceroRouter).conceroSend{value: fee}(
                dstChainSelector, shouldFinaliseSource, usdc, conceroExtraArgs, message
            );
        }

        emit CrossChainMessageSent(conceroMessageId, txType, amountToBridge);
    }

    /// @notice Handles receiving a Concero message - see ConceroClient
    /// @param conceroMessageId The ID of the Concero message
    /// @param sourceChainSelector The Concero chain selector of the source chain
    /// @param sender The sender of the message
    /// @param messageData The message received - decodes to CrossChainTxType and bytes (which decodes to DepositData, WithdrawData, or Strategy)
    /// @dev Revert if message came from a chain that is not allowed
    /// @dev Revert if message came from a contract that is not allowed
    function _conceroReceive(
        bytes32 conceroMessageId,
        uint24 sourceChainSelector,
        bytes calldata sender,
        bytes calldata messageData
    ) internal override onlyAllowed(sourceChainSelector, abi.decode(sender, (address))) {
        _handleConceroMessage(conceroMessageId, ZERO_BRIDGE_AMOUNT, message, sourceChainSelector);
    }

    /// @notice Handles receiving a Lanca message - see LancaClient
    /// @param conceroMessageId The ID of the Concero message
    /// @param sourceChainSelector The Concero chain selector of the source chain
    /// @param sender The sender of the message
    /// @param amount The amount of tokens that were bridged and received on this chain
    /// @param messageData The message received - decodes to CrossChainTxType and bytes (which decodes to DepositData, WithdrawData, or Strategy)
    /// @dev Revert if message came from a chain that is not allowed
    /// @dev Revert if message came from a contract that is not allowed
    function _lancaReceive(
        bytes32 conceroMessageId,
        uint24 sourceChainSelector,
        address sender,
        uint256 amount,
        bytes memory messageData
    ) internal override onlyAllowed(sourceChainSelector, sender) {
        _handleConceroMessage(conceroMessageId, amount, message, sourceChainSelector);
    }

    /// @notice Handles Concero/Lanca messages
    /// @param conceroMessageId The ID of the Concero message
    /// @param bridgeAmount The amount of tokens received in the message
    /// @param messageData The message data - decodes to CrossChainTxType and bytes (which decodes to DepositData, WithdrawData, or Strategy)
    /// @param sourceChainSelector The chain selector of the chain where the tx originated from
    function _handleConceroMessage(
        bytes32 conceroMessageId,
        uint256 bridgeAmount,
        bytes calldata messageData,
        uint24 sourceChainSelector
    ) internal {
        (CrossChainTxType txType, bytes memory data) = abi.decode(messageData, (CrossChainTxType, bytes));
        emit CrossChainMessageReceived(conceroMessageId, txType, sourceChainSelector);

        _handleCrossChainMessage(txType, bridgeAmount, data, sourceChainSelector);

        // IYieldPeer(i_yieldPeer).handleCrossChainMessage(txType, amountReceived, data, sourceChainSelector);
    }

    /// @notice This function is overridden and implemented in the ChildPeer and ParentPeer contracts
    /// @notice Previously YieldPeer::_handleCCIPMessage()
    /// @notice Handles crosschain messages based on transaction type
    /// @param txType The type of crosschain transaction - see ./interfaces/IConceroPeer.sol
    /// @param amountReceived The token amount received in the message
    /// @param data The message data - decodes to DepositData, WithdrawData, or Strategy
    /// @param sourceChainSelector The chain selector of the chain where the tx originated from
    function _handleCrossChainMessage(
        CrossChainTxType txType,
        uint256 amountReceived,
        bytes memory data,
        uint64 sourceChainSelector
    ) internal virtual;

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Set the gas limit for Concero messages
    /// @param gasLimit The gas limit to set
    /// @dev Access control: CROSS_CHAIN_ADMIN_ROLE
    function setConceroGasLimit(uint256 gasLimit) external onlyRole(Roles.CROSS_CHAIN_ADMIN_ROLE) {
        s_conceroGasLimit = gasLimit;
        emit ConceroGasLimitSet(gasLimit);
    }

    /// @notice Set whether to finalise the source chain for Concero messages
    /// @param shouldFinaliseSource Whether to finalise the source chain for Concero messages
    /// @dev Access control: CROSS_CHAIN_ADMIN_ROLE
    function setConceroShouldFinaliseSource(bool shouldFinaliseSource) external onlyRole(Roles.CROSS_CHAIN_ADMIN_ROLE) {
        s_conceroShouldFinaliseSource = shouldFinaliseSource;
        emit ConceroShouldFinaliseSourceSet(shouldFinaliseSource);
    }

    /// @notice Set chains that are allowed to send Concero/Lanca messages to this peer
    /// @param chainSelector The chain selector to set
    /// @param isAllowed Whether the chain is allowed to send Concero/Lanca messages to this peer
    /// @dev Access control: CROSS_CHAIN_ADMIN_ROLE
    function setAllowedChain(uint24 chainSelector, bool isAllowed) external onlyRole(Roles.CROSS_CHAIN_ADMIN_ROLE) {
        s_allowedChains[chainSelector] = isAllowed;
        emit AllowedChainSet(chainSelector, isAllowed);
    }

    /// @notice Set the peer contract for an allowed chain selector
    /// @param chainSelector The chain selector to set
    /// @param peer The peer to set
    /// @dev Access control: CROSS_CHAIN_ADMIN_ROLE
    function setAllowedPeer(uint24 chainSelector, address peer) external onlyRole(Roles.CROSS_CHAIN_ADMIN_ROLE) {
        if (!s_allowedChains[chainSelector]) revert ConceroPeer__ChainNotAllowed(chainSelector);
        s_peers[chainSelector] = peer;
        emit AllowedPeerSet(chainSelector, peer);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Get the chain selector for this chain
    /// @return thisChainSelector The Concero chain selector for this chain
    function getThisChainSelector() external view returns (uint24) {
        return i_thisChainSelector;
    }

    /// @notice Get whether a chain is allowed to send Concero/Lanca messages to this peer
    /// @param chainSelector The chain selector to check
    /// @return isAllowedChain Whether the chain is allowed to send Concero/Lanca messages to this peer
    function getAllowedChain(uint24 chainSelector) external view returns (bool isAllowedChain) {
        isAllowedChain = s_allowedChains[chainSelector];
    }

    /// @notice Get the peer contract for an allowed chain selector
    /// @param chainSelector The chain selector to check
    /// @return peer The peer contract for the chain selector
    function getAllowedPeer(uint24 chainSelector) external view returns (address peer) {
        peer = s_peers[chainSelector];
    }

    /// @notice Get the gas limit for Concero messages
    /// @return gasLimit The gas limit for Concero messages
    function getConceroGasLimit() external view returns (uint256 conceroGasLimit) {
        conceroGasLimit = s_conceroGasLimit;
    }

    /// @notice Get whether to finalise the source chain for Concero messages
    /// @return shouldFinaliseSource Whether to finalise the source chain for Concero messages
    function getConceroShouldFinaliseSource() external view returns (bool shouldFinaliseSource) {
        shouldFinaliseSource = s_conceroShouldFinaliseSource;
    }
}
