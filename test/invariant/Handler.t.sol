// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {
    Test,
    Vm,
    console2,
    ParentPeer,
    ChildPeer,
    IERC20,
    Share,
    IYieldPeer,
    Rebalancer,
    Roles,
    IYieldPeer,
    WorkflowHelpers
} from "../BaseTest.t.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @notice This contract is used to handle fuzzed interactions with the external functions of the system to test invariants.
contract Handler is Test {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev we are making an assumption that no deposit higher than 1m usdc will happen
    uint256 internal constant MAX_DEPOSIT_AMOUNT = 1_000_000_000_000;
    uint256 internal constant MIN_DEPOSIT_AMOUNT = 1_000_000;
    uint256 internal constant INITIAL_DEPOSIT_AMOUNT = 100_000_000;
    uint256 internal constant POOL_DEAL_AMOUNT = 1_000_000_000_000_000_000; // 1T USDC

    ParentPeer internal parent;
    ChildPeer internal child1;
    ChildPeer internal child2;
    Share internal share;
    address internal ccipRouter;
    IERC20 internal usdc;
    address internal forwarder = makeAddr("forwarder");
    address internal admin = makeAddr("admin");
    address internal aavePool;
    address internal compoundPool;
    Rebalancer internal rebalancer;

    uint64 internal parentChainSelector;
    uint64 internal child1ChainSelector;
    uint64 internal child2ChainSelector;
    mapping(uint64 => address) public chainSelectorsToPeers;
    mapping(address => uint64) public peersToChainSelectors;

    /// @dev workflow params and metadata
    address internal workflowOwner = makeAddr("workflowOwner");
    bytes32 internal workflowId = bytes32("rebalanceWorkflowId");
    string internal workflowNameRaw = "yieldcoin-rebalance-workflow";
    bytes10 internal workflowName = WorkflowHelpers.createWorkflowName(workflowNameRaw);
    bytes internal workflowMetadata = WorkflowHelpers.createWorkflowMetadata(workflowId, workflowName, workflowOwner);

    /// @dev struct is used to track the actors with the system roles
    /// @notice needed to avoid stack too deep errors
    struct SystemRoles {
        address emergencyPauser;
        address emergencyUnpauser;
        address configAdmin;
        address crossChainAdmin;
        address feeWithdrawer;
        address feeRateSetter;
    }
    SystemRoles internal systemRoles;

    /*//////////////////////////////////////////////////////////////
                            ENUMERABLE SETS
    //////////////////////////////////////////////////////////////*/
    /// @dev track the users in the system (the only role for a user is to deposit and withdraw USDC)
    EnumerableSet.AddressSet internal users;
    /// @dev track the chain selectors in the system
    EnumerableSet.UintSet internal chainSelectors;

    /*//////////////////////////////////////////////////////////////
                                 GHOSTS
    //////////////////////////////////////////////////////////////*/
    /// @dev track the total shares burned by incrementing by shareBurnAmount everytime share.transferAndCall is used to withdraw USDC
    uint256 public ghost_state_totalSharesBurned;

    /// @dev track the total shares minted amount according to ShareMintUpdate events emitted by ParentPeet
    uint256 public ghost_event_totalSharesMinted;
    /// @dev track the total shares burned amount according to ShareBurnUpdate events emitted by ParentPeer
    uint256 public ghost_event_totalSharesBurned;

    /// @dev track total USDC deposited across the system
    uint256 public ghost_state_totalUsdcDeposited;

    /// @dev track the total USDC deposited as user principal (initial deposit amount minus fees)
    uint256 public ghost_state_totalUsdcDeposited_userPrincipal;

    /// @dev track the total USDC withdrawn amount according to WithdrawCompleted events emitted by Peers
    uint256 public ghost_event_totalUsdcWithdrawn;

    /// @dev track total USDC deposited per user in user principal (initial deposit amount minus fees)
    mapping(address user => uint256 usdcDepositAmount) public ghost_state_totalUsdcDepositedPerUser_userPrincipal;

    /// @dev tracks the total usdc withdrawn per user emitted by WithdrawCompleted events
    mapping(address user => uint256 usdcWithdrawAmount) public ghost_event_totalUsdcWithdrawnPerUser;

    /// @dev incremented by 1 everytime a DepositInitiated event is emitted
    uint256 public ghost_event_depositInitiated_emissions;
    /// @dev incremented by 1 everytime a ShareMintUpdate event is emitted
    uint256 public ghost_event_shareMintUpdate_emissions;

    /// @dev incremented by 1 everytime a WithdrawCompleted event is emitted
    uint256 public ghost_event_withdrawCompleted_emissions;
    /// @dev incremented by 1 everytime a ShareBurnUpdate event is emitted
    uint256 public ghost_event_shareBurnUpdate_emissions;

    /// @dev tracks the total shares minted per user - based on ShareMintUpdate events
    mapping(address user => uint256 totalSharesMinted) public ghost_event_totalSharesMintedPerUser;
    /// @dev track total shares burnt per user - based on value passed to share.transferAndCall
    mapping(address user => uint256 shareBurnAmount) public ghost_state_totalSharesBurnedPerUser;

    /// @dev tracks the total fees withdrawn, in stablecoin
    uint256 public ghost_state_totalFeesWithdrawnInStablecoin;

    /// @dev tracks the number of FeeTaken events
    uint256 public ghost_event_feeTaken_emissions;
    /// @dev tracks the number of FeeWithdrawn events
    uint256 public ghost_event_feeWithdrawn_emissions; // unused

    /// @dev tracks the total fees taken in stablecoins per user - based on FeeTaken events
    mapping(address user => uint256 totalFeesTaken) public ghost_event_totalFeesTakenInStablecoinPerUser;
    /// @dev tracks the total fees taken in stablecoins - based on FeeTaken events
    uint256 public ghost_event_totalFeesTakenInStablecoin;

    /// @dev tracks the current fee rate
    uint256 public ghost_state_feeRate;

    /// @dev tracks if a non-FeeWithdrawer withdrew fees
    bool public ghost_nonFeeWithdrawer_withdrewFees;

    /// @dev tracks decoded strategy in CRE report
    IYieldPeer.Strategy public ghost_event_lastCREReceivedStrategy;

    /// @dev tracks previous strategy before onReport changes it
    IYieldPeer.Strategy public ghost_state_previousStrategy;

    /// @dev ghost flag to track if the CRE report was decoded
    bool public ghost_flag_creReport_decoded;

    /// @dev ghost flag to track if the decoded CRE report strategy
    /// @dev doesn't match the strategy emitted by Parent after 'onReport'
    bool public ghost_flag_decodedStrategy_mismatchWithEmittedStrategy;

    /*//////////////////////////////////////////////////////////////
                            DEPOSIT TRACKING
    //////////////////////////////////////////////////////////////*/
    /// @dev struct to track individual deposits with their fee rates
    struct DepositRecord {
        address user;
        uint256 amount;
        uint256 feeRate;
        uint256 timestamp;
        uint256 fee;
    }

    /// @dev mapping from user to array of their deposits
    mapping(address => DepositRecord[]) public ghost_userDeposits;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        ParentPeer _parent,
        ChildPeer _child1,
        ChildPeer _child2,
        Share _share,
        address _ccipRouter,
        address _usdc,
        address _aavePool,
        address _compoundPool,
        Rebalancer _rebalancer,
        Handler.SystemRoles memory _systemRoles
    ) {
        parent = _parent;
        child1 = _child1;
        child2 = _child2;
        share = _share;
        ccipRouter = _ccipRouter;
        usdc = IERC20(_usdc);
        aavePool = _aavePool;
        compoundPool = _compoundPool;
        rebalancer = _rebalancer;
        systemRoles = _systemRoles;

        vm.prank(rebalancer.owner());
        rebalancer.setKeystoneForwarder(forwarder);

        parentChainSelector = parent.getThisChainSelector();
        child1ChainSelector = child1.getThisChainSelector();
        child2ChainSelector = child2.getThisChainSelector();

        chainSelectorsToPeers[parentChainSelector] = address(parent);
        chainSelectorsToPeers[child1ChainSelector] = address(child1);
        chainSelectorsToPeers[child2ChainSelector] = address(child2);

        chainSelectors.add(parentChainSelector);
        chainSelectors.add(child1ChainSelector);
        chainSelectors.add(child2ChainSelector);

        /// @dev admin deposits USDC to the system to mitigate share inflation attacks
        setFeeRate(0);
        _adminDeposit();

        uint256 halfMax = type(uint256).max / 2;
        deal(address(usdc), aavePool, halfMax);
        deal(address(usdc), compoundPool, halfMax);
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice This function handles deposits to the system
    /// @param isNewDepositor whether the depositor is a new user or an existing user
    /// @param addressSeed the seed used to create or get the depositor
    /// @param depositAmount the amount of USDC to deposit
    /// @param chainSelectorSeed the seed used to get the deposit chain selector
    function deposit(bool isNewDepositor, uint256 addressSeed, uint256 depositAmount, uint256 chainSelectorSeed)
        public
        returns (address depositor)
    {
        /// @dev create or get the depositor
        if (isNewDepositor) depositor = _seedToAddress(addressSeed);
        else depositor = _createOrGetUser(addressSeed);

        /// @dev bind the fuzzed deposit amount and deal the USDC to the depositor
        depositAmount = bound(depositAmount, MIN_DEPOSIT_AMOUNT, MAX_DEPOSIT_AMOUNT);
        deal(address(usdc), depositor, depositAmount);

        /// @dev bind the fuzzed chain selector to the range of valid values
        uint64 chainSelector = uint64(bound(chainSelectorSeed, 1, 3));

        vm.recordLogs();

        /// @dev deposit the USDC to the peer
        address peer = chainSelectorsToPeers[chainSelector];
        _deposit(depositor, depositAmount, peer);
        console2.log("depositor:", depositor);
        console2.log("depositAmount:", depositAmount);

        /// @dev update the ghost state
        _updateDepositGhosts(depositor, depositAmount);
        _handleDepositLogs();
    }

    /// @notice This function handles withdraws from the system
    /// @param addressSeed the seed used to create or get the withdrawer
    /// @notice If the withdrawer has no shares, the function will deposit some USDC to get shares
    /// @param shareBurnAmount the amount of shares to burn
    /// @param chainSelectorSeed the seed used to get the withdraw chain selector
    /// @param usdcDepositAmount the amount of USDC to deposit if the withdrawer has no shares
    function withdraw(
        uint256 addressSeed,
        uint256 shareBurnAmount,
        uint256 chainSelectorSeed,
        uint256 usdcDepositAmount
    ) public {
        /// @dev ensure the pools have enough liquidity
        _dealPoolsUsdc();

        /// @dev create or get the withdrawer
        address withdrawer = _createOrGetUser(addressSeed);
        uint256 withdrawerShareBalance = share.balanceOf(withdrawer);

        /// @dev if the withdrawer has no shares, deposit some USDC to get shares
        if (withdrawerShareBalance == 0) {
            withdrawer = deposit(true, addressSeed, usdcDepositAmount, chainSelectorSeed);
            withdrawerShareBalance = share.balanceOf(withdrawer);
        }

        /// @dev bind the fuzzed withdraw amount to the range of valid values
        shareBurnAmount = bound(shareBurnAmount, 1, withdrawerShareBalance);
        /// @dev bind the fuzzed chain selectors to the range of valid values
        uint64 chainSelector = uint64(bound(chainSelectorSeed, 1, 3));

        vm.recordLogs();

        /// @dev withdraw the shares from the peer
        address peer = chainSelectorsToPeers[chainSelector];
        _changePrank(withdrawer);
        share.transferAndCall(peer, shareBurnAmount, "");
        console2.log("withdrawer:", withdrawer);
        console2.log("shareBurnAmount:", shareBurnAmount);

        /// @dev update the ghost state
        _updateWithdrawGhosts(withdrawer, shareBurnAmount);
        _handleWithdrawLogs();
    }

    /// @notice This function handles rebalancer cre reports
    /// @param chainSelectorSeed the seed used to set the chain selector in the report
    /// @param protocolIdSeed the seed used to set the protocol id in the report
    function onReport(uint256 chainSelectorSeed, uint256 protocolIdSeed) public {
        /// @dev ensure the pools have enough liquidity
        _dealPoolsUsdc();

        /// @dev bind the chain selector and protocol enum to the range of valid values
        uint64 chainSelector = uint64(bound(chainSelectorSeed, 1, 3));
        bytes32 protocolId;
        if (protocolIdSeed % 2 == 0) protocolId = keccak256(abi.encodePacked("aave-v3"));
        else protocolId = keccak256(abi.encodePacked("compound-v3"));

        /// @dev workflow report setup
        bytes memory report = WorkflowHelpers.createWorkflowReport(chainSelector, protocolId);
        IYieldPeer.Strategy memory currentStrategy = parent.getStrategy();
        if (currentStrategy.chainSelector == chainSelector && currentStrategy.protocolId == protocolId) {
            return; // @review wasted run
        }

        /// @dev simulate the passing of time
        /// @notice we are simulating CRE workflow triggering once per day
        vm.warp(block.timestamp + 1 days);

        /// @dev store previous(current) strategy before onReport changes it
        ghost_state_previousStrategy = parent.getStrategy();

        vm.recordLogs();
        _changePrank(forwarder);
        rebalancer.onReport(workflowMetadata, report);
        _handleOnReportLogs();
    }

    /// @notice This function handles withdrawing fees
    function withdrawFees(address nonFeeWithdrawerAddr) public {
        uint256 parentFees = usdc.balanceOf(address(parent));
        uint256 child1Fees = usdc.balanceOf(address(child1));
        uint256 child2Fees = usdc.balanceOf(address(child2));
        uint256 availableFees = parentFees + child1Fees + child2Fees;
        if (availableFees == 0) return; // @review wasted run

        /// @dev update the ghost state
        ghost_state_totalFeesWithdrawnInStablecoin += availableFees;

        /// @dev try call from non-fee withdrawer to assert it never succeeds
        vm.assume(nonFeeWithdrawerAddr != systemRoles.feeWithdrawer);
        _changePrank(nonFeeWithdrawerAddr);
        try parent.withdrawFees(address(usdc)) {
            ghost_nonFeeWithdrawer_withdrewFees = true;
        } catch {
            console2.log("nonFeeWithdrawerRoleAddr withdrawFees failed");
        }

        /// @dev withdraw the fees
        _changePrank(systemRoles.feeWithdrawer);
        if (parentFees > 0) parent.withdrawFees(address(usdc));
        if (child1Fees > 0) child1.withdrawFees(address(usdc));
        if (child2Fees > 0) child2.withdrawFees(address(usdc));
    }

    /// @notice This function handles setting the fee rate
    /// @param feeRate the fee rate to set
    function setFeeRate(uint256 feeRate) public {
        /// @dev bind the fee rate to the range of valid values
        feeRate = bound(feeRate, 0, parent.getMaxFeeRate());
        /// @dev update the ghost state
        ghost_state_feeRate = feeRate;
        /// @dev update the fee rate
        _changePrank(systemRoles.feeRateSetter);
        parent.setFeeRate(feeRate);
        child1.setFeeRate(feeRate);
        child2.setFeeRate(feeRate);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    function _deposit(address depositor, uint256 depositAmount, address peer) internal {
        _changePrank(depositor);
        usdc.approve(peer, depositAmount);
        IYieldPeer(peer).deposit(depositAmount);
        _stopPrank();
    }

    /// @dev calculate the fee for a deposit
    function _calculateFee(uint256 depositAmount) internal view returns (uint256) {
        return (depositAmount * parent.getFeeRate()) / parent.getFeeRateDivisor();
    }

    /*//////////////////////////////////////////////////////////////
                            DEPOSIT TRACKING
    //////////////////////////////////////////////////////////////*/
    /// @dev record a deposit with its fee rate and timestamp
    function _recordDeposit(address user, uint256 amount) internal {
        DepositRecord memory depositRecord = DepositRecord({
            user: user,
            amount: amount, // @notice this is the total deposit amount, including the fee - NOT the user principal
            feeRate: parent.getFeeRate(),
            timestamp: block.timestamp,
            fee: _calculateFee(amount)
        });

        ghost_userDeposits[user].push(depositRecord);
    }

    /*//////////////////////////////////////////////////////////////
                             UPDATE GHOSTS
    //////////////////////////////////////////////////////////////*/
    function _updateDepositGhosts(address depositor, uint256 depositAmount) internal {
        uint256 userPrincipal = depositAmount - _calculateFee(depositAmount);
        ghost_state_totalUsdcDeposited_userPrincipal += userPrincipal;
        ghost_state_totalUsdcDepositedPerUser_userPrincipal[depositor] += userPrincipal;
        ghost_state_totalUsdcDeposited += depositAmount;

        /// @dev record the deposit with current fee rate
        _recordDeposit(depositor, depositAmount);
    }

    function _updateWithdrawGhosts(address withdrawer, uint256 shareBurnAmount) internal {
        ghost_state_totalSharesBurned += shareBurnAmount;
        ghost_state_totalSharesBurnedPerUser[withdrawer] += shareBurnAmount;
    }

    /*//////////////////////////////////////////////////////////////
                              HANDLE LOGS
    //////////////////////////////////////////////////////////////*/
    function _handleDepositLogs() internal {
        bytes32 depositInitiatedEvent = keccak256("DepositInitiated(address,uint256,uint64)");
        bytes32 shareMintUpdateEvent = keccak256("ShareMintUpdate(uint256,uint64,uint256)");
        bytes32 feeTakenEvent = keccak256("FeeTaken(uint256)");
        bool depositInitiatedEventFound = false;
        bool shareMintUpdateEventFound = false;
        bool feeTakenEventFound = false;
        address depositor;

        Vm.Log[] memory logs = vm.getRecordedLogs();

        // First pass: find the depositor from DepositInitiated event
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == depositInitiatedEvent) {
                depositInitiatedEventFound = true;
                ghost_event_depositInitiated_emissions++;
                depositor = address(uint160(uint256(logs[i].topics[1])));
                break; // Found the depositor, break out of loop
            }
        }

        // Second pass: process all events with the correct depositor
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == shareMintUpdateEvent) {
                shareMintUpdateEventFound = true;
                ghost_event_shareMintUpdate_emissions++;
                uint256 shareMintAmount = uint256(logs[i].topics[1]);
                ghost_event_totalSharesMinted += shareMintAmount;
                ghost_event_totalSharesMintedPerUser[depositor] += shareMintAmount;
                console2.log("shareMintAmount:", shareMintAmount);
            }
            if (logs[i].topics[0] == feeTakenEvent) {
                feeTakenEventFound = true;
                ghost_event_feeTaken_emissions++;
                uint256 feeInStablecoin = uint256(logs[i].topics[1]);
                console2.log("FeeTaken event found for depositor:", depositor);
                console2.log("Fee amount:", feeInStablecoin);
                ghost_event_totalFeesTakenInStablecoinPerUser[depositor] += feeInStablecoin;
                ghost_event_totalFeesTakenInStablecoin += feeInStablecoin;
            }
        }
        assertTrue(depositInitiatedEventFound, "DepositInitiated log not found");
        assertTrue(shareMintUpdateEventFound, "ShareMintUpdate log not found");
        console2.log("ghost_state_feeRate:", ghost_state_feeRate);
        if (ghost_state_feeRate > 0) assertTrue(feeTakenEventFound, "FeeTaken log not found");
    }

    function _handleWithdrawLogs() internal {
        bytes32 withdrawCompletedEvent = keccak256("WithdrawCompleted(address,uint256)");
        bytes32 shareBurnUpdateEvent = keccak256("ShareBurnUpdate(uint256,uint64,uint256)");
        bool withdrawCompletedEventFound = false;
        bool shareBurnUpdateEventFound = false;

        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == withdrawCompletedEvent) {
                withdrawCompletedEventFound = true;
                ghost_event_withdrawCompleted_emissions++;
                address user = address(uint160(uint256(logs[i].topics[1])));
                uint256 amount = uint256(logs[i].topics[2]);
                ghost_event_totalUsdcWithdrawn += amount;
                ghost_event_totalUsdcWithdrawnPerUser[user] += amount;
                console2.log("usdc withdraw amount:", amount);
                console2.log("total withdrawn:", ghost_event_totalUsdcWithdrawn);
            }
            if (logs[i].topics[0] == shareBurnUpdateEvent) {
                shareBurnUpdateEventFound = true;
                uint256 shareBurnAmount = uint256(logs[i].topics[1]);
                ghost_event_shareBurnUpdate_emissions++;
                ghost_event_totalSharesBurned += shareBurnAmount;
            }
        }
        assertTrue(withdrawCompletedEventFound, "WithdrawCompleted log not found");
    }

    function _handleOnReportLogs() internal {
        /// @dev Events to look for
        bytes32 reportDecodedEvent = keccak256("ReportDecoded(uint64,bytes32)");
        bytes32 currentStrategyOptimalEvent = keccak256("CurrentStrategyOptimal(uint64,bytes32)");
        bytes32 strategyUpdatedEvent = keccak256("StrategyUpdated(uint64,bytes32,uint64)");

        /// @dev Flags to track if the appropriate strategy event was emitted
        bool reportDecodedEventFound = false;
        bool currentStrategyOptimalEventFound = false;
        bool strategyUpdatedEventFound = false;

        /// @dev Flag to track which strategy event to check
        bool isCurrentStrategyOptimal = false;
        bool isStrategyUpdated = false;

        /// @dev previous strategy before onReport changed it
        uint64 previousStrategyChain = ghost_state_previousStrategy.chainSelector;
        bytes32 previousStrategyProtocol = ghost_state_previousStrategy.protocolId;

        /// @dev decoded strategy from ReportDecoded event
        uint64 decodedChainSelector;
        bytes32 decodedProtocolId;

        /// @dev Pass to find ReportDecoded event and extract strategy
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == reportDecodedEvent) {
                /// @dev set ghost flag indicating CRE report was decoded
                ghost_flag_creReport_decoded = true;
                /// @dev update event flag and decode strategy
                reportDecodedEventFound = true;
                decodedChainSelector = uint64(uint256(logs[i].topics[1]));
                decodedProtocolId = logs[i].topics[2];

                /// @dev store the decoded strategy in ghost state
                ghost_event_lastCREReceivedStrategy =
                    IYieldPeer.Strategy({chainSelector: decodedChainSelector, protocolId: decodedProtocolId});
                /// @dev log decoded strategy for debugging
                console2.log("Decoded Report - chainSelector:", decodedChainSelector);
                console2.log("Decoded Report - protocolId:");
                console2.logBytes32(decodedProtocolId);

                /// @dev set flag for appropriate emitted strategy event check
                if (previousStrategyChain == decodedChainSelector && previousStrategyProtocol == decodedProtocolId) {
                    isCurrentStrategyOptimal = true;
                } else {
                    isStrategyUpdated = true;
                }
            }
        }

        /// @dev If the current strategy is optimal, ensure CurrentStrategyOptimal
        /// @dev event matches decoded strategy
        if (isCurrentStrategyOptimal) {
            for (uint256 i = 0; i < logs.length; i++) {
                if (logs[i].topics[0] == currentStrategyOptimalEvent) {
                    currentStrategyOptimalEventFound = true;
                    uint64 emittedChainSelector = uint64(uint256(logs[i].topics[1]));
                    bytes32 emittedProtocolId = logs[i].topics[2];

                    if (emittedChainSelector != decodedChainSelector || emittedProtocolId != decodedProtocolId) {
                        ghost_flag_decodedStrategy_mismatchWithEmittedStrategy = true;
                        console2.log("CRE report strategy mismatch with emitted strategy detected");
                    }
                }
            }
        }

        /// @dev If the strategy was updated, ensure StrategyUpdated event
        /// @dev matches decoded strategy
        if (isStrategyUpdated) {
            for (uint256 i = 0; i < logs.length; i++) {
                if (logs[i].topics[0] == strategyUpdatedEvent) {
                    strategyUpdatedEventFound = true;
                    uint64 emittedChainSelector = uint64(uint256(logs[i].topics[1]));
                    bytes32 emittedProtocolId = logs[i].topics[2];
                    uint64 emittedOldStrategyChain = uint64(uint256(logs[i].topics[3]));

                    if (emittedChainSelector != decodedChainSelector || emittedProtocolId != decodedProtocolId) {
                        ghost_flag_decodedStrategy_mismatchWithEmittedStrategy = true;
                        console2.log("CRE report strategy mismatch with emitted strategy detected");
                    }

                    /// @dev consistency/sanity check that emitted old strategy chain matches the previous strategy chain
                    assertTrue(emittedOldStrategyChain == previousStrategyChain, "Old strategy chain mismatch");
                }
            }
        }

        assertTrue(reportDecodedEventFound, "ReportDecoded log not found");
        assertTrue(
            currentStrategyOptimalEventFound || strategyUpdatedEventFound,
            "No strategy event matching decoded strategy found"
        );
    }

    /*//////////////////////////////////////////////////////////////
                                UTILITY
    //////////////////////////////////////////////////////////////*/
    /// @dev convert a seed to an address
    function _seedToAddress(uint256 addressSeed) internal returns (address seedAddress) {
        uint160 boundInt = uint160(bound(addressSeed, 1, type(uint160).max));
        seedAddress = address(boundInt);
        if (seedAddress == admin) seedAddress = _seedToAddress(addressSeed + 1);
        if (seedAddress == address(share)) seedAddress = _seedToAddress(addressSeed + 2);
        if (seedAddress == address(parent)) seedAddress = _seedToAddress(addressSeed + 3);
        if (seedAddress == address(child1)) seedAddress = _seedToAddress(addressSeed + 4);
        if (seedAddress == address(child2)) seedAddress = _seedToAddress(addressSeed + 5);
        if (seedAddress == parent.owner()) seedAddress = _seedToAddress(addressSeed + 6); // excluding the owner introduces the assumption that the owner will not be interacting with the protocol as a user
        users.add(seedAddress);
    }

    /// @dev create a user address for calling and passing to requestKycStatus or onTokenTransfer
    function _createOrGetUser(uint256 addressSeed) internal returns (address user) {
        if (users.length() == 0) {
            user = _seedToAddress(addressSeed);
            users.add(user);
        } else {
            user = _indexToUser(addressSeed);
        }
    }

    /// @dev convert an index to an existing user
    function _indexToUser(uint256 addressIndex) internal view returns (address) {
        return users.at(bound(addressIndex, 0, users.length() - 1));
    }

    /// @dev helper function for looping through chainSelectors in the system
    function forEachChainSelector(function(uint64) external func) external {
        for (uint256 i; i < chainSelectors.length(); ++i) {
            func(uint64(chainSelectors.at(i)));
        }
    }

    /// @dev helper function for looping through users in the system
    function forEachUser(function(address) external func) external {
        for (uint256 i; i < users.length(); ++i) {
            func(users.at(i));
        }
    }

    /// @notice this is needed to mitigate share inflation attacks
    function _adminDeposit() internal {
        vm.recordLogs();
        _changePrank(admin);
        deal(address(usdc), admin, INITIAL_DEPOSIT_AMOUNT);
        usdc.approve(address(parent), INITIAL_DEPOSIT_AMOUNT);
        parent.deposit(INITIAL_DEPOSIT_AMOUNT);
        _updateDepositGhosts(admin, INITIAL_DEPOSIT_AMOUNT);
        _handleDepositLogs();
    }

    /// @notice deal USDC to the pools to ensure they have enough liquidity and we dont get insufficient balance errors
    function _dealPoolsUsdc() internal {
        deal(address(usdc), aavePool, POOL_DEAL_AMOUNT);
        deal(address(usdc), compoundPool, POOL_DEAL_AMOUNT);
    }

    function _changePrank(address newPrank) internal {
        vm.stopPrank();
        vm.startPrank(newPrank);
    }

    function _stopPrank() internal {
        vm.stopPrank();
    }

    /// @dev getter for the number of users
    function getUsersLength() external view returns (uint256) {
        return EnumerableSet.length(users);
    }

    /// @dev getter for a user at a specific index
    function getUserAt(uint256 index) external view returns (address) {
        return EnumerableSet.at(users, index);
    }

    /// @dev getter for the admin's share balance
    function getAdminShareBalance() external view returns (uint256) {
        return share.balanceOf(admin);
    }

    /// @dev calculate expected fees taken for a user based on their historical deposits
    function calculateExpectedFeesForUser(address user) external view returns (uint256 totalExpectedFees) {
        DepositRecord[] memory deposits = ghost_userDeposits[user];
        for (uint256 i = 0; i < deposits.length; i++) {
            totalExpectedFees += _calculateFeeWithRate(deposits[i].amount, deposits[i].feeRate);
        }
    }

    /// @dev calculate expected fees for a user by summing up the fees from deposit records
    function calculateExpectedFeesFromDepositRecords(address user) external view returns (uint256 totalExpectedFees) {
        DepositRecord[] memory deposits = ghost_userDeposits[user];
        for (uint256 i = 0; i < deposits.length; i++) {
            totalExpectedFees += deposits[i].fee;
        }
    }

    /// @dev calculate total expected fees across all users by summing deposit record fees
    function calculateTotalExpectedFeesFromDepositRecords() external view returns (uint256 totalExpectedFees) {
        for (uint256 i = 0; i < users.length(); i++) {
            address user = users.at(i);
            totalExpectedFees += this.calculateExpectedFeesFromDepositRecords(user);
        }
    }

    /// @dev calculate fee for a specific deposit amount with a specific fee rate
    function _calculateFeeWithRate(uint256 depositAmount, uint256 feeRate) internal view returns (uint256) {
        return (depositAmount * feeRate) / parent.getFeeRateDivisor();
    }

    /// @dev get the number of deposits for a user
    function getUserDepositCount(address user) external view returns (uint256) {
        return ghost_userDeposits[user].length;
    }

    /// @dev get a specific deposit record for a user
    function getUserDeposit(address user, uint256 index) external view returns (DepositRecord memory) {
        return ghost_userDeposits[user][index];
    }

    /// @dev get the previous strategy before onReport changed it
    function getPreviousStrategy() external view returns (IYieldPeer.Strategy memory) {
        return ghost_state_previousStrategy;
    }

    /// @dev get the last decoded strategy from CRE report
    function getLastCREReceivedStrategy() external view returns (IYieldPeer.Strategy memory) {
        return ghost_event_lastCREReceivedStrategy;
    }

    /// @dev empty test to ignore in coverage report
    function test_emptyTest() public {}
}
