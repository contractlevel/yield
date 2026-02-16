// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// @review Currently not used, meant to test collision detection

// import {ProxyInvariant} from "./../ProxyInvariant.t.sol";
// import {ProxyHandlerFailure} from "./ProxyHandlerFailure.t.sol";
// import {Roles} from "../../../BaseTest.t.sol";

// /// @title ProxyInvariantCollisionTest
// /// @notice "Must Fail" Suite: This test suite uses Unsafe mocks that intentionally corrupt storage.
// /// @notice PASSING this suite means the Invariants SUCCESSFULLY DETECTED the corruption.
// contract ProxyInvariantCollisionTest is ProxyInvariant {
//     function setUp() public override {
//         _deployInfra();

//         address owner = parent.owner();
//         vm.startPrank(owner);
//         parent.grantRole(Roles.UPGRADER_ROLE, owner);
//         parent.grantRole(Roles.FEE_RATE_SETTER_ROLE, owner);
//         parent.grantRole(Roles.EMERGENCY_PAUSER_ROLE, owner);
//         parent.grantRole(Roles.EMERGENCY_UNPAUSER_ROLE, owner);
//         child1.grantRole(Roles.UPGRADER_ROLE, owner);
//         child2.grantRole(Roles.UPGRADER_ROLE, owner);
//         registry.acceptOwnership();
//         vm.stopPrank();

//         // Initialize Failure Handler
//         proxyHandler = new ProxyHandlerFailure(
//             address(parent),
//             address(child1),
//             address(child2),
//             address(share),
//             address(rebalancer),
//             address(registry),
//             address(usdc),
//             owner
//         );

//         targetContract(address(proxyHandler));

//         excludeContract(address(parent));
//         excludeContract(address(child1));
//         excludeContract(address(child2));
//         excludeContract(address(share));
//         excludeContract(address(rebalancer));
//         excludeContract(address(registry));
//     }

//     // --- DISABLE STANDARD INVARIANTS ---
//     // These would naturally fail because we ARE corrupting storage.
//     // We disable them here so the suite only checks if we DETECTED the failure via the collision invariants below.

//     function invariant_proxy_upgrade_persistence() public view override {}
//     function invariant_proxy_parent_integrity_post_upgrade() public view override {}
//     function invariant_proxy_child_integrity_post_upgrade() public view override {}
//     function invariant_proxy_share_integrity_post_upgrade() public view override {}
//     function invariant_proxy_rebalancer_integrity_post_upgrade() public view override {}
//     function invariant_proxy_registry_integrity_post_upgrade() public view override {}
//     function invariant_proxy_implementation_slot() public view override {}

//     // Disable Cutting Edge Invariants (Focus purely on storage collision)
//     function invariant_proxy_interface_adherence() public view override {}
//     function invariant_proxy_admin_access_persistence() public view override {}
//     function invariant_proxy_distributed_state_integrity() public view override {}
//     function invariant_proxy_code_immutables_integrity() public view override {}
//     function invariant_proxy_governance_hierarchy_integrity() public view override {}
//     function invariant_proxy_fee_configuration_integrity() public view override {}

//     // --- COLLISION DETECTION INVARIANTS ---
//     // These are the ONLY tests that should run in this file.

//     function invariant_proxy_collision_detect_parent_corruption() public view {
//         if (proxyHandler.ghost_parent_upgradeCount() > 0) {
//             // Check: Total Shares (contract) vs Ghost (snapshot)
//             bool corruptionDetected = (parent.getTotalShares() != proxyHandler.ghost_parent_totalShares());
//             assertTrue(corruptionDetected, "FAILED TO DETECT PARENT STORAGE CORRUPTION");
//         }
//     }

//     function invariant_proxy_collision_detect_child_corruption() public view {
//         if (proxyHandler.ghost_child1_upgradeCount() > 0) {
//             // Unsafe mock corrupts Gas Limit.
//             // The handler ensures initVal != 500,000, so this MUST be true.
//             bool corruptionDetected = (child1.getCCIPGasLimit() != 500_000);
//             assertTrue(corruptionDetected, "FAILED TO DETECT CHILD STORAGE CORRUPTION");
//         }
//     }

//     function invariant_proxy_collision_ensure_corruption_is_observable() public view {
//         bool anyCorruption = false;

//         if (proxyHandler.ghost_parent_upgradeCount() > 0) {
//             if (parent.getTotalShares() != proxyHandler.ghost_parent_totalShares()) anyCorruption = true;
//         }

//         if (proxyHandler.ghost_share_upgradeCount() > 0) {
//             if (share.totalSupply() != proxyHandler.ghost_share_totalSupply()) anyCorruption = true;
//         }

//         if (proxyHandler.ghost_rebalancer_upgradeCount() > 0) {
//             if (rebalancer.getParentPeer() != proxyHandler.ghost_rebalancer_parentPeer()) anyCorruption = true;
//         }

//         if (proxyHandler.ghost_registry_upgradeCount() > 0) {
//             bytes32 aaveId = keccak256(abi.encodePacked("aave-v3"));
//             if (registry.getStrategyAdapter(aaveId) != proxyHandler.ghost_registry_adapter()) anyCorruption = true;
//         }

//         if (proxyHandler.ghost_child1_upgradeCount() > 0) {
//             if (child1.getCCIPGasLimit() != 500_000) anyCorruption = true;
//         }

//         // If any upgrade happened, we MUST see corruption.
//         if (
//             proxyHandler.ghost_parent_upgradeCount() > 0 || proxyHandler.ghost_share_upgradeCount() > 0
//                 || proxyHandler.ghost_rebalancer_upgradeCount() > 0 || proxyHandler.ghost_registry_upgradeCount() > 0
//                 || proxyHandler.ghost_child1_upgradeCount() > 0
//         ) {
//             assertTrue(anyCorruption, "SUITE FAILURE: Unsafe Mocks were used but no state mismatch was found!");
//         }
//     }
// }
