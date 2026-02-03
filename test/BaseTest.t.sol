// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console2, Vm} from "forge-std/Test.sol";

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";

import {DeployParent, HelperConfig, ParentPeer, Rebalancer} from "../script/deploy/DeployParent.s.sol";
import {DeployChild, ChildPeer} from "../script/deploy/DeployChild.s.sol";
import {Share} from "../src/token/Share.sol";
import {SharePool} from "../src/token/SharePool.sol";
import {RateLimiter} from "@chainlink/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";
import {TokenPool} from "@chainlink/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {IPoolAddressesProvider} from "@aave/v3-origin/src/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "@aave/v3-origin/src/contracts/interfaces/IPool.sol";
import {DataTypes} from "@aave/v3-origin/src/contracts/protocol/libraries/types/DataTypes.sol";
import {USDCTokenPool} from "@chainlink/contracts/src/v0.8/ccip/pools/USDC/USDCTokenPool.sol";

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IMessageTransmitter} from "../src/interfaces/IMessageTransmitter.sol";
import {IYieldPeer} from "../src/interfaces/IYieldPeer.sol";
import {IComet} from "../src/interfaces/IComet.sol";
import {AaveV3Adapter} from "../src/adapters/AaveV3Adapter.sol";
import {CompoundV3Adapter} from "../src/adapters/CompoundV3Adapter.sol";
import {StrategyRegistry} from "../src/modules/StrategyRegistry.sol";
import {Roles} from "../src/libraries/Roles.sol";

import {CREReceiver} from "../src/modules/CREReceiver.sol";
import {WorkflowHelpers} from "./helpers/WorkflowHelpers.sol";

