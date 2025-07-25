// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {StrategyRegistry} from "../../src/modules/StrategyRegistry.sol";

contract StrategyRegistryHarness is StrategyRegistry {
    function bytes32ToAddress(bytes32 b) external returns (address) {
        return address(uint160(uint256(b)));
    }
}