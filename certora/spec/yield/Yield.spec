using MockUsdc as usdc;
using MockAToken as aUsdc;
using MockComet as compound;
using AaveV3Adapter as aaveV3Adapter;
using CompoundV3Adapter as compoundV3Adapter;

/// Verification of YieldPeer
/// @author @contractlevel
/// @notice YieldPeer is the abstract base contract for the Parent and Child peer

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    function getAllowedChain(uint64) external returns (bool) envfree;
    function getAllowedPeer(uint64) external returns (address) envfree;
    function getActiveStrategyAdapter() external returns (address) envfree;
    function getThisChainSelector() external returns (uint64) envfree;

    // External methods
    function usdc.balanceOf(address) external returns (uint256) envfree;
    function aUsdc.balanceOf(address) external returns (uint256);
    function compound.balanceOf(address) external returns (uint256);

    // Wildcard dispatcher summaries
    function _.withdraw(address,uint256) external => DISPATCHER(true);
    function _.deposit(address,uint256) external => DISPATCHER(true);
    function _.getTotalValue(address) external => DISPATCHER(true);
    
    // Harness helper methods
    function decodeAddress(bytes) external returns (address) envfree;
    function buildEncodedWithdrawData(address,uint256,uint256,uint256,uint64) external returns (bytes) envfree;
    function encodeStrategy(uint64,uint8) external returns (bytes) envfree;
    function encodeUint64(uint64) external returns (bytes) envfree;
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition CCIPMessageReceivedEvent() returns bytes32 =
// keccak256(abi.encodePacked("CCIPMessageReceived(bytes32,uint8,uint64)"))
    to_bytes32(0xcde62365c77ee9372df921a4ee8f4bff64fc3b4cc39417c70fc4a6d358c12f6e);

definition WithdrawCompletedEvent() returns bytes32 =
// keccak256(abi.encodePacked("WithdrawCompleted(address,uint256)"))
    to_bytes32(0x60188009b974c2fa66ee3b916d93f64d6534ea2204e0c466f9784ace689e8e49);     

definition ActiveStrategyAdapterUpdatedEvent() returns bytes32 =
// keccak256(abi.encodePacked("ActiveStrategyAdapterUpdated(address)"))
    to_bytes32(0xebe96b449bfdb3f1ed534cb774b9a9b0954447b489e45e828c81a03fec492cc7);

definition DepositToStrategyEvent() returns bytes32 =
// keccak256(abi.encodePacked("DepositToStrategy(address,uint256)"))
    to_bytes32(0x8125d05f0839eec6c1f6b1674833e01f11ab362bd9c60eb2e3b274fa3b47e4f4);

definition WithdrawFromStrategyEvent() returns bytes32 =
// keccak256(abi.encodePacked("WithdrawFromStrategy(address,uint256)"))
    to_bytes32(0xb28e99afed98b3607aeea074f84c346dc4135d86f35b1c28bc35ab6782e7ce30);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
/// @notice track amount of CCIPMessageReceived event is emitted
ghost mathint ghost_ccipMessageReceived_eventCount {
    init_state axiom ghost_ccipMessageReceived_eventCount == 0;
}

/// @notice track amount of WithdrawCompleted event is emitted
ghost mathint ghost_withdrawCompleted_eventCount {
    init_state axiom ghost_withdrawCompleted_eventCount == 0;
}

/// @notice track amount of ActiveStrategyAdapterUpdated event is emitted
ghost mathint ghost_activeStrategyAdapterUpdated_eventCount {
    init_state axiom ghost_activeStrategyAdapterUpdated_eventCount == 0;
}

/// @notice track amount of DepositToStrategy event is emitted
ghost mathint ghost_depositToStrategy_eventCount {
    init_state axiom ghost_depositToStrategy_eventCount == 0;
}

/// @notice track amount of WithdrawFromStrategy event is emitted
ghost mathint ghost_withdrawFromStrategy_eventCount {
    init_state axiom ghost_withdrawFromStrategy_eventCount == 0;
}

