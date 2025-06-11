// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ChildPeer} from "../../src/peers/ChildPeer.sol";
import {HelperHarness} from "./HelperHarness.sol";
import {Client} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";

contract ChildHarness is ChildPeer, HelperHarness {
    constructor(
        address ccipRouter,
        address link,
        uint64 thisChainSelector,
        address usdc,
        address aavePoolAddressesProvider,
        address comet,
        address share,
        uint64 parentChainSelector
    ) ChildPeer(ccipRouter, link, thisChainSelector, usdc, aavePoolAddressesProvider, comet, share, parentChainSelector) {}

    /*//////////////////////////////////////////////////////////////
                            EXPOSED INTERNAL
    //////////////////////////////////////////////////////////////*/
    function handleCCIPDepositToStrategy(Client.EVMTokenAmount[] memory tokenAmounts, bytes memory data) public {
        _handleCCIPDepositToStrategy(tokenAmounts, data);
    }

    function handleCCIPDepositCallbackChild(bytes memory data) public {
        _handleCCIPDepositCallbackChild(data);
    }

    function handleCCIPWithdrawToStrategy(bytes memory data) public {
        _handleCCIPWithdrawToStrategy(data);
    }

    function handleCCIPRebalanceOldStrategy(bytes memory data) public {
        _handleCCIPRebalanceOldStrategy(data);
    }   
}