using Share as share;
using MockUsdc as usdc;
using AaveV3Adapter as aaveV3Adapter;
using CompoundV3Adapter as compoundV3Adapter;
using StrategyRegistry as strategyRegistry;

/// Verification of ChildPeer
/// @author @contractlevel
/// @notice ChildPeer contract for the Contract Level Yield system

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // Peer methods
    function getAllowedChain(uint64) external returns (bool) envfree;
    function getAllowedPeer(uint64) external returns (address) envfree;
    function getActiveStrategyAdapter() external returns (address) envfree;
    function getThisChainSelector() external returns (uint64) envfree;

    // External methods
    function share.totalSupply() external returns (uint256) envfree;
    function usdc.balanceOf(address) external returns (uint256) envfree;
    function strategyRegistry.getStrategyAdapter(bytes32) external returns (address) envfree;

    // Wildcard dispatcher summaries
    function _.withdraw(address,uint256) external => DISPATCHER(true);
    function _.deposit(address,uint256) external => DISPATCHER(true);
    function _.getTotalValue(address) external => DISPATCHER(true);

    // Harness helper methods
    function encodeStrategy(uint64,bytes32) external returns (bytes memory) envfree;
    function encodeUint64(uint64 value) external returns (bytes memory) envfree;
    function bytes32ToUint8(bytes32 value) external returns (uint8) envfree;
    function bytes32ToUint256(bytes32 value) external returns (uint256) envfree;
    function buildEncodedDepositData(address,uint256,uint256,uint256,uint64) external returns (bytes memory) envfree;
    function buildEncodedWithdrawData(address,uint256,uint256,uint256,uint64) external returns (bytes memory) envfree;
    function calculateWithdrawAmount(uint256,uint256,uint256) external returns (uint256) envfree;
    function calculateFee(uint256) external returns (uint256) envfree;
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

definition WithdrawFromStrategyEvent() returns bytes32 =
// keccak256(abi.encodePacked("WithdrawFromStrategy(address,uint256)"))
    to_bytes32(0xb28e99afed98b3607aeea074f84c346dc4135d86f35b1c28bc35ab6782e7ce30);

definition ActiveStrategyAdapterUpdatedEvent() returns bytes32 =
// keccak256(abi.encodePacked("ActiveStrategyAdapterUpdated(address)"))
    to_bytes32(0xebe96b449bfdb3f1ed534cb774b9a9b0954447b489e45e828c81a03fec492cc7);

definition DepositToStrategyEvent() returns bytes32 =
// keccak256(abi.encodePacked("DepositToStrategy(address,uint256)"))
    to_bytes32(0x8125d05f0839eec6c1f6b1674833e01f11ab362bd9c60eb2e3b274fa3b47e4f4);

definition DepositPingPongEvent() returns bytes32 =
// keccak256(abi.encodePacked("DepositPingPongToParent(uint256)"))
    to_bytes32(0x07a8895ad201463447eac3116473614940ca48b2be48a2e0851f29fe6144eb99);

definition WithdrawPingPongEvent() returns bytes32 =
// keccak256(abi.encodePacked("WithdrawPingPongToParent(uint256)"))
    to_bytes32(0x92fdcaf7d7e4ba9fb2e6b7aaa33ab45a3464542db1f0f314eb75be8130d37e56);

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

/// @notice EventCount: track amount of WithdrawFromStrategy event is emitted
ghost mathint ghost_withdrawFromStrategy_eventCount {
    init_state axiom ghost_withdrawFromStrategy_eventCount == 0;
}

/// @notice EventCount: track amount of ActiveStrategyAdapterUpdated event is emitted
ghost mathint ghost_activeStrategyAdapterUpdated_eventCount {
    init_state axiom ghost_activeStrategyAdapterUpdated_eventCount == 0;
}

/// @notice EventCount: track amount of DepositToStrategy event is emitted
ghost mathint ghost_depositToStrategy_eventCount {
    init_state axiom ghost_depositToStrategy_eventCount == 0;
}

