using Share as share;
using MockUsdc as usdc;

/// Verification of shared behavior between ChildPeer and ParentPeer
/// @author @contractlevel
/// @notice Peers are entry and exit points for the Contract Level Yield system and are deployed on each chain

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // Peer methods
    function getAllowedChain(uint64) external returns (bool) envfree;
    function getThisChainSelector() external returns (uint64) envfree;
    function getActiveStrategyAdapter() external returns (address) envfree;
    function getMaxFeeRate() external returns (uint256) envfree;
    
    // PausableWithAccessControl methods
    function owner() external returns (address) envfree;
    function paused() external returns (bool) envfree;  
    function hasRole(bytes32, address) external returns (bool) envfree;
    function getRoleMember(bytes32, uint256) external returns (address) envfree;
    function getRoleMemberCount(bytes32) external returns (uint256) envfree;
    function getRoleMembers(bytes32) external returns (address[] memory) envfree;

    // External methods
    function share.totalSupply() external returns (uint256) envfree;
    function usdc.balanceOf(address) external returns (uint256) envfree;

    // Wildcard dispatcher summaries
    function _.balanceOf(address) external => DISPATCHER(true);
    function _.transfer(address,uint256) external => DISPATCHER(true);

    // Harness helper methods
    function encodeUint64(uint64 value) external returns (bytes memory) envfree;
    function bytes32ToUint8(bytes32 value) external returns (uint8) envfree;
    function bytes32ToUint256(bytes32 value) external returns (uint256) envfree;
    function calculateFee(uint256) external returns (uint256) envfree;
    function bytes32ToUint64(bytes32 value) external returns (uint64) envfree;
    function bytes32ToBool(bytes32 value) external returns (bool) envfree;
    function bytes32ToAddress(bytes32 value) external returns (address) envfree;
    function addressToBytes32(address value) external returns (bytes32) envfree;
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
/// @notice functions that can only be called by the cross chain admin
definition onlyRoleCrossChainAdmin(method f) returns bool = 
    f.selector == sig:setAllowedChain(uint64,bool).selector ||
    f.selector == sig:setAllowedPeer(uint64,address).selector ||
    f.selector == sig:setCCIPGasLimit(uint256).selector;

/// @notice functions that can only be called by the config admin
definition onlyRoleConfigAdmin(method f) returns bool = 
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

definition WithdrawInitiatedEvent() returns bytes32 =
// keccak256(abi.encodePacked("WithdrawInitiated(address,uint256,uint64)"))
    to_bytes32(0x071730c3ee1a890531b67cec0adad1806a898c172618e7da6b2f77205b17ab0f);

definition SharesBurnedEvent() returns bytes32 =
// keccak256(abi.encodePacked("SharesBurned(address,uint256)"))
    to_bytes32(0xdb79cc492679ef2624944d6ed3cdbad5b974b5550de330ae18922f2944eec78a);

definition CCIPMessageSentEvent() returns bytes32 =
// keccak256(abi.encodePacked("CCIPMessageSent(bytes32,uint8,uint256)"))
    to_bytes32(0xf58bb6f6ec82990ff728621d18279c43cae3bc9777d052ed0d2316669e58cee6);

definition DepositInitiatedEvent() returns bytes32 =
// keccak256(abi.encodePacked("DepositInitiated(address,uint256,uint64)"))
    to_bytes32(0xaa9f6c1bc844ba1793f5ed5d61d1dd6688efd3d0759386f21c10d07b2f8bdd27);

definition SharesMintedEvent() returns bytes32 =
// keccak256(abi.encodePacked("SharesMinted(address,uint256)"))
    to_bytes32(0x6332ddaa8a69b5eb2524ec7ca317b7c2b01ecf678d584031415f81270977b8fc);

definition WithdrawCompletedEvent() returns bytes32 =
// keccak256(abi.encodePacked("WithdrawCompleted(address,uint256)"))
    to_bytes32(0x60188009b974c2fa66ee3b916d93f64d6534ea2204e0c466f9784ace689e8e49);

