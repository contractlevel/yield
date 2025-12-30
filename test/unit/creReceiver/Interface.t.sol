// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm} from "../../BaseTest.t.sol";
import {IReceiver, IERC165} from "@chainlink/contracts/src/v0.8/keystone/interfaces/IReceiver.sol";

/// @dev CREReceiver inherited by Rebalancer
contract InterfaceTest is BaseTest {
    function test_yield_creReceiver_supportsInterface_returnsTrue_whenIReceiverInterface() public view {
        // Arrange
        bytes4 iReceiverInterfaceId = type(IReceiver).interfaceId;

        // Act & Assert
        bool isSupported = baseRebalancer.supportsInterface(iReceiverInterfaceId);
        assertEq(isSupported, true);
    }

    function test_yield_creReceiver_supportsInterface_returnsTrue_whenIERC165Interface() public view {
        // Arrange
        bytes4 ierc165InterfaceId = type(IERC165).interfaceId;

        // Act & Assert
        bool isSupported = baseRebalancer.supportsInterface(ierc165InterfaceId);
        assertEq(isSupported, true);
    }

    function test_yield_creReceiver_supportsInterface_returnsFalse_whenUnsupportedInterface() public view {
        // Arrange
        bytes4 randomInterfaceId = 0x12345678;

        // Act & Assert
        bool isSupported = baseRebalancer.supportsInterface(randomInterfaceId);
        assertEq(isSupported, false);
    }
}
