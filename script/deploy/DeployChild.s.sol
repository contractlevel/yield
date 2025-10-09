// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {ChildPeer} from "../../src/peers/ChildPeer.sol";
import {Share} from "../../src/token/Share.sol";
import {SharePool} from "../../src/token/SharePool.sol";
import {ITokenAdminRegistry} from "@chainlink/contracts/src/v0.8/ccip/interfaces/ITokenAdminRegistry.sol";
import {
    RegistryModuleOwnerCustom
} from "@chainlink/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {AaveV3Adapter} from "../../src/adapters/AaveV3Adapter.sol";
import {CompoundV3Adapter} from "../../src/adapters/CompoundV3Adapter.sol";
import {IYieldPeer} from "../../src/interfaces/IYieldPeer.sol";
import {StrategyRegistry} from "../../src/modules/StrategyRegistry.sol";
import {StablecoinRegistry} from "../../src/modules/StablecoinRegistry.sol";

contract DeployChild is Script {
    struct DeploymentConfig {
        Share share;
        SharePool sharePool;
        ChildPeer childPeer;
        HelperConfig config;
        StrategyRegistry strategyRegistry;
        AaveV3Adapter aaveV3Adapter;
        CompoundV3Adapter compoundV3Adapter;
        StablecoinRegistry stablecoinRegistry;
    }

    /*//////////////////////////////////////////////////////////////
                                  RUN
    //////////////////////////////////////////////////////////////*/
    function run() public returns (DeploymentConfig memory childDeploy) {
        childDeploy.config = new HelperConfig();

        vm.startBroadcast();
        HelperConfig.NetworkConfig memory networkConfig = childDeploy.config.getActiveNetworkConfig();
        childDeploy.share = new Share();
        childDeploy.sharePool =
            new SharePool(address(childDeploy.share), networkConfig.ccip.rmnProxy, networkConfig.ccip.ccipRouter);
        RegistryModuleOwnerCustom(networkConfig.ccip.registryModuleOwnerCustom)
            .registerAdminViaOwner(address(childDeploy.share));
        ITokenAdminRegistry(networkConfig.ccip.tokenAdminRegistry).acceptAdminRole(address(childDeploy.share));
        ITokenAdminRegistry(networkConfig.ccip.tokenAdminRegistry)
            .setPool(address(childDeploy.share), address(childDeploy.sharePool));

        childDeploy.childPeer = new ChildPeer(
            networkConfig.ccip.ccipRouter,
            networkConfig.tokens.link,
            networkConfig.ccip.thisChainSelector,
            networkConfig.tokens.usdc,
            address(childDeploy.share),
            networkConfig.ccip.parentChainSelector
        );
        childDeploy.share.grantMintAndBurnRoles(address(childDeploy.sharePool));
        childDeploy.share.grantMintAndBurnRoles(address(childDeploy.childPeer));

        childDeploy.strategyRegistry = new StrategyRegistry();
        childDeploy.aaveV3Adapter =
            new AaveV3Adapter(address(childDeploy.childPeer), networkConfig.protocols.aavePoolAddressesProvider);
        childDeploy.compoundV3Adapter =
            new CompoundV3Adapter(address(childDeploy.childPeer), networkConfig.protocols.comet);
        childDeploy.strategyRegistry
            .setStrategyAdapter(keccak256(abi.encodePacked("aave-v3")), address(childDeploy.aaveV3Adapter));
        childDeploy.strategyRegistry
            .setStrategyAdapter(keccak256(abi.encodePacked("compound-v3")), address(childDeploy.compoundV3Adapter));
        childDeploy.childPeer.setStrategyRegistry(address(childDeploy.strategyRegistry));
        childDeploy.stablecoinRegistry = new StablecoinRegistry();
        // populate Child stablecoin registry

        vm.stopBroadcast();
    }
}
