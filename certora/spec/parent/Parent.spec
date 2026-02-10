using Share as share;
using MockUsdc as usdc;
using AaveV3Adapter as aaveV3Adapter;
using CompoundV3Adapter as compoundV3Adapter;
using StrategyRegistry as strategyRegistry;

/// Verification of ParentPeer
/// @author @contractlevel
/// @notice ParentPeer is the contract that tracks system wide state for the Contract Level Yield system

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // Peer methods
    function getTotalShares() external returns (uint256) envfree;
    function getStrategy() external returns (IYieldPeer.Strategy) envfree;
    function getThisChainSelector() external returns (uint64) envfree;
    function getActiveStrategyAdapter() external returns (address) envfree;
    function getMaxFeeRate() external returns (uint256) envfree;
    function getRebalancer() external returns (address) envfree;
    function paused() external returns (bool) envfree;
    function getAllowedChain(uint64) external returns (bool) envfree;
    function getSupportedProtocol(bytes32) external returns (bool) envfree;

    // PausableWithAccessControl methods
    function owner() external returns (address) envfree;
    function hasRole(bytes32, address) external returns (bool) envfree;

    // External methods
    function share.totalSupply() external returns (uint256) envfree;
    function share.balanceOf(address) external returns (uint256) envfree;
    function usdc.balanceOf(address) external returns (uint256) envfree;
    function strategyRegistry.getStrategyAdapter(bytes32) external returns (address) envfree;

    // Wildcard dispatcher summaries
    function _.withdraw(address, uint256) external => DISPATCHER(true);
    function _.deposit(address, uint256) external => DISPATCHER(true);
    function _.getTotalValue(address) external => DISPATCHER(true);
    function _.balanceOf(address) external => DISPATCHER(true);
    function _.transfer(address, uint256) external => DISPATCHER(true);

    // Harness helper methods
    function bytes32ToAddress(bytes32 value) external returns (address) envfree;
    function bytes32ToUint256(bytes32) external returns (uint256) envfree;
    function bytes32ToUint8(bytes32) external returns (uint8) envfree;
    function buildEncodedWithdrawData(address, uint256, uint256, uint256, uint64) external returns (bytes memory) envfree;
    function encodeUint64(uint64) external returns (bytes memory) envfree;
    function calculateWithdrawAmount(uint256, uint256, uint256) external returns (uint256) envfree;
    function buildEncodedDepositData(address, uint256, uint256, uint256, uint64) external returns (bytes memory) envfree;
    function prepareTokenAmounts(address, uint256) external returns (Client.EVMTokenAmount[] memory) envfree;
    function calculateMintAmount(uint256, uint256) external returns (uint256) envfree;
    function calculateTotalValue(uint256) external returns (uint256);
    function createStrategy(uint64, bytes32) external returns (IYieldPeer.Strategy memory) envfree;
    function convertUsdcToShare(uint256) external returns (uint256) envfree;
    function getStrategyAdapterFromProtocol(bytes32) external returns (address) envfree;
    function calculateFee(uint256) external returns (uint256) envfree;
    function bytes32ToBool(bytes32) external returns (bool) envfree;
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
definition defaultAdminRole() returns bytes32 = to_bytes32(0x00);

definition configAdminRole() returns bytes32 =
// keccak256("CONFIG_ADMIN_ROLE")
to_bytes32(0xb92d52e77ebaa0cae5c23e882d85609efbcb44029214147dd132daf9ef1018af);

definition RebalancerSetEvent() returns bytes32 =
// keccak256(abi.encodePacked("RebalancerSet(address)"))
to_bytes32(0xeaa5fe3125389d5a88065ca297da7e3cce7178e00062a28488efbc1550b9c02c);

definition ShareMintUpdateEvent() returns bytes32 =
// keccak256(abi.encodePacked("ShareMintUpdate(uint256,uint64,uint256)"))
to_bytes32(0xb72631492a31c565f552fa60e02d84a245e98d5519ff22100b4cae30bb5d8465);

definition ShareBurnUpdateEvent() returns bytes32 =
// keccak256(abi.encodePacked("ShareBurnUpdate(uint256,uint64,uint256)"))
to_bytes32(0xf0d8949c30598c33e13bf98c6e616d7feaecf272318c3ba93d9811f5efbcc2b6);

definition SharesMintedEvent() returns bytes32 =
// keccak256(abi.encodePacked("SharesMinted(address,uint256)"))
to_bytes32(0x6332ddaa8a69b5eb2524ec7ca317b7c2b01ecf678d584031415f81270977b8fc);

definition SharesBurnedEvent() returns bytes32 =
// keccak256(abi.encodePacked("SharesBurned(address,uint256)"))
to_bytes32(0xdb79cc492679ef2624944d6ed3cdbad5b974b5550de330ae18922f2944eec78a);

definition CCIPMessageSentEvent() returns bytes32 =
// keccak256(abi.encodePacked("CCIPMessageSent(bytes32,uint8,uint256)"))
to_bytes32(0xf58bb6f6ec82990ff728621d18279c43cae3bc9777d052ed0d2316669e58cee6);

definition WithdrawInitiatedEvent() returns bytes32 =
// keccak256(abi.encodePacked("WithdrawInitiated(address,uint256,uint64)"))
to_bytes32(0x071730c3ee1a890531b67cec0adad1806a898c172618e7da6b2f77205b17ab0f);

definition WithdrawCompletedEvent() returns bytes32 =
// keccak256(abi.encodePacked("WithdrawCompleted(address,uint256)"))
to_bytes32(0x60188009b974c2fa66ee3b916d93f64d6534ea2204e0c466f9784ace689e8e49);

definition DepositForwardedToStrategyEvent() returns bytes32 =
// keccak256(abi.encodePacked("DepositForwardedToStrategy(uint256,uint64)"))
to_bytes32(0xa554b5f1c31b39bc39a68f319912196377a72eb969ff7027278fcd981aa33b27);

definition WithdrawForwardedToStrategyEvent() returns bytes32 =
// keccak256(abi.encodePacked("WithdrawForwardedToStrategy(uint256,uint64)"))
to_bytes32(0x62b63098828571301ff9aea97af7a6df908783e702393e063e1adf27d89605e4);

definition CurrentStrategyOptimalEvent() returns bytes32 =
// keccak256(abi.encodePacked("CurrentStrategyOptimal(uint64,bytes32)"))
to_bytes32(0x8a2bbc9188a750bed30596d0ed7ae5d7b521e02729739c43b6e7106bdfb7e89d);

definition StrategyUpdatedEvent() returns bytes32 =
// keccak256(abi.encodePacked("StrategyUpdated(uint64,bytes32,uint64)"))
to_bytes32(0x60d0790094d9774dbd1ef0d8d0a670010be9595ac41c3215452ac9430a078aa6);

