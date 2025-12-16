// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Rebalancer, IParentPeer, IYieldPeer, IStrategyRegistry} from "../../src/modules/Rebalancer.sol";
import {HelperHarness} from "./HelperHarness.sol";

contract RebalancerHarness is Rebalancer, HelperHarness {
    function getParentChainSelector() public view returns (uint64) {
        return IParentPeer(s_parentPeer).getThisChainSelector();
    }

    function getTotalValueFromParentPeer() public view returns (uint256) {
        return IParentPeer(s_parentPeer).getTotalValue();
    }

    function getActiveStrategyAdapterFromParentPeer() public view returns (address) {
        return IParentPeer(s_parentPeer).getActiveStrategyAdapter();
    }

    function getStrategyFromParentPeer() public view returns (IYieldPeer.Strategy memory) {
        return IParentPeer(s_parentPeer).getStrategy();
    }
}