/// @notice track the storage mapping for strategy adapters
ghost mapping(IYieldPeer.Protocol => address) ghost_storage_strategyAdapters {
    init_state axiom forall IYieldPeer.Protocol p. ghost_storage_strategyAdapters[p] == 0;
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// @notice hook onto emitted events and increment relevant ghosts
hook LOG4(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2, bytes32 t3) {
    if (t0 == CCIPMessageReceivedEvent()) ghost_ccipMessageReceived_eventCount = ghost_ccipMessageReceived_eventCount + 1;
}

hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == WithdrawCompletedEvent()) ghost_withdrawCompleted_eventCount = ghost_withdrawCompleted_eventCount + 1;
    if (t0 == DepositToStrategyEvent()) ghost_depositToStrategy_eventCount = ghost_depositToStrategy_eventCount + 1;
    if (t0 == WithdrawFromStrategyEvent()) ghost_withdrawFromStrategy_eventCount = ghost_withdrawFromStrategy_eventCount + 1;
}

hook LOG2(uint offset, uint length, bytes32 t0, bytes32 t1) {
    if (t0 == ActiveStrategyAdapterUpdatedEvent())
        ghost_activeStrategyAdapterUpdated_eventCount = ghost_activeStrategyAdapterUpdated_eventCount + 1;
}

hook Sstore s_strategyAdapters[KEY IYieldPeer.Protocol protocol] address newValue (address oldValue) {
    if (newValue != oldValue) 
        ghost_storage_strategyAdapters[protocol] = newValue;
}

/*//////////////////////////////////////////////////////////////
                           INVARIANTS
//////////////////////////////////////////////////////////////*/
// invariant strategyAdapter_consistency() 
//     getActiveStrategyAdapter() != 0 =>
//         ghost_storage_strategyAdapters[IYieldPeer.Protocol.Aave]     == getActiveStrategyAdapter()
//     ||  ghost_storage_strategyAdapters[IYieldPeer.Protocol.Compound] == getActiveStrategyAdapter();

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule strategyAdapter_eventConsistency(method f) {
    env e;
    calldataarg args;

    mathint eventCountBefore = ghost_activeStrategyAdapterUpdated_eventCount;

    address strategyAdapterBefore = getActiveStrategyAdapter();

    f(e, args);

    assert getActiveStrategyAdapter() != strategyAdapterBefore => 
        ghost_activeStrategyAdapterUpdated_eventCount == eventCountBefore + 1;
}

// --- ccipReceive --- //
rule ccipReceive_revertsWhen_notAllowedChain() {
    env e;
    Client.Any2EVMMessage message;
    require e.msg.sender == currentContract.i_ccipRouter;
    
    require !getAllowedChain(message.sourceChainSelector),
        "ccipReceive should revert when the chain selector is not allowed";

    ccipReceive@withrevert(e, message);
    assert lastReverted;
}

rule ccipReceive_revertsWhen_notAllowedPeer() {
    env e;
    Client.Any2EVMMessage message;
    require e.msg.sender == currentContract.i_ccipRouter;
    require getAllowedChain(message.sourceChainSelector);

    address invalidPeer = decodeAddress(message.sender);
    require invalidPeer != getAllowedPeer(message.sourceChainSelector),
        "ccipReceive should revert when the peer is not allowed";

    ccipReceive@withrevert(e, message);
    assert lastReverted;
}

rule ccipReceive_emits_CCIPMessageReceived() {
    env e;
    calldataarg args;

    require ghost_ccipMessageReceived_eventCount == 0;
    ccipReceive(e, args);
    assert ghost_ccipMessageReceived_eventCount == 1;
}

// --- handleCCIPWithdrawCallback --- //
rule handleCCIPWithdrawCallback_emits_WithdrawCompleted() {
    env e;
    calldataarg args;

    require ghost_withdrawCompleted_eventCount == 0;
    handleCCIPWithdrawCallback(e, args);
    assert ghost_withdrawCompleted_eventCount == 1;
}

