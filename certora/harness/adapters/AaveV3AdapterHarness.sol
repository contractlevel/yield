// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AaveV3Adapter} from "../../../src/adapters/AaveV3Adapter.sol";
import {HelperHarness} from "../HelperHarness.sol";
import {IPoolAddressesProvider} from "@aave/v3-origin/src/contracts/interfaces/IPoolAddressesProvider.sol";

contract AaveV3AdapterHarness is AaveV3Adapter, HelperHarness {
    constructor(
        address yieldPeer,
        address aavePoolAddressesProvider
    ) AaveV3Adapter(yieldPeer, aavePoolAddressesProvider) {}

    // @review:certora this can be modularized across adapter harnesses
    function isReentrancyGuardLocked() public view returns (bool) {
        return _reentrancyGuardEntered();
    }
}