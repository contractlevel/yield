// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Roles} from "../../BaseTest.t.sol";

contract SetStablecoinRegistryTest is BaseTest {
    event StablecoinRegistrySet(address indexed stablecoinRegistry);

    /*//////////////////////////////////////////////////////////////
                        SET STABLECOIN REGISTRY
    //////////////////////////////////////////////////////////////*/
    function test_yield_yieldPeer_setStablecoinRegistry_revertsWhen_notConfigAdmin() public {
        _changePrank(holder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", holder, Roles.CONFIG_ADMIN_ROLE
            )
        );
        baseParentPeer.setStablecoinRegistry(address(0x123));
    }

    function test_yield_yieldPeer_setStablecoinRegistry_success() public {
        address newRegistry = makeAddr("newStablecoinRegistry");
        _changePrank(configAdmin);
        baseParentPeer.setStablecoinRegistry(newRegistry);
        assertEq(baseParentPeer.getStablecoinRegistry(), newRegistry);
    }

    function test_yield_yieldPeer_setStablecoinRegistry_emitsEvent() public {
        address newRegistry = makeAddr("newStablecoinRegistry");
        _changePrank(configAdmin);
        vm.expectEmit(true, false, false, false);
        emit StablecoinRegistrySet(newRegistry);
        baseParentPeer.setStablecoinRegistry(newRegistry);
    }

    function test_yield_yieldPeer_setStablecoinRegistry_canSetToZero() public {
        address newRegistry = makeAddr("newStablecoinRegistry");
        _changePrank(configAdmin);
        baseParentPeer.setStablecoinRegistry(newRegistry);
        assertEq(baseParentPeer.getStablecoinRegistry(), newRegistry);

        baseParentPeer.setStablecoinRegistry(address(0));
        assertEq(baseParentPeer.getStablecoinRegistry(), address(0));
    }

    /*//////////////////////////////////////////////////////////////
                        GET STABLECOIN REGISTRY
    //////////////////////////////////////////////////////////////*/
    function test_yield_yieldPeer_getStablecoinRegistry_returnsCorrectAddress() public {
        address newRegistry = makeAddr("newStablecoinRegistry");
        _changePrank(configAdmin);
        baseParentPeer.setStablecoinRegistry(newRegistry);
        assertEq(baseParentPeer.getStablecoinRegistry(), newRegistry);
    }
}
