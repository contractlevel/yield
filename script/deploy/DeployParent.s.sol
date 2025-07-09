// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ParentPeer} from "../../src/peers/ParentPeer.sol";
import {Rebalancer} from "../../src/modules/Rebalancer.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {Share} from "../../src/token/Share.sol";
import {SharePool} from "../../src/token/SharePool.sol";
import {IFunctionsSubscriptions} from
    "@chainlink/contracts/src/v0.8/functions/v1_0_0/interfaces/IFunctionsSubscriptions.sol";
import {IFunctionsRouter} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/interfaces/IFunctionsRouter.sol";
import {ITokenAdminRegistry} from "@chainlink/contracts/src/v0.8/ccip/interfaces/ITokenAdminRegistry.sol";
import {RegistryModuleOwnerCustom} from
    "@chainlink/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {AaveV3} from "../../src/adapters/AaveV3.sol";
import {CompoundV3} from "../../src/adapters/CompoundV3.sol";
import {IYieldPeer} from "../../src/interfaces/IYieldPeer.sol";

contract DeployParent is Script {
    struct DeploymentConfig {
        Share share;
        SharePool sharePool;
        ParentPeer parentPeer;
        Rebalancer rebalancer;
        HelperConfig config;
        uint64 clfSubId;
        AaveV3 aaveV3;
        CompoundV3 compoundV3;
    }

    /*//////////////////////////////////////////////////////////////
                                  RUN
    //////////////////////////////////////////////////////////////*/
    function run() public returns (DeploymentConfig memory deploy) {
        deploy.config = new HelperConfig();
        // @review this line was fine above the broadcast ??
        HelperConfig.NetworkConfig memory networkConfig = deploy.config.getActiveNetworkConfig();

        vm.startBroadcast();
        // Unit tests:
        deploy.clfSubId = IFunctionsSubscriptions(networkConfig.clf.functionsRouter).createSubscription();
        /// @notice Use this instead of the above line for premade subscription:
        // deploy.clfSubId = networkConfig.clf.clfSubId;

        deploy.share = new Share();
        deploy.sharePool =
            new SharePool(address(deploy.share), networkConfig.ccip.rmnProxy, networkConfig.ccip.ccipRouter);

        RegistryModuleOwnerCustom(networkConfig.ccip.registryModuleOwnerCustom).registerAdminViaOwner(
            address(deploy.share)
        );
        ITokenAdminRegistry(networkConfig.ccip.tokenAdminRegistry).acceptAdminRole(address(deploy.share));
        ITokenAdminRegistry(networkConfig.ccip.tokenAdminRegistry).setPool(
            address(deploy.share), address(deploy.sharePool)
        );

        deploy.rebalancer = new Rebalancer(networkConfig.clf.functionsRouter, networkConfig.clf.donId, deploy.clfSubId);
        deploy.parentPeer = new ParentPeer(
            networkConfig.ccip.ccipRouter,
            networkConfig.tokens.link,
            networkConfig.ccip.thisChainSelector,
            networkConfig.tokens.usdc,
            address(deploy.share),
            address(deploy.rebalancer)
        );

        deploy.share.grantMintAndBurnRoles(address(deploy.sharePool));
        deploy.share.grantMintAndBurnRoles(address(deploy.parentPeer));
        deploy.rebalancer.setParentPeer(address(deploy.parentPeer));

        deploy.aaveV3 = new AaveV3(address(deploy.parentPeer), networkConfig.protocols.aavePoolAddressesProvider);
        deploy.compoundV3 = new CompoundV3(address(deploy.parentPeer), networkConfig.protocols.comet);
        deploy.parentPeer.setStrategyAdapter(IYieldPeer.Protocol.Aave, address(deploy.aaveV3));
        deploy.parentPeer.setStrategyAdapter(IYieldPeer.Protocol.Compound, address(deploy.compoundV3));
        deploy.parentPeer.setInitialActiveStrategy(IYieldPeer.Protocol.Aave);

        vm.stopBroadcast();
    }
}
