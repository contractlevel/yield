using Share as share;
using MockUsdc as usdc;
using MockPoolAddressesProvider as addressesProvider;

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
    function getStrategyPool() external returns (address) envfree;
    function getAave() external returns (address) envfree;
    function getCompound() external returns (address) envfree;
    function getThisChainSelector() external returns (uint64) envfree;

    // External methods
    function share.totalSupply() external returns (uint256) envfree;
    function usdc.balanceOf(address) external returns (uint256) envfree;
    function addressesProvider.getPool() external returns (address) envfree;

    // Harness helper methods
    function encodeStrategy(uint64,uint8) external returns (bytes memory) envfree;
    function encodeUint64(uint64 value) external returns (bytes memory) envfree;
    function bytes32ToUint8(bytes32 value) external returns (uint8) envfree;
    function bytes32ToUint256(bytes32 value) external returns (uint256) envfree;
    function buildEncodedDepositData(address,uint256,uint256,uint256,uint64) external returns (bytes memory) envfree;
    function buildEncodedWithdrawData(address,uint256,uint256,uint256,uint64) external returns (bytes memory) envfree;
    function calculateWithdrawAmount(uint256,uint256,uint256) external returns (uint256) envfree;
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
    require ghost_ccipMessageSent_eventCount == 0;
    deposit(e, amountToDeposit);
    assert ghost_ccipMessageSent_eventCount == 1;

    assert getStrategyPool() != 0 => 
        ghost_ccipMessageSent_txType_emitted == 2 && // CcipTxType.DepositCallbackParent
        ghost_ccipMessageSent_bridgeAmount_emitted == 0;
    assert getStrategyPool() == 0 => 
        ghost_ccipMessageSent_txType_emitted == 0 && // CcipTxType.DepositToParent
        ghost_ccipMessageSent_bridgeAmount_emitted == amountToDeposit;
}

// --- handleCCIPDepositToStrategy --- //
rule handleCCIPDepositToStrategy_emits_CCIPMessageSent() {
    env e;
    calldataarg args;

    require ghost_ccipMessageSent_eventCount == 0;
    handleCCIPDepositToStrategy(e, args);
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 2; // CcipTxType.DepositCallbackParent
    assert ghost_ccipMessageSent_bridgeAmount_emitted == 0;
}

rule handleCCIPDepositToStrategy_depositsToStrategy() {
    env e;
    Client.EVMTokenAmount[] tokenAmounts;
    address depositor;
    uint256 amount;
    uint256 totalValue;
    uint256 shareMintAmount;
    uint64 chainSelector;
    bytes encodedDepositData = buildEncodedDepositData(depositor, amount, totalValue, shareMintAmount, chainSelector);
    address aave = addressesProvider.getPool();
    address compound = getCompound();

    uint256 usdcBalanceBefore = usdc.balanceOf(currentContract);
    uint256 compoundBalanceBefore = usdc.balanceOf(compound);
    uint256 aaveBalanceBefore = usdc.balanceOf(aave);

    require usdcBalanceBefore - amount >= 0, "should not cause underflow";
    require compoundBalanceBefore + amount <= max_uint256, "should not cause overflow";
    require aaveBalanceBefore + amount <= max_uint256, "should not cause overflow";
    require currentContract != compound && currentContract != aave,
        "currentContract should not be the compound or aave pool";

    handleCCIPDepositToStrategy(e, tokenAmounts, encodedDepositData);

    assert usdc.balanceOf(currentContract) == usdcBalanceBefore - amount;

    assert getStrategyPool() == compound => usdc.balanceOf(compound) == compoundBalanceBefore + amount;
    assert getStrategyPool() == addressesProvider => usdc.balanceOf(aave) == aaveBalanceBefore + amount;
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
    
    address aave = addressesProvider.getPool();
    address compound = getCompound();

    uint256 expectedUsdcWithdrawAmount = calculateWithdrawAmount(getTotalValue(e), totalShares, shareBurnAmount);

    uint256 compoundBalanceBefore = usdc.balanceOf(compound);
    uint256 aaveBalanceBefore = usdc.balanceOf(aave);

    require compoundBalanceBefore - expectedUsdcWithdrawAmount >= 0, "should not cause underflow";
    require aaveBalanceBefore - expectedUsdcWithdrawAmount >= 0, "should not cause underflow";
    require withdrawer != compound && withdrawer != aave && withdrawer != currentContract,
        "withdrawer should not be the compound or aave pool or current contract";
    
    handleCCIPWithdrawToStrategy(e, encodedWithdrawData);

    assert getStrategyPool() == compound => usdc.balanceOf(compound) == compoundBalanceBefore - expectedUsdcWithdrawAmount;
    assert getStrategyPool() == addressesProvider => usdc.balanceOf(aave) == aaveBalanceBefore - expectedUsdcWithdrawAmount;
}

