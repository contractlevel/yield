using MockUsdc as usdc;

/// Verification of ParentRebalancer
/// @author @contractlevel
/// @notice ParentRebalancer handles the Chainlink Log-trigger Automation to execute CCIP rebalances

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // ParentRebalancer methods
    function getForwarder() external returns (address) envfree;
    function getParentPeer() external returns (address) envfree;

    // External methods
    function usdc.balanceOf(address) external returns (uint256) envfree;

    // Summary methods
    function _.balanceOf(address) external => DISPATCHER(true);
    function _.getPool() external => DISPATCHER(true);
    function _.getReserveData(address) external => DISPATCHER(true);
    function _.rebalanceNewStrategy(address, uint256, IYieldPeer.Strategy) external => DISPATCHER(true);
    function _.rebalanceOldStrategy(uint64, IYieldPeer.Strategy) external => DISPATCHER(true);
    function _.getFee(uint64, Client.EVM2AnyMessage) external => DISPATCHER(true);
    function _.approve(address, uint256) external => DISPATCHER(true);
    function _.ccipSend(uint64, Client.EVM2AnyMessage) external => DISPATCHER(true);
    function _.withdraw(address, uint256) external => DISPATCHER(true);
    function _.withdraw(address, uint256, address) external => DISPATCHER(true);
    function _.transfer(address, uint256) external => DISPATCHER(true);

    // Harness helper methods
    function bytes32ToAddress(bytes32) external returns (address) envfree;
    function uint64ToBytes32(uint64) external returns (bytes32) envfree;
    function uint8ToBytes32(uint8) external returns (bytes32) envfree;
    function getParentChainSelector() external returns (uint64) envfree;
    function harnessCreateLog(uint256,uint256,bytes32,uint256,bytes32,address,bytes32[],bytes) external returns (ParentRebalancer.Log) envfree;
    function decodePerformData(bytes) external returns (
        address,
        address,
        IYieldPeer.Strategy memory,
        IYieldPeer.CcipTxType,
        uint64,
        address,
        uint256
    ) envfree;
    function getTotalValueFromParentPeer() external returns (uint256) envfree;
    function getStrategyPoolFromParentPeer() external returns (address) envfree;
    function createNonEmptyBytes() external returns (bytes) envfree;
    function createEmptyBytes() external returns (bytes) envfree;
    function createPerformData(
        address,
        address,
        IYieldPeer.Strategy,
        IYieldPeer.CcipTxType,
        uint64,
        address,
        uint256
    ) external returns (bytes) envfree;
    function createStrategy(uint64, IYieldPeer.Protocol) external returns (IYieldPeer.Strategy) envfree;
    function bytes32ToUint8(bytes32) external returns (uint8) envfree;
    function bytes32ToUint256(bytes32) external returns (uint256) envfree;
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition ForwarderSetEvent() returns bytes32 =
// keccak256(abi.encodePacked("ForwarderSet(address)"))
    to_bytes32(0x01e06e871b32b0b127105fbd5dbecd24273b7e1191a8940de24f4ea249e355d6);

definition ParentPeerSetEvent() returns bytes32 =
// keccak256(abi.encodePacked("ParentPeerSet(address)"))
    to_bytes32(0x9bd1968cee8e2e99d039a6a765fa06cfa0ddb152eacae28608f4b14390157658);

definition StrategyUpdatedEvent() returns bytes32 =
// keccak256(abi.encodePacked("StrategyUpdated(uint64,uint8,uint64)"))
    to_bytes32(0xcb31617872c52547b670aaf6e63c8f6be35dc74d4144db1b17f2e539b5475ac7);

definition CCIPMessageSentEvent() returns bytes32 =
// keccak256(abi.encodePacked("CCIPMessageSent(bytes32,uint8,uint256)"))
    to_bytes32(0xf58bb6f6ec82990ff728621d18279c43cae3bc9777d052ed0d2316669e58cee6);