contract BaseTest is Test {
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 internal constant DEPOSIT_AMOUNT = 1_000_000_000; // 1000 USDC
    uint256 internal constant INITIAL_SHARE_PRECISION = 1e18 / 1e6;
    uint256 internal constant BALANCE_TOLERANCE = 4; // Allow 4 wei difference
    uint256 internal constant INITIAL_FEE_RATE = 10_000; // 1%
    uint256 internal constant LINK_AMOUNT = 1_000 * 1e18; // 1000 LINK
    uint256 internal constant INITIAL_CCIP_GAS_LIMIT = 500_000;

    // EIP-1967 implementation slot for proxies
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    // --- Fork IDs & Blocks --- //
    uint256 internal baseFork;
    uint256 internal constant BASE_MAINNET_CHAIN_ID = 8453;
    uint256 internal constant BASE_MAINNET_BLOCK_NUMBER = 38045674;

    uint256 internal optFork;
    uint256 internal constant OPTIMISM_MAINNET_CHAIN_ID = 10;
    uint256 internal constant OPTIMISM_MAINNET_BLOCK_NUMBER = 143640972;

    uint256 internal ethFork;
    uint256 internal constant ETHEREUM_MAINNET_CHAIN_ID = 1;
    uint256 internal constant ETHEREUM_MAINNET_BLOCK_NUMBER = 23777365;

    CCIPLocalSimulatorFork internal ccipLocalSimulatorFork;

    // --- Base Chain (Parent) --- //
    Share internal baseShare;
    address internal baseShareImplAddr;
    SharePool internal baseSharePool;
    ParentPeer internal baseParentPeer;
    address internal baseParentPeerImplAddr;
    Rebalancer internal baseRebalancer;
    address internal baseRebalancerImplAddr;
    HelperConfig internal baseConfig;
    HelperConfig.NetworkConfig internal baseNetworkConfig;
    uint64 internal baseChainSelector;
    ERC20 internal baseUsdc;
    USDCTokenPool internal baseUsdcTokenPool;
    IMessageTransmitter internal baseCCTPMessageTransmitter;
    StrategyRegistry internal baseStrategyRegistry;
    address internal baseStrategyRegistryImplAddr;
    AaveV3Adapter internal baseAaveV3Adapter;
    CompoundV3Adapter internal baseCompoundV3Adapter;

    // --- Optimism Chain (Child 1) --- //
    Share internal optShare;
    address internal optShareImplAddr;
    SharePool internal optSharePool;
    ChildPeer internal optChildPeer;
    address internal optChildPeerImplAddr;
    HelperConfig internal optConfig;
    HelperConfig.NetworkConfig internal optNetworkConfig;
    uint64 internal optChainSelector;
    ERC20 internal optUsdc;
    USDCTokenPool internal optUsdcTokenPool;
    IMessageTransmitter internal optCCTPMessageTransmitter;
    StrategyRegistry internal optStrategyRegistry;
    address internal optStrategyRegistryImplAddr;
    AaveV3Adapter internal optAaveV3Adapter;
    CompoundV3Adapter internal optCompoundV3Adapter;

    // --- Ethereum Chain (Child 2) --- //
    Share internal ethShare;
    address internal ethShareImplAddr;
    SharePool internal ethSharePool;
    ChildPeer internal ethChildPeer;
    address internal ethChildPeerImplAddr;
    HelperConfig internal ethConfig;
    HelperConfig.NetworkConfig internal ethNetworkConfig;
    uint64 internal ethChainSelector;
    ERC20 internal ethUsdc;
    USDCTokenPool internal ethUsdcTokenPool;
    IMessageTransmitter internal ethCCTPMessageTransmitter;
    StrategyRegistry internal ethStrategyRegistry;
    address internal ethStrategyRegistryImplAddr;
    AaveV3Adapter internal ethAaveV3Adapter;
    CompoundV3Adapter internal ethCompoundV3Adapter;

    // --- Users & Roles --- //
    address internal owner = makeAddr("owner");
    address internal depositor = makeAddr("depositor");
    address internal withdrawer = makeAddr("withdrawer");
    address internal holder = makeAddr("holder");
    address internal keystoneForwarder = makeAddr("keystoneForwarder");

    // CCTP Actors
    address[] internal attesters = new address[](4);
    uint256[] internal attesterPks = new uint256[](4);

    // Custom Role Addresses
    address internal configAdmin = makeAddr("configAdmin");
    address internal crossChainAdmin = makeAddr("crossChainAdmin");
    address internal emergencyPauser = makeAddr("emergencyPauser");
    address internal emergencyUnpauser = makeAddr("emergencyUnpauser");
    address internal feeWithdrawer = makeAddr("feeWithdrawer");
    address internal feeRateSetter = makeAddr("feeRateSetter");

    // --- Workflow Metadata --- //
    address internal workflowOwner = makeAddr("workflowOwner");
    bytes32 internal workflowId = bytes32("rebalanceWorkflowId");
    string internal workflowNameRaw = "yieldcoin-rebalance-workflow";
    bytes10 internal workflowName = WorkflowHelpers.createWorkflowName(workflowNameRaw);
    bytes internal workflowMetadata = WorkflowHelpers.createWorkflowMetadata(workflowId, workflowName, workflowOwner);

    // --- Testing Flags --- //
    /// @dev Flag to indicate whether to perform cross-chain tests
    bool internal constant SET_CROSS_CHAIN = true;
    bool internal constant NO_CROSS_CHAIN = false;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/
    function setUp() public virtual {
        // 1. Deploy contracts on all forks
        _deployInfra();

        // 2. Setup Access Control
        _grantRoles();

        // 3. CCIP & CCTP Setup
        _setPools();
        _setCrossChainPeers();
        _setCCTPAttesters();
        _setDomains();

        // 4. Initial Funding & Workflow Config
        _dealLinkToPeers(false, address(0), address(0), address(0), address(0));
        _setForwarderAndWorkflow();

        /// @dev sanity check that we're ending BaseTest.setUp() on the Parent chain
        assertEq(block.chainid, BASE_MAINNET_CHAIN_ID);
        _stopPrank();
    }

    /// @dev Deploys Share/Pool, Rebalancer, ParentPeer, and StrategyRegistry on Base
    /// @dev Deploys Share/Pool, ChildPeer and StrategyRegistry on Optimism & Ethereum
    /// @dev Sets up CCIP Local Simulator Fork
    function _deployInfra() internal virtual {
        _deployBase();
        _deployOpt();
        _deployEth();

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));
        _registerChains();
    }

    /*//////////////////////////////////////////////////////////////
                          DEPLOYMENT HELPERS
    //////////////////////////////////////////////////////////////*/
    /// @dev _deployInfra:: Helper to deploy Share/Pool, Parent, Rebalancer and StrategyRegistry on Base
    function _deployBase() private {
        // Create Base fork
        baseFork = vm.createSelectFork(vm.envString("BASE_MAINNET_RPC_URL"), BASE_MAINNET_BLOCK_NUMBER);
        assertEq(block.chainid, BASE_MAINNET_CHAIN_ID);

        // Create & store Parent deployment config
        DeployParent baseDeployParent = new DeployParent();
        DeployParent.DeploymentConfig memory baseDeploy = baseDeployParent.run();

        // Store deployed contracts and impl addresses from deployment config
        baseShare = baseDeploy.share;
        baseShareImplAddr = baseDeploy.shareImplAddr;
        baseSharePool = baseDeploy.sharePool;
        baseParentPeer = baseDeploy.parentPeer;
        baseParentPeerImplAddr = baseDeploy.parentPeerImplAddr;
        baseRebalancer = baseDeploy.rebalancer;
        baseRebalancerImplAddr = baseDeploy.rebalancerImplAddr;
        baseConfig = baseDeploy.config;
        baseStrategyRegistry = baseDeploy.strategyRegistry;
        baseStrategyRegistryImplAddr = baseDeploy.strategyRegistryImplAddr;
        baseAaveV3Adapter = baseDeploy.aaveV3Adapter;
        baseCompoundV3Adapter = baseDeploy.compoundV3Adapter;

        // Persist
        vm.makePersistent(address(baseShare));
        vm.makePersistent(address(baseSharePool));
        vm.makePersistent(address(baseParentPeer));
        vm.makePersistent(address(baseRebalancer));
        vm.makePersistent(address(baseStrategyRegistry));
        vm.makePersistent(address(baseAaveV3Adapter));
        vm.makePersistent(address(baseCompoundV3Adapter));
        vm.makePersistent(baseShareImplAddr);
        vm.makePersistent(baseParentPeerImplAddr);
        vm.makePersistent(baseRebalancerImplAddr);
        vm.makePersistent(baseStrategyRegistryImplAddr);

        // Network Config
        baseNetworkConfig = baseConfig.getActiveNetworkConfig();
        baseChainSelector = baseNetworkConfig.ccip.thisChainSelector;
        baseUsdc = ERC20(baseNetworkConfig.tokens.usdc);
        baseUsdcTokenPool = USDCTokenPool(baseNetworkConfig.ccip.usdcTokenPool);
        baseCCTPMessageTransmitter = IMessageTransmitter(baseNetworkConfig.ccip.cctpMessageTransmitter);
    }

    /// @dev _deployInfra:: Helper to deploy Share/Pool, ChildPeer and StrategyRegistry on Optimism
    function _deployOpt() private {
        // Create Optimism fork
        optFork = vm.createSelectFork(vm.envString("OPTIMISM_MAINNET_RPC_URL"), OPTIMISM_MAINNET_BLOCK_NUMBER);
        assertEq(block.chainid, OPTIMISM_MAINNET_CHAIN_ID);

        // Create & store Child deployment config
        DeployChild optDeployChild = new DeployChild();
        DeployChild.ChildDeploymentConfig memory optDeploy = optDeployChild.run();

        // Store deployed contracts and impl addresses from deployment config
        optShare = optDeploy.share;
        optShareImplAddr = optDeploy.shareImplAddr;
        optSharePool = optDeploy.sharePool;
        optChildPeer = optDeploy.childPeer;
        optChildPeerImplAddr = optDeploy.childPeerImplAddr;
        optConfig = optDeploy.config;
        optStrategyRegistry = optDeploy.strategyRegistry;
        optStrategyRegistryImplAddr = optDeploy.strategyRegistryImplAddr;
        optAaveV3Adapter = optDeploy.aaveV3Adapter;
        optCompoundV3Adapter = optDeploy.compoundV3Adapter;

        // Persist
        vm.makePersistent(address(optShare));
        vm.makePersistent(address(optSharePool));
        vm.makePersistent(address(optChildPeer));
        vm.makePersistent(address(optStrategyRegistry));
        vm.makePersistent(address(optAaveV3Adapter));
        vm.makePersistent(address(optCompoundV3Adapter));
        vm.makePersistent(optShareImplAddr);
        vm.makePersistent(optChildPeerImplAddr);
        vm.makePersistent(optStrategyRegistryImplAddr);

        // Network Config
        optNetworkConfig = optConfig.getActiveNetworkConfig();
        optChainSelector = optNetworkConfig.ccip.thisChainSelector;
        optUsdc = ERC20(optNetworkConfig.tokens.usdc);
        optUsdcTokenPool = USDCTokenPool(optNetworkConfig.ccip.usdcTokenPool);
        optCCTPMessageTransmitter = IMessageTransmitter(optNetworkConfig.ccip.cctpMessageTransmitter);
    }

    /// @dev _deployInfra:: Helper to deploy Share/Pool, ChildPeer and StrategyRegistry on Ethereum
    function _deployEth() private {
        // Create Ethereum fork
        ethFork = vm.createSelectFork(vm.envString("ETH_MAINNET_RPC_URL"), ETHEREUM_MAINNET_BLOCK_NUMBER);
        assertEq(block.chainid, ETHEREUM_MAINNET_CHAIN_ID);

        // Create & store Child deployment config
        DeployChild ethDeployChild = new DeployChild();
        DeployChild.ChildDeploymentConfig memory ethDeploy = ethDeployChild.run();

        // Store deployed contracts and impl addresses from deployment config
        ethShare = ethDeploy.share;
        ethShareImplAddr = ethDeploy.shareImplAddr;
        ethSharePool = ethDeploy.sharePool;
        ethChildPeer = ethDeploy.childPeer;
        ethChildPeerImplAddr = ethDeploy.childPeerImplAddr;
        ethConfig = ethDeploy.config;
        ethStrategyRegistry = ethDeploy.strategyRegistry;
        ethStrategyRegistryImplAddr = ethDeploy.strategyRegistryImplAddr;
        ethAaveV3Adapter = ethDeploy.aaveV3Adapter;
        ethCompoundV3Adapter = ethDeploy.compoundV3Adapter;

        // Persist
        vm.makePersistent(address(ethShare));
        vm.makePersistent(address(ethSharePool));
        vm.makePersistent(address(ethChildPeer));
        vm.makePersistent(address(ethStrategyRegistry));
        vm.makePersistent(address(ethAaveV3Adapter));
        vm.makePersistent(address(ethCompoundV3Adapter));
        vm.makePersistent(ethShareImplAddr);
        vm.makePersistent(ethChildPeerImplAddr);
        vm.makePersistent(ethStrategyRegistryImplAddr);

        // Network Config
        ethNetworkConfig = ethConfig.getActiveNetworkConfig();
        ethChainSelector = ethNetworkConfig.ccip.thisChainSelector;
        ethUsdc = ERC20(ethNetworkConfig.tokens.usdc);
        ethUsdcTokenPool = USDCTokenPool(ethNetworkConfig.ccip.usdcTokenPool);
        ethCCTPMessageTransmitter = IMessageTransmitter(ethNetworkConfig.ccip.cctpMessageTransmitter);
    }

    /*//////////////////////////////////////////////////////////////
                        CONFIGURATION HELPERS
    //////////////////////////////////////////////////////////////*/
    /// @dev _deployInfra:: Helper to set up CCIP Local Simulator with all chains
    /// @dev Registers all chains in CCIP Local Simulator
    function _registerChains() internal {
        _registerChainInSimulator(OPTIMISM_MAINNET_CHAIN_ID, optNetworkConfig);
        _registerChainInSimulator(BASE_MAINNET_CHAIN_ID, baseNetworkConfig);
        _registerChainInSimulator(ETHEREUM_MAINNET_CHAIN_ID, ethNetworkConfig);
    }

    /// @dev _registerChains:: Helper to register a chain in the CCIP Local Simulator
    /// @param chainId The chain ID to register
    /// @param networkConfig The network config of the chain to register
    function _registerChainInSimulator(uint256 chainId, HelperConfig.NetworkConfig memory networkConfig) private {
        Register.NetworkDetails memory details = Register.NetworkDetails({
            chainSelector: networkConfig.ccip.thisChainSelector,
            routerAddress: networkConfig.ccip.ccipRouter,
            linkAddress: networkConfig.tokens.link,
            wrappedNativeAddress: address(0),
            ccipBnMAddress: address(0),
            ccipLnMAddress: address(0),
            rmnProxyAddress: address(0),
            registryModuleOwnerCustomAddress: address(0),
            tokenAdminRegistryAddress: address(0)
        });
        ccipLocalSimulatorFork.setNetworkDetails(chainId, details);
    }

    /// @dev Grants custom roles on all chains to predefined addresses
    function _grantRoles() internal virtual {
        _grantRolesForPeer(baseFork, baseParentPeer, baseParentPeer.owner());
        _grantRolesForPeer(optFork, optChildPeer, optChildPeer.owner());
        _grantRolesForPeer(ethFork, ethChildPeer, ethChildPeer.owner());
        _stopPrank();
    }

    /// @dev _grantRoles:: Helper to grant custom roles on a specific chain
    /// @param forkId The fork ID to grant roles for
    /// @param peer The peer to grant roles for
    /// @param peerOwner The owner of the peer to grant roles for
    function _grantRolesForPeer(uint256 forkId, IYieldPeer peer, address peerOwner) private {
        _selectFork(forkId);
        _changePrank(peerOwner);

        // Cast IYieldPeer to IAccessControl to access grant role functions
        IAccessControl peerAccessControl = IAccessControl(address(peer));

        peerAccessControl.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser);
        peerAccessControl.grantRole(Roles.EMERGENCY_UNPAUSER_ROLE, emergencyUnpauser);
        peerAccessControl.grantRole(Roles.CONFIG_ADMIN_ROLE, configAdmin);
        peerAccessControl.grantRole(Roles.CROSS_CHAIN_ADMIN_ROLE, crossChainAdmin);
        peerAccessControl.grantRole(Roles.FEE_WITHDRAWER_ROLE, feeWithdrawer);
        peerAccessControl.grantRole(Roles.FEE_RATE_SETTER_ROLE, feeRateSetter);
        // Assertions
        assertTrue(peerAccessControl.hasRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser));
        assertTrue(peerAccessControl.hasRole(Roles.EMERGENCY_UNPAUSER_ROLE, emergencyUnpauser));
        assertTrue(peerAccessControl.hasRole(Roles.CONFIG_ADMIN_ROLE, configAdmin));
        assertTrue(peerAccessControl.hasRole(Roles.CROSS_CHAIN_ADMIN_ROLE, crossChainAdmin));
        assertTrue(peerAccessControl.hasRole(Roles.FEE_WITHDRAWER_ROLE, feeWithdrawer));
        assertTrue(peerAccessControl.hasRole(Roles.FEE_RATE_SETTER_ROLE, feeRateSetter));
    }

    /// @dev Sets up SharePools on all chains to know about each other
    function _setPools() internal {
        uint64[] memory remoteChains = new uint64[](3);
        address[] memory remotePools = new address[](3);
        address[] memory remoteTokens = new address[](3);

        // Set up Base's pool to know about Optimism and Ethereum
        _selectFork(baseFork);
        remoteChains[0] = optChainSelector;
        remoteChains[1] = ethChainSelector;
        remoteChains[2] = baseChainSelector;
        remotePools[0] = address(optSharePool);
        remotePools[1] = address(ethSharePool);
        remotePools[2] = address(baseSharePool);
        remoteTokens[0] = address(optShare);
        remoteTokens[1] = address(ethShare);
        remoteTokens[2] = address(baseShare);
        _applyChainUpdates(baseSharePool, remoteChains, remotePools, remoteTokens);
        _assertArraysEqual(baseSharePool.getSupportedChains(), remoteChains);
        assertEq(baseSharePool.isRemotePool(optChainSelector, abi.encode(address(optSharePool))), true);
        assertEq(baseSharePool.isRemotePool(ethChainSelector, abi.encode(address(ethSharePool))), true);
        assertEq(baseSharePool.isRemotePool(baseChainSelector, abi.encode(address(baseSharePool))), true);
        assertEq(baseSharePool.getRemoteToken(optChainSelector), abi.encode(address(optShare)));
        assertEq(baseSharePool.getRemoteToken(ethChainSelector), abi.encode(address(ethShare)));
        assertEq(baseSharePool.getRemoteToken(baseChainSelector), abi.encode(address(baseShare)));

        // Set up Optimism's pool to know about Base and Ethereum
        _selectFork(optFork);
        remoteChains[0] = baseChainSelector;
        remoteChains[1] = ethChainSelector;
        remoteChains[2] = optChainSelector;
        remotePools[0] = address(baseSharePool);
        remotePools[1] = address(ethSharePool);
        remotePools[2] = address(optSharePool);
        remoteTokens[0] = address(baseShare);
        remoteTokens[1] = address(ethShare);
        remoteTokens[2] = address(optShare);
        _applyChainUpdates(optSharePool, remoteChains, remotePools, remoteTokens);
        _assertArraysEqual(optSharePool.getSupportedChains(), remoteChains);
        assertEq(optSharePool.isRemotePool(baseChainSelector, abi.encode(address(baseSharePool))), true);
        assertEq(optSharePool.isRemotePool(ethChainSelector, abi.encode(address(ethSharePool))), true);
        assertEq(optSharePool.isRemotePool(optChainSelector, abi.encode(address(optSharePool))), true);
        assertEq(optSharePool.getRemoteToken(baseChainSelector), abi.encode(address(baseShare)));
        assertEq(optSharePool.getRemoteToken(ethChainSelector), abi.encode(address(ethShare)));
        assertEq(optSharePool.getRemoteToken(optChainSelector), abi.encode(address(optShare)));

        // Set up Ethereum's pool to know about Base and Optimism
        _selectFork(ethFork);
        remoteChains[0] = baseChainSelector;
        remoteChains[1] = optChainSelector;
        remoteChains[2] = ethChainSelector;
        remotePools[0] = address(baseSharePool);
        remotePools[1] = address(optSharePool);
        remotePools[2] = address(ethSharePool);
        remoteTokens[0] = address(baseShare);
        remoteTokens[1] = address(optShare);
        remoteTokens[2] = address(ethShare);
        _applyChainUpdates(ethSharePool, remoteChains, remotePools, remoteTokens);
        _assertArraysEqual(ethSharePool.getSupportedChains(), remoteChains);
        assertEq(ethSharePool.isRemotePool(baseChainSelector, abi.encode(address(baseSharePool))), true);
        assertEq(ethSharePool.isRemotePool(optChainSelector, abi.encode(address(optSharePool))), true);
        assertEq(ethSharePool.isRemotePool(ethChainSelector, abi.encode(address(ethSharePool))), true);
        assertEq(ethSharePool.getRemoteToken(baseChainSelector), abi.encode(address(baseShare)));
        assertEq(ethSharePool.getRemoteToken(optChainSelector), abi.encode(address(optShare)));
        assertEq(ethSharePool.getRemoteToken(ethChainSelector), abi.encode(address(ethShare)));
    }

    /// @dev Sets cross chain configurations on Parent and Child Peers
    function _setCrossChainPeers() internal virtual {
        _selectFork(baseFork);
        /// @dev grant temp cross chain role to deployer to set cross chain configs
        baseParentPeer.grantRole(Roles.CROSS_CHAIN_ADMIN_ROLE, baseParentPeer.owner());
        baseParentPeer.setCCIPGasLimit(INITIAL_CCIP_GAS_LIMIT);
        baseParentPeer.setAllowedChain(optChainSelector, true);
        baseParentPeer.setAllowedChain(ethChainSelector, true);
        baseParentPeer.setAllowedChain(baseChainSelector, true);
        baseParentPeer.setAllowedPeer(optChainSelector, address(optChildPeer));
        baseParentPeer.setAllowedPeer(ethChainSelector, address(ethChildPeer));
        baseParentPeer.revokeRole(Roles.CROSS_CHAIN_ADMIN_ROLE, baseParentPeer.owner());
        /// @dev revoke role
        assertEq(baseParentPeer.getAllowedChain(optChainSelector), true);
        assertEq(baseParentPeer.getAllowedChain(ethChainSelector), true);
        assertEq(baseParentPeer.getAllowedPeer(optChainSelector), address(optChildPeer));
        assertEq(baseParentPeer.getAllowedPeer(ethChainSelector), address(ethChildPeer));

        _selectFork(optFork);
        /// @dev grant temp cross chain role to deployer to set cross chain configs
        optChildPeer.grantRole(Roles.CROSS_CHAIN_ADMIN_ROLE, optChildPeer.owner());
        optChildPeer.setCCIPGasLimit(INITIAL_CCIP_GAS_LIMIT);
        optChildPeer.setAllowedChain(baseChainSelector, true);
        optChildPeer.setAllowedChain(ethChainSelector, true);
        optChildPeer.setAllowedPeer(baseChainSelector, address(baseParentPeer));
        optChildPeer.setAllowedPeer(ethChainSelector, address(ethChildPeer));
        optChildPeer.revokeRole(Roles.CROSS_CHAIN_ADMIN_ROLE, optChildPeer.owner());
        /// @dev revoke role
        assertEq(optChildPeer.getAllowedChain(baseChainSelector), true);
        assertEq(optChildPeer.getAllowedChain(ethChainSelector), true);
        assertEq(optChildPeer.getAllowedPeer(baseChainSelector), address(baseParentPeer));
        assertEq(optChildPeer.getAllowedPeer(ethChainSelector), address(ethChildPeer));

        _selectFork(ethFork);
        /// @dev grant temp cross chain role to deployer to set cross chain configs
        ethChildPeer.grantRole(Roles.CROSS_CHAIN_ADMIN_ROLE, ethChildPeer.owner());
        ethChildPeer.setCCIPGasLimit(INITIAL_CCIP_GAS_LIMIT);
        ethChildPeer.setAllowedChain(baseChainSelector, true);
        ethChildPeer.setAllowedChain(optChainSelector, true);
        ethChildPeer.setAllowedPeer(baseChainSelector, address(baseParentPeer));
        ethChildPeer.setAllowedPeer(optChainSelector, address(optChildPeer));
        ethChildPeer.revokeRole(Roles.CROSS_CHAIN_ADMIN_ROLE, ethChildPeer.owner());
        /// @dev revoke role
        assertEq(ethChildPeer.getAllowedChain(baseChainSelector), true);
        assertEq(ethChildPeer.getAllowedChain(optChainSelector), true);
        assertEq(ethChildPeer.getAllowedPeer(baseChainSelector), address(baseParentPeer));
        assertEq(ethChildPeer.getAllowedPeer(optChainSelector), address(optChildPeer));
    }

    /// _setCrossChainPeers:: Helper to apply chain updates to SharePools
    /// @dev Apply chain updates to SharePools
    /// @param sharePool The SharePool to apply chain updates to
    /// @param remoteChainSelectors The chain selectors to apply chain updates to
    /// @param remotePoolAddresses The pool addresses to apply chain updates to
    /// @param remoteTokenAddresses The token addresses to apply chain updates to
    function _applyChainUpdates(
        SharePool sharePool,
        uint64[] memory remoteChainSelectors,
        address[] memory remotePoolAddresses,
        address[] memory remoteTokenAddresses
    ) internal {
        require(
            remoteChainSelectors.length == remotePoolAddresses.length
                && remotePoolAddresses.length == remoteTokenAddresses.length,
            "Length mismatch"
        );

        TokenPool.ChainUpdate[] memory chainUpdates = new TokenPool.ChainUpdate[](remoteChainSelectors.length);
        for (uint256 i = 0; i < remoteChainSelectors.length; i++) {
            chainUpdates[i] = TokenPool.ChainUpdate({
                remoteChainSelector: remoteChainSelectors[i],
                remotePoolAddresses: new bytes[](1),
                remoteTokenAddress: abi.encode(remoteTokenAddresses[i]),
                outboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0}),
                inboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0})
            });
            chainUpdates[i].remotePoolAddresses[0] = abi.encode(remotePoolAddresses[i]);
        }

        _changePrank(sharePool.owner());
        sharePool.applyChainUpdates(new uint64[](0), chainUpdates);
    }

    /// @dev Sets CCTP attesters on all chains
    function _setCCTPAttesters() internal {
        for (uint256 i = 0; i < attesters.length; i++) {
            (attesters[i], attesterPks[i]) = makeAddrAndKey(string.concat("attester", vm.toString(i)));
        }
        _enableAttestersForChain(baseFork, baseCCTPMessageTransmitter);
        _enableAttestersForChain(optFork, optCCTPMessageTransmitter);
        _enableAttestersForChain(ethFork, ethCCTPMessageTransmitter);
        _stopPrank();
    }

    /// @dev _setCCTPAttesters:: Helper to set CCTP attesters on a specific chain
    function _enableAttestersForChain(uint256 forkId, IMessageTransmitter transmitter) private {
        _selectFork(forkId);
        _changePrank(transmitter.owner());
        transmitter.updateAttesterManager(attesters[0]);
        _changePrank(attesters[0]);
        for (uint256 i = 0; i < attesters.length; i++) {
            transmitter.enableAttester(attesters[i]);
        }
        transmitter.setSignatureThreshold(attesters.length);
    }

    /// @dev Sets domains on all USDC Token Pools
    function _setDomains() internal {
        // Domain Updates
        USDCTokenPool.DomainUpdate[] memory domains = new USDCTokenPool.DomainUpdate[](3);

        // Optimism Domain
        domains[0] = USDCTokenPool.DomainUpdate({
            allowedCaller: bytes32(uint256(uint160(address(optUsdcTokenPool)))),
            domainIdentifier: 2,
            destChainSelector: optChainSelector,
            enabled: true
        });
        // Ethereum Domain
        domains[1] = USDCTokenPool.DomainUpdate({
            allowedCaller: bytes32(uint256(uint160(address(ethUsdcTokenPool)))),
            domainIdentifier: 0,
            destChainSelector: ethChainSelector,
            enabled: true
        });
        // Base Domain
        domains[2] = USDCTokenPool.DomainUpdate({
            allowedCaller: bytes32(uint256(uint160(address(baseUsdcTokenPool)))),
            domainIdentifier: 6,
            destChainSelector: baseChainSelector,
            enabled: true
        });

        // Apply
        _selectFork(baseFork);
        _changePrank(baseUsdcTokenPool.owner());
        baseUsdcTokenPool.setDomains(domains);

        _selectFork(optFork);
        _changePrank(optUsdcTokenPool.owner());
        optUsdcTokenPool.setDomains(domains);

        _selectFork(ethFork);
        _changePrank(ethUsdcTokenPool.owner());
        ethUsdcTokenPool.setDomains(domains);

        _stopPrank();
    }

    /// @dev Deals LINK to Parent and Child Peers
    /// @param isLocal If true, deals LINK on the current fork. If false, deals LINK on each respective fork.
    /// @param parent The Parent Peer address (used if isLocal is true)
    /// @param child1 The Optimism Child Peer address (used if isLocal is true)
    /// @param child2 The Ethereum Child Peer address (used if isLocal is true)
    /// @param link The LINK token address (used if isLocal is true)
    function _dealLinkToPeers(bool isLocal, address parent, address child1, address child2, address link) internal {
        if (isLocal) {
            deal(link, parent, LINK_AMOUNT);
            deal(link, child1, LINK_AMOUNT);
            deal(link, child2, LINK_AMOUNT);
        } else {
            _selectFork(baseFork);
            deal(baseParentPeer.getLink(), address(baseParentPeer), LINK_AMOUNT);

            _selectFork(optFork);
            deal(optChildPeer.getLink(), address(optChildPeer), LINK_AMOUNT);

            _selectFork(ethFork);
            deal(ethChildPeer.getLink(), address(ethChildPeer), LINK_AMOUNT);
        }
    }

    /// @dev Sets the keystone forwarder and workflow on the Rebalancer
    function _setForwarderAndWorkflow() internal {
        _selectFork(baseFork);
        _changePrank(baseRebalancer.owner());

        /// @dev set keystone forwarder
        baseRebalancer.setKeystoneForwarder(keystoneForwarder);
        baseRebalancer.setWorkflow(workflowId, workflowOwner, workflowName);
    }

    /// @notice empty test to skip file in coverage
    function test_baseTest() public {}

    /*//////////////////////////////////////////////////////////////
                                UTILITY
    //////////////////////////////////////////////////////////////*/
    /// @notice Helper function to change the prank
    /// @param newPrank The address to change the prank to
    function _changePrank(address newPrank) internal {
        vm.stopPrank();
        vm.startPrank(newPrank);
    }

    /// @notice Helper function to stop the prank
    function _stopPrank() internal {
        vm.stopPrank();
    }

    /// @notice Helper function to select a fork
    /// @param fork The fork to select
    function _selectFork(uint256 fork) internal {
        vm.selectFork(fork);
    }

    /// @notice Helper function to assert that two arrays are equal
    /// @param a The first array
    /// @param b The second array
    function _assertArraysEqual(uint64[] memory a, uint64[] memory b) internal pure {
        assertEq(a.length, b.length, "Array lengths do not match");
        for (uint256 i = 0; i < a.length; i++) {
            assertEq(a[i], b[i], string.concat("Arrays differ at index ", vm.toString(i)));
        }
    }

    /// @notice Helper function to get the Aave aToken address
    /// @param poolAddressesProvider The address of the Aave pool addresses provider
    /// @param underlyingToken The address of the underlying token
    /// @return aTokenAddress The address of the Aave aToken
    function _getATokenAddress(address poolAddressesProvider, address underlyingToken) internal view returns (address) {
        address aavePool = IPoolAddressesProvider(poolAddressesProvider).getPool();
        DataTypes.ReserveDataLegacy memory reserveData = IPool(aavePool).getReserveData(underlyingToken);
        return reserveData.aTokenAddress;
    }

    /// @notice Helper function to deal and approve USDC
    /// @param forkId The ID of the fork to select
    /// @param approver The address to deal USDC to
    /// @param approvee The address to approve USDC for
    /// @param amount The amount of USDC to deal and approve
    function _dealAndApproveUsdc(uint256 forkId, address approver, address approvee, uint256 amount) internal {
        _selectFork(forkId);
        deal(address(baseUsdc), approver, amount);
        _changePrank(approver);
        baseUsdc.approve(approvee, amount);
    }

    /// @notice Helper function to convert USDC to Share
    /// @param amountInUsdc The amount of USDC to convert
    /// @return amountInShare The amount of Share
    function _convertUsdcToShare(uint256 amountInUsdc) internal pure returns (uint256 amountInShare) {
        amountInShare = amountInUsdc * INITIAL_SHARE_PRECISION;
    }

    /// @notice Helper function to convert Share to USDC
    /// @param amountInShare The amount of Share to convert
    /// @return amountInUsdc The amount of USDC
    function _convertShareToUsdc(uint256 amountInShare) internal pure returns (uint256 amountInUsdc) {
        amountInUsdc = amountInShare / INITIAL_SHARE_PRECISION;
    }

    /// @notice Helper function to set the fee rate across chains
    /// @param feeRate The fee rate to set
    function _setFeeRate(uint256 feeRate) internal {
        _changePrank(feeRateSetter);
        _selectFork(baseFork);
        baseParentPeer.setFeeRate(feeRate);
        _selectFork(optFork);
        optChildPeer.setFeeRate(feeRate);
        _selectFork(ethFork);
        ethChildPeer.setFeeRate(feeRate);
        _stopPrank();
    }

    /// @notice Helper function to get the fee for a deposit
    /// @param stablecoinDepositAmount The amount of stablecoin being deposited
    /// @return fee The fee for the deposit
    function _getFee(uint256 stablecoinDepositAmount) internal view returns (uint256 fee) {
        // Get the fee rate from the current chain's peer
        uint256 feeRate;
        if (block.chainid == BASE_MAINNET_CHAIN_ID) {
            feeRate = baseParentPeer.getFeeRate();
        } else if (block.chainid == OPTIMISM_MAINNET_CHAIN_ID) {
            feeRate = optChildPeer.getFeeRate();
        } else if (block.chainid == ETHEREUM_MAINNET_CHAIN_ID) {
            feeRate = ethChildPeer.getFeeRate();
        }
        fee = (stablecoinDepositAmount * feeRate) / baseParentPeer.getFeeRateDivisor();
    }

    /// @notice Helper function to set the strategy across chains
    /// @dev 1. Takes a chain selector and protocol ID and creates the necessary metadata and report
    /// @dev 2. Calls onReport on Rebalancer with the metadata and report and sets the strategy on Parent
    /// @dev The "isSetAcrossChains" parameter is used to set the strategy on the Parent
    /// @dev but not yet route the message through CCIP.
    /// @param chainSelector The chain selector of the strategy
    /// @param protocolId The protocol ID of the strategy
    /// @param isSetAcrossChains Whether to set strategy across chains - this is used for testing ping pong scenarios
    function _setStrategy(uint64 chainSelector, bytes32 protocolId, bool isSetAcrossChains) internal {
        _selectFork(baseFork);

        /// @dev report using helper functions
        bytes memory report = WorkflowHelpers.createWorkflowReport(chainSelector, protocolId);

        /// @dev call onReport on Rebalancer with metadata and report as the Keystone Forwarder
        _changePrank(keystoneForwarder);
        baseRebalancer.onReport(workflowMetadata, report);
        _stopPrank();

        /// @dev route message through CCIP Local Simulator Fork if setting across chains is true
        if (isSetAcrossChains == true) {
            if (chainSelector == optChainSelector) {
                ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);
            } else if (chainSelector == ethChainSelector) {
                ccipLocalSimulatorFork.switchChainAndRouteMessage(ethFork);
            }
        }
    }
}
