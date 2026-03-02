// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// import {StdInvariant} from "forge-std/StdInvariant.sol";
// import {console2} from "forge-std/Test.sol";
// import {
//     BaseTest,
//     HelperConfig,
//     ParentPeer,
//     ChildPeer,
//     Share,
//     Rebalancer,
//     StrategyRegistry,
//     Roles,
//     IERC20,
//     IYieldPeer,
//     IAccessControl,
//     CREReceiver
// } from "test/BaseTest.t.sol";
// import {RebalancerProxy} from "src/proxies/RebalancerProxy.sol";
// import {ShareProxy} from "src/proxies/ShareProxy.sol";
// import {ParentProxy} from "src/proxies/ParentProxy.sol";
// import {ChildProxy} from "src/proxies/ChildProxy.sol";
// import {StrategyRegistryProxy} from "src/proxies/StrategyRegistryProxy.sol";
// import {AaveV3Adapter} from "src/adapters/AaveV3Adapter.sol";
// import {CompoundV3Adapter} from "src/adapters/CompoundV3Adapter.sol";
// import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
// import {IAny2EVMMessageReceiver} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";
// import {IPoolAddressesProvider} from "@aave/v3-origin/src/contracts/interfaces/IPoolAddressesProvider.sol";
// import {IComet} from "src/interfaces/IComet.sol";
// import {MockCCIPRouter} from "@chainlink-local/test/mocks/MockRouter.sol";

// import {ProxyHandler} from "./ProxyHandler.t.sol";
// import {
//     MockUpgradeStorage,
//     MockUpgradeParentPeer,
//     MockUpgradeChildPeer,
//     MockUpgradeShare,
//     MockUpgradeRebalancer,
//     MockUpgradeStrategyRegistry
// } from "./mocks/MockUpgrade.sol";

// /**
//  * @title ProxyInvariant
//  * @author George Gorzhiyev | Judge Finance
//  * @notice The ProxyInvariant contract defines a suite of invariant tests to ensure the integrity and security of the proxy-based architecture in the system.
//  * It verifies that implementations are sealed, storage slots are correct, cross-chain state is consistent, singleton components maintain integrity,
//  * and critical roles persist across upgrades.
//  */

// interface Pausable {
//     function paused() external view returns (bool);
//     function emergencyPause() external;
//     function emergencyUnpause() external;
// }

// contract ProxyInvariant is StdInvariant, BaseTest {
//     /*//////////////////////////////////////////////////////////////
//                                VARIABLES
//     //////////////////////////////////////////////////////////////*/
//     // Constants
//     uint64 internal constant PARENT_SELECTOR = 1;
//     uint64 internal constant CHILD1_SELECTOR = 2;
//     uint64 internal constant CHILD2_SELECTOR = 3;
//     uint256 internal constant STRATEGY_POOL_USDC_STARTING_BALANCE = 1_000_000_000_000_000_000; // 1T USDC
//     /// @notice We are making the assumption that the gasLimit set for CCIP works correctly
//     uint256 internal constant CCIP_GAS_LIMIT = 1_000_000;
//     bytes32 internal constant AAVE_V3_PROTOCOL_ID = keccak256(abi.encodePacked("aave-v3"));
//     bytes32 internal constant COMPOUND_V3_PROTOCOL_ID = keccak256(abi.encodePacked("compound-v3"));

//     // Helper & Network Config
//     HelperConfig internal helperConfig;
//     HelperConfig.NetworkConfig internal networkConfig;

//     // Handler, Rabalancer, Parent/Child Peers, Share
//     ProxyHandler internal proxyHandler;
//     Rebalancer internal rebalancer;
//     ParentPeer internal parent;
//     ChildPeer internal child1;
//     ChildPeer internal child2;
//     Share internal share;

//     // USDC & Aave Pool
//     IERC20 internal usdc;
//     address internal aavePool;

//     // Strategy registries
//     StrategyRegistry internal strategyRegistryParent;
//     StrategyRegistry internal strategyRegistryChild1;
//     StrategyRegistry internal strategyRegistryChild2;

//     // Adapters - Parent/Children
//     AaveV3Adapter internal aaveV3Parent;
//     AaveV3Adapter internal aaveV3Child1;
//     AaveV3Adapter internal aaveV3Child2;
//     CompoundV3Adapter internal compoundV3Parent;
//     CompoundV3Adapter internal compoundV3Child1;
//     CompoundV3Adapter internal compoundV3Child2;

