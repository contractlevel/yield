// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {StrategyHelper} from "../../src/modules/StrategyHelper.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract DeployStrategyHelper is Script {
    /*//////////////////////////////////////////////////////////////
                                  RUN
    //////////////////////////////////////////////////////////////*/
    function run() public returns (StrategyHelper strategyHelper) {
        HelperConfig config = new HelperConfig();

        vm.startBroadcast();
        HelperConfig.NetworkConfig memory networkConfig = config.getActiveNetworkConfig();
        strategyHelper = new StrategyHelper(networkConfig.protocols.aavePoolAddressesProvider);
        vm.stopBroadcast();
    }
}
