// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {BaseTest, Vm, console2, ParentCLF, ChildPeer, Share, IYieldPeer, ParentRebalancer} from "../BaseTest.t.sol";
import {Handler} from "./Handler.t.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IComet} from "../../src/interfaces/IComet.sol";
import {MockCCIPRouter} from "@chainlink-local/test/mocks/MockRouter.sol";

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
    ParentCLF internal parent;
    /// @dev Parent Rebalancer contract
    ParentRebalancer internal rebalancer;
    /// @dev Child Peer contract
    ChildPeer internal child1;
    /// @dev Child Peer contract
    ChildPeer internal child2;
    /// @dev Share contract
    Share internal share;
    /// @dev Chainlink Automation Time-based Upkeep Address
    address internal upkeep = makeAddr("upkeep");
    /// @dev Aave Pool Address
    address internal aavePool;

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
            networkConfig.tokens.usdc,
            upkeep,
            networkConfig.clf.functionsRouter,
            aavePool,
            networkConfig.protocols.comet,
            rebalancer
        );

        /// @dev define appropriate function selectors
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = Handler.deposit.selector;
        selectors[1] = Handler.withdraw.selector;
        selectors[2] = Handler.fulfillRequest.selector;

        /// @dev target handler and appropriate function selectors
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    /// @notice We are overriding the BaseTest _deployInfra because it forks live mainnets and we are going to be doing fuzz runs.
    function _deployInfra() internal override {
        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getOrCreateAnvilEthConfig();
        share = Share(networkConfig.tokens.share);
        aavePool = IPoolAddressesProvider(networkConfig.protocols.aavePoolAddressesProvider).getPool();
        rebalancer = new ParentRebalancer();

        /// @dev since we are not forking mainnets, we will deploy contracts locally
        /// the deployed peers will interact via the ccip local simulator as if they were crosschain
        /// this is a context we need to be aware of in this test suite
        /// @dev deploy the parent contract
        parent = new ParentCLF(
            networkConfig.ccip.ccipRouter,
            networkConfig.tokens.link,
            PARENT_SELECTOR,
            networkConfig.tokens.usdc,
            networkConfig.protocols.aavePoolAddressesProvider,
            networkConfig.protocols.comet,
            networkConfig.tokens.share,
            networkConfig.clf.functionsRouter,
            networkConfig.clf.donId, // 0x0
            networkConfig.clf.clfSubId, // 0
            address(rebalancer)
        );
        parent.setUpkeepAddress(upkeep);
        rebalancer.setParentPeer(address(parent));
        /// @dev deploy at least 2 child peers to cover all CCIP tx types
        child1 = new ChildPeer(
            networkConfig.ccip.ccipRouter,
            networkConfig.tokens.link,
            CHILD1_SELECTOR,
            networkConfig.tokens.usdc,
            networkConfig.protocols.aavePoolAddressesProvider,
            networkConfig.protocols.comet,
            networkConfig.tokens.share,
            PARENT_SELECTOR
        );
        child2 = new ChildPeer(
            networkConfig.ccip.ccipRouter,
            networkConfig.tokens.link,
            CHILD2_SELECTOR,
            networkConfig.tokens.usdc,
            networkConfig.protocols.aavePoolAddressesProvider,
            networkConfig.protocols.comet,
            networkConfig.tokens.share,
            PARENT_SELECTOR
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
    /// @notice Strategy Consistency: Strategy Pool should only be set on the strategy chain
    function invariant_strategy_consistency() public {
        handler.forEachChainSelector(this.checkStrategyPoolPerChainSelector);
    }

    function checkStrategyPoolPerChainSelector(uint64 chainSelector) external view {
        if (chainSelector == parent.getStrategy().chainSelector) {
            assertTrue(
                IYieldPeer(handler.chainSelectorsToPeers(chainSelector)).getStrategyPool() != address(0),
                "Invariant violated: Strategy pool should be set on the strategy chain"
            );
        } else {
            assertTrue(
                IYieldPeer(handler.chainSelectorsToPeers(chainSelector)).getStrategyPool() == address(0),
                "Invariant violated: Strategy pool should not be set on non-strategy chains"
            );
        }
    }

    /// @notice Strategy Protocol Consistency: Strategy Protocol pool on active strategy chain should match the protocol stored in ParentPeer
    function invariant_strategyProtocol_consistency() public {
        handler.forEachChainSelector(this.checkStrategyProtocolPerChainSelector);
    }

    function checkStrategyProtocolPerChainSelector(uint64 chainSelector) external view {
        if (chainSelector == parent.getStrategy().chainSelector) {
            if (parent.getStrategy().protocol == IYieldPeer.Protocol.Aave) {
                assertEq(
                    IYieldPeer(handler.chainSelectorsToPeers(chainSelector)).getAave(),
                    IYieldPeer(handler.chainSelectorsToPeers(chainSelector)).getStrategyPool(),
                    "Invariant violated: Strategy protocol on active strategy chain should match the protocol stored in ParentPeer"
                );
            } else if (parent.getStrategy().protocol == IYieldPeer.Protocol.Compound) {
                assertEq(
                    IYieldPeer(handler.chainSelectorsToPeers(chainSelector)).getCompound(),
                    IYieldPeer(handler.chainSelectorsToPeers(chainSelector)).getStrategyPool(),
                    "Invariant violated: Strategy protocol on active strategy chain should match the protocol stored in ParentPeer"
                );
            }
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
        uint256 totalDeposited = handler.ghost_state_totalUsdcDeposited();
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

    /// @notice Users should always be able to withdraw what they deposited (minus fees, but those arent implemented yet)
    /// @dev this is a critical invariant that ensures the integrity of user deposit redemption
    function invariant_stablecoinRedemptionIntegrity() public {
        handler.forEachUser(this.checkRedemptionIntegrityPerUser);
    }

    function checkRedemptionIntegrityPerUser(address user) external view {
        uint256 deposited = handler.ghost_state_totalUsdcDepositedPerUser(user);
        uint256 withdrawn = handler.ghost_event_totalUsdcWithdrawnPerUser(user);
        uint256 netDeposits = deposited > withdrawn ? deposited - withdrawn : 0;
        uint256 userShares = share.balanceOf(user);

        uint256 totalValue =
            IYieldPeer(handler.chainSelectorsToPeers(parent.getStrategy().chainSelector)).getTotalValue();
        uint256 totalValueConverted = _convertUsdcToShare(totalValue);
        uint256 minUsdcValueInShares = _convertUsdcToShare(1);
        uint256 totalShares = parent.getTotalShares();

        if (totalShares > 0) {
            uint256 withdrawable = (userShares * totalValueConverted) / totalShares;
            uint256 withdrawableConverted = _convertShareToUsdc(withdrawable);
            uint256 minWithdrawable = netDeposits * 990 / 1000; // Allow 1% slippage
            if (withdrawableConverted < minWithdrawable) {}
            assertTrue(
                withdrawableConverted >= minWithdrawable || netDeposits < minUsdcValueInShares,
                "Invariant violated: User should be able to withdraw what they deposited, except for left over dust"
            );
        } else {
            assertTrue(netDeposits == 0, "Invariant violated: User should be able to withdraw what they deposited");
        }
    }
}
