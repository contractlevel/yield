// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Roles} from "../../BaseTest.t.sol";

contract SetAllowedTest is BaseTest {
    function test_yield_setAllowedChain_revertsWhen_notCrossChainAdmin() public {
        /// @dev arrange
        address notOwner = makeAddr("notCrossChainAdmin");
        _changePrank(notOwner);

        /// @dev act/assert
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", notOwner, Roles.CROSS_CHAIN_ADMIN_ROLE
            )
        );
        baseParentPeer.setAllowedChain(baseChainSelector, true);
    }

    function test_yield_setAllowedPeer_revertsWhen_notCrossChainAdmin() public {
        /// @dev arrange
        address notOwner = makeAddr("notCrossChainAdmin");
        _changePrank(notOwner);

        /// @dev act/assert
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)", notOwner, Roles.CROSS_CHAIN_ADMIN_ROLE
            )
        );
        baseParentPeer.setAllowedPeer(baseChainSelector, address(0));
    }

    function test_yield_setAllowedChain_revertsWhen_chainSelectorNotAllowed() public {
        /// @dev arrange
        _changePrank(crossChainAdmin);

        uint64 invalidChainSelector = 100;
        address attemptedPeer = makeAddr("attemptedPeer");

        /// @dev act/assert
        vm.expectRevert(abi.encodeWithSignature("YieldPeer__ChainNotAllowed(uint64)", invalidChainSelector));
        baseParentPeer.setAllowedPeer(invalidChainSelector, attemptedPeer);
    }
}
