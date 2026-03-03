// SPDX-License-Identifier: UNLICENSED
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
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";
import {Events} from "./modules/Events.t.sol";
import {ManualMockRouter} from "../mocks/ManualMockRouter.sol";

/// @notice This contract is used to handle fuzzed interactions with the external functions of the system to test invariants.
/// @notice Events inherits Ghosts, and forge-std/Test.sol
contract Handler is Events {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using stdStorage for StdStorage;

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
    ManualMockRouter internal ccipRouter;
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
        ccipRouter = ManualMockRouter(_ccipRouter);
        usdc = IERC20(_usdc);
        aavePool = _aavePool;
        compoundPool = _compoundPool;
        rebalancer = _rebalancer;
        systemRoles = _systemRoles;

        vm.prank(rebalancer.owner());
        rebalancer.setKeystoneForwarder(forwarder);
        vm.stopPrank();

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

        /// @dev update ghost state — event ghosts first, then state ghosts (state helpers read event ghosts)
        _handleLogs();
        _updateDepositStateGhosts(depositor, depositAmount);
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

        /// @dev update ghost state — event ghosts first, then state ghosts (state helpers read event ghosts)
        _handleLogs();
        _updateWithdrawStateGhosts(withdrawer, shareBurnAmount);
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

        /// @dev capture previous strategy before onReport changes it
        ghost_previousStrategy = parent.getStrategy();

        vm.recordLogs();
        _changePrank(forwarder);
        rebalancer.onReport(workflowMetadata, report);
        _handleLogs();
        _updateRebalanceStateGhosts();
    }

    /// @notice This function handles withdrawing fees
    function withdrawFees(address nonFeeWithdrawerAddr) public {
        uint256 parentFees = usdc.balanceOf(address(parent));
        uint256 child1Fees = usdc.balanceOf(address(child1));
        uint256 child2Fees = usdc.balanceOf(address(child2));
        uint256 availableFees = parentFees + child1Fees + child2Fees;
        if (availableFees == 0) return; // @review wasted run

        /// @dev update the ghost state
        _updateFeesStateGhosts(availableFees);

        /// @dev try call from non-fee withdrawer to assert it never succeeds
        vm.assume(nonFeeWithdrawerAddr != systemRoles.feeWithdrawer);
        _changePrank(nonFeeWithdrawerAddr);
        try parent.withdrawFees(address(usdc)) {
            ghost_flag_nonFeeWithdrawer_withdrewFees = true;
        } catch {
            console2.log("nonFeeWithdrawerRoleAddr withdrawFees failed");
        }

        vm.recordLogs();

        /// @dev withdraw the fees
        _changePrank(systemRoles.feeWithdrawer);
        if (parentFees > 0) parent.withdrawFees(address(usdc));
        if (child1Fees > 0) child1.withdrawFees(address(usdc));
        if (child2Fees > 0) child2.withdrawFees(address(usdc));

        _handleLogs();
    }

    /// @notice This function handles setting the fee rate
    /// @param feeRate the fee rate to set
    function setFeeRate(uint256 feeRate) public {
        /// @dev bind the fee rate to the range of valid values
        feeRate = bound(feeRate, 0, parent.getMaxFeeRate());
        /// @dev update the ghost state
        ghost_feeRate = feeRate;
        /// @dev update the fee rate
        _changePrank(systemRoles.feeRateSetter);
        parent.setFeeRate(feeRate);
        child1.setFeeRate(feeRate);
        child2.setFeeRate(feeRate);
    }

    /// @notice This function handles deposit ping-pong scenarios
    /// @notice Zeroes the strategy adapter, initiates a deposit from a child, manually steps
    ///         through the first two CCIP hops, restores the adapter, then drains the queue.
    /// @param addressSeed the seed used to create the depositor
    /// @param depositAmount the amount of USDC to deposit
    /// @param childSeed the seed used to select which child to deposit from
    function depositPingPong(uint256 addressSeed, uint256 depositAmount, uint256 childSeed) public {
        address depositor = _seedToAddress(addressSeed);
        depositAmount = bound(depositAmount, MIN_DEPOSIT_AMOUNT, MAX_DEPOSIT_AMOUNT);
        deal(address(usdc), depositor, depositAmount);

        address depositingPeer = childSeed % 2 == 0 ? address(child1) : address(child2);

        IYieldPeer.Strategy memory strategy = parent.getStrategy();
        address strategyPeer = chainSelectorsToPeers[strategy.chainSelector];
        address oldAdapter = IYieldPeer(strategyPeer).getActiveStrategyAdapter();
        if (oldAdapter == address(0)) return; // @review wasted run

        stdstore.target(strategyPeer).sig("getActiveStrategyAdapter()").checked_write(address(0));

        ccipRouter.setManualMode(true);
        vm.recordLogs();
        _deposit(depositor, depositAmount, depositingPeer);

        ccipRouter.routeNext();
        ccipRouter.routeNext();
        stdstore.target(strategyPeer).sig("getActiveStrategyAdapter()").checked_write(oldAdapter);
        while (ccipRouter.queueLength() > 0) ccipRouter.routeNext();

        ccipRouter.setManualMode(false);

        uint256 prevMinted = ghost_yieldPeer_event_SharesMinted_emissions;
        _handleLogs();
        _updateDepositStateGhosts(depositor, depositAmount);
        ghost_depositPingPong_calls++;
        if (ghost_yieldPeer_event_SharesMinted_emissions > prevMinted) ghost_depositPingPong_completions++;
    }

    /// @notice This function handles withdraw ping-pong scenarios
    /// @notice If the withdrawer has no shares, deposits first as a sub-action.
    /// @notice Zeroes the strategy adapter, initiates a withdraw from a child, manually steps
    ///         through the first two CCIP hops, restores the adapter, then drains the queue.
    /// @param addressSeed the seed used to create or get the withdrawer
    /// @param shareBurnAmount the amount of shares to burn
    /// @param childSeed the seed used to select which child to withdraw from
    /// @param usdcDepositAmount the amount of USDC to deposit if the withdrawer has no shares
    function withdrawPingPong(
        uint256 addressSeed,
        uint256 shareBurnAmount,
        uint256 childSeed,
        uint256 usdcDepositAmount
    ) public {
        _dealPoolsUsdc();

        address withdrawer = _createOrGetUser(addressSeed);
        if (share.balanceOf(withdrawer) == 0) {
            withdrawer = deposit(true, addressSeed, usdcDepositAmount, childSeed);
        }
        uint256 withdrawerShareBalance = share.balanceOf(withdrawer);
        shareBurnAmount = bound(shareBurnAmount, 1, withdrawerShareBalance);

        address withdrawingPeer = childSeed % 2 == 0 ? address(child1) : address(child2);

        IYieldPeer.Strategy memory strategy = parent.getStrategy();
        address strategyPeer = chainSelectorsToPeers[strategy.chainSelector];
        address oldAdapter = IYieldPeer(strategyPeer).getActiveStrategyAdapter();
        if (oldAdapter == address(0)) return; // @review wasted run

        stdstore.target(strategyPeer).sig("getActiveStrategyAdapter()").checked_write(address(0));

        ccipRouter.setManualMode(true);
        vm.recordLogs();
        _changePrank(withdrawer);
        share.transferAndCall(withdrawingPeer, shareBurnAmount, "");
        _stopPrank();

        ccipRouter.routeNext();
        ccipRouter.routeNext();
        stdstore.target(strategyPeer).sig("getActiveStrategyAdapter()").checked_write(oldAdapter);
        while (ccipRouter.queueLength() > 0) ccipRouter.routeNext();

        ccipRouter.setManualMode(false);

        uint256 prevWithdrawCompleted = ghost_yieldPeer_event_WithdrawCompleted_emissions;
        _handleLogs();
        _updateWithdrawStateGhosts(withdrawer, shareBurnAmount);
        ghost_withdrawPingPong_calls++;
        if (ghost_yieldPeer_event_WithdrawCompleted_emissions > prevWithdrawCompleted) {
            ghost_withdrawPingPong_completions++;
        }
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
                         UPDATE STATE GHOSTS
    //////////////////////////////////////////////////////////////*/
    /// @dev updates system aggregate ghosts after a deposit
    /// @dev must be called after _handleLogs() — reads ghost_yieldPeer_event_SharesMinted_param_amount
    function _updateDepositStateGhosts(address depositor, uint256 depositAmount) internal {
        uint256 fee = _calculateFee(depositAmount);
        uint256 userPrincipal = depositAmount - fee;

        ghost_totalUsdcDeposited += depositAmount;
        ghost_totalUsdcDeposited_userPrincipal += userPrincipal;
        ghost_totalUsdcDepositedPerUser_userPrincipal[depositor] += userPrincipal;
        ghost_totalFeesTakenInStablecoinPerUser[depositor] += fee;

        // reads event ghost set during _handleLogs() — intentional documented dependency
        ghost_totalSharesMintedPerUser[depositor] += ghost_yieldPeer_event_SharesMinted_param_amount;

        _recordDeposit(depositor, depositAmount);
    }

    /// @dev updates system aggregate ghosts after a withdrawal
    /// @dev must be called after _handleLogs() — reads ghost_yieldPeer_event_WithdrawCompleted_param_amount
    function _updateWithdrawStateGhosts(address withdrawer, uint256 shareBurnAmount) internal {
        ghost_totalSharesBurned += shareBurnAmount;
        ghost_totalSharesBurnedPerUser[withdrawer] += shareBurnAmount;

        // reads event ghost set during _handleLogs() — intentional documented dependency
        ghost_event_totalUsdcWithdrawnPerUser[withdrawer] += ghost_yieldPeer_event_WithdrawCompleted_param_amount;
    }

    /// @dev updates system aggregate ghosts after fees are withdrawn
    function _updateFeesStateGhosts(uint256 withdrawnFees) internal {
        ghost_totalFeesWithdrawnInStablecoin += withdrawnFees;
    }

    /// @dev updates system aggregate ghosts after a rebalance
    function _updateRebalanceStateGhosts() internal {
        ghost_rebalances++;
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

    /// @dev create a user address
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
        _handleLogs();
        _updateDepositStateGhosts(admin, INITIAL_DEPOSIT_AMOUNT);
        _stopPrank();
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

    /// @dev empty test to ignore in coverage report
    function test_emptyTest() public override {}
}
