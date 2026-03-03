// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {
    BaseTest,
    Vm,
    console2,
    ParentPeer,
    ChildPeer,
    Share,
    IYieldPeer,
    Rebalancer,
    Roles,
    IYieldPeer,
    IAccessControl
} from "../BaseTest.t.sol";
import {Handler} from "./Handler.t.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IPoolAddressesProvider} from "@aave/v3-origin/src/contracts/interfaces/IPoolAddressesProvider.sol";
import {IComet} from "../../src/interfaces/IComet.sol";
import {ManualMockRouter} from "../mocks/ManualMockRouter.sol";
import {AaveV3Adapter} from "../../src/adapters/AaveV3Adapter.sol";
import {CompoundV3Adapter} from "../../src/adapters/CompoundV3Adapter.sol";
import {StrategyRegistry} from "../../src/modules/StrategyRegistry.sol";
import {IStrategyAdapter} from "../../src/interfaces/IStrategyAdapter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ShareProxy} from "../../src/proxies/ShareProxy.sol";
import {ParentProxy} from "../../src/proxies/ParentProxy.sol";
import {ChildProxy} from "../../src/proxies/ChildProxy.sol";
import {RebalancerProxy} from "../../src/proxies/RebalancerProxy.sol";
import {StrategyRegistryProxy} from "../../src/proxies/StrategyRegistryProxy.sol";

