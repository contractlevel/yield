// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IYieldPeer} from "./IYieldPeer.sol";

interface IParentPeer {
    function rebalanceNewStrategy(address oldStrategyPool, uint256 totalValue, IYieldPeer.Strategy calldata newStrategy)
        external;
    function rebalanceOldStrategy(uint64 oldStrategyChainSelector, IYieldPeer.Strategy calldata newStrategy) external;
    function getThisChainSelector() external view returns (uint64);
}
