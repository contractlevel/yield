// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// import {Test, console2} from "forge-std/Test.sol";
// import {
//     ParentPeer,
//     ChildPeer,
//     Share,
//     Rebalancer,
//     Roles,
//     IERC20,
//     StrategyRegistry,
//     IYieldPeer,
//     WorkflowHelpers
// } from "test/BaseTest.t.sol";
// import {
//     MockUpgradeStorage,
//     MockUpgradeParentPeer,
//     MockUpgradeChildPeer,
//     MockUpgradeShare,
//     MockUpgradeRebalancer,
//     MockUpgradeStrategyRegistry
// } from "./mocks/MockUpgrade.sol";
// import {CREReceiver} from "src/modules/CREReceiver.sol";

// /**
//  * @title ProxyHandler
//  * @author George Gorzhiyev | Judge Finance
//  * @notice The ProxyHandler contract is responsible for managing upgrades and interactions with proxy contracts in the system.
//  */

// interface IUUPS {
//     function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
// }

// interface Pausable {
//     function paused() external view returns (bool);
//     function emergencyPause() external;
//     function emergencyUnpause() external;
// }

// contract ProxyHandler is Test {
//     /*//////////////////////////////////////////////////////////////
//                                VARIABLES
//     //////////////////////////////////////////////////////////////*/
//     struct GlobalState {
//         bool paused;
//         uint256 feeRate;
//         uint256 ccipGasLimit;
//         bool withdrewWhilePaused;
//         bool depositedWhilePaused;
//         bool depositedIntoImpl;
//         bool withdrawFromImpl;
//         bool unauthorizedUpgradeSuccess;
//         bool implementationWasUnlocked;
//     }

//     struct ParentState {
//         uint256 totalShares;
//         address rebalancer;
//         bool initialActiveStrategySet;
//         uint64 strategyChainSelector;
//         bytes32 strategyProtocolId;
//     }

//     struct PeerState {
//         uint64 version;
//         uint256 upgradeCount;
//         uint256 newVal;
//         address latestImpl;
//         bool paused;
//         uint256 feeRate;
//         uint256 ccipGasLimit;
//         address activeStrategyAdapter;
//         address strategyRegistry;
//         mapping(uint64 => bool) allowedChains;
//         mapping(uint64 => address) allowedPeers;
//     }

//     struct ShareState {
//         uint64 version;
//         uint256 upgradeCount;
//         uint256 newVal;
//         address latestImpl;
//         uint256 totalSupply;
//         uint256 userBalance;
//         address ccipAdmin;
//         string name;
//         string symbol;
//         uint8 decimals;
//         mapping(address peer => uint256 amount) allowances;
//     }

//     struct RegistryState {
//         uint64 version;
//         uint256 upgradeCount;
//         uint256 newVal;
//         address latestImpl;
//         address aaveV3Adapter;
//         address compoundV3Adapter;
//     }

//     struct RebalancerState {
//         uint64 version;
//         uint256 upgradeCount;
//         uint256 newVal;
//         address latestImpl;
//         address parentPeer;
//         address strategyRegistry;
//         address forwarder;
//         address workflowOwner;
//         bytes10 workflowName;
//     }

//     // Constants
//     uint256 internal constant MAX_DEPOSIT_AMOUNT = 1_000_000_000_000;
//     uint256 internal constant INITIAL_DEPOSIT_AMOUNT = 100_000_000;
//     bytes32 public constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

//     uint64 internal constant PARENT_CHAIN_SELECTOR = 1;
//     uint64 internal constant CHILD1_CHAIN_SELECTOR = 2;
//     uint64 internal constant CHILD2_CHAIN_SELECTOR = 3;

//     bytes32 internal constant AAVE_V3_PROTOCOL_ID = keccak256(abi.encodePacked("aave-v3"));
//     bytes32 internal constant COMPOUND_V3_PROTOCOL_ID = keccak256(abi.encodePacked("compound-v3"));