/// @notice We are making the assumption that the gasLimit set for CCIP works correctly
contract Invariant is StdInvariant, BaseTest {
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint64 internal constant PARENT_SELECTOR = 1;
    uint64 internal constant CHILD1_SELECTOR = 2;
    uint64 internal constant CHILD2_SELECTOR = 3;
    uint256 internal constant STRATEGY_POOL_USDC_STARTING_BALANCE = 1_000_000_000_000_000_000; // 1T USDC
    uint256 internal constant CCIP_GAS_LIMIT = 1_000_000;

    bytes32 internal constant AAVE_V3_PROTOCOL_ID = keccak256(abi.encodePacked("aave-v3"));
    bytes32 internal constant COMPOUND_V3_PROTOCOL_ID = keccak256(abi.encodePacked("compound-v3"));

    /// @dev Handler contract we are running calls to the SBT through
    /// @dev Handler contract we are running calls to the system through
    Handler internal handler;
    /// @dev Manual mock CCIP router used for all peers (replaces MockCCIPRouter)
    ManualMockRouter internal ccipRouter;
    /// @dev provides addresses passed to the contracts based on where we are deploying (locally in this case)
    HelperConfig internal helperConfig;
    /// @dev provides address passed to contracts
    HelperConfig.NetworkConfig internal networkConfig;
    /// @dev Parent Peer contract
    ParentPeer internal parent;
    /// @dev Parent Rebalancer contract
    Rebalancer internal rebalancer;
    /// @dev Child Peer contract
    ChildPeer internal child1;
    /// @dev Child Peer contract
    ChildPeer internal child2;
    /// @dev USDC contract
    IERC20 internal usdc;
    /// @dev Share contract
    Share internal share;
    /// @dev Aave Pool Address
    address internal aavePool;

    /// @dev Strategy Registry contract for parent
    StrategyRegistry strategyRegistryParent;
    /// @dev Strategy Registry contract for child 1
    StrategyRegistry strategyRegistryChild1;
    /// @dev Strategy Registry contract for child 2
    StrategyRegistry strategyRegistryChild2;

    /// @dev Aave Adapter contract for parent
    AaveV3Adapter aaveV3AdapterParent;
    /// @dev Compound Adapter contract for parent
    CompoundV3Adapter compoundV3AdapterParent;
    /// @dev Aave Adapter contract for child 1
    AaveV3Adapter aaveV3AdapterChild1;
    /// @dev Compound Adapter contract for child 1
    CompoundV3Adapter compoundV3AdapterChild1;
    /// @dev Aave Adapter contract for child 2
    AaveV3Adapter aaveV3AdapterChild2;
    /// @dev Compound Adapter contract for child 2
    CompoundV3Adapter compoundV3AdapterChild2;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/
    function setUp() public override {
        /// @dev deploy infrastructure
        _deployInfra();
        _grantRoles();
        _dealLinkToPeers(true, address(parent), address(child1), address(child2), networkConfig.tokens.link);
        _setCrossChainPeers();
        _setWorkflow();

        /// @notice needed to avoid stack too deep errors
        Handler.SystemRoles memory systemRoles = Handler.SystemRoles({
            emergencyPauser: emergencyPauser,
            emergencyUnpauser: emergencyUnpauser,
            configAdmin: configAdmin,
            crossChainAdmin: crossChainAdmin,
            feeWithdrawer: feeWithdrawer,
            feeRateSetter: feeRateSetter
        });

        /// @dev deploy handler
        handler = new Handler(
            parent,
            child1,
            child2,
            share,
            address(ccipRouter),
            address(usdc),
            aavePool,
            networkConfig.protocols.comet,
            rebalancer,
            systemRoles
        );

        /// @dev define appropriate function selectors
        bytes4[] memory selectors = new bytes4[](7);
        selectors[0] = Handler.deposit.selector;
        selectors[1] = Handler.withdraw.selector;
        selectors[2] = Handler.onReport.selector;
        selectors[3] = Handler.withdrawFees.selector;
        selectors[4] = Handler.setFeeRate.selector;
        selectors[5] = Handler.depositPingPong.selector;
        selectors[6] = Handler.withdrawPingPong.selector;

        /// @dev target handler and appropriate function selectors
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    /// @notice Overrides BaseTest _deployInfra to deploy local UUPS proxies instead of forking mainnets.
    /// @dev Peers interact via CCIPLocalSimulator.
    /// @dev since we are not forking mainnets, we will deploy contracts locally
    /// the deployed peers will interact via the ccip local simulator as if they were crosschain
    /// this is a context we need to be aware of in this test suite
    /// @dev All deployments follow the Implementation -> Proxy -> Interface pattern.
    /// @dev Contracts are initialized with address(this) to allow the test contract to configure roles.
    /// @dev Modularized into helper functions for readability and avoiding 'stack too deep'.
    /// @notice Main deployment function orchestrating the setup for Invariant.
    function _deployInfra() internal override {
        // Setup Configuration & Mocks
        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getOrCreateAnvilEthConfig();
        usdc = IERC20(networkConfig.tokens.usdc);
        share = Share(networkConfig.tokens.share);
        aavePool = IPoolAddressesProvider(networkConfig.protocols.aavePoolAddressesProvider).getPool();

        // Prepare Strategy Registry Implementation (passed to deploy helpers)
        StrategyRegistry registryImpl = new StrategyRegistry();
        bytes memory registryInit = abi.encodeWithSelector(StrategyRegistry.initialize.selector);

        // Deploy Rebalancer, Parent & Children
        _deployRebalancer();
        _deployParentInfra(address(registryImpl), registryInit);
        _deployChild1Infra(address(registryImpl), registryInit);
        _deployChild2Infra(address(registryImpl), registryInit);

        // Roles & Liquidity
        /// @dev Grant Share Roles to Proxies (prank Share owner)
        _changePrank(share.owner());
        share.grantMintAndBurnRoles(address(parent));
        share.grantMintAndBurnRoles(address(child1));
        share.grantMintAndBurnRoles(address(child2));
        _stopPrank();

        /// @dev Seed liquidity for mocks
        deal(networkConfig.tokens.usdc, aavePool, STRATEGY_POOL_USDC_STARTING_BALANCE);
        deal(networkConfig.tokens.usdc, networkConfig.protocols.comet, STRATEGY_POOL_USDC_STARTING_BALANCE);
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
    function _deployParentInfra(address registryImpl, bytes memory registryInit) private {
        // Deploy Parent Impl and create init data
        ParentPeer parentImpl = new ParentPeer(
            networkConfig.ccip.ccipRouter,
    }
        ccipRouter = new ManualMockRouter();

        /// @dev since we are not forking mainnets, we will deploy contracts locally
        /// the deployed peers will interact via the ccip local simulator as if they were crosschain
        /// this is a context we need to be aware of in this test suite
        /// @dev deploy the parent contract
        parent = new ParentPeer(
            address(ccipRouter),
            networkConfig.tokens.link,
            PARENT_SELECTOR,
            networkConfig.tokens.usdc,
            networkConfig.tokens.share
        );
        bytes memory parentInit = abi.encodeWithSelector(ParentPeer.initialize.selector);

        // Deploy Parent Proxy and cast to ParentPeer type
        ParentProxy parentProxy = new ParentProxy(address(parentImpl), parentInit);
        parent = ParentPeer(address(parentProxy));

        // Connect Rebalancer & Parent
        parent.grantRole(Roles.CONFIG_ADMIN_ROLE, address(this));
        parent.setRebalancer(address(rebalancer));
        rebalancer.setParentPeer(address(parent));

        // Deploy Registry & Adapters
        StrategyRegistryProxy strategyRegistryProxy = new StrategyRegistryProxy(registryImpl, registryInit);
        strategyRegistryParent = StrategyRegistry(address(strategyRegistryProxy));

        // Set Rebalancer & Supported Protocols in ParentPeer
        /// @dev temp config admin role granted to deployer/owner to set necessary configs
        parent.grantRole(Roles.CONFIG_ADMIN_ROLE, parent.owner());
        parent.setRebalancer(address(rebalancer));
        parent.setSupportedProtocol(keccak256(abi.encodePacked("aave-v3")), true);
        parent.setSupportedProtocol(keccak256(abi.encodePacked("compound-v3")), true);
        _changePrank(rebalancer.owner());
        rebalancer.setParentPeer(address(parent));
        _stopPrank();

        // Deploy Adapters
        aaveV3AdapterParent = new AaveV3Adapter(address(parent), networkConfig.protocols.aavePoolAddressesProvider);
        compoundV3AdapterParent = new CompoundV3Adapter(address(parent), networkConfig.protocols.comet);

        // Set adapters in Registry
        strategyRegistryParent.setStrategyAdapter(AAVE_V3_PROTOCOL_ID, address(aaveV3AdapterParent));
        strategyRegistryParent.setStrategyAdapter(COMPOUND_V3_PROTOCOL_ID, address(compoundV3AdapterParent));

        // Set Registry to Parent Peer, set initial strategy and revoke temp config role
        parent.setStrategyRegistry(address(strategyRegistryParent));
        parent.setInitialActiveStrategy(AAVE_V3_PROTOCOL_ID);
        parent.revokeRole(Roles.CONFIG_ADMIN_ROLE, address(this));
    }

    /// @dev _deployInfra:: Helper to deploy ChildPeer 1
    /// @param registryImpl The strategy registry impl address
    /// @param registryInit The strategy registry init data
    function _deployChild1Infra(address registryImpl, bytes memory registryInit) private {
        // Deploy Proxy
        ChildPeer child1Impl = new ChildPeer(
            networkConfig.ccip.ccipRouter,
        /// @dev deploy at least 2 child peers to cover all CCIP tx types
        child1 = new ChildPeer(
            address(ccipRouter),
            networkConfig.tokens.link,
            CHILD1_SELECTOR,
            networkConfig.tokens.usdc,
            networkConfig.tokens.share,
            PARENT_SELECTOR
        );
        bytes memory child1Init = abi.encodeWithSelector(ChildPeer.initialize.selector);
        ChildProxy childProxy = new ChildProxy(address(child1Impl), child1Init);
        child1 = ChildPeer(address(childProxy)); /// @dev cast Proxy to ChildPeer type

        // Deploy Registry & Adapters
        StrategyRegistryProxy strategyRegistryProxy = new StrategyRegistryProxy(registryImpl, registryInit);
        strategyRegistryChild1 = StrategyRegistry(address(strategyRegistryProxy));

        aaveV3AdapterChild1 = new AaveV3Adapter(address(child1), networkConfig.protocols.aavePoolAddressesProvider);
        compoundV3AdapterChild1 = new CompoundV3Adapter(address(child1), networkConfig.protocols.comet);

        // Set adapters in Registry
        strategyRegistryChild1.setStrategyAdapter(AAVE_V3_PROTOCOL_ID, address(aaveV3AdapterChild1));
        strategyRegistryChild1.setStrategyAdapter(COMPOUND_V3_PROTOCOL_ID, address(compoundV3AdapterChild1));

        // Set Registry to Child Peer
        child1.grantRole(Roles.CONFIG_ADMIN_ROLE, address(this));
        child1.setStrategyRegistry(address(strategyRegistryChild1));
        child1.revokeRole(Roles.CONFIG_ADMIN_ROLE, address(this));
    }

    /// @dev _deployInfra:: Helper to deploy ChildPeer 2
    /// @param registryImpl The strategy registry impl address
    /// @param registryInit The strategy registry init data
    function _deployChild2Infra(address registryImpl, bytes memory registryInit) private {
        // Deploy Proxy
        ChildPeer child2Impl = new ChildPeer(
            networkConfig.ccip.ccipRouter,
        child2 = new ChildPeer(
            address(ccipRouter),
            networkConfig.tokens.link,
            CHILD2_SELECTOR,
            networkConfig.tokens.usdc,
            networkConfig.tokens.share,
            PARENT_SELECTOR
        );
        bytes memory child2Init = abi.encodeWithSelector(ChildPeer.initialize.selector);
        ChildProxy childProxy = new ChildProxy(address(child2Impl), child2Init);
        child2 = ChildPeer(address(childProxy)); /// @dev cast Proxy to ChildPeer type

        // Deploy Registry & Adapters
        StrategyRegistryProxy strategyRegistryProxy = new StrategyRegistryProxy(registryImpl, registryInit);
        strategyRegistryChild2 = StrategyRegistry(address(strategyRegistryProxy));

        aaveV3AdapterChild2 = new AaveV3Adapter(address(child2), networkConfig.protocols.aavePoolAddressesProvider);
        compoundV3AdapterChild2 = new CompoundV3Adapter(address(child2), networkConfig.protocols.comet);

        strategyRegistryChild2.setStrategyAdapter(AAVE_V3_PROTOCOL_ID, address(aaveV3AdapterChild2));
        strategyRegistryChild2.setStrategyAdapter(COMPOUND_V3_PROTOCOL_ID, address(compoundV3AdapterChild2));

        // Configure Child 2
        child2.grantRole(Roles.CONFIG_ADMIN_ROLE, address(this));
        child2.setStrategyRegistry(address(strategyRegistryChild2));
        child2.revokeRole(Roles.CONFIG_ADMIN_ROLE, address(this));
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

        ccipRouter.setPeerToChainSelector(address(parent), PARENT_SELECTOR);
        ccipRouter.setPeerToChainSelector(address(child1), CHILD1_SELECTOR);
        ccipRouter.setPeerToChainSelector(address(child2), CHILD2_SELECTOR);
    }

    function _setWorkflow() internal {
        _changePrank(rebalancer.owner());
        rebalancer.setWorkflow(workflowId, workflowOwner, workflowName);
        _stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                                 SYSTEM
    //////////////////////////////////////////////////////////////*/
    /// @notice Users should always be able to withdraw what they deposited
    /// @dev this is a critical invariant that ensures the integrity of user deposit redemption
    function invariant_system_stablecoinRedemption_perUser_integrity() public {
        handler.forEachUser(this.checkStablecoinRedemptionPerUser);
    }

    function checkStablecoinRedemptionPerUser(address user) external view {
        uint256 deposited = handler.ghost_totalUsdcDepositedPerUser_userPrincipal(user);
        uint256 withdrawn = handler.ghost_event_totalUsdcWithdrawnPerUser(user);
        uint256 netDeposits = deposited > withdrawn ? deposited - withdrawn : 0;
        uint256 userShares = share.balanceOf(user);

        uint256 totalValue =
            IYieldPeer(handler.chainSelectorsToPeers(parent.getStrategy().chainSelector)).getTotalValue();
        uint256 totalValueConverted = _convertUsdcToShare(totalValue);
        uint256 minUsdcValueInShares = _convertUsdcToShare(1);
        uint256 totalShares = parent.getTotalShares();

        if (totalShares > 0) {
            uint256 withdrawable = totalShares > 0 ? (userShares * totalValueConverted) / totalShares : 0;
            uint256 withdrawableConverted = _convertShareToUsdc(withdrawable);
            uint256 minWithdrawable = netDeposits * 990 / 1000; // Allow 1% slippage
            assertTrue(
                withdrawableConverted >= minWithdrawable || netDeposits < minUsdcValueInShares,
                "Invariant violated: User should be able to withdraw what they deposited, except for left over dust"
            );
        } else {
            assertTrue(netDeposits == 0, "Invariant violated: User should be able to withdraw what they deposited");
        }
    }

    /// @notice Total Value Accountancy: The total value in the system should be more than or equal to total USDC deposited minus total USDC withdrawn
    function invariant_system_totalValue_exceedsNetDeposits() public {
        handler.forEachChainSelector(this.checkTotalValueExceedsNetDepositsPerChainSelector);
    }

    function checkTotalValueExceedsNetDepositsPerChainSelector(uint64 chainSelector) external view {
        uint256 totalDeposited = handler.ghost_totalUsdcDeposited_userPrincipal();
        uint256 totalWithdrawn = handler.ghost_yieldPeer_event_WithdrawCompleted_param_amount_totalSum();
        uint256 netDeposits = totalDeposited > totalWithdrawn ? totalDeposited - totalWithdrawn : 0;
        if (chainSelector == parent.getStrategy().chainSelector) {
            assertTrue(
                IYieldPeer(handler.chainSelectorsToPeers(chainSelector)).getTotalValue() >= netDeposits,
                "Invariant violated: Total value in the system should be more than or equal to total USDC deposited minus total USDC withdrawn"
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                                DEPOSIT
    //////////////////////////////////////////////////////////////*/
    /// @notice Emission Count: DepositInitiated, ShareMintUpdate, and SharesMinted must each be emitted exactly once per deposit
    function invariant_deposit_DepositInitiated_ShareMintUpdate_SharesMinted_emissionConsistency() public view {
        assertEq(
            handler.ghost_yieldPeer_event_DepositInitiated_emissions(),
            handler.ghost_parent_event_ShareMintUpdate_emissions(),
            "Invariant violated: The number of DepositInitiated events should be equal to the number of ShareMintUpdate events"
        );
        assertEq(
            handler.ghost_yieldPeer_event_SharesMinted_emissions(),
            handler.ghost_yieldPeer_event_DepositInitiated_emissions(),
            "Invariant violated: SharesMinted must be emitted exactly once per DepositInitiated"
        );
    }

    /// @notice Emission Count: DepositToStrategy must be emitted exactly once per DepositInitiated plus rebalances
    function invariant_deposit_DepositToStrategy_emissionConsistency() public view {
        assertEq(
            handler.ghost_yieldPeer_event_DepositToStrategy_emissions(),
            handler.ghost_yieldPeer_event_DepositInitiated_emissions() + handler.ghost_rebalances(),
            "Invariant violated: DepositToStrategy must be emitted exactly once per DepositInitiated plus rebalances"
        );
    }

    /// @notice Amount Flow: Total DepositInitiated amounts must equal total user principal deposited
    function invariant_deposit_DepositInitiated_amount_equalsUserPrincipal() public view {
        assertEq(
            handler.ghost_yieldPeer_event_DepositInitiated_param_amount_totalSum(),
            handler.ghost_totalUsdcDeposited_userPrincipal(),
            "Invariant violated: Total DepositInitiated amounts must equal total user principal deposited"
        );
    }

    /// @notice Amount Flow: Total StrategyAdapter Deposit amounts must equal total DepositToStrategy amounts emitted by peers
    function invariant_deposit_DepositToStrategy_amount_matchesStrategyAdapterDeposit() public view {
        assertEq(
            handler.ghost_strategyAdapter_event_Deposit_param_amount_totalSum(),
            handler.ghost_yieldPeer_event_DepositToStrategy_param_amount_totalSum(),
            "Invariant violated: Total StrategyAdapter Deposit amounts must equal total DepositToStrategy amounts emitted by peers"
        );
    }

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/
    /// @notice Emission Count: WithdrawInitiated, SharesBurned, WithdrawCompleted, and ShareBurnUpdate must each be emitted exactly once per withdrawal
    function invariant_withdraw_WithdrawInitiated_SharesBurned_WithdrawCompleted_ShareBurnUpdate_emissionConsistency()
        public
        view
    {
        assertEq(
            handler.ghost_yieldPeer_event_SharesBurned_emissions(),
            handler.ghost_yieldPeer_event_WithdrawInitiated_emissions(),
            "Invariant violated: SharesBurned must be emitted exactly once per WithdrawInitiated"
        );
        assertEq(
            handler.ghost_yieldPeer_event_WithdrawCompleted_emissions(),
            handler.ghost_yieldPeer_event_SharesBurned_emissions(),
            "Invariant violated: WithdrawCompleted must be emitted exactly once per SharesBurned"
        );
        assertEq(
            handler.ghost_yieldPeer_event_WithdrawCompleted_emissions(),
            handler.ghost_parent_event_ShareBurnUpdate_emissions(),
            "Invariant violated: The number of WithdrawCompleted events should be equal to the number of ShareBurnUpdate events"
        );
    }

    /// @notice Amount Flow: Total WithdrawInitiated and SharesBurned amounts must equal ghost total shares burned
    function invariant_withdraw_WithdrawInitiated_SharesBurned_amount_equalsGhostSharesBurned() public view {
        assertEq(
            handler.ghost_yieldPeer_event_WithdrawInitiated_param_amount_totalSum(),
            handler.ghost_totalSharesBurned(),
            "Invariant violated: Total WithdrawInitiated amounts must equal total shares burned"
        );
        assertEq(
            handler.ghost_yieldPeer_event_SharesBurned_param_amount_totalSum(),
            handler.ghost_totalSharesBurned(),
            "Invariant violated: Total SharesBurned event amounts must equal total shares burned tracked by handler"
        );
    }

    /*//////////////////////////////////////////////////////////////
                                 SHARES
    //////////////////////////////////////////////////////////////*/
    /// @notice Total Shares Accountancy: The total shares tracked by ParentPeer should be equal to total minted minus total burned system wide.
    function invariant_shares_totalShares_equalsMintedMinusBurned() public view {
        uint256 totalSharesMinted = handler.ghost_parent_event_ShareMintUpdate_param_amount_totalSum();
        uint256 totalSharesBurned = handler.ghost_totalSharesBurned();
        assertEq(
            parent.getTotalShares(),
            totalSharesMinted - totalSharesBurned,
            "Invariant violated: Total shares tracked by ParentPeer should be equal to total minted minus total burned system wide."
        );
    }

    /// @notice Total Share Balances: The total shares tracked by ParentPeer should be equal to the sum of all holder balances
    function invariant_shares_totalShares_equalsSumOfHolderBalances() public view {
        /// @dev we mint an initial amount of shares to the admin to mitigate share inflation attacks
        uint256 sumOfBalances = handler.getAdminShareBalance();
        /// @dev loop through all users in the system and add their share balances to the sum
        for (uint256 i = 0; i < handler.getUsersLength(); i++) {
            address user = handler.getUserAt(i);
            sumOfBalances += share.balanceOf(user);
        }
        sumOfBalances += share.balanceOf(address(parent));
        sumOfBalances += share.balanceOf(parent.owner());

        assertEq(
            parent.getTotalShares(),
            sumOfBalances,
            "Invariant violated: Total shares tracked by ParentPeer should be equal to the sum of all holder balances"
        );
    }

    /// @notice Share Balance: Share balance per user must equal total shares minted per user minus total shares burned per user
    function invariant_shares_ShareBalance_perUser_equalsMintedMinusBurned() public {
        handler.forEachUser(this.checkShareBalanceIntegrityPerUser);
    }

    function checkShareBalanceIntegrityPerUser(address user) external view {
        assertEq(
            share.balanceOf(user),
            handler.ghost_totalSharesMintedPerUser(user) - handler.ghost_totalSharesBurnedPerUser(user),
            "Invariant violated: Share balance per user must equal total shares minted per user minus total shares burned per user"
        );
    }

    /// @notice Amount Consistency: Total SharesMinted event amounts must equal total ShareMintUpdate event amounts
    function invariant_shares_SharesMinted_ShareMintUpdate_amountConsistency() public view {
        assertEq(
            handler.ghost_yieldPeer_event_SharesMinted_param_amount_totalSum(),
            handler.ghost_parent_event_ShareMintUpdate_param_amount_totalSum(),
            "Invariant violated: Total SharesMinted amounts must equal total ShareMintUpdate amounts"
        );
    }

    /// @notice Amount Consistency: Total SharesBurned event amounts must equal total ShareBurnUpdate event amounts
    function invariant_shares_SharesBurned_ShareBurnUpdate_amountConsistency() public view {
        assertEq(
            handler.ghost_yieldPeer_event_SharesBurned_param_amount_totalSum(),
            handler.ghost_parent_event_ShareBurnUpdate_param_amount_totalSum(),
            "Invariant violated: Total SharesBurned amounts must equal total ShareBurnUpdate amounts"
        );
    }

    /// @notice Share Token Supply: share.totalSupply() must equal parent.getTotalShares()
    function invariant_shares_Share_totalSupply_equalsParentTotalShares() public view {
        assertEq(
            share.totalSupply(),
            parent.getTotalShares(),
            "Invariant violated: share.totalSupply() must equal parent.getTotalShares()"
        );
    }

    /*//////////////////////////////////////////////////////////////
                                  FEES
    //////////////////////////////////////////////////////////////*/
    /// @notice Fee rate should always be within valid bounds
    function invariant_fees_FeeRate_withinBounds() public {
        handler.forEachChainSelector(this.checkFeeRateWithinBoundsPerChainSelector);
    }

    function checkFeeRateWithinBoundsPerChainSelector(uint64 chainSelector) external view {
        IYieldPeer peer = IYieldPeer(handler.chainSelectorsToPeers(chainSelector));
        assertTrue(
            peer.getFeeRate() <= peer.getMaxFeeRate(),
            "Invariant violated: Fee rate should not exceed maximum allowed fee rate"
        );
    }

    /// @notice Fee Rate: Fee rate must be consistent across all chains
    function invariant_fees_FeeRate_consistentAcrossChains() public {
        handler.forEachChainSelector(this.checkFeeRateConsistencyPerChainSelector);
    }

    function checkFeeRateConsistencyPerChainSelector(uint64 chainSelector) external view {
        assertEq(
            IYieldPeer(handler.chainSelectorsToPeers(chainSelector)).getFeeRate(),
            parent.getFeeRate(),
            "Invariant violated: Fee rate must be consistent across all chains"
        );
    }

    /// @notice Amount Flow: Total FeeTaken event amounts must equal total raw deposits minus total user principal
    function invariant_fees_FeeTaken_amount_equalsTotalDepositMinusUserPrincipal() public view {
        assertEq(
            handler.ghost_yieldFees_event_FeeTaken_param_amount_totalSum(),
            handler.ghost_totalUsdcDeposited() - handler.ghost_totalUsdcDeposited_userPrincipal(),
            "Invariant violated: Total FeeTaken amounts must equal total raw deposits minus total user principal"
        );
    }

    /// @notice Fee amount integrity: Total fees per user should equal sum of individual deposit fees
    function invariant_fees_FeeTaken_amount_perUser_equalsSumOfDepositFees() public {
        handler.forEachUser(this.checkFeeAmountIntegrityPerUser);
    }

    function checkFeeAmountIntegrityPerUser(address user) external view {
        if (handler.ghost_totalUsdcDepositedPerUser_userPrincipal(user) > 0) {
            assertTrue(
                handler.ghost_totalFeesTakenInStablecoinPerUser(user)
                    == handler.calculateExpectedFeesFromDepositRecords(user),
                "Invariant violated: Total fees per user should equal sum of individual deposit fees"
            );
        }
    }

    /// @notice Total fees taken should equal sum of all individual deposit fees
    function invariant_fees_FeeTaken_amount_equalsSumOfDepositFees() public view {
        uint256 totalFeesFromEvents = handler.ghost_yieldFees_event_FeeTaken_param_amount_totalSum();
        uint256 totalFeesFromDepositRecords = handler.calculateTotalExpectedFeesFromDepositRecords();

        assertEq(
            totalFeesFromEvents,
            totalFeesFromDepositRecords,
            "Invariant violated: Total fees taken should equal sum of all individual deposit fees"
        );
    }

    /// @notice Fees Consistency: The total withdrawable fees taken should be equal to the total fees taken minus total fees withdrawn
    function invariant_fees_FeeTaken_FeesWithdrawn_balanceConsistency() public view {
        // @review instead of using .balanceOf, do we want to track fees in YieldFees::s_feesCollected[feeToken] mapping address => uint256?
        uint256 parentFees = usdc.balanceOf(address(parent));
        uint256 child1Fees = usdc.balanceOf(address(child1));
        uint256 child2Fees = usdc.balanceOf(address(child2));
        uint256 availableFees = parentFees + child1Fees + child2Fees;
        assertEq(
            handler.ghost_yieldFees_event_FeeTaken_param_amount_totalSum()
                - handler.ghost_totalFeesWithdrawnInStablecoin(),
            availableFees,
            "Invariant violated: The total withdrawable fees taken should be equal to the total fees taken minus total fees withdrawn"
        );
    }

    /// @notice Amount Flow: Total FeesWithdrawn event amounts must equal ghost total fees withdrawn
    function invariant_fees_FeesWithdrawn_amount_matchesGhost() public view {
        assertEq(
            handler.ghost_yieldFees_event_FeesWithdrawn_param_amount_totalSum(),
            handler.ghost_totalFeesWithdrawnInStablecoin(),
            "Invariant violated: Total FeesWithdrawn event amounts must equal total fees withdrawn tracked by handler"
        );
    }

    /// @notice Fee withdrawal integrity: Non-fee-withdrawer should not be able to withdraw fees
    function invariant_fees_FeesWithdrawn_onlyFeeWithdrawer() public view {
        assertFalse(
            handler.ghost_flag_nonFeeWithdrawer_withdrewFees(),
            "Invariant violated: Fees should only be withdrawable by fee withdrawer"
        );
    }

    /*//////////////////////////////////////////////////////////////
                               STRATEGY
    //////////////////////////////////////////////////////////////*/
    /// @notice Strategy Registry: Active protocol must be registered in StrategyRegistry
    // @review:certora is this verified with certora?
    // where should it be verified? BasePeer.spec? Parent.spec because of getStrategy()?
    function invariant_strategy_activeProtocol_registeredInStrategyRegistry() public view {
        bytes32 protocolId = parent.getStrategy().protocolId;
        address adapter = strategyRegistryParent.getStrategyAdapter(protocolId);
        assertTrue(adapter != address(0), "Invariant violated: Active protocol must be registered in StrategyRegistry");
    }

    /// @notice Strategy: Active strategy protocolId must be a supported protocol in ParentPeer
    function invariant_strategy_activeProtocol_isSupportedInParent() public view {
        assertTrue(
            parent.getSupportedProtocol(parent.getStrategy().protocolId),
            "Invariant violated: Active strategy protocolId must be a supported protocol in ParentPeer"
        );
    }

    /// @notice Strategy Registry: Active adapter must match registered adapter for protocolId stored in ParentPeer
    // @review:certora is this verified with certora?
    function invariant_strategy_activeAdapter_matchesStrategyRegistry() public view {
        bytes32 protocolId = parent.getStrategy().protocolId;
        address activePeer = handler.chainSelectorsToPeers(parent.getStrategy().chainSelector);
        assertEq(
            IYieldPeer(activePeer).getActiveStrategyAdapter(),
            StrategyRegistry(IYieldPeer(activePeer).getStrategyRegistry()).getStrategyAdapter(protocolId),
            "Invariant violated: Active adapter must match registered adapter for protocolId stored in ParentPeer"
        );
    }

    /// @notice Active Strategy Adapter Consistency: Active strategy adapter on active strategy chain should match the protocol stored in ParentPeer
    function invariant_strategy_ActiveStrategyAdapterUpdated_consistencyPerChain() public {
        handler.forEachChainSelector(this.checkActiveStrategyAdapterConsistencyPerChainSelector);
    }

    function checkActiveStrategyAdapterConsistencyPerChainSelector(uint64 chainSelector) external view {
        if (chainSelector == parent.getStrategy().chainSelector) {
            assertEq(
                IYieldPeer(handler.chainSelectorsToPeers(chainSelector))
                    .getStrategyAdapter(parent.getStrategy().protocolId),
                IYieldPeer(handler.chainSelectorsToPeers(chainSelector)).getActiveStrategyAdapter(),
                "Invariant violated: Active strategy adapter on active strategy chain should match the protocol stored in ParentPeer"
            );
            assertTrue(
                IYieldPeer(handler.chainSelectorsToPeers(chainSelector)).getActiveStrategyAdapter() != address(0),
                "Invariant violated: Active strategy adapter should be non-zero on the strategy chain"
            );
        } else {
            assertEq(
                IYieldPeer(handler.chainSelectorsToPeers(chainSelector)).getActiveStrategyAdapter(),
                address(0),
                "Invariant violated: Active strategy adapter should be set to 0 on non-active strategy chains"
            );
        }
    }

    /// @notice Strategy: Exactly one peer must be the strategy chain (have a non-zero active strategy adapter)
    function invariant_strategy_exactlyOneStrategyChain() public view {
        uint256 strategyChainCount = 0;
        if (IYieldPeer(handler.chainSelectorsToPeers(PARENT_SELECTOR)).getActiveStrategyAdapter() != address(0)) {
            strategyChainCount++;
        }
        if (IYieldPeer(handler.chainSelectorsToPeers(CHILD1_SELECTOR)).getActiveStrategyAdapter() != address(0)) {
            strategyChainCount++;
        }
        if (IYieldPeer(handler.chainSelectorsToPeers(CHILD2_SELECTOR)).getActiveStrategyAdapter() != address(0)) {
            strategyChainCount++;
        }
        assertEq(strategyChainCount, 1, "Invariant violated: Exactly one peer must be the strategy chain");
    }

    /*//////////////////////////////////////////////////////////////
                               REBALANCE
    //////////////////////////////////////////////////////////////*/
    /// @notice Rebalance Event Consistency: The number of rebalances should be equal to the number of:
    /// - WithdrawFromStrategy events
    /// - OnReportSecurityChecksPassed events
    /// - StrategyUpdated events
    function invariant_rebalance_WithdrawFromStrategy_OnReportSecurityChecksPassed_StrategyUpdated_emissionConsistency()
        public
        view
    {
        uint256 rebalances = handler.ghost_rebalances();
        assertEq(
            rebalances,
            handler.ghost_yieldPeer_event_WithdrawFromStrategy_rebalance_emissions(),
            "Invariant violated: The number of rebalance events should be equal to the number of WithdrawFromStrategy events"
        );
        assertEq(
            rebalances,
            handler.ghost_creReceiver_event_OnReportSecurityChecksPassed_emissions(),
            "Invariant violated: The number of rebalance events should be equal to the number of OnReportSecurityChecksPassed events"
        );
        assertEq(
            rebalances,
            handler.ghost_parent_event_StrategyUpdated_emissions(),
            "Invariant violated: The number of rebalance events should be equal to the number of StrategyUpdated events"
        );
    }

    /// @notice CRE Report Consistency: The strategy decoded from the last CRE report
    /// must always match the strategy state stored in ParentPeer
    function invariant_rebalance_ReportDecoded_matchesParentStrategy() public view {
        if (handler.ghost_rebalancer_event_ReportDecoded_emissions() == 0) return;
        assertEq(
            parent.getStrategy().chainSelector,
            handler.ghost_rebalancer_event_ReportDecoded_param_chainSelector(),
            "Invariant violated: ParentPeer strategy chain selector must match last decoded CRE report"
        );
        assertEq(
            parent.getStrategy().protocolId,
            handler.ghost_rebalancer_event_ReportDecoded_param_protocolId(),
            "Invariant violated: ParentPeer strategy protocolId must match last decoded CRE report"
        );
    }

    /// @notice Rebalance: StrategyUpdated event params must match decoded CRE report params
    function invariant_rebalance_StrategyUpdated_matchesReportDecoded() public view {
        if (handler.ghost_rebalances() == 0) return;
        assertEq(
            handler.ghost_parent_event_StrategyUpdated_param_chainSelector(),
            handler.ghost_rebalancer_event_ReportDecoded_param_chainSelector(),
            "Invariant violated: StrategyUpdated chain selector must match decoded CRE report"
        );
        assertEq(
            handler.ghost_parent_event_StrategyUpdated_param_protocolId(),
            handler.ghost_rebalancer_event_ReportDecoded_param_protocolId(),
            "Invariant violated: StrategyUpdated protocolId must match decoded CRE report"
        );
    }

    /// @notice After a MAX sentinel rebalance withdrawal, the old adapter's protocol position (getTotalValue()) must be fully drained
    function invariant_rebalance_WithdrawFromStrategy_drainsTotalValue() public view {
        if (handler.ghost_rebalances() == 0) return;
        address drainedAdapter = handler.ghost_yieldPeer_event_WithdrawFromStrategy_rebalance_param_strategyAdapter();
        assertTrue(
            IStrategyAdapter(drainedAdapter).getTotalValue(address(usdc)) < 1e6,
            "Invariant violated: Old strategy adapter should be fully drained after rebalance withdrawal"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              CROSSCHAIN
    //////////////////////////////////////////////////////////////*/
    /// @notice CCIP: Every CCIPMessageSent must result in a CCIPMessageReceived in the synchronous mock
    function invariant_crosschain_CCIPMessageSent_CCIPMessageReceived_emissionConsistency() public view {
        assertEq(
            handler.ghost_yieldPeer_event_CCIPMessageSent_emissions(),
            handler.ghost_yieldPeer_event_CCIPMessageReceived_emissions(),
            "Invariant violated: Every CCIPMessageSent must result in a CCIPMessageReceived"
        );
    }

    /// @notice PingPong Completion: Every fuzzed depositPingPong must result in SharesMinted
    function invariant_crosschain_depositPingPong_alwaysCompletes() public view {
        assertEq(
            handler.ghost_depositPingPong_calls(),
            handler.ghost_depositPingPong_completions(),
            "Invariant violated: Every fuzzed depositPingPong must result in SharesMinted"
        );
    }

    /// @notice PingPong Completion: Every fuzzed withdrawPingPong must result in WithdrawCompleted
    function invariant_crosschain_withdrawPingPong_alwaysCompletes() public view {
        assertEq(
            handler.ghost_withdrawPingPong_calls(),
            handler.ghost_withdrawPingPong_completions(),
            "Invariant violated: Every fuzzed withdrawPingPong must result in WithdrawCompleted"
        );
    }

    /*//////////////////////////////////////////////////////////////
                                UTILITY
    //////////////////////////////////////////////////////////////*/
    /// @notice Helper function to calculate the fee for a deposit
    /// @param stablecoinDepositAmount The amount of stablecoin being deposited
    /// @return fee The fee for the deposit in stablecoin amount
    function _calculateFee(uint256 stablecoinDepositAmount) internal view returns (uint256 fee) {
        fee = (stablecoinDepositAmount * parent.getFeeRate()) / parent.getFeeRateDivisor();
    }
}
