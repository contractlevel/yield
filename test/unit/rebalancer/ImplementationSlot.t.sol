// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";

contract ImplementationSlotTest is BaseTest {
    function test_yield_rebalancer_proxy_implementationSlot_hasImplAddress() public {
        // Arrange & Act
        _selectFork(baseFork);
        bytes32 slotValue = vm.load(address(baseRebalancer), IMPLEMENTATION_SLOT);
        address storedImplementation = address(uint160(uint256(slotValue)));

        // Assert
        assertEq(storedImplementation, baseRebalancerImplAddr, "Rebalancer proxy should point to Rebalancer Impl Addr");
    }
}
