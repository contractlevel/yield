// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.26;

// import {AaveV3} from "../../src/adapters/AaveV3.sol";

// contract DeployAaveV3Script is AaveV3Adapter {
//     function run() public returns (AaveV3, HelperConfig) {
//         HelperConfig helperConfig = new HelperConfig();
//         vm.startBroadcast();
//         AaveV3 aaveV3 = new AaveV3(helperConfig.getYieldPeer(), helperConfig.getAavePoolAddressesProvider());
//         vm.stopBroadcast();
//         return (aaveV3, helperConfig);
//     }
// }

// @review maybe delete this file
