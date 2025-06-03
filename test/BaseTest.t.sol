// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console2, Vm} from "forge-std/Test.sol";

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {CCIPLocalSimulatorFork, Register} from "@chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";

import {DeployParent, HelperConfig, ParentPeer} from "../script/deploy/DeployParent.s.sol";
import {DeployChild, ChildPeer} from "../script/deploy/DeployChild.s.sol";
import {Share} from "../src/token/Share.sol";
import {SharePool} from "../src/token/SharePool.sol";
import {RateLimiter} from "@chainlink/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";
import {TokenPool} from "@chainlink/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {DataTypes} from "@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol";
import {USDCTokenPool} from "@chainlink/contracts/src/v0.8/ccip/pools/USDC/USDCTokenPool.sol";
import {IMessageTransmitter} from "../src/interfaces/IMessageTransmitter.sol";

contract BaseTest is Test {
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 internal constant DEPOSIT_AMOUNT = 1_000_000_000; // 1000 USDC
    uint256 internal constant INITIAL_SHARE_PRECISION = 1e18 / 1e6;
    uint256 internal constant BALANCE_TOLERANCE = 2; // Allow 2 wei difference

    CCIPLocalSimulatorFork internal ccipLocalSimulatorFork;
    uint256 internal constant LINK_AMOUNT = 1_000 * 1e18; // 1000 LINK
    uint256 internal constant INITIAL_CCIP_GAS_LIMIT = 500_000;

    string internal constant ARBITRUM_MAINNET_RPC_URL = "https://arb1.arbitrum.io/rpc";
    uint256 internal constant ARBITRUM_MAINNET_CHAIN_ID = 42161;
    uint256 internal arbFork;

    string internal constant OPTIMISM_MAINNET_RPC_URL = "https://mainnet.optimism.io";
    uint256 internal constant OPTIMISM_MAINNET_CHAIN_ID = 10;
    uint256 internal optFork;

    uint256 internal constant ETHEREUM_MAINNET_CHAIN_ID = 1;
    uint256 internal ethFork;

    Share internal arbShare;
    SharePool internal arbSharePool;
    ParentPeer internal arbParentPeer;
    HelperConfig internal arbConfig;
    HelperConfig.NetworkConfig internal arbNetworkConfig;
    uint64 internal arbChainSelector;
    ERC20 internal arbUsdc;
    USDCTokenPool internal arbUsdcTokenPool;
    IMessageTransmitter internal arbCCTPMessageTransmitter;

    Share internal optShare;
    SharePool internal optSharePool;
    ChildPeer internal optChildPeer;
    HelperConfig internal optConfig;
    HelperConfig.NetworkConfig internal optNetworkConfig;
    uint64 internal optChainSelector;
    ERC20 internal optUsdc;
    USDCTokenPool internal optUsdcTokenPool;
    IMessageTransmitter internal optCCTPMessageTransmitter;

    Share internal ethShare;
    SharePool internal ethSharePool;
    ChildPeer internal ethChildPeer;
    HelperConfig internal ethConfig;
    HelperConfig.NetworkConfig internal ethNetworkConfig;
    uint64 internal ethChainSelector;
    ERC20 internal ethUsdc;
    USDCTokenPool internal ethUsdcTokenPool;
    IMessageTransmitter internal ethCCTPMessageTransmitter;

    address internal owner = makeAddr("owner");
    address internal depositor = makeAddr("depositor");
    address internal withdrawer = makeAddr("withdrawer");
    address[] internal attesters = new address[](4);
    address internal cctpAttester1;
    address internal cctpAttester2;
    address internal cctpAttester3;
    address internal cctpAttester4;
    uint256[] internal attesterPks = new uint256[](4);
    uint256 internal cctpAttesterPk1;
    uint256 internal cctpAttesterPk2;
    uint256 internal cctpAttesterPk3;
    uint256 internal cctpAttesterPk4;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/
    function setUp() public virtual {
        _deployInfra();
        _setPools();
        _setCrossChainPeers();
        _dealLinkToPeers();

        for (uint256 i = 0; i < attesters.length; i++) {
            (attesters[i], attesterPks[i]) = makeAddrAndKey(string.concat("attester", vm.toString(i)));
        }
        _setCCTPAttesters();
        _setDomains();

        _stopPrank();
    }

    function _deployInfra() internal {
        // Deploy on Arbitrum
        arbFork = vm.createSelectFork(ARBITRUM_MAINNET_RPC_URL);
        assertEq(block.chainid, ARBITRUM_MAINNET_CHAIN_ID);

        DeployParent arbDeployParent = new DeployParent();
        (arbShare, arbSharePool, arbParentPeer, arbConfig) = arbDeployParent.run();
        vm.makePersistent(address(arbShare));
        vm.makePersistent(address(arbSharePool));
        vm.makePersistent(address(arbParentPeer));

        arbNetworkConfig = arbConfig.getActiveNetworkConfig();
        arbChainSelector = arbNetworkConfig.thisChainSelector;
        arbUsdc = ERC20(arbNetworkConfig.usdc);
        arbUsdcTokenPool = USDCTokenPool(arbNetworkConfig.usdcTokenPool);
        arbCCTPMessageTransmitter = IMessageTransmitter(arbNetworkConfig.cctpMessageTransmitter);

        // Deploy on Optimism
        optFork = vm.createSelectFork(OPTIMISM_MAINNET_RPC_URL);
        assertEq(block.chainid, OPTIMISM_MAINNET_CHAIN_ID);

        DeployChild optDeployChild = new DeployChild();
        (optShare, optSharePool, optChildPeer, optConfig) = optDeployChild.run();
        vm.makePersistent(address(optShare));
        vm.makePersistent(address(optSharePool));
        vm.makePersistent(address(optChildPeer));

        optNetworkConfig = optConfig.getActiveNetworkConfig();
        optChainSelector = optNetworkConfig.thisChainSelector;
        optUsdc = ERC20(optNetworkConfig.usdc);
        optUsdcTokenPool = USDCTokenPool(optNetworkConfig.usdcTokenPool);
        optCCTPMessageTransmitter = IMessageTransmitter(optNetworkConfig.cctpMessageTransmitter);

        // Deploy on Ethereum
        ethFork = vm.createSelectFork(vm.envString("ETH_MAINNET_RPC_URL"));
        assertEq(block.chainid, ETHEREUM_MAINNET_CHAIN_ID);

        DeployChild ethDeployChild = new DeployChild();
        (ethShare, ethSharePool, ethChildPeer, ethConfig) = ethDeployChild.run();
        vm.makePersistent(address(ethShare));
        vm.makePersistent(address(ethSharePool));
        vm.makePersistent(address(ethChildPeer));

        ethNetworkConfig = ethConfig.getActiveNetworkConfig();
        ethChainSelector = ethNetworkConfig.thisChainSelector;
        ethUsdc = ERC20(ethNetworkConfig.usdc);
        ethUsdcTokenPool = USDCTokenPool(ethNetworkConfig.usdcTokenPool);
        ethCCTPMessageTransmitter = IMessageTransmitter(ethNetworkConfig.cctpMessageTransmitter);

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));
        _registerChains();
    }

    function _setPools() internal {
        uint64[] memory remoteChains = new uint64[](2);
        address[] memory remotePools = new address[](2);
        address[] memory remoteTokens = new address[](2);

        // Set up Arbitrum's pool to know about Optimism and Ethereum
        _selectFork(arbFork);
        remoteChains[0] = optChainSelector;
        remoteChains[1] = ethChainSelector;
        remotePools[0] = address(optChildPeer);
        remotePools[1] = address(ethChildPeer);
        remoteTokens[0] = address(optShare);
        remoteTokens[1] = address(ethShare);
        _applyChainUpdates(arbSharePool, remoteChains, remotePools, remoteTokens);
        _assertArraysEqual(arbSharePool.getSupportedChains(), remoteChains);
        assertEq(arbSharePool.isRemotePool(optChainSelector, abi.encode(address(optChildPeer))), true);
        assertEq(arbSharePool.isRemotePool(ethChainSelector, abi.encode(address(ethChildPeer))), true);
        assertEq(arbSharePool.getRemoteToken(optChainSelector), abi.encode(address(optShare)));
        assertEq(arbSharePool.getRemoteToken(ethChainSelector), abi.encode(address(ethShare)));

        // Set up Optimism's pool to know about Arbitrum and Ethereum
        _selectFork(optFork);
        remoteChains[0] = arbChainSelector;
        remoteChains[1] = ethChainSelector;
        remotePools[0] = address(arbParentPeer);
        remotePools[1] = address(ethChildPeer);
        remoteTokens[0] = address(arbShare);
        remoteTokens[1] = address(ethShare);
        _applyChainUpdates(optSharePool, remoteChains, remotePools, remoteTokens);
        _assertArraysEqual(optSharePool.getSupportedChains(), remoteChains);
        assertEq(optSharePool.isRemotePool(arbChainSelector, abi.encode(address(arbParentPeer))), true);
        assertEq(optSharePool.isRemotePool(ethChainSelector, abi.encode(address(ethChildPeer))), true);
        assertEq(optSharePool.getRemoteToken(arbChainSelector), abi.encode(address(arbShare)));
        assertEq(optSharePool.getRemoteToken(ethChainSelector), abi.encode(address(ethShare)));

        // Set up Ethereum's pool to know about Arbitrum and Optimism
        _selectFork(ethFork);
        remoteChains[0] = arbChainSelector;
        remoteChains[1] = optChainSelector;
        remotePools[0] = address(arbParentPeer);
        remotePools[1] = address(optChildPeer);
        remoteTokens[0] = address(arbShare);
        remoteTokens[1] = address(optShare);
        _applyChainUpdates(ethSharePool, remoteChains, remotePools, remoteTokens);
        _assertArraysEqual(ethSharePool.getSupportedChains(), remoteChains);
        assertEq(ethSharePool.isRemotePool(arbChainSelector, abi.encode(address(arbParentPeer))), true);
        assertEq(ethSharePool.isRemotePool(optChainSelector, abi.encode(address(optChildPeer))), true);
        assertEq(ethSharePool.getRemoteToken(arbChainSelector), abi.encode(address(arbShare)));
        assertEq(ethSharePool.getRemoteToken(optChainSelector), abi.encode(address(optShare)));
    }

    function _setCrossChainPeers() internal {
        _selectFork(arbFork);
        arbParentPeer.setCCIPGasLimit(INITIAL_CCIP_GAS_LIMIT);
        arbParentPeer.setAllowedChain(optChainSelector, true);
        arbParentPeer.setAllowedChain(ethChainSelector, true);
        arbParentPeer.setAllowedPeer(optChainSelector, address(optChildPeer));
        arbParentPeer.setAllowedPeer(ethChainSelector, address(ethChildPeer));
        assertEq(arbParentPeer.getAllowedChain(optChainSelector), true);
        assertEq(arbParentPeer.getAllowedChain(ethChainSelector), true);
        assertEq(arbParentPeer.getAllowedPeer(optChainSelector), address(optChildPeer));
        assertEq(arbParentPeer.getAllowedPeer(ethChainSelector), address(ethChildPeer));

        _selectFork(optFork);
        optChildPeer.setCCIPGasLimit(INITIAL_CCIP_GAS_LIMIT);
        optChildPeer.setAllowedChain(arbChainSelector, true);
        optChildPeer.setAllowedChain(ethChainSelector, true);
        optChildPeer.setAllowedPeer(arbChainSelector, address(arbParentPeer));
        optChildPeer.setAllowedPeer(ethChainSelector, address(ethChildPeer));
        assertEq(optChildPeer.getAllowedChain(arbChainSelector), true);
        assertEq(optChildPeer.getAllowedChain(ethChainSelector), true);
        assertEq(optChildPeer.getAllowedPeer(arbChainSelector), address(arbParentPeer));
        assertEq(optChildPeer.getAllowedPeer(ethChainSelector), address(ethChildPeer));

        _selectFork(ethFork);
        ethChildPeer.setCCIPGasLimit(INITIAL_CCIP_GAS_LIMIT);
        ethChildPeer.setAllowedChain(arbChainSelector, true);
        ethChildPeer.setAllowedChain(optChainSelector, true);
        ethChildPeer.setAllowedPeer(arbChainSelector, address(arbParentPeer));
        ethChildPeer.setAllowedPeer(optChainSelector, address(optChildPeer));
        assertEq(ethChildPeer.getAllowedChain(arbChainSelector), true);
        assertEq(ethChildPeer.getAllowedChain(optChainSelector), true);
        assertEq(ethChildPeer.getAllowedPeer(arbChainSelector), address(arbParentPeer));
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

    function _dealLinkToPeers() internal {
        _selectFork(arbFork);
        deal(arbParentPeer.getLink(), address(arbParentPeer), LINK_AMOUNT);

        _selectFork(optFork);
        deal(optChildPeer.getLink(), address(optChildPeer), LINK_AMOUNT);

        _selectFork(ethFork);
        deal(ethChildPeer.getLink(), address(ethChildPeer), LINK_AMOUNT);
    }

    function _registerChains() internal {
        // Set up Optimism network details using values from HelperConfig
        Register.NetworkDetails memory optimismDetails = Register.NetworkDetails({
            chainSelector: optChainSelector, // From HelperConfig
            routerAddress: optNetworkConfig.ccipRouter, // From HelperConfig
            linkAddress: optNetworkConfig.link, // From HelperConfig
            wrappedNativeAddress: address(0), // Not needed for testing
            ccipBnMAddress: address(0), // Not needed for testing
            ccipLnMAddress: address(0), // Not needed for testing
            rmnProxyAddress: address(0), // Not needed for testing
            registryModuleOwnerCustomAddress: address(0), // Not needed for testing
            tokenAdminRegistryAddress: address(0) // Not needed for testing
        });

        // Set the network details for Optimism
        ccipLocalSimulatorFork.setNetworkDetails(OPTIMISM_MAINNET_CHAIN_ID, optimismDetails);

        // Set up Arbitrum network details using values from HelperConfig
        Register.NetworkDetails memory arbitrumDetails = Register.NetworkDetails({
            chainSelector: arbChainSelector, // From HelperConfig
            routerAddress: arbNetworkConfig.ccipRouter, // From HelperConfig
            linkAddress: arbNetworkConfig.link, // From HelperConfig
            wrappedNativeAddress: address(0), // Not needed for testing
            ccipBnMAddress: address(0), // Not needed for testing
            ccipLnMAddress: address(0), // Not needed for testing
            rmnProxyAddress: address(0), // Not needed for testing
            registryModuleOwnerCustomAddress: address(0), // Not needed for testing
            tokenAdminRegistryAddress: address(0) // Not needed for testing
        });

        // Set the network details for Arbitrum
        ccipLocalSimulatorFork.setNetworkDetails(ARBITRUM_MAINNET_CHAIN_ID, arbitrumDetails);

        // Set up Ethereum network details using values from HelperConfig
        Register.NetworkDetails memory ethereumDetails = Register.NetworkDetails({
            chainSelector: ethChainSelector, // From HelperConfig
            routerAddress: ethNetworkConfig.ccipRouter, // From HelperConfig
            linkAddress: ethNetworkConfig.link, // From HelperConfig
            wrappedNativeAddress: address(0), // Not needed for testing
            ccipBnMAddress: address(0), // Not needed for testing
            ccipLnMAddress: address(0), // Not needed for testing
            rmnProxyAddress: address(0), // Not needed for testing
            registryModuleOwnerCustomAddress: address(0), // Not needed for testing
            tokenAdminRegistryAddress: address(0) // Not needed for testing
        });

        // Set the network details for Ethereum
        ccipLocalSimulatorFork.setNetworkDetails(ETHEREUM_MAINNET_CHAIN_ID, ethereumDetails);
    }

    function _setCCTPAttesters() internal {
        _selectFork(arbFork);
        _changePrank(arbCCTPMessageTransmitter.owner());
        arbCCTPMessageTransmitter.updateAttesterManager(attesters[0]);
        _changePrank(attesters[0]);
        for (uint256 i = 0; i < attesters.length; i++) {
            arbCCTPMessageTransmitter.enableAttester(attesters[i]);
        }
        arbCCTPMessageTransmitter.setSignatureThreshold(attesters.length);

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
            allowedCaller: bytes32(uint256(uint160(address(arbUsdcTokenPool)))),
            domainIdentifier: 3,
            destChainSelector: arbChainSelector,
            enabled: true
        });
        _selectFork(arbFork);
        _changePrank(arbUsdcTokenPool.owner());
        arbUsdcTokenPool.setDomains(domains);
        _selectFork(optFork);
        _changePrank(optUsdcTokenPool.owner());
        optUsdcTokenPool.setDomains(domains);
        _selectFork(ethFork);
        _changePrank(ethUsdcTokenPool.owner());
        ethUsdcTokenPool.setDomains(domains);
        _stopPrank();
    }

    // function _configureCCTPAllowedCallers() internal {
    //     // Configure Arbitrum's CCTP Message Transmitter Proxy
    //     _selectFork(arbFork);
    //     _changePrank(arbCCTPMessageTransmitterProxy.owner());
    //     CCTPMessageTransmitterProxy.AllowedCallerConfigArgs[] memory allowedCallerParams =
    //         new CCTPMessageTransmitterProxy.AllowedCallerConfigArgs[](1);
    //     allowedCallerParams[0] =
    //         CCTPMessageTransmitterProxy.AllowedCallerConfigArgs({caller: address(arbUsdcTokenPool), allowed: true});
    //     CCTPMessageTransmitterProxy(address(arbCCTPMessageTransmitterProxy)).configureAllowedCallers(
    //         allowedCallerParams
    //     );

    //     // Configure Optimism's CCTP Message Transmitter Proxy
    //     _selectFork(optFork);
    //     _changePrank(optCCTPMessageTransmitterProxy.owner());
    //     allowedCallerParams[0] =
    //         CCTPMessageTransmitterProxy.AllowedCallerConfigArgs({caller: address(optUsdcTokenPool), allowed: true});
    //     CCTPMessageTransmitterProxy(address(optCCTPMessageTransmitterProxy)).configureAllowedCallers(
    //         allowedCallerParams
    //     );

    //     // Configure Ethereum's CCTP Message Transmitter Proxy
    //     _selectFork(ethFork);
    //     _changePrank(ethCCTPMessageTransmitterProxy.owner());
    //     allowedCallerParams[0] =
    //         CCTPMessageTransmitterProxy.AllowedCallerConfigArgs({caller: address(ethUsdcTokenPool), allowed: true});
    //     CCTPMessageTransmitterProxy(address(ethCCTPMessageTransmitterProxy)).configureAllowedCallers(
    //         allowedCallerParams
    //     );

    //     _stopPrank();
    // }

    function test_baseTest() public {}

    /*//////////////////////////////////////////////////////////////
                                UTILITY
    //////////////////////////////////////////////////////////////*/
    function _changePrank(address newPrank) internal {
        vm.stopPrank();
        vm.startPrank(newPrank);
    }

    function _stopPrank() internal {
        vm.stopPrank();
    }

    function _selectFork(uint256 fork) internal {
        vm.selectFork(fork);
    }

    function _assertArraysEqual(uint64[] memory a, uint64[] memory b) internal pure {
        assertEq(a.length, b.length, "Array lengths do not match");
        for (uint256 i = 0; i < a.length; i++) {
            assertEq(a[i], b[i], string.concat("Arrays differ at index ", vm.toString(i)));
        }
    }

    function _getATokenAddress(address poolAddressesProvider, address underlyingToken)
        internal
        view
        returns (address)
    {
        address aavePool = IPoolAddressesProvider(poolAddressesProvider).getPool();
        DataTypes.ReserveData memory reserveData = IPool(aavePool).getReserveData(underlyingToken);
        return reserveData.aTokenAddress;
    }
}