definition FeeRateSetEvent() returns bytes32 =
// keccak256(abi.encodePacked("FeeRateSet(uint256)"))
    to_bytes32(0x45398c451b1a31b88dbaed4e7b89a632f43cc4b50149d437db03a5300afe40d1);

definition FeeTakenEvent() returns bytes32 =
// keccak256(abi.encodePacked("FeeTaken(uint256)"))
    to_bytes32(0x28ecfa9863ff521e372e36eca8b2401df92e9ed1deb428d178c53b727eb9b3cf);

definition FeesWithdrawnEvent() returns bytes32 =
// keccak256(abi.encodePacked("FeesWithdrawn(uint256)"))
    to_bytes32(0x9800e6f57aeb4360eaa72295a820a4293e1e66fbfcabcd8874ae141304a76deb);

definition AllowedChainSetEvent() returns bytes32 =
// keccak256(abi.encodePacked("AllowedChainSet(uint64,bool)"))
    to_bytes32(0x42495b3125ef4e9597e7a2b5e95801bd4f99bd0303d24b38cbf449046b89281c);

definition AllowedPeerSetEvent() returns bytes32 =
// keccak256(abi.encodePacked("AllowedPeerSet(uint64,address)"))
    to_bytes32(0x14e51845b92c487641d948a073f73a08c932e03f3db5f1e1d0b4fd802dbe9d4f);

definition CCIPGasLimitSetEvent() returns bytes32 =
// keccak256(abi.encodePacked("CCIPGasLimitSet(uint256)"))
    to_bytes32(0x3b4d93bc2f3cc141ff9b9f3e05fad12abe4166256b2c3ee960e3a5f3f79480e8);

definition StrategyRegistrySetEvent() returns bytes32 =
// keccak256(abi.encodePacked("StrategyRegistrySet(address)"))
    to_bytes32(0xc8f6f976c20221cfca1498913573ed2bc921d8f3c6e4b7d1fcf4d228628bbd10);

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

/// @notice EventCount: track amount of WithdrawInitiated event is emitted
ghost mathint ghost_withdrawInitiated_eventCount {
    init_state axiom ghost_withdrawInitiated_eventCount == 0;
}

/// @notice EventCount: track amount of WithdrawCompleted event is emitted
ghost mathint ghost_withdrawCompleted_eventCount {
    init_state axiom ghost_withdrawCompleted_eventCount == 0;
}

/// @notice EventCount: track amount of SharesBurned event is emitted
ghost mathint ghost_sharesBurned_eventCount {
    init_state axiom ghost_sharesBurned_eventCount == 0;
}

/// @notice EventCount: track amount of SharesMinted event is emitted
ghost mathint ghost_sharesMinted_eventCount {
    init_state axiom ghost_sharesMinted_eventCount == 0;
}

