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
        address share
    ) YieldPeer(ccipRouter, link, thisChainSelector, usdc, share) {}

    /*//////////////////////////////////////////////////////////////
                                OVERRIDE
    //////////////////////////////////////////////////////////////*/
    function deposit(bytes32 stablecoinId, uint256 amount) external override {}

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

    function handleCCIPRebalanceNewStrategy(Client.EVMTokenAmount[] memory tokenAmounts, bytes memory data) public {
        _handleCCIPRebalanceNewStrategy(tokenAmounts, data);
    }

    function depositToStrategy(address strategyAdapter, address asset, uint256 amount) public {
        _depositToStrategy(strategyAdapter, asset, amount);
    }

    function withdrawFromStrategy(address strategyAdapter, address asset, uint256 amount) public {
        _withdrawFromStrategy(strategyAdapter, asset, amount);
    }

    function calculateFee(uint256 stablecoinDepositAmount) public view returns (uint256) {
        return _calculateFee(stablecoinDepositAmount);
    }
}