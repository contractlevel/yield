// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";

contract ImplementationSlotTest is BaseTest {
    /// @dev Sanity test to verify the impl storage slot for ChildPeer proxy has Impl address
    function test_yield_child_proxy_implementationSlot_hasImplAddress() public {
        // Arrange & Act
        _selectFork(optFork);
        bytes32 slotValue = vm.load(address(optChildPeer), IMPLEMENTATION_SLOT);
        address storedImplementation = address(uint160(uint256(slotValue)));

        // Assert
        assertEq(
            storedImplementation, optChildPeerImplAddr, "ChildPeer (Opt) proxy should point to ChildPeer Impl Addr"
        );
    }
}
