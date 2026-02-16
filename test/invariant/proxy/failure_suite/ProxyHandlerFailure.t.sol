// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// @review Currently not used, meant to test collision detection

// import {ProxyHandler} from "./../ProxyHandler.t.sol";
// import {ParentPeer, ChildPeer, Share, Rebalancer, IERC20, StrategyRegistry} from "../../../BaseTest.t.sol";
// import {
//     MockUpgradeParentPeerUnsafe,
//     MockUpgradeChildPeerUnsafe,
//     MockUpgradeShareUnsafe,
//     MockUpgradeRebalancerUnsafe,
//     MockUpgradeStrategyRegistryUnsafe
// } from "./../mocks/MockUpgrade.sol";

// /// @title ProxyHandlerFailure
// /// @notice A specialized handler that performs UNSAFE upgrades to test collision detection.
// contract ProxyHandlerFailure is ProxyHandler {
//     constructor(
//         address _parent,
//         address _child1,
//         address _child2,
//         address _share,
//         address _rebalancer,
//         address _registry,
//         address _usdc,
//         address _admin
//     )
//         ProxyHandler(
//             ParentPeer(_parent),
//             ChildPeer(_child1),
//             ChildPeer(_child2),
//             Share(_share),
//             Rebalancer(_rebalancer),
//             StrategyRegistry(_registry),
//             IERC20(_usdc),
//             _admin
//         )
//     {}

//     // --- INTERACTION OVERRIDES ---
//     // We disable standard interactions once an upgrade happens to focus purely on the corruption state.

//     function deposit(uint256 amount, uint256 seed) public override {
//         if (ghost_parent_upgradeCount > 0 || ghost_share_upgradeCount > 0) return;
//         super.deposit(amount, seed);
//     }

//     function withdraw(uint256 amount, uint256 seed) public override {
//         if (ghost_parent_upgradeCount > 0 || ghost_share_upgradeCount > 0) return;
//         super.withdraw(amount, seed);
//     }

//     // NEW: Block rebalance after upgrade to prevent ghost state from syncing to corruption
//     function rebalance(uint256 chainSeed, uint256 protocolSeed) public override {
//         // If any upgrade has happened, we stop rebalancing to preserve the mismatch
//         if (
//             ghost_parent_upgradeCount > 0 || ghost_child1_upgradeCount > 0 || ghost_child2_upgradeCount > 0
//                 || ghost_rebalancer_upgradeCount > 0
//         ) return;

//         super.rebalance(chainSeed, protocolSeed);
//     }

//     function setFeeRate(uint256 newRate) public override {
//         if (ghost_parent_upgradeCount > 0) return;
//         super.setFeeRate(newRate);
//     }

//     function setRebalancer(uint256 seed) public override {
//         if (ghost_parent_upgradeCount > 0) return;
//         super.setRebalancer(seed);
//     }

//     function setWorkflow(uint256 seed) public override {
//         if (ghost_rebalancer_upgradeCount > 0) return;
//         super.setWorkflow(seed);
//     }

//     // --- UPGRADE OVERRIDES (THE UNSAFE PART) ---

//     function upgradeParent(uint256 seed) public override {
//         if (ghost_parent_upgradeCount > 0) return;

//         _snapshotParentState();

//         MockUpgradeParentPeerUnsafe newImpl =
//             new MockUpgradeParentPeerUnsafe(address(1), address(1), 1, address(1), address(1));

//         uint64 nextVersion = ghost_parent_version + 1;
//         uint256 initVal = bound(seed, 1, type(uint256).max);

//         bytes memory initData =
//             abi.encodeWithSelector(MockUpgradeParentPeerUnsafe.initializeDynamic.selector, nextVersion, initVal);

//         bool success = _upgradeContract(address(parent), address(newImpl), seed, initData);