//     // Rebalancer Workflow
//     address internal workflowOwner = makeAddr("workflowOwner");
//     bytes32 internal workflowId = bytes32("rebalanceWorkflowId");
//     string internal workflowNameRaw = "yieldcoin-rebalance-workflow";
//     bytes10 internal workflowName = WorkflowHelpers.createWorkflowName(workflowNameRaw);
//     bytes internal workflowMetadata = WorkflowHelpers.createWorkflowMetadata(workflowId, workflowName, workflowOwner);

//     // Share, USDC, Rebalancer
//     Share internal share;
//     IERC20 internal usdc;
//     Rebalancer internal rebalancer;

//     // Aave & Compound Pools
//     address internal aavePool;
//     address internal compoundPool;

//     // Basic users
//     address public superUser = makeAddr("super_user");
//     address internal admin;
//     address internal attacker = makeAddr("attacker");

//     // Ghosts
//     GlobalState public globalGhost;
//     ParentState public parentGhost;
//     ShareState public shareGhost;
//     RebalancerState public rebalancerGhost;

//     mapping(uint64 => IYieldPeer) public peers;
//     mapping(uint64 => PeerState) public peerGhosts;

//     mapping(uint64 => StrategyRegistry) public registries;
//     mapping(uint64 => RegistryState) public registryGhosts;

//     uint64[] public activeSelectors;

//     /*//////////////////////////////////////////////////////////////
//                               CONSTRUCTOR
//     //////////////////////////////////////////////////////////////*/
//     constructor(
//         ParentPeer _parent,
//         ChildPeer _child1,
//         ChildPeer _child2,
//         Share _share,
//         Rebalancer _rebalancer,
//         StrategyRegistry _registryParent,
//         StrategyRegistry _registryChild1,
//         StrategyRegistry _registryChild2,
//         IERC20 _usdc,
//         address _aavePool,
//         address _compoundPool
//     ) {
//         share = _share;
//         usdc = _usdc;
//         rebalancer = _rebalancer;
//         aavePool = _aavePool;
//         compoundPool = _compoundPool;
//         admin = _parent.owner();

//         // Register Peers
//         peers[1] = IYieldPeer(address(_parent));
//         peers[2] = IYieldPeer(address(_child1));
//         peers[3] = IYieldPeer(address(_child2));

//         // Register Strategy Registries mapped identically to the chains
//         registries[1] = _registryParent;
//         registries[2] = _registryChild1;
//         registries[3] = _registryChild2;

//         activeSelectors = [PARENT_CHAIN_SELECTOR, CHILD1_CHAIN_SELECTOR, CHILD2_CHAIN_SELECTOR];

//         // Initialize Base Versions for all upgradeable components
//         for (uint256 i = 0; i < activeSelectors.length; i++) {
//             peerGhosts[activeSelectors[i]].version = 1;
//             registryGhosts[activeSelectors[i]].version = 1;
//         }
//         shareGhost.version = 1;
//         rebalancerGhost.version = 1;

//         _setFeeRate(0);
//         _initialDeposit();
//         _snapshotAll();
//     }

//     /*//////////////////////////////////////////////////////////////
//           PROTOCOL INTERACTIONS (deposit, withdraw, rebalance)
//     //////////////////////////////////////////////////////////////*/
//     function deposit(uint256 depositAmount, uint256 chainSelectorSeed) public virtual {
//         depositAmount = bound(depositAmount, INITIAL_DEPOSIT_AMOUNT / 100, MAX_DEPOSIT_AMOUNT);

//         uint64 targetChain = _selectChain(chainSelectorSeed);
//         IYieldPeer targetPeer = peers[targetChain];
//         address targetImpl = _getTargetImpl(targetChain);

//         vm.startPrank(superUser);
//         deal(address(usdc), superUser, depositAmount);

//         // STACKED CHECK 1: Negative - Direct impl deposit
//         try IYieldPeer(targetImpl).deposit(depositAmount) {
//             globalGhost.depositedIntoImpl = true;
//         } catch {}

