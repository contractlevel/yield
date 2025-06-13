// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {ChildPeer} from "../../src/peers/ChildPeer.sol";
import {Share} from "../../src/token/Share.sol";
import {SharePool} from "../../src/token/SharePool.sol";
import {ITokenAdminRegistry} from "@chainlink/contracts/src/v0.8/ccip/interfaces/ITokenAdminRegistry.sol";
import {RegistryModuleOwnerCustom} from
    "@chainlink/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";

contract DeployChild is Script {
    /*//////////////////////////////////////////////////////////////
                                  RUN
    //////////////////////////////////////////////////////////////*/
    function run() public returns (Share, SharePool, ChildPeer, HelperConfig) {
        HelperConfig config = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = config.getActiveNetworkConfig();

        vm.startBroadcast();
        Share share = new Share();
        SharePool sharePool = new SharePool(address(share), networkConfig.ccip.rmnProxy, networkConfig.ccip.ccipRouter);
        RegistryModuleOwnerCustom(networkConfig.ccip.registryModuleOwnerCustom).registerAdminViaOwner(address(share));
        ITokenAdminRegistry(networkConfig.ccip.tokenAdminRegistry).acceptAdminRole(address(share));
        ITokenAdminRegistry(networkConfig.ccip.tokenAdminRegistry).setPool(address(share), address(sharePool));

        ChildPeer childPeer = new ChildPeer(
            networkConfig.ccip.ccipRouter,
            networkConfig.tokens.link,
            networkConfig.ccip.thisChainSelector,
            networkConfig.tokens.usdc,
            networkConfig.protocols.aavePoolAddressesProvider,
            networkConfig.protocols.comet,
            address(share),
            networkConfig.ccip.parentChainSelector
        );
        share.grantMintAndBurnRoles(address(sharePool));
        share.grantMintAndBurnRoles(address(childPeer));

        vm.stopBroadcast();

        return (share, sharePool, childPeer, config);
    }
}
