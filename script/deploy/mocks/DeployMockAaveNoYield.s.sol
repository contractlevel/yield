// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {MockAaveNoYield} from "../../../test/mocks/testnet/MockAaveNoYield.sol";
import {MockAToken} from "../../../test/mocks/MockAToken.sol";
import {MockPoolAddressesProvider} from "../../../test/mocks/MockPoolAddressesProvider.sol";
import {HelperConfig} from "../../HelperConfig.s.sol";

/// @notice This is for deploying the Mock Aave contract on testnets that do not have the actual Aave contracts deployed
contract DeployMockAaveNoYield is Script {
    function run() public returns (HelperConfig, MockAaveNoYield, MockAToken, MockPoolAddressesProvider) {
        HelperConfig config = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = config.getActiveNetworkConfig();
        vm.startBroadcast();
        MockAaveNoYield mockAaveNoYield = new MockAaveNoYield(networkConfig.tokens.usdc);
        MockAToken mockAToken = new MockAToken(address(mockAaveNoYield));
        MockPoolAddressesProvider mockPoolAddressesProvider = new MockPoolAddressesProvider(address(mockAaveNoYield));
        mockAaveNoYield.setATokenAddress(address(mockAToken));
        vm.stopBroadcast();

        return (config, mockAaveNoYield, mockAToken, mockPoolAddressesProvider);
    }
}