//         // STACKED CHECK 2: Negative - Deposit while paused
//         if (globalGhost.paused) {
//             usdc.approve(address(targetPeer), depositAmount);
//             try targetPeer.deposit(depositAmount) {
//                 globalGhost.depositedWhilePaused = true;
//             } catch {}
//             vm.stopPrank();
//             return; // Preserve paused state for fuzzer exploration
//         }

//         // PRIMARY ACTION
//         usdc.approve(address(targetPeer), depositAmount);
//         targetPeer.deposit(depositAmount);
//         vm.stopPrank();

//         // Sync entire system state (CCIP messages mutate across chains)
//         _snapshotAll();
//     }

//     function withdraw(uint256 withdrawAmount, uint256 chainSeed) public virtual {
//         uint256 userBalance = share.balanceOf(superUser);
//         _dealPoolsUsdc();

//         // Edge case bypass: Attempt deposit if balance is empty
//         if (userBalance == 0) {
//             deposit(withdrawAmount, chainSeed);
//             userBalance = share.balanceOf(superUser);
//             if (userBalance == 0) return;
//         }

//         uint64 targetChain = _selectChain(chainSeed);
//         IYieldPeer targetPeer = peers[targetChain];
//         address targetImpl = _getTargetImpl(targetChain);

//         withdrawAmount = bound(withdrawAmount, 1, userBalance);

//         vm.startPrank(superUser);

//         // STACKED CHECK 1: Negative - Direct impl withdraw
//         try share.transferAndCall(targetImpl, withdrawAmount, "") {
//             globalGhost.withdrawFromImpl = true;
//         } catch {}

//         // STACKED CHECK 2: Negative - Withdraw while paused
//         if (globalGhost.paused) {
//             try share.transferAndCall(address(targetPeer), withdrawAmount, "") {
//                 globalGhost.withdrewWhilePaused = true;
//             } catch {}
//             vm.stopPrank();
//             return;
//         }

//         // PRIMARY ACTION
//         share.transferAndCall(address(targetPeer), withdrawAmount, "");
//         vm.stopPrank();

//         _snapshotAll();
//     }

//     function rebalance(uint256 chainSeed, uint256 protocolSeed) public virtual {
//         // Ensure pools have liquidity so strategy migration doesn't revert
//         _dealPoolsUsdc();

//         // --- 1. Dynamic Routing ---
//         uint64 targetChain = _selectChain(chainSeed);
//         bytes32 protocolId = (protocolSeed % 2 == 0) ? AAVE_V3_PROTOCOL_ID : COMPOUND_V3_PROTOCOL_ID;

//         // --- 2. Payload Generation ---
//         bytes memory report = WorkflowHelpers.createWorkflowReport(targetChain, protocolId);
//         bytes memory metadata = WorkflowHelpers.createWorkflowMetadata(workflowId, workflowName, workflowOwner);

//         // Advance time to simulate realistic workflow pacing
//         vm.warp(block.timestamp + 1 hours);

//         // --- 3. Execution ---
//         address currentForwarder = rebalancer.getKeystoneForwarder();

//         vm.startPrank(currentForwarder);
//         rebalancer.onReport(metadata, report);
//         vm.stopPrank();

//         // --- 4. Global State Sync ---
//         // Because rebalancing moves TVL, updates adapters, and changes Parent state,
//         // we take a clean picture of the entire network.
//         _snapshotAll();
//     }

//     /*//////////////////////////////////////////////////////////////
//                            SETTER INTERACTIONS
//     //////////////////////////////////////////////////////////////*/
//     function setterInteraction(uint256 interactionSeed, uint256 setterSeed) public {
//         uint256 interactionChoice = interactionSeed % 3;
//         if (interactionChoice == 0) _setFeeRate(setterSeed);
//         else if (interactionChoice == 1) _setCCIPGasLimit(setterSeed);
//         else _togglePause();
//     }

//     function _setFeeRate(uint256 newFeeRate) internal {
//         // Assume fee rate setter role is universally managed via the Parent's access control
//         ParentPeer parent = ParentPeer(address(peers[PARENT_CHAIN_SELECTOR]));
//         address feeRateSetter = parent.getRoleMember(Roles.FEE_RATE_SETTER_ROLE, 0);