/// @notice EventCount: track amount of DepositPingPong event is emitted
ghost mathint ghost_depositPingPong_eventCount {
    init_state axiom ghost_depositPingPong_eventCount == 0;
}

/// @notice EventCount: track amount of WithdrawPingPong event is emitted
ghost mathint ghost_withdrawPingPong_eventCount {
    init_state axiom ghost_withdrawPingPong_eventCount == 0;
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
    if (t0 == WithdrawFromStrategyEvent()) ghost_withdrawFromStrategy_eventCount = ghost_withdrawFromStrategy_eventCount + 1;
    if (t0 == DepositToStrategyEvent()) ghost_depositToStrategy_eventCount = ghost_depositToStrategy_eventCount + 1;
}

hook LOG2(uint offset, uint length, bytes32 t0, bytes32 t1) {
    if (t0 == ActiveStrategyAdapterUpdatedEvent()) 
        ghost_activeStrategyAdapterUpdated_eventCount = ghost_activeStrategyAdapterUpdated_eventCount + 1;
    if (t0 == DepositPingPongEvent()) ghost_depositPingPong_eventCount = ghost_depositPingPong_eventCount + 1;
    if (t0 == WithdrawPingPongEvent()) ghost_withdrawPingPong_eventCount = ghost_withdrawPingPong_eventCount + 1;
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
/// @notice this rule is specific to the ChildPeer, not the ParentPeer
rule child_onTokenTransfer_emits_CCIPMessageSent() {
    env e;
    calldataarg args;
    require ghost_ccipMessageSent_eventCount == 0;
    onTokenTransfer(e, args);
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 4; // CcipTxType.WithdrawToParent
    assert ghost_ccipMessageSent_bridgeAmount_emitted == 0;
}

/// @notice this rule is specific to the ChildPeer, not the ParentPeer
rule child_deposit_emits_CCIPMessageSent() {
    env e;
    uint256 amountToDeposit;
    uint256 fee = calculateFee(amountToDeposit);
    require ghost_ccipMessageSent_eventCount == 0;
    deposit(e, amountToDeposit);
    assert ghost_ccipMessageSent_eventCount == 1;

    assert getActiveStrategyAdapter() != 0 => 
        ghost_ccipMessageSent_txType_emitted == 2 && // CcipTxType.DepositCallbackParent
        ghost_ccipMessageSent_bridgeAmount_emitted == 0;
    assert getActiveStrategyAdapter() == 0 => 
        ghost_ccipMessageSent_txType_emitted == 0 && // CcipTxType.DepositToParent
        ghost_ccipMessageSent_bridgeAmount_emitted == amountToDeposit - fee;
}

rule child_deposit_isStrategy_emits_correct_params() {
    env e;
    uint256 amountToDeposit;

    require getActiveStrategyAdapter() != 0;

    require ghost_ccipMessageSent_bridgeAmount_emitted == 0;
    require ghost_ccipMessageSent_txType_emitted == 0;
    deposit(e, amountToDeposit);
    assert ghost_ccipMessageSent_bridgeAmount_emitted == 0;
    assert ghost_ccipMessageSent_txType_emitted == 2; // CcipTxType.DepositCallbackParent
}

rule child_deposit_notStrategy_emits_correct_params() {
    env e;
    uint256 amountToDeposit;
    uint256 fee = calculateFee(amountToDeposit);

    require getActiveStrategyAdapter() == 0;

    require ghost_ccipMessageSent_bridgeAmount_emitted == 0;
    require ghost_ccipMessageSent_txType_emitted == 0;
    deposit(e, amountToDeposit);
    assert ghost_ccipMessageSent_bridgeAmount_emitted == amountToDeposit - fee;
    assert ghost_ccipMessageSent_txType_emitted == 0; // CcipTxType.DepositToParent
}

// --- handleCCIPDepositToStrategy --- //
rule handleCCIPDepositToStrategy_emits_CCIPMessageSent() {
    env e;
    Client.EVMTokenAmount[] tokenAmounts;
    bytes data;

    require ghost_ccipMessageSent_eventCount == 0;
    handleCCIPDepositToStrategy(e, tokenAmounts, data);
    assert ghost_ccipMessageSent_eventCount == 1;

    assert getActiveStrategyAdapter() != 0 => 
        ghost_ccipMessageSent_txType_emitted == 2 && // CcipTxType.DepositCallbackParent
        ghost_ccipMessageSent_bridgeAmount_emitted == 0;
    assert getActiveStrategyAdapter() == 0 => 
        ghost_ccipMessageSent_txType_emitted == 11 && // CcipTxType.DepositPingPong
        ghost_ccipMessageSent_bridgeAmount_emitted == tokenAmounts[0].amount;
}

rule handleCCIPDepositToStrategy_depositsToStrategy(env e) {
    Client.EVMTokenAmount[]       tokenAmounts;

    uint256 totalValue;           uint256 shareMintAmount;  uint64         chainSelector;    
    address depositor;            uint256          amount;  
                                                            bytes     encodedDepositData      
                                  =                              buildEncodedDepositData(
            depositor,                             amount, 
            totalValue,                   shareMintAmount,                 chainSelector);

    address aavePool              =     aaveV3Adapter.getStrategyPool(e);
    address compoundPool          = compoundV3Adapter.getStrategyPool(e);

    uint256     usdcBalanceBefore = usdc.balanceOf(currentContract);
    uint256 compoundBalanceBefore = usdc.balanceOf(compoundPool);
    uint256     aaveBalanceBefore = usdc.balanceOf(aavePool);

    require      currentContract != compoundPool &&
                 currentContract != aavePool,
                "currentContract                                  should not be the compound or aave pool";
    require     usdcBalanceBefore - amount       >= 0,           "should not cause underflow";
    require     aaveBalanceBefore + amount       <= max_uint256, "should not cause over flow";
    require compoundBalanceBefore + amount       <= max_uint256, "should not cause over flow";

    handleCCIPDepositToStrategy(e,  tokenAmounts,                     encodedDepositData);

    assert 
           usdc.balanceOf(currentContract)       == usdcBalanceBefore            - amount;
    assert getActiveStrategyAdapter()            == compoundV3Adapter      => 
           usdc.balanceOf(compoundPool)          == compoundBalanceBefore        + amount;
    assert getActiveStrategyAdapter()            == aaveV3Adapter          => 
           usdc.balanceOf(aavePool)              == aaveBalanceBefore            + amount;
}

// --- handleCCIPDepositCallbackChild --- //
rule handleCCIPDepositCallbackChild_increases_share_totalSupply() {
    env e;
    address depositor;
    uint256 amount;
    uint256 totalValue;
    uint256 shareMintAmount;
    uint64 chainSelector;
    bytes encodedDepositData = buildEncodedDepositData(depositor, amount, totalValue, shareMintAmount, chainSelector);
    require shareMintAmount > 0, "shareMintAmount must be greater than 0";

    uint256 shareTotalSupplyBefore = share.totalSupply();
    handleCCIPDepositCallbackChild(e, encodedDepositData);
    assert share.totalSupply() > shareTotalSupplyBefore;
}

rule handleCCIPDepositCallbackChild_emits_SharesMinted() {
    env e;
    calldataarg args;
    require ghost_sharesMinted_eventCount == 0;
    handleCCIPDepositCallbackChild(e, args);
    assert ghost_sharesMinted_eventCount == 1;
}

// --- handleCCIPWithdrawToStrategy --- //
rule handleCCIPWithdrawToStrategy_withdrawsFromStrategy() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    uint256 totalShares;
    uint256 usdcWithdrawAmountPlaceholder; // dummy value, set during this function we are verifying
    uint64 chainSelector;
    bytes encodedWithdrawData = 
        buildEncodedWithdrawData(withdrawer, shareBurnAmount, totalShares, usdcWithdrawAmountPlaceholder, chainSelector);
    
    address aavePool = aaveV3Adapter.getStrategyPool(e);
    address compoundPool = compoundV3Adapter.getStrategyPool(e);

    uint256 expectedUsdcWithdrawAmount = calculateWithdrawAmount(getTotalValue(e), totalShares, shareBurnAmount);

    uint256 compoundBalanceBefore = usdc.balanceOf(compoundPool);
    uint256 aaveBalanceBefore = usdc.balanceOf(aavePool);

    require compoundBalanceBefore - expectedUsdcWithdrawAmount >= 0, "should not cause underflow";
    require aaveBalanceBefore - expectedUsdcWithdrawAmount >= 0, "should not cause underflow";
    require withdrawer != compoundPool && withdrawer != aavePool && withdrawer != currentContract,
        "withdrawer should not be the compound or aave pool or current contract";
    require ghost_withdrawPingPong_eventCount == 0;

    handleCCIPWithdrawToStrategy(e, encodedWithdrawData);

    assert getActiveStrategyAdapter() == compoundV3Adapter => 
        usdc.balanceOf(compoundPool) == compoundBalanceBefore - expectedUsdcWithdrawAmount;
    assert getActiveStrategyAdapter() == aaveV3Adapter => 
        usdc.balanceOf(aavePool) == aaveBalanceBefore - expectedUsdcWithdrawAmount;
    assert getActiveStrategyAdapter() == 0 =>
        ghost_withdrawPingPong_eventCount == 1;
}

