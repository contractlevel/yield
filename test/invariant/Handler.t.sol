// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, Vm, console2, ParentCLF, ChildPeer, IERC20, Share, IYieldPeer} from "../BaseTest.t.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

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

    ParentCLF internal parent;
    ChildPeer internal child1;
    ChildPeer internal child2;
    Share internal share;
    address internal ccipRouter;
    IERC20 internal usdc;
    address internal upkeep;
    address internal functionsRouter;
    address internal admin = makeAddr("admin");

    uint64 internal parentChainSelector;
    uint64 internal child1ChainSelector;
    uint64 internal child2ChainSelector;
    mapping(uint64 => address) public chainSelectorsToPeers;
    mapping(address => uint64) public peersToChainSelectors;

    /*//////////////////////////////////////////////////////////////
                            ENUMERABLE SETS
    //////////////////////////////////////////////////////////////*/
    /// @dev track the users in the system
    EnumerableSet.AddressSet internal users;
    /// @dev track the chain selectors in the system
    EnumerableSet.UintSet internal chainSelectors;

    /*//////////////////////////////////////////////////////////////
                                 GHOSTS
    //////////////////////////////////////////////////////////////*/
    uint256 public ghost_state_totalSharesMinted;
    /// @dev track the total shares burned by incrementing by shareBurnAmount everytime share.transferAndCall is used to withdraw USDC
    uint256 public ghost_state_totalSharesBurned;

    /// @dev track the total shares minted amount according to ShareMintUpdate events emitted by ParentPeet
    uint256 public ghost_event_totalSharesMinted;
    uint256 public ghost_event_totalSharesBurned;

    /// @dev track total USDC deposited across the system
    uint256 public ghost_state_totalUsdcDeposited;
    uint256 public ghost_state_totalUsdcWithdrawn;

    /// @dev track total USDC deposited per user
    mapping(address user => uint256 usdcDepositAmount) public ghost_state_totalUsdcDepositedPerUser;
    /// @dev track total USDC withdrawn per user
    mapping(address user => uint256 usdcWithdrawAmount) public ghost_state_totalUsdcWithdrawnPerUser;

    /// @dev track total shares burnt per user
    mapping(address user => uint256 shareBurnAmount) public ghost_state_totalSharesBurnedPerUser;

    /// @dev track total USDC deposited per chain
    // @review not sure we'll need these
    mapping(uint64 chainSelector => uint256 amount) public ghost_state_totalUsdcDepositedPerChain;
    mapping(uint64 chainSelector => uint256 amount) public ghost_state_totalUsdcWithdrawnPerChain;

    uint64 public ghost_state_currentStrategyChainSelector;
    uint8 public ghost_state_currentStrategyProtocolEnum;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        ParentCLF _parent,
        ChildPeer _child1,
        ChildPeer _child2,
        Share _share,
        address _ccipRouter,
        address _usdc,
        address _upkeep,
        address _functionsRouter
    ) {
        parent = _parent;
        child1 = _child1;
        child2 = _child2;
        share = _share;
        ccipRouter = _ccipRouter;
        usdc = IERC20(_usdc);
        upkeep = _upkeep;
        functionsRouter = _functionsRouter;

        // @review could delete this
        parentChainSelector = parent.getThisChainSelector();
        child1ChainSelector = child1.getThisChainSelector();
        child2ChainSelector = child2.getThisChainSelector();

        chainSelectorsToPeers[parentChainSelector] = address(parent);
        chainSelectorsToPeers[child1ChainSelector] = address(child1);
        chainSelectorsToPeers[child2ChainSelector] = address(child2);

        // @review could delete this
        peersToChainSelectors[address(parent)] = parentChainSelector;
        peersToChainSelectors[address(child1)] = child1ChainSelector;
        peersToChainSelectors[address(child2)] = child2ChainSelector;

        chainSelectors.add(parentChainSelector);
        chainSelectors.add(child1ChainSelector);
        chainSelectors.add(child2ChainSelector);

        /// @dev set the initial strategy to the parent chain
        /// @notice this is set in parent constructor
        ghost_state_currentStrategyChainSelector = parentChainSelector;
        ghost_state_currentStrategyProtocolEnum = 0;

        _adminDeposit();
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

        /// @dev update the ghost state
        _updateDepositGhosts(depositor, depositAmount, chainSelector);
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

        /// @dev withdraw the shares from the peer
        address peer = chainSelectorsToPeers[initiateChainSelector];
        bytes memory encodedWithdrawChainSelector = abi.encode(withdrawChainSelector);
        _changePrank(withdrawer);
        share.transferAndCall(peer, shareBurnAmount, encodedWithdrawChainSelector);

        /// @dev update the ghost state
        _updateWithdrawGhosts(withdrawer, shareBurnAmount, withdrawChainSelector);
    }

    /// @notice This function handles the fulfillment of requests to the CLF don - the purpose of which is to update the strategy
    function fulfillRequest(uint256 chainSelectorSeed, uint256 protocolEnumSeed) public {
        /// @dev bind the chain selector and protocol enum to the range of valid values
        uint64 chainSelector = uint64(bound(chainSelectorSeed, 1, 3));
        uint8 protocolEnum = uint8(bound(protocolEnumSeed, 0, 1));

        /// @dev simulate the passing of time
        /// @notice we are simulating time based automation triggering once per day
        vm.warp(block.timestamp + 1 days);

        /// @dev simulate sending request to CLF don and get the request id
        vm.recordLogs();
        _changePrank(upkeep);
        parent.sendCLFRequest();
        bytes memory response = abi.encode(chainSelector, protocolEnum);
        bytes32 requestId;
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256("RequestSent(bytes32)")) {
                requestId = bytes32(logs[i].data);
            }
        }

        /// @dev simulate fulfilling request from CLF don to update the strategy
        _changePrank(functionsRouter);
        parent.handleOracleFulfillment(requestId, response, "");
        _stopPrank();

        /// @dev update the ghost state
        _updateStrategyGhosts(chainSelector, protocolEnum);
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

    /*//////////////////////////////////////////////////////////////
                             UPDATE GHOSTS
    //////////////////////////////////////////////////////////////*/
    function _updateDepositGhosts(address depositor, uint256 depositAmount, uint64 chainSelector) internal {
        // uint256 userShareBalance = share.balanceOf(depositor);
        ghost_state_totalUsdcDeposited += depositAmount;
        ghost_state_totalUsdcDepositedPerUser[depositor] += depositAmount;
        // ghost_state_totalUsdcDepositedPerChain[chainSelector] += depositAmount;
    }

    function _updateWithdrawGhosts(address withdrawer, uint256 shareBurnAmount, uint64 chainSelector) internal {
        ghost_state_totalSharesBurned += shareBurnAmount;
        ghost_state_totalSharesBurnedPerUser[withdrawer] += shareBurnAmount;
        // ghost_state_totalUsdcWithdrawn += withdrawAmount;
        // ghost_state_totalUsdcWithdrawnPerUser[withdrawer] += withdrawAmount;
        // ghost_state_totalUsdcWithdrawnPerChain[chainSelector] += withdrawAmount;
    }

    /// @notice we track the current strategy chain selector and protocol enum with ghosts
    function _updateStrategyGhosts(uint64 chainSelector, uint8 protocolEnum) internal {
        ghost_state_currentStrategyChainSelector = chainSelector;
        ghost_state_currentStrategyProtocolEnum = protocolEnum;
    }

    /*//////////////////////////////////////////////////////////////
                              HANDLE LOGS
    //////////////////////////////////////////////////////////////*/
    function _handleDepositLogs() internal {
        bytes32 depositInitiatedEvent = keccak256("DepositInitiated(address,uint256,uint64)");
        bytes32 shareMintUpdateEvent = keccak256("ShareMintUpdate(uint256,uint64,uint256)");
        bool depositInitiatedEventFound = false;
        bool shareMintUpdateEventFound = false;

        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == depositInitiatedEvent) depositInitiatedEventFound = true;
            if (logs[i].topics[0] == shareMintUpdateEvent) {
                shareMintUpdateEventFound = true;
                uint256 shareMintAmount = uint256(logs[i].topics[1]);
                ghost_event_totalSharesMinted += shareMintAmount;
            }
        }
        assertTrue(depositInitiatedEventFound, "DepositInitiated log not found");
        assertTrue(shareMintUpdateEventFound, "ShareMintUpdate log not found");
    }

    /*//////////////////////////////////////////////////////////////
                                UTILITY
    //////////////////////////////////////////////////////////////*/
    /// @dev convert a seed to an address
    function _seedToAddress(uint256 addressSeed) internal view returns (address seedAddress) {
        uint160 boundInt = uint160(bound(addressSeed, 1, type(uint160).max));
        seedAddress = address(boundInt);
        if (seedAddress == admin) seedAddress = _seedToAddress(addressSeed + 1);
        if (seedAddress == address(share)) seedAddress = _seedToAddress(addressSeed + 2);
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

    /// @notice this is needed to mitigate share inflation attacks
    function _adminDeposit() internal {
        vm.recordLogs();
        _changePrank(admin);
        deal(address(usdc), admin, INITIAL_DEPOSIT_AMOUNT);
        usdc.approve(address(parent), INITIAL_DEPOSIT_AMOUNT);
        parent.deposit(INITIAL_DEPOSIT_AMOUNT);
        _updateDepositGhosts(admin, INITIAL_DEPOSIT_AMOUNT, parentChainSelector);
        _handleDepositLogs();
    }

    function _changePrank(address newPrank) internal {
        vm.stopPrank();
        vm.startPrank(newPrank);
    }

    function _stopPrank() internal {
        vm.stopPrank();
    }
}