//     /*//////////////////////////////////////////////////////////////
//                                  SETUP
//     //////////////////////////////////////////////////////////////*/
//     function setUp() public virtual override {
//         // Deploy infra & grant roles
//         _deployInfra();
//         _grantRoles();

//         // Deal Link, set cross chain configs & workflow
//         _dealLinkToPeers(true, address(parent), address(child1), address(child2), networkConfig.tokens.link);
//         _setCrossChainPeers();
//         _setWorkflow();

//         // Deploy Proxy Handler
//         proxyHandler = new ProxyHandler(
//             parent,
//             child1,
//             child2,
//             share,
//             rebalancer,
//             strategyRegistryParent,
//             strategyRegistryChild1,
//             strategyRegistryChild2,
//             usdc,
//             aavePool,
//             networkConfig.protocols.comet
//         );

//         // Create function selectors for Handler
//         bytes4[] memory selectors = new bytes4[](5);
//         selectors[0] = ProxyHandler.deposit.selector;
//         selectors[1] = ProxyHandler.withdraw.selector;
//         selectors[2] = ProxyHandler.rebalance.selector;
//         selectors[3] = ProxyHandler.setterInteraction.selector;
//         selectors[4] = ProxyHandler.triggerRandomUpgrade.selector;

//         // Target handler and appropriate function selectors
//         targetSelector(FuzzSelector({addr: address(proxyHandler), selectors: selectors}));
//         targetContract(address(proxyHandler));

//         // Exclude contracts from direct call - must go through handler
//         excludeContract(address(parent));
//         excludeContract(address(child1));
//         excludeContract(address(child2));
//         excludeContract(address(share));
//         excludeContract(address(rebalancer));
//         excludeContract(address(strategyRegistryParent));
//         excludeContract(address(strategyRegistryChild1));
//         excludeContract(address(strategyRegistryChild2));
//     }

//     function _deployInfra() internal override {
//         // Create HelperConfig and get network config
//         helperConfig = new HelperConfig();
//         networkConfig = helperConfig.getActiveNetworkConfig();

//         // Store usdc, share and aave pool address
//         usdc = IERC20(networkConfig.tokens.usdc);
//         share = Share(networkConfig.tokens.share);
//         aavePool = IPoolAddressesProvider(networkConfig.protocols.aavePoolAddressesProvider).getPool();

//         // Create Registry Impl (passed to deploy helpers)
//         StrategyRegistry registryImpl = new StrategyRegistry();
//         bytes memory registryInit = abi.encodeWithSelector(StrategyRegistry.initialize.selector);

//         // Deploy Rebalancer, Parent/Children & Registries
//         _deployRebalancer();
//         _deployParent(address(registryImpl), registryInit);
//         _deployChild1(address(registryImpl), registryInit);
//         _deployChild2(address(registryImpl), registryInit);

//         // Grant Share Rols to Proxies
//         _changePrank(share.owner());
//         share.grantMintAndBurnRoles(address(parent));
//         share.grantMintAndBurnRoles(address(child1));
//         share.grantMintAndBurnRoles(address(child2));
//         _stopPrank();

//         // Store admin
//         owner = address(this);

//         // Seed Pools
//         deal(address(usdc), aavePool, STRATEGY_POOL_USDC_STARTING_BALANCE);
//         deal(address(usdc), networkConfig.protocols.comet, STRATEGY_POOL_USDC_STARTING_BALANCE);
//     }

//     /// @dev _deployInfra:: Helper to deploy Rebalancer
//     function _deployRebalancer() private {
//         // Deploy Rebalancer Impl and create init data
//         Rebalancer rebalancerImpl = new Rebalancer();
//         bytes memory rebalancerInit = abi.encodeWithSelector(Rebalancer.initialize.selector);

//         // Deploy Rebalancer Proxy and cast to Rebalancer type
//         RebalancerProxy rebalancerProxy = new RebalancerProxy(address(rebalancerImpl), rebalancerInit);
//         rebalancer = Rebalancer(address(rebalancerProxy));
//     }

//     /// @dev _deployInfra:: Helper to deploy ParentPeer
//     /// @param registryImpl The strategy registry impl address
//     /// @param registryInit The strategy registry init data
//     function _deployParent(address registryImpl, bytes memory registryInit) private {
//         // Deploy Parent Impl and create init data
//         ParentPeer parentImpl = new ParentPeer(
//             networkConfig.ccip.ccipRouter, networkConfig.tokens.link, PARENT_SELECTOR, address(usdc), address(share)
//         );
//         bytes memory parentInit = abi.encodeWithSelector(ParentPeer.initialize.selector);

