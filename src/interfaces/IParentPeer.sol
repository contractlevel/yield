// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IYieldPeer} from "./IYieldPeer.sol";

interface IParentPeer is IYieldPeer {
    function rebalance(IYieldPeer.Strategy calldata newStrategy) external;
    function getThisChainSelector() external view returns (uint64);
    function getActiveStrategyAdapter() external view returns (address);
    function getTotalValue() external view returns (uint256);
    function getStrategy() external view returns (IYieldPeer.Strategy memory);
}
