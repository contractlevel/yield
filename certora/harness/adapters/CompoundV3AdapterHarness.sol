// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {CompoundV3Adapter} from "../../../src/adapters/CompoundV3Adapter.sol";
import {HelperHarness} from "../HelperHarness.sol";

contract CompoundV3AdapterHarness is CompoundV3Adapter, HelperHarness {
    constructor(
        address yieldPeer,
        address comet
    ) CompoundV3Adapter(yieldPeer, comet) {}
}