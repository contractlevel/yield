// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Roles} from "../../BaseTest.t.sol";

contract SetStrategyRegistryTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_yield_yieldPeer_setStrategyRegistry_revertsWhen_notConfigAdmin() public {
        _changePrank(holder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", holder, Roles.CONFIG_ADMIN_ROLE
            )
        );
        baseParentPeer.setStrategyRegistry(address(baseStrategyRegistry));
    }

    function test_yield_yieldPeer_setStrategyRegistry_success() public {
        address newStrategyRegistry = makeAddr("newStrategyRegistry");
        _changePrank(baseParentPeer.owner());
        baseParentPeer.grantRole(Roles.CONFIG_ADMIN_ROLE, baseParentPeer.owner());
        baseParentPeer.setStrategyRegistry(newStrategyRegistry);
        assertEq(baseParentPeer.getStrategyRegistry(), newStrategyRegistry);
    }
}
