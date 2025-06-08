// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract MockPoolAddressesProvider {
    /// @notice making this immutable to make verifying with certora easier later
    address internal immutable i_pool;

    constructor(address pool) {
        i_pool = pool;
    }

    function getPool() external view returns (address) {
        return i_pool;
    }
}
