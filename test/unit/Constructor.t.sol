// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../BaseTest.t.sol";
import {IYieldPeer} from "../../src/interfaces/IYieldPeer.sol";

contract ConstructorTest is BaseTest {
    function test_yield_parent_constructor() public view {
        assertEq(arbParentPeer.getLink(), arbNetworkConfig.link);
        assertEq(arbParentPeer.getThisChainSelector(), arbNetworkConfig.thisChainSelector);
        assertEq(arbParentPeer.getUsdc(), arbNetworkConfig.usdc);
        assertEq(arbParentPeer.getAavePoolAddressesProvider(), arbNetworkConfig.aavePoolAddressesProvider);
        assertEq(arbParentPeer.getComet(), arbNetworkConfig.comet);
        assertEq(arbParentPeer.getShare(), address(arbShare));

        assertEq(uint8(arbParentPeer.getStrategy().protocol), uint8(IYieldPeer.Protocol.Aave));
        assertEq(arbParentPeer.getStrategy().chainSelector, arbNetworkConfig.thisChainSelector);
    }

    function test_yield_child_constructor() public view {
        assertEq(optChildPeer.getLink(), optNetworkConfig.link);
        assertEq(optChildPeer.getThisChainSelector(), optNetworkConfig.thisChainSelector);
        assertEq(optChildPeer.getUsdc(), optNetworkConfig.usdc);
        assertEq(optChildPeer.getAavePoolAddressesProvider(), optNetworkConfig.aavePoolAddressesProvider);
        assertEq(optChildPeer.getComet(), optNetworkConfig.comet);
        assertEq(optChildPeer.getShare(), address(optShare));
        assertEq(optChildPeer.getParentChainSelector(), arbNetworkConfig.thisChainSelector);

        assertEq(ethChildPeer.getLink(), ethNetworkConfig.link);
        assertEq(ethChildPeer.getThisChainSelector(), ethNetworkConfig.thisChainSelector);
        assertEq(ethChildPeer.getUsdc(), ethNetworkConfig.usdc);
        assertEq(ethChildPeer.getAavePoolAddressesProvider(), ethNetworkConfig.aavePoolAddressesProvider);
        assertEq(ethChildPeer.getComet(), ethNetworkConfig.comet);
        assertEq(ethChildPeer.getShare(), address(ethShare));
        assertEq(ethChildPeer.getParentChainSelector(), arbNetworkConfig.thisChainSelector);
    }
}