definition WithdrawFromStrategyEvent() returns bytes32 =
// keccak256(abi.encodePacked("WithdrawFromStrategy(address,uint256)"))
to_bytes32(0xb28e99afed98b3607aeea074f84c346dc4135d86f35b1c28bc35ab6782e7ce30);

definition StrategyPoolUpdatedEvent() returns bytes32 =
// keccak256(abi.encodePacked("StrategyPoolUpdated(address)"))
to_bytes32(0xe93cbfefd912dc9a1b30a0c2333d11e2bffb32d29ae125c33bbdba59af9e387c);

definition DepositToStrategyEvent() returns bytes32 =
// keccak256(abi.encodePacked("DepositToStrategy(address,uint256)"))
to_bytes32(0x8125d05f0839eec6c1f6b1674833e01f11ab362bd9c60eb2e3b274fa3b47e4f4);

definition ActiveStrategyAdapterUpdatedEvent() returns bytes32 =
// keccak256(abi.encodePacked("ActiveStrategyAdapterUpdated(address)"))
to_bytes32(0xebe96b449bfdb3f1ed534cb774b9a9b0954447b489e45e828c81a03fec492cc7);

definition DepositPingPongToChildEvent() returns bytes32 =
// keccak256(abi.encodePacked("DepositPingPongToChild(uint256,uint64)"))
to_bytes32(0xd226c55624acdf7dc487bf2d322d07feef128f29f6bb7793e03ba147d84b5c98);

definition WithdrawPingPongToChildEvent() returns bytes32 =
// keccak256(abi.encodePacked("WithdrawPingPongToChild(uint256,uint64)"))
to_bytes32(0xc75e77a40c4dc3a53d5deb9d8fb9d32536847fcc2c9d2d88f1f6f1aed0f71de5);

definition SupportedProtocolSetEvent() returns bytes32 =
// keccak256(abi.encodePacked("SupportedProtocolSet(bytes32,bool)"))
to_bytes32(0x56cc71f639333b7ecd9179fddeb0ecc00bcb82b3f98664a11601a28652604c48);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
/// @notice EventCount: track amount of RebalancerSet event is emitted
ghost mathint ghost_rebalancerSet_eventCount {
    init_state axiom ghost_rebalancerSet_eventCount == 0;
}

/// @notice EmittedValue: track address emitted in RebalancerSet event
ghost address ghost_rebalancerSet_emittedAddress {
    init_state axiom ghost_rebalancerSet_emittedAddress == 0;
}

/// @notice Emitted Value Count: track the total amount of shares minted based on param emitted by ShareMintUpdate event
ghost mathint ghost_shareMintUpdate_totalAmount_emitted {
    init_state axiom ghost_shareMintUpdate_totalAmount_emitted == 0;
}

/// @notice Emitted Value Count: track the amount of shares burned based on param emitted by ShareBurnUpdate event
ghost mathint ghost_shareBurnUpdate_totalAmount_emitted {
    init_state axiom ghost_shareBurnUpdate_totalAmount_emitted == 0;
}

/// @notice EventCount: track amount of ShareMintUpdate event is emitted
ghost mathint ghost_shareMintUpdate_eventCount {
    init_state axiom ghost_shareMintUpdate_eventCount == 0;
}

/// @notice EventCount: track amount of ShareBurnUpdate event is emitted
ghost mathint ghost_shareBurnUpdate_eventCount {
    init_state axiom ghost_shareBurnUpdate_eventCount == 0;
}

/// @notice EventCount: track amount of SharesBurned event is emitted
ghost mathint ghost_sharesBurned_eventCount {
    init_state axiom ghost_sharesBurned_eventCount == 0;
}

/// @notice EventCount: track amount of SharesMinted event is emitted
ghost mathint ghost_sharesMinted_eventCount {
    init_state axiom ghost_sharesMinted_eventCount == 0;
}

/// @notice EventCount: track amount of WithdrawInitiated event is emitted
ghost mathint ghost_withdrawInitiated_eventCount {
    init_state axiom ghost_withdrawInitiated_eventCount == 0;
}

/// @notice EventCount: track amount of WithdrawCompleted event is emitted
ghost mathint ghost_withdrawCompleted_eventCount {
    init_state axiom ghost_withdrawCompleted_eventCount == 0;
}

/// @notice EventCount: track amount of DepositForwardedToStrategy event is emitted
ghost mathint ghost_depositForwardedToStrategy_eventCount {
    init_state axiom ghost_depositForwardedToStrategy_eventCount == 0;
}

/// @notice EventCount: track amount of WithdrawForwardedToStrategy event is emitted
ghost mathint ghost_withdrawForwardedToStrategy_eventCount {
    init_state axiom ghost_withdrawForwardedToStrategy_eventCount == 0;
}

/// @notice EventCount: track amount of CurrentStrategyOptimal event is emitted
ghost mathint ghost_currentStrategyOptimal_eventCount {
    init_state axiom ghost_currentStrategyOptimal_eventCount == 0;
}

