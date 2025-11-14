using MockUsdc as usdc;
using ParentPeer as parent;
using StrategyRegistry as strategyRegistry;

/// Verification of Rebalancer
/// @author @contractlevel
/// @notice Rebalancer handles the Chainlink Automation and Functions logic

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // Rebalancer methods
    function getUpkeepAddress() external returns (address) envfree;
    function getForwarder() external returns (address) envfree;
    function getParentPeer() external returns (address) envfree;
    function getStrategyRegistry() external returns (address) envfree;

    // PausableWithAccessControl methods
    function owner() external returns (address) envfree;
    function paused() external returns (bool) envfree;  
    function hasRole(bytes32, address) external returns (bool) envfree;
    function getRoleMember(bytes32, uint256) external returns (address) envfree;
    function getRoleMemberCount(bytes32) external returns (uint256) envfree;
    function getRoleMembers(bytes32) external returns (address[] memory) envfree;

    // External methods
    function usdc.balanceOf(address) external returns (uint256) envfree;
    function parent.getAllowedChain(uint64) external returns (bool) envfree;
    function strategyRegistry.getStrategyAdapter(bytes32) external returns (address) envfree;

    // Summary methods
    function _.balanceOf(address) external => DISPATCHER(true);
    function _.getPool() external => DISPATCHER(true);
    function _.getReserveData(address) external => DISPATCHER(true);
    function _.rebalanceParentToChild(address, uint256, IYieldPeer.Strategy) external => DISPATCHER(true);
    function _.rebalanceChildToOther(uint64, IYieldPeer.Strategy) external => DISPATCHER(true);
    function _.getFee(uint64, Client.EVM2AnyMessage) external => DISPATCHER(true);
    function _.approve(address, uint256) external => DISPATCHER(true);
    function _.ccipSend(uint64, Client.EVM2AnyMessage) external => DISPATCHER(true);
    function _.withdraw(address, uint256) external => DISPATCHER(true);
    function _.withdraw(address, uint256, address) external => DISPATCHER(true);
    function _.transfer(address, uint256) external => DISPATCHER(true);
    function _.getAllowedChain(uint64 chainSelector) external => DISPATCHER(true);
    function _.deposit(address,uint256) external => DISPATCHER(true);
    function _.getTotalValue(address) external => DISPATCHER(true);

    // Harness helper methods
    function bytes32ToAddress(bytes32) external returns (address) envfree;
    function addressToBytes32(address value) external returns (bytes32) envfree;
    function uint64ToBytes32(uint64) external returns (bytes32) envfree;
    function uint8ToBytes32(uint8) external returns (bytes32) envfree;
    function getParentChainSelector() external returns (uint64) envfree;
    function harnessCreateLog(uint256,uint256,bytes32,uint256,bytes32,address,bytes32[],bytes) external returns 
        (Rebalancer.Log) envfree;
    function decodePerformData(bytes) external returns (
        address,
        IYieldPeer.Strategy memory,
        IYieldPeer.CcipTxType,
        uint64,
        address,
        uint256
    ) envfree;
    function getTotalValueFromParentPeer() external returns (uint256) envfree;
    function getActiveStrategyAdapterFromParentPeer() external returns (address) envfree;
    function createNonEmptyBytes() external returns (bytes) envfree;
    function createEmptyBytes() external returns (bytes) envfree;
    function createPerformData(
        address,
        IYieldPeer.Strategy,
        IYieldPeer.CcipTxType,
        uint64,
        address,
        uint256
    ) external returns (bytes) envfree;
    function createStrategy(uint64, bytes32) external returns (IYieldPeer.Strategy) envfree;
    function bytes32ToUint8(bytes32) external returns (uint8) envfree;
    function bytes32ToUint256(bytes32) external returns (uint256) envfree;
    function createCLFResponse(uint64 chainSelector, bytes32 protocolId) external returns (bytes memory) envfree;
    function getStrategyFromParentPeer() external returns (IYieldPeer.Strategy memory) envfree;
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
/// @notice functions that can only be called by the config admin role
definition onlyRoleConfigAdmin(method f) returns bool = 
    f.selector == sig:setForwarder(address).selector ||
    f.selector == sig:setParentPeer(address).selector ||
    f.selector == sig:setUpkeepAddress(address).selector ||
    f.selector == sig:setStrategyRegistry(address).selector;

definition crossChainAdminRole() returns bytes32 = 
// keccak256("CROSS_CHAIN_ADMIN_ROLE")
    to_bytes32(0xb28dc5efd345f3bec5c16749590c736fbb2ba9912d8680cac4da7a59f918a760);

definition configAdminRole() returns bytes32 = 
// keccak256("CONFIG_ADMIN_ROLE")
    to_bytes32(0xb92d52e77ebaa0cae5c23e882d85609efbcb44029214147dd132daf9ef1018af);

definition feeWithdrawerRole() returns bytes32 = 
// keccak256("FEE_WITHDRAWER_ROLE")
    to_bytes32(0xcecef922ac6ded813804bed2d5fdf033decf4a090fa3c9b9f529302a0aff6455);   

