// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ParentPeer} from "../../src/peers/ParentPeer.sol";
import {IYieldPeer} from "../../src/interfaces/IYieldPeer.sol";
import {Client, IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {CCIPOperations} from "../../src/libraries/CCIPOperations.sol";
import {HelperHarness} from "./HelperHarness.sol";

contract ParentHarness is ParentPeer, HelperHarness {
    constructor(
        address ccipRouter,
        address link,
        uint64 thisChainSelector,
        address usdc,
        address aavePoolAddressesProvider,
        address comet,
        address share,
        address parentRebalancer    
    ) ParentPeer(ccipRouter, link, thisChainSelector, usdc, aavePoolAddressesProvider, comet, share, parentRebalancer) {}

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

    function calculateTotalValue(uint256 usdcDepositAmount) public view returns (uint256) {
        return _getTotalValue() + usdcDepositAmount;
    }

    /*//////////////////////////////////////////////////////////////
                            EXPOSED INTERNAL
    //////////////////////////////////////////////////////////////*/
    function handleCCIPDepositToParent(Client.EVMTokenAmount[] memory tokenAmounts, bytes memory data) public {
        _handleCCIPDepositToParent(tokenAmounts, data);
    }

    function handleCCIPDepositCallbackParent(bytes memory data) public {
        _handleCCIPDepositCallbackParent(data);
    }

    function handleCCIPWithdrawToParent(bytes memory data, uint64 sourceChainSelector) public {
        _handleCCIPWithdrawToParent(data, sourceChainSelector);
    }

    function setStrategy(uint64 chainSelector, Protocol protocol) public {
        _setStrategy(chainSelector, protocol);
    }

    function calculateMintAmount(uint256 totalValue, uint256 amount) public view returns (uint256) {
        return _calculateMintAmount(totalValue, amount);
    }
}