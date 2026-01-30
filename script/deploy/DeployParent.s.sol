// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// --- Forge & HelperConfig --- //
import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
// --- Contracts --- //
import {Share} from "../../src/token/Share.sol";
import {SharePool} from "../../src/token/SharePool.sol";
import {ParentPeer} from "../../src/peers/ParentPeer.sol";
import {Rebalancer} from "../../src/modules/Rebalancer.sol";
import {StrategyRegistry} from "../../src/modules/StrategyRegistry.sol";
import {AaveV3Adapter} from "../../src/adapters/AaveV3Adapter.sol";
import {CompoundV3Adapter} from "../../src/adapters/CompoundV3Adapter.sol";
// --- Interfaces & Libraries --- //
import {ITokenAdminRegistry} from "@chainlink/contracts/src/v0.8/ccip/interfaces/ITokenAdminRegistry.sol";
import {
    RegistryModuleOwnerCustom
} from "@chainlink/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {IYieldPeer} from "../../src/interfaces/IYieldPeer.sol";
import {Roles} from "../../src/libraries/Roles.sol";
// --- Proxies --- //
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
        StrategyRegistry strategyRegistry; // strategy registry interfaced through proxy
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
        _configureSystem(deploy);

        vm.stopBroadcast();
    }

    /*//////////////////////////////////////////////////////////////
                          DEPLOYMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @dev Deploys the Share Token Impl, Share Proxy, and CCIP Pool
    /// @dev Registers Share & Pool with Chainlink Token Admin Registry
    function _deployShareInfra(DeploymentConfig memory deploy, HelperConfig.NetworkConfig memory networkConfig)
        private
    {
        // Deploy Implementation & Proxy
        Share shareImpl = new Share();
        deploy.shareImplAddr = address(shareImpl);

        bytes memory shareInitData = abi.encodeWithSelector(Share.initialize.selector);
        ShareProxy shareProxy = new ShareProxy(address(shareImpl), shareInitData);

        deploy.share = Share(address(shareProxy)); /// @dev wrap proxy with Share type

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
        Rebalancer rebalancerImpl = new Rebalancer();
        deploy.rebalancerImplAddr = address(rebalancerImpl);

        bytes memory rebalancerInitData = abi.encodeWithSelector(Rebalancer.initialize.selector);
        RebalancerProxy rebalancerProxy = new RebalancerProxy(address(rebalancerImpl), rebalancerInitData);

        deploy.rebalancer = Rebalancer(address(rebalancerProxy)); /// @dev wrap proxy with Rebalancer type
    }

    /// @dev Deploys the Parent Peer contract
    function _deployParentPeer(DeploymentConfig memory deploy, HelperConfig.NetworkConfig memory networkConfig)
        private
    {
        ParentPeer parentPeerImpl = new ParentPeer(
            networkConfig.ccip.ccipRouter,
            networkConfig.tokens.link,
            networkConfig.ccip.thisChainSelector,
            networkConfig.tokens.usdc,
            address(deploy.share)
        );
        deploy.parentPeerImplAddr = address(parentPeerImpl);

        bytes memory parentInitData = abi.encodeWithSelector(ParentPeer.initialize.selector);
        ParentProxy parentProxy = new ParentProxy(address(parentPeerImpl), parentInitData);

        deploy.parentPeer = ParentPeer(address(parentProxy)); /// @dev wrap proxy with ParentPeer type
    }

    /// @dev Deploys the Strategy Registry module
    function _deployStrategyRegistry(DeploymentConfig memory deploy) private {
        StrategyRegistry strategyRegistryImpl = new StrategyRegistry();
        deploy.strategyRegistryImplAddr = address(strategyRegistryImpl);

        bytes memory strategyRegistryInitData = abi.encodeWithSelector(StrategyRegistry.initialize.selector);
        StrategyRegistryProxy strategyRegistryProxy =
            new StrategyRegistryProxy(address(strategyRegistryImpl), strategyRegistryInitData);

        deploy.strategyRegistry = StrategyRegistry(address(strategyRegistryProxy)); /// @dev wrap proxy with StrategyRegistry type
    }

    /// @dev Deploys strategy registries and registers adapters
    function _deployAdapters(DeploymentConfig memory deploy, HelperConfig.NetworkConfig memory networkConfig) private {
        // Deploy Adapters
        deploy.aaveV3Adapter =
            new AaveV3Adapter(address(deploy.parentPeer), networkConfig.protocols.aavePoolAddressesProvider);

        deploy.compoundV3Adapter = new CompoundV3Adapter(address(deploy.parentPeer), networkConfig.protocols.comet);

        // Register Adapters in Registry
        deploy.strategyRegistry
            .setStrategyAdapter(keccak256(abi.encodePacked("aave-v3")), address(deploy.aaveV3Adapter));

        deploy.strategyRegistry
            .setStrategyAdapter(keccak256(abi.encodePacked("compound-v3")), address(deploy.compoundV3Adapter));
    }

    /*//////////////////////////////////////////////////////////////
                        CONFIGURATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @dev Configs system together (Roles, Links, Initial Strategy)
    /// @dev Requires all contracts to be deployed first
    function _configureSystem(DeploymentConfig memory deploy) private {
        /// @dev Grant Share BnM Roles to Pool & Peer
        deploy.share.grantMintAndBurnRoles(address(deploy.sharePool));
        deploy.share.grantMintAndBurnRoles(address(deploy.parentPeer));

        /// @dev Grant Temp Config Admin Role to deployer/owner (to allow config setting)
        deploy.parentPeer.grantRole(Roles.CONFIG_ADMIN_ROLE, deploy.parentPeer.owner());

        /// @dev Link ParentPeer & Rebalancer
        deploy.rebalancer.setParentPeer(address(deploy.parentPeer));
        deploy.parentPeer.setRebalancer(address(deploy.rebalancer));

        /// @dev Link Registry to ParentPeer & Rebalancer
        deploy.parentPeer.setStrategyRegistry(address(deploy.strategyRegistry));
        deploy.rebalancer.setStrategyRegistry(address(deploy.strategyRegistry));

        /// @dev Set Initial Active Strategy on ParentPeer
        deploy.parentPeer.setInitialActiveStrategy(keccak256(abi.encodePacked("aave-v3")));

        /// @dev Cleanup (Revoke Temp Admin)
        deploy.parentPeer.revokeRole(Roles.CONFIG_ADMIN_ROLE, deploy.parentPeer.owner());
    }
}
