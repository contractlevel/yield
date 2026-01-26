// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Roles} from "../../BaseTest.t.sol";

contract SetSwapperTest is BaseTest {
    event SwapperSet(address indexed swapper);

    /*//////////////////////////////////////////////////////////////
                            SET SWAPPER
    //////////////////////////////////////////////////////////////*/
    function test_yield_yieldPeer_setSwapper_revertsWhen_notConfigAdmin() public {
        _changePrank(holder);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", holder, Roles.CONFIG_ADMIN_ROLE
            )
        );
        baseParentPeer.setSwapper(address(0x123));
    }

    function test_yield_yieldPeer_setSwapper_success() public {
        address newSwapper = makeAddr("newSwapper");
        _changePrank(configAdmin);
        baseParentPeer.setSwapper(newSwapper);
        assertEq(baseParentPeer.getSwapper(), newSwapper);
    }

    function test_yield_yieldPeer_setSwapper_emitsEvent() public {
        address newSwapper = makeAddr("newSwapper");
        _changePrank(configAdmin);
        vm.expectEmit(true, false, false, false);
        emit SwapperSet(newSwapper);
        baseParentPeer.setSwapper(newSwapper);
    }

    function test_yield_yieldPeer_setSwapper_canSetToZero() public {
        address newSwapper = makeAddr("newSwapper");
        _changePrank(configAdmin);
        baseParentPeer.setSwapper(newSwapper);
        assertEq(baseParentPeer.getSwapper(), newSwapper);

        baseParentPeer.setSwapper(address(0));
        assertEq(baseParentPeer.getSwapper(), address(0));
    }

    /*//////////////////////////////////////////////////////////////
                            GET SWAPPER
    //////////////////////////////////////////////////////////////*/
    function test_yield_yieldPeer_getSwapper_returnsCorrectAddress() public {
        address newSwapper = makeAddr("newSwapper");
        _changePrank(configAdmin);
        baseParentPeer.setSwapper(newSwapper);
        assertEq(baseParentPeer.getSwapper(), newSwapper);
    }
}
