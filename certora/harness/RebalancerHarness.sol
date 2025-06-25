// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ParentRebalancer, Log, IParentPeer, IYieldPeer} from "../../src/modules/ParentRebalancer.sol";
import {HelperHarness} from "./HelperHarness.sol";

contract RebalancerHarness is ParentRebalancer, HelperHarness {
    function harnessCreateLog(
        uint256 index,
        uint256 timestamp,
        bytes32 txHash,
        uint256 blockNumber,
        bytes32 blockHash,
        address source,
        bytes32[] memory topics,
        bytes memory data
    ) 
    public pure returns (Log memory) {
            return Log({
                index: index,
                timestamp: timestamp,
                txHash: txHash,
                blockNumber: blockNumber,
                blockHash: blockHash,
                source: source,
                topics: topics,
                data: data
        });
    }

    function getParentChainSelector() public view returns (uint64) {
        return IParentPeer(s_parentPeer).getThisChainSelector();
    }

    function decodePerformData(bytes memory performData) public pure returns (
        address,
        address,
        IYieldPeer.Strategy memory,
        IYieldPeer.CcipTxType,
        uint64,
        address,
        uint256
    ) {
        return abi.decode(performData, (address, address, IYieldPeer.Strategy, IYieldPeer.CcipTxType, uint64, address, uint256));
    }

    function createPerformData(
        address forwarder,
        address parentPeer,
        IYieldPeer.Strategy memory strategy,
        IYieldPeer.CcipTxType txType,
        uint64 oldChainSelector,
        address oldStrategyPool,
        uint256 totalValue
    ) public pure returns (bytes memory) {
        return abi.encode(forwarder, parentPeer, strategy, txType, oldChainSelector, oldStrategyPool, totalValue);
    }

    function getTotalValueFromParentPeer() public view returns (uint256) {
        return IParentPeer(s_parentPeer).getTotalValue();
    }

    function getStrategyPoolFromParentPeer() public view returns (address) {
        return IParentPeer(s_parentPeer).getStrategyPool();
    }

    function createNonEmptyBytes() public pure returns (bytes memory) {
        return abi.encode(1);
    }

    function createEmptyBytes() public pure returns (bytes memory) {
        return "";
    }
}

/**
 * address forwarder,
            address parentPeer,
            IYieldPeer.Strategy memory strategy,
            IYieldPeer.CcipTxType txType,
            uint64 oldChainSelector,
            address oldStrategyPool,
            uint256 totalValue
 */