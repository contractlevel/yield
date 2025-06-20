// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, console2, ParentCLF, ChildPeer, Share, IYieldPeer, ParentRebalancer} from "../../BaseTest.t.sol";

contract SetterTest is BaseTest {
    function test_yield_setForwarder_revertsWhen_notOwner() public {
        _changePrank(holder);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", holder));
        baseParentRebalancer.setForwarder(address(forwarder));
    }

    function test_yield_setForwarder_success() public {
        address newForwarder = makeAddr("newForwarder");
        _changePrank(baseParentRebalancer.owner());
        baseParentRebalancer.setForwarder(newForwarder);
        assertEq(baseParentRebalancer.getForwarder(), newForwarder);
    }

    function test_yield_setParentPeer_revertsWhen_notOwner() public {
        address newParentPeer = makeAddr("newParentPeer");
        _changePrank(holder);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", holder));
        baseParentRebalancer.setParentPeer(newParentPeer);
    }

    function test_yield_setParentPeer_success() public {
        address newParentPeer = makeAddr("newParentPeer");
        _changePrank(baseParentRebalancer.owner());
        baseParentRebalancer.setParentPeer(newParentPeer);
        assertEq(baseParentRebalancer.getParentPeer(), newParentPeer);
    }

    function test_yield_rebalanceNewStrategy_revertsWhen_notParentRebalancer() public {
        vm.expectRevert(abi.encodeWithSignature("ParentPeer__OnlyParentRebalancer()"));
        baseParentPeer.rebalanceNewStrategy(
            address(0), 0, IYieldPeer.Strategy({chainSelector: 0, protocol: IYieldPeer.Protocol.Aave})
        );
    }

    function test_yield_rebalanceOldStrategy_revertsWhen_notParentRebalancer() public {
        vm.expectRevert(abi.encodeWithSignature("ParentPeer__OnlyParentRebalancer()"));
        baseParentPeer.rebalanceOldStrategy(
            0, IYieldPeer.Strategy({chainSelector: 0, protocol: IYieldPeer.Protocol.Aave})
        );
    }
}