//         newFeeRate = bound(newFeeRate, 0, parent.getMaxFeeRate());

//         vm.startPrank(feeRateSetter);
//         for (uint256 i = 0; i < activeSelectors.length; i++) {
//             peers[activeSelectors[i]].setFeeRate(newFeeRate);
//         }
//         vm.stopPrank();

//         globalGhost.feeRate = newFeeRate;
//         _snapshotAll();
//     }

//     function _setCCIPGasLimit(uint256 ccipGasLimit) internal {
//         uint256 minGas = 900_000;
//         ParentPeer parent = ParentPeer(address(peers[PARENT_CHAIN_SELECTOR]));
//         address crossChainAdmin = parent.getRoleMember(Roles.CROSS_CHAIN_ADMIN_ROLE, 0);

//         ccipGasLimit = bound(ccipGasLimit, minGas, 1_000_000); // Max CCIP_GAS_LIMIT

//         vm.startPrank(crossChainAdmin);
//         for (uint256 i = 0; i < activeSelectors.length; i++) {
//             peers[activeSelectors[i]].setCCIPGasLimit(ccipGasLimit);
//         }
//         vm.stopPrank();

//         globalGhost.ccipGasLimit = ccipGasLimit;
//         _snapshotAll();
//     }

//     function _togglePause() internal {
//         ParentPeer parent = ParentPeer(address(peers[PARENT_CHAIN_SELECTOR]));

//         if (!globalGhost.paused) {
//             address pauser = parent.getRoleMember(Roles.EMERGENCY_PAUSER_ROLE, 0);
//             vm.startPrank(pauser);
//             for (uint256 i = 0; i < activeSelectors.length; i++) {
//                 Pausable(address(peers[activeSelectors[i]])).emergencyPause();
//             }
//             vm.stopPrank();
//             globalGhost.paused = true;
//         } else {
//             address unpauser = parent.getRoleMember(Roles.EMERGENCY_UNPAUSER_ROLE, 0);
//             vm.startPrank(unpauser);
//             for (uint256 i = 0; i < activeSelectors.length; i++) {
//                 Pausable(address(peers[activeSelectors[i]])).emergencyUnpause();
//             }
//             vm.stopPrank();
//             globalGhost.paused = false;
//         }

//         _snapshotAll();
//     }

//     /*//////////////////////////////////////////////////////////////
//                                 UPGRADES
//     //////////////////////////////////////////////////////////////*/
//     function triggerRandomUpgrade(uint256 seed, uint256 selectorSeed) public {
//         // We route to 4 distinct architectural categories.
//         uint256 targetCategory = selectorSeed % 4;

//         if (targetCategory == 0) {
//             _triggerPeerUpgrade(seed, selectorSeed);
//         } else if (targetCategory == 1) {
//             _triggerRegistryUpgrade(seed, selectorSeed);
//         } else if (targetCategory == 2) {
//             _triggerRebalancerUpgrade(seed);
//         } else {
//             _triggerShareUpgrade(seed);
//         }
//     }

//     function _triggerPeerUpgrade(uint256 seed, uint256 selectorSeed) internal {
//         uint64 targetChain = _selectChain(selectorSeed);
//         IYieldPeer targetPeer = peers[targetChain];

//         _snapshotPeerState(targetChain);

//         // --- Immutable Extraction & Implementation Deployment ---
//         address newImpl;

//         if (targetChain == PARENT_CHAIN_SELECTOR) {
//             ParentPeer parent = ParentPeer(address(targetPeer));
//             // Route constructor args cleanly from the live Parent
//             newImpl = address(
//                 new MockUpgradeParentPeer(
//                     parent.getRouter(), // Extracted from CCIPReceiver base (assumes public/getter exists)
//                     parent.getLink(),
//                     parent.getThisChainSelector(),
//                     parent.getUsdc(),
//                     parent.getShare()
//                 )
//             );
//         } else {
//             ChildPeer child = ChildPeer(address(targetPeer));
//             // Route constructor args cleanly from the live Child
//             newImpl = address(
//                 new MockUpgradeChildPeer(
//                     child.getRouter(), // Extracted from CCIPReceiver base
//                     child.getLink(),
//                     child.getThisChainSelector(),
//                     child.getUsdc(),
//                     child.getShare(),
//                     child.getParentChainSelector() // Unique to Child
//                 )
//             );
//         }