rule handleCCIPWithdrawToStrategy_completesWithdrawal_when_sameChain() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    uint256 totalShares;
    uint256 usdcWithdrawAmount; // this value is set during this function we are verifying
    bytes encodedWithdrawData =
        buildEncodedWithdrawData(withdrawer, shareBurnAmount, totalShares, usdcWithdrawAmount, getThisChainSelector());
    address aavePool = aaveV3Adapter.getStrategyPool(e);
    address compoundPool = compoundV3Adapter.getStrategyPool(e);

    //uint256 usdcBalanceBefore = usdc.balanceOf(withdrawer);
    uint256 expectedWithdrawAmount = calculateWithdrawAmount(getTotalValue(e), totalShares, shareBurnAmount);
    //require usdcBalanceBefore + expectedWithdrawAmount <= max_uint256, "should not cause overflow";

    require getTotalValue(e) > 0, "total value should be greater than 0";
    require withdrawer != compoundPool && withdrawer != aavePool && withdrawer != currentContract,
        "withdrawer should not be the compound or aave pool or current contract";

    require ghost_withdrawCompleted_eventCount == 0;
    require ghost_withdrawPingPong_eventCount == 0;
    require ghost_ccipMessageSent_eventCount == 0;
    require ghost_withdrawFromStrategy_eventCount == 0;
    handleCCIPWithdrawToStrategy(e, encodedWithdrawData);

    // When adapter == 0: Child ping-pongs to parent (emits WithdrawPingPongToParent, sends WithdrawPingPong)
    assert getActiveStrategyAdapter() == 0 =>
        ghost_withdrawPingPong_eventCount == 1 &&
        ghost_ccipMessageSent_eventCount == 1 &&
        ghost_ccipMessageSent_txType_emitted == 12; // WithdrawPingPong

    // When adapter != 0: Child sends WithdrawCallbackParent. WithdrawFromStrategy is only emitted when
    // usdcWithdrawAmount != 0 (see YieldPeer._withdrawFromStrategyAndGetUsdcWithdrawAmount).
    // no balance update to evaluate
    assert getActiveStrategyAdapter() != 0 =>
        ghost_ccipMessageSent_eventCount == 1 &&
        ghost_ccipMessageSent_txType_emitted == 7 && // WithdrawCallbackParent
        (expectedWithdrawAmount > 0 => ghost_withdrawFromStrategy_eventCount == 1);
}