definition feeRateSetterRole() returns bytes32 = 
// keccak256("FEE_RATE_SETTER_ROLE")
    to_bytes32(0x658e71518b7b5afc52c60427d525dee00a59b3720f918587414f669096f77bee);

definition emergencyPauserRole() returns bytes32 = 
// keccak256("EMERGENCY_PAUSER_ROLE")
    to_bytes32(0x3b72b77b3d95d9b831cca52b36d7a9c3758f77be6c47ebd087c47739c743d369);

definition emergencyUnpauserRole() returns bytes32 = 
// keccak256("EMERGENCY_UNPAUSER_ROLE")
    to_bytes32(0x7bd03e5eb4ee9007f85634e07fc4bb1fbe96d33e9f2d1644bc6bda2b6b8a3169);

definition PausedEvent() returns bytes32 =
// keccak256(abi.encodePacked("Paused(address)"))
    to_bytes32(0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258);

definition UnpausedEvent() returns bytes32 =
// keccak256(abi.encodePacked("Unpaused(address)"))
    to_bytes32(0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa);

definition UpkeepAddressSetEvent() returns bytes32 = 
// keccak256(abi.encodePacked("UpkeepAddressSet(address)"))
to_bytes32(0x1be7b94706c10cf5f370becb942307f13539075d19051fc58795a999c57e8849);

definition ForwarderSetEvent() returns bytes32 =
// keccak256(abi.encodePacked("ForwarderSet(address)"))
    to_bytes32(0x01e06e871b32b0b127105fbd5dbecd24273b7e1191a8940de24f4ea249e355d6);

definition ParentPeerSetEvent() returns bytes32 =
// keccak256(abi.encodePacked("ParentPeerSet(address)"))
    to_bytes32(0x9bd1968cee8e2e99d039a6a765fa06cfa0ddb152eacae28608f4b14390157658);

definition StrategyRegistrySetEvent() returns bytes32 = 
// keccak256(abi.encodePacked("StrategyRegistrySet(address)"))
to_bytes32(0xc8f6f976c20221cfca1498913573ed2bc921d8f3c6e4b7d1fcf4d228628bbd10);

definition StrategyUpdatedEvent() returns bytes32 =
// keccak256(abi.encodePacked("StrategyUpdated(uint64,uint8,uint64)"))
    to_bytes32(0xcb31617872c52547b670aaf6e63c8f6be35dc74d4144db1b17f2e539b5475ac7);

definition CCIPMessageSentEvent() returns bytes32 =
// keccak256(abi.encodePacked("CCIPMessageSent(bytes32,uint8,uint256)"))
    to_bytes32(0xf58bb6f6ec82990ff728621d18279c43cae3bc9777d052ed0d2316669e58cee6);

definition CLFRequestErrorEvent() returns bytes32 =
// keccak256(abi.encodePacked("CLFRequestError(bytes32,bytes)"))
    to_bytes32(0x4bb259a91776ab365a90aa2b74bcc616da60d5c6a651a9e55e79c1bae9340818);

definition InvalidChainSelectorEvent() returns bytes32 =
// keccak256(abi.encodePacked("InvalidChainSelector(bytes32,uint64)"))
    to_bytes32(0xcbb1a0175d5d5f83e120c4bcd9d3b172de3d4303caf6d5a3be87fc19472fd108);

definition InvalidProtocolIdEvent() returns bytes32 =
// keccak256(abi.encodePacked("InvalidProtocolId(bytes32,bytes32)"))
    to_bytes32(0x5fbf94e7763a39475d6eeabb0e295a0f648d2e113bc1783be5aa614513cba101);

definition CLFRequestFulfilledEvent() returns bytes32 =
// keccak256(abi.encodePacked("CLFRequestFulfilled(bytes32,uint64,bytes32)"))
    to_bytes32(0xfc2f12fbc5bcf0ba379c3c98039595e5f7793e4a1e6ad603b05c23004fd3f98b);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
/// @notice EventCount: track amount Paused event is emitted
ghost mathint ghost_paused_eventCount {
    init_state axiom ghost_paused_eventCount == 0;
}

/// @notice EventCount: track amount Unpaused event is emitted
ghost mathint ghost_unpaused_eventCount {
    init_state axiom ghost_unpaused_eventCount == 0;
}

/// @notice EventCount: track amount UpkeepAddressSet event is emitted
ghost mathint ghost_upkeepAddressSet_eventCount {
    init_state axiom ghost_upkeepAddressSet_eventCount == 0;
}

/// @notice EventCount: track amount ForwarderSet event is emitted
ghost mathint ghost_forwarderSet_eventCount {
    init_state axiom ghost_forwarderSet_eventCount == 0;
}

/// @notice EventCount: track amount ParentPeerSet event is emitted
ghost mathint ghost_parentPeerSet_eventCount {
    init_state axiom ghost_parentPeerSet_eventCount == 0;
}

