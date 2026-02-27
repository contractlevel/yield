// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {IRouterClient, Client} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice A CCIP router mock with a toggleable manual queue for invariant testing of PingPong tx types.
/// @notice In normal mode, messages are delivered synchronously (like MockCCIPRouter).
/// @notice In manual mode, ccipSend escrows tokens and enqueues the message.
/// @notice routeNext() delivers exactly one message from the front of the FIFO queue.
/// @notice Manual mode stays ON during routeNext() delivery — new sends are also queued.
contract ManualMockRouter is IRouterClient {
    /*//////////////////////////////////////////////////////////////
                             TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ManualMockRouter__QueueEmpty();

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/
    struct QueuedMessage {
        address receiver;
        address sender;
        uint64 sourceChainSelector;
        bytes32 mockMsgId;
        bytes data;
        address[] tokens;
        uint256[] amounts;
    }

    QueuedMessage[] private s_queue;
    mapping(address peer => uint64 chainSelector) private s_peerToChainSelector;
    bool private s_manualMode;

    /*//////////////////////////////////////////////////////////////
                              IROUTERCLIENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IRouterClient
    function ccipSend(uint64, Client.EVM2AnyMessage calldata message) external payable returns (bytes32) {
        address receiver = abi.decode(message.receiver, (address));
        bytes32 mockMsgId = keccak256(abi.encode(message));

        uint256 n = message.tokenAmounts.length;
        address[] memory tokens = new address[](n);
        uint256[] memory amounts = new uint256[](n);
        for (uint256 i = 0; i < n; ++i) {
            tokens[i] = message.tokenAmounts[i].token;
            amounts[i] = message.tokenAmounts[i].amount;
        }

        if (s_manualMode) {
            for (uint256 i = 0; i < n; ++i) {
                IERC20(tokens[i]).safeTransferFrom(msg.sender, address(this), amounts[i]);
            }
            s_queue.push(
                QueuedMessage({
                    receiver: receiver,
                    sender: msg.sender,
                    sourceChainSelector: s_peerToChainSelector[msg.sender],
                    mockMsgId: mockMsgId,
                    data: message.data,
                    tokens: tokens,
                    amounts: amounts
                })
            );
        } else {
            for (uint256 i = 0; i < n; ++i) {
                IERC20(tokens[i]).safeTransferFrom(msg.sender, receiver, amounts[i]);
            }
            IAny2EVMMessageReceiver(receiver)
                .ccipReceive(_buildExecMsg(mockMsgId, msg.sender, message.data, tokens, amounts));
        }

        return mockMsgId;
    }

    /// @inheritdoc IRouterClient
    function getFee(uint64, Client.EVM2AnyMessage memory) public pure returns (uint256) {
        return 0;
    }

    /// @inheritdoc IRouterClient
    function isChainSupported(uint64) external pure returns (bool) {
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                              QUEUE CONTROL
    //////////////////////////////////////////////////////////////*/
    /// @notice Delivers the front message in the queue. Manual mode stays ON during delivery.
    function routeNext() external {
        if (s_queue.length == 0) revert ManualMockRouter__QueueEmpty();

        QueuedMessage memory queued = s_queue[0];

        // shift queue (pop front)
        for (uint256 i = 0; i < s_queue.length - 1; ++i) {
            s_queue[i] = s_queue[i + 1];
        }
        s_queue.pop();

        for (uint256 i = 0; i < queued.tokens.length; ++i) {
            IERC20(queued.tokens[i]).safeTransfer(queued.receiver, queued.amounts[i]);
        }

        IAny2EVMMessageReceiver(queued.receiver)
            .ccipReceive(_buildExecMsg(queued.mockMsgId, queued.sender, queued.data, queued.tokens, queued.amounts));
    }

    /*//////////////////////////////////////////////////////////////
                                 ADMIN
    //////////////////////////////////////////////////////////////*/
    function setManualMode(bool manual) external {
        s_manualMode = manual;
    }

    function setPeerToChainSelector(address peer, uint64 chainSelector) external {
        s_peerToChainSelector[peer] = chainSelector;
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/
    function queueLength() external view returns (uint256) {
        return s_queue.length;
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    function _buildExecMsg(
        bytes32 mockMsgId,
        address sender,
        bytes memory data,
        address[] memory tokens,
        uint256[] memory amounts
    ) internal view returns (Client.Any2EVMMessage memory) {
        Client.EVMTokenAmount[] memory destTokenAmounts = new Client.EVMTokenAmount[](tokens.length);
        for (uint256 i = 0; i < tokens.length; ++i) {
            destTokenAmounts[i] = Client.EVMTokenAmount({token: tokens[i], amount: amounts[i]});
        }
        return Client.Any2EVMMessage({
            messageId: mockMsgId,
            sourceChainSelector: s_peerToChainSelector[sender],
            sender: abi.encode(sender),
            data: data,
            destTokenAmounts: destTokenAmounts
        });
    }
}
