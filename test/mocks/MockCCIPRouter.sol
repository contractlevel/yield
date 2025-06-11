// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IRouterClient, Client} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";

contract MockCCIPRouter is IRouterClient {
    uint256 internal s_nonce;

    constructor() {
        s_nonce = 1;
    }

    function getFee(uint64, Client.EVM2AnyMessage memory) public pure returns (uint256) {
        return 0;
    }

    function ccipSend(uint64, Client.EVM2AnyMessage calldata) external payable returns (bytes32) {
        uint256 nonce = s_nonce;
        s_nonce = nonce + 1;
        return bytes32(nonce);
    }

    function isChainSupported(uint64) external pure returns (bool) {
        return true;
    }
}
