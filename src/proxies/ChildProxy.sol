// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title ChildProxy
/// @author Judge Finance
/// @notice This contract serves as a proxy for the YieldCoin Child contract.
/// @dev This contract implements an ERC1967 proxy that delegates calls to a logic contract.
contract ChildProxy is ERC1967Proxy {
    /// @param implementation The address of the initial implementation contract.
    /// @param initData The initialization data to be delegatecalled to the implementation contract.
    constructor(address implementation, bytes memory initData) ERC1967Proxy(implementation, initData) {}
}