//         _verifyImplementationLocked(newImpl);

//         // --- Standardized Upgrade Execution ---
//         PeerState storage ghost = peerGhosts[targetChain];
//         uint64 nextVersion = ghost.version + 1;
//         uint256 initVal = bound(seed, 1, type(uint256).max);

//         // ERC-7201 standard dictates the reinitializer handles the dynamic variables
//         bytes memory initData =
//             abi.encodeWithSelector(MockUpgradeStorage.initializeDynamic.selector, nextVersion, initVal);

//         // Negative check
//         _tryUnauthorizedUpgrade(address(targetPeer), newImpl, initData);

//         // Positive check
//         vm.prank(admin);
//         try IUUPS(address(targetPeer)).upgradeToAndCall(newImpl, initData) {
//             ghost.upgradeCount++;
//             ghost.version++;
//             ghost.latestImpl = newImpl;
//             ghost.newVal = initVal;
//         } catch {}
//     }

//     function _triggerRegistryUpgrade(uint256 seed, uint256 selectorSeed) internal {
//         uint64 targetChain = _selectChain(selectorSeed);
//         StrategyRegistry targetRegistry = registries[targetChain];

//         _snapshotRegistryState(targetChain);

//         address newImpl = address(new MockUpgradeStrategyRegistry());
//         _verifyImplementationLocked(newImpl);

//         RegistryState storage ghost = registryGhosts[targetChain];
//         uint64 nextVersion = ghost.version + 1;
//         uint256 initVal = bound(seed, 1, type(uint256).max);
//         bytes memory initData =
//             abi.encodeWithSelector(MockUpgradeStorage.initializeDynamic.selector, nextVersion, initVal);

//         vm.prank(admin);
//         try IUUPS(address(targetRegistry)).upgradeToAndCall(newImpl, initData) {
//             ghost.upgradeCount++;
//             ghost.version++;
//             ghost.latestImpl = newImpl;
//             ghost.newVal = initVal;
//         } catch {}
//     }

//     function _triggerRebalancerUpgrade(uint256 seed) internal {
//         _snapshotRebalancerState();

//         address newImpl = address(new MockUpgradeRebalancer());
//         _verifyImplementationLocked(newImpl);

//         uint64 nextVersion = rebalancerGhost.version + 1;
//         uint256 initVal = bound(seed, 1, type(uint256).max);
//         bytes memory initData =
//             abi.encodeWithSelector(MockUpgradeStorage.initializeDynamic.selector, nextVersion, initVal);

//         _tryUnauthorizedUpgrade(address(rebalancer), newImpl, initData);

//         vm.prank(admin);
//         try IUUPS(address(rebalancer)).upgradeToAndCall(newImpl, initData) {
//             rebalancerGhost.upgradeCount++;
//             rebalancerGhost.version++;
//             rebalancerGhost.latestImpl = newImpl;
//             rebalancerGhost.newVal = initVal;
//         } catch {}
//     }

//     function _triggerShareUpgrade(uint256 seed) internal {
//         _snapshotShareState();

//         address newImpl = address(new MockUpgradeShare());
//         _verifyImplementationLocked(newImpl);

//         ShareState storage ghost = shareGhost;
//         uint64 nextVersion = ghost.version + 1;
//         uint256 initVal = bound(seed, 1, type(uint256).max);
//         bytes memory initData =
//             abi.encodeWithSelector(MockUpgradeStorage.initializeDynamic.selector, nextVersion, initVal);

//         _tryUnauthorizedUpgrade(address(share), newImpl, initData);

//         // Positive state-changing upgrade
//         vm.prank(admin);
//         try IUUPS(address(share)).upgradeToAndCall(newImpl, initData) {
//             ghost.upgradeCount++;
//             ghost.version++;
//             ghost.latestImpl = newImpl;
//             ghost.newVal = initVal;
//         } catch {}
//     }