rule handleCCIPWithdrawToStrategy_emits_CCIPMessageSent_when_differentChain() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    uint256 totalShares;
    uint256 usdcWithdrawAmount; // this value is set during this function we are verifying
    uint64 chainSelector;
    bytes encodedWithdrawData = 
        buildEncodedWithdrawData(withdrawer, shareBurnAmount, totalShares, usdcWithdrawAmount, chainSelector);

    require chainSelector != getThisChainSelector();

    uint256 expectedBridgeAmount = calculateWithdrawAmount(getTotalValue(e), totalShares, shareBurnAmount);

    require ghost_ccipMessageSent_eventCount == 0;
    handleCCIPWithdrawToStrategy(e, encodedWithdrawData);
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 7; // CcipTxType.WithdrawCallbackParent
    assert ghost_ccipMessageSent_bridgeAmount_emitted == expectedBridgeAmount;
}

// --- handleCCIPRebalanceOldStrategy --- //
rule handleCCIPRebalanceOldStrategy_withdrawsFromOldStrategy() {
    env e;
    uint256 totalValue = getTotalValue(e);
    address oldStrategyPool = getActiveStrategyAdapter().getStrategyPool(e);
    uint64 chainSelector;
    bytes32 protocolId;
    bytes32 aaveV3ProtocolId;
    bytes32 compoundV3ProtocolId;
    bytes newStrategy = encodeStrategy(chainSelector, protocolId);

    /// @dev require the storage mappings for active strategy adapters to be the correct contracts
    require strategyRegistry.getStrategyAdapter(aaveV3ProtocolId)     == aaveV3Adapter;
    require strategyRegistry.getStrategyAdapter(compoundV3ProtocolId) == compoundV3Adapter;

    /// @dev require the storage for active strategy adapter to be aave or compound adapters
    require currentContract.s_activeStrategyAdapter == aaveV3Adapter ||
            currentContract.s_activeStrategyAdapter == compoundV3Adapter;

    address aavePool = aaveV3Adapter.getStrategyPool(e);
    address compoundPool = compoundV3Adapter.getStrategyPool(e);

    require chainSelector == getThisChainSelector() && oldStrategyPool == compoundPool => protocolId == aaveV3ProtocolId;
    require chainSelector == getThisChainSelector() && oldStrategyPool == aavePool => protocolId == compoundV3ProtocolId;

    uint256 aaveBalanceBefore = usdc.balanceOf(aavePool);
    uint256 compoundBalanceBefore = usdc.balanceOf(compoundPool);

    require aaveBalanceBefore - totalValue >= 0, "should not cause underflow";
    require compoundBalanceBefore - totalValue >= 0, "should not cause underflow";

    handleCCIPRebalanceOldStrategy(e, newStrategy);

    assert oldStrategyPool == aavePool => 
        usdc.balanceOf(aavePool) == aaveBalanceBefore - totalValue;
    assert oldStrategyPool == compoundPool => 
        usdc.balanceOf(compoundPool) == compoundBalanceBefore - totalValue;
}

