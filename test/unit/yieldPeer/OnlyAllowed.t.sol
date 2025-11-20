// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Roles} from "../../BaseTest.t.sol";
import {IRouterClient, Client} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";

contract OnlyAllowedTest is BaseTest {
    function test_yield_onlyAllowed_revertsWhen_chainSelectorNotAllowed() public {
        /// @dev arrange
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](0);
        Client.Any2EVMMessage memory any2EvmMessage = Client.Any2EVMMessage({
            messageId: bytes32("requestId"),
            sourceChainSelector: baseChainSelector,
            sender: abi.encode(address(baseParentPeer)),
            data: "",
            destTokenAmounts: tokenAmounts
        });

        _selectFork(optFork);
        _changePrank(crossChainAdmin);
        optChildPeer.setAllowedChain(baseChainSelector, false);

        /// @dev act/assert
        _changePrank(optNetworkConfig.ccip.ccipRouter);
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__ChainNotAllowed(uint64)", baseChainSelector));
        optChildPeer.ccipReceive(any2EvmMessage);
    }

    function test_yield_onlyAllowed_revertsWhen_peerNotAllowed() public {
        /// @dev arrange
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](0);
        Client.Any2EVMMessage memory any2EvmMessage = Client.Any2EVMMessage({
            messageId: bytes32("requestId"),
            sourceChainSelector: baseChainSelector,
            sender: abi.encode(address(0)),
            data: "",
            destTokenAmounts: tokenAmounts
        });

        _selectFork(optFork);

        /// @dev act/assert
        _changePrank(optNetworkConfig.ccip.ccipRouter);
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__PeerNotAllowed(address)", address(0)));
        optChildPeer.ccipReceive(any2EvmMessage);
    }
}
