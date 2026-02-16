// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {ITokenAdminRegistry} from "@chainlink/contracts/src/v0.8/ccip/interfaces/ITokenAdminRegistry.sol";
import {
    RegistryModuleOwnerCustom
} from "@chainlink/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {IYieldPeer} from "../../src/interfaces/IYieldPeer.sol";
import {Roles} from "../../src/libraries/Roles.sol";
import {Share} from "../../src/token/Share.sol";
import {SharePool} from "../../src/token/SharePool.sol";
import {ChildPeer} from "../../src/peers/ChildPeer.sol";
import {StrategyRegistry} from "../../src/modules/StrategyRegistry.sol";
import {AaveV3Adapter} from "../../src/adapters/AaveV3Adapter.sol";
import {CompoundV3Adapter} from "../../src/adapters/CompoundV3Adapter.sol";
import {ShareProxy} from "../../src/proxies/ShareProxy.sol";
import {ChildProxy} from "../../src/proxies/ChildProxy.sol";
import {StrategyRegistryProxy} from "../../src/proxies/StrategyRegistryProxy.sol";

/// @title DeployChild
/// @notice Deployment script for the Child architecture
/// @dev Deploys Share, Pool, ChildPeer, Registry, and Adapters, then configs them together.
contract DeployChild is Script {
    /// @dev Struct to hold deployed contracts and Impl addresses for testing
    struct ChildDeploymentConfig {
        // Contract Types that are interfaced through their Proxies
        Share share;
        SharePool sharePool;
        ChildPeer childPeer;
        StrategyRegistry strategyRegistry;
        // Adapter contracts
        AaveV3Adapter aaveV3Adapter;
        CompoundV3Adapter compoundV3Adapter;
        // Implementation addresses for testing
        address shareImplAddr;
        address childPeerImplAddr;
        address strategyRegistryImplAddr;
        // Config
        HelperConfig config;
    }

    /*//////////////////////////////////////////////////////////////
                                  RUN
    //////////////////////////////////////////////////////////////*/
    function run() public returns (ChildDeploymentConfig memory deploy) {
        // Setup - create HelperConfig and get network config
        deploy.config = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = deploy.config.getActiveNetworkConfig();

        vm.startBroadcast();

        // Deployment & Configuration
        _deployShareInfra(deploy, networkConfig); /// @dev BnM role granted to Pool
        _deployChildPeer(deploy, networkConfig); /// @dev BnM role granted to ChildPeer
        _deployStrategyRegistry(deploy); /// @dev Registry set on ChildPeer
        _deployStrategyAdapters(deploy, networkConfig); /// @dev Adapters set in Registry

        vm.stopBroadcast();
    }

    /*//////////////////////////////////////////////////////////////
                               DEPLOYMENT
    //////////////////////////////////////////////////////////////*/
    /// @dev Deploys the Share Token Impl, Share Proxy, and CCIP Pool
    /// @dev Registers Share & Pool with Chainlink Token Admin Registry
    function _deployShareInfra(ChildDeploymentConfig memory deploy, HelperConfig.NetworkConfig memory networkConfig)
        private
    {
        // Deploy Share Impl and cache address for testing
        Share shareImpl = new Share();
        deploy.shareImplAddr = address(shareImpl);

        // Create Share Proxy init data and deploy Proxy
        bytes memory shareInitData = abi.encodeWithSelector(Share.initialize.selector);
        ShareProxy shareProxy = new ShareProxy(address(shareImpl), shareInitData);

        // Cast Proxy address to Share type
        deploy.share = Share(address(shareProxy));

        // Deploy CCIP Pool
        deploy.sharePool =
            new SharePool(address(deploy.share), networkConfig.ccip.rmnProxy, networkConfig.ccip.ccipRouter);

        // Register Share & Pool with Chainlink Token Admin Registry
        RegistryModuleOwnerCustom(networkConfig.ccip.registryModuleOwnerCustom)
            .registerAdminViaOwner(address(deploy.share));

        ITokenAdminRegistry(networkConfig.ccip.tokenAdminRegistry).acceptAdminRole(address(deploy.share));

        ITokenAdminRegistry(networkConfig.ccip.tokenAdminRegistry)
            .setPool(address(deploy.share), address(deploy.sharePool));

        // Grant Share BnM role to Share Pool
        deploy.share.grantMintAndBurnRoles(address(deploy.sharePool));
    }

    /// @dev Deploys the Child Peer contract Impl and Proxy
    function _deployChildPeer(ChildDeploymentConfig memory deploy, HelperConfig.NetworkConfig memory networkConfig)
        private
    {
        // Deploy ChildPeer Impl and cache address for testing
        ChildPeer childPeerImpl = new ChildPeer(
            networkConfig.ccip.ccipRouter,
            networkConfig.tokens.link,
            networkConfig.ccip.thisChainSelector,
            networkConfig.tokens.usdc,
            address(deploy.share),
            networkConfig.ccip.parentChainSelector
        );
        deploy.childPeerImplAddr = address(childPeerImpl);

        // Create ChildPeer Proxy init data and deploy Proxy
        bytes memory childInitData = abi.encodeWithSelector(ChildPeer.initialize.selector);
        ChildProxy childProxy = new ChildProxy(address(childPeerImpl), childInitData);

        // Cast Proxy address to ChildPeer type
        deploy.childPeer = ChildPeer(address(childProxy));

        // Grant Share BnM role to Child Peer
        deploy.share.grantMintAndBurnRoles(address(deploy.childPeer));
    }

    /// @dev Deploys the Strategy Registry Impl and Proxy
    function _deployStrategyRegistry(ChildDeploymentConfig memory deploy) private {
        // Deploy Strategy Registry Impl and cache address for testing
        StrategyRegistry strategyRegistryImpl = new StrategyRegistry();
        deploy.strategyRegistryImplAddr = address(strategyRegistryImpl);

        // Create Strategy Registry Proxy init data and deploy Proxy
        bytes memory strategyRegistryInitData = abi.encodeWithSelector(StrategyRegistry.initialize.selector);
        StrategyRegistryProxy strategyRegistryProxy =
            new StrategyRegistryProxy(address(strategyRegistryImpl), strategyRegistryInitData);

        // Cast Proxy address to StrategyRegistry type
        deploy.strategyRegistry = StrategyRegistry(address(strategyRegistryProxy));

        // Set deployed StrategyRegistry on ChildPeer
        /// @dev Temp role granted/revoked after
        deploy.childPeer.grantRole(Roles.CONFIG_ADMIN_ROLE, deploy.childPeer.owner());
        deploy.childPeer.setStrategyRegistry(address(deploy.strategyRegistry));
        deploy.childPeer.revokeRole(Roles.CONFIG_ADMIN_ROLE, deploy.childPeer.owner());
    }

    /// @dev Deploys adapters and registers them (Child adapters point to ChildPeer)
    function _deployStrategyAdapters(
        ChildDeploymentConfig memory deploy,
        HelperConfig.NetworkConfig memory networkConfig
    ) private {
        // Deploy Strategy Adapters
        deploy.aaveV3Adapter =
            new AaveV3Adapter(address(deploy.childPeer), networkConfig.protocols.aavePoolAddressesProvider);

        deploy.compoundV3Adapter = new CompoundV3Adapter(address(deploy.childPeer), networkConfig.protocols.comet);

        // Set Adapters in Registry
        deploy.strategyRegistry
            .setStrategyAdapter(keccak256(abi.encodePacked("aave-v3")), address(deploy.aaveV3Adapter));

        deploy.strategyRegistry
            .setStrategyAdapter(keccak256(abi.encodePacked("compound-v3")), address(deploy.compoundV3Adapter));
    }
}
