// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {CompoundV3Adapter} from "../../../src/adapters/CompoundV3Adapter.sol";
import {HelperHarness} from "../HelperHarness.sol";

contract CompoundV3AdapterHarness is CompoundV3Adapter, HelperHarness {
    constructor(
        address yieldPeer,
        address comet
    ) CompoundV3Adapter(yieldPeer, comet) {}

    // @review:certora this can be modularized across adapter harnesses
    function isReentrancyGuardLocked() public view returns (bool) {
        return _reentrancyGuardEntered();
    }
}