/// @notice EventCount: track amount of DepositInitiated event is emitted
ghost mathint ghost_depositInitiated_eventCount {
    init_state axiom ghost_depositInitiated_eventCount == 0;
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

/// @notice EventCount: track amount of FeeRateSet event is emitted
ghost mathint ghost_feeRateSet_eventCount {
    init_state axiom ghost_feeRateSet_eventCount == 0;
}

/// @notice EmittedValue: track the feeRate emitted by FeeRateSet event
ghost mathint ghost_feeRateSet_feeRate_emitted {
    init_state axiom ghost_feeRateSet_feeRate_emitted == 0;
}

/// @notice EventCount: track amount of FeeTaken event is emitted
ghost mathint ghost_feeTaken_eventCount {
    init_state axiom ghost_feeTaken_eventCount == 0;
}

/// @notice EmittedValue: track the fee emitted by FeeTaken event
ghost mathint ghost_feeTaken_fee_emitted {
    init_state axiom ghost_feeTaken_fee_emitted == 0;
}

/// @notice EventCount: track amount of FeesWithdrawn event is emitted
ghost mathint ghost_feesWithdrawn_eventCount {
    init_state axiom ghost_feesWithdrawn_eventCount == 0;
}

/// @notice EmittedValue: track the feesWithdrawn emitted by FeesWithdrawn event
ghost mathint ghost_feesWithdrawn_feesWithdrawn_emitted {
    init_state axiom ghost_feesWithdrawn_feesWithdrawn_emitted == 0;
}

/// @notice EventCount: track amount of AllowedChainSet event is emitted
ghost mathint ghost_allowedChainSet_eventCount {
    init_state axiom ghost_allowedChainSet_eventCount == 0;
}

/// @notice EmittedValue: track the allowedChain emitted by AllowedChainSet event
ghost mapping(uint64 => bool) ghost_allowedChainSet_allowedChain_emitted {
    init_state axiom forall uint64 chainSelector. ghost_allowedChainSet_allowedChain_emitted[chainSelector] == false;
}

/// @notice EventCount: track amount of AllowedPeerSet event is emitted
ghost mathint ghost_allowedPeerSet_eventCount {
    init_state axiom ghost_allowedPeerSet_eventCount == 0;
}

/// @notice EmittedValue: track the allowedPeer emitted by AllowedPeerSet event
ghost mapping(uint64 => address) ghost_allowedPeerSet_allowedPeer_emitted {
    init_state axiom forall uint64 chainSelector. ghost_allowedPeerSet_allowedPeer_emitted[chainSelector] == 0;
}

/// @notice EventCount: track amount of CCIPGasLimitSet event is emitted
ghost mathint ghost_ccipGasLimitSet_eventCount {
    init_state axiom ghost_ccipGasLimitSet_eventCount == 0;
}

/// @notice EmittedValue: track the ccipGasLimit emitted by CCIPGasLimitSet event
ghost mathint ghost_ccipGasLimitSet_ccipGasLimit_emitted {
    init_state axiom ghost_ccipGasLimitSet_ccipGasLimit_emitted == 0;
}

/// @notice EventCount: track amount of StrategyRegistrySet event is emitted
ghost mathint ghost_strategyRegistrySet_eventCount {
    init_state axiom ghost_strategyRegistrySet_eventCount == 0;
}

/// @notice EmittedValue: track the strategyRegistry emitted by StrategyRegistrySet event
ghost address ghost_strategyRegistrySet_strategyRegistry_emitted {
    init_state axiom ghost_strategyRegistrySet_strategyRegistry_emitted == 0;
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// @notice hook onto emitted events and increment relevant ghosts
hook LOG4(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2, bytes32 t3) {
    if (t0 == WithdrawInitiatedEvent()) ghost_withdrawInitiated_eventCount = ghost_withdrawInitiated_eventCount + 1;
    if (t0 == DepositInitiatedEvent()) ghost_depositInitiated_eventCount = ghost_depositInitiated_eventCount + 1;
    if (t0 == CCIPMessageSentEvent()) { 
        ghost_ccipMessageSent_eventCount = ghost_ccipMessageSent_eventCount + 1;
        ghost_ccipMessageSent_txType_emitted = bytes32ToUint8(t2);
        ghost_ccipMessageSent_bridgeAmount_emitted = bytes32ToUint256(t3);
    }
}

hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == SharesBurnedEvent()) ghost_sharesBurned_eventCount = ghost_sharesBurned_eventCount + 1;
    if (t0 == SharesMintedEvent()) ghost_sharesMinted_eventCount = ghost_sharesMinted_eventCount + 1;
    if (t0 == WithdrawCompletedEvent()) ghost_withdrawCompleted_eventCount = ghost_withdrawCompleted_eventCount + 1;
    if (t0 == AllowedChainSetEvent()) {
        ghost_allowedChainSet_eventCount = ghost_allowedChainSet_eventCount + 1;
        ghost_allowedChainSet_allowedChain_emitted[bytes32ToUint64(t1)] = bytes32ToBool(t2);
    }
    if (t0 == AllowedPeerSetEvent()) {
        ghost_allowedPeerSet_eventCount = ghost_allowedPeerSet_eventCount + 1;
        ghost_allowedPeerSet_allowedPeer_emitted[bytes32ToUint64(t1)] = bytes32ToAddress(t2);
    }
}