/// @notice EventCount: track amount of StrategyUpdated event is emitted
ghost mathint ghost_strategyUpdated_eventCount {
    init_state axiom ghost_strategyUpdated_eventCount == 0;
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

/// @notice EventCount: track amount of WithdrawFromStrategy event is emitted
ghost mathint ghost_withdrawFromStrategy_eventCount {
    init_state axiom ghost_withdrawFromStrategy_eventCount == 0;
}

/// @notice EventCount: track amount of StrategyPoolUpdated event is emitted
ghost mathint ghost_strategyPoolUpdated_eventCount {
    init_state axiom ghost_strategyPoolUpdated_eventCount == 0;
}

/// @notice EventCount: track amount of DepositToStrategy event is emitted
ghost mathint ghost_depositToStrategy_eventCount {
    init_state axiom ghost_depositToStrategy_eventCount == 0;
}

/// @notice EventCount: track amount of ActiveStrategyAdapterUpdated event is emitted
ghost mathint ghost_activeStrategyAdapterUpdated_eventCount {
    init_state axiom ghost_activeStrategyAdapterUpdated_eventCount == 0;
}

/// @notice EventCount: track amount of DepositPingPongToStrategy event is emitted
ghost mathint ghost_depositPingPongToChild_eventCount {
    init_state axiom ghost_depositPingPongToChild_eventCount == 0;
}

/// @notice EventCount: track amount of WithdrawPingPongToStrategy event is emitted
ghost mathint ghost_withdrawPingPongToChild_eventCount {
    init_state axiom ghost_withdrawPingPongToChild_eventCount == 0;
}

/// @notice EventCount: track amount of SupportedProtocolSet event is emitted
ghost mathint ghost_supportedProtocolSet_eventCount {
    init_state axiom ghost_supportedProtocolSet_eventCount == 0;
}

/// @notice EmittedValue: track the protocolId emitted by SupportedProtocolSet event
ghost bytes32 ghost_supportedProtocolSet_emittedProtocolId {
    init_state axiom ghost_supportedProtocolSet_emittedProtocolId == to_bytes32(0);
}

/// @notice EmittedValue: track the isSupported emitted by SupportedProtocolSet event
ghost bool ghost_supportedProtocolSet_emittedIsSupported {
    init_state axiom ghost_supportedProtocolSet_emittedIsSupported == false;
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// @notice hook onto emitted events and increment relevant ghosts
hook LOG4(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2, bytes32 t3) {
    if (t0 == WithdrawInitiatedEvent()) ghost_withdrawInitiated_eventCount = ghost_withdrawInitiated_eventCount + 1;
    if (t0 == ShareMintUpdateEvent()) {
        ghost_shareMintUpdate_eventCount = ghost_shareMintUpdate_eventCount + 1;
        ghost_shareMintUpdate_totalAmount_emitted = ghost_shareMintUpdate_totalAmount_emitted + bytes32ToUint256(t1);
    }
    if (t0 == ShareBurnUpdateEvent()) {
        ghost_shareBurnUpdate_eventCount = ghost_shareBurnUpdate_eventCount + 1;
        ghost_shareBurnUpdate_totalAmount_emitted = ghost_shareBurnUpdate_totalAmount_emitted + bytes32ToUint256(t1);
    }
    if (t0 == CCIPMessageSentEvent()) {
        ghost_ccipMessageSent_eventCount = ghost_ccipMessageSent_eventCount + 1;
        ghost_ccipMessageSent_txType_emitted = bytes32ToUint8(t2);
        ghost_ccipMessageSent_bridgeAmount_emitted = bytes32ToUint256(t3);
    }
    if (t0 == StrategyUpdatedEvent()) ghost_strategyUpdated_eventCount = ghost_strategyUpdated_eventCount + 1;
}

hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == SharesBurnedEvent()) ghost_sharesBurned_eventCount = ghost_sharesBurned_eventCount + 1;
    if (t0 == SharesMintedEvent()) ghost_sharesMinted_eventCount = ghost_sharesMinted_eventCount + 1;
    if (t0 == WithdrawCompletedEvent()) ghost_withdrawCompleted_eventCount = ghost_withdrawCompleted_eventCount + 1;
    if (t0 == DepositForwardedToStrategyEvent()) ghost_depositForwardedToStrategy_eventCount = ghost_depositForwardedToStrategy_eventCount + 1;
    if (t0 == WithdrawForwardedToStrategyEvent()) ghost_withdrawForwardedToStrategy_eventCount = ghost_withdrawForwardedToStrategy_eventCount + 1;
    if (t0 == CurrentStrategyOptimalEvent()) ghost_currentStrategyOptimal_eventCount = ghost_currentStrategyOptimal_eventCount + 1;
    if (t0 == WithdrawFromStrategyEvent()) ghost_withdrawFromStrategy_eventCount = ghost_withdrawFromStrategy_eventCount + 1;
    if (t0 == DepositToStrategyEvent()) ghost_depositToStrategy_eventCount = ghost_depositToStrategy_eventCount + 1;
    if (t0 == DepositPingPongToChildEvent()) ghost_depositPingPongToChild_eventCount = ghost_depositPingPongToChild_eventCount + 1;
    if (t0 == WithdrawPingPongToChildEvent()) ghost_withdrawPingPongToChild_eventCount = ghost_withdrawPingPongToChild_eventCount + 1;
    if (t0 == SupportedProtocolSetEvent()) {
        ghost_supportedProtocolSet_eventCount = ghost_supportedProtocolSet_eventCount + 1;
        ghost_supportedProtocolSet_emittedProtocolId = t1;
        ghost_supportedProtocolSet_emittedIsSupported = bytes32ToBool(t2);
    }
}

hook LOG2(uint offset, uint length, bytes32 t0, bytes32 t1) {
    if (t0 == StrategyPoolUpdatedEvent()) ghost_strategyPoolUpdated_eventCount = ghost_strategyPoolUpdated_eventCount + 1;
    if (t0 == ActiveStrategyAdapterUpdatedEvent()) ghost_activeStrategyAdapterUpdated_eventCount = ghost_activeStrategyAdapterUpdated_eventCount + 1;
    if (t0 == RebalancerSetEvent()) {
        ghost_rebalancerSet_eventCount = ghost_rebalancerSet_eventCount + 1;
        ghost_rebalancerSet_emittedAddress = bytes32ToAddress(t1);
    }
}

/*//////////////////////////////////////////////////////////////
                           INVARIANTS
//////////////////////////////////////////////////////////////*/
invariant totalShares_consistency()
    getTotalShares() == ghost_shareMintUpdate_totalAmount_emitted - ghost_shareBurnUpdate_totalAmount_emitted;

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
// --- deposit --- //
rule deposit_transfersUsdcToStrategy_when_parent_is_strategy() {
    env e;
    uint256 amountToDeposit;
    uint256 fee = calculateFee(amountToDeposit);
    require getStrategy().chainSelector == getThisChainSelector();
    address strategyPool = getActiveStrategyAdapter().getStrategyPool(e);

    uint256 depositorBalanceBefore = usdc.balanceOf(e.msg.sender);
    uint256 strategyPoolBalanceBefore = usdc.balanceOf(strategyPool);

    require strategyPoolBalanceBefore + amountToDeposit <= max_uint256;
    require usdc.balanceOf(currentContract) == 0;
    require e.msg.sender != strategyPool;

    deposit(e, amountToDeposit);

    assert usdc.balanceOf(strategyPool) == strategyPoolBalanceBefore + amountToDeposit - fee;
    assert usdc.balanceOf(e.msg.sender) == depositorBalanceBefore - amountToDeposit;
    assert usdc.balanceOf(currentContract) == fee;
}

rule deposit_mintsShares_when_parent_is_strategy() {
    env e;
    calldataarg args;
    require getStrategy().chainSelector == getThisChainSelector();

    uint256 shareSupplyBefore = share.totalSupply();
    uint256 totalSharesBefore = getTotalShares();

    deposit(e, args);

    assert share.totalSupply() > shareSupplyBefore;
    assert getTotalShares() > totalSharesBefore;
}

rule withdraw_edgecase() {
    env e;
    address user;
    bytes encodedWithdrawChainSelector = encodeUint64(getThisChainSelector());
    require getStrategy().chainSelector == getThisChainSelector();
    require getTotalValue(e) == 100000000000000000002000001;
    require getTotalShares() == 100000000000000000001;
    require share.balanceOf(user) == 1;
    require user != getActiveStrategyAdapter().getStrategyPool(e);

    uint256 balanceBefore = usdc.balanceOf(user);
    require balanceBefore + 1000000 <= max_uint256;

    onTokenTransfer(e, user, 1, encodedWithdrawChainSelector);

    assert usdc.balanceOf(user) == balanceBefore + 1000000;
}

