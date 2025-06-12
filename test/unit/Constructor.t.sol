// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../BaseTest.t.sol";
import {IYieldPeer} from "../../src/interfaces/IYieldPeer.sol";

contract ConstructorTest is BaseTest {
    function test_yield_parent_constructor() public view {
        assertEq(baseParentPeer.getLink(), baseNetworkConfig.tokens.link);
        assertEq(baseParentPeer.getThisChainSelector(), baseNetworkConfig.ccip.thisChainSelector);
        assertEq(baseParentPeer.getUsdc(), baseNetworkConfig.tokens.usdc);
        assertEq(baseParentPeer.getAave(), baseNetworkConfig.protocols.aavePoolAddressesProvider);
        assertEq(baseParentPeer.getCompound(), baseNetworkConfig.protocols.comet);
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
        assertEq(optChildPeer.getAave(), optNetworkConfig.protocols.aavePoolAddressesProvider);
        assertEq(optChildPeer.getCompound(), optNetworkConfig.protocols.comet);
        assertEq(optChildPeer.getShare(), address(optShare));
        assertEq(optChildPeer.getParentChainSelector(), baseNetworkConfig.ccip.thisChainSelector);

        assertEq(ethChildPeer.getLink(), ethNetworkConfig.tokens.link);
        assertEq(ethChildPeer.getThisChainSelector(), ethNetworkConfig.ccip.thisChainSelector);
        assertEq(ethChildPeer.getUsdc(), ethNetworkConfig.tokens.usdc);
        assertEq(ethChildPeer.getAave(), ethNetworkConfig.protocols.aavePoolAddressesProvider);
        assertEq(ethChildPeer.getCompound(), ethNetworkConfig.protocols.comet);
        assertEq(ethChildPeer.getShare(), address(ethShare));
        assertEq(ethChildPeer.getParentChainSelector(), baseNetworkConfig.ccip.thisChainSelector);
    }

    function test_yield_getIsStrategyChain() public view {
        assertEq(baseParentPeer.getIsStrategyChain(), true);
        assertEq(optChildPeer.getIsStrategyChain(), false);
        assertEq(ethChildPeer.getIsStrategyChain(), false);
    }

    function test_yield_getStrategyPool() public view {
        assertEq(baseParentPeer.getStrategyPool(), baseNetworkConfig.protocols.aavePoolAddressesProvider);
        assertEq(optChildPeer.getStrategyPool(), address(0));
        assertEq(ethChildPeer.getStrategyPool(), address(0));
    }

    function test_yield_getTotalValue() public {
        assertEq(baseParentPeer.getTotalValue(), 0);
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__NotStrategyChain()"));
        optChildPeer.getTotalValue();
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__NotStrategyChain()"));
        ethChildPeer.getTotalValue();
    }

    function test_yield_get_strategy_addresses() public view {
        assertEq(baseParentPeer.getCompound(), baseNetworkConfig.protocols.comet);
        assertEq(baseParentPeer.getAave(), baseNetworkConfig.protocols.aavePoolAddressesProvider);

        assertEq(optChildPeer.getCompound(), optNetworkConfig.protocols.comet);
        assertEq(optChildPeer.getAave(), optNetworkConfig.protocols.aavePoolAddressesProvider);

        assertEq(ethChildPeer.getCompound(), ethNetworkConfig.protocols.comet);
        assertEq(ethChildPeer.getAave(), ethNetworkConfig.protocols.aavePoolAddressesProvider);
    }

    function test_yield_getTotalValue_revertsWhen_notStrategyChain() public {
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__NotStrategyChain()"));
        optChildPeer.getTotalValue();
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__NotStrategyChain()"));
        ethChildPeer.getTotalValue();
    }
}
