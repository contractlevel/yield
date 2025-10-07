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
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
/// @notice functions that can only be called by the owner
definition onlyOwner(method f) returns bool = 
    f.selector == sig:setAllowedChain(uint64,bool).selector ||
    f.selector == sig:setAllowedPeer(uint64,address).selector ||
    f.selector == sig:setCCIPGasLimit(uint256).selector ||
    f.selector == sig:setStrategyRegistry(address).selector;

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
rule withdrawFees_revertsWhen_notOwner() {
    env e;
    calldataarg args;

    require e.msg.sender != currentContract._owner;

    withdrawFees@withrevert(e, args);
    assert lastReverted;
}

rule withdrawFees_revertsWhen_noFeesToWithdraw() {
    env e;
    address feeToken;
    require feeToken.balanceOf(e, currentContract) == 0;

    withdrawFees@withrevert(e, feeToken);
    assert lastReverted;
}

rule withdrawFees_success() {
    env e;
    address feeToken;

    uint256 ownerBalanceBefore = feeToken.balanceOf(e, currentContract._owner);
    uint256 fees = feeToken.balanceOf(e, currentContract);
    require fees > 0;
    require ownerBalanceBefore + fees <= max_uint256;
    require currentContract != currentContract._owner;

    /// @dev as more stablecoins are added, we will need to update this: feeToken == usdc || feeToken == usdt etc
    require feeToken == usdc;

    require ghost_feesWithdrawn_eventCount == 0;
    require ghost_feesWithdrawn_feesWithdrawn_emitted == 0;

    withdrawFees(e, feeToken);

    assert ghost_feesWithdrawn_eventCount == 1;
    assert ghost_feesWithdrawn_feesWithdrawn_emitted == fees;
    assert feeToken.balanceOf(e, currentContract) == 0;
    assert feeToken.balanceOf(e, currentContract._owner) == ownerBalanceBefore + fees;
}

// --- setFeeRate --- //
rule setFeeRate_revertsWhen_notOwner() {
    env e;
    calldataarg args;

    require e.msg.sender != currentContract._owner;

    setFeeRate@withrevert(e, args);
    assert lastReverted;
}

rule setFeeRate_revertsWhen_maxFeeRateExceeded() {
    env e;
    uint256 newFeeRate;
    require newFeeRate > getMaxFeeRate();

    setFeeRate@withrevert(e, newFeeRate);
    assert lastReverted;
}

rule setFeeRate_success() {
    env e;
    uint256 newFeeRate;

    require ghost_feeRateSet_eventCount == 0;
    require ghost_feeRateSet_feeRate_emitted == 0;

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

// --- onlyOwner setters --- //
rule onlyOwner_setters_revertWhen_notOwner(method f) 
    filtered {f -> onlyOwner(f)}  {
    env e;
    calldataarg args;

    require e.msg.sender != currentContract._owner;

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
    require e.msg.sender == currentContract._owner;

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

    setCCIPGasLimit(e, gasLimit);

    assert ghost_ccipGasLimitSet_eventCount == 1;
    assert ghost_ccipGasLimitSet_ccipGasLimit_emitted == gasLimit;
    assert currentContract.s_ccipGasLimit == gasLimit;
}

rule setStrategyRegistry_success() {
    env e;
    address strategyRegistry;

    require ghost_strategyRegistrySet_eventCount == 0;
    require ghost_strategyRegistrySet_strategyRegistry_emitted == 0;
    require currentContract.s_strategyRegistry == 0;
    require strategyRegistry != 0;

    setStrategyRegistry(e, strategyRegistry);

    assert ghost_strategyRegistrySet_eventCount == 1;
    assert ghost_strategyRegistrySet_strategyRegistry_emitted == strategyRegistry;
    assert currentContract.s_strategyRegistry == strategyRegistry;
}