//     /*//////////////////////////////////////////////////////////////
//                                SNAPSHOTS
//     //////////////////////////////////////////////////////////////*/
//     function _snapshotAll() internal {
//         for (uint256 i = 0; i < activeSelectors.length; i++) {
//             uint64 chain = activeSelectors[i];

//             // 1. Universal peer state
//             _snapshotPeerState(chain);

//             // 2. Specialized architectural state
//             if (chain == PARENT_CHAIN_SELECTOR) {
//                 _snapshotParentState(chain);
//             }

//             // 3. Registry state
//             _snapshotRegistryState(chain);
//         }

//         // 4. Singleton state
//         _snapshotShareState();
//         _snapshotRebalancerState();
//     }

//     function _snapshotPeerState(uint64 chain) internal {
//         IYieldPeer peer = peers[chain];
//         PeerState storage ghost = peerGhosts[chain];

//         // Universal Peer State
//         ghost.paused = Pausable(address(peer)).paused();
//         ghost.feeRate = peer.getFeeRate();
//         ghost.ccipGasLimit = peer.getCCIPGasLimit();
//         ghost.activeStrategyAdapter = peer.getActiveStrategyAdapter();
//         ghost.strategyRegistry = peer.getStrategyRegistry();

//         // Dynamically snapshot allowed cross-chain topography
//         for (uint256 i = 0; i < activeSelectors.length; i++) {
//             uint64 targetChain = activeSelectors[i];
//             ghost.allowedChains[targetChain] = peer.getAllowedChain(targetChain);
//             ghost.allowedPeers[targetChain] = peer.getAllowedPeer(targetChain);
//         }

//         // Mock State Fallbacks
//         if (ghost.upgradeCount > 0) {
//             try MockUpgradeStorage(address(peer)).getNewVal() returns (uint256 val) {
//                 ghost.newVal = val;
//             } catch {}
//         }
//     }

//     function _snapshotParentState(uint64 chain) internal {
//         ParentPeer parent = ParentPeer(address(peers[chain]));

//         parentGhost.totalShares = parent.getTotalShares();
//         parentGhost.rebalancer = parent.getRebalancer();

//         // Raw storage read for the initialization flag
//         bytes32 parentStorageLocation = 0x603686382b15940b5fa7ef449162bde228a5948ce3b6bdf08bd833ec6ae79500;
//         bytes32 initialSetSlot = bytes32(uint256(parentStorageLocation) + 2);
//         parentGhost.initialActiveStrategySet = vm.load(address(parent), initialSetSlot) != bytes32(0);

//         IYieldPeer.Strategy memory strategy = parent.getStrategy();
//         parentGhost.strategyChainSelector = strategy.chainSelector;
//         parentGhost.strategyProtocolId = strategy.protocolId;
//     }

//     function _snapshotRegistryState(uint64 chain) internal {
//         StrategyRegistry registry = registries[chain];
//         RegistryState storage ghost = registryGhosts[chain];

//         ghost.aaveV3Adapter = registry.getStrategyAdapter(AAVE_V3_PROTOCOL_ID);
//         ghost.compoundV3Adapter = registry.getStrategyAdapter(COMPOUND_V3_PROTOCOL_ID);

//         if (ghost.upgradeCount > 0) {
//             try MockUpgradeStorage(address(registry)).getNewVal() returns (uint256 val) {
//                 ghost.newVal = val;
//             } catch {}
//         }
//     }

//     function _snapshotRebalancerState() internal {
//         rebalancerGhost.forwarder = rebalancer.getKeystoneForwarder();
//         rebalancerGhost.parentPeer = rebalancer.getParentPeer();
//         rebalancerGhost.strategyRegistry = rebalancer.getStrategyRegistry();

//         try rebalancer.getWorkflow(workflowId) returns (CREReceiver.Workflow memory workflow) {
//             rebalancerGhost.workflowOwner = workflow.owner;
//             rebalancerGhost.workflowName = workflow.name;
//         } catch {}

