/// Verification of ParentCLF
/// @author @contractlevel
/// @notice ParentCLF is the Chainlink Functions extension of ParentPeer for the Contract Level Yield system

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    function getAllowedChain(uint64 chainSelector) external returns (bool) envfree;

    /// Harness helper methods
    function createCLFResponse(uint64 chainSelector, uint8 protocolEnum) external returns (bytes memory) envfree;
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
/// @notice functions that can only be called by the owner
definition onlyOwner(method f) returns bool = 
    f.selector == sig:setUpkeepAddress(address).selector ||
    f.selector == sig:setNumberOfProtocols(uint8).selector ||
    f.selector == sig:setAllowedChain(uint64,bool).selector ||
    f.selector == sig:setAllowedPeer(uint64,address).selector ||
    f.selector == sig:setCCIPGasLimit(uint256).selector;

definition CLFRequestErrorEvent() returns bytes32 =
// keccak256(abi.encodePacked("CLFRequestError(bytes32,bytes)"))
    to_bytes32(0x4bb259a91776ab365a90aa2b74bcc616da60d5c6a651a9e55e79c1bae9340818);

definition InvalidChainSelectorEvent() returns bytes32 =
// keccak256(abi.encodePacked("InvalidChainSelector(bytes32,uint64)"))
    to_bytes32(0xcbb1a0175d5d5f83e120c4bcd9d3b172de3d4303caf6d5a3be87fc19472fd108);

definition InvalidProtocolEnumEvent() returns bytes32 =
// keccak256(abi.encodePacked("InvalidProtocolEnum(bytes32,uint8)"))
    to_bytes32(0x8caa888c03854a1029a8338ba08e28156002a44eb9cd4b05cc54c3cfd06a860d);

definition CLFRequestFulfilledEvent() returns bytes32 =
// keccak256(abi.encodePacked("CLFRequestFulfilled(bytes32,uint64,uint8)"))
    to_bytes32(0x7f47906f1ae445cc524f4c4aae1e2e8a12c0ade10b1982e852f2d6fbce7fe32f);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
/// @notice track amount of CLFRequestError event is emitted
persistent ghost mathint ghost_clfRequestError_eventCount {
    init_state axiom ghost_clfRequestError_eventCount == 0;
}

/// @notice track amount of CLFRequestFulfilled event is emitted
persistent ghost mathint ghost_clfRequestFulfilled_eventCount {
    init_state axiom ghost_clfRequestFulfilled_eventCount == 0;
}

/// @notice track amount of InvalidChainSelector event is emitted
persistent ghost mathint ghost_invalidChainSelector_eventCount {
    init_state axiom ghost_invalidChainSelector_eventCount == 0;
}

/// @notice track amount of InvalidProtocolEnum event is emitted
persistent ghost mathint ghost_invalidProtocolEnum_eventCount {
    init_state axiom ghost_invalidProtocolEnum_eventCount == 0;
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// @notice hook onto emitted events and increment relevant ghosts
hook LOG2(uint offset, uint length, bytes32 t0, bytes32 t1) {
    if (t0 == CLFRequestErrorEvent()) ghost_clfRequestError_eventCount = ghost_clfRequestError_eventCount + 1;
}

/// @notice hook onto emitted events and increment relevant ghosts
hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == InvalidChainSelectorEvent()) ghost_invalidChainSelector_eventCount = ghost_invalidChainSelector_eventCount + 1;
    if (t0 == InvalidProtocolEnumEvent()) ghost_invalidProtocolEnum_eventCount = ghost_invalidProtocolEnum_eventCount + 1;
}

