// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, ChildPeer} from "../../BaseTest.t.sol";

contract InitializeTest is BaseTest {
    // --- PROXY CHECK ---
    /// @dev we expect the proxy to revert when initialize is called again
    function test_yield_child_proxy_initialize_revertsWhen_calledAgain() public {
        // Arrange
        _selectFork(optFork);

        // Act & Assert
        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        optChildPeer.initialize();
    }

    // --- IMPLEMENTATION CHECK ---
    /// @dev we expect the implementation contract to revert when initialize is called directly
    function test_yield_child_implementation_initialize_revertsWhen_calledDirectly() public {
        // Arrange
        _selectFork(optFork);
        ChildPeer impl = ChildPeer(optChildPeerImplAddr); /// @dev direct impl address

        // Act & Assert
        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        impl.initialize();
    }
}
