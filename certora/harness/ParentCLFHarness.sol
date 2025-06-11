// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ParentCLF} from "../../src/peers/extensions/ParentCLF.sol";

contract ParentCLFHarness is ParentCLF {
    constructor(
        address ccipRouter,
        address link,
        uint64 thisChainSelector,
        address usdc,
        address aavePoolAddressesProvider,
        address comet,
        address share,
        address functionsRouter,
        bytes32 donId,
        uint64 clfSubId
    ) ParentCLF(ccipRouter, link, thisChainSelector, usdc, aavePoolAddressesProvider, comet, share, functionsRouter, donId, clfSubId) {}

    function createCLFResponse(uint64 chainSelector, uint8 protocolEnum) public pure returns (bytes memory) {
        return abi.encode(chainSelector, protocolEnum);
    }
}