//         // Deploy Parent Proxy and cast to ParentPeer type
//         ParentProxy parentProxy = new ParentProxy(address(parentImpl), parentInit);
//         parent = ParentPeer(address(parentProxy));

//         // Connect Rebalancer & Parent
//         parent.grantRole(Roles.CONFIG_ADMIN_ROLE, address(this));
//         parent.setRebalancer(address(rebalancer));
//         rebalancer.setParentPeer(address(parent));

//         // Deploy Parent Registry Proxy and cast to StrategyRegistry type
//         StrategyRegistryProxy strategyRegistryProxy = new StrategyRegistryProxy(registryImpl, registryInit);
//         strategyRegistryParent = StrategyRegistry(address(strategyRegistryProxy));

//         // Deploy adapters
//         aaveV3Parent = new AaveV3Adapter(address(parent), networkConfig.protocols.aavePoolAddressesProvider);
//         compoundV3Parent = new CompoundV3Adapter(address(parent), networkConfig.protocols.comet);

//         // Configure Parent StrategyRegistry with adapters
//         strategyRegistryParent.setStrategyAdapter(AAVE_V3_PROTOCOL_ID, address(aaveV3Parent));
//         strategyRegistryParent.setStrategyAdapter(COMPOUND_V3_PROTOCOL_ID, address(compoundV3Parent));

//         // Link Registry & set Initial Strategy
//         rebalancer.setStrategyRegistry(address(strategyRegistryParent));
//         parent.setStrategyRegistry(address(strategyRegistryParent));
//         parent.setInitialActiveStrategy(keccak256(abi.encodePacked("aave-v3")));
//         parent.revokeRole(Roles.CONFIG_ADMIN_ROLE, address(this));
//     }

//     /// @dev _deployInfra:: Helper to deploy ChildPeer 1
//     /// @param registryImpl The strategy registry impl address
//     /// @param registryInit The strategy registry init data
//     function _deployChild1(address registryImpl, bytes memory registryInit) private {
//         // Deploy Child Impl and create init data
//         ChildPeer child1Impl = new ChildPeer(
//             networkConfig.ccip.ccipRouter,
//             networkConfig.tokens.link,
//             CHILD1_SELECTOR,
//             networkConfig.tokens.usdc,
//             networkConfig.tokens.share,
//             PARENT_SELECTOR
//         );
//         bytes memory child1Init = abi.encodeWithSelector(ChildPeer.initialize.selector);

//         // Deploy Child Proxy and cast to ChildPeer type
//         ChildProxy childProxy = new ChildProxy(address(child1Impl), child1Init);
//         child1 = ChildPeer(address(childProxy));

//         // Deploy Child 1 Registry Proxy and cast to StrategyRegistry type
//         StrategyRegistryProxy strategyRegistryProxy = new StrategyRegistryProxy(registryImpl, registryInit);
//         strategyRegistryChild1 = StrategyRegistry(address(strategyRegistryProxy));

//         // Deploy Adapters
//         aaveV3Child1 = new AaveV3Adapter(address(child1), networkConfig.protocols.aavePoolAddressesProvider);
//         compoundV3Child1 = new CompoundV3Adapter(address(child1), networkConfig.protocols.comet);

//         // Configure Child 1
//         child1.grantRole(Roles.CONFIG_ADMIN_ROLE, address(this));
//         child1.setStrategyRegistry(address(strategyRegistryChild1));
//         child1.revokeRole(Roles.CONFIG_ADMIN_ROLE, address(this));

//         // Configure Child 1 StrategyRegistry with adapters
//         strategyRegistryChild1.setStrategyAdapter(AAVE_V3_PROTOCOL_ID, address(aaveV3Child1));
//         strategyRegistryChild1.setStrategyAdapter(COMPOUND_V3_PROTOCOL_ID, address(compoundV3Child1));
//     }

