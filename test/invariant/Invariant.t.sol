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
    IYieldPeer
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
import {IStrategyAdapter} from "../../src/interfaces/IStrategyAdapter.sol";

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
    StrategyRegistry internal strategyRegistryParent;
    /// @dev Strategy Registry contract for child 1
    StrategyRegistry internal strategyRegistryChild1;
    /// @dev Strategy Registry contract for child 2
    StrategyRegistry internal strategyRegistryChild2;

    /// @dev Aave Adapter contract for parent
    AaveV3Adapter internal aaveV3AdapterParent;
    /// @dev Compound Adapter contract for parent
    CompoundV3Adapter internal compoundV3AdapterParent;
    /// @dev Aave Adapter contract for child 1
    AaveV3Adapter internal aaveV3AdapterChild1;
    /// @dev Compound Adapter contract for child 1
    CompoundV3Adapter internal compoundV3AdapterChild1;
    /// @dev Aave Adapter contract for child 2
    AaveV3Adapter internal aaveV3AdapterChild2;
    /// @dev Compound Adapter contract for child 2
    CompoundV3Adapter internal compoundV3AdapterChild2;

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

    /// @notice We are overriding the BaseTest _deployInfra because it forks live mainnets and we are going to be doing fuzz runs.
    function _deployInfra() internal override {
        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getOrCreateAnvilEthConfig();
        usdc = IERC20(networkConfig.tokens.usdc);
        share = Share(networkConfig.tokens.share);
        aavePool = IPoolAddressesProvider(networkConfig.protocols.aavePoolAddressesProvider).getPool();
        rebalancer = new Rebalancer();

        /// @dev since we are not forking mainnets, we will deploy contracts locally
        /// the deployed peers will interact via the ccip local simulator as if they were crosschain
        /// this is a context we need to be aware of in this test suite
        /// @dev deploy the parent contract
        parent = new ParentPeer(
            networkConfig.ccip.ccipRouter,
            networkConfig.tokens.link,
            PARENT_SELECTOR,
            networkConfig.tokens.usdc,
            networkConfig.tokens.share
        );
        /// @dev temp config admin role granted to deployer/owner to set necessary configs
        parent.grantRole(Roles.CONFIG_ADMIN_ROLE, parent.owner());
        parent.setRebalancer(address(rebalancer));
        parent.setSupportedProtocol(keccak256(abi.encodePacked("aave-v3")), true);
        parent.setSupportedProtocol(keccak256(abi.encodePacked("compound-v3")), true);
        _changePrank(rebalancer.owner());
        rebalancer.setParentPeer(address(parent));
        _stopPrank();

        /// @dev deploy parent adapters
        strategyRegistryParent = new StrategyRegistry();
        aaveV3AdapterParent = new AaveV3Adapter(address(parent), networkConfig.protocols.aavePoolAddressesProvider);
        compoundV3AdapterParent = new CompoundV3Adapter(address(parent), networkConfig.protocols.comet);
        strategyRegistryParent.setStrategyAdapter(keccak256(abi.encodePacked("aave-v3")), address(aaveV3AdapterParent));
        strategyRegistryParent.setStrategyAdapter(
            keccak256(abi.encodePacked("compound-v3")), address(compoundV3AdapterParent)
        );

        parent.setStrategyRegistry(address(strategyRegistryParent));
        parent.setInitialActiveStrategy(keccak256(abi.encodePacked("aave-v3")));
        parent.revokeRole(Roles.CONFIG_ADMIN_ROLE, parent.owner());

        /// @dev deploy at least 2 child peers to cover all CCIP tx types
        child1 = new ChildPeer(
            networkConfig.ccip.ccipRouter,
            networkConfig.tokens.link,
            CHILD1_SELECTOR,
            networkConfig.tokens.usdc,
            networkConfig.tokens.share,
            PARENT_SELECTOR
        );
        /// @dev child adapters
        strategyRegistryChild1 = new StrategyRegistry();
        aaveV3AdapterChild1 = new AaveV3Adapter(address(child1), networkConfig.protocols.aavePoolAddressesProvider);
        compoundV3AdapterChild1 = new CompoundV3Adapter(address(child1), networkConfig.protocols.comet);
        /// @dev role granted to set registry
        child1.grantRole(Roles.CONFIG_ADMIN_ROLE, child1.owner());
        child1.setStrategyRegistry(address(strategyRegistryChild1));
        child1.revokeRole(Roles.CONFIG_ADMIN_ROLE, child1.owner());
        strategyRegistryChild1.setStrategyAdapter(keccak256(abi.encodePacked("aave-v3")), address(aaveV3AdapterChild1));
        strategyRegistryChild1.setStrategyAdapter(
            keccak256(abi.encodePacked("compound-v3")), address(compoundV3AdapterChild1)
        );

        child2 = new ChildPeer(
            networkConfig.ccip.ccipRouter,
            networkConfig.tokens.link,
            CHILD2_SELECTOR,
            networkConfig.tokens.usdc,
            networkConfig.tokens.share,
            PARENT_SELECTOR
        );
        strategyRegistryChild2 = new StrategyRegistry();
        aaveV3AdapterChild2 = new AaveV3Adapter(address(child2), networkConfig.protocols.aavePoolAddressesProvider);
        compoundV3AdapterChild2 = new CompoundV3Adapter(address(child2), networkConfig.protocols.comet);
        /// @dev role granted to set registry
        child2.grantRole(Roles.CONFIG_ADMIN_ROLE, child2.owner());
        child2.setStrategyRegistry(address(strategyRegistryChild2));
        child2.revokeRole(Roles.CONFIG_ADMIN_ROLE, child2.owner());
        strategyRegistryChild2.setStrategyAdapter(keccak256(abi.encodePacked("aave-v3")), address(aaveV3AdapterChild2));
        strategyRegistryChild2.setStrategyAdapter(
            keccak256(abi.encodePacked("compound-v3")), address(compoundV3AdapterChild2)
        );

        /// @dev grant roles to the contracts
        _changePrank(share.owner());
        share.grantMintAndBurnRoles(address(parent));
        share.grantMintAndBurnRoles(address(child1));
        share.grantMintAndBurnRoles(address(child2));
        _stopPrank();

        /// @dev our mocks of aave and compound will need to be dealt usdc
        deal(networkConfig.tokens.usdc, aavePool, STRATEGY_POOL_USDC_STARTING_BALANCE);
        deal(networkConfig.tokens.usdc, networkConfig.protocols.comet, STRATEGY_POOL_USDC_STARTING_BALANCE);
    }

    function _grantRoles() internal override {
        // grant roles - parent
        _changePrank(parent.owner());
        parent.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser);
        parent.grantRole(Roles.EMERGENCY_UNPAUSER_ROLE, emergencyUnpauser);
        parent.grantRole(Roles.CONFIG_ADMIN_ROLE, configAdmin);
        parent.grantRole(Roles.CROSS_CHAIN_ADMIN_ROLE, crossChainAdmin);
        parent.grantRole(Roles.FEE_WITHDRAWER_ROLE, feeWithdrawer);
        parent.grantRole(Roles.FEE_RATE_SETTER_ROLE, feeRateSetter);
        assertTrue(parent.hasRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser));
        assertTrue(parent.hasRole(Roles.EMERGENCY_UNPAUSER_ROLE, emergencyUnpauser));
        assertTrue(parent.hasRole(Roles.CONFIG_ADMIN_ROLE, configAdmin));
        assertTrue(parent.hasRole(Roles.CROSS_CHAIN_ADMIN_ROLE, crossChainAdmin));
        assertTrue(parent.hasRole(Roles.FEE_WITHDRAWER_ROLE, feeWithdrawer));
        assertTrue(parent.hasRole(Roles.FEE_RATE_SETTER_ROLE, feeRateSetter));

        // grant roles - child 1
        _changePrank(child1.owner());
        child1.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser);
        child1.grantRole(Roles.EMERGENCY_UNPAUSER_ROLE, emergencyUnpauser);
        child1.grantRole(Roles.CONFIG_ADMIN_ROLE, configAdmin);
        child1.grantRole(Roles.CROSS_CHAIN_ADMIN_ROLE, crossChainAdmin);
        child1.grantRole(Roles.FEE_WITHDRAWER_ROLE, feeWithdrawer);
        child1.grantRole(Roles.FEE_RATE_SETTER_ROLE, feeRateSetter);
        assertTrue(child1.hasRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser));
        assertTrue(child1.hasRole(Roles.EMERGENCY_UNPAUSER_ROLE, emergencyUnpauser));
        assertTrue(child1.hasRole(Roles.CONFIG_ADMIN_ROLE, configAdmin));
        assertTrue(child1.hasRole(Roles.CROSS_CHAIN_ADMIN_ROLE, crossChainAdmin));
        assertTrue(child1.hasRole(Roles.FEE_WITHDRAWER_ROLE, feeWithdrawer));
        assertTrue(child1.hasRole(Roles.FEE_RATE_SETTER_ROLE, feeRateSetter));

        // grant roles - child 2
        _changePrank(child2.owner());
        child2.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser);
        child2.grantRole(Roles.EMERGENCY_UNPAUSER_ROLE, emergencyUnpauser);
        child2.grantRole(Roles.CONFIG_ADMIN_ROLE, configAdmin);
        child2.grantRole(Roles.CROSS_CHAIN_ADMIN_ROLE, crossChainAdmin);
        child2.grantRole(Roles.FEE_WITHDRAWER_ROLE, feeWithdrawer);
        child2.grantRole(Roles.FEE_RATE_SETTER_ROLE, feeRateSetter);
        assertTrue(child2.hasRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser));
        assertTrue(child2.hasRole(Roles.EMERGENCY_UNPAUSER_ROLE, emergencyUnpauser));
        assertTrue(child2.hasRole(Roles.CONFIG_ADMIN_ROLE, configAdmin));
        assertTrue(child2.hasRole(Roles.CROSS_CHAIN_ADMIN_ROLE, crossChainAdmin));
        assertTrue(child2.hasRole(Roles.FEE_WITHDRAWER_ROLE, feeWithdrawer));
        assertTrue(child2.hasRole(Roles.FEE_RATE_SETTER_ROLE, feeRateSetter));

        _stopPrank();
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

    /// @notice MAX Sentinel Validation: When uint256.max is passed for withdrawal, validation should always pass
    /// @dev This invariant verifies that the adapter's validation check (actualWithdrawn >= totalValue) always passes
    /// @dev Both AaveV3Adapter and CompoundV3Adapter check: if (actualWithdrawn < totalValue) revert
    /// @dev This ensures the validation logic is correct and doesn't cause false reverts
    function invariant_maxSentinel_validationAlwaysPasses() public view {
        /// @dev check if any MAX sentinel withdrawals occurred during fuzzing
        uint256 withdrawals = handler.ghost_maxSentinelWithdrawals();

        /// @dev if MAX sentinel was never called successfully, nothing to verify
        if (withdrawals == 0) return;

        /// @dev get the totalValue that was in the adapter before withdrawal (expected amount)
        uint256 totalValue = handler.ghost_maxSentinelExpected();

        /// @dev get the actual amount withdrawn by the protocol (Aave/Compound)
        uint256 actualWithdrawn = handler.ghost_maxSentinelReceived();

        /// @dev adapter validation checks: if (actualWithdrawn < totalValue) revert
        /// @dev for validation to pass, we need: actualWithdrawn >= totalValue
        /// @dev special case: if totalValue was 0 (empty pool), actualWithdrawn can also be 0
        assertTrue(
            actualWithdrawn >= totalValue || totalValue == 0,
            "Invariant violated: MAX sentinel validation should pass - actualWithdrawn must be >= totalValue"
        );
    }

    /// @notice MAX Sentinel Completeness: When uint256.max is withdrawn, ALL protocol pool balance should be withdrawn
    /// @dev This invariant verifies that MAX sentinel withdrawal drains the entire protocol pool balance
    /// @dev Aave/Compound handle MAX sentinel internally and ensure they withdraw everything
    /// @dev The adapter's balance in the protocol (via getTotalValue) must be 0 after MAX withdrawal
    function invariant_maxSentinel_withdrawsAllProtocolBalance() public view {
        /// @dev check if any MAX sentinel withdrawals occurred during fuzzing
        uint256 withdrawals = handler.ghost_maxSentinelWithdrawals();

        /// @dev if MAX sentinel was never called successfully, nothing to verify
        if (withdrawals == 0) return;

        /// @dev get the totalValue that was in the adapter before withdrawal
        uint256 totalValueBefore = handler.ghost_maxSentinelExpected();

        /// @dev if there was nothing to withdraw, skip check (empty pool scenario)
        if (totalValueBefore == 0) return;

        /// @dev get the actual amount withdrawn by the protocol
        uint256 actualWithdrawn = handler.ghost_maxSentinelReceived();

        /// @dev MAX sentinel should withdraw ALL balance from the protocol pool
        /// @dev actualWithdrawn should equal totalValueBefore (protocols ensure this)
        assertEq(
            actualWithdrawn,
            totalValueBefore,
            "Invariant violated: MAX sentinel should withdraw all protocol balance - actualWithdrawn should equal totalValueBefore"
        );

        /// @dev verify adapter balance in protocol is 0 after MAX sentinel withdrawal
        /// @dev getTotalValue() returns the adapter's balance in the protocol (Aave/Compound)
        uint256 adapterBalanceAfter = handler.ghost_maxSentinelAdapterBalanceAfter();

        /// @dev after MAX withdrawal, Aave/Compound should have withdrawn everything, leaving 0
        /// @dev this ensures the protocol pool is completely drained as expected
        assertEq(
            adapterBalanceAfter,
            0,
            "Invariant violated: Adapter balance in protocol should be 0 after MAX sentinel withdrawal - Aave/Compound should have withdrawn everything"
        );
    }

    /*//////////////////////////////////////////////////////////////
                            DIRECT TESTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Fuzz test for MAX sentinel withdrawal functionality
    /// @dev This test verifies MAX sentinel withdrawal behavior deterministically
    function testFuzz_MaxSentinelDirectly() public {
        /// @dev get the active chain selector and corresponding peer
        uint64 chainSelector = parent.getStrategy().chainSelector;
        address peer = chainSelector == PARENT_SELECTOR
            ? address(parent)
            : chainSelector == CHILD1_SELECTOR ? address(child1) : address(child2);
        IYieldPeer yieldPeer = IYieldPeer(peer);
        address activeAdapter = yieldPeer.getActiveStrategyAdapter();

        /// @dev ensure adapter has some balance first by making a deposit
        /// @dev deposit(bool isNewDepositor, uint256 addressSeed, uint256 depositAmount, uint256 chainSelectorSeed)
        handler.deposit(true, 1, 100_000_000, uint256(chainSelector));

        /// @dev verify adapter has balance before MAX withdrawal
        uint256 totalValueBefore = IStrategyAdapter(activeAdapter).getTotalValue(address(usdc));
        assertGt(totalValueBefore, 0, "Adapter should have balance before MAX withdrawal");

        /// @dev track peer's USDC balance before withdrawal to verify funds received
        uint256 peerBalanceBefore = usdc.balanceOf(peer);

        /// @dev execute MAX sentinel withdrawal through handler
        handler.testMaxSentinelWithdraw(uint256(chainSelector));

        /// @dev verify we tracked the withdrawal (proves it actually executed)
        assertEq(handler.ghost_maxSentinelWithdrawals(), 1, "Should track one MAX sentinel withdrawal");

        /// @dev verify the adapter's validation passed (actualWithdrawn >= totalValue)
        assertGe(
            handler.ghost_maxSentinelReceived(),
            handler.ghost_maxSentinelExpected(),
            "MAX sentinel validation should pass: actualWithdrawn >= totalValue"
        );

        /// @dev verify adapter is now empty (MAX withdrawal drained it completely)
        uint256 totalValueAfter = IStrategyAdapter(activeAdapter).getTotalValue(address(usdc));
        assertEq(totalValueAfter, 0, "Adapter should be empty after MAX withdrawal");

        /// @dev verify peer received the funds from the withdrawal
        uint256 peerBalanceAfter = usdc.balanceOf(peer);
        assertGt(peerBalanceAfter, peerBalanceBefore, "Peer should receive funds from MAX withdrawal");
        /// @dev verify the amount received matches what was actually withdrawn
        assertEq(
            peerBalanceAfter - peerBalanceBefore,
            handler.ghost_maxSentinelReceived(),
            "Peer balance increase should match actual withdrawn amount"
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
