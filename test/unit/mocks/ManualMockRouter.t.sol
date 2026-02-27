// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ManualMockRouter} from "../../mocks/ManualMockRouter.sol";
import {MockUsdc} from "../../mocks/MockUsdc.sol";
import {Client} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";

/// @notice Captures the last ccipReceive call for assertions
contract MockReceiver is IAny2EVMMessageReceiver {
    bytes32 public lastMessageId;
    uint64 public lastSourceChainSelector;
    address public lastSender;
    bytes public lastData;
    address public lastTokenAddress;
    uint256 public lastTokenAmount;
    uint256 public receiveCount;

    function ccipReceive(Client.Any2EVMMessage calldata message) external override {
        lastMessageId = message.messageId;
        lastSourceChainSelector = message.sourceChainSelector;
        lastSender = abi.decode(message.sender, (address));
        lastData = message.data;
        if (message.destTokenAmounts.length > 0) {
            lastTokenAddress = message.destTokenAmounts[0].token;
            lastTokenAmount = message.destTokenAmounts[0].amount;
        }
        receiveCount++;
    }
}

/// @notice A receiver that, on ccipReceive, turns around and sends a new message via the router
contract ReentrantReceiver is IAny2EVMMessageReceiver {
    ManualMockRouter public router;
    MockUsdc public usdc;
    address public target;
    uint256 public nestedQueueLengthObserved;

    constructor(ManualMockRouter _router, MockUsdc _usdc, address _target) {
        router = _router;
        usdc = _usdc;
        target = _target;
    }

    function ccipReceive(Client.Any2EVMMessage calldata) external override {
        Client.EVM2AnyMessage memory msg_ = Client.EVM2AnyMessage({
            receiver: abi.encode(target),
            data: abi.encode("nested"),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            feeToken: address(0),
            extraArgs: ""
        });
        router.ccipSend(0, msg_);
        nestedQueueLengthObserved = router.queueLength();
    }
}

