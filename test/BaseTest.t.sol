// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console2, Vm} from "forge-std/Test.sol";

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

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

    CCIPLocalSimulatorFork internal ccipLocalSimulatorFork;
    uint256 internal constant LINK_AMOUNT = 1_000 * 1e18; // 1000 LINK
    uint256 internal constant INITIAL_CCIP_GAS_LIMIT = 500_000;

    uint256 internal constant BASE_MAINNET_CHAIN_ID = 8453;
    uint256 internal baseFork;

    uint256 internal constant OPTIMISM_MAINNET_CHAIN_ID = 10;
    uint256 internal optFork;

    uint256 internal constant ETHEREUM_MAINNET_CHAIN_ID = 1;
    uint256 internal ethFork;

    /// @dev update these with more recent block numbers
    uint256 internal constant BASE_MAINNET_BLOCK_NUMBER = 38045674;
    uint256 internal constant OPTIMISM_MAINNET_BLOCK_NUMBER = 143640972;
    uint256 internal constant ETHEREUM_MAINNET_BLOCK_NUMBER = 23777365;

    Share internal baseShare;
    SharePool internal baseSharePool;
    ParentPeer internal baseParentPeer;
    Rebalancer internal baseRebalancer;
    HelperConfig internal baseConfig;
    HelperConfig.NetworkConfig internal baseNetworkConfig;
    uint64 internal baseChainSelector;
    ERC20 internal baseUsdc;
    USDCTokenPool internal baseUsdcTokenPool;
    IMessageTransmitter internal baseCCTPMessageTransmitter;
    StrategyRegistry internal baseStrategyRegistry;
    AaveV3Adapter internal baseAaveV3Adapter;
    CompoundV3Adapter internal baseCompoundV3Adapter;

    Share internal optShare;
    SharePool internal optSharePool;
    ChildPeer internal optChildPeer;
    HelperConfig internal optConfig;
    HelperConfig.NetworkConfig internal optNetworkConfig;
    uint64 internal optChainSelector;
    ERC20 internal optUsdc;
    USDCTokenPool internal optUsdcTokenPool;
    IMessageTransmitter internal optCCTPMessageTransmitter;
    StrategyRegistry internal optStrategyRegistry;
    AaveV3Adapter internal optAaveV3Adapter;
    CompoundV3Adapter internal optCompoundV3Adapter;

    Share internal ethShare;
    SharePool internal ethSharePool;
    ChildPeer internal ethChildPeer;
    HelperConfig internal ethConfig;
    HelperConfig.NetworkConfig internal ethNetworkConfig;
    uint64 internal ethChainSelector;
    ERC20 internal ethUsdc;
    USDCTokenPool internal ethUsdcTokenPool;
    IMessageTransmitter internal ethCCTPMessageTransmitter;
    StrategyRegistry internal ethStrategyRegistry;
    AaveV3Adapter internal ethAaveV3Adapter;
    CompoundV3Adapter internal ethCompoundV3Adapter;

    address internal owner = makeAddr("owner");
    address internal depositor = makeAddr("depositor");
    address internal withdrawer = makeAddr("withdrawer");
    address internal holder = makeAddr("holder");
    address internal keystoneForwarder = makeAddr("keystoneForwarder");
    address[] internal attesters = new address[](4);
    uint256[] internal attesterPks = new uint256[](4);

    /// @dev addresses for custom roles
    address internal configAdmin = makeAddr("configAdmin");
    address internal crossChainAdmin = makeAddr("crossChainAdmin");
    address internal emergencyPauser = makeAddr("emergencyPauser");
    address internal emergencyUnpauser = makeAddr("emergencyUnpauser");
    address internal feeWithdrawer = makeAddr("feeWithdrawer");
    address internal feeRateSetter = makeAddr("feeRateSetter");

    /// @dev workflow params and metadata setup
    address internal workflowOwner = makeAddr("workflowOwner");
    bytes32 internal workflowId = bytes32("rebalanceWorkflowId");
    string internal workflowNameRaw = "yieldcoin-rebalance-workflow";
    bytes10 internal workflowName = WorkflowHelpers.createWorkflowName(workflowNameRaw);
    bytes internal workflowMetadata = WorkflowHelpers.createWorkflowMetadata(workflowId, workflowName, workflowOwner);

    /// @dev '_setStrategy' flag to control message routing
    bool internal constant SET_CROSS_CHAIN = true;
    bool internal constant NO_CROSS_CHAIN = false;

    // Add this constant at the top of BaseTest
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/
    function setUp() public virtual {
        _deployInfra();
        _grantRoles();
        _setPools();
        _setCrossChainPeers();
        _dealLinkToPeers(false, address(0), address(0), address(0), address(0));

        _setCCTPAttesters();
        _setDomains();

        _setForwarderAndWorkflow();

        /// @dev sanity check that we're ending BaseTest.setUp() on the Parent chain
        assertEq(block.chainid, BASE_MAINNET_CHAIN_ID);
        _stopPrank();
    }

    function _deployInfra() internal virtual {
        // Deploy on Base
        baseFork = vm.createSelectFork(vm.envString("BASE_MAINNET_RPC_URL"), BASE_MAINNET_BLOCK_NUMBER);
        assertEq(block.chainid, BASE_MAINNET_CHAIN_ID);

        DeployParent baseDeployParent = new DeployParent();
        DeployParent.DeploymentConfig memory baseDeploy = baseDeployParent.run();
        baseShare = baseDeploy.share;
        baseSharePool = baseDeploy.sharePool;
        baseParentPeer = baseDeploy.parentPeer;
        baseRebalancer = baseDeploy.rebalancer;
        baseConfig = baseDeploy.config;
        baseStrategyRegistry = baseDeploy.strategyRegistry;
        baseAaveV3Adapter = baseDeploy.aaveV3Adapter;
        baseCompoundV3Adapter = baseDeploy.compoundV3Adapter;
        vm.makePersistent(address(baseShare));
        vm.makePersistent(address(baseSharePool));
        vm.makePersistent(address(baseParentPeer));
        vm.makePersistent(address(baseRebalancer));

        // 2. NEW: Persist the hidden Implementation
        address baseImpl = address(uint160(uint256(vm.load(address(baseDeploy.parentPeer), IMPLEMENTATION_SLOT))));
        vm.makePersistent(baseImpl);

        baseNetworkConfig = baseConfig.getActiveNetworkConfig();
        baseChainSelector = baseNetworkConfig.ccip.thisChainSelector;
        baseUsdc = ERC20(baseNetworkConfig.tokens.usdc);
        baseUsdcTokenPool = USDCTokenPool(baseNetworkConfig.ccip.usdcTokenPool);
        baseCCTPMessageTransmitter = IMessageTransmitter(baseNetworkConfig.ccip.cctpMessageTransmitter);

        // Deploy on Optimism
        optFork = vm.createSelectFork(vm.envString("OPTIMISM_MAINNET_RPC_URL"), OPTIMISM_MAINNET_BLOCK_NUMBER);
        assertEq(block.chainid, OPTIMISM_MAINNET_CHAIN_ID);

        DeployChild optDeployChild = new DeployChild();
        DeployChild.ChildDeploymentConfig memory optDeploy = optDeployChild.run();
        optShare = optDeploy.share;
        optSharePool = optDeploy.sharePool;
        optChildPeer = optDeploy.childPeer;
        optConfig = optDeploy.config;
        optStrategyRegistry = optDeploy.strategyRegistry;
        optAaveV3Adapter = optDeploy.aaveV3Adapter;
        optCompoundV3Adapter = optDeploy.compoundV3Adapter;
        vm.makePersistent(address(optShare));
        vm.makePersistent(address(optSharePool));
        vm.makePersistent(address(optChildPeer));
        vm.makePersistent(optDeploy.childPeerImpl);

        optNetworkConfig = optConfig.getActiveNetworkConfig();
        optChainSelector = optNetworkConfig.ccip.thisChainSelector;
        optUsdc = ERC20(optNetworkConfig.tokens.usdc);
        optUsdcTokenPool = USDCTokenPool(optNetworkConfig.ccip.usdcTokenPool);
        optCCTPMessageTransmitter = IMessageTransmitter(optNetworkConfig.ccip.cctpMessageTransmitter);

        // Deploy on Ethereum
        ethFork = vm.createSelectFork(vm.envString("ETH_MAINNET_RPC_URL"), ETHEREUM_MAINNET_BLOCK_NUMBER);
        assertEq(block.chainid, ETHEREUM_MAINNET_CHAIN_ID);

        DeployChild ethDeployChild = new DeployChild();
        DeployChild.ChildDeploymentConfig memory ethDeploy = ethDeployChild.run();
        ethShare = ethDeploy.share;
        ethSharePool = ethDeploy.sharePool;
        ethChildPeer = ethDeploy.childPeer;
        ethConfig = ethDeploy.config;
        ethStrategyRegistry = ethDeploy.strategyRegistry;
        ethAaveV3Adapter = ethDeploy.aaveV3Adapter;
        ethCompoundV3Adapter = ethDeploy.compoundV3Adapter;
        vm.makePersistent(address(ethShare));
        vm.makePersistent(address(ethSharePool));
        vm.makePersistent(address(ethChildPeer));
        vm.makePersistent(ethDeploy.childPeerImpl);

        ethNetworkConfig = ethConfig.getActiveNetworkConfig();
        ethChainSelector = ethNetworkConfig.ccip.thisChainSelector;
        ethUsdc = ERC20(ethNetworkConfig.tokens.usdc);
        ethUsdcTokenPool = USDCTokenPool(ethNetworkConfig.ccip.usdcTokenPool);
        ethCCTPMessageTransmitter = IMessageTransmitter(ethNetworkConfig.ccip.cctpMessageTransmitter);

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));
        _registerChains();
    }

    function _grantRoles() internal virtual {
        // grant roles - parent
        _selectFork(baseFork);
        _changePrank(baseParentPeer.owner());
        baseParentPeer.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser);
        baseParentPeer.grantRole(Roles.EMERGENCY_UNPAUSER_ROLE, emergencyUnpauser);
        baseParentPeer.grantRole(Roles.CONFIG_ADMIN_ROLE, configAdmin);
        baseParentPeer.grantRole(Roles.CROSS_CHAIN_ADMIN_ROLE, crossChainAdmin);
        baseParentPeer.grantRole(Roles.FEE_WITHDRAWER_ROLE, feeWithdrawer);
        baseParentPeer.grantRole(Roles.FEE_RATE_SETTER_ROLE, feeRateSetter);

        assertTrue(baseParentPeer.hasRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser));
        assertTrue(baseParentPeer.hasRole(Roles.EMERGENCY_UNPAUSER_ROLE, emergencyUnpauser));
        assertTrue(baseParentPeer.hasRole(Roles.CONFIG_ADMIN_ROLE, configAdmin));
        assertTrue(baseParentPeer.hasRole(Roles.CROSS_CHAIN_ADMIN_ROLE, crossChainAdmin));
        assertTrue(baseParentPeer.hasRole(Roles.FEE_WITHDRAWER_ROLE, feeWithdrawer));
        assertTrue(baseParentPeer.hasRole(Roles.FEE_RATE_SETTER_ROLE, feeRateSetter));

        // grant roles - child 1
        _selectFork(optFork);
        _changePrank(optChildPeer.owner());
        optChildPeer.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser);
        optChildPeer.grantRole(Roles.EMERGENCY_UNPAUSER_ROLE, emergencyUnpauser);
        optChildPeer.grantRole(Roles.CONFIG_ADMIN_ROLE, configAdmin);
        optChildPeer.grantRole(Roles.CROSS_CHAIN_ADMIN_ROLE, crossChainAdmin);
        optChildPeer.grantRole(Roles.FEE_WITHDRAWER_ROLE, feeWithdrawer);
        optChildPeer.grantRole(Roles.FEE_RATE_SETTER_ROLE, feeRateSetter);

        assertTrue(optChildPeer.hasRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser));
        assertTrue(optChildPeer.hasRole(Roles.EMERGENCY_UNPAUSER_ROLE, emergencyUnpauser));
        assertTrue(optChildPeer.hasRole(Roles.CONFIG_ADMIN_ROLE, configAdmin));
        assertTrue(optChildPeer.hasRole(Roles.CROSS_CHAIN_ADMIN_ROLE, crossChainAdmin));
        assertTrue(optChildPeer.hasRole(Roles.FEE_WITHDRAWER_ROLE, feeWithdrawer));
        assertTrue(optChildPeer.hasRole(Roles.FEE_RATE_SETTER_ROLE, feeRateSetter));

        // grant roles - child 2
        _selectFork(ethFork);
        _changePrank(ethChildPeer.owner());
        ethChildPeer.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser);
        ethChildPeer.grantRole(Roles.EMERGENCY_UNPAUSER_ROLE, emergencyUnpauser);
        ethChildPeer.grantRole(Roles.CONFIG_ADMIN_ROLE, configAdmin);
        ethChildPeer.grantRole(Roles.CROSS_CHAIN_ADMIN_ROLE, crossChainAdmin);
        ethChildPeer.grantRole(Roles.FEE_WITHDRAWER_ROLE, feeWithdrawer);
        ethChildPeer.grantRole(Roles.FEE_RATE_SETTER_ROLE, feeRateSetter);

        assertTrue(ethChildPeer.hasRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser));
        assertTrue(ethChildPeer.hasRole(Roles.EMERGENCY_UNPAUSER_ROLE, emergencyUnpauser));
        assertTrue(ethChildPeer.hasRole(Roles.CONFIG_ADMIN_ROLE, configAdmin));
        assertTrue(ethChildPeer.hasRole(Roles.CROSS_CHAIN_ADMIN_ROLE, crossChainAdmin));
        assertTrue(ethChildPeer.hasRole(Roles.FEE_WITHDRAWER_ROLE, feeWithdrawer));
        assertTrue(ethChildPeer.hasRole(Roles.FEE_RATE_SETTER_ROLE, feeRateSetter));
        _stopPrank();
    }

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

    function _registerChains() internal {
        // Set up Optimism network details using values from HelperConfig
        Register.NetworkDetails memory optimismDetails = Register.NetworkDetails({
            chainSelector: optChainSelector,
            routerAddress: optNetworkConfig.ccip.ccipRouter,
            linkAddress: optNetworkConfig.tokens.link,
            wrappedNativeAddress: address(0),
            ccipBnMAddress: address(0),
            ccipLnMAddress: address(0),
            rmnProxyAddress: address(0),
            registryModuleOwnerCustomAddress: address(0),
            tokenAdminRegistryAddress: address(0)
        });

        // Set the network details for Optimism
        ccipLocalSimulatorFork.setNetworkDetails(OPTIMISM_MAINNET_CHAIN_ID, optimismDetails);

        // Set up Base network details using values from HelperConfig
        Register.NetworkDetails memory baseDetails = Register.NetworkDetails({
            chainSelector: baseChainSelector,
            routerAddress: baseNetworkConfig.ccip.ccipRouter,
            linkAddress: baseNetworkConfig.tokens.link,
            wrappedNativeAddress: address(0),
            ccipBnMAddress: address(0),
            ccipLnMAddress: address(0),
            rmnProxyAddress: address(0),
            registryModuleOwnerCustomAddress: address(0),
            tokenAdminRegistryAddress: address(0)
        });

        // Set the network details for Base
        ccipLocalSimulatorFork.setNetworkDetails(BASE_MAINNET_CHAIN_ID, baseDetails);

        // Set up Ethereum network details using values from HelperConfig
        Register.NetworkDetails memory ethereumDetails = Register.NetworkDetails({
            chainSelector: ethChainSelector,
            routerAddress: ethNetworkConfig.ccip.ccipRouter,
            linkAddress: ethNetworkConfig.tokens.link,
            wrappedNativeAddress: address(0),
            ccipBnMAddress: address(0),
            ccipLnMAddress: address(0),
            rmnProxyAddress: address(0),
            registryModuleOwnerCustomAddress: address(0),
            tokenAdminRegistryAddress: address(0)
        });

        // Set the network details for Ethereum
        ccipLocalSimulatorFork.setNetworkDetails(ETHEREUM_MAINNET_CHAIN_ID, ethereumDetails);
    }

    function _setCCTPAttesters() internal {
        for (uint256 i = 0; i < attesters.length; i++) {
            (attesters[i], attesterPks[i]) = makeAddrAndKey(string.concat("attester", vm.toString(i)));
        }

        _selectFork(baseFork);
        _changePrank(baseCCTPMessageTransmitter.owner());
        baseCCTPMessageTransmitter.updateAttesterManager(attesters[0]);
        _changePrank(attesters[0]);
        for (uint256 i = 0; i < attesters.length; i++) {
            baseCCTPMessageTransmitter.enableAttester(attesters[i]);
        }
        baseCCTPMessageTransmitter.setSignatureThreshold(attesters.length);

        _selectFork(optFork);
        _changePrank(optCCTPMessageTransmitter.owner());
        optCCTPMessageTransmitter.updateAttesterManager(attesters[0]);
        _changePrank(attesters[0]);
        for (uint256 i = 0; i < attesters.length; i++) {
            optCCTPMessageTransmitter.enableAttester(attesters[i]);
        }
        optCCTPMessageTransmitter.setSignatureThreshold(attesters.length);

        _selectFork(ethFork);
        _changePrank(ethCCTPMessageTransmitter.owner());
        ethCCTPMessageTransmitter.updateAttesterManager(attesters[0]);
        _changePrank(attesters[0]);
        for (uint256 i = 0; i < attesters.length; i++) {
            ethCCTPMessageTransmitter.enableAttester(attesters[i]);
        }
        ethCCTPMessageTransmitter.setSignatureThreshold(attesters.length);

        _stopPrank();
    }

    function _setDomains() internal {
        // The allowedCaller must be the MessageTransmitterProxy address of the destination chain
        USDCTokenPool.DomainUpdate[] memory domains = new USDCTokenPool.DomainUpdate[](3);
        domains[0] = USDCTokenPool.DomainUpdate({
            allowedCaller: bytes32(uint256(uint160(address(optUsdcTokenPool)))),
            domainIdentifier: 2,
            destChainSelector: optChainSelector,
            enabled: true
        });
        domains[1] = USDCTokenPool.DomainUpdate({
            allowedCaller: bytes32(uint256(uint160(address(ethUsdcTokenPool)))),
            domainIdentifier: 0,
            destChainSelector: ethChainSelector,
            enabled: true
        });
        domains[2] = USDCTokenPool.DomainUpdate({
            allowedCaller: bytes32(uint256(uint160(address(baseUsdcTokenPool)))),
            domainIdentifier: 6,
            destChainSelector: baseChainSelector,
            enabled: true
        });

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