rule deposit_emits_SharesMinted_when_parent_is_strategy() {
    env e;
    calldataarg args;
    require getStrategy().chainSelector == getThisChainSelector();
    require currentContract.s_feeRate == 0;

    require ghost_sharesMinted_eventCount == 0;
    deposit(e, args);
    assert ghost_sharesMinted_eventCount == 1;
}

rule deposit_emits_CCIPMessageSent_when_strategy_is_differentChain() {
    env e;
    uint256 amountToDeposit;
    uint256 fee = calculateFee(amountToDeposit);
    require getStrategy().chainSelector != getThisChainSelector();

    require ghost_ccipMessageSent_eventCount == 0;
    deposit(e, amountToDeposit);
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 1; // DepositToStrategy
    assert ghost_ccipMessageSent_bridgeAmount_emitted == amountToDeposit - fee;
}

rule deposit_reverts_when_parent_is_strategy_and_activeStrategyAdapter_is_zero() {
    env e;
    uint256 amountToDeposit;

    /// @dev revert conditions being verified
    require getStrategy().chainSelector == getThisChainSelector();
    require getActiveStrategyAdapter() == 0;

    /// @dev revert conditions not being verified
    require e.msg.value == 0;
    require amountToDeposit >= 1000000; // 1e6
    require !paused();

    deposit@withrevert(e, amountToDeposit);
    assert lastReverted;
}

// --- onTokenTransfer --- //
rule onTokenTransfer_decreases_totalShares() {
    env e;
    calldataarg args;

    uint256 totalSharesBefore = getTotalShares();

    // s_totalShares is only decreased in onTokenTransfer when parent is the strategy (same-chain withdraw path)
    // Consider how to handle rules for WithdrawCallbackParent
    require getStrategy().chainSelector == getThisChainSelector();
    onTokenTransfer(e, args);

    assert getTotalShares() < totalSharesBefore;
}

// For parentChain == strategyChain
rule onTokenTransfer_emits_SharesBurned_and_ShareBurnUpdate_and_WithdrawInitiated() {
    env e;
    calldataarg args;
    
    require getStrategy().chainSelector == getThisChainSelector();
    require ghost_sharesBurned_eventCount == 0;
    require ghost_shareBurnUpdate_eventCount == 0;
    require ghost_withdrawInitiated_eventCount == 0;

    onTokenTransfer(e, args);

    assert ghost_sharesBurned_eventCount == 1;
    assert ghost_shareBurnUpdate_eventCount == 1;
    assert ghost_withdrawInitiated_eventCount == 1;
}

rule onTokenTransfer_emits_WithdrawCompleted_when_parent_is_strategyChain_and_withdrawChain() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    bytes encodedWithdrawChainSelector = encodeUint64(getThisChainSelector());

    require getStrategy().chainSelector == getThisChainSelector();

    require ghost_withdrawCompleted_eventCount == 0;
    onTokenTransfer(e, withdrawer, shareBurnAmount, encodedWithdrawChainSelector);
    assert ghost_withdrawCompleted_eventCount == 1;
}

rule onTokenTransfer_transfersUsdcToWithdrawer_when_parent_is_strategyChain_and_withdrawChain() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    bytes encodedWithdrawChainSelector = encodeUint64(getThisChainSelector());
    require getStrategy().chainSelector == getThisChainSelector();

    address strategyPool = getActiveStrategyAdapter().getStrategyPool(e);

    uint256 expectedWithdrawAmount = calculateWithdrawAmount(getTotalValue(e), getTotalShares(), shareBurnAmount);
    uint256 usdcBalanceBefore = usdc.balanceOf(withdrawer);
    uint256 strategyPoolBalanceBefore = usdc.balanceOf(strategyPool);

    require strategyPoolBalanceBefore - expectedWithdrawAmount >= 0;

    require expectedWithdrawAmount > 0, "if the shareBurnAmount is worth less than 1 usdc wei, no usdc will be withdrawn (known issue)";
    require usdcBalanceBefore + expectedWithdrawAmount <= max_uint256;
    require withdrawer != strategyPool;

    onTokenTransfer(e, withdrawer, shareBurnAmount, encodedWithdrawChainSelector);

    assert usdc.balanceOf(withdrawer) == usdcBalanceBefore + expectedWithdrawAmount;
    assert usdc.balanceOf(strategyPool) == strategyPoolBalanceBefore - expectedWithdrawAmount;
}

rule onTokenTransfer_emits_CCIPMessageSent_when_strategyChain_is_differentChain() {
    env e;
    calldataarg args;
    require getStrategy().chainSelector != getThisChainSelector();

    require ghost_ccipMessageSent_eventCount == 0;
    onTokenTransfer(e, args);
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 5; // WithdrawToStrategy
    assert ghost_ccipMessageSent_bridgeAmount_emitted == 0;
}

rule onTokenTransfer_reverts_when_parent_is_strategy_and_activeStrategyAdapter_is_zero() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    uint64 withdrawChainSelector;
    bytes encodedWithdrawChainSelector = encodeUint64(withdrawChainSelector);

    /// @dev revert conditions being verified
    require getStrategy().chainSelector == getThisChainSelector();
    require getActiveStrategyAdapter() == 0;

    /// @dev revert conditions not being verified
    require e.msg.value == 0;
    require e.msg.sender == currentContract.i_share;
    require shareBurnAmount > 0;
    require !paused();
    require getAllowedChain(withdrawChainSelector);

    onTokenTransfer@withrevert(e, withdrawer, shareBurnAmount, encodedWithdrawChainSelector);
    assert lastReverted;
}

// --- handleCCIPDepositToParent --- //
rule handleCCIPDepositToParent_depositsToStrategy_when_parent_is_strategy() {
    env e;
    address depositor;
    uint256 usdcDepositAmount;
    uint256 totalValue;
    uint256 shareMintAmount;
    uint64 chainSelector;
    bytes encodedDepositData = buildEncodedDepositData(depositor, usdcDepositAmount, totalValue, shareMintAmount, chainSelector);
    Client.EVMTokenAmount[] tokenAmounts = prepareTokenAmounts(usdc, usdcDepositAmount);

    require getStrategy().chainSelector == getThisChainSelector();
    require usdcDepositAmount > 0;

    address strategyPool = getActiveStrategyAdapter().getStrategyPool(e);
    uint256 strategyPoolBalanceBefore = usdc.balanceOf(strategyPool);
    uint256 usdcBalanceBefore = usdc.balanceOf(currentContract);
    require usdcBalanceBefore >= usdcDepositAmount;

    require strategyPoolBalanceBefore + usdcDepositAmount <= max_uint256;

    handleCCIPDepositToParent(e, tokenAmounts, encodedDepositData);

    assert usdc.balanceOf(strategyPool) == strategyPoolBalanceBefore + usdcDepositAmount;
    assert usdc.balanceOf(currentContract) == usdcBalanceBefore - usdcDepositAmount;
}

