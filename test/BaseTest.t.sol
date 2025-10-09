// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console2, Vm} from "forge-std/Test.sol";

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {CCIPLocalSimulatorFork, Register} from "@chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";
import {Log} from "@chainlink/contracts/src/v0.8/automation/interfaces/ILogAutomation.sol";

import {DeployParent, HelperConfig, ParentPeer, Rebalancer} from "../script/deploy/DeployParent.s.sol";
import {DeployChild, ChildPeer} from "../script/deploy/DeployChild.s.sol";
import {Share} from "../src/token/Share.sol";
import {SharePool} from "../src/token/SharePool.sol";
import {RateLimiter} from "@chainlink/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";
import {TokenPool} from "@chainlink/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {DataTypes} from "@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol";
import {USDCTokenPool} from "@chainlink/contracts/src/v0.8/ccip/pools/USDC/USDCTokenPool.sol";
import {
    IFunctionsSubscriptions
} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/interfaces/IFunctionsSubscriptions.sol";
import {IFunctionsRouter} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/interfaces/IFunctionsRouter.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_3_0/FunctionsClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IMessageTransmitter} from "../src/interfaces/IMessageTransmitter.sol";
import {IYieldPeer} from "../src/interfaces/IYieldPeer.sol";
import {IComet} from "../src/interfaces/IComet.sol";
import {AaveV3Adapter} from "../src/adapters/AaveV3Adapter.sol";
import {CompoundV3Adapter} from "../src/adapters/CompoundV3Adapter.sol";
import {StrategyRegistry} from "../src/modules/StrategyRegistry.sol";
import {StablecoinRegistry} from "../src/modules/StablecoinRegistry.sol";

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

    uint64 internal clfSubId;

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
    StablecoinRegistry internal baseStablecoinRegistry;

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
    StablecoinRegistry internal optStablecoinRegistry;

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
    StablecoinRegistry internal ethStablecoinRegistry;

    address internal owner = makeAddr("owner");
    address internal depositor = makeAddr("depositor");
    address internal withdrawer = makeAddr("withdrawer");
    address internal holder = makeAddr("holder");
    address internal upkeepAddress = makeAddr("upkeepAddress");
    address internal forwarder = makeAddr("forwarder");
    address[] internal attesters = new address[](4);
    uint256[] internal attesterPks = new uint256[](4);

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/
    function setUp() public virtual {
        _deployInfra();
        _setPools();
        _setCrossChainPeers();
        _dealLinkToPeers(false, address(0), address(0), address(0), address(0));

        _setCCTPAttesters();
        _setDomains();

        _setUpAutomationAndFunctions();

        /// @dev sanity check that we're ending BaseTest.setUp() on the Parent chain
        assertEq(block.chainid, BASE_MAINNET_CHAIN_ID);
        _stopPrank();
    }

    /// @notice Chainlink Functions requires signing Terms of Service - we can bypass this in our fork tests by pranking the FunctionsRouter contract owner and setting the allowListId for the TermsOfServiceAllowList contract to map to address(0)
    function _bypassClfTermsOfService() internal {
        HelperConfig config = new HelperConfig();
        address functionsRouter = config.getActiveNetworkConfig().clf.functionsRouter;
        _changePrank(Ownable(functionsRouter).owner());
        IFunctionsRouter(functionsRouter).setAllowListId("");
        _stopPrank();
    }

    function _deployInfra() internal virtual {
        // Deploy on Base
        baseFork = vm.createSelectFork(vm.envString("BASE_MAINNET_RPC_URL"));
        assertEq(block.chainid, BASE_MAINNET_CHAIN_ID);

        _bypassClfTermsOfService();

        DeployParent baseDeployParent = new DeployParent();
        DeployParent.DeploymentConfig memory baseDeploy = baseDeployParent.run();
        baseShare = baseDeploy.share;
        baseSharePool = baseDeploy.sharePool;
        baseParentPeer = baseDeploy.parentPeer;
        baseRebalancer = baseDeploy.rebalancer;
        baseConfig = baseDeploy.config;
        clfSubId = baseDeploy.clfSubId;
        baseStrategyRegistry = baseDeploy.strategyRegistry;
        baseAaveV3Adapter = baseDeploy.aaveV3Adapter;
        baseCompoundV3Adapter = baseDeploy.compoundV3Adapter;
        baseStablecoinRegistry = baseDeploy.stablecoinRegistry;
        vm.makePersistent(address(baseShare));
        vm.makePersistent(address(baseSharePool));
        vm.makePersistent(address(baseParentPeer));
        vm.makePersistent(address(baseRebalancer));

        baseNetworkConfig = baseConfig.getActiveNetworkConfig();
        baseChainSelector = baseNetworkConfig.ccip.thisChainSelector;
        baseUsdc = ERC20(baseNetworkConfig.tokens.usdc);
        baseUsdcTokenPool = USDCTokenPool(baseNetworkConfig.ccip.usdcTokenPool);
        baseCCTPMessageTransmitter = IMessageTransmitter(baseNetworkConfig.ccip.cctpMessageTransmitter);

        // Deploy on Optimism
        optFork = vm.createSelectFork(vm.envString("OPTIMISM_MAINNET_RPC_URL"));
        assertEq(block.chainid, OPTIMISM_MAINNET_CHAIN_ID);

        DeployChild optDeployChild = new DeployChild();
        DeployChild.DeploymentConfig memory optDeploy = optDeployChild.run();
        optShare = optDeploy.share;
        optSharePool = optDeploy.sharePool;
        optChildPeer = optDeploy.childPeer;
        optConfig = optDeploy.config;
        optStrategyRegistry = optDeploy.strategyRegistry;
        optAaveV3Adapter = optDeploy.aaveV3Adapter;
        optCompoundV3Adapter = optDeploy.compoundV3Adapter;
        optStablecoinRegistry = optDeploy.stablecoinRegistry;
        vm.makePersistent(address(optShare));
        vm.makePersistent(address(optSharePool));
        vm.makePersistent(address(optChildPeer));

        optNetworkConfig = optConfig.getActiveNetworkConfig();
        optChainSelector = optNetworkConfig.ccip.thisChainSelector;
        optUsdc = ERC20(optNetworkConfig.tokens.usdc);
        optUsdcTokenPool = USDCTokenPool(optNetworkConfig.ccip.usdcTokenPool);
        optCCTPMessageTransmitter = IMessageTransmitter(optNetworkConfig.ccip.cctpMessageTransmitter);

        // Deploy on Ethereum
        ethFork = vm.createSelectFork(vm.envString("ETH_MAINNET_RPC_URL"));
        assertEq(block.chainid, ETHEREUM_MAINNET_CHAIN_ID);

        DeployChild ethDeployChild = new DeployChild();
        DeployChild.DeploymentConfig memory ethDeploy = ethDeployChild.run();
        ethShare = ethDeploy.share;
        ethSharePool = ethDeploy.sharePool;
        ethChildPeer = ethDeploy.childPeer;
        ethConfig = ethDeploy.config;
        ethStrategyRegistry = ethDeploy.strategyRegistry;
        ethAaveV3Adapter = ethDeploy.aaveV3Adapter;
        ethCompoundV3Adapter = ethDeploy.compoundV3Adapter;
        ethStablecoinRegistry = ethDeploy.stablecoinRegistry;
        vm.makePersistent(address(ethShare));
        vm.makePersistent(address(ethSharePool));
        vm.makePersistent(address(ethChildPeer));

        ethNetworkConfig = ethConfig.getActiveNetworkConfig();
        ethChainSelector = ethNetworkConfig.ccip.thisChainSelector;
        ethUsdc = ERC20(ethNetworkConfig.tokens.usdc);
        ethUsdcTokenPool = USDCTokenPool(ethNetworkConfig.ccip.usdcTokenPool);
        ethCCTPMessageTransmitter = IMessageTransmitter(ethNetworkConfig.ccip.cctpMessageTransmitter);

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));
        _registerChains();
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
        baseParentPeer.setCCIPGasLimit(INITIAL_CCIP_GAS_LIMIT);
        baseParentPeer.setAllowedChain(optChainSelector, true);
        baseParentPeer.setAllowedChain(ethChainSelector, true);
        baseParentPeer.setAllowedChain(baseChainSelector, true);
        baseParentPeer.setAllowedPeer(optChainSelector, address(optChildPeer));
        baseParentPeer.setAllowedPeer(ethChainSelector, address(ethChildPeer));
        assertEq(baseParentPeer.getAllowedChain(optChainSelector), true);
        assertEq(baseParentPeer.getAllowedChain(ethChainSelector), true);
        assertEq(baseParentPeer.getAllowedPeer(optChainSelector), address(optChildPeer));
        assertEq(baseParentPeer.getAllowedPeer(ethChainSelector), address(ethChildPeer));

        _selectFork(optFork);
        optChildPeer.setCCIPGasLimit(INITIAL_CCIP_GAS_LIMIT);
        optChildPeer.setAllowedChain(baseChainSelector, true);
        optChildPeer.setAllowedChain(ethChainSelector, true);
        optChildPeer.setAllowedPeer(baseChainSelector, address(baseParentPeer));
        optChildPeer.setAllowedPeer(ethChainSelector, address(ethChildPeer));
        assertEq(optChildPeer.getAllowedChain(baseChainSelector), true);
        assertEq(optChildPeer.getAllowedChain(ethChainSelector), true);
        assertEq(optChildPeer.getAllowedPeer(baseChainSelector), address(baseParentPeer));
        assertEq(optChildPeer.getAllowedPeer(ethChainSelector), address(ethChildPeer));

        _selectFork(ethFork);
        ethChildPeer.setCCIPGasLimit(INITIAL_CCIP_GAS_LIMIT);
        ethChildPeer.setAllowedChain(baseChainSelector, true);
        ethChildPeer.setAllowedChain(optChainSelector, true);
        ethChildPeer.setAllowedPeer(baseChainSelector, address(baseParentPeer));
        ethChildPeer.setAllowedPeer(optChainSelector, address(optChildPeer));
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

    function _setUpAutomationAndFunctions() internal {
        _selectFork(baseFork);

        /// @dev set forwarder
        _changePrank(baseParentPeer.owner());
        baseRebalancer.setForwarder(forwarder);

        /// @dev set upkeepAddress
        address parentPeerOwner = baseParentPeer.owner();
        _changePrank(parentPeerOwner);
        baseRebalancer.setUpkeepAddress(upkeepAddress);

        /// @dev add ParentPeer as consumer to Chainlink Functions subscription
        address functionsRouter = baseNetworkConfig.clf.functionsRouter;
        IFunctionsSubscriptions(functionsRouter).addConsumer(clfSubId, address(baseRebalancer));

        /// @dev fund Chainlink Functions subscription
        deal(baseParentPeer.getLink(), parentPeerOwner, LINK_AMOUNT);
        LinkTokenInterface(baseParentPeer.getLink()).transferAndCall(functionsRouter, LINK_AMOUNT, abi.encode(clfSubId));
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
        DataTypes.ReserveData memory reserveData = IPool(aavePool).getReserveData(underlyingToken);
        return reserveData.aTokenAddress;
    }

    /// @notice Helper function to fulfill a Chainlink Functions request
    /// @param requestId The ID of the request to fulfill
    /// @param response The response to the request
    /// @param err The error message to return if the request fails
    function _fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal {
        _changePrank(baseNetworkConfig.clf.functionsRouter);
        FunctionsClient(address(baseRebalancer)).handleOracleFulfillment(requestId, response, err);
        _stopPrank();
    }

    /// @notice Helper function to set the strategy across chains
    /// @param chainSelector The chain selector of the strategy
    /// @param protocolId The protocol ID of the strategy
    function _setStrategy(uint64 chainSelector, bytes32 protocolId) internal {
        _selectFork(baseFork);

        address activeStrategyAdapter = baseParentPeer.getActiveStrategyAdapter();
        uint256 totalValue = baseParentPeer.getTotalValue();

        /// @dev set the strategy on the parent chain by pranking Chainlink Functions fulfillRequest
        bytes32 requestId = bytes32("requestId");
        bytes memory response = abi.encode(uint256(chainSelector), protocolId);
        _fulfillRequest(requestId, response, "");

        if (chainSelector != baseChainSelector) {
            bytes memory performData = _createPerformData(
                chainSelector,
                protocolId,
                IYieldPeer.CcipTxType.RebalanceNewStrategy,
                baseChainSelector,
                activeStrategyAdapter,
                totalValue
            );
            _changePrank(forwarder);
            baseRebalancer.performUpkeep(performData);
            _stopPrank();
        }

        if (chainSelector == optChainSelector) {
            ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);
        } else if (chainSelector == ethChainSelector) {
            ccipLocalSimulatorFork.switchChainAndRouteMessage(ethFork);
        }
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

    /// @notice Helper function to create a log for Chainlink Automation checkLog
    /// @param source The source of the log
    /// @param topics The topics of the log
    /// @return log The log
    function _createLog(address source, bytes32[] memory topics) internal view returns (Log memory) {
        return Log({
            index: 0,
            timestamp: block.timestamp,
            txHash: bytes32(0),
            blockNumber: block.number,
            blockHash: bytes32(0),
            source: source,
            topics: topics,
            data: ""
        });
    }

    /// @notice Helper function to create perform data for Chainlink Automation performUpkeep
    /// @param chainSelector The chain selector of the new strategy
    /// @param protocolId The protocol ID of the strategy
    /// @param txType The type of CCIP message to send
    /// @param oldChainSelector The chain selector of the old strategy
    /// @param oldStrategyPool The address of the old strategy pool
    function _createPerformData(
        uint64 chainSelector,
        bytes32 protocolId,
        IYieldPeer.CcipTxType txType,
        uint64 oldChainSelector,
        address oldStrategyPool,
        uint256 totalValue
    ) internal view returns (bytes memory) {
        address parentPeer = address(baseRebalancer.getParentPeer());
        IYieldPeer.Strategy memory newStrategy =
            IYieldPeer.Strategy({chainSelector: chainSelector, protocolId: protocolId});
        return abi.encode(parentPeer, newStrategy, txType, oldChainSelector, oldStrategyPool, totalValue);
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
        _selectFork(baseFork);
        _changePrank(baseParentPeer.owner());
        baseParentPeer.setFeeRate(feeRate);
        _selectFork(optFork);
        _changePrank(optChildPeer.owner());
        optChildPeer.setFeeRate(feeRate);
        _selectFork(ethFork);
        _changePrank(ethChildPeer.owner());
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
}
