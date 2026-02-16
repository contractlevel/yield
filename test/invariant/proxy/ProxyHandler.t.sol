// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {
    ParentPeer,
    ChildPeer,
    Share,
    Rebalancer,
    Roles,
    IERC20,
    StrategyRegistry,
    IYieldPeer,
    WorkflowHelpers
} from "../../BaseTest.t.sol";
import {
    MockUpgradeParentPeer,
    MockUpgradeChildPeer,
    MockUpgradeShare,
    MockUpgradeRebalancer,
    MockUpgradeStrategyRegistry
} from "./mocks/MockUpgrade.sol";
import {CREReceiver} from "../../../src/modules/CREReceiver.sol";

// Generic interface for UUPS upgrades to avoid casting issues
interface IUUPS {
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
}

contract ProxyHandler is Test {
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    // Constants
    uint256 internal constant MAX_DEPOSIT_AMOUNT = 1_000_000_000_000;
    uint256 internal constant MIN_DEPOSIT_AMOUNT = 1_000_000;
    uint256 internal constant INITIAL_DEPOSIT_AMOUNT = 100_000_000;
    uint256 internal constant POOL_DEAL_AMOUNT = 1_000_000_000_000_000_000; // 1T USDC
    uint256 internal constant CCIP_GAS_LIMIT = 1_000_000;

    uint64 internal constant PARENT_CHAIN_SELECTOR = 1;
    uint64 internal constant CHILD1_CHAIN_SELECTOR = 2;
    uint64 internal constant CHILD2_CHAIN_SELECTOR = 3;

    bytes32 internal constant PARENT_PEER_STORAGE_LOCATION =
        0x603686382b15940b5fa7ef449162bde228a5948ce3b6bdf08bd833ec6ae79500;
    // EIP-1967 implementation slot for proxies
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    bytes32 internal constant AAVE_V3_PROTOCOL_ID = keccak256(abi.encodePacked("aave-v3"));
    bytes32 internal constant COMPOUND_V3_PROTOCOL_ID = keccak256(abi.encodePacked("compound-v3"));

    // System contracts
    ParentPeer internal parent;
    ChildPeer internal child1;
    ChildPeer internal child2;
    Share internal share;
    Rebalancer internal rebalancer;
    StrategyRegistry internal registryParent;
    StrategyRegistry internal registryChild1;
    StrategyRegistry internal registryChild2;

    // External Pools & Usdc
    address internal aavePool;
    address internal compoundPool;
    IERC20 internal usdc;

    // Actors

    address public superUser = makeAddr("super_user");
    address internal attacker = makeAddr("attacker");
    address internal forwarder;
    address internal admin;

    // Mock Implementation Tracking
    address public latestParentImpl;
    address public latestChild1Impl;
    address public latestChild2Impl;
    address public latestShareImpl;
    address public latestRebalancerImpl;
    address public latestRegistryParentImpl;
    address public latestRegistryChild1Impl;
    address public latestRegistryChild2Impl;

    // Rebalancer Workflow
    address internal workflowOwner = makeAddr("workflowOwner");
    bytes32 internal workflowId = bytes32("rebalanceWorkflowId");
    string internal workflowNameRaw = "yieldcoin-rebalance-workflow";
    bytes10 internal workflowName = WorkflowHelpers.createWorkflowName(workflowNameRaw);
    bytes internal workflowMetadata = WorkflowHelpers.createWorkflowMetadata(workflowId, workflowName, workflowOwner);

    /*//////////////////////////////////////////////////////////////
                              GHOST STATE
    //////////////////////////////////////////////////////////////*/

    // --- Version Tracking ---
    /// @dev We are starting with version 1 as that is the default with first implementation
    uint64 public ghost_parent_version = 1;
    uint64 public ghost_child1_version = 1;
    uint64 public ghost_child2_version = 1;
    uint64 public ghost_share_version = 1;
    uint64 public ghost_rebalancer_version = 1;
    uint64 public ghost_registryParent_version = 1;
    uint64 public ghost_registryChild1_version = 1;
    uint64 public ghost_registryChild2_version = 1;

    // --- Protocol Level
    bool public ghost_state_paused;
    uint256 public ghost_state_feeRate;
    uint256 public ghost_state_ccipGasLimit;

    // --- Parent State ---
    bool public ghost_parent_initialActiveStrategySet;
    bool public ghost_parent_paused;
    uint256 public ghost_parent_upgradeCount;
    uint256 public ghost_parent_newVal;

    uint256 public ghost_parent_totalShares;
    uint256 public ghost_parent_feeRate;
    address public ghost_parent_rebalancer;
    bool public ghost_parent_allowedChain1;
    bool public ghost_parent_allowedChain2;
    address public ghost_parent_allowedPeer1;
    address public ghost_parent_allowedPeer2;
    address public ghost_parent_strategyRegistry;
    uint256 public ghost_parent_ccipGasLimit;

    // Parent Strategy
    uint64 public ghost_parent_strategy_chainSelector;
    bytes32 public ghost_parent_strategy_protocolId;
    address public ghost_parent_activeStrategyAdapter;

    // --- Child 1 State ---
    uint64 public ghost_child1_parentChainSelector;

    uint256 public ghost_child1_feeRate;
    bool public ghost_child1_paused;
    bool public ghost_child1_upgraded;
    uint256 public ghost_child1_ccipGasLimit;

    bool public ghost_child1_allowedChain1;
    bool public ghost_child1_allowedChain2;
    address public ghost_child1_allowedPeer1;
    address public ghost_child1_allowedPeer2;
    address public ghost_child1_strategyRegistry;

    uint256 public ghost_child1_upgradeCount;
    uint256 public ghost_child1_newVal;
    address public ghost_child1_activeStrategyAdapter;

    // --- Child 2 State ---
    uint256 public ghost_child2_upgradeCount;
    bool public ghost_child2_upgraded;
    bool public ghost_child2_paused;

    uint64 public ghost_child2_parentChainSelector;
    uint256 public ghost_child2_ccipGasLimit;
    uint256 public ghost_child2_feeRate;
    bool public ghost_child2_allowedChain1;
    bool public ghost_child2_allowedChain2;
    address public ghost_child2_allowedPeer1;
    address public ghost_child2_allowedPeer2;
    address public ghost_child2_strategyRegistry;
    address public ghost_child2_activeStrategyAdapter;

    uint256 public ghost_child2_newVal;

    // --- Share State ---
    uint256 public ghost_share_totalSupply;
    string public ghost_share_name;
    string public ghost_share_symbol;
    uint8 public ghost_share_decimals;
    address public ghost_share_ccipAdmin;

    uint256 public ghost_share_balance;
    uint256 public ghost_share_allowance_parent;
    uint256 public ghost_share_allowance_child1;
    uint256 public ghost_share_allowance_child2;

    uint256 public ghost_share_upgradeCount;
    uint256 public ghost_share_newVal;

    // --- Rebalancer State ---
    address public ghost_rebalancer_parentPeer;
    address public ghost_rebalancer_strategyRegistry;

    address public ghost_rebalancer_forwarder;
    address public ghost_rebalancer_workflowOwner;
    bytes10 public ghost_rebalancer_workflowName;

    uint256 public ghost_rebalancer_upgradeCount;
    uint256 public ghost_rebalancer_newVal;

    // --- Registry States ---

    // Parent Registry
    address public ghost_registryParent_aaveV3_adapter;
    address public ghost_registryParent_compoundV3_adapter;
    uint256 public ghost_registryParent_upgradeCount;
    uint256 public ghost_registryParent_newVal;

    // Child1 Registry
    address public ghost_registryChild1_aaveV3_adapter;
    address public ghost_registryChild1_compoundV3_adapter;
    uint256 public ghost_registryChild1_upgradeCount;
    uint256 public ghost_registryChild1_newVal;

    // Child2 Registry
    address public ghost_registryChild2_aaveV3_adapter;
    address public ghost_registryChild2_compoundV3_adapter;
    uint256 public ghost_registryChild2_upgradeCount;
    uint256 public ghost_registryChild2_newVal;

    // Ghost Actions
    bool public ghost_withdrewWhile_paused;
    bool public ghost_depositedWhile_paused;
    bool public ghost_depositedInto_impl;
    bool public ghost_withdrawFrom_impl;
    bool public ghost_unauthorized_upgrade_success;
    bool public ghost_implementation_was_unlocked;

    constructor(
        ParentPeer _parent,
        ChildPeer _child1,
        ChildPeer _child2,
        Share _share,
        Rebalancer _rebalancer,
        StrategyRegistry _registryParent,
        StrategyRegistry _registryChild1,
        StrategyRegistry _registryChild2,
        IERC20 _usdc,
        address _aavePool,
        address _compoundPool
    ) {
        parent = _parent;
        child1 = _child1;
        child2 = _child2;
        share = _share;
        rebalancer = _rebalancer;
        registryParent = _registryParent;
        registryChild1 = _registryChild1;
        registryChild2 = _registryChild2;
        usdc = _usdc;
        aavePool = _aavePool;
        compoundPool = _compoundPool;

        setFeeRate(0);
        _dealPoolsUsdc();
        _initialDeposit();

        admin = parent.owner();

        // Initial Ghosts
        ghost_parent_totalShares = parent.getTotalShares();
        ghost_share_totalSupply = share.totalSupply();
    }

    function _initialDeposit() internal {
        _changePrank(superUser);
        deal(address(usdc), superUser, INITIAL_DEPOSIT_AMOUNT);
        usdc.approve(address(parent), INITIAL_DEPOSIT_AMOUNT);
        parent.deposit(INITIAL_DEPOSIT_AMOUNT);
        _stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                           HANDLER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function deposit(uint256 depositAmount, uint256 chainSelectorSeed) public virtual {
        depositAmount = bound(depositAmount, MIN_DEPOSIT_AMOUNT, MAX_DEPOSIT_AMOUNT);
        deal(address(usdc), superUser, depositAmount);

        uint256 chainChoice = chainSelectorSeed % 3;
        (address targetPeer, address targetImpl) = _getTargetPeerAndImpl(chainChoice);

        // STACKED CHECK 1: Negative - Direct impl deposit (should fail, flag if not)
        _changePrank(superUser);
        try IYieldPeer(targetImpl).deposit(depositAmount) {
            ghost_depositedInto_impl = true; // Invariant will fail if true
        } catch {
            console2.log("Direct impl deposit failed as expected");
        }
        _stopPrank();

        // STACKED CHECK 2: Negative - Deposit while paused (should fail, flag if not)
        if (ghost_state_paused) {
            _changePrank(superUser);
            usdc.approve(targetPeer, depositAmount); // Setup approval for realism
            try IYieldPeer(targetPeer).deposit(depositAmount) {
                ghost_depositedWhile_paused = true; // Invariant will fail if true
            } catch {
                console2.log("Deposit while paused failed as expected");
            }
            _stopPrank();
            return; // CRITICAL: End the run here. Preserve paused state for fuzzer exploration (e.g., upgrades while paused).
        }

        // PRIMARY ACTION: The real state-changing deposit
        _deposit(depositAmount, targetPeer);
    }

    function withdraw(uint256 withdrawAmount, uint256 chainSeed) public virtual {
        uint256 userBalance = share.balanceOf(superUser);
        _dealPoolsUsdc();

        /// @dev If user balance is 0, we will use "withdrawAmount" to deposit
        /// @dev We check balance afterwards, if still 0, we can assume contract paused so it failed
        /// @dev This is a not ideal but still tests if depositing can happen while paused
        if (userBalance == 0) {
            deposit(withdrawAmount, chainSeed);
            userBalance = share.balanceOf(superUser);
            if (userBalance == 0) return;
        }

        uint256 chainChoice = chainSeed % 3;
        (address targetPeer, address targetImpl) = _getTargetPeerAndImpl(chainChoice);

        withdrawAmount = bound(withdrawAmount, 1, userBalance);

        // STACKED CHECK 1: Negative - Direct impl withdraw (should fail)
        _changePrank(superUser);
        try share.transferAndCall(targetImpl, withdrawAmount, "") {
            ghost_withdrawFrom_impl = true;
        } catch {
            console2.log("Direct impl withdraw failed as expected");
        }
        _stopPrank();

        // STACKED CHECK 2: Negative - Withdraw while paused (should fail)
        if (ghost_state_paused) {
            _changePrank(superUser);
            try share.transferAndCall(targetPeer, withdrawAmount, "") {
                ghost_withdrewWhile_paused = true;
            } catch {
                console2.log("Withdraw while paused failed as expected");
            }
            _stopPrank();
            return; // Preserve state for other actions (e.g., upgrades).
        }

        // PRIMARY ACTION: The real withdraw
        _withdraw(userBalance, withdrawAmount, targetPeer);
    }

    function rebalance(uint256 chainSeed, uint256 protocolSeed) public virtual {
        // Ensure pools have liquidity so strategy migration doesn't revert
        _dealPoolsUsdc();

        uint256 chainChoice = chainSeed % 3;
        uint64 targetChain;
        if (chainChoice == 0) targetChain = PARENT_CHAIN_SELECTOR;
        else if (chainChoice == 1) targetChain = CHILD1_CHAIN_SELECTOR;
        else targetChain = CHILD2_CHAIN_SELECTOR;

        bytes32 protocolId;
        if (protocolSeed % 2 == 0) protocolId = keccak256(abi.encodePacked("aave-v3"));
        else protocolId = keccak256(abi.encodePacked("compound-v3"));

        bytes memory report = WorkflowHelpers.createWorkflowReport(targetChain, protocolId);
        bytes memory metadata = WorkflowHelpers.createWorkflowMetadata(workflowId, workflowName, workflowOwner);

        vm.warp(block.timestamp + 1 hours);

        forwarder = rebalancer.getKeystoneForwarder();
        _changePrank(forwarder);

        rebalancer.onReport(metadata, report);
        _snapshotParentState();
        _snapshotChild1State();
        _snapshotChild2State();

        _stopPrank();
    }

    /// @dev Seed function to set a config/pause state (no setworkflow for now)
    function setterInteraction(uint256 interactionSeed, uint256 setterSeed) public {
        uint256 interactionChoice = interactionSeed % 3;
        if (interactionChoice == 0) {
            console2.log("Interaction chosen: setFeeRate");
            setFeeRate(setterSeed);
        } else if (interactionChoice == 1) {
            console2.log("Interaction chosen: setCCIPGasLimit");
            setCCIPGasLimit(setterSeed);
        } else {
            console2.log("Interaction chosen: togglePause");
            togglePause();
        }
    }

    /// @notice Sets a new few rate
    function setFeeRate(uint256 newFeeRate) public virtual {
        address feeRateSetter = parent.getRoleMember(Roles.FEE_RATE_SETTER_ROLE, 0);

        newFeeRate = bound(newFeeRate, 0, parent.getMaxFeeRate());

        _changePrank(feeRateSetter);
        parent.setFeeRate(newFeeRate);
        child1.setFeeRate(newFeeRate);
        child2.setFeeRate(newFeeRate);

        ghost_state_feeRate = newFeeRate;
        ghost_parent_feeRate = newFeeRate;
        ghost_child1_feeRate = newFeeRate;
        ghost_child2_feeRate = newFeeRate;
        _stopPrank();
    }

    function togglePause() public virtual {
        if (!ghost_state_paused) {
            address emergencyPauser = parent.getRoleMember(Roles.EMERGENCY_PAUSER_ROLE, 0);
            _pauseSystemState(emergencyPauser);
        } else {
            address emergencyUnpauser = parent.getRoleMember(Roles.EMERGENCY_UNPAUSER_ROLE, 0);
            _unpauseSystemState(emergencyUnpauser);
        }
    }

    function setCCIPGasLimit(uint256 ccipGasLimit) public virtual {
        /// @dev Need to be careful with this, setting it too low makes it fail
        uint256 minGas = 900_000;

        address crossChainAdmin = parent.getRoleMember(Roles.CROSS_CHAIN_ADMIN_ROLE, 0);
        ccipGasLimit = bound(ccipGasLimit, minGas, CCIP_GAS_LIMIT);

        _changePrank(crossChainAdmin);
        parent.setCCIPGasLimit(ccipGasLimit);
        child1.setCCIPGasLimit(ccipGasLimit);
        child2.setCCIPGasLimit(ccipGasLimit);

        ghost_state_ccipGasLimit = ccipGasLimit;
        ghost_parent_ccipGasLimit = ccipGasLimit;
        ghost_child1_ccipGasLimit = ccipGasLimit;
        ghost_child2_ccipGasLimit = ccipGasLimit;
        _stopPrank();
    }

    // @review I don't know about this one, its kind of tricky to use it
    // function setWorkflow(uint256 seed) public virtual {
    //     seed = bound(seed, 1, type(uint160).max - 1);
    //     address flowOwner = address(uint160(seed));
    //     _changePrank(rebalancer.owner());
    //     rebalancer.setWorkflow(workflowId, flowOwner, workflowName);
    //     ghost_rebalancer_workflow_set = true;
    //     ghost_rebalancer_workflow_owner = flowOwner;

    //     _stopPrank();
    // }

    function triggerRandomUpgrade(uint256 seed, uint256 selectorSeed) public {
        // We have 8 upgradeable contracts
        uint256 target = selectorSeed % 8;

        if (target == 0) upgradeParent(seed);
        else if (target == 1) upgradeChild1(seed);
        else if (target == 2) upgradeChild2(seed);
        else if (target == 3) upgradeShare(seed);
        else if (target == 4) upgradeRebalancer(seed);
        else if (target == 5) upgradeRegistryParent(seed);
        else if (target == 6) upgradeRegistryChild1(seed);
        else upgradeRegistryChild2(seed);
    }

    function upgradeParent(uint256 seed) public virtual {
        _snapshotParentState();
        MockUpgradeParentPeer newImpl = new MockUpgradeParentPeer(
            parent.getRouter(), parent.getLink(), parent.getThisChainSelector(), parent.getUsdc(), parent.getShare()
        );

        _verifyImplementationLocked(address(newImpl));

        uint64 nextVersion = ghost_parent_version + 1;
        uint256 initVal = bound(seed, 1, type(uint256).max);
        bytes memory initData =
            abi.encodeWithSelector(MockUpgradeParentPeer.initializeDynamic.selector, nextVersion, initVal);

        // Stacked Check: Attempt upgrade as attacker
        _changePrank(attacker);
        try IUUPS(address(parent)).upgradeToAndCall(address(newImpl), initData) {
            ghost_unauthorized_upgrade_success = true;
        } catch { /* Expected failure */ }
        _stopPrank();

        // Primary Action: Upgrade as admin
        _changePrank(admin);
        try IUUPS(address(parent)).upgradeToAndCall(address(newImpl), initData) {
            ghost_parent_upgradeCount++;
            ghost_parent_version++;
            latestParentImpl = address(newImpl);
            ghost_parent_newVal = initVal;
        } catch { /* Should not happen if logic is correct */ }
        _stopPrank();
    }

    function upgradeChild1(uint256 seed) public virtual {
        _snapshotChild1State();
        MockUpgradeChildPeer newImpl = new MockUpgradeChildPeer(
            child1.getRouter(),
            child1.getLink(),
            child1.getThisChainSelector(),
            child1.getUsdc(),
            child1.getShare(),
            child1.getParentChainSelector()
        );
        _verifyImplementationLocked(address(newImpl));

        uint64 nextVersion = ghost_child1_version + 1;
        uint256 initVal = bound(seed, 1, type(uint256).max);
        bytes memory initData =
            abi.encodeWithSelector(MockUpgradeChildPeer.initializeDynamic.selector, nextVersion, initVal);

        // Stacked Check: Attempt upgrade as attacker
        _changePrank(attacker);
        try IUUPS(address(child1)).upgradeToAndCall(address(newImpl), initData) {
            ghost_unauthorized_upgrade_success = true;
        } catch { /* Expected failure */ }
        _stopPrank();

        // Primary Action: Upgrade as admin
        _changePrank(admin);
        try IUUPS(address(child1)).upgradeToAndCall(address(newImpl), initData) {
            ghost_child1_upgradeCount++;
            ghost_child1_version++;
            latestChild1Impl = address(newImpl);
            ghost_child1_newVal = initVal;
        } catch { /* Should not happen */ }
        _stopPrank();
    }

    function upgradeChild2(uint256 seed) public virtual {
        _snapshotChild2State();
        MockUpgradeChildPeer newImpl = new MockUpgradeChildPeer(
            child2.getRouter(),
            child2.getLink(),
            child2.getThisChainSelector(),
            child2.getUsdc(),
            child2.getShare(),
            child2.getParentChainSelector()
        );

        _verifyImplementationLocked(address(newImpl));

        uint64 nextVersion = ghost_child2_version + 1;
        uint256 initVal = bound(seed, 1, type(uint256).max);
        bytes memory initData =
            abi.encodeWithSelector(MockUpgradeChildPeer.initializeDynamic.selector, nextVersion, initVal);

        // Stacked Check
        _changePrank(attacker);
        try IUUPS(address(child2)).upgradeToAndCall(address(newImpl), initData) {
            ghost_unauthorized_upgrade_success = true;
        } catch { /* Expected failure */ }
        _stopPrank();

        // Primary Action
        _changePrank(admin);
        try IUUPS(address(child2)).upgradeToAndCall(address(newImpl), initData) {
            ghost_child2_upgradeCount++;
            ghost_child2_version++;
            latestChild2Impl = address(newImpl);
            ghost_child2_newVal = initVal;
        } catch { /* Should not happen */ }
        _stopPrank();
    }

    function upgradeShare(uint256 seed) public virtual {
        _snapshotShareState();
        MockUpgradeShare newImpl = new MockUpgradeShare();

        _verifyImplementationLocked(address(newImpl));

        uint64 nextVersion = ghost_share_version + 1;
        uint256 initVal = bound(seed, 1, type(uint256).max);
        bytes memory initData =
            abi.encodeWithSelector(MockUpgradeShare.initializeDynamic.selector, nextVersion, initVal);

        // Stacked Check
        _changePrank(attacker);
        try IUUPS(address(share)).upgradeToAndCall(address(newImpl), initData) {
            ghost_unauthorized_upgrade_success = true;
        } catch { /* Expected failure */ }
        _stopPrank();

        // Primary Action
        _changePrank(admin);
        try IUUPS(address(share)).upgradeToAndCall(address(newImpl), initData) {
            ghost_share_upgradeCount++;
            ghost_share_version++;
            latestShareImpl = address(newImpl);
            ghost_share_newVal = initVal;
        } catch { /* Should not happen */ }
        _stopPrank();
    }

    function upgradeRebalancer(uint256 seed) public virtual {
        _snapshotRebalancerState();
        MockUpgradeRebalancer newImpl = new MockUpgradeRebalancer();

        _verifyImplementationLocked(address(newImpl));

        uint64 nextVersion = ghost_rebalancer_version + 1;
        uint256 initVal = bound(seed, 1, type(uint256).max);
        bytes memory initData =
            abi.encodeWithSelector(MockUpgradeRebalancer.initializeDynamic.selector, nextVersion, initVal);

        // Stacked Check
        _changePrank(attacker);
        try IUUPS(address(rebalancer)).upgradeToAndCall(address(newImpl), initData) {
            ghost_unauthorized_upgrade_success = true;
        } catch { /* Expected failure */ }
        _stopPrank();

        // Primary Action
        _changePrank(admin);
        try IUUPS(address(rebalancer)).upgradeToAndCall(address(newImpl), initData) {
            ghost_rebalancer_upgradeCount++;
            ghost_rebalancer_version++;
            latestRebalancerImpl = address(newImpl);
            ghost_rebalancer_newVal = initVal;
        } catch { /* Should not happen */ }
        _stopPrank();
    }

    function upgradeRegistryParent(uint256 seed) public virtual {
        _snapshotRegistryParentState();
        MockUpgradeStrategyRegistry newImpl = new MockUpgradeStrategyRegistry();

        _verifyImplementationLocked(address(newImpl));

        uint64 nextVersion = ghost_registryParent_version + 1;
        uint256 initVal = bound(seed, 1, type(uint256).max);
        bytes memory initData =
            abi.encodeWithSelector(MockUpgradeStrategyRegistry.initializeDynamic.selector, nextVersion, initVal);

        // Stacked Check
        _changePrank(attacker);
        try IUUPS(address(registryParent)).upgradeToAndCall(address(newImpl), initData) {
            ghost_unauthorized_upgrade_success = true;
        } catch { /* Expected failure */ }
        _stopPrank();

        // Primary Action
        _changePrank(admin);
        try IUUPS(address(registryParent)).upgradeToAndCall(address(newImpl), initData) {
            ghost_registryParent_upgradeCount++;
            ghost_registryParent_version++;
            latestRegistryParentImpl = address(newImpl);
            ghost_registryParent_newVal = initVal;
        } catch { /* Should not happen */ }
        _stopPrank();
    }

    function upgradeRegistryChild1(uint256 seed) public virtual {
        _snapshotRegistryChild1State();
        MockUpgradeStrategyRegistry newImpl = new MockUpgradeStrategyRegistry();

        _verifyImplementationLocked(address(newImpl));

        uint64 nextVersion = ghost_registryChild1_version + 1;
        uint256 initVal = bound(seed, 1, type(uint256).max);
        bytes memory initData =
            abi.encodeWithSelector(MockUpgradeStrategyRegistry.initializeDynamic.selector, nextVersion, initVal);

        // Stacked Check
        _changePrank(attacker);
        try IUUPS(address(registryChild1)).upgradeToAndCall(address(newImpl), initData) {
            ghost_unauthorized_upgrade_success = true;
        } catch { /* Expected failure */ }
        _stopPrank();

        // Primary Action
        _changePrank(admin);
        try IUUPS(address(registryChild1)).upgradeToAndCall(address(newImpl), initData) {
            ghost_registryChild1_upgradeCount++;
            ghost_registryChild1_version++;
            latestRegistryChild1Impl = address(newImpl);
            ghost_registryChild1_newVal = initVal;
        } catch { /* Should not happen */ }
        _stopPrank();
    }

    function upgradeRegistryChild2(uint256 seed) public virtual {
        _snapshotRegistryChild2State();
        MockUpgradeStrategyRegistry newImpl = new MockUpgradeStrategyRegistry();

        _verifyImplementationLocked(address(newImpl));

        uint64 nextVersion = ghost_registryChild2_version + 1;
        uint256 initVal = bound(seed, 1, type(uint256).max);
        bytes memory initData =
            abi.encodeWithSelector(MockUpgradeStrategyRegistry.initializeDynamic.selector, nextVersion, initVal);

        // Stacked Check
        _changePrank(attacker);
        try IUUPS(address(registryChild2)).upgradeToAndCall(address(newImpl), initData) {
            ghost_unauthorized_upgrade_success = true;
        } catch { /* Expected failure */ }
        _stopPrank();

        // Primary Action
        _changePrank(admin);
        try IUUPS(address(registryChild2)).upgradeToAndCall(address(newImpl), initData) {
            ghost_registryChild2_upgradeCount++;
            ghost_registryChild2_version++;
            latestRegistryChild2Impl = address(newImpl);
            ghost_registryChild2_newVal = initVal;
        } catch { /* Should not happen */ }
        _stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/
    function _deposit(uint256 _amount, address _peer) internal {
        deal(address(usdc), superUser, _amount);

        _changePrank(superUser);
        usdc.approve(_peer, _amount);
        IYieldPeer(_peer).deposit(_amount);
        ghost_parent_totalShares = parent.getTotalShares();
        ghost_share_totalSupply = share.totalSupply();
        _stopPrank();
    }

    function _withdraw(uint256 _balance, uint256 _amount, address _peer) internal {
        _dealPoolsUsdc();
        _amount = bound(_amount, 1, _balance);
        _changePrank(superUser);
        share.transferAndCall(_peer, _amount, "");
        ghost_parent_totalShares = parent.getTotalShares();
        ghost_share_totalSupply = share.totalSupply();
        _stopPrank();
    }

    function _getTargetPeerAndImpl(uint256 chainChoice) internal returns (address targetPeer, address targetImpl) {
        if (chainChoice == 0) {
            targetPeer = address(parent);

            if (latestParentImpl == address(0)) {
                targetImpl = address(uint160(uint256(vm.load(address(parent), IMPLEMENTATION_SLOT))));
                latestParentImpl = targetImpl;
            } else {
                targetImpl = latestParentImpl;
            }
        } else if (chainChoice == 1) {
            targetPeer = address(child1);

            if (latestChild1Impl == address(0)) {
                targetImpl = address(uint160(uint256(vm.load(address(child1), IMPLEMENTATION_SLOT))));
                latestChild1Impl = targetImpl;
            } else {
                targetImpl = latestChild1Impl;
            }
        } else {
            targetPeer = address(child2);

            if (latestChild2Impl == address(0)) {
                targetImpl = address(uint160(uint256(vm.load(address(child2), IMPLEMENTATION_SLOT))));
                latestChild2Impl = targetImpl;
            } else {
                targetImpl = latestChild2Impl;
            }
        }
    }

    function _pauseSystemState(address pauser) internal {
        _changePrank(pauser);
        parent.emergencyPause();
        child1.emergencyPause();
        child2.emergencyPause();

        ghost_state_paused = true;
        ghost_parent_paused = true;
        ghost_child1_paused = true;
        ghost_child2_paused = true;
        _stopPrank();
    }

    function _unpauseSystemState(address unpauser) internal {
        _changePrank(unpauser);
        parent.emergencyUnpause();
        child1.emergencyUnpause();
        child2.emergencyUnpause();

        ghost_state_paused = false;
        ghost_parent_paused = false;
        ghost_child1_paused = false;
        ghost_child2_paused = false;
        _stopPrank();
    }

    /// @dev Checks if an implementation contract has been initialized (locked).
    /// If initialize() SUCCEEDS, it means the contract was NOT locked (vulnerable).
    function _verifyImplementationLocked(address impl) internal {
        if (impl == address(0)) return;

        // Try to call initialize()
        (bool success,) = impl.call(abi.encodeWithSignature("initialize()"));

        // If the call SUCCEEDS, the implementation was open to initialization (BAD)
        if (success) {
            ghost_implementation_was_unlocked = true;
            console2.log("CRITICAL: Implementation at %s is NOT locked!", impl);
        }
    }

    /*//////////////////////////////////////////////////////////////
                          SNAPSHOT HELPERS
    //////////////////////////////////////////////////////////////*/
    function _snapshotParentState() internal {
        // Strategy state
        IYieldPeer.Strategy memory strategy = parent.getStrategy();
        ghost_parent_strategy_chainSelector = strategy.chainSelector;
        ghost_parent_strategy_protocolId = strategy.protocolId;

        ghost_parent_activeStrategyAdapter = parent.getActiveStrategyAdapter();

        // Parent specific variables
        ghost_parent_totalShares = parent.getTotalShares();
        ghost_parent_feeRate = parent.getFeeRate();
        ghost_parent_rebalancer = parent.getRebalancer();

        bytes32 initialSetSlot = bytes32(uint256(PARENT_PEER_STORAGE_LOCATION) + 2);
        ghost_parent_initialActiveStrategySet = vm.load(address(parent), initialSetSlot) != bytes32(0);

        // Peer specific variables
        ghost_parent_strategyRegistry = parent.getStrategyRegistry();
        ghost_parent_ccipGasLimit = parent.getCCIPGasLimit();

        // Allowed chain and peers state
        ghost_parent_allowedChain1 = parent.getAllowedChain(CHILD1_CHAIN_SELECTOR);
        ghost_parent_allowedChain2 = parent.getAllowedChain(CHILD2_CHAIN_SELECTOR);
        ghost_parent_allowedPeer1 = parent.getAllowedPeer(CHILD1_CHAIN_SELECTOR);
        ghost_parent_allowedPeer2 = parent.getAllowedPeer(CHILD2_CHAIN_SELECTOR);

        // Pause state
        ghost_parent_paused = parent.paused();

        if (ghost_parent_upgradeCount > 0) {
            try MockUpgradeParentPeer((address(parent))).getNewVal() returns (uint256 val) {
                ghost_parent_newVal = val;
            } catch {
                ghost_parent_newVal = 0;
            }
        } else {
            ghost_parent_newVal = 0;
        }
    }

    function _snapshotChild1State() internal {
        ghost_child1_parentChainSelector = child1.getParentChainSelector();
        ghost_child1_feeRate = child1.getFeeRate();
        ghost_child1_activeStrategyAdapter = child1.getActiveStrategyAdapter();
        ghost_child1_strategyRegistry = child1.getStrategyRegistry();
        ghost_child1_paused = child1.paused();
        ghost_child1_ccipGasLimit = child1.getCCIPGasLimit();

        ghost_child1_allowedChain1 = child1.getAllowedChain(PARENT_CHAIN_SELECTOR);
        ghost_child1_allowedChain2 = child1.getAllowedChain(CHILD2_CHAIN_SELECTOR);
        ghost_child1_allowedPeer1 = child1.getAllowedPeer(PARENT_CHAIN_SELECTOR);
        ghost_child1_allowedPeer2 = child1.getAllowedPeer(CHILD2_CHAIN_SELECTOR);
        if (ghost_child1_upgradeCount > 0) {
            try MockUpgradeChildPeer((address(child1))).getNewVal() returns (uint256 val) {
                ghost_child1_newVal = val;
            } catch {
                ghost_child1_newVal = 0;
            }
        } else {
            ghost_child1_newVal = 0;
        }
    }

    function _snapshotChild2State() internal {
        ghost_child2_parentChainSelector = child2.getParentChainSelector();
        ghost_child2_feeRate = child2.getFeeRate();
        ghost_child2_activeStrategyAdapter = child2.getActiveStrategyAdapter();
        ghost_child2_strategyRegistry = child2.getStrategyRegistry();
        ghost_child2_paused = child2.paused();
        ghost_child2_ccipGasLimit = child2.getCCIPGasLimit();

        ghost_child2_allowedChain1 = child2.getAllowedChain(PARENT_CHAIN_SELECTOR);
        ghost_child2_allowedChain2 = child2.getAllowedChain(CHILD1_CHAIN_SELECTOR);
        ghost_child2_allowedPeer1 = child2.getAllowedPeer(PARENT_CHAIN_SELECTOR);
        ghost_child2_allowedPeer2 = child2.getAllowedPeer(CHILD1_CHAIN_SELECTOR);
        if (ghost_child2_upgradeCount > 0) {
            try MockUpgradeChildPeer(payable(address(child2))).getNewVal() returns (uint256 val) {
                ghost_child2_newVal = val;
            } catch {
                ghost_child2_newVal = 0;
            }
        } else {
            ghost_child2_newVal = 0;
        }
    }

    function _snapshotShareState() internal {
        ghost_share_totalSupply = share.totalSupply();
        ghost_share_name = share.name();
        ghost_share_symbol = share.symbol();
        ghost_share_decimals = share.decimals();
        ghost_share_ccipAdmin = share.getCCIPAdmin();
        ghost_share_balance = share.balanceOf(superUser);
        ghost_share_allowance_parent = share.allowance(superUser, address(parent));
        ghost_share_allowance_child1 = share.allowance(superUser, address(child1));
        ghost_share_allowance_child2 = share.allowance(superUser, address(child2));

        if (ghost_share_upgradeCount > 0) {
            try MockUpgradeShare((address(share))).getNewVal() returns (uint256 val) {
                ghost_share_newVal = val;
            } catch {
                ghost_share_newVal = 0;
            }
        } else {
            ghost_share_newVal = 0;
        }
    }

    function _snapshotRebalancerState() internal {
        ghost_rebalancer_forwarder = rebalancer.getKeystoneForwarder();
        ghost_rebalancer_parentPeer = rebalancer.getParentPeer();
        ghost_rebalancer_strategyRegistry = rebalancer.getStrategyRegistry();

        CREReceiver.Workflow memory workflow = rebalancer.getWorkflow(workflowId);
        ghost_rebalancer_workflowOwner = workflow.owner;
        ghost_rebalancer_workflowName = workflow.name;

        if (ghost_rebalancer_upgradeCount > 0) {
            try MockUpgradeRebalancer(payable(address(rebalancer))).getNewVal() returns (uint256 val) {
                ghost_rebalancer_newVal = val;
            } catch {
                ghost_rebalancer_newVal = 0;
            }
        } else {
            ghost_rebalancer_newVal = 0;
        }
    }

    function _snapshotRegistryParentState() internal {
        ghost_registryParent_aaveV3_adapter = registryParent.getStrategyAdapter(AAVE_V3_PROTOCOL_ID);
        ghost_registryParent_compoundV3_adapter = registryParent.getStrategyAdapter(COMPOUND_V3_PROTOCOL_ID);

        if (ghost_registryParent_upgradeCount > 0) {
            try MockUpgradeStrategyRegistry(payable(address(registryParent))).getNewVal() returns (uint256 val) {
                ghost_registryParent_newVal = val;
            } catch {
                ghost_registryParent_newVal = 0;
            }
        } else {
            ghost_registryParent_newVal = 0;
        }
    }

    function _snapshotRegistryChild1State() internal {
        ghost_registryChild1_aaveV3_adapter = registryChild1.getStrategyAdapter(AAVE_V3_PROTOCOL_ID);
        ghost_registryChild1_compoundV3_adapter = registryChild1.getStrategyAdapter(COMPOUND_V3_PROTOCOL_ID);

        if (ghost_registryChild1_upgradeCount > 0) {
            try MockUpgradeStrategyRegistry(payable(address(registryChild1))).getNewVal() returns (uint256 val) {
                ghost_registryChild1_newVal = val;
            } catch {
                ghost_registryChild1_newVal = 0;
            }
        } else {
            ghost_registryChild1_newVal = 0;
        }
    }

    function _snapshotRegistryChild2State() internal {
        ghost_registryChild2_aaveV3_adapter = registryChild2.getStrategyAdapter(AAVE_V3_PROTOCOL_ID);
        ghost_registryChild2_compoundV3_adapter = registryChild2.getStrategyAdapter(COMPOUND_V3_PROTOCOL_ID);

        if (ghost_registryChild2_upgradeCount > 0) {
            try MockUpgradeStrategyRegistry(payable(address(registryChild2))).getNewVal() returns (uint256 val) {
                ghost_registryChild2_newVal = val;
            } catch {
                ghost_registryChild2_newVal = 0;
            }
        } else {
            ghost_registryChild2_newVal = 0;
        }
    }

    /*//////////////////////////////////////////////////////////////
                                UTILITY
    //////////////////////////////////////////////////////////////*/
    function _dealPoolsUsdc() internal {
        if (aavePool != address(0)) deal(address(usdc), aavePool, POOL_DEAL_AMOUNT);
        if (compoundPool != address(0)) deal(address(usdc), compoundPool, POOL_DEAL_AMOUNT);
    }

    function _changePrank(address newPrank) internal {
        vm.stopPrank();
        vm.startPrank(newPrank);
    }

    function _stopPrank() internal {
        vm.stopPrank();
    }
}