rule handleCCIPDepositToParent_updatesTotalShares_when_depositChain_is_strategyChain() {
    env e;
    address depositor;
    uint256 usdcDepositAmount;
    uint256 totalValue; // irrelevant placeholder
    uint256 shareMintAmount; // irrelevant placeholder
    uint64 chainSelector;
    bytes encodedDepositData = buildEncodedDepositData(depositor, usdcDepositAmount, totalValue, shareMintAmount, chainSelector);
    Client.EVMTokenAmount[] tokenAmounts;
    require getStrategy().chainSelector == chainSelector;

    uint256 totalSharesBefore = getTotalShares();

    handleCCIPDepositToParent(e, tokenAmounts, encodedDepositData);

    assert getTotalShares() >= totalSharesBefore;
}

rule handleCCIPDepositToParent_ping_pongs_to_child_when_activeStrategyAdapter_is_zero() {
    env e;
    address depositor;
    uint256 usdcDepositAmount;
    uint256 totalValue;
    uint256 shareMintAmount;
    uint64 chainSelector;
    bytes encodedDepositData = buildEncodedDepositData(depositor, usdcDepositAmount, totalValue, shareMintAmount, chainSelector);
    Client.EVMTokenAmount[] tokenAmounts;

    require getStrategy().chainSelector == getThisChainSelector();
    require getActiveStrategyAdapter() == 0;

    require ghost_depositPingPongToChild_eventCount == 0;
    require ghost_ccipMessageSent_eventCount == 0;

    handleCCIPDepositToParent(e, tokenAmounts, encodedDepositData);
    assert ghost_depositPingPongToChild_eventCount == 1;
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 11; // DepositPingPong
    assert ghost_ccipMessageSent_bridgeAmount_emitted == usdcDepositAmount;
}

rule handleCCIPDepositToParent_forwardsToStrategy() {
    env e;
    address depositor;
    uint256 usdcDepositAmount;
    uint256 totalValue;
    uint256 shareMintAmount;
    uint64 chainSelector;
    bytes encodedDepositData = buildEncodedDepositData(depositor, usdcDepositAmount, totalValue, shareMintAmount, chainSelector);
    Client.EVMTokenAmount[] tokenAmounts;
    require getStrategy().chainSelector != getThisChainSelector();
    require getStrategy().chainSelector != chainSelector;

    require ghost_ccipMessageSent_eventCount == 0;
    require ghost_depositForwardedToStrategy_eventCount == 0;
    handleCCIPDepositToParent(e, tokenAmounts, encodedDepositData);
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 1; // DepositToStrategy
    assert ghost_ccipMessageSent_bridgeAmount_emitted == usdcDepositAmount;
    assert ghost_depositForwardedToStrategy_eventCount == 1;
}

// --- handleCCIPDepositCallbackParent --- //
rule handleCCIPDepositCallbackParent_updatesTotalShares_and_emits_ShareMintUpdate() {
    env e;
    calldataarg args;

    uint256 totalSharesBefore = getTotalShares();

    require ghost_shareMintUpdate_eventCount == 0;
    handleCCIPDepositCallbackParent(e, args);
    assert ghost_shareMintUpdate_eventCount == 1;

    assert getTotalShares() >= totalSharesBefore;
}

rule handleCCIPDepositCallbackParent_mintsShares_when_depositChain_is_parent() {
    env e;
    address depositor;
    uint256 usdcDepositAmount;
    uint256 totalValue;
    uint256 shareMintAmount; // irrelevant placeholder
    uint64 chainSelector;
    bytes encodedDepositData = buildEncodedDepositData(depositor, usdcDepositAmount, totalValue, shareMintAmount, chainSelector);
    Client.EVMTokenAmount[] tokenAmounts;
    require chainSelector == getThisChainSelector();

    uint256 totalSharesBefore = getTotalShares();
    uint256 shareBalanceBefore = share.balanceOf(depositor);
    uint256 expectedShareMintAmount = calculateMintAmount(totalValue, usdcDepositAmount);

    require shareBalanceBefore + expectedShareMintAmount <= max_uint256;

    require ghost_sharesMinted_eventCount == 0;
    handleCCIPDepositCallbackParent(e, encodedDepositData);
    assert ghost_sharesMinted_eventCount == 1;

    assert share.balanceOf(depositor) == shareBalanceBefore + expectedShareMintAmount;
    assert getTotalShares() == totalSharesBefore + expectedShareMintAmount;
}

rule handleCCIPDepositCallbackParent_forwardsCallbackToChild() {
    env e;
    address depositor;
    uint256 usdcDepositAmount;
    uint256 totalValue;
    uint256 shareMintAmount; // irrelevant placeholder
    uint64 chainSelector;
    bytes encodedDepositData = buildEncodedDepositData(depositor, usdcDepositAmount, totalValue, shareMintAmount, chainSelector);
    Client.EVMTokenAmount[] tokenAmounts;
    require chainSelector != getThisChainSelector();

    require ghost_ccipMessageSent_eventCount == 0;
    handleCCIPDepositCallbackParent(e, encodedDepositData);
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 3; // DepositCallbackChild
    assert ghost_ccipMessageSent_bridgeAmount_emitted == 0;
}

// --- handleCCIPWithdrawToParent --- //
rule handleCCIPWithdrawToParent_updatesTotalShares_and_emits_ShareBurnUpdate() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    uint256 totalShares;
    uint256 usdcWithdrawAmount;
    uint64 withdrawChainSelector;
    uint64 sourceChainSelector;
    bytes encodedWithdrawData = buildEncodedWithdrawData(withdrawer, shareBurnAmount, totalShares, usdcWithdrawAmount, withdrawChainSelector);

    uint256 totalSharesBefore = getTotalShares();

    // ShareBurnUpdate is only emitted when parent is strategy and has an active adapter (_handleCCIPWithdraw first branch).
    // When parent is not the strategy, totalShares/ShareBurnUpdate are updated in handleCCIPWithdrawCallbackParent (see that section).
    require getStrategy().chainSelector == getThisChainSelector();
    require getActiveStrategyAdapter() != 0;
    require ghost_shareBurnUpdate_eventCount == 0;
    handleCCIPWithdrawToParent(e, encodedWithdrawData, sourceChainSelector);
    assert ghost_shareBurnUpdate_eventCount == 1;
    assert getTotalShares() == totalSharesBefore - shareBurnAmount;
}

