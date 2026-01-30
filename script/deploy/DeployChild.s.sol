// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// --- Forge & HelperConfig --- //
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
// --- Contracts --- //
import {Share} from "../../src/token/Share.sol";
import {SharePool} from "../../src/token/SharePool.sol";
import {ChildPeer} from "../../src/peers/ChildPeer.sol";
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
import {ChildProxy} from "../../src/proxies/ChildProxy.sol";
import {StrategyRegistryProxy} from "../../src/proxies/StrategyRegistryProxy.sol";

/// @title DeployChild
/// @notice Deployment script for the Child architecture
/// @dev Deploys Share, Pool, ChildPeer, Registry, and Adapters, then configs them together.
contract DeployChild is Script {
    /// @dev Struct to hold deployed contracts and impl addresses for testing
    struct ChildDeploymentConfig {
        // Contract Types that will be interfaced through their proxies
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
        // 1. Setup
        deploy.config = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = deploy.config.getActiveNetworkConfig();

        vm.startBroadcast();

        // 2. Deployment
        _deployShareInfra(deploy, networkConfig);
        _deployChildPeer(deploy, networkConfig);
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
    function _deployShareInfra(ChildDeploymentConfig memory deploy, HelperConfig.NetworkConfig memory networkConfig)
        private
    {
        // Deploy Implementation & Proxy
        Share shareImpl = new Share();
        deploy.shareImplAddr = address(shareImpl);

        bytes memory shareInitData = abi.encodeWithSelector(Share.initialize.selector);
        ShareProxy shareProxy = new ShareProxy(address(shareImpl), shareInitData);

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

    /// @dev Deploys the Child Peer contract
    function _deployChildPeer(ChildDeploymentConfig memory deploy, HelperConfig.NetworkConfig memory networkConfig)
        private
    {
        ChildPeer childPeerImpl = new ChildPeer(
            networkConfig.ccip.ccipRouter,
            networkConfig.tokens.link,
            networkConfig.ccip.thisChainSelector,
            networkConfig.tokens.usdc,
            address(deploy.share),
            networkConfig.ccip.parentChainSelector
        );
        deploy.childPeerImplAddr = address(childPeerImpl);

        bytes memory childInitData = abi.encodeWithSelector(ChildPeer.initialize.selector);
        ChildProxy childProxy = new ChildProxy(address(childPeerImpl), childInitData);

        deploy.childPeer = ChildPeer(address(childProxy));
    }

    /// @dev Deploys the Strategy Registry module
    function _deployStrategyRegistry(ChildDeploymentConfig memory deploy) private {
        StrategyRegistry strategyRegistryImpl = new StrategyRegistry();
        deploy.strategyRegistryImplAddr = address(strategyRegistryImpl);

        bytes memory strategyRegistryInitData = abi.encodeWithSelector(StrategyRegistry.initialize.selector);
        StrategyRegistryProxy strategyRegistryProxy =
            new StrategyRegistryProxy(address(strategyRegistryImpl), strategyRegistryInitData);

        deploy.strategyRegistry = StrategyRegistry(address(strategyRegistryProxy));
    }

    /// @dev Deploys adapters and registers them (Child adapters point to ChildPeer)
    function _deployAdapters(ChildDeploymentConfig memory deploy, HelperConfig.NetworkConfig memory networkConfig)
        private
    {
        deploy.aaveV3Adapter =
            new AaveV3Adapter(address(deploy.childPeer), networkConfig.protocols.aavePoolAddressesProvider);

        deploy.compoundV3Adapter = new CompoundV3Adapter(address(deploy.childPeer), networkConfig.protocols.comet);

        deploy.strategyRegistry
            .setStrategyAdapter(keccak256(abi.encodePacked("aave-v3")), address(deploy.aaveV3Adapter));

        deploy.strategyRegistry
            .setStrategyAdapter(keccak256(abi.encodePacked("compound-v3")), address(deploy.compoundV3Adapter));
    }

    /*//////////////////////////////////////////////////////////////
                        CONFIGURATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @dev Configs system together (Roles, Links)
    function _configureSystem(ChildDeploymentConfig memory deploy) private {
        /// @dev Grant Share BnM Roles to Pool & Peer
        deploy.share.grantMintAndBurnRoles(address(deploy.sharePool));
        deploy.share.grantMintAndBurnRoles(address(deploy.childPeer));

        /// @dev Grant Temp Config Admin Role to deployer/owner
        deploy.childPeer.grantRole(Roles.CONFIG_ADMIN_ROLE, deploy.childPeer.owner());

        /// @dev Link Registry to ChildPeer
        deploy.childPeer.setStrategyRegistry(address(deploy.strategyRegistry));

        /// @dev Cleanup (Revoke Temp Admin)
        deploy.childPeer.revokeRole(Roles.CONFIG_ADMIN_ROLE, deploy.childPeer.owner());
    }
}
