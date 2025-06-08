// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract MockFunctionsRouter {
    uint256 internal s_nonce;

    constructor() {
        s_nonce = 1;
    }

    function sendRequest(uint64, bytes calldata, uint16, uint32, bytes32) external returns (bytes32) {
        uint256 requestId = s_nonce;
        s_nonce++;
        return bytes32(requestId);
    }
}