rule handleCCIPWithdrawToParent_withdrawsUsdc_when_parent_is_strategy() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    uint256 totalShares;
    uint256 usdcWithdrawAmount;
    uint64 withdrawChainSelector;
    uint64 sourceChainSelector;
    bytes encodedWithdrawData = buildEncodedWithdrawData(withdrawer, shareBurnAmount, totalShares, usdcWithdrawAmount, withdrawChainSelector);
    require getStrategy().chainSelector == getThisChainSelector();

    uint256 expectedWithdrawAmount = calculateWithdrawAmount(getTotalValue(e), getTotalShares(), shareBurnAmount);

    address strategyPool = getActiveStrategyAdapter().getStrategyPool(e);
    uint256 strategyPoolBalanceBefore = usdc.balanceOf(strategyPool);
    require strategyPoolBalanceBefore - expectedWithdrawAmount >= 0;
    require withdrawer != strategyPool;

    handleCCIPWithdrawToParent(e, encodedWithdrawData, sourceChainSelector);

    assert usdc.balanceOf(strategyPool) == strategyPoolBalanceBefore - expectedWithdrawAmount;
}

rule handleCCIPWithdrawToParent_sendsUsdc_to_withdrawChain_when_parent_is_strategy() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    uint256 totalShares;
    uint256 usdcWithdrawAmount;
    uint64 withdrawChainSelector;
    uint64 sourceChainSelector;
    bytes encodedWithdrawData = buildEncodedWithdrawData(withdrawer, shareBurnAmount, totalShares, usdcWithdrawAmount, withdrawChainSelector);

    require getStrategy().chainSelector == getThisChainSelector();
    require withdrawChainSelector != getThisChainSelector();

    uint256 expectedWithdrawAmount = calculateWithdrawAmount(getTotalValue(e), getTotalShares(), shareBurnAmount);

    require ghost_ccipMessageSent_eventCount == 0;
    handleCCIPWithdrawToParent(e, encodedWithdrawData, sourceChainSelector);
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 6; // WithdrawCallbackChild
    assert ghost_ccipMessageSent_bridgeAmount_emitted == expectedWithdrawAmount;
}

rule handleCCIPWithdrawToParent_forwardsToStrategy() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    uint256 totalShares;
    uint256 usdcWithdrawAmount;
    uint64 withdrawChainSelector;
    uint64 sourceChainSelector;
    bytes encodedWithdrawData = buildEncodedWithdrawData(withdrawer, shareBurnAmount, totalShares, usdcWithdrawAmount, withdrawChainSelector);
    require getStrategy().chainSelector != getThisChainSelector();
    require getStrategy().chainSelector != withdrawChainSelector;

    require ghost_ccipMessageSent_eventCount == 0;
    require ghost_withdrawForwardedToStrategy_eventCount == 0;
    handleCCIPWithdrawToParent(e, encodedWithdrawData, sourceChainSelector);
    assert ghost_withdrawForwardedToStrategy_eventCount == 1;
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 5; // WithdrawToStrategy
    assert ghost_ccipMessageSent_bridgeAmount_emitted == 0;
}

// --- handleCCIPWithdrawCallbackParent --- //
// When parent is NOT the strategy: handleCCIPWithdrawToParent forwards WithdrawToStrategy; the strategy chain
// later sends WithdrawCallbackParent to the parent. Here we verify the parent's handling of that callback:
// always updates s_totalShares and emits ShareBurnUpdate; then either transfers USDC (withdraw chain = parent)
// or forwards WithdrawCallbackChild (withdraw chain = child).
rule handleCCIPWithdrawCallbackParent_updatesTotalShares_and_emits_ShareBurnUpdate() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    uint256 totalShares;
    uint256 usdcWithdrawAmount;
    uint64 withdrawChainSelector;
    bytes encodedWithdrawData = buildEncodedWithdrawData(withdrawer, shareBurnAmount, totalShares, usdcWithdrawAmount, withdrawChainSelector);
    Client.EVMTokenAmount[] tokenAmounts = prepareTokenAmounts(usdc, usdcWithdrawAmount);

    uint256 totalSharesBefore = getTotalShares();

    require ghost_shareBurnUpdate_eventCount == 0;
    handleCCIPWithdrawCallbackParent(e, tokenAmounts, encodedWithdrawData);
    assert ghost_shareBurnUpdate_eventCount == 1;
    assert getTotalShares() == totalSharesBefore - shareBurnAmount;
}

// Current fail with balanceOf havocing 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9ef
rule handleCCIPWithdrawCallbackParent_transfersUsdc_and_emits_WithdrawCompleted_when_withdrawChain_is_parent() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    uint256 totalShares;
    uint256 usdcWithdrawAmount;
    uint64 withdrawChainSelector;
    bytes encodedWithdrawData = buildEncodedWithdrawData(withdrawer, shareBurnAmount, totalShares, usdcWithdrawAmount, withdrawChainSelector);
    Client.EVMTokenAmount[] tokenAmounts = prepareTokenAmounts(usdc, usdcWithdrawAmount);

    require withdrawChainSelector == getThisChainSelector();
    uint256 usdcBalanceBefore = usdc.balanceOf(withdrawer);
    require usdcBalanceBefore + usdcWithdrawAmount <= max_uint256;
    // Simulate Parent holding USDC (as if CCIP had already delivered tokenAmounts to the parent)
    require usdc.balanceOf(currentContract) >= usdcWithdrawAmount;

    require ghost_withdrawCompleted_eventCount == 0;
    handleCCIPWithdrawCallbackParent(e, tokenAmounts, encodedWithdrawData);
    assert ghost_withdrawCompleted_eventCount == 1;
    assert usdc.balanceOf(withdrawer) == usdcBalanceBefore + usdcWithdrawAmount;
}

rule handleCCIPWithdrawCallbackParent_forwardsWithdrawCallbackChild_when_withdrawChain_is_child() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    uint256 totalShares;
    uint256 usdcWithdrawAmount;
    uint64 withdrawChainSelector;
    bytes encodedWithdrawData = buildEncodedWithdrawData(withdrawer, shareBurnAmount, totalShares, usdcWithdrawAmount, withdrawChainSelector);
    Client.EVMTokenAmount[] tokenAmounts = prepareTokenAmounts(usdc, usdcWithdrawAmount);

    require withdrawChainSelector != getThisChainSelector();

    require ghost_ccipMessageSent_eventCount == 0;
    handleCCIPWithdrawCallbackParent(e, tokenAmounts, encodedWithdrawData);
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 6; // WithdrawCallbackChild
    assert ghost_ccipMessageSent_bridgeAmount_emitted == usdcWithdrawAmount;
}

