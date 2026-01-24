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
import {Roles} from "../../src/libraries/Roles.sol";
import {ChildProxy} from "../../src/proxies/ChildProxy.sol";

contract DeployChild is Script {
    struct ChildDeploymentConfig {
        Share share;
        SharePool sharePool;
        ChildPeer childPeer; // child peer is interfaced through proxy
        address childPeerImpl;
        HelperConfig config;
        StrategyRegistry strategyRegistry;
        AaveV3Adapter aaveV3Adapter;
        CompoundV3Adapter compoundV3Adapter;
    }

    /*//////////////////////////////////////////////////////////////
                                  RUN
    //////////////////////////////////////////////////////////////*/
    function run() public returns (ChildDeploymentConfig memory deploy) {
        deploy.config = new HelperConfig();

        vm.startBroadcast();
        HelperConfig.NetworkConfig memory networkConfig = deploy.config.getActiveNetworkConfig();

        deploy.share = new Share();
        deploy.sharePool =
            new SharePool(address(deploy.share), networkConfig.ccip.rmnProxy, networkConfig.ccip.ccipRouter);

        RegistryModuleOwnerCustom(networkConfig.ccip.registryModuleOwnerCustom)
            .registerAdminViaOwner(address(deploy.share));
        ITokenAdminRegistry(networkConfig.ccip.tokenAdminRegistry).acceptAdminRole(address(deploy.share));
        ITokenAdminRegistry(networkConfig.ccip.tokenAdminRegistry)
            .setPool(address(deploy.share), address(deploy.sharePool));

        // 1 - deploy child impl
        ChildPeer childPeerImpl = new ChildPeer(
            networkConfig.ccip.ccipRouter,
            networkConfig.tokens.link,
            networkConfig.ccip.thisChainSelector,
            networkConfig.tokens.usdc,
            address(deploy.share),
            networkConfig.ccip.parentChainSelector
        );

        // 2 - make init data
        bytes memory childInitData = abi.encodeWithSelector(ChildPeer.initialize.selector, tx.origin);
        /// @dev tx.origin is used to send the "deployer" into intialize and set owner

        // 3 - deploy child proxy
        ChildProxy childProxy = new ChildProxy(address(childPeerImpl), childInitData);

        // 4 - set child peer interfaced through proxy
        deploy.childPeer = ChildPeer(address(childProxy));

        deploy.childPeerImpl = address(childPeerImpl);

        deploy.share.grantMintAndBurnRoles(address(deploy.sharePool));
        deploy.share.grantMintAndBurnRoles(address(deploy.childPeer));

        deploy.strategyRegistry = new StrategyRegistry();
        deploy.aaveV3Adapter =
            new AaveV3Adapter(address(deploy.childPeer), networkConfig.protocols.aavePoolAddressesProvider);
        deploy.compoundV3Adapter = new CompoundV3Adapter(address(deploy.childPeer), networkConfig.protocols.comet);
        deploy.strategyRegistry
            .setStrategyAdapter(keccak256(abi.encodePacked("aave-v3")), address(deploy.aaveV3Adapter));
        deploy.strategyRegistry
            .setStrategyAdapter(keccak256(abi.encodePacked("compound-v3")), address(deploy.compoundV3Adapter));
        /// @dev config admin role granted (then revoked) to deployer/'owner' to set strategy registry
        deploy.childPeer.grantRole(Roles.CONFIG_ADMIN_ROLE, deploy.childPeer.owner());
        deploy.childPeer.setStrategyRegistry(address(deploy.strategyRegistry));
        deploy.childPeer.revokeRole(Roles.CONFIG_ADMIN_ROLE, deploy.childPeer.owner());

        vm.stopBroadcast();
    }
}
