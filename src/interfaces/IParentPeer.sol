// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IYieldPeer} from "./IYieldPeer.sol";

interface IParentPeer {
    function rebalanceNewStrategy(IYieldPeer.Strategy memory newStrategy) external;
    function rebalanceOldStrategy(uint64 oldChainSelector, IYieldPeer.Strategy memory newStrategy) external;
    function getThisChainSelector() external view returns (uint64);
}