/// @notice EventCount: track amount StrategyRegistrySet event is emitted
ghost mathint ghost_strategyRegistrySet_eventCount {
    init_state axiom ghost_strategyRegistrySet_eventCount == 0;
}

/// @notice EmittedValue: track address emitted in UpkeepAddressSet event
ghost address ghost_upkeepAddressSet_emittedAddress {
    init_state axiom ghost_upkeepAddressSet_emittedAddress == 0;
}

/// @notice EmittedValue: track address emitted in ForwarderSet event
ghost address ghost_forwarderSet_emittedAddress {
    init_state axiom ghost_forwarderSet_emittedAddress == 0;
}

/// @notice EmittedValue: track address emitted in ParentPeerSet event
ghost address ghost_parentPeerSet_emittedAddress {
    init_state axiom ghost_parentPeerSet_emittedAddress == 0;
}

/// @notice EmittedValue: track address emitted in StrategyRegistrySet event
ghost address ghost_strategyRegistrySet_emittedAddress {
    init_state axiom ghost_strategyRegistrySet_emittedAddress == 0;
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

/// @notice track amount of CLFRequestError event is emitted
ghost mathint ghost_clfRequestError_eventCount {
    init_state axiom ghost_clfRequestError_eventCount == 0;
}

/// @notice track amount of CLFRequestFulfilled event is emitted
ghost mathint ghost_clfRequestFulfilled_eventCount {
    init_state axiom ghost_clfRequestFulfilled_eventCount == 0;
}

/// @notice track amount of InvalidChainSelector event is emitted
ghost mathint ghost_invalidChainSelector_eventCount {
    init_state axiom ghost_invalidChainSelector_eventCount == 0;
}

/// @notice track amount of InvalidProtocolId event is emitted
ghost mathint ghost_invalidProtocolId_eventCount {
    init_state axiom ghost_invalidProtocolId_eventCount == 0;
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
    if (t0 == CLFRequestFulfilledEvent()) ghost_clfRequestFulfilled_eventCount = ghost_clfRequestFulfilled_eventCount + 1;
}

/// @notice hook onto emitted events and increment relevant ghosts
hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == InvalidChainSelectorEvent()) ghost_invalidChainSelector_eventCount = ghost_invalidChainSelector_eventCount + 1;
    if (t0 == InvalidProtocolIdEvent()) ghost_invalidProtocolId_eventCount = ghost_invalidProtocolId_eventCount + 1;
}

/// @notice hook onto emitted events and update relevant ghosts
hook LOG2(uint offset, uint length, bytes32 t0, bytes32 t1) {
    if (t0 == UpkeepAddressSetEvent()) {
        ghost_upkeepAddressSet_eventCount = ghost_upkeepAddressSet_eventCount + 1;
        ghost_upkeepAddressSet_emittedAddress = bytes32ToAddress(t1);
    }
    if (t0 == ForwarderSetEvent()) {
        ghost_forwarderSet_eventCount = ghost_forwarderSet_eventCount + 1;
        ghost_forwarderSet_emittedAddress = bytes32ToAddress(t1);
    }
    if (t0 == ParentPeerSetEvent()) {
        ghost_parentPeerSet_eventCount = ghost_parentPeerSet_eventCount + 1;
        ghost_parentPeerSet_emittedAddress = bytes32ToAddress(t1);
    }
    if (t0 == StrategyRegistrySetEvent()) {
        ghost_strategyRegistrySet_eventCount = ghost_strategyRegistrySet_eventCount + 1;
        ghost_strategyRegistrySet_emittedAddress = bytes32ToAddress(t1);
    }
    if (t0 == CLFRequestErrorEvent()) ghost_clfRequestError_eventCount = ghost_clfRequestError_eventCount + 1;
}

/// @notice hook onto emitted events and update relevant ghosts
hook LOG1(uint offset, uint length, bytes32 t0) {
        if (t0 == PausedEvent()) ghost_paused_eventCount = ghost_paused_eventCount + 1;
        if (t0 == UnpausedEvent()) ghost_unpaused_eventCount = ghost_unpaused_eventCount + 1;
}

