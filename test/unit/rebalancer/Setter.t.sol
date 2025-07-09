// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, console2, ParentPeer, ChildPeer, Share, IYieldPeer, Rebalancer} from "../../BaseTest.t.sol";

contract SetterTest is BaseTest {
    function test_yield_setForwarder_revertsWhen_notOwner() public {
        _changePrank(holder);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", holder));
        baseRebalancer.setForwarder(address(forwarder));
    }

    function test_yield_setForwarder_success() public {
        address newForwarder = makeAddr("newForwarder");
        _changePrank(baseRebalancer.owner());
        baseRebalancer.setForwarder(newForwarder);
        assertEq(baseRebalancer.getForwarder(), newForwarder);
    }

    function test_yield_setParentPeer_revertsWhen_notOwner() public {
        address newParentPeer = makeAddr("newParentPeer");
        _changePrank(holder);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", holder));
        baseRebalancer.setParentPeer(newParentPeer);
    }

    function test_yield_setParentPeer_success() public {
        address newParentPeer = makeAddr("newParentPeer");
        _changePrank(baseRebalancer.owner());
        baseRebalancer.setParentPeer(newParentPeer);
        assertEq(baseRebalancer.getParentPeer(), newParentPeer);
    }

    function test_yield_rebalanceNewStrategy_revertsWhen_notParentRebalancer() public {
        vm.expectRevert(abi.encodeWithSignature("ParentPeer__OnlyRebalancer()"));
        baseParentPeer.rebalanceNewStrategy(
            address(0), 0, IYieldPeer.Strategy({chainSelector: 0, protocol: IYieldPeer.Protocol.Aave})
        );
    }

    function test_yield_rebalanceOldStrategy_revertsWhen_notParentRebalancer() public {
        vm.expectRevert(abi.encodeWithSignature("ParentPeer__OnlyRebalancer()"));
        baseParentPeer.rebalanceOldStrategy(
            0, IYieldPeer.Strategy({chainSelector: 0, protocol: IYieldPeer.Protocol.Aave})
        );
    }
}
