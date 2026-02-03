// SPDX-License-Identifier: MIT
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
import {MockCCIPRouter} from "@chainlink-local/test/mocks/MockRouter.sol";
import {AaveV3Adapter} from "../../src/adapters/AaveV3Adapter.sol";
import {CompoundV3Adapter} from "../../src/adapters/CompoundV3Adapter.sol";
import {StrategyRegistry} from "../../src/modules/StrategyRegistry.sol";
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

    /// @dev Handler contract we are running calls to the SBT through
    Handler internal handler;
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

        /// @dev deploy handler
        handler = new Handler(
            parent,
            child1,
            child2,
            share,
            networkConfig.ccip.ccipRouter,
            address(usdc),
            aavePool,
            networkConfig.protocols.comet,
            rebalancer
        );

        /// @dev define appropriate function selectors
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = Handler.deposit.selector;
        selectors[1] = Handler.withdraw.selector;
        selectors[2] = Handler.onReport.selector;
        selectors[3] = Handler.withdrawFees.selector;
        selectors[4] = Handler.setFeeRate.selector;

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
        // 1. Setup Configuration & Mocks
        _setupConfigAndMocks();

        // 2. Prepare Strategy Registry Implementation (passed to deploy helpers)
        StrategyRegistry registryImpl = new StrategyRegistry();
        bytes memory registryInit = abi.encodeWithSelector(StrategyRegistry.initialize.selector);

        // 3. Deploy Rebalancer, Parent & Children
        _deployRebalancer();
        _deployParent(address(registryImpl), registryInit);
        _deployChild1(address(registryImpl), registryInit);
        _deployChild2(address(registryImpl), registryInit);

        // 4. Final Configuration - Roles & Liquidity
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

    /// @dev _deployInfra:: Helper to setup configuration and mocks
    function _setupConfigAndMocks() private {
        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getOrCreateAnvilEthConfig();
        usdc = IERC20(networkConfig.tokens.usdc);
        share = Share(networkConfig.tokens.share);
        aavePool = IPoolAddressesProvider(networkConfig.protocols.aavePoolAddressesProvider).getPool();
    }

    /// @dev _deployInfra:: Helper to deploy Rebalancer
    function _deployRebalancer() private {
        Rebalancer rebalancerImpl = new Rebalancer();
        bytes memory rebalancerInit = abi.encodeWithSelector(Rebalancer.initialize.selector);
        RebalancerProxy rebalancerProxy = new RebalancerProxy(address(rebalancerImpl), rebalancerInit);
        rebalancer = Rebalancer(address(rebalancerProxy)); /// @dev cast Proxy to Rebalancer type
    }

    /// @dev _deployInfra:: Helper to deploy ParentPeer
    /// @param registryImpl The strategy registry impl address
    /// @param registryInit The strategy registry init data
    function _deployParent(address registryImpl, bytes memory registryInit) private {
        // Deploy Proxy
        ParentPeer parentImpl = new ParentPeer(
            networkConfig.ccip.ccipRouter,
            networkConfig.tokens.link,
            PARENT_SELECTOR,
            networkConfig.tokens.usdc,
            networkConfig.tokens.share
        );
        bytes memory parentInit = abi.encodeWithSelector(ParentPeer.initialize.selector);
        ParentProxy parentProxy = new ParentProxy(address(parentImpl), parentInit);
        parent = ParentPeer(address(parentProxy)); /// @dev cast Proxy to ParentPeer type

        // Connect Rebalancer & Parent
        parent.grantRole(Roles.CONFIG_ADMIN_ROLE, address(this));
        parent.setRebalancer(address(rebalancer));
        rebalancer.setParentPeer(address(parent));

        // Deploy Registry & Adapters
        StrategyRegistryProxy strategyRegistryProxy = new StrategyRegistryProxy(registryImpl, registryInit);
        strategyRegistryParent = StrategyRegistry(address(strategyRegistryProxy));

        aaveV3AdapterParent = new AaveV3Adapter(address(parent), networkConfig.protocols.aavePoolAddressesProvider);
        compoundV3AdapterParent = new CompoundV3Adapter(address(parent), networkConfig.protocols.comet);

        // Configure Registry
        strategyRegistryParent.setStrategyAdapter(keccak256(abi.encodePacked("aave-v3")), address(aaveV3AdapterParent));
        strategyRegistryParent.setStrategyAdapter(
            keccak256(abi.encodePacked("compound-v3")), address(compoundV3AdapterParent)
        );

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
        // Deploy Proxy
        ChildPeer child1Impl = new ChildPeer(
            networkConfig.ccip.ccipRouter,
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

        // Configure Child 1
        child1.grantRole(Roles.CONFIG_ADMIN_ROLE, address(this));
        child1.setStrategyRegistry(address(strategyRegistryChild1));
        child1.revokeRole(Roles.CONFIG_ADMIN_ROLE, address(this));

        strategyRegistryChild1.setStrategyAdapter(keccak256(abi.encodePacked("aave-v3")), address(aaveV3AdapterChild1));
        strategyRegistryChild1.setStrategyAdapter(
            keccak256(abi.encodePacked("compound-v3")), address(compoundV3AdapterChild1)
        );
    }

    /// @dev _deployInfra:: Helper to deploy ChildPeer 2
    /// @param registryImpl The strategy registry impl address
    /// @param registryInit The strategy registry init data
    function _deployChild2(address registryImpl, bytes memory registryInit) private {
        // Deploy Proxy
        ChildPeer child2Impl = new ChildPeer(
            networkConfig.ccip.ccipRouter,
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

        // Configure Child 2
        child2.grantRole(Roles.CONFIG_ADMIN_ROLE, address(this));
        child2.setStrategyRegistry(address(strategyRegistryChild2));
        child2.revokeRole(Roles.CONFIG_ADMIN_ROLE, address(this));

        strategyRegistryChild2.setStrategyAdapter(keccak256(abi.encodePacked("aave-v3")), address(aaveV3AdapterChild2));
        strategyRegistryChild2.setStrategyAdapter(
            keccak256(abi.encodePacked("compound-v3")), address(compoundV3AdapterChild2)
        );
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

        parent.setCCIPGasLimit(CCIP_GAS_LIMIT);
        child1.setCCIPGasLimit(CCIP_GAS_LIMIT);
        child2.setCCIPGasLimit(CCIP_GAS_LIMIT);

        parent.setAllowedChain(PARENT_SELECTOR, true);
        parent.setAllowedChain(CHILD1_SELECTOR, true);
        parent.setAllowedChain(CHILD2_SELECTOR, true);
        parent.setAllowedPeer(PARENT_SELECTOR, address(parent));
        parent.setAllowedPeer(CHILD1_SELECTOR, address(child1));
        parent.setAllowedPeer(CHILD2_SELECTOR, address(child2));

        child1.setAllowedChain(PARENT_SELECTOR, true);
        child1.setAllowedChain(CHILD1_SELECTOR, true);
        child1.setAllowedChain(CHILD2_SELECTOR, true);
        child1.setAllowedPeer(PARENT_SELECTOR, address(parent));
        child1.setAllowedPeer(CHILD1_SELECTOR, address(child1));
        child1.setAllowedPeer(CHILD2_SELECTOR, address(child2));

        child2.setAllowedChain(PARENT_SELECTOR, true);
        child2.setAllowedChain(CHILD1_SELECTOR, true);
        child2.setAllowedChain(CHILD2_SELECTOR, true);
        child2.setAllowedPeer(PARENT_SELECTOR, address(parent));
        child2.setAllowedPeer(CHILD1_SELECTOR, address(child1));
        child2.setAllowedPeer(CHILD2_SELECTOR, address(child2));

        parent.revokeRole(Roles.CROSS_CHAIN_ADMIN_ROLE, parent.owner());
        child1.revokeRole(Roles.CROSS_CHAIN_ADMIN_ROLE, child1.owner());
        child2.revokeRole(Roles.CROSS_CHAIN_ADMIN_ROLE, child2.owner());

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
    /// @notice Active Strategy Adapter Consistency: Active strategy adapter on active strategy chain should match the protocol stored in ParentPeer
    function invariant_activeStrategyAdapter_consistency() public {
        handler.forEachChainSelector(this.checkActiveStrategyAdapterPerChainSelector);
    }

    function checkActiveStrategyAdapterPerChainSelector(uint64 chainSelector) external view {
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

    /// @notice Total Shares Accountancy: The total shares tracked by ParentPeer should be equal to total minted minus total burned system wide.
    function invariant_totalShares_integrity() public view {
        assertEq(
            parent.getTotalShares(),
            handler.ghost_event_totalSharesMinted() - handler.ghost_state_totalSharesBurned(),
            "Invariant violated: Total shares tracked by ParentPeer should be equal to total minted minus total burned system wide."
        );
    }

    /// @notice Total Value Accountancy: The total value in the system should be more than or equal to total USDC deposited minus total USDC withdrawn
    function invariant_totalValue_integrity() public {
        handler.forEachChainSelector(this.checkTotalDepositsAgainstTotalValuePerChainSelector);
    }

    function checkTotalDepositsAgainstTotalValuePerChainSelector(uint64 chainSelector) external view {
        uint256 totalDeposited = handler.ghost_state_totalUsdcDeposited_userPrincipal();
        uint256 totalWithdrawn = handler.ghost_event_totalUsdcWithdrawn();
        uint256 netDeposits = totalDeposited > totalWithdrawn ? totalDeposited - totalWithdrawn : 0;
        if (chainSelector == parent.getStrategy().chainSelector) {
            assertTrue(
                IYieldPeer(handler.chainSelectorsToPeers(chainSelector)).getTotalValue() >= netDeposits,
                "Invariant violated: Total value in the system should be more than or equal to total USDC deposited minus total USDC withdrawn"
            );
        }
    }

    /// @notice Total Share Balances: The total shares tracked by ParentPeer should be equal to the sum of all holder balances
    function invariant_totalShareBalances_integrity() public view {
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

    /// @notice Event Consistency: The number of WithdrawCompleted events should be equal to the number of ShareBurnUpdate events
    function invariant_withdrawCompleted_shareBurnUpdate_consistency() public view {
        assertEq(
            handler.ghost_event_withdrawCompleted_emissions(),
            handler.ghost_event_shareBurnUpdate_emissions(),
            "Invariant violated: The number of WithdrawCompleted events should be equal to the number of ShareBurnUpdate events"
        );
    }

    /// @notice Event Consistency: The number of DepositInitiated events should be equal to the number of ShareMintUpdate events
    function invariant_depositInitiated_shareMintUpdate_consistency() public view {
        assertEq(
            handler.ghost_event_depositInitiated_emissions(),
            handler.ghost_event_shareMintUpdate_emissions(),
            "Invariant violated: The number of DepositInitiated events should be equal to the number of ShareMintUpdate events"
        );
    }

    /// @notice Users should always be able to withdraw what they deposited
    /// @dev this is a critical invariant that ensures the integrity of user deposit redemption
    function invariant_stablecoinRedemptionIntegrity() public {
        handler.forEachUser(this.checkRedemptionIntegrityPerUser);
    }

    function checkRedemptionIntegrityPerUser(address user) external view {
        uint256 deposited = handler.ghost_state_totalUsdcDepositedPerUser_userPrincipal(user);
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

    /// @notice Fees Consistency: The total withdrawable fees taken should be equal to the total fees taken minus total fees withdrawn
    function invariant_fees_consistency() public view {
        // @review instead of using .balanceOf, do we want to track fees in YieldFees::s_feesCollected[feeToken] mapping address => uint256?
        uint256 parentFees = usdc.balanceOf(address(parent));
        uint256 child1Fees = usdc.balanceOf(address(child1));
        uint256 child2Fees = usdc.balanceOf(address(child2));
        uint256 availableFees = parentFees + child1Fees + child2Fees;
        assertEq(
            handler.ghost_event_totalFeesTakenInStablecoin() - handler.ghost_state_totalFeesWithdrawnInStablecoin(),
            availableFees,
            "Invariant violated: The total withdrawable fees taken should be equal to the total fees taken minus total fees withdrawn"
        );
    }

    /// @notice Fee rate should always be within valid bounds
    function invariant_feeRate_bounds() public {
        handler.forEachChainSelector(this.checkFeeRateBoundsPerChainSelector);
    }

    function checkFeeRateBoundsPerChainSelector(uint64 chainSelector) external view {
        IYieldPeer peer = IYieldPeer(handler.chainSelectorsToPeers(chainSelector));
        assertTrue(
            peer.getFeeRate() <= peer.getMaxFeeRate(),
            "Invariant violated: Fee rate should not exceed maximum allowed fee rate"
        );
    }

    /// @notice Fee amount integrity: Total fees per user should equal sum of individual deposit fees
    function invariant_fee_integrity_perUser() public {
        handler.forEachUser(this.checkFeeIntegrityPerUser);
    }

    function checkFeeIntegrityPerUser(address user) external view {
        if (handler.ghost_state_totalUsdcDepositedPerUser_userPrincipal(user) > 0) {
            assertTrue(
                handler.ghost_event_totalFeesTakenInStablecoinPerUser(user)
                    == handler.calculateExpectedFeesFromDepositRecords(user),
                "Invariant violated: Total fees per user should equal sum of individual deposit fees"
            );
        }
    }

    /// @notice Total fees taken should equal sum of all individual deposit fees
    function invariant_totalFees_equals_sumOfDepositFees() public view {
        uint256 totalFeesFromEvents = handler.ghost_event_totalFeesTakenInStablecoin();
        // @review would it be cleaner to do these calculations in invariant or handler?
        uint256 totalFeesFromDepositRecords = handler.calculateTotalExpectedFeesFromDepositRecords();

        assertEq(
            totalFeesFromEvents,
            totalFeesFromDepositRecords,
            "Invariant violated: Total fees taken should equal sum of all individual deposit fees"
        );
    }

    /// @notice Fee withdrawal integrity: Non-owner should not be able to withdraw fees
    function invariant_feeWithdrawal_onlyOwner() public view {
        assertFalse(
            handler.ghost_nonFeeWithdrawer_withdrewFees(),
            "Invariant violated: Fees should only be withdrawable by fee withdrawer"
        );
    }

    /// @notice Strategy Registry: Active protocol must be registered in StrategyRegistry
    // @review:certora is this verified with certora?
    // where should it be verified? BasePeer.spec? Parent.spec because of getStrategy()?
    function invariant_activeProtocol_registered() public view {
        bytes32 protocolId = parent.getStrategy().protocolId;
        address adapter = strategyRegistryParent.getStrategyAdapter(protocolId);
        assertTrue(adapter != address(0), "Invariant violated: Active protocol must be registered in StrategyRegistry");
    }

    /// @notice Strategy Registry: Active adapter must match registered adapter for strategyprotocolId stored in ParentPeer
    // @review:certora is this verified with certora?
    function invariant_adapterMatchesRegistryOnActiveChain() public view {
        bytes32 protocolId = parent.getStrategy().protocolId;
        address activePeer = handler.chainSelectorsToPeers(parent.getStrategy().chainSelector);
        assertEq(
            IYieldPeer(activePeer).getActiveStrategyAdapter(),
            StrategyRegistry(IYieldPeer(activePeer).getStrategyRegistry()).getStrategyAdapter(protocolId),
            "Invariant violated: Active adapter must match registered adapter for protocolId stored in ParentPeer"
        );
    }

    /// @notice CRE Report Consistency: The strategy decoded in the CRE report
    /// @notice should match the strategy state stored in ParentPeer
    function invariant_decodedCREReportStrategy_matchesParentStrategyState() public view {
        /// @dev only check if CRE report was decoded
        /// @dev to avoid false positive in run where no CRE report was decoded
        if (!handler.ghost_flag_creReport_decoded()) {
            return;
        }
        IYieldPeer.Strategy memory strategy = parent.getStrategy();
        IYieldPeer.Strategy memory reportedStrategy = handler.getLastCREReceivedStrategy();

        assertEq(
            reportedStrategy.chainSelector,
            strategy.chainSelector,
            "Invariant violated: Reported chain selector should match ParentPeer strategy chain selector"
        );
        assertEq(
            reportedStrategy.protocolId,
            strategy.protocolId,
            "Invariant violated: Reported protocol Id should match ParentPeer strategy protocol Id"
        );
    }

    /// @notice CRE Report Consistency: The strategy decoded in the CRE report
    /// @notice should match the strategy emitted by ParentPeer after 'onReport'.
    /// @notice If a CRE strategy was decoded, it should match a StrategyUpdated or StrategyOptimal event
    function invariant_decodedCREReportStrategy_matches_emittedStrategy() public view {
        assertFalse(
            handler.ghost_flag_decodedStrategy_mismatchWithEmittedStrategy(),
            "Invariant violated: CRE decoded strategy should match emitted strategy"
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