//     /// @dev _deployInfra:: Helper to deploy ChildPeer 2
//     /// @param registryImpl The strategy registry impl address
//     /// @param registryInit The strategy registry init data
//     function _deployChild2(address registryImpl, bytes memory registryInit) private {
//         // Deploy Child Impl and create init data
//         ChildPeer child2Impl = new ChildPeer(
//             networkConfig.ccip.ccipRouter,
//             networkConfig.tokens.link,
//             CHILD2_SELECTOR,
//             networkConfig.tokens.usdc,
//             networkConfig.tokens.share,
//             PARENT_SELECTOR
//         );
//         bytes memory child2Init = abi.encodeWithSelector(ChildPeer.initialize.selector);

//         // Deploy Child Proxy and cast to ChildPeer type
//         ChildProxy childProxy = new ChildProxy(address(child2Impl), child2Init);
//         child2 = ChildPeer(address(childProxy));

//         // Deploy Child 2 Registry Proxy and cast to StrategyRegistry type
//         StrategyRegistryProxy strategyRegistryProxy = new StrategyRegistryProxy(registryImpl, registryInit);
//         strategyRegistryChild2 = StrategyRegistry(address(strategyRegistryProxy));

//         // Deploy Adapters
//         aaveV3Child2 = new AaveV3Adapter(address(child2), networkConfig.protocols.aavePoolAddressesProvider);
//         compoundV3Child2 = new CompoundV3Adapter(address(child2), networkConfig.protocols.comet);

//         // Configure Child 2
//         child2.grantRole(Roles.CONFIG_ADMIN_ROLE, address(this));
//         child2.setStrategyRegistry(address(strategyRegistryChild2));
//         child2.revokeRole(Roles.CONFIG_ADMIN_ROLE, address(this));

//         // Configure Child 2 StrategyRegistry with adapters
//         strategyRegistryChild2.setStrategyAdapter(AAVE_V3_PROTOCOL_ID, address(aaveV3Child2));
//         strategyRegistryChild2.setStrategyAdapter(COMPOUND_V3_PROTOCOL_ID, address(compoundV3Child2));
//     }

//     /// @dev Grants custom roles on all chains (simulated locally)
//     function _grantRoles() internal override {
//         _grantRolesToPeer(parent, parent.owner());
//         _grantRolesToPeer(child1, child1.owner());
//         _grantRolesToPeer(child2, child2.owner());
//         _stopPrank();
//     }

//     /// @dev _grantRoles:: Helper to grant roles to a specific peer
//     /// @param peer The peer to grant roles for
//     /// @param peerOwner The owner of the peer (passed explicitly as IYieldPeer might not expose owner())
//     function _grantRolesToPeer(IYieldPeer peer, address peerOwner) private {
//         _changePrank(peerOwner);

//         // Cast peer to IAccessControl to access role functions
//         IAccessControl peerAccessControl = IAccessControl(address(peer));

//         peerAccessControl.grantRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser);
//         peerAccessControl.grantRole(Roles.EMERGENCY_UNPAUSER_ROLE, emergencyUnpauser);
//         peerAccessControl.grantRole(Roles.CONFIG_ADMIN_ROLE, configAdmin);
//         peerAccessControl.grantRole(Roles.CROSS_CHAIN_ADMIN_ROLE, crossChainAdmin);
//         peerAccessControl.grantRole(Roles.FEE_WITHDRAWER_ROLE, feeWithdrawer);
//         peerAccessControl.grantRole(Roles.FEE_RATE_SETTER_ROLE, feeRateSetter);

//         // Assertions
//         assertTrue(peerAccessControl.hasRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser));
//         assertTrue(peerAccessControl.hasRole(Roles.EMERGENCY_UNPAUSER_ROLE, emergencyUnpauser));
//         assertTrue(peerAccessControl.hasRole(Roles.CONFIG_ADMIN_ROLE, configAdmin));
//         assertTrue(peerAccessControl.hasRole(Roles.CROSS_CHAIN_ADMIN_ROLE, crossChainAdmin));
//         assertTrue(peerAccessControl.hasRole(Roles.FEE_WITHDRAWER_ROLE, feeWithdrawer));
//         assertTrue(peerAccessControl.hasRole(Roles.FEE_RATE_SETTER_ROLE, feeRateSetter));
//     }

//     function _setCrossChainPeers() internal override {
//         /// @dev temp cross chain admin roles granted to set cross chain configs
//         parent.grantRole(Roles.CROSS_CHAIN_ADMIN_ROLE, parent.owner());
//         child1.grantRole(Roles.CROSS_CHAIN_ADMIN_ROLE, child1.owner());
//         child2.grantRole(Roles.CROSS_CHAIN_ADMIN_ROLE, child2.owner());