/// @notice functions that can only be called by the owner
definition onlyOwner(method f) returns bool = 
    f.selector == sig:setForwarder(address).selector ||
    f.selector == sig:setParentPeer(address).selector;

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
/// @notice EventCount: track amount ForwarderSet event is emitted
ghost mathint ghost_forwarderSet_eventCount {
    init_state axiom ghost_forwarderSet_eventCount == 0;
}

/// @notice EventCount: track amount ParentPeerSet event is emitted
ghost mathint ghost_parentPeerSet_eventCount {
    init_state axiom ghost_parentPeerSet_eventCount == 0;
}

/// @notice EmittedValue: track address emitted in ForwarderSet event
ghost address ghost_forwarderSet_emittedAddress {
    init_state axiom ghost_forwarderSet_emittedAddress == 0;
}

/// @notice EmittedValue: track address emitted in ParentPeerSet event
ghost address ghost_parentPeerSet_emittedAddress {
    init_state axiom ghost_parentPeerSet_emittedAddress == 0;
}

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
}

/// @notice hook onto emitted events and update relevant ghosts
hook LOG2(uint offset, uint length, bytes32 t0, bytes32 t1) {
    if (t0 == ForwarderSetEvent()) {
        ghost_forwarderSet_eventCount = ghost_forwarderSet_eventCount + 1;
        ghost_forwarderSet_emittedAddress = bytes32ToAddress(t1);
    }
    if (t0 == ParentPeerSetEvent()) {
        ghost_parentPeerSet_eventCount = ghost_parentPeerSet_eventCount + 1;
        ghost_parentPeerSet_emittedAddress = bytes32ToAddress(t1);
    }
}