/// @notice hook onto emitted events and increment relevant ghosts
hook LOG4(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2, bytes32 t3) {
    if (t0 == CLFRequestFulfilledEvent()) ghost_clfRequestFulfilled_eventCount = ghost_clfRequestFulfilled_eventCount + 1;
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
// --- onlyOwner --- //
rule onlyOwner_revertsWhen_notOwner(method f) filtered {f -> onlyOwner(f)} {
    env e;
    calldataarg args;
    require e.msg.sender != currentContract._owner, 
        "onlyOwner functions should always revert if the caller is not the owner";
    f@withrevert(e, args);
    assert lastReverted;
}

// --- sendCLFRequest --- //
rule sendCLFRequest_revertsWhen_notUpkeep() {
    env e;
    require e.msg.sender != currentContract.s_upkeepAddress, 
        "sendCLFRequest should always revert if the caller is not the upkeep address";

    sendCLFRequest@withrevert(e);
    assert lastReverted;
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
        ghost_invalidProtocolEnum_eventCount == 0,
        "event counts should be 0 before calling fulfillRequest";

    handleOracleFulfillment(e, requestId, response, err);

    assert ghost_clfRequestError_eventCount == 1;
    assert ghost_clfRequestFulfilled_eventCount == 0;
    assert ghost_invalidChainSelector_eventCount == 0;
    assert ghost_invalidProtocolEnum_eventCount == 0;
}

rule fulfillRequest_returnsWhen_invalidChainSelector() {
    env e;
    bytes32 requestId;
    bytes response;
    bytes err;
    uint64 chainSelector;
    uint8 protocolEnum;

    require err.length == 0, "error should be empty when CLF returns a valid response";
    require !getAllowedChain(chainSelector), "fulfillRequest should always return if the chain selector is not allowed";

    require ghost_clfRequestError_eventCount == 0 &&
        ghost_clfRequestFulfilled_eventCount == 0 &&
        ghost_invalidChainSelector_eventCount == 0 &&
        ghost_invalidProtocolEnum_eventCount == 0,
        "event counts should be 0 before calling fulfillRequest";

    response = createCLFResponse(chainSelector, protocolEnum);
    handleOracleFulfillment(e, requestId, response, err);

    assert ghost_clfRequestError_eventCount == 0;
    assert ghost_clfRequestFulfilled_eventCount == 0;
    assert ghost_invalidChainSelector_eventCount == 1;
    assert ghost_invalidProtocolEnum_eventCount == 0;
}

rule fulfillRequest_returnsWhen_invalidProtocolEnum() {
    env e;
    bytes32 requestId;
    bytes response;
    bytes err;
    uint64 chainSelector;
    uint8 protocolEnum;

    require err.length == 0, "error should be empty when CLF returns a valid response";
    require getAllowedChain(chainSelector), "chain selector should be allowed";
    require protocolEnum > currentContract.s_numberOfProtocols, 
        "fulfillRequest should always return if the protocol enum is invalid";

    require ghost_clfRequestError_eventCount == 0 &&
        ghost_clfRequestFulfilled_eventCount == 0 &&
        ghost_invalidChainSelector_eventCount == 0 &&
        ghost_invalidProtocolEnum_eventCount == 0,
        "event counts should be 0 before calling fulfillRequest";

    response = createCLFResponse(chainSelector, protocolEnum);
    handleOracleFulfillment(e, requestId, response, err);

    assert ghost_clfRequestError_eventCount == 0;
    assert ghost_clfRequestFulfilled_eventCount == 0;
    assert ghost_invalidChainSelector_eventCount == 0;
    assert ghost_invalidProtocolEnum_eventCount == 1;
}

rule fulfillRequest_success() {
    env e;
    bytes32 requestId;
    bytes response;
    bytes err;
    uint64 chainSelector;
    uint8 protocolEnum;

    require err.length == 0, "error should be empty when CLF returns a valid response";
    require getAllowedChain(chainSelector), "chain selector should be allowed";
    require protocolEnum <= currentContract.s_numberOfProtocols, "protocol enum should be less than or equal to the number of protocols";

    require ghost_clfRequestError_eventCount == 0 &&
        ghost_clfRequestFulfilled_eventCount == 0 &&
        ghost_invalidChainSelector_eventCount == 0 &&
        ghost_invalidProtocolEnum_eventCount == 0,
        "event counts should be 0 before calling fulfillRequest";

    response = createCLFResponse(chainSelector, protocolEnum);
    handleOracleFulfillment(e, requestId, response, err);

    assert ghost_clfRequestError_eventCount == 0;
    assert ghost_clfRequestFulfilled_eventCount == 1;
    assert ghost_invalidChainSelector_eventCount == 0;
    assert ghost_invalidProtocolEnum_eventCount == 0;

    assert assert_uint8(currentContract.s_strategy.protocol) == protocolEnum;
    assert currentContract.s_strategy.chainSelector == chainSelector;
}

rule fulfillRequest_revertsWhen_notFunctionsRouter() {
    env e;
    calldataarg args;
    require e.msg.sender != currentContract.i_functionsRouter, 
        "fulfillRequest should always revert if the caller is not the functions router";

    handleOracleFulfillment@withrevert(e, args);
    assert lastReverted;
}