using MockUsdc as usdc;
using ParentPeer as parent;
using StrategyRegistry as strategyRegistry;

/// Verification of Rebalancer
/// @author @contractlevel / George Gorzhiyev | Judge Finance
/// @notice Rebalancer handles the Chainlink CRE report and triggers set strategy on ParentPeer

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // Rebalancer methods
    function getParentPeer() external returns (address) envfree;
    function getCurrentStrategy() external returns (IYieldPeer.Strategy memory) envfree;
    function owner() external returns (address) envfree;

    // External methods
    function usdc.balanceOf(address) external returns (uint256) envfree;
    function parent.getAllowedChain(uint64 chainSelector) external returns (bool) envfree;
    function parent.getStrategy() external returns (IYieldPeer.Strategy memory) envfree;
    function strategyRegistry.getStrategyAdapter(bytes32 protocolId) external returns (address) envfree;
    function parent.getSupportedProtocol(bytes32 protocolId) external returns (bool) envfree;
    function parent.getTotalValue() external returns (uint256) envfree;

    // Summary methods
    function _._decodeMetadata(bytes memory) internal => NONDET;
    function _.balanceOf(address) external => DISPATCHER(true);
    function _.getPool() external => DISPATCHER(true);
    function _.getReserveData(address) external => DISPATCHER(true);
    function _.getFee(uint64, Client.EVM2AnyMessage) external => DISPATCHER(true);
    function _.approve(address, uint256) external => DISPATCHER(true);
    function _.ccipSend(uint64, Client.EVM2AnyMessage) external => DISPATCHER(true);
    function _.withdraw(address, uint256) external => DISPATCHER(true);
    function _.withdraw(address, uint256, address) external => DISPATCHER(true);
    function _.transfer(address, uint256) external => DISPATCHER(true);
    function _.deposit(address, uint256) external => DISPATCHER(true);
    function _.getTotalValue(address) external => DISPATCHER(true);
    function _.getStrategyAdapter(bytes32 protocolId) external => DISPATCHER(true);

    // Harness helper methods
    function bytes32ToAddress(bytes32) external returns (address) envfree;
    function bytes32ToUint64(bytes32) external returns (uint64) envfree;
    function getParentChainSelector() external returns (uint64) envfree;
    function bytes32ToUint8(bytes32) external returns (uint8) envfree;
    function bytes32ToUint256(bytes32) external returns (uint256) envfree;
    function createWorkflowReport(uint64, bytes32) external returns (bytes) envfree;
    function createWorkflowMetadata(bytes32, bytes10, address) external returns (bytes) envfree;
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
// --- Rebalancer events --- //
definition ReportDecodedEvent() returns bytes32 =
// keccak256(abi.encodePacked("ReportDecoded(uint64,bytes32)"))
to_bytes32(0xdf6bb49f8dc3a37fe44a00ed2e2f5ce7ad2fa79d8a5135cc2fdd3506530ad63f);

definition ParentPeerSetEvent() returns bytes32 =
// keccak256(abi.encodePacked("ParentPeerSet(address)"))
to_bytes32(0x9bd1968cee8e2e99d039a6a765fa06cfa0ddb152eacae28608f4b14390157658);

// --- Parent events (some - for testing) --- //
definition CurrentStrategyOptimalEvent() returns bytes32 =
// keccak256(abi.encodePacked("CurrentStrategyOptimal(uint64,bytes32)"))
to_bytes32(0x8a2bbc9188a750bed30596d0ed7ae5d7b521e02729739c43b6e7106bdfb7e89d);

definition StrategyUpdatedEvent() returns bytes32 =
// keccak256(abi.encodePacked("StrategyUpdated(uint64,bytes32,uint64)"))
to_bytes32(0x60d0790094d9774dbd1ef0d8d0a670010be9595ac41c3215452ac9430a078aa6);

definition DepositToStrategyEvent() returns bytes32 =
// keccak256(abi.encodePacked("DepositToStrategy(address,uint256)"))
to_bytes32(0x8125d05f0839eec6c1f6b1674833e01f11ab362bd9c60eb2e3b274fa3b47e4f4);

definition CCIPMessageSentEvent() returns bytes32 =
// keccak256(abi.encodePacked("CCIPMessageSent(bytes32,uint8,uint256)"))
to_bytes32(0xf58bb6f6ec82990ff728621d18279c43cae3bc9777d052ed0d2316669e58cee6);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
// --- ReportDecoded --- //
/// @notice track amount of ReportDecoded event is emitted
ghost mathint ghost_reportDecoded_eventCount {
    init_state axiom ghost_reportDecoded_eventCount == 0;
}