/*//////////////////////////////////////////////////////////////
                           FUNCTIONS
//////////////////////////////////////////////////////////////*/
function createLog(
    address source, 
    bytes32 eventSignature,
    uint64 newChainSelector, 
    uint8 protocolEnum, 
    uint64 oldChainSelector
) returns ParentRebalancer.Log {
    uint256 index;
    uint256 timestamp;
    bytes32 txHash;
    uint256 blockNumber;
    bytes32 blockHash;
    bytes32[] topics;
    bytes data;

    require topics.length == 4;
    require topics[0] == eventSignature;
    require topics[1] == uint64ToBytes32(newChainSelector);
    require topics[2] == uint8ToBytes32(protocolEnum);
    require topics[3] == uint64ToBytes32(oldChainSelector);

    return harnessCreateLog(index, timestamp, txHash, blockNumber, blockHash, source, topics, data);
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule onlyOwner_revertsWhen_notOwner(method f) 
    filtered {f -> onlyOwner(f)} 
{
    env e;
    calldataarg args;

    require e.msg.sender != currentContract._owner;

    f@withrevert(e, args);
    assert lastReverted;
}

rule setForwarder_success() {
    env e;
    address forwarder;

    require ghost_forwarderSet_eventCount == 0;
    require ghost_forwarderSet_emittedAddress == 0;
    setForwarder(e, forwarder);
    assert ghost_forwarderSet_eventCount == 1;
    assert ghost_forwarderSet_emittedAddress == forwarder;
    assert getForwarder() == forwarder;
}

rule setParentPeer_success() {
    env e;
    address parentPeer;

    require ghost_parentPeerSet_eventCount == 0;
    require ghost_parentPeerSet_emittedAddress == 0;
    setParentPeer(e, parentPeer);
    assert ghost_parentPeerSet_eventCount == 1;
    assert ghost_parentPeerSet_emittedAddress == parentPeer;
    assert getParentPeer() == parentPeer;
}

// --- checkLog --- //
/// @notice checkLog is simulated offchain by CLA nodes and should revert
rule checkLog_reverts() {
    env e;
    calldataarg args;
    require e.msg.value == 0;
    
    require e.tx.origin != 0;
    require e.tx.origin != 0x1111111111111111111111111111111111111111;

    checkLog@withrevert(e, args);
    assert lastReverted;
}

// rule is vacuous
rule checkLog_revertsWhen_localParentRebalance() {
    env e;
    uint8 protocolEnum;
    require e.msg.value == 0;
    require e.tx.origin == 0 || e.tx.origin == 0x1111111111111111111111111111111111111111;

    ParentRebalancer.Log log = createLog(
        getParentPeer(),
        StrategyUpdatedEvent(),
        getParentChainSelector(),
        protocolEnum,
        getParentChainSelector()
    );
    bytes data;

    checkLog@withrevert(e, log, data);
    assert lastReverted;
}

// rule is vacuous
rule checkLog_revertsWhen_wrongEvent() {
    env e;
    uint8 protocolEnum;
    uint64 newChainSelector;
    uint64 oldChainSelector;
    require e.tx.origin == 0 || e.tx.origin == 0x1111111111111111111111111111111111111111;
    require newChainSelector == getParentChainSelector() => oldChainSelector != getParentChainSelector();
    require oldChainSelector == getParentChainSelector() => newChainSelector != getParentChainSelector();
    require e.msg.value == 0;

    bytes32 wrongEvent;
    require wrongEvent != StrategyUpdatedEvent();

    ParentRebalancer.Log log = createLog(
        getParentPeer(),
        wrongEvent,
        newChainSelector,
        protocolEnum,
        oldChainSelector
    );
    bytes data;

    checkLog@withrevert(e, log, data);
    assert lastReverted;
}

// rule is vacuous
rule checkLog_revertsWhen_wrongSource() {
    env e;
    uint8 protocolEnum;
    uint64 newChainSelector;
    uint64 oldChainSelector;
    require newChainSelector == getParentChainSelector() => oldChainSelector != getParentChainSelector();
    require oldChainSelector == getParentChainSelector() => newChainSelector != getParentChainSelector();
    require e.tx.origin == 0 || e.tx.origin == 0x1111111111111111111111111111111111111111;
    require e.msg.value == 0;
    address wrongSource;
    require wrongSource != getParentPeer();

    ParentRebalancer.Log log = createLog(
        wrongSource,
        StrategyUpdatedEvent(),
        newChainSelector,
        protocolEnum,
        oldChainSelector
    );
    bytes data;

    checkLog@withrevert(e, log, data);
    assert lastReverted;
}

// rule is vacuous
rule checkLog_returnsTrueWhen_oldStrategyChild() {
    env e;
    uint8 protocolEnum;
    uint64 newChainSelector;
    uint64 oldChainSelector;
    require oldChainSelector != getParentChainSelector();

    require e.tx.origin == 0 || e.tx.origin == 0x1111111111111111111111111111111111111111;
    require e.msg.value == 0;

    ParentRebalancer.Log log = createLog(
        getParentPeer(),
        StrategyUpdatedEvent(),
        newChainSelector,
        protocolEnum,
        oldChainSelector
    );
    bytes data;

    bool upkeepNeeded = false;
    bytes performData = createEmptyBytes();

    (upkeepNeeded, performData) = checkLog@withrevert(e, log, data);
    assert !lastReverted;
    assert upkeepNeeded;
    assert performData.length > 0;

    address forwarder;
    address parentPeer;
    IYieldPeer.Strategy strategy;
    IYieldPeer.CcipTxType txType;
    uint64 decodedOldChainSelector;
    address oldStrategyPool;
    uint256 totalValue;

    (
    forwarder,
    parentPeer,
    strategy,
    txType,
    decodedOldChainSelector,
    oldStrategyPool,
    totalValue
    ) = decodePerformData(performData);

    assert forwarder == getForwarder();
    assert parentPeer == getParentPeer();
    assert strategy.chainSelector == newChainSelector;
    assert assert_uint8(strategy.protocol) == protocolEnum;
    assert txType == IYieldPeer.CcipTxType.RebalanceOldStrategy;
    assert decodedOldChainSelector == oldChainSelector;
    assert oldStrategyPool == 0;
    assert totalValue == 0;
}

// rule is vacuous
rule checkLog_returnsTrueWhen_oldStrategyParent_newStrategyChild() {
    env e;
    uint8 protocolEnum;
    uint64 newChainSelector;
    uint64 oldChainSelector;
    require oldChainSelector == getParentChainSelector();
    require newChainSelector != getParentChainSelector();

    require e.tx.origin == 0 || e.tx.origin == 0x1111111111111111111111111111111111111111;
    require e.msg.value == 0;

    ParentRebalancer.Log log = createLog(
        getParentPeer(),
        StrategyUpdatedEvent(),
        newChainSelector,
        protocolEnum,
        oldChainSelector
    );
    bytes data;

    bool upkeepNeeded = false;
    bytes performData = createEmptyBytes();

    (upkeepNeeded, performData) = checkLog@withrevert(e, log, data);
    assert !lastReverted;
    assert upkeepNeeded;
    assert performData.length > 0;

    address forwarder;
    address parentPeer;
    IYieldPeer.Strategy strategy;
    IYieldPeer.CcipTxType txType;
    uint64 decodedOldChainSelector;
    address oldStrategyPool;
    uint256 totalValue;

    (
    forwarder,
    parentPeer,
    strategy,
    txType,
    decodedOldChainSelector,
    oldStrategyPool,
    totalValue
    ) = decodePerformData(performData);

    assert forwarder == getForwarder();
    assert parentPeer == getParentPeer();
    assert strategy.chainSelector == newChainSelector;
    assert assert_uint8(strategy.protocol) == protocolEnum;
    assert txType == IYieldPeer.CcipTxType.RebalanceNewStrategy;
    assert decodedOldChainSelector == oldChainSelector;
    assert oldStrategyPool == getStrategyPoolFromParentPeer();
    assert totalValue == getTotalValueFromParentPeer();
}

// --- performUpkeep --- //
rule performUpkeep_revertsWhen_notForwarder() {
    env e;
    uint64 chainSelector;
    IYieldPeer.Protocol protocol;
    IYieldPeer.Strategy strategy = createStrategy(chainSelector, protocol);
    bytes performData = createPerformData(
        getForwarder(),
        getParentPeer(),
        strategy,
        IYieldPeer.CcipTxType.RebalanceOldStrategy,
        getParentChainSelector(),
        0,
        0
    );

    require e.msg.sender != getForwarder();

    performUpkeep@withrevert(e, performData);
    assert lastReverted;
}

rule performUpkeep_triggersCCIPMessageSentEvent() {
    env e;
    calldataarg args;

    require ghost_ccipMessageSent_eventCount == 0;
    performUpkeep(e, args);
    assert ghost_ccipMessageSent_eventCount == 1;
}

rule performUpkeep_rebalanceNewStrategy() {
    env e;
    uint64 chainSelector;
    IYieldPeer.Protocol protocol;
    IYieldPeer.Strategy strategy = createStrategy(chainSelector, protocol);
    uint256 totalValue = getTotalValueFromParentPeer();
    bytes performData = createPerformData(
        getForwarder(),
        getParentPeer(),
        strategy,
        IYieldPeer.CcipTxType.RebalanceNewStrategy,
        getParentChainSelector(),
        getStrategyPoolFromParentPeer(),
        totalValue
    );

    require ghost_ccipMessageSent_eventCount == 0;
    require ghost_ccipMessageSent_txType_emitted == 0;
    performUpkeep(e, performData);
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 8;
}

rule performUpkeep_rebalanceOldStrategy() {
    env e;
    uint64 chainSelector;
    uint64 oldChainSelector;
    IYieldPeer.Protocol protocol;
    IYieldPeer.Strategy strategy = createStrategy(chainSelector, protocol);
    bytes performData = createPerformData(
        getForwarder(),
        getParentPeer(),
        strategy,
        IYieldPeer.CcipTxType.RebalanceOldStrategy,
        oldChainSelector,
        0,
        0
    );
    require oldChainSelector != getParentChainSelector();

    require ghost_ccipMessageSent_eventCount == 0;
    require ghost_ccipMessageSent_txType_emitted == 0;
    require ghost_ccipMessageSent_bridgeAmount_emitted == 0;
    performUpkeep(e, performData);
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 7;
    assert ghost_ccipMessageSent_bridgeAmount_emitted == 0;
}
