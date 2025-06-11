// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MockCCIPRouter, Client} from "../../mocks/MockCCIPRouter.sol";

contract MockCCIPRouterTest is Test {
    MockCCIPRouter public mockCCIPRouter;

    function setUp() public {
        mockCCIPRouter = new MockCCIPRouter();
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
