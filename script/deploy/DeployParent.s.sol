// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ITokenAdminRegistry} from "@chainlink/contracts/src/v0.8/ccip/interfaces/ITokenAdminRegistry.sol";
import {
    RegistryModuleOwnerCustom
} from "@chainlink/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {IYieldPeer} from "../../src/interfaces/IYieldPeer.sol";
import {Roles} from "../../src/libraries/Roles.sol";
import {Share} from "../../src/token/Share.sol";
import {SharePool} from "../../src/token/SharePool.sol";
import {ParentPeer} from "../../src/peers/ParentPeer.sol";
import {Rebalancer} from "../../src/modules/Rebalancer.sol";
import {StrategyRegistry} from "../../src/modules/StrategyRegistry.sol";
import {AaveV3Adapter} from "../../src/adapters/AaveV3Adapter.sol";
import {CompoundV3Adapter} from "../../src/adapters/CompoundV3Adapter.sol";
import {ShareProxy} from "../../src/proxies/ShareProxy.sol";
import {ParentProxy} from "../../src/proxies/ParentProxy.sol";
import {RebalancerProxy} from "../../src/proxies/RebalancerProxy.sol";
import {StrategyRegistryProxy} from "../../src/proxies/StrategyRegistryProxy.sol";

/// @title DeployParent
/// @notice Deployment script for the Parent architecture
/// @dev Deploys Share, Pool, Peer, Rebalancer, Registry, and Adapters, then configs them together.
contract DeployParent is Script {
    /// @dev Struct to hold deployed contracts and impl addresses for testing
    struct DeploymentConfig {
        // Contract Types that will be interfaced through their proxies
        Share share;
        SharePool sharePool;
        ParentPeer parentPeer;
        Rebalancer rebalancer;
        StrategyRegistry strategyRegistry;
        // Adapter contracts
        AaveV3Adapter aaveV3Adapter;
        CompoundV3Adapter compoundV3Adapter;
        // Implementation addresses for testing
        address shareImplAddr;
        address rebalancerImplAddr;
        address parentPeerImplAddr;
        address strategyRegistryImplAddr;
        // Config
        HelperConfig config;
    }

    /*//////////////////////////////////////////////////////////////
                                  RUN
    //////////////////////////////////////////////////////////////*/
    function run() public returns (DeploymentConfig memory deploy) {
        // 1. Setup
        deploy.config = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = deploy.config.getActiveNetworkConfig();

        vm.startBroadcast();

        // 2. Deployment
        _deployShareInfra(deploy, networkConfig);
        _deployRebalancer(deploy);
        _deployParentPeer(deploy, networkConfig);
        _deployStrategyRegistry(deploy);
        _deployAdapters(deploy, networkConfig);

        // 3. Configuration
        _setConfigs(deploy);

        vm.stopBroadcast();
    }

    /*//////////////////////////////////////////////////////////////
                               DEPLOYMENT
    //////////////////////////////////////////////////////////////*/
    /// @dev Deploys the Share Token Impl, Proxy and CCIP Pool
    /// @dev Registers Share & Pool with Chainlink Token Admin Registry
    function _deployShareInfra(DeploymentConfig memory deploy, HelperConfig.NetworkConfig memory networkConfig)
        private
    {
        // Deploy Share impl and store address for testing
        Share shareImpl = new Share();
        deploy.shareImplAddr = address(shareImpl);

        // Create Share Proxy init data and deploy proxy
        bytes memory shareInitData = abi.encodeWithSelector(Share.initialize.selector);
        ShareProxy shareProxy = new ShareProxy(address(shareImpl), shareInitData);

        // Cast proxy address to Share type
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
    }

    /// @dev Deploys the Rebalancer Impl and Proxy
    function _deployRebalancer(DeploymentConfig memory deploy) private {
        // Deploy Rebalancer impl and store address for testing
        Rebalancer rebalancerImpl = new Rebalancer();
        deploy.rebalancerImplAddr = address(rebalancerImpl);

        // Create Rebalancer Proxy init data and deploy proxy
        bytes memory rebalancerInitData = abi.encodeWithSelector(Rebalancer.initialize.selector);
        RebalancerProxy rebalancerProxy = new RebalancerProxy(address(rebalancerImpl), rebalancerInitData);

        // Cast proxy address to Rebalancer type
        deploy.rebalancer = Rebalancer(address(rebalancerProxy));
    }

    /// @dev Deploys the Parent Peer Impl and Proxy
    function _deployParentPeer(DeploymentConfig memory deploy, HelperConfig.NetworkConfig memory networkConfig)
        private
    {
        // Deploy ParentPeer impl and store address for testing
        ParentPeer parentPeerImpl = new ParentPeer(
            networkConfig.ccip.ccipRouter,
            networkConfig.tokens.link,
            networkConfig.ccip.thisChainSelector,
            networkConfig.tokens.usdc,
            address(deploy.share)
        );
        deploy.parentPeerImplAddr = address(parentPeerImpl);

        // Create ParentPeer Proxy init data and deploy proxy
        bytes memory parentInitData = abi.encodeWithSelector(ParentPeer.initialize.selector);
        ParentProxy parentProxy = new ParentProxy(address(parentPeerImpl), parentInitData);

        // Cast proxy address to ParentPeer type
        deploy.parentPeer = ParentPeer(address(parentProxy));
    }

    /// @dev Deploys the Strategy Registry module Impl and Proxy
    function _deployStrategyRegistry(DeploymentConfig memory deploy) private {
        // Deploy Strategy Registry impl and store address for testing
        StrategyRegistry strategyRegistryImpl = new StrategyRegistry();
        deploy.strategyRegistryImplAddr = address(strategyRegistryImpl);

        // Create Strategy Registry Proxy init data and deploy proxy
        bytes memory strategyRegistryInitData = abi.encodeWithSelector(StrategyRegistry.initialize.selector);
        StrategyRegistryProxy strategyRegistryProxy =
            new StrategyRegistryProxy(address(strategyRegistryImpl), strategyRegistryInitData);

        // Cast proxy address to StrategyRegistry type
        deploy.strategyRegistry = StrategyRegistry(address(strategyRegistryProxy));
    }

    /// @dev Deploys strategy registries and registers adapters
    function _deployAdapters(DeploymentConfig memory deploy, HelperConfig.NetworkConfig memory networkConfig) private {
        // Deploy Adapters
        deploy.aaveV3Adapter =
            new AaveV3Adapter(address(deploy.parentPeer), networkConfig.protocols.aavePoolAddressesProvider);

        deploy.compoundV3Adapter = new CompoundV3Adapter(address(deploy.parentPeer), networkConfig.protocols.comet);

        // Set Adapters in Registry
        deploy.strategyRegistry
            .setStrategyAdapter(keccak256(abi.encodePacked("aave-v3")), address(deploy.aaveV3Adapter));

        deploy.strategyRegistry
            .setStrategyAdapter(keccak256(abi.encodePacked("compound-v3")), address(deploy.compoundV3Adapter));
    }

    /*//////////////////////////////////////////////////////////////
                             CONFIGURATION
    //////////////////////////////////////////////////////////////*/
    /// @dev Configs system together (Roles, Links, Initial Strategy)
    /// @dev Requires all contracts to be deployed first
    function _setConfigs(DeploymentConfig memory deploy) private {
        // Grant Share BnM Roles to Pool & Peer
        deploy.share.grantMintAndBurnRoles(address(deploy.sharePool));
        deploy.share.grantMintAndBurnRoles(address(deploy.parentPeer));

        // Grant Temp Config Admin Role to deployer/owner (to allow config setting)
        deploy.parentPeer.grantRole(Roles.CONFIG_ADMIN_ROLE, deploy.parentPeer.owner());

        // Link ParentPeer & Rebalancer
        deploy.rebalancer.setParentPeer(address(deploy.parentPeer));
        deploy.parentPeer.setRebalancer(address(deploy.rebalancer));

        // Link Strategy Registry to ParentPeer & Rebalancer
        deploy.parentPeer.setStrategyRegistry(address(deploy.strategyRegistry));
        deploy.rebalancer.setStrategyRegistry(address(deploy.strategyRegistry));

        // Set Initial Active Strategy on ParentPeer
        deploy.parentPeer.setInitialActiveStrategy(keccak256(abi.encodePacked("aave-v3")));

        // Cleanup (Revoke Temp Config Admin)
        deploy.parentPeer.revokeRole(Roles.CONFIG_ADMIN_ROLE, deploy.parentPeer.owner());
    }
}
