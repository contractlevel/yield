// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../../BaseTest.t.sol";

contract ConstructorTest is BaseTest {
    function test_yield_pausableWithAccessControlRebalancer_constructor() public view {
        /// @dev deployed admin transfer delay value in constructor is correct
        assertEq(baseRebalancer.defaultAdminDelay(), 3 days); // @reviewGeorge : check delay

        /// @dev deploying 'owner' should be 'default admin'
        assertEq(baseRebalancer.owner(), baseRebalancer.defaultAdmin());
    }

    function test_yield_pausableWithAccessControlYieldPeer_constructor() public view {
        /// @dev deployed admin transfer delay value in constructor is correct
        assertEq(baseParentPeer.defaultAdminDelay(), 3 days); // @reviewGeorge : check delay

        /// @dev deploying 'owner' should be 'default admin'
        assertEq(baseParentPeer.owner(), baseParentPeer.defaultAdmin());
    }
}
