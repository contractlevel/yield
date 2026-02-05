// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Share} from "../../BaseTest.t.sol";

contract InitializationTest is BaseTest {
    // --- PROXY CHECK ---
    /// @dev we expect the proxy to revert when initialize is called again
    function test_yield_share_proxy_initialize_revertsWhen_calledAgain() public {
        // Arrange
        _selectFork(baseFork);

        // Act & Assert
        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        baseShare.initialize();
    }

    // --- IMPLEMENTATION CHECK ---
    /// @dev we expect the implementation contract to revert when initialize is called directly
    function test_yield_share_base_implementation_initialize_reverts() public {
        // Arrange
        _selectFork(baseFork);
        Share impl = Share(baseShareImplAddr);

        // Act & Assert
        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        impl.initialize();
    }
}
