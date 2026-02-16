// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {console2} from "forge-std/Test.sol";
import {
    BaseTest,
    HelperConfig,
    ParentPeer,
    ChildPeer,
    Share,
    Rebalancer,
    StrategyRegistry,
    Roles,
    IERC20,
    IYieldPeer,
    IAccessControl,
    CREReceiver
} from "test/BaseTest.t.sol";
import {RebalancerProxy} from "src/proxies/RebalancerProxy.sol";
import {ShareProxy} from "src/proxies/ShareProxy.sol";
import {ParentProxy} from "src/proxies/ParentProxy.sol";
import {ChildProxy} from "src/proxies/ChildProxy.sol";
import {StrategyRegistryProxy} from "src/proxies/StrategyRegistryProxy.sol";
import {AaveV3Adapter} from "src/adapters/AaveV3Adapter.sol";
import {CompoundV3Adapter} from "src/adapters/CompoundV3Adapter.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";
import {IPoolAddressesProvider} from "@aave/v3-origin/src/contracts/interfaces/IPoolAddressesProvider.sol";
import {IComet} from "src/interfaces/IComet.sol";
import {MockCCIPRouter} from "@chainlink-local/test/mocks/MockRouter.sol";

import {ProxyHandler} from "./ProxyHandler.t.sol";
import {
    MockUpgradeParentPeer,
    MockUpgradeChildPeer,
    MockUpgradeShare,
    MockUpgradeRebalancer,
    MockUpgradeStrategyRegistry
} from "./mocks/MockUpgrade.sol";