rule handleCCIPRebalanceOldStrategy_depositsToNewStrategy_when_sameChain() {
    env e;
    uint256 totalValue = getTotalValue(e);
    address oldStrategyPool = getActiveStrategyAdapter().getStrategyPool(e);
    bytes32 protocolId;
    bytes32 aaveV3ProtocolId;
    bytes32 compoundV3ProtocolId;
    bytes newStrategy = encodeStrategy(getThisChainSelector(), protocolId);

    /// @dev require the storage mappings for active strategy adapters to be the correct contracts
    require strategyRegistry.getStrategyAdapter(aaveV3ProtocolId)     == aaveV3Adapter;
    require strategyRegistry.getStrategyAdapter(compoundV3ProtocolId) == compoundV3Adapter;

    /// @dev require the storage for active strategy adapter to be aave or compound adapters
    require currentContract.s_activeStrategyAdapter == aaveV3Adapter ||
            currentContract.s_activeStrategyAdapter == compoundV3Adapter;

    address aavePool = aaveV3Adapter.getStrategyPool(e);
    address compoundPool = compoundV3Adapter.getStrategyPool(e);

    require oldStrategyPool == compoundPool => protocolId == aaveV3ProtocolId;
    require oldStrategyPool == aavePool => protocolId == compoundV3ProtocolId;

    uint256 compoundBalanceBefore = usdc.balanceOf(compoundPool);
    uint256 aaveBalanceBefore = usdc.balanceOf(aavePool);

    require oldStrategyPool == compoundPool 
        => compoundBalanceBefore - totalValue >= 0 && aaveBalanceBefore + totalValue <= max_uint256;
    require oldStrategyPool == aavePool 
        => aaveBalanceBefore - totalValue >= 0 && compoundBalanceBefore + totalValue <= max_uint256;

    require usdc.balanceOf(currentContract) == 0;

    handleCCIPRebalanceOldStrategy(e, newStrategy);

    assert oldStrategyPool == compoundPool
        => usdc.balanceOf(compoundPool) == compoundBalanceBefore - totalValue &&
        usdc.balanceOf(aavePool) == aaveBalanceBefore + totalValue;
    assert oldStrategyPool == aavePool
        => usdc.balanceOf(aavePool) == aaveBalanceBefore - totalValue &&
        usdc.balanceOf(compoundPool) == compoundBalanceBefore + totalValue;
}