rule handleCCIPWithdrawToStrategy_completesWithdrawal_when_sameChain() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    uint256 totalShares;
    uint256 usdcWithdrawAmount; // this value is set during this function we are verifying
    bytes encodedWithdrawData = 
        buildEncodedWithdrawData(withdrawer, shareBurnAmount, totalShares, usdcWithdrawAmount, getThisChainSelector());
    address aave = addressesProvider.getPool();
    address compound = getCompound();

    uint256 usdcBalanceBefore = usdc.balanceOf(withdrawer);
    uint256 expectedWithdrawAmount = calculateWithdrawAmount(getTotalValue(e), totalShares, shareBurnAmount);
    require usdcBalanceBefore + expectedWithdrawAmount <= max_uint256, "should not cause overflow";

    require getTotalValue(e) > 0, "total value should be greater than 0";
    require withdrawer != compound && withdrawer != aave && withdrawer != currentContract,
        "withdrawer should not be the compound or aave pool or current contract";

    require ghost_withdrawCompleted_eventCount == 0;
    handleCCIPWithdrawToStrategy(e, encodedWithdrawData);
    assert ghost_withdrawCompleted_eventCount == 1;
    assert usdc.balanceOf(withdrawer) == usdcBalanceBefore + expectedWithdrawAmount;
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
    assert ghost_ccipMessageSent_txType_emitted == 6; // CcipTxType.WithdrawCallback
    assert ghost_ccipMessageSent_bridgeAmount_emitted == expectedBridgeAmount;
}

// --- handleCCIPRebalanceOldStrategy --- //
rule handleCCIPRebalanceOldStrategy_withdrawsFromOldStrategy() {
    env e;
    uint256 totalValue = getTotalValue(e);
    address oldStrategyPool = getStrategyPool();
    uint64 chainSelector;
    uint8 protocolEnum;
    bytes newStrategy = encodeStrategy(chainSelector, protocolEnum);

    require chainSelector == getThisChainSelector() && oldStrategyPool == getCompound() => protocolEnum == 0;
    require chainSelector == getThisChainSelector() && oldStrategyPool == getAave() => protocolEnum == 1;

    uint256 aaveBalanceBefore = usdc.balanceOf(addressesProvider.getPool());
    uint256 compoundBalanceBefore = usdc.balanceOf(getCompound());

    require aaveBalanceBefore - totalValue >= 0, "should not cause underflow";
    require compoundBalanceBefore - totalValue >= 0, "should not cause underflow";

    handleCCIPRebalanceOldStrategy(e, newStrategy);

    assert oldStrategyPool == getAave() => usdc.balanceOf(addressesProvider.getPool()) == aaveBalanceBefore - totalValue;
    assert oldStrategyPool == getCompound() => usdc.balanceOf(getCompound()) == compoundBalanceBefore - totalValue;
}

rule handleCCIPRebalanceOldStrategy_depositsToNewStrategy_when_sameChain() {
    env e;
    uint256 totalValue = getTotalValue(e);
    address oldStrategyPool = getStrategyPool();
    uint8 protocolEnum;
    bytes newStrategy = encodeStrategy(getThisChainSelector(), protocolEnum);

    require oldStrategyPool == getCompound() => protocolEnum == 0;
    require oldStrategyPool == getAave() => protocolEnum == 1;

    uint256 compoundBalanceBefore = usdc.balanceOf(getCompound());
    uint256 aaveBalanceBefore = usdc.balanceOf(addressesProvider.getPool());

    require oldStrategyPool == getCompound() 
        => compoundBalanceBefore - totalValue >= 0 && aaveBalanceBefore + totalValue <= max_uint256;
    require oldStrategyPool == getAave() 
        => aaveBalanceBefore - totalValue >= 0 && compoundBalanceBefore + totalValue <= max_uint256;

    require usdc.balanceOf(currentContract) == 0;

    handleCCIPRebalanceOldStrategy(e, newStrategy);

    assert oldStrategyPool == getCompound()
        => usdc.balanceOf(getCompound()) == compoundBalanceBefore - totalValue &&
        usdc.balanceOf(addressesProvider.getPool()) == aaveBalanceBefore + totalValue;
    assert oldStrategyPool == getAave()
        => usdc.balanceOf(addressesProvider.getPool()) == aaveBalanceBefore - totalValue &&
        usdc.balanceOf(getCompound()) == compoundBalanceBefore + totalValue;
}

rule handleCCIPRebalanceOldStrategy_emits_CCIPMessageSent_when_differentChain() {
    env e;
    uint256 totalValue = getTotalValue(e);
    uint64 chainSelector;
    require chainSelector != getThisChainSelector();
    uint8 protocolEnum;
    bytes newStrategy = encodeStrategy(chainSelector, protocolEnum);
    require usdc.balanceOf(currentContract) == 0;
    require ghost_ccipMessageSent_eventCount == 0;
    handleCCIPRebalanceOldStrategy(e, newStrategy);
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 8; // CcipTxType.RebalanceNewStrategy
    assert ghost_ccipMessageSent_bridgeAmount_emitted == totalValue;
}