/// @notice EmittedValue: track the chain selector emitted by ReportDecoded event
ghost uint64 ghost_reportDecoded_emittedChainSelector {
    init_state axiom ghost_reportDecoded_emittedChainSelector == 0;
}

/// @notice EmittedValue: track the protocol id emitted by ReportDecoded event
ghost bytes32 ghost_reportDecoded_emittedProtocolId {
    init_state axiom ghost_reportDecoded_emittedProtocolId == to_bytes32(0);
}

// --- ParentPeerSet --- //
/// @notice EventCount: track amount ParentPeerSet event is emitted
ghost mathint ghost_parentPeerSet_eventCount {
    init_state axiom ghost_parentPeerSet_eventCount == 0;
}

/// @notice EmittedValue: track address emitted in ParentPeerSet event
ghost address ghost_parentPeerSet_emittedAddress {
    init_state axiom ghost_parentPeerSet_emittedAddress == 0;
}

// --- StrategyUpdated (Parent) --- //
/// @notice EventCount: track amount of StrategyUpdated event is emitted
ghost mathint ghost_strategyUpdated_eventCount {
    init_state axiom ghost_strategyUpdated_eventCount == 0;
}

/// @notice EmittedValue: track the new chain selector emitted by StrategyUpdated event
ghost uint64 ghost_strategyUpdated_emittedNewChainSelector {
    init_state axiom ghost_strategyUpdated_emittedNewChainSelector == 0;
}

/// @notice EmittedValue: track the new protocol id emitted by StrategyUpdated event
ghost bytes32 ghost_strategyUpdated_emittedNewProtocolId {
    init_state axiom ghost_strategyUpdated_emittedNewProtocolId == to_bytes32(0);
}

/// @notice EmittedValue: track the old chain selector emitted by StrategyUpdated event
ghost uint64 ghost_strategyUpdated_emittedOldChainSelector {
    init_state axiom ghost_strategyUpdated_emittedOldChainSelector == 0;
}

// --- DepositToStrategy (Parent) --- //
/// @notice EventCount: track amount of DepositToStrategy event is emitted
ghost mathint ghost_depositToStrategy_eventCount {
    init_state axiom ghost_depositToStrategy_eventCount == 0;
}

// --- CCIPMessageSent (Parent) --- //
/// @notice EventCount: track amount of CCIPMessageSent event is emitted
ghost mathint ghost_ccipMessageSent_eventCount {
    init_state axiom ghost_ccipMessageSent_eventCount == 0;
}

/// @notice EmittedValue: track the CcipTxType emitted by CCIPMessageSent event
ghost mathint ghost_ccipMessageSent_txType_emitted {
    init_state axiom ghost_ccipMessageSent_txType_emitted == 0;
}

/// @notice EmittedValue: track the bridgeAmount emitted by CCIPMessageSent event
ghost mathint ghost_ccipMessageSent_bridgeAmount_emitted {
    init_state axiom ghost_ccipMessageSent_bridgeAmount_emitted == 0;
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// @notice hook onto emitted events and update relevant ghosts
hook LOG4(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2, bytes32 t3) {
    if (t0 == CCIPMessageSentEvent()) {
        ghost_ccipMessageSent_eventCount = ghost_ccipMessageSent_eventCount + 1;
        ghost_ccipMessageSent_txType_emitted = bytes32ToUint8(t2);
        ghost_ccipMessageSent_bridgeAmount_emitted = bytes32ToUint256(t3);
    }
    if (t0 == StrategyUpdatedEvent()) {
        ghost_strategyUpdated_eventCount = ghost_strategyUpdated_eventCount + 1;
        ghost_strategyUpdated_emittedNewChainSelector = bytes32ToUint64(t1);
        ghost_strategyUpdated_emittedNewProtocolId = t2;
        ghost_strategyUpdated_emittedOldChainSelector = bytes32ToUint64(t3);
    }
}

/// @notice hook onto emitted events and increment relevant ghosts
hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == ReportDecodedEvent()) {
        ghost_reportDecoded_eventCount = ghost_reportDecoded_eventCount + 1;
        ghost_reportDecoded_emittedChainSelector = bytes32ToUint64(t1);
        ghost_reportDecoded_emittedProtocolId = t2;
    }
    if (t0 == DepositToStrategyEvent()) {
        ghost_depositToStrategy_eventCount = ghost_depositToStrategy_eventCount + 1;
    }
}

