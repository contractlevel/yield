// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {BaseTest, Vm, console2, ParentPeer, ChildPeer, Share, IYieldPeer, Rebalancer} from "../BaseTest.t.sol";
import {Handler} from "./Handler.t.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IComet} from "../../src/interfaces/IComet.sol";
import {MockCCIPRouter} from "@chainlink-local/test/mocks/MockRouter.sol";
import {AaveV3Adapter} from "../../src/adapters/AaveV3Adapter.sol";
import {CompoundV3Adapter} from "../../src/adapters/CompoundV3Adapter.sol";
import {StrategyRegistry} from "../../src/modules/StrategyRegistry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
    /// @dev Chainlink Automation Time-based Upkeep Address
    address internal upkeep = makeAddr("upkeep");
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
        _dealLinkToPeers(true, address(parent), address(child1), address(child2), networkConfig.tokens.link);
        _setCrossChainPeers();

        /// @dev deploy handler
        handler = new Handler(
            parent,
            child1,
            child2,
            share,
            networkConfig.ccip.ccipRouter,
            address(usdc),
            upkeep,
            networkConfig.clf.functionsRouter,
            aavePool,
            networkConfig.protocols.comet,
            rebalancer
        );

        /// @dev define appropriate function selectors
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = Handler.deposit.selector;
        selectors[1] = Handler.withdraw.selector;
        selectors[2] = Handler.fulfillRequest.selector;
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
        rebalancer =
            new Rebalancer(networkConfig.clf.functionsRouter, networkConfig.clf.donId, networkConfig.clf.clfSubId);

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
        parent.setRebalancer(address(rebalancer));
        rebalancer.setUpkeepAddress(upkeep);
        rebalancer.setParentPeer(address(parent));
        /// @dev deploy parent adapters
        strategyRegistryParent = new StrategyRegistry();
        aaveV3AdapterParent = new AaveV3Adapter(address(parent), networkConfig.protocols.aavePoolAddressesProvider);
        compoundV3AdapterParent = new CompoundV3Adapter(address(parent), networkConfig.protocols.comet);
        strategyRegistryParent.setStrategyAdapter(keccak256(abi.encodePacked("aave-v3")), address(aaveV3AdapterParent));
        strategyRegistryParent.setStrategyAdapter(
            keccak256(abi.encodePacked("compound-v3")), address(compoundV3AdapterParent)
        );
        rebalancer.setStrategyRegistry(address(strategyRegistryParent));
        parent.setStrategyRegistry(address(strategyRegistryParent));
        parent.setInitialActiveStrategy(keccak256(abi.encodePacked("aave-v3")));

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
        child1.setStrategyRegistry(address(strategyRegistryChild1));
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
        child2.setStrategyRegistry(address(strategyRegistryChild2));
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

    function _setCrossChainPeers() internal override {
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

        MockCCIPRouter(networkConfig.ccip.ccipRouter).setPeerToChainSelector(address(parent), PARENT_SELECTOR);
        MockCCIPRouter(networkConfig.ccip.ccipRouter).setPeerToChainSelector(address(child1), CHILD1_SELECTOR);
        MockCCIPRouter(networkConfig.ccip.ccipRouter).setPeerToChainSelector(address(child2), CHILD2_SELECTOR);
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
                IYieldPeer(handler.chainSelectorsToPeers(chainSelector)).getStrategyAdapter(
                    parent.getStrategy().protocolId
                ),
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
            handler.ghost_nonOwner_withdrewFees(), "Invariant violated: Fees should only be withdrawable by owner"
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