hook LOG2(uint offset, uint length, bytes32 t0, bytes32 t1) {
    if (t0 == FeeRateSetEvent()) {
        ghost_feeRateSet_eventCount = ghost_feeRateSet_eventCount + 1;
        ghost_feeRateSet_feeRate_emitted = bytes32ToUint256(t1);
    }
    if (t0 == FeeTakenEvent()) {
        ghost_feeTaken_eventCount = ghost_feeTaken_eventCount + 1;
        ghost_feeTaken_fee_emitted = bytes32ToUint256(t1);
    }
    if (t0 == FeesWithdrawnEvent()) {
        ghost_feesWithdrawn_eventCount = ghost_feesWithdrawn_eventCount + 1;
        ghost_feesWithdrawn_feesWithdrawn_emitted = bytes32ToUint256(t1);
    }
    if (t0 == CCIPGasLimitSetEvent()) {
        ghost_ccipGasLimitSet_eventCount = ghost_ccipGasLimitSet_eventCount + 1;
        ghost_ccipGasLimitSet_ccipGasLimit_emitted = bytes32ToUint256(t1);
    }
    if (t0 == StrategyRegistrySetEvent()) {
        ghost_strategyRegistrySet_eventCount = ghost_strategyRegistrySet_eventCount + 1;
        ghost_strategyRegistrySet_strategyRegistry_emitted = bytes32ToAddress(t1);
    }
}