rule handleCCIPWithdrawCallback_sendUsdcToWithdrawer() {
    env e;
    Client.EVMTokenAmount[] tokenAmounts;
    address withdrawer;
    uint256 shareBurnAmount;
    uint256 totalShares;
    uint256 usdcWithdrawAmount;
    uint64 chainSelector;
    bytes withdrawData = buildEncodedWithdrawData(withdrawer, shareBurnAmount, totalShares, usdcWithdrawAmount, chainSelector);

    uint256 withdrawerBalanceBefore = usdc.balanceOf(withdrawer);
    uint256 contractBalanceBefore = usdc.balanceOf(currentContract);

    require withdrawerBalanceBefore + usdcWithdrawAmount <= max_uint256;
    require withdrawer != currentContract;
    require usdc.balanceOf(currentContract) >= usdcWithdrawAmount;

    handleCCIPWithdrawCallback(e, tokenAmounts, withdrawData);

    assert usdc.balanceOf(withdrawer) == withdrawerBalanceBefore + usdcWithdrawAmount;
    assert usdc.balanceOf(currentContract) == contractBalanceBefore - usdcWithdrawAmount;
}

rule handleCCIPWithdrawCallback_revertsWhen_invalidTokenAmounts() {
    env e;
    Client.EVMTokenAmount[] tokenAmounts;
    address withdrawer;
    uint256 shareBurnAmount;
    uint256 totalShares;
    uint256 usdcWithdrawAmount;
    uint64 chainSelector;

    bytes withdrawData = buildEncodedWithdrawData(withdrawer, shareBurnAmount, totalShares, usdcWithdrawAmount, chainSelector);

    require tokenAmounts.length == 0;
    require usdcWithdrawAmount != 0;

    handleCCIPWithdrawCallback@withrevert(e, tokenAmounts, withdrawData);
    assert lastReverted;
}

rule handleCCIPWithdrawCallback_revertsWhen_invalidToken() {
    env e;
    Client.EVMTokenAmount[] tokenAmounts;
    address withdrawer;
    uint256 shareBurnAmount;
    uint256 totalShares;
    uint256 usdcWithdrawAmount;
    uint64 chainSelector;

    bytes withdrawData = buildEncodedWithdrawData(withdrawer, shareBurnAmount, totalShares, usdcWithdrawAmount, chainSelector);

    require usdcWithdrawAmount != 0;
    require tokenAmounts.length == usdcWithdrawAmount;
    require tokenAmounts[0].token != usdc;

    handleCCIPWithdrawCallback@withrevert(e, tokenAmounts, withdrawData);
    assert lastReverted;
}

// --- handleCCIPRebalanceNewStrategy --- //
rule handleCCIPRebalanceNewStrategy_emits_ActiveStrategyAdapterUpdated() {
    env e;
    calldataarg args;

    require ghost_activeStrategyAdapterUpdated_eventCount == 0;
    handleCCIPRebalanceNewStrategy(e, args);
    assert ghost_activeStrategyAdapterUpdated_eventCount == 1;
}

rule handleCCIPRebalanceNewStrategy_depositsToNewStrategy() {
    env e;
    uint8 protocolEnum;
    bytes strategyData = encodeStrategy(getThisChainSelector(), protocolEnum);

    /// @dev require the storage mappings for active strategy adapters to be the correct contracts
    require currentContract.s_strategyAdapters[IYieldPeer.Protocol.Aave]     == aaveV3Adapter;
    require currentContract.s_strategyAdapters[IYieldPeer.Protocol.Compound] == compoundV3Adapter;

    uint256 usdcBalanceBefore = usdc.balanceOf(currentContract);
    mathint depositToStrategy_eventCountBefore = ghost_depositToStrategy_eventCount;

    handleCCIPRebalanceNewStrategy(e, strategyData);

    assert protocolEnum == 0 => getActiveStrategyAdapter() == aaveV3Adapter;
    assert protocolEnum == 1 => getActiveStrategyAdapter() == compoundV3Adapter;

    assert usdcBalanceBefore > 0 && protocolEnum == 0 => aUsdc.balanceOf(e, getActiveStrategyAdapter()) >= usdcBalanceBefore;
    assert usdcBalanceBefore > 0 && protocolEnum == 1 => compound.balanceOf(e, getActiveStrategyAdapter()) >= usdcBalanceBefore;
    assert usdcBalanceBefore > 0 => ghost_depositToStrategy_eventCount == depositToStrategy_eventCountBefore + 1;
}

