// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {MockCometNoYield} from "../../../test/mocks/testnet/MockCometNoYield.sol";

/// @notice This is for deploying the Mock Compound contract on testnets that do not have the actual Compound contracts deployed
contract DeployMockCometNoYield is Script {
    function run() public returns (MockCometNoYield) {
        vm.startBroadcast();
        MockCometNoYield mockCometNoYield = new MockCometNoYield();
        vm.stopBroadcast();

        return mockCometNoYield;
    }
}