//         // Set CCIP Gas Limit
//         parent.setCCIPGasLimit(CCIP_GAS_LIMIT);
//         child1.setCCIPGasLimit(CCIP_GAS_LIMIT);
//         child2.setCCIPGasLimit(CCIP_GAS_LIMIT);

//         // Parent - Set allowed chains and peers
//         parent.setAllowedChain(PARENT_SELECTOR, true);
//         parent.setAllowedChain(CHILD1_SELECTOR, true);
//         parent.setAllowedChain(CHILD2_SELECTOR, true);
//         parent.setAllowedPeer(PARENT_SELECTOR, address(parent));
//         parent.setAllowedPeer(CHILD1_SELECTOR, address(child1));
//         parent.setAllowedPeer(CHILD2_SELECTOR, address(child2));

//         // Child 1 - Set allowed chains and peers
//         child1.setAllowedChain(PARENT_SELECTOR, true);
//         child1.setAllowedChain(CHILD1_SELECTOR, true);
//         child1.setAllowedChain(CHILD2_SELECTOR, true);
//         child1.setAllowedPeer(PARENT_SELECTOR, address(parent));
//         child1.setAllowedPeer(CHILD1_SELECTOR, address(child1));
//         child1.setAllowedPeer(CHILD2_SELECTOR, address(child2));

//         // Child 2 - Set allowed chains and peers
//         child2.setAllowedChain(PARENT_SELECTOR, true);
//         child2.setAllowedChain(CHILD1_SELECTOR, true);
//         child2.setAllowedChain(CHILD2_SELECTOR, true);
//         child2.setAllowedPeer(PARENT_SELECTOR, address(parent));
//         child2.setAllowedPeer(CHILD1_SELECTOR, address(child1));
//         child2.setAllowedPeer(CHILD2_SELECTOR, address(child2));

//         /// @dev Revoke temp cross chain admin role
//         parent.revokeRole(Roles.CROSS_CHAIN_ADMIN_ROLE, parent.owner());
//         child1.revokeRole(Roles.CROSS_CHAIN_ADMIN_ROLE, child1.owner());
//         child2.revokeRole(Roles.CROSS_CHAIN_ADMIN_ROLE, child2.owner());

//         // Set MockCCIPRouter Config
//         MockCCIPRouter(networkConfig.ccip.ccipRouter).setPeerToChainSelector(address(parent), PARENT_SELECTOR);
//         MockCCIPRouter(networkConfig.ccip.ccipRouter).setPeerToChainSelector(address(child1), CHILD1_SELECTOR);
//         MockCCIPRouter(networkConfig.ccip.ccipRouter).setPeerToChainSelector(address(child2), CHILD2_SELECTOR);
//     }

//     function _setWorkflow() internal {
//         _changePrank(rebalancer.owner());
//         rebalancer.setWorkflow(workflowId, workflowOwner, workflowName);
//         _stopPrank();
//     }

//     /*//////////////////////////////////////////////////////////////
//                                INVARIANTS
//     //////////////////////////////////////////////////////////////*/

//     uint64[] internal chains = [PARENT_SELECTOR, CHILD1_SELECTOR, CHILD2_SELECTOR];

//     // --- Storage Slots ---
//     bytes32 internal constant OZ_INITIALIZABLE_SLOT =
//         0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

//     // --- 1. Global Safety & Implementation Checks ---

//     function invariant_proxy_implementations_are_sealed_and_secure() public view {
//         (

//             /* bool paused */,
//             /* uint256 feeRate */,
//             /* uint256 ccipGasLimit */,
//             bool withdrewWhilePaused,
//             bool depositedWhilePaused,
//             bool depositedIntoImpl,
//             bool withdrawFromImpl,
//             bool unauthorizedUpgradeSuccess,
//             bool implementationWasUnlocked
//         ) = proxyHandler.globalGhost();

//         assertFalse(implementationWasUnlocked, "[Global] Impl deployed unsealed");
//         assertFalse(unauthorizedUpgradeSuccess, "[Global] Unauthorized upgrade succeeded");
//         assertFalse(withdrewWhilePaused, "[Global] Withdraw bypassed pause");
//         assertFalse(depositedWhilePaused, "[Global] Deposit bypassed pause");
//         assertFalse(depositedIntoImpl, "[Global] Direct impl deposit succeeded");
//         assertFalse(withdrawFromImpl, "[Global] Direct impl withdraw succeeded");
//     }

