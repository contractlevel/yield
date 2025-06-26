// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {YieldPeer} from "../../src/peers/YieldPeer.sol";
import {Client} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IYieldPeer} from "../../src/interfaces/IYieldPeer.sol";
import {HelperHarness} from "./HelperHarness.sol";

contract YieldHarness is YieldPeer, HelperHarness {
    constructor(
        address ccipRouter,
        address link,
        uint64 thisChainSelector,
        address usdc,
        address aavePoolAddressesProvider,
        address comet,
        address share
    ) YieldPeer(ccipRouter, link, thisChainSelector, usdc, aavePoolAddressesProvider, comet, share) {}

    /*//////////////////////////////////////////////////////////////
                                OVERRIDE
    //////////////////////////////////////////////////////////////*/
    function deposit(uint256 amountToDeposit) external override {}

    function onTokenTransfer(address withdrawer, uint256 shareBurnAmount, bytes calldata /* data */ ) external override {}

    function _handleCCIPMessage(
        IYieldPeer.CcipTxType txType,
        Client.EVMTokenAmount[] memory tokenAmounts,
        bytes memory data,
        uint64 sourceChainSelector
    ) internal override {}

    /*//////////////////////////////////////////////////////////////
                            EXPOSED INTERNAL
    //////////////////////////////////////////////////////////////*/
    function handleCCIPWithdrawCallback(Client.EVMTokenAmount[] memory tokenAmounts, bytes memory data) public {
        _handleCCIPWithdrawCallback(tokenAmounts, data);
    }

    function handleCCIPRebalanceNewStrategy(bytes memory data) public {
        _handleCCIPRebalanceNewStrategy(data);
    }

    function depositToStrategy(address strategyPool, uint256 amount) public {
        _depositToStrategy(strategyPool, amount);
    }

    function withdrawFromStrategy(address strategyPool, uint256 amount) public {
        _withdrawFromStrategy(strategyPool, amount);
    }
    
    function decodeWithdrawChainSelector(bytes calldata data) public view returns (uint64) {
        return _decodeWithdrawChainSelector(data);
    }
}