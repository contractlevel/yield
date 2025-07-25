// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, Vm, console2, ParentPeer, ChildPeer, IERC20, Share, IYieldPeer, Rebalancer} from "../BaseTest.t.sol";
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
    address internal upkeep;
    address internal functionsRouter;
    address internal admin = makeAddr("admin");
    address internal aavePool;
    address internal compoundPool;
    Rebalancer internal rebalancer;
    address internal forwarder = makeAddr("forwarder");

    uint64 internal parentChainSelector;
    uint64 internal child1ChainSelector;
    uint64 internal child2ChainSelector;
    mapping(uint64 => address) public chainSelectorsToPeers;
    mapping(address => uint64) public peersToChainSelectors;

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
    // 1
    uint256 public ghost_state_totalSharesMinted;
    /// @dev track the total shares burned by incrementing by shareBurnAmount everytime share.transferAndCall is used to withdraw USDC
    uint256 public ghost_state_totalSharesBurned;

    /// @dev track the total shares minted amount according to ShareMintUpdate events emitted by ParentPeet
    uint256 public ghost_event_totalSharesMinted;
    /// @dev track the total shares burned amount according to ShareBurnUpdate events emitted by ParentPeer
    uint256 public ghost_event_totalSharesBurned;

    /// @dev track total USDC deposited across the system
    uint256 public ghost_state_totalUsdcDeposited;
    // 1
    uint256 public ghost_state_totalUsdcWithdrawn;

    // 1
    uint256 public ghost_event_totalUsdcDeposited;
    /// @dev track the total USDC withdrawn amount according to WithdrawCompleted events emitted by Peers
    uint256 public ghost_event_totalUsdcWithdrawn;

    /// @dev track total USDC deposited per user
    mapping(address user => uint256 usdcDepositAmount) public ghost_state_totalUsdcDepositedPerUser;
    /// @dev track total USDC withdrawn per user
    // 1
    mapping(address user => uint256 usdcWithdrawAmount) public ghost_state_totalUsdcWithdrawnPerUser;

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

    /// @dev tracks the number of deposits per user
    mapping(address user => uint256 numOfDeposits) public ghost_numOfDepositsPerUser;

    /// @dev tracks the total shares minted per user - based on ShareMintUpdate events
    mapping(address user => uint256 totalSharesMinted) public ghost_event_totalSharesMintedPerUser;
    /// @dev track total shares burnt per user - based on value passed to share.transferAndCall
    mapping(address user => uint256 shareBurnAmount) public ghost_state_totalSharesBurnedPerUser;

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
        address _upkeep,
        address _functionsRouter,
        address _aavePool,
        address _compoundPool,
        Rebalancer _rebalancer
    ) {
        parent = _parent;
        child1 = _child1;
        child2 = _child2;
        share = _share;
        ccipRouter = _ccipRouter;
        usdc = IERC20(_usdc);
        upkeep = _upkeep;
        functionsRouter = _functionsRouter;
        aavePool = _aavePool;
        compoundPool = _compoundPool;
        rebalancer = _rebalancer;
        vm.prank(rebalancer.owner());
        rebalancer.setForwarder(forwarder);

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
    /// @param initiateChainSelectorSeed the chain selector of the chain the withdrawal is initiated on
    /// @param withdrawChainSelectorSeed the chain selector of the chain the withdrawal is received on
    /// @param usdcDepositAmount the amount of USDC to deposit if the withdrawer has no shares
    function withdraw(
        uint256 addressSeed,
        uint256 shareBurnAmount,
        uint256 initiateChainSelectorSeed,
        uint256 withdrawChainSelectorSeed,
        uint256 usdcDepositAmount
    ) public {
        /// @dev ensure the pools have enough liquidity
        _dealPoolsUsdc();

        /// @dev create or get the withdrawer
        address withdrawer = _createOrGetUser(addressSeed);
        uint256 withdrawerShareBalance = share.balanceOf(withdrawer);

        /// @dev if the withdrawer has no shares, deposit some USDC to get shares
        if (withdrawerShareBalance == 0) {
            withdrawer = deposit(true, addressSeed, usdcDepositAmount, initiateChainSelectorSeed);
            withdrawerShareBalance = share.balanceOf(withdrawer);
        }

        /// @dev bind the fuzzed withdraw amount to the range of valid values
        shareBurnAmount = bound(shareBurnAmount, 1, withdrawerShareBalance);
        /// @dev bind the fuzzed chain selectors to the range of valid values
        uint64 initiateChainSelector = uint64(bound(initiateChainSelectorSeed, 1, 3));
        uint64 withdrawChainSelector = uint64(bound(withdrawChainSelectorSeed, 1, 3));

        vm.recordLogs();

        /// @dev withdraw the shares from the peer
        address peer = chainSelectorsToPeers[initiateChainSelector];
        bytes memory encodedWithdrawChainSelector = abi.encode(withdrawChainSelector);
        _changePrank(withdrawer);
        share.transferAndCall(peer, shareBurnAmount, encodedWithdrawChainSelector);
        console2.log("withdrawer:", withdrawer);
        console2.log("shareBurnAmount:", shareBurnAmount);

        /// @dev update the ghost state
        _updateWithdrawGhosts(withdrawer, shareBurnAmount);
        _handleWithdrawLogs();
    }

    /// @notice This function handles the fulfillment of requests to the CLF don - the purpose of which is to update the strategy
    function fulfillRequest(uint256 chainSelectorSeed, uint256 protocolIdSeed) public {
        /// @dev ensure the pools have enough liquidity
        // uint256 totalValue =
        _dealPoolsUsdc();

        /// @dev bind the chain selector and protocol enum to the range of valid values
        uint64 chainSelector = uint64(bound(chainSelectorSeed, 1, 3));
        bytes32 protocolId;
        if (protocolIdSeed % 2 == 0) protocolId = keccak256(abi.encodePacked("aave-v3"));
        else protocolId = keccak256(abi.encodePacked("compound-v3"));

        /// @dev simulate the passing of time
        /// @notice we are simulating time based automation triggering once per day
        vm.warp(block.timestamp + 1 days);

        /// @dev simulate sending request to CLF don and get the request id
        vm.recordLogs();
        _changePrank(upkeep);
        rebalancer.sendCLFRequest();
        bytes memory response = abi.encode(chainSelector, protocolId);
        bytes32 requestId;
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256("RequestSent(bytes32)")) {
                requestId = bytes32(logs[i].data);
            }
        }

        /// @dev simulate fulfilling request from CLF don to update the strategy
        vm.recordLogs();
        _changePrank(functionsRouter);
        rebalancer.handleOracleFulfillment(requestId, response, "");
        /// @dev if the logs contain a StrategyUpdated event with relevant data, perform upkeep
        _handleCLFLogs();
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

    function _performUpkeep(uint64 newChainSelector, bytes32 protocolId, uint64 oldChainSelector) internal {
        if (newChainSelector == parentChainSelector && oldChainSelector == parentChainSelector) return;

        IYieldPeer.Strategy memory newStrategy =
            IYieldPeer.Strategy({chainSelector: newChainSelector, protocolId: protocolId});
        IYieldPeer.CcipTxType txType;
        if (oldChainSelector == parentChainSelector && newChainSelector != parentChainSelector) {
            txType = IYieldPeer.CcipTxType.RebalanceNewStrategy;
        } else {
            txType = IYieldPeer.CcipTxType.RebalanceOldStrategy;
        }

        address oldStrategyAdapter = parent.getActiveStrategyAdapter();
        uint256 totalValue;
        if (oldStrategyAdapter != address(0)) totalValue = parent.getTotalValue();

        bytes memory performData = abi.encode(
            forwarder, address(parent), newStrategy, txType, oldChainSelector, oldStrategyAdapter, totalValue
        );
        _changePrank(forwarder);
        rebalancer.performUpkeep(performData);
    }

    /*//////////////////////////////////////////////////////////////
                             UPDATE GHOSTS
    //////////////////////////////////////////////////////////////*/
    function _updateDepositGhosts(address depositor, uint256 depositAmount) internal {
        ghost_state_totalUsdcDeposited += depositAmount;
        ghost_state_totalUsdcDepositedPerUser[depositor] += depositAmount;
        console2.log("total deposited:", ghost_state_totalUsdcDeposited);
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
        bool depositInitiatedEventFound = false;
        bool shareMintUpdateEventFound = false;
        address depositor;

        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == depositInitiatedEvent) {
                depositInitiatedEventFound = true;
                ghost_event_depositInitiated_emissions++;
                depositor = address(uint160(uint256(logs[i].topics[1])));
            }
            if (logs[i].topics[0] == shareMintUpdateEvent) {
                shareMintUpdateEventFound = true;
                ghost_event_shareMintUpdate_emissions++;
                uint256 shareMintAmount = uint256(logs[i].topics[1]);
                ghost_event_totalSharesMinted += shareMintAmount;
                ghost_event_totalSharesMintedPerUser[depositor] += shareMintAmount;
                console2.log("shareMintAmount:", shareMintAmount);
            }
        }
        assertTrue(depositInitiatedEventFound, "DepositInitiated log not found");
        assertTrue(shareMintUpdateEventFound, "ShareMintUpdate log not found");
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

    /// @notice Handle the logs emitted during Chainlink Functions callback
    /// @dev If the logs contain a StrategyUpdated event with relevant data, perform upkeep
    function _handleCLFLogs() internal {
        bytes32 strategyUpdatedEvent = keccak256("StrategyUpdated(uint64,bytes32,uint64)");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == strategyUpdatedEvent) {
                uint64 newChainSelector = uint64(uint256(logs[i].topics[1]));
                bytes32 protocolId = logs[i].topics[2];
                uint64 oldChainSelector = uint64(uint256(logs[i].topics[3]));

                _performUpkeep(newChainSelector, protocolId, oldChainSelector);
            }
        }
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

    /// @dev empty test to ignore in coverage report
    function test_emptyTest() public {}
}
