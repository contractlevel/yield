/// Verification of StrategyRegistry
/// @author @contractlevel
/// @notice StrategyRegistry stores the strategy adapters for each protocol

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // StrategyRegistry methods
    function setStrategyAdapter(bytes32 protocolId, address strategyAdapter) external;

    // Harness helper methods
    function bytes32ToAddress(bytes32) external returns (address) envfree;
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition StrategyAdapterSetEvent() returns bytes32 =
// keccak256(abi.encodePacked("StrategyAdapterSet(bytes32,address)"))
    to_bytes32(0x8c732d9e4addd27f75a625922373422c6bd97a7563d3120bb58352ed601a8961);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
/// @notice EventCount: track amount StrategyAdapterSet event is emitted
ghost mathint ghost_strategyAdapterSet_eventCount {
    init_state axiom ghost_strategyAdapterSet_eventCount == 0;
}

/// @notice EmittedValue: track protocolId emitted in StrategyAdapterSet event
ghost bytes32 ghost_strategyAdapterSet_emittedProtocolId {
    init_state axiom ghost_strategyAdapterSet_emittedProtocolId == to_bytes32(0);
}

/// @notice EmittedValue: track adapter emitted in StrategyAdapterSet event
ghost address ghost_strategyAdapterSet_emittedAdapter {
    init_state axiom ghost_strategyAdapterSet_emittedAdapter == 0;
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// @notice hook onto emitted events and increment relevant ghosts
hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == StrategyAdapterSetEvent()) {
        ghost_strategyAdapterSet_eventCount = ghost_strategyAdapterSet_eventCount + 1;
        ghost_strategyAdapterSet_emittedProtocolId = t1;
        ghost_strategyAdapterSet_emittedAdapter = bytes32ToAddress(t2);
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule setStrategyAdapter_revertsWhen_notOwner(method f) {
    env e;
    calldataarg args;

    require e.msg.sender != currentContract._owner;

    setStrategyAdapter@withrevert(e, args);
    assert lastReverted;
}

rule setStrategyAdapter_success(method f) {
    env e;
    bytes32 protocolId;
    address strategyAdapter;
    require e.msg.sender                               == currentContract._owner;
    require e.msg.value                                ==            0;
    require ghost_strategyAdapterSet_eventCount        ==            0;
    require ghost_strategyAdapterSet_emittedAdapter    ==            0;

    require       strategyAdapter                      !=            0;
    require                                 protocolId != to_bytes32(0);
    require ghost_strategyAdapterSet_emittedProtocolId == to_bytes32(0);

    setStrategyAdapter@withrevert(e,        protocolId,   strategyAdapter);

    assert  ghost_strategyAdapterSet_emittedAdapter    == strategyAdapter;
    assert  ghost_strategyAdapterSet_emittedProtocolId == protocolId;
    assert  ghost_strategyAdapterSet_eventCount        == 1;
    assert !lastReverted;
}