/// @notice hook onto emitted events and update relevant ghosts
hook LOG2(uint offset, uint length, bytes32 t0, bytes32 t1) {
    if (t0 == ParentPeerSetEvent()) {
        ghost_parentPeerSet_eventCount = ghost_parentPeerSet_eventCount + 1;
        ghost_parentPeerSet_emittedAddress = bytes32ToAddress(t1);
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
// --- _onReport --- //
rule onReport_validReport_emitsReportDecodedEvent() {
    env e;

    // workflow metadata
    bytes metadata;

    // workflow report
    uint64 chainSelector;
    bytes32 protocolId;
    bytes report = createWorkflowReport(chainSelector, protocolId);

    require ghost_reportDecoded_eventCount == 0;
    require ghost_reportDecoded_emittedChainSelector == 0;
    require ghost_reportDecoded_emittedProtocolId == to_bytes32(0);

    onReport(e, metadata, report);

    assert ghost_reportDecoded_eventCount == 1;
    assert ghost_reportDecoded_emittedChainSelector == chainSelector;
    assert ghost_reportDecoded_emittedProtocolId == protocolId;
}

/// @dev Sanity rule to ensure onReport can update/emit strategy if not optimal
rule onReport_updatesStrategyState_andEmitsStrategyUpdated() {
    env e;

    // worfklow metadata
    bytes metadata;

    // workflow report
    uint64 chainSelector;
    bytes32 protocolId;
    bytes report = createWorkflowReport(chainSelector, protocolId);

    IYieldPeer.Strategy oldStrategy = getCurrentStrategy();

    // chain or protocol id not current strategy
    require oldStrategy.chainSelector != chainSelector || oldStrategy.protocolId != protocolId;

    require ghost_strategyUpdated_eventCount == 0;
    require ghost_strategyUpdated_emittedNewChainSelector == 0;
    require ghost_strategyUpdated_emittedNewProtocolId == to_bytes32(0);
    require ghost_strategyUpdated_emittedOldChainSelector == 0;

    onReport(e, metadata, report);

    IYieldPeer.Strategy newStrategy = getCurrentStrategy();
    assert newStrategy.chainSelector == chainSelector;
    assert newStrategy.protocolId == protocolId;
    assert ghost_strategyUpdated_eventCount == 1;
    assert ghost_strategyUpdated_emittedNewChainSelector == chainSelector;
    assert ghost_strategyUpdated_emittedNewProtocolId == protocolId;
    assert ghost_strategyUpdated_emittedOldChainSelector == oldStrategy.chainSelector;
}

rule onReport_rebalanceParentToParent() {
    env e;

    // workflow metadata
    bytes metadata;

    // workflow report
    uint64 chainSelector;
    bytes32 protocolId;
    bytes report = createWorkflowReport(chainSelector, protocolId);

    // same parent chain, different protocol
    IYieldPeer.Strategy oldStrategy = getCurrentStrategy();
    require oldStrategy.chainSelector == getParentChainSelector();
    require oldStrategy.protocolId != protocolId;
    require chainSelector == oldStrategy.chainSelector;

    require parent.getTotalValue() > 0;

    require ghost_reportDecoded_eventCount == 0;
    require ghost_reportDecoded_emittedChainSelector == 0;
    require ghost_reportDecoded_emittedProtocolId == to_bytes32(0);
    require ghost_strategyUpdated_eventCount == 0;
    require ghost_strategyUpdated_emittedNewChainSelector == 0;
    require ghost_strategyUpdated_emittedNewProtocolId == to_bytes32(0);
    require ghost_strategyUpdated_emittedOldChainSelector == 0;
    require ghost_depositToStrategy_eventCount == 0;

    onReport(e, metadata, report);

    IYieldPeer.Strategy newStrategy = getCurrentStrategy();
    assert newStrategy.chainSelector == chainSelector;
    assert newStrategy.protocolId == protocolId;
    assert ghost_reportDecoded_eventCount == 1;
    assert ghost_reportDecoded_emittedChainSelector == chainSelector;
    assert ghost_reportDecoded_emittedProtocolId == protocolId;
    assert ghost_strategyUpdated_eventCount == 1;
    assert ghost_strategyUpdated_emittedNewChainSelector == chainSelector;
    assert ghost_strategyUpdated_emittedNewProtocolId == protocolId;
    assert ghost_strategyUpdated_emittedOldChainSelector == oldStrategy.chainSelector;
    assert ghost_depositToStrategy_eventCount == 1;
}

rule onReport_rebalanceParentToChild() {
    env e;

    // workflow metadata
    bytes metadata;

    // workflow report
    uint64 chainSelector;
    bytes32 protocolId;
    bytes report = createWorkflowReport(chainSelector, protocolId);

    // strategy on parent, new strategy on child
    IYieldPeer.Strategy oldStrategy = getCurrentStrategy();
    require oldStrategy.chainSelector == getParentChainSelector();
    require chainSelector != oldStrategy.chainSelector;

    require ghost_reportDecoded_eventCount == 0;
    require ghost_reportDecoded_emittedChainSelector == 0;
    require ghost_reportDecoded_emittedProtocolId == to_bytes32(0);
    require ghost_strategyUpdated_eventCount == 0;
    require ghost_strategyUpdated_emittedNewChainSelector == 0;
    require ghost_strategyUpdated_emittedNewProtocolId == to_bytes32(0);
    require ghost_strategyUpdated_emittedOldChainSelector == 0;
    require ghost_ccipMessageSent_eventCount == 0;
    require ghost_ccipMessageSent_txType_emitted == 0;

    onReport(e, metadata, report);

    IYieldPeer.Strategy newStrategy = getCurrentStrategy();
    assert newStrategy.chainSelector == chainSelector;
    assert newStrategy.protocolId == protocolId;
    assert ghost_reportDecoded_eventCount == 1;
    assert ghost_reportDecoded_emittedChainSelector == chainSelector;
    assert ghost_reportDecoded_emittedProtocolId == protocolId;
    assert ghost_strategyUpdated_eventCount == 1;
    assert ghost_strategyUpdated_emittedNewChainSelector == chainSelector;
    assert ghost_strategyUpdated_emittedNewProtocolId == protocolId;
    assert ghost_strategyUpdated_emittedOldChainSelector == oldStrategy.chainSelector;
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 8; // rebalance new strateegy
}

rule onReport_rebalanceChildToOther() {
    env e;

    // workflow metadata
    bytes metadata;

    // workflow report
    uint64 chainSelector;
    bytes32 protocolId;
    bytes report = createWorkflowReport(chainSelector, protocolId);

    // strategy on child
    IYieldPeer.Strategy oldStrategy = getCurrentStrategy();
    require oldStrategy.chainSelector != getParentChainSelector();
    // require protocolId != oldStrategy.protocolId;

    require ghost_reportDecoded_eventCount == 0;
    require ghost_reportDecoded_emittedChainSelector == 0;
    require ghost_reportDecoded_emittedProtocolId == to_bytes32(0);
    require ghost_strategyUpdated_eventCount == 0;
    require ghost_strategyUpdated_emittedNewChainSelector == 0;
    require ghost_strategyUpdated_emittedNewProtocolId == to_bytes32(0);
    require ghost_strategyUpdated_emittedOldChainSelector == 0;
    require ghost_ccipMessageSent_eventCount == 0;
    require ghost_ccipMessageSent_txType_emitted == 0;
    require ghost_ccipMessageSent_bridgeAmount_emitted == 0;

    onReport(e, metadata, report);

    IYieldPeer.Strategy newStrategy = getCurrentStrategy();
    assert newStrategy.chainSelector == chainSelector;
    assert newStrategy.protocolId == protocolId;
    assert ghost_reportDecoded_eventCount == 1;
    assert ghost_reportDecoded_emittedChainSelector == chainSelector;
    assert ghost_reportDecoded_emittedProtocolId == protocolId;
    assert ghost_strategyUpdated_eventCount == 1;
    assert ghost_strategyUpdated_emittedNewChainSelector == chainSelector;
    assert ghost_strategyUpdated_emittedNewProtocolId == protocolId;
    assert ghost_strategyUpdated_emittedOldChainSelector == oldStrategy.chainSelector;
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 7; // rebalance old strateegy
    assert ghost_ccipMessageSent_bridgeAmount_emitted == 0;
}

// --- setters --- //
rule setParentPeer_success() {
    env e;
    address parentPeer;

    require ghost_parentPeerSet_eventCount == 0;
    require ghost_parentPeerSet_emittedAddress == 0;

    setParentPeer(e, parentPeer);

    assert ghost_parentPeerSet_eventCount == 1;
    assert ghost_parentPeerSet_emittedAddress == parentPeer;
    assert currentContract.s_parentPeer == parentPeer;
    assert getParentPeer() == parentPeer;
}

// --- getters --- //
rule getParentPeer_returnsParentPeer() {
    address parentPeer;
    require parentPeer != 0x0;
    require currentContract.s_parentPeer == parentPeer;

    assert getParentPeer() == parentPeer;
}

rule getCurrentStrategy_matchesParentPeer() {
    IYieldPeer.Strategy strategyFromRebalancer = getCurrentStrategy();
    IYieldPeer.Strategy strategyFromParentPeer = parent.getStrategy();

    assert strategyFromRebalancer.chainSelector == strategyFromParentPeer.chainSelector;
    assert strategyFromRebalancer.protocolId == strategyFromParentPeer.protocolId;
}
