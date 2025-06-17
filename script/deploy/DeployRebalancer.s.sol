// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {ParentRebalancer} from "../../src/modules/ParentRebalancer.sol";

contract DeployRebalancer is Script {
    function run() public returns (ParentRebalancer) {
        vm.startBroadcast();
        ParentRebalancer rebalancer = new ParentRebalancer();
        vm.stopBroadcast();
        return rebalancer;
    }
}