//     function invariant_proxy_implementation_slots_are_valid() public view {
//         for (uint256 i = 0; i < chains.length; i++) {
//             uint64 chain = chains[i];

//             // 1. Peer Slot Check
//             (,,, address peerImpl,,,,,) = proxyHandler.peerGhosts(chain);
//             if (peerImpl != address(0)) {
//                 assertEq(_getProxyImpl(address(proxyHandler.peers(chain))), peerImpl, "[Peer] Impl slot corrupted");

//                 uint64 initVersion = uint64(uint256(vm.load(peerImpl, OZ_INITIALIZABLE_SLOT)));
//                 assertEq(initVersion, type(uint64).max, "[Peer] Impl contract not sealed");
//             }

//             // 2. Registry Slot Check
//             (,,, address regImpl,,) = proxyHandler.registryGhosts(chain);
//             if (regImpl != address(0)) {
//                 assertEq(
//                     _getProxyImpl(address(proxyHandler.registries(chain))), regImpl, "[Registry] Impl slot corrupted"
//                 );
//             }
//         }

//         // 3. Singleton Slot Checks
//         (,,, address shareImpl,,,,,,) = proxyHandler.shareGhost();
//         if (shareImpl != address(0)) {
//             assertEq(_getProxyImpl(address(share)), shareImpl, "[Share] Impl slot corrupted");
//         }

//         (,,, address rebImpl,,,,,) = proxyHandler.rebalancerGhost();
//         if (rebImpl != address(0)) {
//             assertEq(_getProxyImpl(address(rebalancer)), rebImpl, "[Rebalancer] Impl slot corrupted");
//         }
//     }

//     // --- 2. Dynamic Cross-Chain State Integrity ---
//     function invariant_proxy_distributed_peer_integrity() public view {
//         // --- 1. Hub (Parent) State Verification ---
//         (
//             uint256 hubShares,
//             address expectedRebalancer,
//             bool expectedInitialSet,
//             uint64 expectedStrategyChain,
//             bytes32 expectedStrategyProtocol
//         ) = proxyHandler.parentGhost();

//         // Accounting & Singleton References
//         assertEq(parent.getTotalShares(), hubShares, "[Hub] Total shares accounting drifted");
//         assertEq(parent.getTotalShares(), share.totalSupply(), "[Hub] Accounting vs Token supply mismatch");
//         assertEq(parent.getRebalancer(), expectedRebalancer, "[Hub] Rebalancer reference corrupted");

//         // Strategy Struct Integrity
//         IYieldPeer.Strategy memory liveStrategy = parent.getStrategy();
//         assertEq(liveStrategy.chainSelector, expectedStrategyChain, "[Hub] Strategy chain selector corrupted");
//         assertEq(liveStrategy.protocolId, expectedStrategyProtocol, "[Hub] Strategy protocol ID corrupted");

//         // Low-level Initialization Flag Integrity
//         bytes32 initialSetSlot =
//             bytes32(uint256(0x603686382b15940b5fa7ef449162bde228a5948ce3b6bdf08bd833ec6ae79500) + 2);
//         bool liveInitialSet = vm.load(address(parent), initialSetSlot) != bytes32(0);
//         assertEq(liveInitialSet, expectedInitialSet, "[Hub] Initial strategy flag corrupted");

//         // --- 2. Universal Peer Verification ---
//         for (uint256 i = 0; i < chains.length; i++) {
//             uint64 chain = chains[i];
//             IYieldPeer livePeer = proxyHandler.peers(chain);

//             // Universal live state constraints
//             uint256 expectedFeeRate;
//             (, expectedFeeRate,,,,,,,) = proxyHandler.globalGhost();
//             assertTrue(livePeer.getFeeRate() == expectedFeeRate, "[Peer] Fee rate limit breached");

//             // Expected Pause State Sync (using the global state)
//             (bool expectedPauseState,,,,,,,,) = proxyHandler.globalGhost();
//             assertEq(Pausable(address(livePeer)).paused(), expectedPauseState, "[Peer] Pause state desynced");

//             // Offload the heavy memory destructuring to a dedicated execution context
//             _verifyPeerUpgradeState(chain, livePeer);
//         }
//     }

