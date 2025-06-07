// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";

contract SetAllowedTest is BaseTest {
    function test_yield_setAllowedChain_revertsWhen_notOwner() public {
        /// @dev arrange
        address notOwner = makeAddr("notOwner");
        _changePrank(notOwner);

        /// @dev act/assert
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", notOwner));
        baseParentPeer.setAllowedChain(baseChainSelector, true);
    }

    function test_yield_setAllowedPeer_revertsWhen_notOwner() public {
        /// @dev arrange
        address notOwner = makeAddr("notOwner");
        _changePrank(notOwner);

        /// @dev act/assert
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", notOwner));
        baseParentPeer.setAllowedPeer(baseChainSelector, address(0));
    }

    function test_yield_setAllowedChain_revertsWhen_chainSelectorNotAllowed() public {
        /// @dev arrange
        _changePrank(baseParentPeer.owner());

        uint64 invalidChainSelector = 100;
        address attemptedPeer = makeAddr("attemptedPeer");

        /// @dev act/assert
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__ChainNotAllowed(uint64)", invalidChainSelector));
        baseParentPeer.setAllowedPeer(invalidChainSelector, attemptedPeer);
    }
}