rule handleCCIPRebalanceOldStrategy_emits_CCIPMessageSent_when_differentChain() {
    env e;
    uint256 totalValue = getTotalValue(e);
    uint64 chainSelector;
    require chainSelector != getThisChainSelector();
    bytes32 protocolId;
    bytes newStrategy = encodeStrategy(chainSelector, protocolId);
    require usdc.balanceOf(currentContract) == 0;
    require ghost_ccipMessageSent_eventCount == 0;
    handleCCIPRebalanceOldStrategy(e, newStrategy);
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 10; // CcipTxType.RebalanceNewStrategy
    assert ghost_ccipMessageSent_bridgeAmount_emitted == totalValue;
}

// --- handleCCIPMessage --- //
rule handleCCIPMessage_DepositToStrategy() {
    env e;
    IYieldPeer.CcipTxType txType = IYieldPeer.CcipTxType.DepositToStrategy;
    Client.EVMTokenAmount[] tokenAmounts;
    bytes data;
    uint64 sourceChainSelector;

    require ghost_ccipMessageSent_eventCount == 0;
    require ghost_depositPingPong_eventCount == 0;

    require getActiveStrategyAdapter() != 0;

    handleCCIPMessage(e, txType, tokenAmounts, data, sourceChainSelector);
    
    assert 
        ghost_ccipMessageSent_eventCount == 1 &&
        ghost_ccipMessageSent_txType_emitted == 2 && // CcipTxType.DepositCallbackParent
        ghost_ccipMessageSent_bridgeAmount_emitted == 0;
}

rule handleCCIPMessage_DepositToStrategyPingPongs() {
    env e;
    IYieldPeer.CcipTxType txType = IYieldPeer.CcipTxType.DepositToStrategy;
    Client.EVMTokenAmount[] tokenAmounts;
    bytes data;
    uint64 sourceChainSelector;

    require ghost_ccipMessageSent_eventCount == 0;
    require ghost_depositPingPong_eventCount == 0;
    require getActiveStrategyAdapter() == 0;
    handleCCIPMessage(e, txType, tokenAmounts, data, sourceChainSelector);
    assert 
        ghost_ccipMessageSent_eventCount == 1 &&
        ghost_ccipMessageSent_txType_emitted == 11 && // CcipTxType.DepositPingPong
        ghost_ccipMessageSent_bridgeAmount_emitted == tokenAmounts[0].amount &&
        ghost_depositPingPong_eventCount == 1;
}

rule handleCCIPMessage_DepositCallbackChild() {
    env e;
    IYieldPeer.CcipTxType txType = IYieldPeer.CcipTxType.DepositCallbackChild;
    Client.EVMTokenAmount[] tokenAmounts;
    bytes data;
    uint64 sourceChainSelector;

    require ghost_ccipMessageSent_eventCount == 0;
    require ghost_sharesMinted_eventCount == 0;
    handleCCIPMessage(e, txType, tokenAmounts, data, sourceChainSelector);
    assert ghost_sharesMinted_eventCount == 1;
    assert ghost_ccipMessageSent_eventCount == 0;
}