/*//////////////////////////////////////////////////////////////
                           FUNCTIONS
//////////////////////////////////////////////////////////////*/
function createLog(
    address source, 
    bytes32 eventSignature,
    uint64 newChainSelector, 
    bytes32 protocolId, 
    uint64 oldChainSelector
) returns Rebalancer.Log {
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
    require topics[2] == protocolId;
    require topics[3] == uint64ToBytes32(oldChainSelector);

    return harnessCreateLog(index, timestamp, txHash, blockNumber, blockHash, source, topics, data);
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/

// --- onlyRole reverts --- //
rule onlyRoleConfigAdmin_revertsWhen_notConfigAdmin(method f) 
    filtered {f -> onlyRoleConfigAdmin(f)} 
{
    env e;
    calldataarg args;

    require currentContract.hasRole(configAdminRole(), e.msg.sender) == false;
    require e.msg.value == 0;

    f@withrevert(e, args);
    assert lastReverted;
}

// --- emergencyPause --- //
rule emergencyPause_success() {
    env e;

    require ghost_paused_eventCount == 0;
    require paused() == false;
    require hasRole(emergencyPauserRole(), e.msg.sender) == true;
    require e.msg.value == 0;

    emergencyPause(e);

    assert paused() == true;
    assert ghost_paused_eventCount == 1;
}

rule emergencyPause_revertsWhen_noPauserRole() {
    env e;

    require ghost_paused_eventCount == 0;
    require paused() == false;
    require hasRole(emergencyPauserRole(), e.msg.sender) == false;
    require e.msg.value == 0;

    emergencyPause@withrevert(e);

    assert lastReverted;
    assert paused() == false;
    assert ghost_paused_eventCount == 0;
}

rule emergencyPause_revertsWhen_alreadyPaused {
    env e;

    require ghost_paused_eventCount == 0;
    require paused() == false;
    require hasRole(emergencyPauserRole(), e.msg.sender) == true;
    require e.msg.value == 0;

    emergencyPause(e); /// @dev pause once, then try again
    emergencyPause@withrevert(e);

    assert lastReverted;
    assert paused() == true;
    assert ghost_paused_eventCount == 1; 
}

// --- emergencyUnpase --- //
rule emergencyUnpause_success() {
    env e;

    require ghost_unpaused_eventCount == 0;
    require paused() == true;
    require hasRole(emergencyUnpauserRole(), e.msg.sender) == true;
    require e.msg.value == 0;

    emergencyUnpause(e);

    assert paused() == false;
    assert ghost_unpaused_eventCount == 1;
}

rule emergencyUnpause_revertsWhen_noUnpauserRole() {
    env e;

    require ghost_unpaused_eventCount == 0;
    require paused() == true;
    require hasRole(emergencyUnpauserRole(), e.msg.sender) == false;
    require e.msg.value == 0;

    emergencyUnpause@withrevert(e);

    assert lastReverted;
    assert paused() == true;
    assert ghost_unpaused_eventCount == 0;
}

rule emergencyUnpause_revertsWhen_notPaused() {
    env e;

    require ghost_unpaused_eventCount == 0;
    require paused() == false;
    require hasRole(emergencyUnpauserRole(), e.msg.sender) == true;
    require e.msg.value == 0;

    emergencyUnpause@withrevert(e);

    assert lastReverted;
    assert paused() == false;
    assert ghost_unpaused_eventCount == 0; 
}

// --- getRole --- // 
rule getRoleMember_returns_roleMember() {
    env e;
    address crossChainAdmin1;
    address crossChainAdmin2;
    address crossChainAdmin3;
    address pauser1;
    address pauser2;

    require crossChainAdmin1 != crossChainAdmin2;
    require crossChainAdmin3 != crossChainAdmin1;
    require crossChainAdmin2 != crossChainAdmin3;
    require pauser1 != pauser2;

    require getRoleMemberCount(crossChainAdminRole()) == 0;
    require getRoleMemberCount(emergencyPauserRole()) == 0;

    require hasRole(crossChainAdminRole(), crossChainAdmin1) == false;
    require hasRole(crossChainAdminRole(), crossChainAdmin2) == false;
    require hasRole(crossChainAdminRole(), crossChainAdmin3) == false;
    require currentContract.s_roleMembers[crossChainAdminRole()]._inner._positions[addressToBytes32(crossChainAdmin1)] == 0;
    require currentContract.s_roleMembers[crossChainAdminRole()]._inner._positions[addressToBytes32(crossChainAdmin2)] == 0;
    require currentContract.s_roleMembers[crossChainAdminRole()]._inner._positions[addressToBytes32(crossChainAdmin3)] == 0; 

    require hasRole(emergencyPauserRole(), pauser1) == false;
    require hasRole(emergencyPauserRole(), pauser2) == false;
    require currentContract.s_roleMembers[emergencyPauserRole()]._inner._positions[addressToBytes32(pauser1)] == 0;
    require currentContract.s_roleMembers[emergencyPauserRole()]._inner._positions[addressToBytes32(pauser2)] == 0;

    grantRole(e, crossChainAdminRole(), crossChainAdmin1);
    grantRole(e, crossChainAdminRole(), crossChainAdmin2);
    grantRole(e, crossChainAdminRole(), crossChainAdmin3);
    grantRole(e, emergencyPauserRole(), pauser1);    
    grantRole(e, emergencyPauserRole(), pauser2);

    assert getRoleMember(crossChainAdminRole(), 0) == crossChainAdmin1;
    assert getRoleMember(crossChainAdminRole(), 1) == crossChainAdmin2;
    assert getRoleMember(crossChainAdminRole(), 2) == crossChainAdmin3;
    assert getRoleMember(emergencyPauserRole(), 0) == pauser1;
    assert getRoleMember(emergencyPauserRole(), 1) == pauser2;
}

rule getRoleMemberCount_returns_roleMemberCount() {
    env e;
    /// @dev we are adding a random assortment of role users to test numbers
    address configAdmin;
    address crossChainAdmin1;
    address crossChainAdmin2;
    address crossChainAdmin3;
    address pauser1;
    address pauser2;
    address unpauser1;
    address unpauser2;
    address feeSetter;
    address feeWithdrawer;

    require crossChainAdmin1 != crossChainAdmin2;
    require crossChainAdmin3 != crossChainAdmin1;
    require crossChainAdmin2 != crossChainAdmin3;
    require pauser1 != pauser2;
    require unpauser1 != unpauser2;

    require getRoleMemberCount(configAdminRole()) == 0;
    require getRoleMemberCount(crossChainAdminRole()) == 0;
    require getRoleMemberCount(emergencyPauserRole()) == 0;
    require getRoleMemberCount(emergencyUnpauserRole()) == 0;
    require getRoleMemberCount(feeRateSetterRole()) == 0;
    require getRoleMemberCount(feeWithdrawerRole()) == 0;

    // config admin
    require hasRole(configAdminRole(), configAdmin) == false;
    require currentContract.s_roleMembers[configAdminRole()]._inner._positions[addressToBytes32(configAdmin)] == 0;
    // cross chain admin
    require hasRole(crossChainAdminRole(), crossChainAdmin1) == false;
    require hasRole(crossChainAdminRole(), crossChainAdmin2) == false;
    require hasRole(crossChainAdminRole(), crossChainAdmin3) == false;
    require currentContract.s_roleMembers[crossChainAdminRole()]._inner._positions[addressToBytes32(crossChainAdmin1)] == 0;
    require currentContract.s_roleMembers[crossChainAdminRole()]._inner._positions[addressToBytes32(crossChainAdmin2)] == 0;
    require currentContract.s_roleMembers[crossChainAdminRole()]._inner._positions[addressToBytes32(crossChainAdmin3)] == 0; 
    // pauser
    require hasRole(emergencyPauserRole(), pauser1) == false;
    require hasRole(emergencyPauserRole(), pauser2) == false;
    require currentContract.s_roleMembers[emergencyPauserRole()]._inner._positions[addressToBytes32(pauser1)] == 0;
    require currentContract.s_roleMembers[emergencyPauserRole()]._inner._positions[addressToBytes32(pauser2)] == 0;
    // unpauser
    require hasRole(emergencyUnpauserRole(), unpauser1) == false;
    require hasRole(emergencyUnpauserRole(), unpauser2) == false;
    require currentContract.s_roleMembers[emergencyUnpauserRole()]._inner._positions[addressToBytes32(unpauser1)] == 0;
    require currentContract.s_roleMembers[emergencyUnpauserRole()]._inner._positions[addressToBytes32(unpauser2)] == 0;
    // fee rate setter
    require hasRole(feeRateSetterRole(), feeSetter) == false;
    require currentContract.s_roleMembers[feeRateSetterRole()]._inner._positions[addressToBytes32(feeSetter)] == 0;
    // fee withdrawer
    require hasRole(feeWithdrawerRole(), feeWithdrawer) == false;
    require currentContract.s_roleMembers[feeWithdrawerRole()]._inner._positions[addressToBytes32(feeWithdrawer)] == 0;

    grantRole(e, configAdminRole(), configAdmin);
    grantRole(e, crossChainAdminRole(), crossChainAdmin1);
    grantRole(e, crossChainAdminRole(), crossChainAdmin2);
    grantRole(e, crossChainAdminRole(), crossChainAdmin3);
    grantRole(e, emergencyPauserRole(), pauser1);    
    grantRole(e, emergencyPauserRole(), pauser2);
    grantRole(e, emergencyUnpauserRole(), unpauser1);    
    grantRole(e, emergencyUnpauserRole(), unpauser2);
    grantRole(e, feeRateSetterRole(), feeSetter);
    grantRole(e, feeWithdrawerRole(), feeWithdrawer);

    assert getRoleMemberCount(configAdminRole()) == 1;
    assert getRoleMemberCount(crossChainAdminRole()) == 3;
    assert getRoleMemberCount(emergencyPauserRole()) == 2;
    assert getRoleMemberCount(emergencyUnpauserRole()) == 2;
    assert getRoleMemberCount(feeRateSetterRole()) == 1;
    assert getRoleMemberCount(feeWithdrawerRole()) == 1;
}

rule getRoleMembers_returns_roleMembers() {
    env e1;
    env e2;
    address pauser1;
    address pauser2;
    address crossChainAdmin1;
    address crossChainAdmin2;

    require pauser1 != pauser2;
    require crossChainAdmin1 != crossChainAdmin2;

    require getRoleMemberCount(emergencyPauserRole()) == 0;
    require getRoleMemberCount(crossChainAdminRole()) == 0;

    require hasRole(emergencyPauserRole(), pauser1) == false;
    require hasRole(emergencyPauserRole(), pauser2) == false;
    require hasRole(crossChainAdminRole(), crossChainAdmin1) == false;
    require hasRole(crossChainAdminRole(), crossChainAdmin2) == false;
     
    require currentContract.s_roleMembers[emergencyPauserRole()]._inner._positions[addressToBytes32(pauser1)] == 0;
    require currentContract.s_roleMembers[emergencyPauserRole()]._inner._positions[addressToBytes32(pauser2)] == 0;   
    require currentContract.s_roleMembers[crossChainAdminRole()]._inner._positions[addressToBytes32(crossChainAdmin1)] == 0;
    require currentContract.s_roleMembers[crossChainAdminRole()]._inner._positions[addressToBytes32(crossChainAdmin2)] == 0;

    require e2.block.timestamp > e1.block.timestamp;

    grantRole(e1, emergencyPauserRole(), pauser1);
    grantRole(e2, emergencyPauserRole(), pauser2);
    grantRole(e1, crossChainAdminRole(), crossChainAdmin1);
    grantRole(e2, crossChainAdminRole(), crossChainAdmin2);

    address[] actualPauserMembers = getRoleMembers(emergencyPauserRole());
    address[] actualCrossChainMembers = getRoleMembers(crossChainAdminRole());
    assert actualPauserMembers.length == 2;
    assert actualPauserMembers[0] == pauser1;
    assert actualPauserMembers[1] == pauser2;
    assert actualCrossChainMembers.length == 2;
    assert actualCrossChainMembers[0] == crossChainAdmin1;
    assert actualCrossChainMembers[1] == crossChainAdmin2;
}

// --- setters --- //
rule setUpkeepAddress_success() {
    env e;
    address upkeep;

    require ghost_upkeepAddressSet_eventCount == 0;
    require ghost_upkeepAddressSet_emittedAddress == 0;

    setUpkeepAddress(e, upkeep);

    assert ghost_upkeepAddressSet_eventCount == 1;
    assert ghost_upkeepAddressSet_emittedAddress == upkeep;
    assert currentContract.s_upkeepAddress == upkeep;
    assert getUpkeepAddress() == upkeep;
}

rule setForwarder_success() {
    env e;
    address forwarder;

    require ghost_forwarderSet_eventCount == 0;
    require ghost_forwarderSet_emittedAddress == 0;

    setForwarder(e, forwarder);

    assert ghost_forwarderSet_eventCount == 1;
    assert ghost_forwarderSet_emittedAddress == forwarder;
    assert currentContract.s_forwarder == forwarder;
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
    assert currentContract.s_parentPeer == parentPeer;
    assert getParentPeer() == parentPeer;
}

rule setStrategyRegistry() {
    env e;
    address registry;

    require ghost_strategyRegistrySet_eventCount == 0;
    require ghost_strategyRegistrySet_emittedAddress == 0;

    setStrategyRegistry(e, registry);

    assert ghost_strategyRegistrySet_eventCount == 1;
    assert ghost_strategyRegistrySet_emittedAddress == registry;
    assert currentContract.s_strategyRegistry == registry;
    assert getStrategyRegistry() == registry;
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
    bytes32 protocolId;
    require e.msg.value == 0;
    require e.tx.origin == 0 || e.tx.origin == 0x1111111111111111111111111111111111111111;

    Rebalancer.Log log = createLog(
        getParentPeer(),
        StrategyUpdatedEvent(),
        getParentChainSelector(),
        protocolId,
        getParentChainSelector()
    );
    bytes data;

    checkLog@withrevert(e, log, data);
    assert lastReverted;
}

// rule is vacuous
rule checkLog_revertsWhen_wrongEvent() {
    env e;
    bytes32 protocolId;
    uint64 newChainSelector;
    uint64 oldChainSelector;
    require e.tx.origin == 0 || e.tx.origin == 0x1111111111111111111111111111111111111111;
    require newChainSelector == getParentChainSelector() => oldChainSelector != getParentChainSelector();
    require oldChainSelector == getParentChainSelector() => newChainSelector != getParentChainSelector();
    require e.msg.value == 0;

    bytes32 wrongEvent;
    require wrongEvent != StrategyUpdatedEvent();

    Rebalancer.Log log = createLog(
        getParentPeer(),
        wrongEvent,
        newChainSelector,
        protocolId,
        oldChainSelector
    );
    bytes data;

    checkLog@withrevert(e, log, data);
    assert lastReverted;
}

// rule is vacuous
rule checkLog_revertsWhen_wrongSource() {
    env e;
    bytes32 protocolId;
    uint64 newChainSelector;
    uint64 oldChainSelector;
    require newChainSelector == getParentChainSelector() => oldChainSelector != getParentChainSelector();
    require oldChainSelector == getParentChainSelector() => newChainSelector != getParentChainSelector();
    require e.tx.origin == 0 || e.tx.origin == 0x1111111111111111111111111111111111111111;
    require e.msg.value == 0;
    address wrongSource;
    require wrongSource != getParentPeer();

    Rebalancer.Log log = createLog(
        wrongSource,
        StrategyUpdatedEvent(),
        newChainSelector,
        protocolId,
        oldChainSelector
    );
    bytes data;

    checkLog@withrevert(e, log, data);
    assert lastReverted;
}

// rule is vacuous
rule checkLog_returnsTrueWhen_oldStrategyChild() {
    env e;
    bytes32 protocolId;
    uint64 newChainSelector;
    uint64 oldChainSelector;
    require oldChainSelector != getParentChainSelector();

    require e.tx.origin == 0 || e.tx.origin == 0x1111111111111111111111111111111111111111;
    require e.msg.value == 0;

    Rebalancer.Log log = createLog(
        getParentPeer(),
        StrategyUpdatedEvent(),
        newChainSelector,
        protocolId,
        oldChainSelector
    );
    bytes data;

    bool upkeepNeeded = false;
    bytes performData = createEmptyBytes();

    (upkeepNeeded, performData) = checkLog@withrevert(e, log, data);
    assert !lastReverted;
    assert upkeepNeeded;
    assert performData.length > 0;

    address parentPeer;
    IYieldPeer.Strategy strategy;
    IYieldPeer.CcipTxType txType;
    uint64 decodedOldChainSelector;
    address oldStrategyAdapter;
    uint256 totalValue;

    (
    parentPeer,
    strategy,
    txType,
    decodedOldChainSelector,
    oldStrategyAdapter,
    totalValue
    ) = decodePerformData(performData);

    assert parentPeer == getParentPeer();
    assert strategy.chainSelector == newChainSelector;
    assert strategy.protocolId == protocolId;
    assert txType == IYieldPeer.CcipTxType.RebalanceOldStrategy;
    assert decodedOldChainSelector == oldChainSelector;
    assert oldStrategyAdapter == 0;
    assert totalValue == 0;
}

// rule is vacuous
rule checkLog_returnsTrueWhen_oldStrategyParent_newStrategyChild() {
    env e;
    bytes32 protocolId;
    uint64 newChainSelector;
    uint64 oldChainSelector;
    require oldChainSelector == getParentChainSelector();
    require newChainSelector != getParentChainSelector();

    require e.tx.origin == 0 || e.tx.origin == 0x1111111111111111111111111111111111111111;
    require e.msg.value == 0;

    Rebalancer.Log log = createLog(
        getParentPeer(),
        StrategyUpdatedEvent(),
        newChainSelector,
        protocolId,
        oldChainSelector
    );
    bytes data;

    bool upkeepNeeded = false;
    bytes performData = createEmptyBytes();

    (upkeepNeeded, performData) = checkLog@withrevert(e, log, data);
    assert !lastReverted;
    assert upkeepNeeded;
    assert performData.length > 0;

    address parentPeer;
    IYieldPeer.Strategy strategy;
    IYieldPeer.CcipTxType txType;
    uint64 decodedOldChainSelector;
    address oldStrategyAdapter;
    uint256 totalValue;

    (
    parentPeer,
    strategy,
    txType,
    decodedOldChainSelector,
    oldStrategyAdapter,
    totalValue
    ) = decodePerformData(performData);

    assert parentPeer == getParentPeer();
    assert strategy.chainSelector == newChainSelector;
    assert strategy.protocolId == protocolId;
    assert txType == IYieldPeer.CcipTxType.RebalanceNewStrategy;
    assert decodedOldChainSelector == oldChainSelector;
    assert oldStrategyAdapter == getActiveStrategyAdapterFromParentPeer();
    assert totalValue == getTotalValueFromParentPeer();
}

// --- performUpkeep --- //
rule performUpkeep_revertsWhen_notForwarder() {
    env e;
    uint64 chainSelector;
    bytes32 protocolId;
    IYieldPeer.Strategy strategy = createStrategy(chainSelector, protocolId);
    bytes performData = createPerformData(
        getParentPeer(),
        strategy,
        IYieldPeer.CcipTxType.RebalanceOldStrategy,
        getParentChainSelector(),
        0,
        0
    );

    require e.msg.sender != currentContract.s_forwarder;

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
    bytes32 protocolId;
    IYieldPeer.Strategy strategy = createStrategy(chainSelector, protocolId);
    uint256 totalValue = getTotalValueFromParentPeer();
    bytes performData = createPerformData(
        getParentPeer(),
        strategy,
        IYieldPeer.CcipTxType.RebalanceNewStrategy,
        getParentChainSelector(),
        getActiveStrategyAdapterFromParentPeer(),
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
    bytes32 protocolId;
    IYieldPeer.Strategy strategy = createStrategy(chainSelector, protocolId);
    bytes performData = createPerformData(
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

/*//////////////////////////////////////////////////////////////
                              CLF
//////////////////////////////////////////////////////////////*/
// --- sendCLFRequest --- //
rule sendCLFRequest_revertsWhen_notUpkeep() {
    env e;
    require e.msg.sender != currentContract.s_upkeepAddress, 
        "sendCLFRequest should always revert if the caller is not the upkeep address";

    sendCLFRequest@withrevert(e);
    assert lastReverted;
}

rule sendCLFRequest_revertsWhen_paused() {
    env e;

    require ghost_clfRequestFulfilled_eventCount == 0;
    require paused() == true;
    require e.msg.sender == currentContract.s_upkeepAddress;

    sendCLFRequest@withrevert(e);

    assert lastReverted;
    assert ghost_clfRequestFulfilled_eventCount == 0;
}

// --- fulfillRequest --- //
rule fulfillRequest_returnsWhen_error() {
    env e;
    bytes32 requestId;
    bytes response;
    bytes err;
    
    require err.length > 0,
        "fulfillRequest should always return if CLF returns an error";
    
    require ghost_clfRequestError_eventCount == 0 &&
        ghost_clfRequestFulfilled_eventCount == 0 &&
        ghost_invalidChainSelector_eventCount == 0 &&
        ghost_invalidProtocolId_eventCount == 0,
        "event counts should be 0 before calling fulfillRequest";

    handleOracleFulfillment(e, requestId, response, err);

    assert ghost_clfRequestError_eventCount == 1;
    assert ghost_clfRequestFulfilled_eventCount == 0;
    assert ghost_invalidChainSelector_eventCount == 0;
    assert ghost_invalidProtocolId_eventCount == 0;
}

rule fulfillRequest_returnsWhen_invalidChainSelector() {
    env e;
    bytes32 requestId;
    bytes response;
    bytes err;
    uint64 chainSelector;
    bytes32 protocolId;

    require err.length == 0, "error should be empty when CLF returns a valid response";
    require !parent.getAllowedChain(chainSelector), "fulfillRequest should always return if the chain selector is not allowed";

    require ghost_clfRequestError_eventCount == 0 &&
        ghost_clfRequestFulfilled_eventCount == 0 &&
        ghost_invalidChainSelector_eventCount == 0 &&
        ghost_invalidProtocolId_eventCount == 0,
        "event counts should be 0 before calling fulfillRequest";

    response = createCLFResponse(chainSelector, protocolId);
    handleOracleFulfillment(e, requestId, response, err);

    assert ghost_clfRequestError_eventCount == 0;
    assert ghost_clfRequestFulfilled_eventCount == 0;
    assert ghost_invalidChainSelector_eventCount == 1;
    assert ghost_invalidProtocolId_eventCount == 0;
}

rule fulfillRequest_returnsWhen_invalidProtocolId() {
    env e;
    bytes32 requestId;
    bytes response;
    bytes err;
    uint64 chainSelector;
    bytes32 protocolId;

    require err.length == 0, "error should be empty when CLF returns a valid response";
    require parent.getAllowedChain(chainSelector), "chain selector should be allowed";
    require strategyRegistry.getStrategyAdapter(protocolId) == 0, "fulfillRequest should always return if the protocol id is invalid";

    require ghost_clfRequestError_eventCount == 0 &&
        ghost_clfRequestFulfilled_eventCount == 0 &&
        ghost_invalidChainSelector_eventCount == 0 &&
        ghost_invalidProtocolId_eventCount == 0,
        "event counts should be 0 before calling fulfillRequest";

    response = createCLFResponse(chainSelector, protocolId);
    handleOracleFulfillment(e, requestId, response, err);

    assert ghost_clfRequestError_eventCount == 0;
    assert ghost_clfRequestFulfilled_eventCount == 0;
    assert ghost_invalidChainSelector_eventCount == 0;
    assert ghost_invalidProtocolId_eventCount == 1;
}

rule fulfillRequest_success() {
    env e;
    bytes32 requestId;
    bytes response;
    bytes err;
    uint64 chainSelector;
    bytes32 protocolId;

    require err.length == 0, "error should be empty when CLF returns a valid response";
    require parent.getAllowedChain(chainSelector), "chain selector should be allowed";
    require strategyRegistry.getStrategyAdapter(protocolId) != 0, "protocol id should be valid";

    require ghost_clfRequestError_eventCount == 0 &&
        ghost_clfRequestFulfilled_eventCount == 0 &&
        ghost_invalidChainSelector_eventCount == 0 &&
        ghost_invalidProtocolId_eventCount == 0,
        "event counts should be 0 before calling fulfillRequest";

    response = createCLFResponse(chainSelector, protocolId);
    handleOracleFulfillment(e, requestId, response, err);

    assert ghost_clfRequestError_eventCount == 0;
    assert ghost_clfRequestFulfilled_eventCount == 1;
    assert ghost_invalidChainSelector_eventCount == 0;
    assert ghost_invalidProtocolId_eventCount == 0;

    assert getStrategyFromParentPeer().protocolId == protocolId;
    assert getStrategyFromParentPeer().chainSelector == chainSelector;
}

rule fulfillRequest_revertsWhen_notFunctionsRouter() {
    env e;
    calldataarg args;
    require e.msg.sender != currentContract.i_functionsRouter, 
        "fulfillRequest should always revert if the caller is not the functions router";

    handleOracleFulfillment@withrevert(e, args);
    assert lastReverted;
}