contract ProxyInvariant is StdInvariant, BaseTest {
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    // Constants
    uint64 internal constant PARENT_SELECTOR = 1;
    uint64 internal constant CHILD1_SELECTOR = 2;
    uint64 internal constant CHILD2_SELECTOR = 3;
    uint256 internal constant STRATEGY_POOL_USDC_STARTING_BALANCE = 1_000_000_000_000_000_000; // 1T USDC
    /// @notice We are making the assumption that the gasLimit set for CCIP works correctly
    uint256 internal constant CCIP_GAS_LIMIT = 1_000_000;
    bytes32 internal constant AAVE_V3_PROTOCOL_ID = keccak256(abi.encodePacked("aave-v3"));
    bytes32 internal constant COMPOUND_V3_PROTOCOL_ID = keccak256(abi.encodePacked("compound-v3"));

    // Helper & Network Config
    HelperConfig internal helperConfig;
    HelperConfig.NetworkConfig internal networkConfig;

    // Handler, Rabalancer, Parent/Child Peers, Share
    ProxyHandler internal proxyHandler;
    Rebalancer internal rebalancer;
    ParentPeer internal parent;
    ChildPeer internal child1;
    ChildPeer internal child2;
    Share internal share;

    address internal parentInitialImpl;
    address internal child1InitialImpl;
    address internal child2InitialImpl;

    // USDC & Aave Pool
    IERC20 internal usdc;
    address internal aavePool;

    // Strategy registries
    StrategyRegistry internal strategyRegistryParent;
    StrategyRegistry internal strategyRegistryChild1;
    StrategyRegistry internal strategyRegistryChild2;

    // Adapters - Parent/Children
    AaveV3Adapter internal aaveV3Parent;
    AaveV3Adapter internal aaveV3Child1;
    AaveV3Adapter internal aaveV3Child2;
    CompoundV3Adapter internal compoundV3Parent;
    CompoundV3Adapter internal compoundV3Child1;
    CompoundV3Adapter internal compoundV3Child2;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/
    function setUp() public virtual override {
        // Deploy infra & grant roles
        _deployInfra();
        _grantRoles();

        // Deal Link, set cross chain configs & workflow
        _dealLinkToPeers(true, address(parent), address(child1), address(child2), networkConfig.tokens.link);
        _setCrossChainPeers();
        _setWorkflow();

        // Deploy Proxy Handler
        proxyHandler = new ProxyHandler(
            parent,
            child1,
            child2,
            share,
            rebalancer,
            strategyRegistryParent,
            strategyRegistryChild1,
            strategyRegistryChild2,
            usdc,
            aavePool,
            networkConfig.protocols.comet
        );

        // Create function selectors for Handler
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = ProxyHandler.deposit.selector;
        selectors[1] = ProxyHandler.withdraw.selector;
        selectors[2] = ProxyHandler.rebalance.selector;
        selectors[3] = ProxyHandler.setterInteraction.selector;
        selectors[4] = ProxyHandler.triggerRandomUpgrade.selector;

        // Target handler and appropriate function selectors
        targetSelector(FuzzSelector({addr: address(proxyHandler), selectors: selectors}));
        targetContract(address(proxyHandler));

        // Exclude contracts from direct call - must go through handler
        excludeContract(address(parent));
        excludeContract(address(child1));
        excludeContract(address(child2));
        excludeContract(address(share));
        excludeContract(address(rebalancer));
        excludeContract(address(strategyRegistryParent));
        excludeContract(address(strategyRegistryChild1));
        excludeContract(address(strategyRegistryChild2));
    }

    function _deployInfra() internal override {
        // Create HelperConfig and get network config
        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getActiveNetworkConfig();

        // Store usdc, share and aave pool address
        usdc = IERC20(networkConfig.tokens.usdc);
        share = Share(networkConfig.tokens.share);
        aavePool = IPoolAddressesProvider(networkConfig.protocols.aavePoolAddressesProvider).getPool();

        // Create Registry Impl (passed to deploy helpers)
        StrategyRegistry registryImpl = new StrategyRegistry();
        bytes memory registryInit = abi.encodeWithSelector(StrategyRegistry.initialize.selector);

        // Deploy Rebalancer, Parent/Children & Registries
        _deployRebalancer();
        _deployParent(address(registryImpl), registryInit);
        _deployChild1(address(registryImpl), registryInit);
        _deployChild2(address(registryImpl), registryInit);

        // Grant Share Rols to Proxies
        _changePrank(share.owner());
        share.grantMintAndBurnRoles(address(parent));
        share.grantMintAndBurnRoles(address(child1));
        share.grantMintAndBurnRoles(address(child2));
        _stopPrank();

        // Store admin
        owner = address(this);

        // Seed Pools
        deal(address(usdc), aavePool, STRATEGY_POOL_USDC_STARTING_BALANCE);
        deal(address(usdc), networkConfig.protocols.comet, STRATEGY_POOL_USDC_STARTING_BALANCE);
    }

    /// @dev _deployInfra:: Helper to deploy Rebalancer
    function _deployRebalancer() private {
        // Deploy Rebalancer Impl and create init data
        Rebalancer rebalancerImpl = new Rebalancer();
        bytes memory rebalancerInit = abi.encodeWithSelector(Rebalancer.initialize.selector);

        // Deploy Rebalancer Proxy and cast to Rebalancer type
        RebalancerProxy rebalancerProxy = new RebalancerProxy(address(rebalancerImpl), rebalancerInit);
        rebalancer = Rebalancer(address(rebalancerProxy));
    }

    /// @dev _deployInfra:: Helper to deploy ParentPeer
    /// @param registryImpl The strategy registry impl address
    /// @param registryInit The strategy registry init data
    function _deployParent(address registryImpl, bytes memory registryInit) private {
        // Deploy Parent Impl and create init data
        ParentPeer parentImpl = new ParentPeer(
            networkConfig.ccip.ccipRouter, networkConfig.tokens.link, PARENT_SELECTOR, address(usdc), address(share)
        );
        bytes memory parentInit = abi.encodeWithSelector(ParentPeer.initialize.selector);
        parentInitialImpl = address(parentImpl);

        // Deploy Parent Proxy and cast to ParentPeer type
        ParentProxy parentProxy = new ParentProxy(address(parentImpl), parentInit);
        parent = ParentPeer(address(parentProxy));

        // Connect Rebalancer & Parent
        parent.grantRole(Roles.CONFIG_ADMIN_ROLE, address(this));
        parent.setRebalancer(address(rebalancer));
        rebalancer.setParentPeer(address(parent));

        // Deploy Parent Registry Proxy and cast to StrategyRegistry type
        StrategyRegistryProxy strategyRegistryProxy = new StrategyRegistryProxy(registryImpl, registryInit);
        strategyRegistryParent = StrategyRegistry(address(strategyRegistryProxy));

        // Deploy adapters
        aaveV3Parent = new AaveV3Adapter(address(parent), networkConfig.protocols.aavePoolAddressesProvider);
        compoundV3Parent = new CompoundV3Adapter(address(parent), networkConfig.protocols.comet);

        // Configure Parent StrategyRegistry with adapters
        strategyRegistryParent.setStrategyAdapter(AAVE_V3_PROTOCOL_ID, address(aaveV3Parent));
        strategyRegistryParent.setStrategyAdapter(COMPOUND_V3_PROTOCOL_ID, address(compoundV3Parent));

        // Link Registry & set Initial Strategy
        rebalancer.setStrategyRegistry(address(strategyRegistryParent));
        parent.setStrategyRegistry(address(strategyRegistryParent));
        parent.setInitialActiveStrategy(keccak256(abi.encodePacked("aave-v3")));
        parent.revokeRole(Roles.CONFIG_ADMIN_ROLE, address(this));
    }

    /// @dev _deployInfra:: Helper to deploy ChildPeer 1
    /// @param registryImpl The strategy registry impl address
    /// @param registryInit The strategy registry init data
    function _deployChild1(address registryImpl, bytes memory registryInit) private {
        // Deploy Child Impl and create init data
        ChildPeer child1Impl = new ChildPeer(
            networkConfig.ccip.ccipRouter,
            networkConfig.tokens.link,
            CHILD1_SELECTOR,
            networkConfig.tokens.usdc,
            networkConfig.tokens.share,
            PARENT_SELECTOR
        );
        bytes memory child1Init = abi.encodeWithSelector(ChildPeer.initialize.selector);
        child1InitialImpl = address(child1Impl);

        // Deploy Child Proxy and cast to ChildPeer type
        ChildProxy childProxy = new ChildProxy(address(child1Impl), child1Init);
        child1 = ChildPeer(address(childProxy));

        // Deploy Child 1 Registry Proxy and cast to StrategyRegistry type
        StrategyRegistryProxy strategyRegistryProxy = new StrategyRegistryProxy(registryImpl, registryInit);
        strategyRegistryChild1 = StrategyRegistry(address(strategyRegistryProxy));

        // Deploy Adapters
        aaveV3Child1 = new AaveV3Adapter(address(child1), networkConfig.protocols.aavePoolAddressesProvider);
        compoundV3Child1 = new CompoundV3Adapter(address(child1), networkConfig.protocols.comet);

        // Configure Child 1
        child1.grantRole(Roles.CONFIG_ADMIN_ROLE, address(this));
        child1.setStrategyRegistry(address(strategyRegistryChild1));
        child1.revokeRole(Roles.CONFIG_ADMIN_ROLE, address(this));

        // Configure Child 1 StrategyRegistry with adapters
        strategyRegistryChild1.setStrategyAdapter(AAVE_V3_PROTOCOL_ID, address(aaveV3Child1));
        strategyRegistryChild1.setStrategyAdapter(COMPOUND_V3_PROTOCOL_ID, address(compoundV3Child1));
    }

    /// @dev _deployInfra:: Helper to deploy ChildPeer 2
    /// @param registryImpl The strategy registry impl address
    /// @param registryInit The strategy registry init data
    function _deployChild2(address registryImpl, bytes memory registryInit) private {
        // Deploy Child Impl and create init data
        ChildPeer child2Impl = new ChildPeer(
            networkConfig.ccip.ccipRouter,
            networkConfig.tokens.link,
            CHILD2_SELECTOR,
            networkConfig.tokens.usdc,
            networkConfig.tokens.share,
            PARENT_SELECTOR
        );
        bytes memory child2Init = abi.encodeWithSelector(ChildPeer.initialize.selector);
        child2InitialImpl = address(child2Impl);

        // Deploy Child Proxy and cast to ChildPeer type
        ChildProxy childProxy = new ChildProxy(address(child2Impl), child2Init);
        child2 = ChildPeer(address(childProxy));

        // Deploy Child 2 Registry Proxy and cast to StrategyRegistry type
        StrategyRegistryProxy strategyRegistryProxy = new StrategyRegistryProxy(registryImpl, registryInit);
        strategyRegistryChild2 = StrategyRegistry(address(strategyRegistryProxy));

        // Deploy Adapters
        aaveV3Child2 = new AaveV3Adapter(address(child2), networkConfig.protocols.aavePoolAddressesProvider);
        compoundV3Child2 = new CompoundV3Adapter(address(child2), networkConfig.protocols.comet);

        // Configure Child 2
        child2.grantRole(Roles.CONFIG_ADMIN_ROLE, address(this));
        child2.setStrategyRegistry(address(strategyRegistryChild2));
        child2.revokeRole(Roles.CONFIG_ADMIN_ROLE, address(this));

        // Configure Child 2 StrategyRegistry with adapters
        strategyRegistryChild2.setStrategyAdapter(AAVE_V3_PROTOCOL_ID, address(aaveV3Child2));
        strategyRegistryChild2.setStrategyAdapter(COMPOUND_V3_PROTOCOL_ID, address(compoundV3Child2));
    }

    /// @dev Grants custom roles on all chains (simulated locally)
    function _grantRoles() internal override {
        _grantRolesToPeer(parent, parent.owner());
        _grantRolesToPeer(child1, child1.owner());
        _grantRolesToPeer(child2, child2.owner());
        _stopPrank();
    }

    /// @dev _grantRoles:: Helper to grant roles to a specific peer
    /// @param peer The peer to grant roles for
    /// @param peerOwner The owner of the peer (passed explicitly as IYieldPeer might not expose owner())
    function _grantRolesToPeer(IYieldPeer peer, address peerOwner) private {
        _changePrank(peerOwner);

        // Cast peer to IAccessControl to access role functions
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

    function _setCrossChainPeers() internal override {
        /// @dev temp cross chain admin roles granted to set cross chain configs
        parent.grantRole(Roles.CROSS_CHAIN_ADMIN_ROLE, parent.owner());
        child1.grantRole(Roles.CROSS_CHAIN_ADMIN_ROLE, child1.owner());
        child2.grantRole(Roles.CROSS_CHAIN_ADMIN_ROLE, child2.owner());

        // Set CCIP Gas Limit
        parent.setCCIPGasLimit(CCIP_GAS_LIMIT);
        child1.setCCIPGasLimit(CCIP_GAS_LIMIT);
        child2.setCCIPGasLimit(CCIP_GAS_LIMIT);

        // Parent - Set allowed chains and peers
        parent.setAllowedChain(PARENT_SELECTOR, true);
        parent.setAllowedChain(CHILD1_SELECTOR, true);
        parent.setAllowedChain(CHILD2_SELECTOR, true);
        parent.setAllowedPeer(PARENT_SELECTOR, address(parent));
        parent.setAllowedPeer(CHILD1_SELECTOR, address(child1));
        parent.setAllowedPeer(CHILD2_SELECTOR, address(child2));

        // Child 1 - Set allowed chains and peers
        child1.setAllowedChain(PARENT_SELECTOR, true);
        child1.setAllowedChain(CHILD1_SELECTOR, true);
        child1.setAllowedChain(CHILD2_SELECTOR, true);
        child1.setAllowedPeer(PARENT_SELECTOR, address(parent));
        child1.setAllowedPeer(CHILD1_SELECTOR, address(child1));
        child1.setAllowedPeer(CHILD2_SELECTOR, address(child2));

        // Child 2 - Set allowed chains and peers
        child2.setAllowedChain(PARENT_SELECTOR, true);
        child2.setAllowedChain(CHILD1_SELECTOR, true);
        child2.setAllowedChain(CHILD2_SELECTOR, true);
        child2.setAllowedPeer(PARENT_SELECTOR, address(parent));
        child2.setAllowedPeer(CHILD1_SELECTOR, address(child1));
        child2.setAllowedPeer(CHILD2_SELECTOR, address(child2));

        /// @dev Revoke temp cross chain admin role
        parent.revokeRole(Roles.CROSS_CHAIN_ADMIN_ROLE, parent.owner());
        child1.revokeRole(Roles.CROSS_CHAIN_ADMIN_ROLE, child1.owner());
        child2.revokeRole(Roles.CROSS_CHAIN_ADMIN_ROLE, child2.owner());

        // Set MockCCIPRouter Config
        MockCCIPRouter(networkConfig.ccip.ccipRouter).setPeerToChainSelector(address(parent), PARENT_SELECTOR);
        MockCCIPRouter(networkConfig.ccip.ccipRouter).setPeerToChainSelector(address(child1), CHILD1_SELECTOR);
        MockCCIPRouter(networkConfig.ccip.ccipRouter).setPeerToChainSelector(address(child2), CHILD2_SELECTOR);
    }

    function _setWorkflow() internal {
        _changePrank(rebalancer.owner());
        rebalancer.setWorkflow(workflowId, workflowOwner, workflowName);
        _stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                               INVARIANTS
    //////////////////////////////////////////////////////////////*/
    function invariant_proxy_implementations_are_locked() public view {
        // Now a simple check against the ghost variable
        assertFalse(
            proxyHandler.ghost_implementation_was_unlocked(),
            "CRITICAL: An implementation contract was deployed without _disableInitializers!"
        );
    }

    function invariant_proxy_unauthorized_upgrade_not_allowed() public view {
        assertTrue(!proxyHandler.ghost_unauthorized_upgrade_success(), "Unauthorized Upgrade Succeeded");
    }

    function invariant_proxy_noDeposit_noWithdraw_whilePaused() public view virtual {
        assertFalse(proxyHandler.ghost_withdrewWhile_paused());
        assertFalse(proxyHandler.ghost_depositedWhile_paused());
    }

    function invariant_proxy_noDirection_call() public view virtual {
        assertFalse(proxyHandler.ghost_depositedInto_impl());
        assertFalse(proxyHandler.ghost_withdrawFrom_impl());
    }

    function invariant_proxy_fee_configuration_integrity() public view virtual {
        assertTrue(parent.getFeeRate() <= parent.getMaxFeeRate(), "Parent: Fee Corruption");
        assertTrue(child1.getFeeRate() <= child1.getMaxFeeRate(), "Child1: Fee Corruption");
    }

    function invariant_proxy_solvency_totalShares_sync() public view {
        assertEq(
            parent.getTotalShares(),
            share.totalSupply(),
            "CRITICAL: Parent Peer accounting and Share Token supply are out of sync!"
        );

        assertEq(
            parent.getTotalShares(),
            proxyHandler.ghost_parent_totalShares(),
            "Parent: Total shares accounting does not match expected ghost state"
        );
    }

    function invariant_proxy_pausable_state_consistency() public view {
        // Get the expected state from the handler
        bool expectedPauseState = proxyHandler.ghost_state_paused();

        // Ensure all contracts reflect this state
        // If one is paused and another is not, the system is in an invalid fractured state
        assertEq(parent.paused(), expectedPauseState, "Parent: Pause state mismatch");
        assertEq(child1.paused(), expectedPauseState, "Child 1: Pause state mismatch");
        assertEq(child2.paused(), expectedPauseState, "Child 2: Pause state mismatch");

        // Also verify the fee module (inherited) is paused
        // Since YieldFees inherits PausableWithAccessControl, checking .paused() on the contract covers it,
        // but this verifies the inheritance structure didn't break.
    }

    function invariant_proxy_ccip_configuration_integrity() public view {
        // Verify Parent Configuration
        assertTrue(parent.getAllowedChain(CHILD1_SELECTOR), "Parent: Should allow Child 1 Chain");
        assertTrue(parent.getAllowedChain(CHILD2_SELECTOR), "Parent: Should allow Child 2 Chain");
        assertEq(parent.getAllowedPeer(CHILD1_SELECTOR), address(child1), "Parent: Incorrect Peer for Child 1");
        assertEq(parent.getAllowedPeer(CHILD2_SELECTOR), address(child2), "Parent: Incorrect Peer for Child 2");

        // Verify Child 1 Configuration
        assertTrue(child1.getAllowedChain(PARENT_SELECTOR), "Child 1: Should allow Parent Chain");
        // Child 1 might communicate with Child 2 depending on your rebalance logic, verifying Parent is critical
        assertEq(child1.getAllowedPeer(PARENT_SELECTOR), address(parent), "Child 1: Incorrect Peer for Parent");

        // Verify Child 2 Configuration
        assertTrue(child2.getAllowedChain(PARENT_SELECTOR), "Child 2: Should allow Parent Chain");
        assertEq(child2.getAllowedPeer(PARENT_SELECTOR), address(parent), "Child 2: Incorrect Peer for Parent");

        // Verify Ghost Sync (Did we lose the config during an upgrade?)
        if (proxyHandler.ghost_parent_upgradeCount() > 0) {
            assertEq(
                parent.getCCIPGasLimit(), proxyHandler.ghost_parent_ccipGasLimit(), "Parent: CCIP Gas Limit corrupted"
            );
        }
        if (proxyHandler.ghost_child1_upgradeCount() > 0) {
            assertEq(
                child1.getCCIPGasLimit(), proxyHandler.ghost_child1_ccipGasLimit(), "Child 1: CCIP Gas Limit corrupted"
            );
        }
    }

    function invariant_proxy_distributed_state_integrity() public view virtual {
        IYieldPeer.Strategy memory strategy = parent.getStrategy();

        // 1. Check Upgrade Integrity (Ghosts)
        if (proxyHandler.ghost_parent_upgradeCount() > 0) {
            assertEq(
                parent.getActiveStrategyAdapter(),
                proxyHandler.ghost_parent_activeStrategyAdapter(),
                "Parent Active Strategy Corrupted"
            );
        }
        if (proxyHandler.ghost_child1_upgradeCount() > 0) {
            assertEq(
                child1.getActiveStrategyAdapter(),
                proxyHandler.ghost_child1_activeStrategyAdapter(),
                "Child1 Active Strategy Corrupted"
            );
        }
        if (proxyHandler.ghost_child2_upgradeCount() > 0) {
            assertEq(
                child2.getActiveStrategyAdapter(),
                proxyHandler.ghost_child2_activeStrategyAdapter(),
                "Child2 Active Strategy Corrupted"
            );
        }

        // 2. Check Logical Integrity (Multi-Chain Registry Check)
        // If Parent says strategy is on Chain X, Peer X must have a valid adapter set.
        if (strategy.chainSelector == PARENT_SELECTOR) {
            assertTrue(parent.getActiveStrategyAdapter() != address(0), "Parent: Adapter 0 on active strategy chain");
            address expected = strategyRegistryParent.getStrategyAdapter(strategy.protocolId);
            assertEq(parent.getActiveStrategyAdapter(), expected, "Parent: Active adapter mismatch with Registry");
        } else if (strategy.chainSelector == CHILD1_SELECTOR) {
            assertTrue(child1.getActiveStrategyAdapter() != address(0), "Child1: Adapter 0 on active strategy chain");
            address expected = strategyRegistryChild1.getStrategyAdapter(strategy.protocolId);
            assertEq(child1.getActiveStrategyAdapter(), expected, "Child1: Active adapter mismatch with Registry");
        } else if (strategy.chainSelector == CHILD2_SELECTOR) {
            assertTrue(child2.getActiveStrategyAdapter() != address(0), "Child2: Adapter 0 on active strategy chain");
            address expected = strategyRegistryChild2.getStrategyAdapter(strategy.protocolId);
            assertEq(child2.getActiveStrategyAdapter(), expected, "Child2: Active adapter mismatch with Registry");
        }
    }

    function invariant_proxy_role_persistence() public view {
        // We iterate through all contracts to ensure role tables weren't wiped
        address[3] memory contracts = [address(parent), address(child1), address(child2)];
        string[3] memory labels = ["Parent", "Child1", "Child2"];

        for (uint256 i = 0; i < 3; i++) {
            IAccessControl accessControl = IAccessControl(contracts[i]);
            string memory label = labels[i];

            // 1. Check Default Admin (Owner)
            // Note: In your setup, the 'owner' (this contract) holds the DEFAULT_ADMIN_ROLE
            assertTrue(accessControl.hasRole(0x00, address(this)), string.concat(label, ": DEFAULT_ADMIN_ROLE lost"));

            // 2. Check Emergency Pauser
            assertTrue(
                accessControl.hasRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser),
                string.concat(label, ": EMERGENCY_PAUSER_ROLE lost")
            );

            // 3. Check Emergency Unpauser
            assertTrue(
                accessControl.hasRole(Roles.EMERGENCY_UNPAUSER_ROLE, emergencyUnpauser),
                string.concat(label, ": EMERGENCY_UNPAUSER_ROLE lost")
            );

            // 4. Check Config Admin
            assertTrue(
                accessControl.hasRole(Roles.CONFIG_ADMIN_ROLE, configAdmin),
                string.concat(label, ": CONFIG_ADMIN_ROLE lost")
            );

            // 5. Check Cross Chain Admin
            assertTrue(
                accessControl.hasRole(Roles.CROSS_CHAIN_ADMIN_ROLE, crossChainAdmin),
                string.concat(label, ": CROSS_CHAIN_ADMIN_ROLE lost")
            );

            // 6. Check Fee Roles
            assertTrue(
                accessControl.hasRole(Roles.FEE_WITHDRAWER_ROLE, feeWithdrawer),
                string.concat(label, ": FEE_WITHDRAWER_ROLE lost")
            );
            assertTrue(
                accessControl.hasRole(Roles.FEE_RATE_SETTER_ROLE, feeRateSetter),
                string.concat(label, ": FEE_RATE_SETTER_ROLE lost")
            );

            // 7. Check Upgrader Role (Specific to UUPS safety)
            // In your setup, 'owner' (this contract) usually holds this initially
            assertTrue(
                accessControl.hasRole(Roles.UPGRADER_ROLE, address(this)), string.concat(label, ": UPGRADER_ROLE lost")
            );
        }
    }

    function invariant_proxy_parent_storage_integrity_post_upgrade() public view virtual {
        // Only run checks if at least one upgrade has occurred
        if (proxyHandler.ghost_parent_upgradeCount() > 0) {
            // --- 1. Core Yield State ---
            // Verify Strategy Struct components
            IYieldPeer.Strategy memory currentStrategy = parent.getStrategy();
            assertEq(
                currentStrategy.chainSelector,
                proxyHandler.ghost_parent_strategy_chainSelector(),
                "Parent: Strategy ChainSelector mismatch"
            );
            assertEq(
                currentStrategy.protocolId,
                proxyHandler.ghost_parent_strategy_protocolId(),
                "Parent: Strategy ProtocolID mismatch"
            );

            assertEq(
                parent.getActiveStrategyAdapter(),
                proxyHandler.ghost_parent_activeStrategyAdapter(),
                "Parent: Active Adapter mismatch"
            );

            // --- 2. Financial & Admin State ---
            assertEq(parent.getTotalShares(), proxyHandler.ghost_parent_totalShares(), "Parent: TotalShares mismatch");
            assertEq(parent.getFeeRate(), proxyHandler.ghost_parent_feeRate(), "Parent: FeeRate mismatch");
            assertEq(parent.getRebalancer(), proxyHandler.ghost_parent_rebalancer(), "Parent: Rebalancer mismatch");

            // --- 3. Low-Level Storage Check (initialActiveStrategySet) ---
            // We verify the raw storage slot matches the boolean ghost we saved
            bytes32 parentStorageLocation = 0x603686382b15940b5fa7ef449162bde228a5948ce3b6bdf08bd833ec6ae79500;
            bytes32 initialSetSlot = bytes32(uint256(parentStorageLocation) + 2);
            bool currentInitialSet = vm.load(address(parent), initialSetSlot) != bytes32(0);

            assertEq(
                currentInitialSet,
                proxyHandler.ghost_parent_initialActiveStrategySet(),
                "Parent: InitialStrategySet storage slot mismatch"
            );

            // --- 4. Peer Configuration ---
            assertEq(
                parent.getStrategyRegistry(),
                proxyHandler.ghost_parent_strategyRegistry(),
                "Parent: StrategyRegistry mismatch"
            );
            assertEq(
                parent.getCCIPGasLimit(), proxyHandler.ghost_parent_ccipGasLimit(), "Parent: CCIP GasLimit mismatch"
            );
            assertEq(parent.paused(), proxyHandler.ghost_parent_paused(), "Parent: Paused state mismatch");

            // --- 5. Allowed Chains & Peers ---
            // Using literals 2 and 3 for child chain selectors based on your Handler constants
            uint64 child1Chain = 2;
            uint64 child2Chain = 3;

            assertEq(
                parent.getAllowedChain(child1Chain),
                proxyHandler.ghost_parent_allowedChain1(),
                "Parent: AllowedChain (Child1) mismatch"
            );
            assertEq(
                parent.getAllowedChain(child2Chain),
                proxyHandler.ghost_parent_allowedChain2(),
                "Parent: AllowedChain (Child2) mismatch"
            );

            assertEq(
                parent.getAllowedPeer(child1Chain),
                proxyHandler.ghost_parent_allowedPeer1(),
                "Parent: AllowedPeer (Child1) mismatch"
            );
            assertEq(
                parent.getAllowedPeer(child2Chain),
                proxyHandler.ghost_parent_allowedPeer2(),
                "Parent: AllowedPeer (Child2) mismatch"
            );

            // --- 6. Upgrade Persistence (Mock Verification) ---
            try MockUpgradeParentPeer(payable(address(parent))).version() returns (uint64 v) {
                assertEq(v, proxyHandler.ghost_parent_version(), "Parent: Version check failed");
            } catch {
                assertTrue(false, "Parent: Call to version() failed on upgraded contract");
            }

            // Verify the new storage variable persisted
            try MockUpgradeParentPeer(payable(address(parent))).getNewVal() returns (uint256 val) {
                assertEq(val, proxyHandler.ghost_parent_newVal(), "Parent: NewVal mismatch");
            } catch {
                assertTrue(false, "Parent: Call to getNewVal() failed on upgraded contract");
            }
        }
    }

    function invariant_proxy_children_storage_integrity_post_upgrade() public view virtual {
        // Defined constants for clarity matching Handler
        uint64 parentChain = 1;
        uint64 child1Chain = 2;
        uint64 child2Chain = 3;

        // --- CHECK 1: Child 1 State ---
        if (proxyHandler.ghost_child1_upgradeCount() > 0) {
            // Configuration & State
            assertEq(
                child1.getParentChainSelector(),
                proxyHandler.ghost_child1_parentChainSelector(),
                "Child1: ParentChainSelector mismatch"
            );
            assertEq(child1.getFeeRate(), proxyHandler.ghost_child1_feeRate(), "Child1: FeeRate mismatch");
            assertEq(
                child1.getActiveStrategyAdapter(),
                proxyHandler.ghost_child1_activeStrategyAdapter(),
                "Child1: ActiveStrategyAdapter mismatch"
            );
            assertEq(
                child1.getStrategyRegistry(),
                proxyHandler.ghost_child1_strategyRegistry(),
                "Child1: StrategyRegistry mismatch"
            );
            assertEq(child1.paused(), proxyHandler.ghost_child1_paused(), "Child1: Paused state mismatch");
            assertEq(
                child1.getCCIPGasLimit(), proxyHandler.ghost_child1_ccipGasLimit(), "Child1: CCIP GasLimit mismatch"
            );

            // Allowed Chains & Peers (Child1 checks Parent(1) and Child2(3))
            assertEq(
                child1.getAllowedChain(parentChain),
                proxyHandler.ghost_child1_allowedChain1(),
                "Child1: AllowedChain (Parent) mismatch"
            );
            assertEq(
                child1.getAllowedChain(child2Chain),
                proxyHandler.ghost_child1_allowedChain2(),
                "Child1: AllowedChain (Child2) mismatch"
            );

            assertEq(
                child1.getAllowedPeer(parentChain),
                proxyHandler.ghost_child1_allowedPeer1(),
                "Child1: AllowedPeer (Parent) mismatch"
            );
            assertEq(
                child1.getAllowedPeer(child2Chain),
                proxyHandler.ghost_child1_allowedPeer2(),
                "Child1: AllowedPeer (Child2) mismatch"
            );

            // Upgrade Verification
            try MockUpgradeChildPeer(payable(address(child1))).version() returns (uint64 v) {
                assertEq(v, proxyHandler.ghost_child1_version(), "Child1: Version check failed");
            } catch {
                assertTrue(false, "Child1: Call to version() failed on upgraded contract");
            }

            try MockUpgradeChildPeer(payable(address(child1))).getNewVal() returns (uint256 val) {
                assertEq(val, proxyHandler.ghost_child1_newVal(), "Child1: NewVal mismatch");
            } catch {
                assertTrue(false, "Child1: Call to getNewVal() failed on upgraded contract");
            }
        }

        // --- CHECK 2: Child 2 State ---
        if (proxyHandler.ghost_child2_upgradeCount() > 0) {
            // Configuration & State
            assertEq(
                child2.getParentChainSelector(),
                proxyHandler.ghost_child2_parentChainSelector(),
                "Child2: ParentChainSelector mismatch"
            );
            assertEq(child2.getFeeRate(), proxyHandler.ghost_child2_feeRate(), "Child2: FeeRate mismatch");
            assertEq(
                child2.getActiveStrategyAdapter(),
                proxyHandler.ghost_child2_activeStrategyAdapter(),
                "Child2: ActiveStrategyAdapter mismatch"
            );
            assertEq(
                child2.getStrategyRegistry(),
                proxyHandler.ghost_child2_strategyRegistry(),
                "Child2: StrategyRegistry mismatch"
            );
            assertEq(child2.paused(), proxyHandler.ghost_child2_paused(), "Child2: Paused state mismatch");
            assertEq(
                child2.getCCIPGasLimit(), proxyHandler.ghost_child2_ccipGasLimit(), "Child2: CCIP GasLimit mismatch"
            );

            // Allowed Chains & Peers (Child2 checks Parent(1) and Child1(2))
            assertEq(
                child2.getAllowedChain(parentChain),
                proxyHandler.ghost_child2_allowedChain1(),
                "Child2: AllowedChain (Parent) mismatch"
            );
            assertEq(
                child2.getAllowedChain(child1Chain),
                proxyHandler.ghost_child2_allowedChain2(),
                "Child2: AllowedChain (Child1) mismatch"
            );

            assertEq(
                child2.getAllowedPeer(parentChain),
                proxyHandler.ghost_child2_allowedPeer1(),
                "Child2: AllowedPeer (Parent) mismatch"
            );
            assertEq(
                child2.getAllowedPeer(child1Chain),
                proxyHandler.ghost_child2_allowedPeer2(),
                "Child2: AllowedPeer (Child1) mismatch"
            );

            // Upgrade Verification
            try MockUpgradeChildPeer(payable(address(child2))).version() returns (uint64 v) {
                assertEq(v, proxyHandler.ghost_child2_version(), "Child2: Version check failed");
            } catch {
                assertTrue(false, "Child2: Call to version() failed on upgraded contract");
            }

            try MockUpgradeChildPeer(payable(address(child2))).getNewVal() returns (uint256 val) {
                assertEq(val, proxyHandler.ghost_child2_newVal(), "Child2: NewVal mismatch");
            } catch {
                assertTrue(false, "Child2: Call to getNewVal() failed on upgraded contract");
            }
        }
    }

    function invariant_proxy_share_storage_integrity_post_upgrade() public view virtual {
        // Only run checks if at least one upgrade has occurred
        if (proxyHandler.ghost_share_upgradeCount() > 0) {
            // --- 1. Basic Token Metadata & Supply ---
            assertEq(share.totalSupply(), proxyHandler.ghost_share_totalSupply(), "Share: TotalSupply mismatch");
            assertEq(share.name(), proxyHandler.ghost_share_name(), "Share: Name mismatch");
            assertEq(share.symbol(), proxyHandler.ghost_share_symbol(), "Share: Symbol mismatch");
            assertEq(share.decimals(), proxyHandler.ghost_share_decimals(), "Share: Decimals mismatch");

            // --- 2. Administrative Roles ---
            assertEq(address(share.getCCIPAdmin()), proxyHandler.ghost_share_ccipAdmin(), "Share: CCIP Admin mismatch");

            // --- 3. User Balances ---
            // We retrieve the superUser address from the handler to ensure we check the right account
            address superUser = proxyHandler.superUser();
            assertEq(
                share.balanceOf(superUser), proxyHandler.ghost_share_balance(), "Share: SuperUser Balance mismatch"
            );

            // --- 4. User Allowances ---
            // Check allowance for Parent
            assertEq(
                share.allowance(superUser, address(parent)),
                proxyHandler.ghost_share_allowance_parent(),
                "Share: Allowance (Parent) mismatch"
            );

            // Check allowance for Child 1
            assertEq(
                share.allowance(superUser, address(child1)),
                proxyHandler.ghost_share_allowance_child1(),
                "Share: Allowance (Child1) mismatch"
            );

            // Check allowance for Child 2
            assertEq(
                share.allowance(superUser, address(child2)),
                proxyHandler.ghost_share_allowance_child2(),
                "Share: Allowance (Child2) mismatch"
            );

            // --- 5. Upgrade Specific Logic (Mock Verification) ---
            // Verify the version bumped correctly
            try MockUpgradeShare(payable(address(share))).version() returns (uint64 v) {
                assertEq(v, proxyHandler.ghost_share_version(), "Share: Version check failed");
            } catch {
                // Using assertTrue(false, ...) allows you to keep the error message
                assertTrue(false, "Share: Call to version() failed on upgraded contract");
            }

            // Verify the new storage variable (newVal) persisted
            try MockUpgradeShare(payable(address(share))).getNewVal() returns (uint256 val) {
                assertEq(val, proxyHandler.ghost_share_newVal(), "Share: NewVal mismatch");
            } catch {
                assertTrue(false, "Share: Call to getNewVal() failed on upgraded contract");
            }
        }
    }

    function invariant_proxy_rebalancer_storage_integrity_post_upgrade() public view virtual {
        // Define the ID locally to ensure we query the correct mapping slot
        bytes32 workflowId = bytes32("rebalanceWorkflowId");

        // Only run checks if at least one upgrade has occurred
        if (proxyHandler.ghost_rebalancer_upgradeCount() > 0) {
            // --- 1. System Configuration Checks ---
            assertEq(
                rebalancer.getKeystoneForwarder(),
                proxyHandler.ghost_rebalancer_forwarder(),
                "Rebalancer: Keystone Forwarder mismatch"
            );

            assertEq(
                address(rebalancer.getParentPeer()),
                proxyHandler.ghost_rebalancer_parentPeer(),
                "Rebalancer: ParentPeer mismatch"
            );

            assertEq(
                address(rebalancer.getStrategyRegistry()),
                proxyHandler.ghost_rebalancer_strategyRegistry(),
                "Rebalancer: StrategyRegistry mismatch"
            );

            // --- 2. Workflow Storage Checks ---
            // Retrieve the struct from the contract to verify integrity
            CREReceiver.Workflow memory currentWorkflow = rebalancer.getWorkflow(workflowId);

            assertEq(
                currentWorkflow.owner,
                proxyHandler.ghost_rebalancer_workflowOwner(),
                "Rebalancer: Workflow Owner mismatch"
            );

            assertEq(
                currentWorkflow.name, proxyHandler.ghost_rebalancer_workflowName(), "Rebalancer: Workflow Name mismatch"
            );

            // --- 3. Upgrade Persistence (Mock Verification) ---
            // Verify version bumped correctly (to 2)
            try MockUpgradeRebalancer(payable(address(rebalancer))).version() returns (uint64 v) {
                assertEq(v, proxyHandler.ghost_rebalancer_version(), "Rebalancer: Version check failed");
            } catch {
                assertTrue(false, "Rebalancer: Call to version() failed on upgraded contract");
            }

            // Verify the new storage variable persisted
            try MockUpgradeRebalancer(payable(address(rebalancer))).getNewVal() returns (uint256 val) {
                assertEq(val, proxyHandler.ghost_rebalancer_newVal(), "Rebalancer: NewVal mismatch");
            } catch {
                assertTrue(false, "Rebalancer: Call to getNewVal() failed on upgraded contract");
            }
        }
    }

    function invariant_proxy_registry_storage_integrity_post_upgrade() public view virtual {
        // Define IDs locally to verify against the source of truth
        bytes32 aaveId = keccak256(abi.encodePacked("aave-v3"));
        bytes32 compoundId = keccak256(abi.encodePacked("compound-v3"));

        // --- CHECK 1: Parent Registry ---
        if (proxyHandler.ghost_registryParent_upgradeCount() > 0) {
            // Check Aave Adapter Integrity
            assertEq(
                strategyRegistryParent.getStrategyAdapter(aaveId),
                proxyHandler.ghost_registryParent_aaveV3_adapter(),
                "Registry Parent: AaveV3 Adapter mismatch"
            );

            // Check Compound Adapter Integrity
            assertEq(
                strategyRegistryParent.getStrategyAdapter(compoundId),
                proxyHandler.ghost_registryParent_compoundV3_adapter(),
                "Registry Parent: CompoundV3 Adapter mismatch"
            );

            // Check Upgrade Persistence (Version)
            try MockUpgradeStrategyRegistry(payable(address(strategyRegistryParent))).version() returns (uint64 v) {
                assertEq(v, proxyHandler.ghost_registryParent_version(), "Registry Parent: Version mismatch");
            } catch {
                assertTrue(false, "Registry Parent: Call to version() failed");
            }

            // Check Upgrade Persistence (New Value)
            try MockUpgradeStrategyRegistry(payable(address(strategyRegistryParent))).getNewVal() returns (
                uint256 val
            ) {
                assertEq(val, proxyHandler.ghost_registryParent_newVal(), "Registry Parent: NewVal mismatch");
            } catch {
                assertTrue(false, "Registry Parent: Call to getNewVal() failed");
            }
        }

        // --- CHECK 2: Child1 Registry ---
        if (proxyHandler.ghost_registryChild1_upgradeCount() > 0) {
            assertEq(
                strategyRegistryChild1.getStrategyAdapter(aaveId),
                proxyHandler.ghost_registryChild1_aaveV3_adapter(),
                "Registry Child1: AaveV3 Adapter mismatch"
            );
            assertEq(
                strategyRegistryChild1.getStrategyAdapter(compoundId),
                proxyHandler.ghost_registryChild1_compoundV3_adapter(),
                "Registry Child1: CompoundV3 Adapter mismatch"
            );

            try MockUpgradeStrategyRegistry(payable(address(strategyRegistryChild1))).version() returns (uint64 v) {
                assertEq(v, proxyHandler.ghost_registryChild1_version(), "Registry Child1: Version mismatch");
            } catch {
                assertTrue(false, "Registry Child1: Call to version() failed");
            }

            try MockUpgradeStrategyRegistry(payable(address(strategyRegistryChild1))).getNewVal() returns (
                uint256 val
            ) {
                assertEq(val, proxyHandler.ghost_registryChild1_newVal(), "Registry Child1: NewVal mismatch");
            } catch {
                assertTrue(false, "Registry Child1: Call to getNewVal() failed");
            }
        }

        // --- CHECK 3: Child2 Registry ---
        if (proxyHandler.ghost_registryChild2_upgradeCount() > 0) {
            assertEq(
                strategyRegistryChild2.getStrategyAdapter(aaveId),
                proxyHandler.ghost_registryChild2_aaveV3_adapter(),
                "Registry Child2: AaveV3 Adapter mismatch"
            );
            assertEq(
                strategyRegistryChild2.getStrategyAdapter(compoundId),
                proxyHandler.ghost_registryChild2_compoundV3_adapter(),
                "Registry Child2: CompoundV3 Adapter mismatch"
            );

            try MockUpgradeStrategyRegistry(payable(address(strategyRegistryChild2))).version() returns (uint64 v) {
                assertEq(v, proxyHandler.ghost_registryChild2_version(), "Registry Child2: Version mismatch");
            } catch {
                assertTrue(false, "Registry Child2: Call to version() failed");
            }

            try MockUpgradeStrategyRegistry(payable(address(strategyRegistryChild2))).getNewVal() returns (
                uint256 val
            ) {
                assertEq(val, proxyHandler.ghost_registryChild2_newVal(), "Registry Child2: NewVal mismatch");
            } catch {
                assertTrue(false, "Registry Child2: Call to getNewVal() failed");
            }
        }
    }

    // Hash from OpenZeppelin Initializable.sol (erc7201:openzeppelin.storage.Initializable)
    bytes32 internal constant OZ_INITIALIZABLE_STORAGE_SLOT =
        0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    function invariant_proxy_implementation_is_sealed() public view {
        // 1. Get the implementation address from our handler's ghost tracking
        address impl = proxyHandler.latestParentImpl();

        // Skip if we haven't deployed an implementation yet
        if (impl == address(0)) return;

        // 2. Load the specific storage slot from the IMPLEMENTATION contract
        // We are reading the storage of the logic contract directly, not the proxy.
        bytes32 storageSlotValue = vm.load(impl, OZ_INITIALIZABLE_STORAGE_SLOT);

        // 3. Extract `_initialized` (uint64)
        // In Solidity packing, the first member of the struct (uint64) occupies
        // the lowest-order bits (right-most) of the storage slot.
        uint64 initializedVersion = uint64(uint256(storageSlotValue));

        // 4. Assert the Seal
        // _disableInitializers() sets the version to type(uint64).max
        assertEq(
            initializedVersion, type(uint64).max, "CRITICAL: Implementation contract is NOT sealed! It can be hijacked."
        );
        // Ensure the implementation is actually a contract
        assertTrue(impl.code.length > 0, "Implementation address has no code!");
    }

    function invariant_proxy_implementation_slot() public view virtual {
        // 1. Parent
        if (proxyHandler.ghost_parent_upgradeCount() > 0) {
            assertEq(
                vm.load(address(parent), IMPLEMENTATION_SLOT),
                bytes32(uint256(uint160(address(proxyHandler.latestParentImpl())))),
                "Parent: Implementation slot corrupted"
            );

            // In your invariant
            address parentImpl = address(uint160(uint256(vm.load(address(parent), IMPLEMENTATION_SLOT))));
            assertTrue(parentImpl.code.length > 0, "Parent Implementation is not a contract!");
        }

        // 2. Child 1
        if (proxyHandler.ghost_child1_upgradeCount() > 0) {
            assertEq(
                vm.load(address(child1), IMPLEMENTATION_SLOT),
                bytes32(uint256(uint160(address(proxyHandler.latestChild1Impl())))),
                "Child1: Implementation slot corrupted"
            );
        }

        // 3. Child 2
        if (proxyHandler.ghost_child2_upgradeCount() > 0) {
            assertEq(
                vm.load(address(child2), IMPLEMENTATION_SLOT),
                bytes32(uint256(uint160(address(proxyHandler.latestChild2Impl())))),
                "Child2: Implementation slot corrupted"
            );
        }

        // 4. Share Token
        if (proxyHandler.ghost_share_upgradeCount() > 0) {
            assertEq(
                vm.load(address(share), IMPLEMENTATION_SLOT),
                bytes32(uint256(uint160(address(proxyHandler.latestShareImpl())))),
                "Share: Implementation slot corrupted"
            );
        }

        // 5. Rebalancer
        if (proxyHandler.ghost_rebalancer_upgradeCount() > 0) {
            assertEq(
                vm.load(address(rebalancer), IMPLEMENTATION_SLOT),
                bytes32(uint256(uint160(address(proxyHandler.latestRebalancerImpl())))),
                "Rebalancer: Implementation slot corrupted"
            );
        }

        // 6. Parent Registry
        if (proxyHandler.ghost_registryParent_upgradeCount() > 0) {
            assertEq(
                vm.load(address(strategyRegistryParent), IMPLEMENTATION_SLOT),
                bytes32(uint256(uint160(address(proxyHandler.latestRegistryParentImpl())))),
                "RegistryParent: Implementation slot corrupted"
            );
        }

        // 7. Child 1 Registry
        if (proxyHandler.ghost_registryChild1_upgradeCount() > 0) {
            assertEq(
                vm.load(address(strategyRegistryChild1), IMPLEMENTATION_SLOT),
                bytes32(uint256(uint160(address(proxyHandler.latestRegistryChild1Impl())))),
                "RegistryChild1: Implementation slot corrupted"
            );
        }

        // 8. Child 2 Registry
        if (proxyHandler.ghost_registryChild2_upgradeCount() > 0) {
            assertEq(
                vm.load(address(strategyRegistryChild2), IMPLEMENTATION_SLOT),
                bytes32(uint256(uint160(address(proxyHandler.latestRegistryChild2Impl())))),
                "RegistryChild2: Implementation slot corrupted"
            );
        }
    }

    function invariant_proxy_interface_adherence() public view virtual {
        bytes4 accessControlId = type(IAccessControl).interfaceId;
        bytes4 ccipReceiverId = type(IAny2EVMMessageReceiver).interfaceId;
        bytes4 shareId = type(IERC20).interfaceId;

        // 1. Parent Checks
        assertTrue(parent.supportsInterface(accessControlId), "Parent: Lost IAccessControl signature");
        assertTrue(parent.supportsInterface(ccipReceiverId), "Parent: Lost CCIP Receiver signature");

        // 2. Child Checks
        assertTrue(child1.supportsInterface(accessControlId), "Child1: Lost IAccessControl signature");
        assertTrue(child2.supportsInterface(accessControlId), "Child2: Lost IAccessControl signature");

        // 3. Share Checks
        assertTrue(share.supportsInterface(shareId), "Share: Lost IERC20 signature");
    }
}