rule handleCCIPMessage_WithdrawToStrategy() {
    env e;
    IYieldPeer.CcipTxType txType = IYieldPeer.CcipTxType.WithdrawToStrategy;
    Client.EVMTokenAmount[] tokenAmounts;
    bytes data;
    uint64 sourceChainSelector;

    require ghost_ccipMessageSent_eventCount == 0;
    require ghost_withdrawCompleted_eventCount == 0;
    handleCCIPMessage(e, txType, tokenAmounts, data, sourceChainSelector);
    assert ghost_withdrawCompleted_eventCount == 1 || ghost_ccipMessageSent_eventCount == 1;
}

rule handleCCIPMessage_WithdrawToStrategyPingPongs() {
    env e;
    IYieldPeer.CcipTxType txType = IYieldPeer.CcipTxType.WithdrawToStrategy;
    Client.EVMTokenAmount[] tokenAmounts;
    address withdrawer;
    uint256 shareBurnAmount;
    uint256 totalShares;
    uint256 usdcWithdrawAmount;
    uint64 chainSelector;
    bytes data = buildEncodedWithdrawData(withdrawer, shareBurnAmount, totalShares, usdcWithdrawAmount, chainSelector);
    uint64 sourceChainSelector;

    require getActiveStrategyAdapter() == 0;
    require ghost_ccipMessageSent_eventCount == 0;
    require ghost_withdrawCompleted_eventCount == 0;
    require ghost_withdrawPingPong_eventCount == 0;
    handleCCIPMessage(e, txType, tokenAmounts, data, sourceChainSelector);
    assert ghost_withdrawPingPong_eventCount == 1;
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_withdrawCompleted_eventCount == 0;
    assert ghost_ccipMessageSent_txType_emitted == 12; // WithdrawPingPong (10 is RebalanceNewStrategy)
}

rule handleCCIPMessage_WithdrawCallback() {
    env e;
    IYieldPeer.CcipTxType txType = IYieldPeer.CcipTxType.WithdrawCallbackChild;
    Client.EVMTokenAmount[] tokenAmounts;
    bytes data;
    uint64 sourceChainSelector;

    require ghost_withdrawCompleted_eventCount == 0;
    handleCCIPMessage(e, txType, tokenAmounts, data, sourceChainSelector);
    assert ghost_withdrawCompleted_eventCount == 1;
}

rule handleCCIPMessage_RebalanceOldStrategy() {
    env e;
    IYieldPeer.CcipTxType txType = IYieldPeer.CcipTxType.RebalanceOldStrategy;
    Client.EVMTokenAmount[] tokenAmounts;
    bytes data;
    uint64 sourceChainSelector;

    uint256 totalValue = getTotalValue(e);
    require totalValue > 0;
    uint256 usdcBalance = usdc.balanceOf(currentContract);
    require totalValue + usdcBalance <= max_uint256 && totalValue + usdcBalance > 0;

    require ghost_withdrawFromStrategy_eventCount == 0;
    require ghost_ccipMessageSent_eventCount == 0;
    require ghost_activeStrategyAdapterUpdated_eventCount == 0;
    require ghost_depositToStrategy_eventCount == 0;
    handleCCIPMessage(e, txType, tokenAmounts, data, sourceChainSelector);
    assert ghost_activeStrategyAdapterUpdated_eventCount == 1;
    assert ghost_withdrawFromStrategy_eventCount == 1;
    assert ghost_depositToStrategy_eventCount == 1 || ghost_ccipMessageSent_eventCount == 1;
}

rule handleCCIPMessage_RebalanceNewStrategy() {
    env e;
    IYieldPeer.CcipTxType txType = IYieldPeer.CcipTxType.RebalanceNewStrategy;
    Client.EVMTokenAmount[] tokenAmounts;
    bytes data;
    uint64 sourceChainSelector;

    require tokenAmounts.length > 0 && tokenAmounts[0].token == usdc && tokenAmounts[0].amount > 0;

    require ghost_depositToStrategy_eventCount == 0;
    require ghost_activeStrategyAdapterUpdated_eventCount == 0;
    handleCCIPMessage(e, txType, tokenAmounts, data, sourceChainSelector);
    assert ghost_activeStrategyAdapterUpdated_eventCount == 1;
    assert ghost_depositToStrategy_eventCount == 1;
}