//         if (success && _isCallerAdmin(seed)) {
//             ghost_parent_upgradeCount++;
//             ghost_parent_version++;
//             latestParentImplementation = address(newImpl);
//         }
//     }

//     function upgradeChild1(uint256 seed) public override {
//         if (ghost_child1_upgradeCount > 0) return;

//         _snapshotChild1State();
//         MockUpgradeChildPeerUnsafe newImpl =
//             new MockUpgradeChildPeerUnsafe(address(1), address(1), 2, address(1), address(1), 1);

//         uint64 nextVersion = ghost_child1_version + 1;
//         uint256 initVal = bound(seed, 1, type(uint256).max);

//         if (initVal == 500_000) initVal = 500_001;

//         bytes memory initData =
//             abi.encodeWithSelector(MockUpgradeChildPeerUnsafe.initializeDynamic.selector, nextVersion, initVal);

//         bool success = _upgradeContract(address(child1), address(newImpl), seed, initData);

//         if (success && _isCallerAdmin(seed)) {
//             ghost_child1_upgradeCount++;
//             ghost_child1_version++;
//             latestChild1Implementation = address(newImpl);
//         }
//     }

//     function upgradeChild2(uint256 seed) public override {
//         // We only corrupt Child 1 for this suite
//         if (ghost_child2_upgradeCount > 0) return;
//         super.upgradeChild2(seed);
//     }

//     function upgradeShare(uint256 seed) public override {
//         if (ghost_share_upgradeCount > 0) return;

//         _snapshotShareState();
//         MockUpgradeShareUnsafe newImpl = new MockUpgradeShareUnsafe();

//         uint64 nextVersion = ghost_share_version + 1;
//         uint256 initVal = bound(seed, 1, type(uint256).max);

//         bytes memory initData =
//             abi.encodeWithSelector(MockUpgradeShareUnsafe.initializeDynamic.selector, nextVersion, initVal);

//         bool success = _upgradeContract(address(share), address(newImpl), seed, initData);

//         if (success && _isCallerAdmin(seed)) {
//             ghost_share_upgradeCount++;
//             ghost_share_version++;
//             latestShareImplementation = address(newImpl);
//         }
//     }

//     function upgradeRebalancer(uint256 seed) public override {
//         if (ghost_rebalancer_upgradeCount > 0) return;

//         _snapshotRebalancerState();
//         MockUpgradeRebalancerUnsafe newImpl = new MockUpgradeRebalancerUnsafe();

//         uint64 nextVersion = ghost_rebalancer_version + 1;
//         uint256 initVal = bound(seed, 1, type(uint256).max);

//         bytes memory initData =
//             abi.encodeWithSelector(MockUpgradeRebalancerUnsafe.initializeDynamic.selector, nextVersion, initVal);

//         bool success = _upgradeContract(address(rebalancer), address(newImpl), seed, initData);

//         if (success && _isCallerAdmin(seed)) {
//             ghost_rebalancer_upgradeCount++;
//             ghost_rebalancer_version++;
//             latestRebalancerImplementation = address(newImpl);
//         }
//     }

//     function upgradeRegistry(uint256 seed) public override {
//         if (ghost_registry_upgradeCount > 0) return;

//         _snapshotRegistryState();
//         MockUpgradeStrategyRegistryUnsafe newImpl = new MockUpgradeStrategyRegistryUnsafe();

//         uint64 nextVersion = ghost_registry_version + 1;
//         uint256 initVal = bound(seed, 1, type(uint256).max);

//         bytes memory initData =
//             abi.encodeWithSelector(MockUpgradeStrategyRegistryUnsafe.initializeDynamic.selector, nextVersion, initVal);

//         bool success = _upgradeContract(address(registry), address(newImpl), seed, initData);

//         if (success && _isCallerAdmin(seed)) {
//             ghost_registry_upgradeCount++;
//             ghost_registry_version++;
//             latestRegistryImplementation = address(newImpl);
//         }
//     }
// }