/// @notice hook onto emitted events and update relevant ghosts
hook LOG1(uint offset, uint length, bytes32 t0) {
        if (t0 == PausedEvent()) ghost_paused_eventCount = ghost_paused_eventCount + 1;
        if (t0 == UnpausedEvent()) ghost_unpaused_eventCount = ghost_unpaused_eventCount + 1;
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
// --- emergency pause --- //
rule emergencyPause_success() {
    env e;

    require ghost_paused_eventCount == 0;
    require paused() == false;
    require hasRole(emergencyPauserRole(), e.msg.sender) == true;
    require e.msg.value == 0;

    emergencyPause@withrevert(e);

    assert !lastReverted;
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

rule emergencyPause_revertsWhen_alreadyPaused() {
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

// --- emergency unpause --- //
rule emergencyUnpause_success() {
    env e;

    require ghost_unpaused_eventCount == 0;
    require paused() == true;
    require hasRole(emergencyUnpauserRole(), e.msg.sender) == true;
    require e.msg.value == 0;

    emergencyUnpause@withrevert(e);

    assert !lastReverted;
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

// @review Rule is vacuous 
rule getRoleMembers_returns_roleMembers() {
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

    address[] actualCrossChainMembers = getRoleMembers(crossChainAdminRole());
    assert actualCrossChainMembers.length == 3;
    assert actualCrossChainMembers[0] == crossChainAdmin1;
    assert actualCrossChainMembers[1] == crossChainAdmin2;
    assert actualCrossChainMembers[2] == crossChainAdmin3;

    address[] actualPauserMembers = getRoleMembers(emergencyPauserRole());
    assert actualPauserMembers.length == 2;
    assert actualPauserMembers[0] == pauser1;
    assert actualPauserMembers[1] == pauser2;
}

// --- deposit --- //
rule deposit_revertsWhen_paused() {
    env e;
    uint256 amountToDeposit;

    require ghost_depositInitiated_eventCount == 0;
    require paused() == true;

    deposit@withrevert(e, amountToDeposit);

    assert lastReverted;
    assert ghost_depositInitiated_eventCount == 0;
}

rule deposit_revertsWhen_zeroAmount() {
    env e;
    uint256 amountToDeposit = 0;
    deposit@withrevert(e, amountToDeposit);
    assert lastReverted;
}

rule deposit_transfersUsdcFromMsgSender() {
    env e;
    uint256 amountToDeposit;
    uint256 balanceBefore = usdc.balanceOf(e.msg.sender);

    require balanceBefore - amountToDeposit >= 0, "should not cause underflow";
    require e.msg.sender != getActiveStrategyAdapter(), "msg.sender should not be the active strategy adapter";
    require e.msg.sender != getActiveStrategyAdapter().getStrategyPool(e), "msg.sender should not be the active strategy pool";
    require e.msg.sender != currentContract, "msg.sender should not be the current contract";

    deposit(e, amountToDeposit);
    assert usdc.balanceOf(e.msg.sender) == balanceBefore - amountToDeposit;
}

rule deposit_emits_DepositInitiated() {
    env e;
    calldataarg args;
    require ghost_depositInitiated_eventCount == 0;
    deposit(e, args);
    assert ghost_depositInitiated_eventCount == 1;
}

// --- onTokenTransfer --- //
rule onTokenTransfer_revertsWhen_paused() {
    env e;
    calldataarg args;
    
    require ghost_withdrawInitiated_eventCount == 0;
    require ghost_sharesBurned_eventCount == 0;
    require paused() == true;

    onTokenTransfer@withrevert(e, args);

    assert lastReverted;
    assert ghost_withdrawInitiated_eventCount == 0;
    assert ghost_sharesBurned_eventCount == 0;
}

rule onTokenTransfer_revertsWhen_msgSenderIsNotShare() {
    env e;
    calldataarg args;
    require e.msg.sender != currentContract.i_share, "msg.sender must be the share token";
    onTokenTransfer@withrevert(e, args);
    assert lastReverted;
}

rule onTokenTransfer_revertsWhen_zeroAmount() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    uint64 chainSelector;
    require e.msg.sender == currentContract.i_share,
        "msg.sender must be the share token";
    require getAllowedChain(chainSelector) || chainSelector == getThisChainSelector(), 
        "withdraw chain selector must be allowed";
    bytes encodedWithdrawChainSelector = encodeUint64(chainSelector);

    require shareBurnAmount == 0, "onTokenTransfer should revert when share burn amount is 0";
    onTokenTransfer@withrevert(e, withdrawer, shareBurnAmount, encodedWithdrawChainSelector); 
    assert lastReverted;
}

rule onTokenTransfer_revertsWhen_chainNotAllowed() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    uint64 chainSelector;
    require e.msg.sender == currentContract.i_share,
        "msg.sender must be the share token";
    require shareBurnAmount > 0, "shareBurnAmount must be greater than 0";
    require !getAllowedChain(chainSelector) && chainSelector != getThisChainSelector(), 
        "onTokenTransfer should revert when chain selector is not allowed";
    bytes encodedWithdrawChainSelector = encodeUint64(chainSelector);
    onTokenTransfer@withrevert(e, withdrawer, shareBurnAmount, encodedWithdrawChainSelector); 
    assert lastReverted;
}

rule onTokenTransfer_emits_WithdrawInitiated_and_SharesBurned() {
    env e;
    calldataarg args;
    require ghost_withdrawInitiated_eventCount == 0;
    require ghost_sharesBurned_eventCount == 0;
    onTokenTransfer(e, args);
    assert ghost_withdrawInitiated_eventCount == 1;
    assert ghost_sharesBurned_eventCount == 1;
}

rule onTokenTransfer_decreases_share_totalSupply() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    bytes encodedWithdrawChainSelector;

    uint256 shareTotalSupplyBefore = share.totalSupply();

    require shareTotalSupplyBefore - shareBurnAmount >= 0, "should not cause underflow";

    onTokenTransfer(e, withdrawer, shareBurnAmount, encodedWithdrawChainSelector);

    assert share.totalSupply() == shareTotalSupplyBefore - shareBurnAmount;
}

// --- withdrawFees --- //
rule withdrawFees_revertsWhen_noFeeWithdrawerRole() {
    env e;
    calldataarg args;

    require hasRole(feeWithdrawerRole(), e.msg.sender) == false;

    withdrawFees@withrevert(e, args);
    assert lastReverted;
}

rule withdrawFees_revertsWhen_noFeesToWithdraw() {
    env e;
    address feeToken;
    require feeToken.balanceOf(e, currentContract) == 0;
    require hasRole(feeWithdrawerRole(), e.msg.sender) == true;

    withdrawFees@withrevert(e, feeToken);
    assert lastReverted;
}

rule withdrawFees_success() {
    env e;
    address feeToken;

    uint256 feeWithdrawerBalanceBefore = feeToken.balanceOf(e, e.msg.sender);
    uint256 fees = feeToken.balanceOf(e, currentContract);
    require fees > 0;
    require feeWithdrawerBalanceBefore + fees <= max_uint256;
    require currentContract != e.msg.sender;
    /// @dev the msg.sender is acting as the fee withdrawer in this scenario 
    require hasRole(feeWithdrawerRole(), e.msg.sender) == true;

    /// @dev as more stablecoins are added, we will need to update this: feeToken == usdc || feeToken == usdt etc
    require feeToken == usdc;

    require ghost_feesWithdrawn_eventCount == 0;
    require ghost_feesWithdrawn_feesWithdrawn_emitted == 0;

    withdrawFees(e, feeToken);

    assert ghost_feesWithdrawn_eventCount == 1;
    assert ghost_feesWithdrawn_feesWithdrawn_emitted == fees;
    assert feeToken.balanceOf(e, currentContract) == 0;
    assert feeToken.balanceOf(e, e.msg.sender) == feeWithdrawerBalanceBefore + fees;
}

// --- setFeeRate --- //
rule setFeeRate_revertsWhen_noFeeRateSetterRole() {
    env e;
    calldataarg args;

    require hasRole(feeRateSetterRole(), e.msg.sender) == false;

    setFeeRate@withrevert(e, args);
    assert lastReverted;
}

rule setFeeRate_revertsWhen_maxFeeRateExceeded() {
    env e;
    uint256 newFeeRate;
    require newFeeRate > getMaxFeeRate();
    require hasRole(feeRateSetterRole(), e.msg.sender) == true;

    setFeeRate@withrevert(e, newFeeRate);
    assert lastReverted;
}

rule setFeeRate_success() {
    env e;
    uint256 newFeeRate;

    require ghost_feeRateSet_eventCount == 0;
    require ghost_feeRateSet_feeRate_emitted == 0;
    require hasRole(feeRateSetterRole(), e.msg.sender) == true;

    setFeeRate(e, newFeeRate);

    assert ghost_feeRateSet_eventCount == 1;
    assert ghost_feeRateSet_feeRate_emitted == newFeeRate;
    assert currentContract.s_feeRate == newFeeRate;
}

// --- deposit takes fees --- //
rule deposit_takesFees_when_feeRate_is_set() {
    env e;
    uint256 amountToDeposit;
    uint256 fee = calculateFee(amountToDeposit);

    uint256 depositorBalanceBefore = usdc.balanceOf(e.msg.sender);
    uint256 contractBalanceBefore = usdc.balanceOf(currentContract);

    require depositorBalanceBefore - amountToDeposit >= 0, "should not cause underflow";
    require contractBalanceBefore + fee <= max_uint256, "should not cause overflow";

    require currentContract.s_feeRate > 0, "deposit should take fee when fee rate is set";

    require e.msg.sender != getActiveStrategyAdapter().getStrategyPool(e), "msg.sender should not be the active strategy pool";
    require e.msg.sender != currentContract, "msg.sender should not be the current contract";

    require ghost_feeTaken_eventCount == 0;
    require ghost_feeTaken_fee_emitted == 0;

    deposit(e, amountToDeposit);

    assert ghost_feeTaken_eventCount == 1;
    assert ghost_feeTaken_fee_emitted == fee;

    assert usdc.balanceOf(e.msg.sender) == depositorBalanceBefore - amountToDeposit;
    assert usdc.balanceOf(currentContract) == contractBalanceBefore + fee;
}

// --- onlyRoleCrossChainAdmin setters --- //
rule onlyRoleCrossChainAdmin_setters_revertWhen_notCrossChainAdmin(method f) 
    filtered {f -> onlyRoleCrossChainAdmin(f)}  {
    env e;
    calldataarg args;

    require hasRole(crossChainAdminRole(), e.msg.sender) == false;

    f@withrevert(e, args);
    assert lastReverted;
}

rule setAllowedChain_success() {
    env e;
    uint64 chainSelector;
    bool isAllowed;

    require ghost_allowedChainSet_eventCount == 0;
    require ghost_allowedChainSet_allowedChain_emitted[chainSelector] == !isAllowed;
    require currentContract.s_allowedChains[chainSelector] == !isAllowed;
    require hasRole(crossChainAdminRole(), e.msg.sender) == true;

    setAllowedChain(e, chainSelector, isAllowed);

    assert currentContract.s_allowedChains[chainSelector] == isAllowed;
    assert ghost_allowedChainSet_eventCount == 1;
    assert ghost_allowedChainSet_allowedChain_emitted[chainSelector] == isAllowed;
}

rule setAllowedPeer_revertsWhen_chainNotAllowed() {
    env e;
    uint64 chainSelector;
    address peer;

    require !getAllowedChain(chainSelector);
    require hasRole(crossChainAdminRole(), e.msg.sender) == true;

    setAllowedPeer@withrevert(e, chainSelector, peer);
    assert lastReverted;
}

rule setAllowedPeer_success() {
    env e;
    uint64 chainSelector;
    address peer;

    require ghost_allowedPeerSet_eventCount == 0;
    require ghost_allowedPeerSet_allowedPeer_emitted[chainSelector] == 0;
    require currentContract.s_peers[chainSelector] == 0;
    require peer != 0;
    require hasRole(crossChainAdminRole(), e.msg.sender) == true;

    setAllowedPeer(e, chainSelector, peer);
    assert ghost_allowedPeerSet_eventCount == 1;
    assert ghost_allowedPeerSet_allowedPeer_emitted[chainSelector] == peer;
    assert currentContract.s_peers[chainSelector] == peer;
}

rule setCCIPGasLimit_success() {
    env e;
    uint256 gasLimit;

    require ghost_ccipGasLimitSet_eventCount == 0;
    require ghost_ccipGasLimitSet_ccipGasLimit_emitted == 0;
    require currentContract.s_ccipGasLimit == 0;
    require gasLimit > 0;
    require hasRole(crossChainAdminRole(), e.msg.sender) == true;

    setCCIPGasLimit(e, gasLimit);

    assert ghost_ccipGasLimitSet_eventCount == 1;
    assert ghost_ccipGasLimitSet_ccipGasLimit_emitted == gasLimit;
    assert currentContract.s_ccipGasLimit == gasLimit;
}

// --- onlyRoleConfigAdmin setters --- //
rule onlyRoleConfigAdmin_setters_revertWhen_notConfigAdmin(method f) 
    filtered {f -> onlyRoleConfigAdmin(f)}  {
    env e;
    calldataarg args;

    require hasRole(configAdminRole(), e.msg.sender) == false;

    f@withrevert(e, args);
    assert lastReverted;
}

rule setStrategyRegistry_success() {
    env e;
    address strategyRegistry;

    require ghost_strategyRegistrySet_eventCount == 0;
    require ghost_strategyRegistrySet_strategyRegistry_emitted == 0;
    require currentContract.s_strategyRegistry == 0;
    require strategyRegistry != 0;
    require hasRole(configAdminRole(), e.msg.sender) == true;

    setStrategyRegistry(e, strategyRegistry);

    assert ghost_strategyRegistrySet_eventCount == 1;
    assert ghost_strategyRegistrySet_strategyRegistry_emitted == strategyRegistry;
    assert currentContract.s_strategyRegistry == strategyRegistry;
}