using MockUsdc as usdc;
using MockAToken as aUsdc;
using MockComet as compound;

/// Verification of YieldPeer
/// @author @contractlevel
/// @notice YieldPeer is the abstract base contract for the Parent and Child peer

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    function getAllowedChain(uint64) external returns (bool) envfree;
    function getAllowedPeer(uint64) external returns (address) envfree;
    function getStrategyPool() external returns (address) envfree;
    function getAave() external returns (address) envfree;
    function getCompound() external returns (address) envfree;
    function getThisChainSelector() external returns (uint64) envfree;

    // External methods
    function usdc.balanceOf(address) external returns (uint256) envfree;
    function aUsdc.balanceOf(address) external returns (uint256);
    function compound.balanceOf(address) external returns (uint256);
    
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

definition StrategyPoolUpdatedEvent() returns bytes32 =
// keccak256(abi.encodePacked("StrategyPoolUpdated(address)"))
    to_bytes32(0xe93cbfefd912dc9a1b30a0c2333d11e2bffb32d29ae125c33bbdba59af9e387c);

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

/// @notice track amount of StrategyPoolUpdated event is emitted
ghost mathint ghost_strategyPoolUpdated_eventCount {
    init_state axiom ghost_strategyPoolUpdated_eventCount == 0;
}

/// @notice track amount of DepositToStrategy event is emitted
ghost mathint ghost_depositToStrategy_eventCount {
    init_state axiom ghost_depositToStrategy_eventCount == 0;
}

/// @notice track amount of WithdrawFromStrategy event is emitted
ghost mathint ghost_withdrawFromStrategy_eventCount {
    init_state axiom ghost_withdrawFromStrategy_eventCount == 0;
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
    if (t0 == StrategyPoolUpdatedEvent()) ghost_strategyPoolUpdated_eventCount = ghost_strategyPoolUpdated_eventCount + 1;
}

/*//////////////////////////////////////////////////////////////
                           INVARIANTS
//////////////////////////////////////////////////////////////*/
invariant strategyProtocol_consistency() 
    getStrategyPool() != 0 => getStrategyPool() == getAave() || getStrategyPool() == getCompound();

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule strategyPool_eventConsistency(method f) {
    env e;
    calldataarg args;

    mathint eventCountBefore = ghost_strategyPoolUpdated_eventCount;

    address strategyPoolBefore = getStrategyPool();

    f(e, args);

    assert getStrategyPool() != strategyPoolBefore => ghost_strategyPoolUpdated_eventCount == eventCountBefore + 1;
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
rule handleCCIPRebalanceNewStrategy_emits_StrategyPoolUpdated() {
    env e;
    calldataarg args;

    require ghost_strategyPoolUpdated_eventCount == 0;
    handleCCIPRebalanceNewStrategy(e, args);
    assert ghost_strategyPoolUpdated_eventCount == 1;
}

rule handleCCIPRebalanceNewStrategy_depositsToNewStrategy() {
    env e;
    uint8 protocolEnum;
    bytes strategyData = encodeStrategy(getThisChainSelector(), protocolEnum);

    uint256 usdcBalanceBefore = usdc.balanceOf(currentContract);
    mathint depositToStrategy_eventCountBefore = ghost_depositToStrategy_eventCount;

    handleCCIPRebalanceNewStrategy(e, strategyData);

    assert protocolEnum == 0 => getStrategyPool() == getAave();
    assert protocolEnum == 1 => getStrategyPool() == getCompound();

    assert usdcBalanceBefore > 0 && protocolEnum == 0 => aUsdc.balanceOf(e, currentContract) >= usdcBalanceBefore;
    assert usdcBalanceBefore > 0 && protocolEnum == 1 => compound.balanceOf(e, currentContract) >= usdcBalanceBefore;
    assert usdcBalanceBefore > 0 => ghost_depositToStrategy_eventCount == depositToStrategy_eventCountBefore + 1;
}

// --- depositToStrategy --- //
rule depositToStrategy_revertsWhen_invalidStrategyPool() {
    env e;
    address invalidStrategyPool;
    uint256 amount;

    require invalidStrategyPool != getAave() && invalidStrategyPool != getCompound();

    depositToStrategy@withrevert(e, invalidStrategyPool, amount);
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
    address strategyPool;
    uint256 amount;

    depositToStrategy(e, strategyPool, amount);

    assert strategyPool == getAave() => aUsdc.balanceOf(e, currentContract) >= amount;
    assert strategyPool == getCompound() => compound.balanceOf(e, currentContract) >= amount;
}

// --- withdrawFromStrategy --- //
rule withdrawFromStrategy_revertsWhen_invalidStrategyPool() {
    env e;
    address invalidStrategyPool;
    uint256 amount;

    require invalidStrategyPool != getAave() && invalidStrategyPool != getCompound();

    withdrawFromStrategy@withrevert(e, invalidStrategyPool, amount);
    assert lastReverted;
}

rule withdrawFromStrategy_emit_WithdrawFromStrategy() {
    env e;
    calldataarg args;
    require ghost_withdrawFromStrategy_eventCount == 0;
    withdrawFromStrategy(e, args);
    assert ghost_withdrawFromStrategy_eventCount == 1;
}

rule withdrawFromStrategy_withdrawsFromStrategy() {
    env e;
    address strategyPool;
    uint256 amount;

    uint256 aUsdcBalanceBefore = aUsdc.balanceOf(e, currentContract);
    uint256 compoundBalanceBefore = compound.balanceOf(e, currentContract);

    withdrawFromStrategy(e, strategyPool, amount);

    assert strategyPool == getAave() => aUsdc.balanceOf(e, currentContract) == aUsdcBalanceBefore - amount;
    assert strategyPool == getCompound() => compound.balanceOf(e, currentContract) == compoundBalanceBefore - amount;
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