// --- depositToStrategy --- //
// @review, probably delete
rule depositToStrategy_revertsWhen_invalidStrategyPool() {
    env e;
    address invalidStrategyAdapter;
    uint256 amount;

    require invalidStrategyAdapter != aaveV3Adapter && invalidStrategyAdapter != compoundV3Adapter;

    depositToStrategy@withrevert(e, invalidStrategyAdapter, amount);
    assert lastReverted;
}

rule depositToStrategy_emit_DepositToStrategy() {
    env e;
    calldataarg args;
    require ghost_depositToStrategy_eventCount == 0;
    depositToStrategy(e, args);
    assert ghost_depositToStrategy_eventCount == 1;
}

rule depositToStrategy_depositsToStrategy() {
    env e;
    address strategyAdapter = getActiveStrategyAdapter();
    uint256 amount;

    depositToStrategy(e, strategyAdapter, amount);

    assert strategyAdapter ==     aaveV3Adapter =>    aUsdc.balanceOf(e,     aaveV3Adapter) >= amount;
    assert strategyAdapter == compoundV3Adapter => compound.balanceOf(e, compoundV3Adapter) >= amount;
}

// --- withdrawFromStrategy --- //
// @review, this could be deleted but we will probably need something like this if introducing the invalid protocol enum
// rule withdrawFromStrategy_revertsWhen_invalidStrategyAdapter() {
//     env e;
//     address invalidStrategyAdapter;
//     uint256 amount;

//     require invalidStrategyAdapter != aaveV3Adapter && invalidStrategyAdapter != compoundV3Adapter;

//     withdrawFromStrategy@withrevert(e, invalidStrategyAdapter, amount);
//     assert lastReverted;
// }

rule withdrawFromStrategy_emit_WithdrawFromStrategy() {
    env e;
    calldataarg args;
    require ghost_withdrawFromStrategy_eventCount == 0;
    withdrawFromStrategy(e, args);
    assert ghost_withdrawFromStrategy_eventCount == 1;
}

rule withdrawFromStrategy_withdrawsFromStrategy(env e) {
    address strategyAdapter = getActiveStrategyAdapter();
    uint256 amount;

    uint256 aUsdcBalanceBefore    =    aUsdc.balanceOf(e, strategyAdapter);
    uint256 compoundBalanceBefore = compound.balanceOf(e, strategyAdapter);

    withdrawFromStrategy(   e, strategyAdapter, amount);

    assert strategyAdapter == aaveV3Adapter => 
            aUsdc.balanceOf(e, strategyAdapter) == aUsdcBalanceBefore - amount;
    assert strategyAdapter == compoundV3Adapter => 
         compound.balanceOf(e, strategyAdapter) == compoundBalanceBefore - amount;
}

// --- decodeWithdrawChainSelector --- //
rule decodeWithdrawChainSelector_revertsWhen_chainNotAllowed() {
    env e;
    uint64 chainSelector;
    bytes data = encodeUint64(chainSelector);

    require !getAllowedChain(chainSelector);

    decodeWithdrawChainSelector@withrevert(e, data);
    assert lastReverted;
}

rule decodeWithdrawChainSelector_returns_allowedChainSelector() {
    env e;
    calldataarg args;
    assert getAllowedChain(decodeWithdrawChainSelector(e, args)) || decodeWithdrawChainSelector(e, args) == getThisChainSelector();
}