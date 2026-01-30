// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";

contract ImplementationSlotTest is BaseTest {
    /// @dev Sanity test to verify the impl storage slot for ParentPeer proxy has Impl address
    function test_yield_parent_proxy_implementationSlot_hasImplAddress() public {
        // Arrange & Act
        _selectFork(baseFork);
        bytes32 slotValue = vm.load(address(baseParentPeer), IMPLEMENTATION_SLOT);
        address storedImplementation = address(uint160(uint256(slotValue)));

        // Assert
        assertEq(storedImplementation, baseParentPeerImplAddr, "ParentPeer proxy should point to ParentPeer Impl Addr");
    }
}