// --- handleCCIPWithdraw & handleCCIPWithdrawPingPong --- //
rule handleCCIPWithdraw_forwardsToStrategy_and_emits_WithdrawPingPongToChild_when_Adapter_is_zero() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    uint256 totalShares;
    uint256 usdcWithdrawAmount;
    uint64 chainSelector;
    bytes encodedWithdrawData = buildEncodedWithdrawData(withdrawer, shareBurnAmount, totalShares, usdcWithdrawAmount, chainSelector);

    require getStrategy().chainSelector == getThisChainSelector();
    require getActiveStrategyAdapter() == 0;

    require ghost_withdrawPingPongToChild_eventCount == 0;
    require ghost_ccipMessageSent_eventCount == 0;
    handleCCIPWithdraw(e, encodedWithdrawData);
    assert ghost_withdrawPingPongToChild_eventCount == 1;
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 12; // WithdrawPingPong
    assert ghost_ccipMessageSent_bridgeAmount_emitted == 0;
}

// --- rebalance --- //
rule rebalance_revertsWhen_notRebalancer() {
    env e;
    uint64 chainSelector;
    bytes32 protocolId;
    IYieldPeer.Strategy newStrategy = createStrategy(chainSelector, protocolId);

    /// @dev revert condition being verified
    require e.msg.sender != currentContract.s_rebalancer;

    /// @dev revert conditions not being verified
    require e.msg.value == 0;
    require newStrategy != getStrategy();
    require getAllowedChain(chainSelector) == true;
    require getSupportedProtocol(protocolId) == true;

    rebalance@withrevert(e, newStrategy);
    assert lastReverted;
}

rule rebalance_revertsWhen_sameStrategy() {
    env e;
    uint64 chainSelector;
    bytes32 protocolId;
    IYieldPeer.Strategy newStrategy = createStrategy(chainSelector, protocolId);

    /// @dev revert condition being verified
    require newStrategy == getStrategy();

    /// @dev revert conditions not being verified
    require e.msg.value == 0;
    require getAllowedChain(chainSelector) == true;
    require getSupportedProtocol(protocolId) == true;
    require e.msg.sender == currentContract.s_rebalancer;

    rebalance@withrevert(e, newStrategy);
    assert lastReverted;
}

rule rebalance_revertsWhen_chainNotAllowed() {
    env e;
    uint64 chainSelector;
    bytes32 protocolId;
    IYieldPeer.Strategy newStrategy = createStrategy(chainSelector, protocolId);

    /// @dev revert condition being verified
    require getAllowedChain(chainSelector) == false;

    /// @dev revert conditions not being verified
    require e.msg.value == 0;
    require getSupportedProtocol(protocolId) == true;
    require e.msg.sender == currentContract.s_rebalancer;
    require newStrategy != getStrategy();

    rebalance@withrevert(e, newStrategy);
    assert lastReverted;
}

rule rebalance_revertsWhen_protocolNotSupported() {
    env e;
    uint64 chainSelector;
    bytes32 protocolId;
    IYieldPeer.Strategy newStrategy = createStrategy(chainSelector, protocolId);

    /// @dev revert condition being verified
    require getSupportedProtocol(protocolId) == false;

    /// @dev revert conditions not being verified
    require e.msg.value == 0;
    require getAllowedChain(chainSelector) == true;
    require e.msg.sender == currentContract.s_rebalancer;
    require newStrategy != getStrategy();

    rebalance@withrevert(e, newStrategy);
    assert lastReverted;
}


rule rebalance_updatesStrategy_when_newStrategy_is_different() {
    env e;
    uint64 chainSelector;
    bytes32 protocolId;
    IYieldPeer.Strategy newStrategy = createStrategy(chainSelector, protocolId);
    IYieldPeer.Strategy oldStrategy = getStrategy();

    require oldStrategy.chainSelector != chainSelector || oldStrategy.protocolId != protocolId;

    require ghost_currentStrategyOptimal_eventCount == 0;
    require ghost_strategyUpdated_eventCount == 0;
    rebalance(e, newStrategy);
    assert ghost_currentStrategyOptimal_eventCount == 0;
    assert ghost_strategyUpdated_eventCount == 1;
    assert getStrategy() != oldStrategy;
}

rule rebalance_handles_rebalanceParentToParent() {
    env e;
    uint64 chainSelector;
    bytes32 protocolId;
    IYieldPeer.Strategy newStrategy = createStrategy(chainSelector, protocolId);
    bytes32 aaveV3ProtocolId;
    bytes32 compoundV3ProtocolId;

    /// @dev require the storage mappings for active strategy adapters to be the correct contracts
    require strategyRegistry.getStrategyAdapter(aaveV3ProtocolId) == aaveV3Adapter;
    require strategyRegistry.getStrategyAdapter(compoundV3ProtocolId) == compoundV3Adapter;

    /// @dev require the storage for active strategy adapter to be aave or compound adapters
    require currentContract.s_activeStrategyAdapter == aaveV3Adapter || currentContract.s_activeStrategyAdapter == compoundV3Adapter;
    address oldActiveStrategyAdapter = getActiveStrategyAdapter();

    /// @dev cache old strategy
    IYieldPeer.Strategy oldStrategy = getStrategy();

    /// @dev require old strategy values to enable local strategy change
    require oldStrategy.chainSelector == chainSelector && oldStrategy.chainSelector == getThisChainSelector() && oldStrategy.protocolId != protocolId;
    require oldActiveStrategyAdapter != getStrategyAdapterFromProtocol(protocolId);

    /// @dev cache total value and require it to be more than 0
    uint256 totalValue = getTotalValue(e);
    require totalValue > 0;

    /// @dev cache old strategy pool and its balance
    address oldStrategyPool = oldActiveStrategyAdapter.getStrategyPool(e);
    uint256 oldStrategyPoolBalanceBefore = usdc.balanceOf(oldStrategyPool);
    require oldStrategyPoolBalanceBefore - totalValue >= 0 && usdc.balanceOf(currentContract) == 0;

    /// @dev if the old active adapter is aave, the new active adapter is compound, and vice versa
    address newActiveStrategyAdapter;
    require oldActiveStrategyAdapter == aaveV3Adapter => newActiveStrategyAdapter == compoundV3Adapter;
    require oldActiveStrategyAdapter == compoundV3Adapter => newActiveStrategyAdapter == aaveV3Adapter;

    /// @dev if the old active adapter is aave, the new protocol id is compound, and vice versa
    require oldActiveStrategyAdapter == aaveV3Adapter => protocolId == compoundV3ProtocolId;
    require oldActiveStrategyAdapter == compoundV3Adapter => protocolId == aaveV3ProtocolId;

    /// @dev cache new strategy pool and its balance
    address newStrategyPool = newActiveStrategyAdapter.getStrategyPool(e);
    uint256 newStrategyPoolBalanceBefore = usdc.balanceOf(newStrategyPool);
    require newStrategyPoolBalanceBefore + totalValue <= max_uint256;

    /// @dev act
    rebalance(e, newStrategy);

    /// @dev assert correct balance changes
    assert usdc.balanceOf(oldStrategyPool) == oldStrategyPoolBalanceBefore - totalValue;
    assert usdc.balanceOf(newStrategyPool) == newStrategyPoolBalanceBefore + totalValue;
}

