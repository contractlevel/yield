// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ParentPeer} from "../../src/peers/ParentPeer.sol";
import {IYieldPeer} from "../../src/interfaces/IYieldPeer.sol";
import {Client, IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {CCIPOperations} from "../../src/libraries/CCIPOperations.sol";

contract ParentHarness is ParentPeer {
    constructor(
        address ccipRouter,
        address link,
        uint64 thisChainSelector,
        address usdc,
        address aavePoolAddressesProvider,
        address comet,
        address share
    ) ParentPeer(ccipRouter, link, thisChainSelector, usdc, aavePoolAddressesProvider, comet, share) {}

    function buildCCIPMessage(
        address receiver,
        IYieldPeer.CcipTxType txType,
        bytes memory data,
        Client.EVMTokenAmount[] memory tokenAmounts
    )
        public view returns (Client.EVM2AnyMessage memory) 
    {
        return CCIPOperations._buildCCIPMessage(
            receiver, 
            txType, 
            data, 
            tokenAmounts, 
            s_ccipGasLimit, 
            address(i_link)
        );
    }

    function decodeAddress(bytes memory data) public pure returns (address) {
        return abi.decode(data, (address));
    }
}