contract ManualMockRouterTest is Test {
    ManualMockRouter public router;
    MockUsdc public usdc;
    MockReceiver public receiver;

    address internal constant SENDER = address(0x1234);
    uint64 internal constant CHAIN_SELECTOR = 42;
    uint256 internal constant TOKEN_AMOUNT = 1_000_000;

    function setUp() public {
        router = new ManualMockRouter();
        usdc = new MockUsdc();
        receiver = new MockReceiver();

        router.setPeerToChainSelector(SENDER, CHAIN_SELECTOR);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/
    function test_manualMockRouter_getFee_returnsZero() public view {
        assertEq(router.getFee(0, _buildMessage(address(receiver), "")), 0);
    }

    function test_manualMockRouter_isChainSupported_returnsTrue() public view {
        assertTrue(router.isChainSupported(0));
        assertTrue(router.isChainSupported(type(uint64).max));
    }

    function test_manualMockRouter_queueLength_initiallyZero() public view {
        assertEq(router.queueLength(), 0);
    }

    /*//////////////////////////////////////////////////////////////
                             NORMAL MODE
    //////////////////////////////////////////////////////////////*/
    function test_manualMockRouter_normalMode_deliversImmediately() public {
        bytes memory data = abi.encode("hello");
        vm.prank(SENDER);
        router.ccipSend(0, _buildMessage(address(receiver), data));

        assertEq(receiver.receiveCount(), 1);
        assertEq(receiver.lastData(), data);
        assertEq(router.queueLength(), 0);
    }

    function test_manualMockRouter_normalMode_withTokens_transfersDirectlyToReceiver() public {
        deal(address(usdc), SENDER, TOKEN_AMOUNT);

        vm.startPrank(SENDER);
        usdc.approve(address(router), TOKEN_AMOUNT);
        router.ccipSend(0, _buildMessageWithToken(address(receiver), TOKEN_AMOUNT));
        vm.stopPrank();

        assertEq(usdc.balanceOf(address(receiver)), TOKEN_AMOUNT);
        assertEq(usdc.balanceOf(address(router)), 0);
        assertEq(receiver.lastTokenAddress(), address(usdc));
        assertEq(receiver.lastTokenAmount(), TOKEN_AMOUNT);
    }

    function test_manualMockRouter_normalMode_returnsMockMsgId() public {
        Client.EVM2AnyMessage memory message = _buildMessage(address(receiver), "");
        bytes32 expectedId = keccak256(abi.encode(message));

        vm.prank(SENDER);
        bytes32 returnedId = router.ccipSend(0, message);

        assertEq(returnedId, expectedId);
    }

    function test_manualMockRouter_normalMode_sourceChainSelector_fromMapping() public {
        vm.prank(SENDER);
        router.ccipSend(0, _buildMessage(address(receiver), ""));

        assertEq(receiver.lastSourceChainSelector(), CHAIN_SELECTOR);
    }

    function test_manualMockRouter_normalMode_sender_encodedCorrectly() public {
        vm.prank(SENDER);
        router.ccipSend(0, _buildMessage(address(receiver), ""));

        assertEq(receiver.lastSender(), SENDER);
    }

    /*//////////////////////////////////////////////////////////////
                             MANUAL MODE
    //////////////////////////////////////////////////////////////*/
    function test_manualMockRouter_manualMode_noTokens_queuesAndDoesNotDeliver() public {
        router.setManualMode(true);

        vm.prank(SENDER);
        router.ccipSend(0, _buildMessage(address(receiver), ""));

        assertEq(receiver.receiveCount(), 0);
        assertEq(router.queueLength(), 1);
    }

    function test_manualMockRouter_manualMode_withTokens_escrrowsToRouter() public {
        deal(address(usdc), SENDER, TOKEN_AMOUNT);
        router.setManualMode(true);

        vm.startPrank(SENDER);
        usdc.approve(address(router), TOKEN_AMOUNT);
        router.ccipSend(0, _buildMessageWithToken(address(receiver), TOKEN_AMOUNT));
        vm.stopPrank();

        assertEq(usdc.balanceOf(address(router)), TOKEN_AMOUNT);
        assertEq(usdc.balanceOf(address(receiver)), 0);
        assertEq(router.queueLength(), 1);
    }

    function test_manualMockRouter_manualMode_returnsMockMsgId() public {
        router.setManualMode(true);
        Client.EVM2AnyMessage memory message = _buildMessage(address(receiver), "");
        bytes32 expectedId = keccak256(abi.encode(message));

        vm.prank(SENDER);
        bytes32 returnedId = router.ccipSend(0, message);

        assertEq(returnedId, expectedId);
    }

    function test_manualMockRouter_manualMode_multipleMessages_incrementsQueueLength() public {
        router.setManualMode(true);

        vm.startPrank(SENDER);
        router.ccipSend(0, _buildMessage(address(receiver), "a"));
        router.ccipSend(0, _buildMessage(address(receiver), "b"));
        router.ccipSend(0, _buildMessage(address(receiver), "c"));
        vm.stopPrank();

        assertEq(router.queueLength(), 3);
    }

    /*//////////////////////////////////////////////////////////////
                              ROUTENEXT
    //////////////////////////////////////////////////////////////*/
    function test_manualMockRouter_routeNext_emptyQueue_reverts() public {
        vm.expectRevert(ManualMockRouter.ManualMockRouter__QueueEmpty.selector);
        router.routeNext();
    }

    function test_manualMockRouter_routeNext_deliversAndDecrementsQueue() public {
        router.setManualMode(true);
        bytes memory data = abi.encode("payload");

        vm.prank(SENDER);
        router.ccipSend(0, _buildMessage(address(receiver), data));

        assertEq(router.queueLength(), 1);
        router.routeNext();
        assertEq(router.queueLength(), 0);
        assertEq(receiver.receiveCount(), 1);
        assertEq(receiver.lastData(), data);
    }

    function test_manualMockRouter_routeNext_withTokens_transfersEscrowToReceiver() public {
        deal(address(usdc), SENDER, TOKEN_AMOUNT);
        router.setManualMode(true);

        vm.startPrank(SENDER);
        usdc.approve(address(router), TOKEN_AMOUNT);
        router.ccipSend(0, _buildMessageWithToken(address(receiver), TOKEN_AMOUNT));
        vm.stopPrank();

        assertEq(usdc.balanceOf(address(router)), TOKEN_AMOUNT);
        router.routeNext();
        assertEq(usdc.balanceOf(address(receiver)), TOKEN_AMOUNT);
        assertEq(usdc.balanceOf(address(router)), 0);
    }

    function test_manualMockRouter_routeNext_msgId_matchesCcipSend() public {
        router.setManualMode(true);
        Client.EVM2AnyMessage memory message = _buildMessage(address(receiver), "");

        vm.prank(SENDER);
        bytes32 sentId = router.ccipSend(0, message);
        router.routeNext();

        assertEq(receiver.lastMessageId(), sentId);
    }

    function test_manualMockRouter_routeNext_fifoOrder() public {
        router.setManualMode(true);

        bytes memory data1 = abi.encode("first");
        bytes memory data2 = abi.encode("second");
        bytes memory data3 = abi.encode("third");

        vm.startPrank(SENDER);
        router.ccipSend(0, _buildMessage(address(receiver), data1));
        router.ccipSend(0, _buildMessage(address(receiver), data2));
        router.ccipSend(0, _buildMessage(address(receiver), data3));
        vm.stopPrank();

        router.routeNext();
        assertEq(receiver.lastData(), data1);
        router.routeNext();
        assertEq(receiver.lastData(), data2);
        router.routeNext();
        assertEq(receiver.lastData(), data3);
        assertEq(router.queueLength(), 0);
    }

    function test_manualMockRouter_routeNext_sourceChainSelector_correct() public {
        router.setManualMode(true);

        vm.prank(SENDER);
        router.ccipSend(0, _buildMessage(address(receiver), ""));
        router.routeNext();

        assertEq(receiver.lastSourceChainSelector(), CHAIN_SELECTOR);
    }

    /// @notice Verifies manual mode stays ON during routeNext delivery:
    /// a send triggered from inside ccipReceive is queued, not delivered immediately.
    function test_manualMockRouter_routeNext_staysInManualMode_duringDelivery() public {
        router.setManualMode(true);

        MockReceiver secondReceiver = new MockReceiver();
        ReentrantReceiver reentrant = new ReentrantReceiver(router, usdc, address(secondReceiver));

        vm.prank(SENDER);
        router.ccipSend(0, _buildMessage(address(reentrant), "trigger"));

        // deliver the first message — reentrant will try to send another
        router.routeNext();

        // the nested send must have been queued (not delivered) because manual mode was still ON
        assertEq(reentrant.nestedQueueLengthObserved(), 1);
        assertEq(secondReceiver.receiveCount(), 0);

        // deliver the nested message
        router.routeNext();
        assertEq(secondReceiver.receiveCount(), 1);
    }

    /*//////////////////////////////////////////////////////////////
                             HELPERS
    //////////////////////////////////////////////////////////////*/
    function _buildMessage(address _receiver, bytes memory data) internal view returns (Client.EVM2AnyMessage memory) {
        return Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: data,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            feeToken: address(0),
            extraArgs: ""
        });
    }

    function _buildMessageWithToken(address _receiver, uint256 amount)
        internal
        view
        returns (Client.EVM2AnyMessage memory)
    {
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: address(usdc), amount: amount});
        return Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), data: "", tokenAmounts: tokenAmounts, feeToken: address(0), extraArgs: ""
        });
    }
}
