// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IYieldPeer} from "./IYieldPeer.sol";

interface IParentPeer is IYieldPeer {
    function rebalanceParentToChild(
        address oldStrategyPool,
        uint256 totalValue,
        IYieldPeer.Strategy calldata newStrategy
    ) external;
    function rebalanceChildToOther(uint64 oldStrategyChainSelector, IYieldPeer.Strategy calldata newStrategy)
        external;
    function getThisChainSelector() external view returns (uint64);
    function getStrategyPool() external view returns (address);
    function getTotalValue() external view returns (uint256);
    function setStrategy(uint64 chainSelector, bytes32 protocolId) external;
    function getStrategy() external view returns (IYieldPeer.Strategy memory);
}
