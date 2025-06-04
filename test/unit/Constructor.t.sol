// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../BaseTest.t.sol";
import {IYieldPeer} from "../../src/interfaces/IYieldPeer.sol";

contract ConstructorTest is BaseTest {
    function test_yield_parent_constructor() public view {
        assertEq(baseParentPeer.getLink(), baseNetworkConfig.tokens.link);
        assertEq(baseParentPeer.getThisChainSelector(), baseNetworkConfig.ccip.thisChainSelector);
        assertEq(baseParentPeer.getUsdc(), baseNetworkConfig.tokens.usdc);
        assertEq(baseParentPeer.getAavePoolAddressesProvider(), baseNetworkConfig.protocols.aavePoolAddressesProvider);
        assertEq(baseParentPeer.getComet(), baseNetworkConfig.protocols.comet);
        assertEq(baseParentPeer.getShare(), address(baseShare));

        assertEq(uint8(baseParentPeer.getStrategy().protocol), uint8(IYieldPeer.Protocol.Aave));
        assertEq(baseParentPeer.getStrategy().chainSelector, baseNetworkConfig.ccip.thisChainSelector);

        assertEq(baseParentPeer.getFunctionsRouter(), baseNetworkConfig.clf.functionsRouter);
        assertEq(baseParentPeer.getDonId(), baseNetworkConfig.clf.donId);
        assertEq(baseParentPeer.getClfSubId(), clfSubId);
    }

    function test_yield_child_constructor() public view {
        assertEq(optChildPeer.getLink(), optNetworkConfig.tokens.link);
        assertEq(optChildPeer.getThisChainSelector(), optNetworkConfig.ccip.thisChainSelector);
        assertEq(optChildPeer.getUsdc(), optNetworkConfig.tokens.usdc);
        assertEq(optChildPeer.getAavePoolAddressesProvider(), optNetworkConfig.protocols.aavePoolAddressesProvider);
        assertEq(optChildPeer.getComet(), optNetworkConfig.protocols.comet);
        assertEq(optChildPeer.getShare(), address(optShare));
        assertEq(optChildPeer.getParentChainSelector(), baseNetworkConfig.ccip.thisChainSelector);

        assertEq(ethChildPeer.getLink(), ethNetworkConfig.tokens.link);
        assertEq(ethChildPeer.getThisChainSelector(), ethNetworkConfig.ccip.thisChainSelector);
        assertEq(ethChildPeer.getUsdc(), ethNetworkConfig.tokens.usdc);
        assertEq(ethChildPeer.getAavePoolAddressesProvider(), ethNetworkConfig.protocols.aavePoolAddressesProvider);
        assertEq(ethChildPeer.getComet(), ethNetworkConfig.protocols.comet);
        assertEq(ethChildPeer.getShare(), address(ethShare));
        assertEq(ethChildPeer.getParentChainSelector(), baseNetworkConfig.ccip.thisChainSelector);
    }
}
