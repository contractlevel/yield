// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MockCCIPRouter, Client} from "../../mocks/MockCCIPRouter.sol";
import {MockUsdc} from "../../mocks/MockUsdc.sol";

contract MockCCIPRouterTest is Test {
    MockCCIPRouter public mockCCIPRouter;
    MockUsdc public mockUsdc;

    function setUp() public {
        mockCCIPRouter = new MockCCIPRouter();
        mockUsdc = new MockUsdc();
    }

    function test_mockCCIPRouter_getFee() public view {
        assertEq(mockCCIPRouter.getFee(0, _buildEVM2AnyMessage()), 0);
    }

    function test_mockCCIPRouter_ccipSend() public {
        assertEq(mockCCIPRouter.ccipSend(0, _buildEVM2AnyMessage()), bytes32(uint256(1)));
    }

    function test_mockCCIPRouter_isChainSupported() public view {
        assertEq(mockCCIPRouter.isChainSupported(0), true);
    }

    function test_mockCCIPRouter_ccipSend_with_tokenAmounts() public {
        uint256 amount = 100;
        deal(address(mockUsdc), address(this), amount);
        mockUsdc.approve(address(mockCCIPRouter), amount);
        Client.EVM2AnyMessage memory message = _buildEVM2AnyMessage();
        message.tokenAmounts = new Client.EVMTokenAmount[](1);
        message.tokenAmounts[0] = Client.EVMTokenAmount({token: address(mockUsdc), amount: amount});

        mockCCIPRouter.ccipSend(0, message);

        assertEq(mockUsdc.balanceOf(address(mockCCIPRouter)), amount);
    }

    function _buildEVM2AnyMessage() internal pure returns (Client.EVM2AnyMessage memory) {
        return Client.EVM2AnyMessage({
            receiver: abi.encode(address(0)),
            data: "",
            tokenAmounts: new Client.EVMTokenAmount[](0),
            feeToken: address(0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 0}))
        });
    }
}