//         if (rebalancerGhost.upgradeCount > 0) {
//             try MockUpgradeStorage(address(rebalancer)).getNewVal() returns (uint256 val) {
//                 rebalancerGhost.newVal = val;
//             } catch {}
//         }
//     }

//     function _snapshotShareState() internal {
//         shareGhost.totalSupply = share.totalSupply();
//         shareGhost.userBalance = share.balanceOf(superUser);
//         shareGhost.name = share.name();
//         shareGhost.symbol = share.symbol();
//         shareGhost.decimals = share.decimals();
//         shareGhost.ccipAdmin = share.getCCIPAdmin();

//         for (uint256 i = 0; i < activeSelectors.length; i++) {
//             uint64 chain = activeSelectors[i];
//             address peerAddress = address(peers[chain]);
//             shareGhost.allowances[peerAddress] = share.allowance(superUser, peerAddress);
//         }

//         if (shareGhost.upgradeCount > 0) {
//             try MockUpgradeStorage(address(share)).getNewVal() returns (uint256 val) {
//                 shareGhost.newVal = val;
//             } catch {}
//         }
//     }

//     /*//////////////////////////////////////////////////////////////
//                            GHOST MAPPINGS EXPOSURE
//     //////////////////////////////////////////////////////////////*/
//     function getGhostAllowedChain(uint64 peerChain, uint64 targetChain) external view returns (bool) {
//         return peerGhosts[peerChain].allowedChains[targetChain];
//     }

//     function getGhostAllowedPeer(uint64 peerChain, uint64 targetChain) external view returns (address) {
//         return peerGhosts[peerChain].allowedPeers[targetChain];
//     }

//     function getGhostAllowance(address peerAddress) external view returns (uint256) {
//         return shareGhost.allowances[peerAddress];
//     }

//     /*//////////////////////////////////////////////////////////////
//                            HELPERS & UTILITY
//     //////////////////////////////////////////////////////////////*/
//     function _verifyImplementationLocked(address impl) internal {
//         (bool success,) = impl.call(abi.encodeWithSignature("initialize()"));
//         if (success) globalGhost.implementationWasUnlocked = true;
//     }

//     function _tryUnauthorizedUpgrade(address targetProxy, address newImpl, bytes memory initData) internal {
//         vm.prank(attacker);
//         try IUUPS(address(targetProxy)).upgradeToAndCall(newImpl, initData) {
//             globalGhost.unauthorizedUpgradeSuccess = true;
//         } catch {}
//     }

//     function _getTargetImpl(uint64 chain) internal returns (address impl) {
//         impl = peerGhosts[chain].latestImpl;

//         // If an upgrade hasn't happened yet, pull the initial logic contract from the proxy slot
//         if (impl == address(0)) {
//             address proxyAddress = address(peers[chain]);
//             impl = address(uint160(uint256(vm.load(proxyAddress, IMPLEMENTATION_SLOT))));
//             peerGhosts[chain].latestImpl = impl;
//         }
//     }

//     function _selectChain(uint256 seed) internal view returns (uint64) {
//         return activeSelectors[seed % activeSelectors.length];
//     }

//     function _dealPoolsUsdc() internal {
//         if (aavePool != address(0)) deal(address(usdc), aavePool, 1_000_000_000_000_000_000);
//         if (compoundPool != address(0)) deal(address(usdc), compoundPool, 1_000_000_000_000_000_000);
//     }

//     function _changePrank(address newPrank) internal {
//         vm.stopPrank();
//         vm.startPrank(newPrank);
//     }

//     function _stopPrank() internal {
//         vm.stopPrank();
//     }

//     function _initialDeposit() internal {
//         vm.startPrank(superUser);
//         deal(address(usdc), superUser, INITIAL_DEPOSIT_AMOUNT);
//         usdc.approve(address(peers[1]), INITIAL_DEPOSIT_AMOUNT);
//         peers[1].deposit(INITIAL_DEPOSIT_AMOUNT);
//         vm.stopPrank();
//     }
// }
