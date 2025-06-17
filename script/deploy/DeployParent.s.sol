// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ParentCLF} from "../../src/peers/extensions/ParentCLF.sol";
// import {ParentCLA} from "../../src/peers/extensions/ParentCLA.sol";
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

contract DeployParent is Script {
    /*//////////////////////////////////////////////////////////////
                                  RUN
    //////////////////////////////////////////////////////////////*/
    function run() public returns (Share, SharePool, ParentCLF, HelperConfig, uint64) {
        HelperConfig config = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = config.getActiveNetworkConfig();

        vm.startBroadcast();
        // Unit tests:
        // @review: move this to unit test
        uint64 clfSubId = IFunctionsSubscriptions(networkConfig.clf.functionsRouter).createSubscription();
        // Deployment:
        // uint64 clfSubId = networkConfig.clf.clfSubId;

        Share share = new Share();
        SharePool sharePool = new SharePool(address(share), networkConfig.ccip.rmnProxy, networkConfig.ccip.ccipRouter);
        RegistryModuleOwnerCustom(networkConfig.ccip.registryModuleOwnerCustom).registerAdminViaOwner(address(share));
        ITokenAdminRegistry(networkConfig.ccip.tokenAdminRegistry).acceptAdminRole(address(share));
        ITokenAdminRegistry(networkConfig.ccip.tokenAdminRegistry).setPool(address(share), address(sharePool));

        ParentCLF parentPeer = new ParentCLF(
            networkConfig.ccip.ccipRouter,
            networkConfig.tokens.link,
            networkConfig.ccip.thisChainSelector,
            networkConfig.tokens.usdc,
            networkConfig.protocols.aavePoolAddressesProvider,
            networkConfig.protocols.comet,
            address(share),
            networkConfig.clf.functionsRouter,
            networkConfig.clf.donId,
            clfSubId
        );

        share.grantMintAndBurnRoles(address(sharePool));
        share.grantMintAndBurnRoles(address(parentPeer));

        vm.stopBroadcast();

        return (share, sharePool, parentPeer, config, clfSubId);
    }
}
