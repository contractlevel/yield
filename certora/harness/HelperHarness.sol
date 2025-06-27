// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IYieldPeer} from "../../src/interfaces/IYieldPeer.sol";
import {Client} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";

contract HelperHarness {
    function decodeAddress(bytes memory data) public pure returns (address) {
        return abi.decode(data, (address));
    }

    function buildEncodedWithdrawData(
        address withdrawer,
        uint256 shareBurnAmount,
        uint256 totalShares,
        uint256 usdcWithdrawAmount,
        uint64 chainSelector
    ) public pure returns (bytes memory) {
        IYieldPeer.WithdrawData memory withdrawData = IYieldPeer.WithdrawData({
            withdrawer: withdrawer,
            shareBurnAmount: shareBurnAmount,
            totalShares: totalShares,
            usdcWithdrawAmount: usdcWithdrawAmount,
            chainSelector: chainSelector
        });
        return abi.encode(withdrawData);
    }

    function buildEncodedDepositData(
        address depositor,
        uint256 amount,
        uint256 totalValue,
        uint256 shareMintAmount,
        uint64 chainSelector
    ) public pure returns (bytes memory) {
        IYieldPeer.DepositData memory depositData = IYieldPeer.DepositData({
            depositor: depositor,
            amount: amount,
            totalValue: totalValue,
            shareMintAmount: shareMintAmount,
            chainSelector: chainSelector
        });
        return abi.encode(depositData);
    }
    
    function prepareTokenAmounts(address usdc,uint256 bridgeAmount) public pure returns (Client.EVMTokenAmount[] memory tokenAmounts) {
        if (bridgeAmount > 0) {
            tokenAmounts = new Client.EVMTokenAmount[](1);
            tokenAmounts[0] = Client.EVMTokenAmount({token: usdc, amount: bridgeAmount});
        } else {
            tokenAmounts = new Client.EVMTokenAmount[](0);
        }
    }

    function encodeStrategy(uint64 chainSelector, uint8 protocolEnum) public pure returns (bytes memory) {
        return abi.encode(IYieldPeer.Strategy({chainSelector: chainSelector, protocol: IYieldPeer.Protocol(protocolEnum)}));
    }

    function encodeUint64(uint64 value) public pure returns (bytes memory) {
        return abi.encode(value);
    }

    function bytes32ToUint8(bytes32 value) public pure returns (uint8) {
        return uint8(uint256(value));
    }

    function bytes32ToUint256(bytes32 value) public pure returns (uint256) {
        return uint256(value);
    }

    function bytes32ToAddress(bytes32 value) public pure returns (address) {
        return address(uint160(uint256(value)));
    }

    function uint64ToBytes32(uint64 value) public pure returns (bytes32) {
        return bytes32(uint256(value));
    }

    function uint8ToBytes32(uint8 value) public pure returns (bytes32) {
        return bytes32(uint256(value));
    }

    function calculateWithdrawAmount(
        uint256 totalValue,
        uint256 totalShares,
        uint256 shareBurnAmount
    ) public pure returns (uint256) {
        return (shareBurnAmount * totalValue) / totalShares;
    }

    function createStrategy(uint64 chainSelector, IYieldPeer.Protocol protocol) public pure returns (IYieldPeer.Strategy memory) {
        return IYieldPeer.Strategy({chainSelector: chainSelector, protocol: protocol});
    }
}