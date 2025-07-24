// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, IYieldPeer} from "../../BaseTest.t.sol";

contract SetStrategyAdapterTest is BaseTest {
    function test_yield_setStrategyAdapter_revertsWhen_notOwner() public {
        _changePrank(holder);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", holder));
        baseStrategyRegistry.setStrategyAdapter(keccak256(abi.encodePacked("aave-v3")), address(baseAaveV3Adapter));
    }

    function test_yield_setInitialActiveStrategy_revertsWhen_notOwner() public {
        _changePrank(holder);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", holder));
        baseParentPeer.setInitialActiveStrategy(keccak256(abi.encodePacked("aave-v3")));
    }

    function test_yield_setInitialActiveStrategy_revertsWhen_alreadySet() public {
        _changePrank(baseParentPeer.owner());
        vm.expectRevert(abi.encodeWithSignature("ParentPeer__InitialActiveStrategyAlreadySet()"));
        baseParentPeer.setInitialActiveStrategy(keccak256(abi.encodePacked("aave-v3")));
    }

    function test_yield_strategyAdapter_onlyYieldPeer() public {
        vm.expectRevert(abi.encodeWithSignature("StrategyAdapter__OnlyYieldPeer()"));
        baseAaveV3Adapter.deposit(address(baseUsdc), DEPOSIT_AMOUNT);
    }
}
