// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {IYieldPeer} from "./IYieldPeer.sol";

interface IParentPeer is IYieldPeer {
    function rebalance(IYieldPeer.Strategy calldata newStrategy) external;
    function getStrategy() external view returns (IYieldPeer.Strategy memory);
}
