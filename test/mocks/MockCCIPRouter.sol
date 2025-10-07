// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IRouterClient, Client} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MockCCIPRouter is IRouterClient {
    using SafeERC20 for IERC20;

    uint256 internal s_nonce;

    constructor() {
        s_nonce = 1;
    }

    function getFee(uint64, Client.EVM2AnyMessage memory) public pure returns (uint256) {
        return 0;
    }

    function ccipSend(uint64, Client.EVM2AnyMessage calldata message) external payable returns (bytes32) {
        for (uint256 i = 0; i < message.tokenAmounts.length; ++i) {
            IERC20(message.tokenAmounts[i].token).safeTransferFrom(
                msg.sender, address(this), message.tokenAmounts[i].amount
            );
        }

        uint256 nonce = s_nonce;
        s_nonce = nonce + 1;
        return bytes32(nonce);
    }

    function isChainSupported(uint64) external pure returns (bool) {
        return true;
    }
}
