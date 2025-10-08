// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IYieldPeer} from "./IYieldPeer.sol";

interface IParentPeer is IYieldPeer {
    function rebalanceNewStrategy(address oldStrategyPool, uint256 totalValue, IYieldPeer.Strategy calldata newStrategy)
        external;
    function rebalanceOldStrategy(uint64 oldStrategyChainSelector, IYieldPeer.Strategy calldata newStrategy) external;
    // @reviewGeorge - Added to check renamed belancing
    function rebalanceParentToChildStrategy(
        address oldStrategyPool,
        uint256 totalValue,
        IYieldPeer.Strategy calldata newStrategy
    ) external;
    // @reviewGeorge - Added to check renamed belancing
    function rebalanceChildToOtherStrategy(uint64 oldStrategyChainSelector, IYieldPeer.Strategy calldata newStrategy)
        external;
    // @reviewGeorge - Added to check renamed belancing
    function rebalanceParentToRemoteOrChildToOtherStrategy(
        address oldStrategyAdapter,
        uint64 oldChainSelector,
        uint256 totalValue,
        IYieldPeer.Strategy calldata newStrategy,
        IYieldPeer.CcipTxType txType
    ) external;
    function getThisChainSelector() external view returns (uint64);
    function getStrategyPool() external view returns (address);
    function getTotalValue() external view returns (uint256);
    function setStrategy(uint64 chainSelector, bytes32 protocolId) external;
    function getStrategy() external view returns (IYieldPeer.Strategy memory);
}