//     function _verifyPeerUpgradeState(uint64 chain, IYieldPeer livePeer) internal view {
//         (
//             uint64 version,
//             uint256 upgradeCount,
//             uint256 newVal,
//             /* latestImpl */,
//             /* paused     */,
//             uint256 feeRate,
//             uint256 ccipGasLimit,
//             address activeAdapter,
//             address strategyReg
//         ) = proxyHandler.peerGhosts(chain);

//         if (upgradeCount > 0) {
//             assertEq(livePeer.getFeeRate(), feeRate, "[Peer] FeeRate corrupted");
//             assertEq(livePeer.getCCIPGasLimit(), ccipGasLimit, "[Peer] CCIP Gas Limit corrupted");
//             assertEq(livePeer.getActiveStrategyAdapter(), activeAdapter, "[Peer] Active Adapter corrupted");
//             assertEq(livePeer.getStrategyRegistry(), strategyReg, "[Peer] Strategy Registry corrupted");

//             // Verify CCIP Topography Maps
//             for (uint256 j = 0; j < chains.length; j++) {
//                 uint64 target = chains[j];
//                 bool expectedChain = proxyHandler.getGhostAllowedChain(chain, target);
//                 address expectedPeer = proxyHandler.getGhostAllowedPeer(chain, target);

//                 assertEq(livePeer.getAllowedChain(target), expectedChain, "[Peer] AllowedChain topography corrupted");
//                 assertEq(livePeer.getAllowedPeer(target), expectedPeer, "[Peer] AllowedPeer topography corrupted");
//             }

//             try MockUpgradeStorage(address(livePeer)).getNewVal() returns (uint256 val) {
//                 assertEq(val, newVal, "[Peer] Mock dynamic data lost");
//                 assertEq(
//                     MockUpgradeStorage(address(livePeer)).version(), version, "[Peer] Reinitializer version bump failed"
//                 );
//             } catch {
//                 assertTrue(false, "[Peer] Mock proxy interface failed");
//             }
//         }
//     }

//     function invariant_proxy_distributed_registry_integrity() public view {
//         for (uint256 i = 0; i < chains.length; i++) {
//             uint64 chain = chains[i];
//             StrategyRegistry liveReg = proxyHandler.registries(chain);

//             (
//                 uint64 version,
//                 uint256 upgradeCount,
//                 uint256 newVal,
//                 /* latestImpl */,
//                 address aaveAdapter,
//                 address compAdapter
//             ) = proxyHandler.registryGhosts(chain);

//             if (upgradeCount > 0) {
//                 assertEq(liveReg.getStrategyAdapter(AAVE_V3_PROTOCOL_ID), aaveAdapter, "[Registry] Aave adapter lost");
//                 assertEq(
//                     liveReg.getStrategyAdapter(COMPOUND_V3_PROTOCOL_ID), compAdapter, "[Registry] Compound adapter lost"
//                 );

//                 try MockUpgradeStorage(address(liveReg)).getNewVal() returns (uint256 val) {
//                     assertEq(val, newVal, "[Registry] Mock dynamic data lost");
//                     assertEq(
//                         MockUpgradeStorage(address(liveReg)).version(),
//                         version,
//                         "[Registry] Reinitializer version bump failed"
//                     );
//                 } catch {
//                     assertTrue(false, "[Registry] Mock proxy interface failed");
//                 }
//             }
//         }
//     }

//     // --- 3. Singleton Components Integrity ---

//     function invariant_proxy_share_token_integrity() public view {
//         (
//             uint64 version,
//             uint256 upgradeCount,
//             uint256 newVal,
//             /* latestImpl */,
//             uint256 totalSupply,
//             uint256 userBalance,
//             address ccipAdmin,
//             string memory expectedName,
//             string memory expectedSymbol,
//             uint8 expectedDecimals
//         ) = proxyHandler.shareGhost();

//         if (upgradeCount > 0) {
//             assertEq(share.totalSupply(), totalSupply, "[Share] Total supply corrupted");
//             assertEq(share.name(), expectedName, "[Share] Name corrupted");
//             assertEq(share.symbol(), expectedSymbol, "[Share] Symbol corrupted");
//             assertEq(share.decimals(), expectedDecimals, "[Share] Decimals corrupted");
//             assertEq(address(share.getCCIPAdmin()), ccipAdmin, "[Share] CCIP Admin lost");

//             address user = proxyHandler.superUser();
//             assertEq(share.balanceOf(user), userBalance, "[Share] User balance corrupted");

