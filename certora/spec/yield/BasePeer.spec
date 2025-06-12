using Share as share;
using MockUsdc as usdc;
using MockPoolAddressesProvider as addressesProvider;

/// Verification of shared behavior between ChildPeer and ParentPeer
/// @author @contractlevel
/// @notice Peers are entry and exit points for the Contract Level Yield system and are deployed on each chain

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // Peer methods
    function getAllowedChain(uint64) external returns (bool) envfree;
    function getCompound() external returns (address) envfree;
    function getThisChainSelector() external returns (uint64) envfree;

    // External methods
    function share.totalSupply() external returns (uint256) envfree;
    function usdc.balanceOf(address) external returns (uint256) envfree;
    function addressesProvider.getPool() external returns (address) envfree;

    // Harness helper methods
    function encodeUint64(uint64 value) external returns (bytes memory) envfree;
    function bytes32ToUint8(bytes32 value) external returns (uint8) envfree;
    function bytes32ToUint256(bytes32 value) external returns (uint256) envfree;
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
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

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
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
}

/*//////////////////////////////////////////////////////////////
                           INVARIANTS
//////////////////////////////////////////////////////////////*/


/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
// --- deposit --- //
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
    require e.msg.sender != getCompound() && e.msg.sender != addressesProvider.getPool(),
        "msg.sender should not be the compound or aave pool";
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