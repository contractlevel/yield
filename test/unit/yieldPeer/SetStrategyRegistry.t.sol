// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";

contract SetStrategyRegistryTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_yield_yieldPeer_setStrategyRegistry_revertsWhen_notOwner() public {
        _changePrank(holder);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", holder));
        baseParentPeer.setStrategyRegistry(address(baseStrategyRegistry));
    }

    function test_yield_yieldPeer_setStrategyRegistry_success() public {
        address newStrategyRegistry = makeAddr("newStrategyRegistry");
        _changePrank(baseParentPeer.owner());
        baseParentPeer.setStrategyRegistry(newStrategyRegistry);
        assertEq(baseParentPeer.getStrategyRegistry(), newStrategyRegistry);
    }
}