//             for (uint256 i = 0; i < chains.length; i++) {
//                 address peer = address(proxyHandler.peers(chains[i]));
//                 uint256 allowance = proxyHandler.getGhostAllowance(peer);
//                 assertEq(share.allowance(user, peer), allowance, "[Share] Allowance corrupted");
//             }

//             try MockUpgradeStorage(address(share)).getNewVal() returns (uint256 val) {
//                 assertEq(val, newVal, "[Share] Mock dynamic data lost");
//                 assertEq(
//                     MockUpgradeStorage(address(share)).version(), version, "[Share] Reinitializer version bump failed"
//                 );
//             } catch {
//                 assertTrue(false, "[Share] Mock proxy interface failed");
//             }
//         }
//     }

//     function invariant_proxy_rebalancer_integrity() public view {
//         (
//             uint64 version,
//             uint256 upgradeCount,
//             uint256 newVal,
//             /* latestImpl */,
//             address parentPeer,
//             address strategyRegistry,
//             address forwarder,
//             address workflowOwner,
//             bytes10 workflowName
//         ) = proxyHandler.rebalancerGhost();

//         if (upgradeCount > 0) {
//             assertEq(rebalancer.getKeystoneForwarder(), forwarder, "[Rebalancer] Forwarder corrupted");
//             assertEq(rebalancer.getParentPeer(), parentPeer, "[Rebalancer] Parent ref corrupted");
//             assertEq(rebalancer.getStrategyRegistry(), strategyRegistry, "[Rebalancer] Registry ref corrupted");

//             CREReceiver.Workflow memory currentWorkflow = rebalancer.getWorkflow(bytes32("rebalanceWorkflowId"));
//             assertEq(currentWorkflow.owner, workflowOwner, "[Rebalancer] CRE Workflow owner corrupted");
//             assertEq(currentWorkflow.name, workflowName, "[Rebalancer] CRE Workflow name corrupted");

//             try MockUpgradeStorage(address(rebalancer)).getNewVal() returns (uint256 val) {
//                 assertEq(val, newVal, "[Rebalancer] Mock dynamic data lost");
//                 assertEq(
//                     MockUpgradeStorage(address(rebalancer)).version(),
//                     version,
//                     "[Rebalancer] Reinitializer version bump failed"
//                 );
//             } catch {
//                 assertTrue(false, "[Rebalancer] Mock proxy interface failed");
//             }
//         }
//     }

//     // --- 4. Role Persistence ---

//     function invariant_proxy_role_persistence() public view {
//         for (uint256 i = 0; i < chains.length; i++) {
//             IAccessControl ac = IAccessControl(address(proxyHandler.peers(chains[i])));

//             assertTrue(ac.hasRole(0x00, address(this)), "[Role] DEFAULT_ADMIN lost");
//             assertTrue(ac.hasRole(Roles.EMERGENCY_PAUSER_ROLE, emergencyPauser), "[Role] EMERGENCY_PAUSER lost");
//             assertTrue(ac.hasRole(Roles.EMERGENCY_UNPAUSER_ROLE, emergencyUnpauser), "[Role] EMERGENCY_UNPAUSER lost");
//             assertTrue(ac.hasRole(Roles.CONFIG_ADMIN_ROLE, configAdmin), "[Role] CONFIG_ADMIN lost");
//             assertTrue(ac.hasRole(Roles.CROSS_CHAIN_ADMIN_ROLE, crossChainAdmin), "[Role] CROSS_CHAIN_ADMIN lost");
//             assertTrue(ac.hasRole(Roles.FEE_WITHDRAWER_ROLE, feeWithdrawer), "[Role] FEE_WITHDRAWER lost");
//             assertTrue(ac.hasRole(Roles.FEE_RATE_SETTER_ROLE, feeRateSetter), "[Role] FEE_RATE_SETTER lost");
//             assertTrue(ac.hasRole(Roles.UPGRADER_ROLE, address(this)), "[Role] UPGRADER lost");
//         }
//     }

//     /*//////////////////////////////////////////////////////////////
//                              UTILITY HELPERS
//     //////////////////////////////////////////////////////////////*/

//     /// @dev Hides the ugly assembly bit-casting required to read the EIP-1967 slot
//     function _getProxyImpl(address proxy) internal view returns (address) {
//         return address(uint160(uint256(vm.load(proxy, IMPLEMENTATION_SLOT))));
//     }
// }