// @review rule vacuous - was before too
rule rebalance_handles_rebalanceParentToChild() {
    env e;
    uint64 chainSelector;
    bytes32 protocolId;

    IYieldPeer.Strategy oldStrategy = getStrategy();
    IYieldPeer.Strategy newStrategy = createStrategy(chainSelector, protocolId);

    require oldStrategy.chainSelector != chainSelector && oldStrategy.chainSelector == getThisChainSelector();

    uint256 totalValue = getTotalValue(e);
    // totalvalue > 0;
    // Allow totalValue >= 0 so rule is not vacuous when getTotalValue is summarized (e.g. returns 0)
    address strategyPool = getActiveStrategyAdapter().getStrategyPool(e);
    uint256 strategyPoolBalanceBefore = usdc.balanceOf(strategyPool);
    require strategyPoolBalanceBefore - totalValue >= 0;
    require usdc.balanceOf(currentContract) == 0;

    require ghost_ccipMessageSent_eventCount == 0;
    rebalance(e, newStrategy);
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 10; // RebalanceNewStrategy
    assert ghost_ccipMessageSent_bridgeAmount_emitted == totalValue;

    assert usdc.balanceOf(strategyPool) == strategyPoolBalanceBefore - totalValue;
}

rule rebalance_handles_rebalanceChildToOther() {
    env e;
    uint64 chainSelector;
    bytes32 protocolId;

    IYieldPeer.Strategy oldStrategy = getStrategy();

    require oldStrategy.chainSelector != getThisChainSelector() && oldStrategy.chainSelector != chainSelector;

    IYieldPeer.Strategy newStrategy = createStrategy(chainSelector, protocolId);

    require ghost_ccipMessageSent_eventCount == 0;
    rebalance(e, newStrategy);
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 9; // RebalanceOldStrategy (7 is WithdrawCallbackParent)
    assert ghost_ccipMessageSent_bridgeAmount_emitted == 0;
}

// --- calculateMintAmount --- //
rule calculateMintAmount_calculation() {
    uint256 totalValue;
    uint256 depositAmount;
    require depositAmount > 0;
    require totalValue > 0;

    mathint expectedMintAmount = convertUsdcToShare(depositAmount) * currentContract.s_totalShares / convertUsdcToShare(totalValue);
    require expectedMintAmount > 0;

    uint256 actualMintAmount = calculateMintAmount(totalValue, depositAmount);
    require actualMintAmount > 1;

    assert actualMintAmount == assert_uint256(expectedMintAmount);
}

// --- setInitialActiveStrategy --- //
rule setInitialActiveStrategy_revertsWhen_noDefaultAdminRole() {
    env e;
    bytes32 protocolId;

    /// @dev revert condition being verified
    require currentContract.hasRole(defaultAdminRole(), e.msg.sender) == false;

    /// @dev revert conditions not being verified
    require e.msg.value == 0;
    require currentContract.s_initialActiveStrategySet == false;

    setInitialActiveStrategy@withrevert(e, protocolId);
    assert lastReverted;
}

rule setInitialActiveStrategy_revertsWhen_alreadyCalled() {
    env e;
    env e2;
    bytes32 protocolId;
    bytes32 protocolId2;

    require e.msg.sender == currentContract.owner();
    require currentContract.hasRole(defaultAdminRole(), e.msg.sender) == true;
    require e.msg.value == 0;

    setInitialActiveStrategy(e, protocolId); /// @dev set, then try again

    require e2.msg.sender == currentContract.owner();
    require currentContract.hasRole(defaultAdminRole(), e2.msg.sender) == true;
    require e2.msg.value == 0;
    setInitialActiveStrategy@withrevert(e2, protocolId2);

    assert lastReverted;
}

rule setInitialActiveStrategy_emitsEvent() {
    env e;
    bytes32 protocolId;

    require ghost_activeStrategyAdapterUpdated_eventCount == 0;
    setInitialActiveStrategy(e, protocolId);
    assert ghost_activeStrategyAdapterUpdated_eventCount == 1;
}

rule setInitialActiveStrategy_updatesStorage() {
    env e;
    bytes32 protocolId;

    require currentContract.s_activeStrategyAdapter == 0;
    require currentContract.s_strategy.chainSelector == 0;

    setInitialActiveStrategy(e, protocolId);

    assert currentContract.s_activeStrategyAdapter == strategyRegistry.getStrategyAdapter(protocolId);
    assert currentContract.s_strategy.chainSelector == getThisChainSelector();
    assert currentContract.s_strategy.protocolId == protocolId;
}

// --- setRebalancer --- //
rule setRebalancer_revertsWhen_noConfigAdminRole() {
    env e;
    address rebalancer;

    require hasRole(configAdminRole(), e.msg.sender) == false;
    require e.msg.value == 0;

    setRebalancer@withrevert(e, rebalancer);

    assert lastReverted;
}

rule setRebalancer_success() {
    env e;
    address rebalancer;

    require ghost_rebalancerSet_eventCount == 0;
    require ghost_rebalancerSet_emittedAddress == 0;

    setRebalancer(e, rebalancer);

    assert ghost_rebalancerSet_eventCount == 1; /// @dev check rebalancer set event
    assert ghost_rebalancerSet_emittedAddress == rebalancer; /// @dev check rebalancer set event emitted address
    assert currentContract.s_rebalancer == rebalancer; /// @dev check storage variable was updated
    assert getRebalancer() == rebalancer;
}

// --- setSupportedProtocol --- //
rule setSupportedProtocol_revertsWhen_notConfigAdmin() {
    env e;
    calldataarg args;

    require hasRole(configAdminRole(), e.msg.sender) == false;
    require e.msg.value == 0;

    setSupportedProtocol@withrevert(e, args);
    assert lastReverted;
}

rule setSupportedProtocol_success() {
    env e;
    bytes32 protocolId;
    bool isSupported;

    require ghost_supportedProtocolSet_eventCount == 0;
    require ghost_supportedProtocolSet_emittedProtocolId == to_bytes32(0);
    require ghost_supportedProtocolSet_emittedIsSupported == false;
    require currentContract.s_supportedProtocols[protocolId] == !isSupported;

    setSupportedProtocol(e, protocolId, isSupported);
    assert ghost_supportedProtocolSet_eventCount == 1;
    assert ghost_supportedProtocolSet_emittedProtocolId == protocolId;
    assert ghost_supportedProtocolSet_emittedIsSupported == isSupported;
    assert currentContract.s_supportedProtocols[protocolId] == isSupported;
}