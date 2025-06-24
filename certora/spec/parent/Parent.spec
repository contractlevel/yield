using Share as share;
using MockUsdc as usdc;
using MockPoolAddressesProvider as addressesProvider;

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
    function getStrategyPool() external returns (address) envfree;
    function getCompound() external returns (address) envfree;
    function getAave() external returns (address) envfree;

    // External methods
    function share.totalSupply() external returns (uint256) envfree;
    function share.balanceOf(address) external returns (uint256) envfree;
    function usdc.balanceOf(address) external returns (uint256) envfree;
    function addressesProvider.getPool() external returns (address) envfree;
    
    // Harness helper methods
    function bytes32ToUint256(bytes32) external returns (uint256) envfree;
    function bytes32ToUint8(bytes32) external returns (uint8) envfree;
    function buildEncodedWithdrawData(address,uint256,uint256,uint256,uint64) external returns (bytes memory) envfree;
    function encodeUint64(uint64) external returns (bytes memory) envfree;
    function calculateWithdrawAmount(uint256,uint256,uint256) external returns (uint256) envfree;
    function buildEncodedDepositData(address,uint256,uint256,uint256,uint64) external returns (bytes memory) envfree;
    function prepareTokenAmounts(address,uint256) external returns (Client.EVMTokenAmount[] memory) envfree;
    function calculateMintAmount(uint256,uint256) external returns (uint256) envfree;
    function calculateTotalValue(uint256) external returns (uint256);
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
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
// keccak256(abi.encodePacked("CurrentStrategyOptimal(uint64,uint8)"))
    to_bytes32(0x27af4b720c71fc9b50aab1114c5dcdf5fd74cb01f03aff4c0e3f4a0dc6cf4360);

definition StrategyUpdatedEvent() returns bytes32 =
// keccak256(abi.encodePacked("StrategyUpdated(uint64,uint8,uint64)"))
    to_bytes32(0xcb31617872c52547b670aaf6e63c8f6be35dc74d4144db1b17f2e539b5475ac7);

definition DepositUpdateEvent() returns bytes32 =
// keccak256(abi.encodePacked("DepositUpdate(uint256,uint64)"))
    to_bytes32(0xff215d791a3a0e5766702c21a1a751625c5cc59035448abd88eb5c21433f4b08);

definition WithdrawUpdateEvent() returns bytes32 =
// keccak256(abi.encodePacked("WithdrawUpdate(uint256,uint64)"))
    to_bytes32(0x9db6cf034e2aa9870048958883ccb4eb967e2adf2ec79fd388f384b5ebcd4310);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
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

// ------------------------------------------------------------//
/// @notice Tracks the total USDC deposited into the system
ghost mathint ghost_totalUsdcDeposited {
    init_state axiom ghost_totalUsdcDeposited == 0;
}

/// @notice Tracks the total USDC withdrawn from the system
ghost mathint ghost_totalUsdcWithdrawn {
    init_state axiom ghost_totalUsdcWithdrawn == 0;
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// @notice hook onto emitted events and increment relevant ghosts
hook LOG4(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2, bytes32 t3) {
    if (t0 == WithdrawInitiatedEvent())
        ghost_withdrawInitiated_eventCount = ghost_withdrawInitiated_eventCount + 1;
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
    if (t0 == StrategyUpdatedEvent())
        ghost_strategyUpdated_eventCount = ghost_strategyUpdated_eventCount + 1;
}

hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == SharesBurnedEvent()) 
        ghost_sharesBurned_eventCount = ghost_sharesBurned_eventCount + 1;
    if (t0 == SharesMintedEvent())
        ghost_sharesMinted_eventCount = ghost_sharesMinted_eventCount + 1;
    if (t0 == WithdrawCompletedEvent())
        ghost_withdrawCompleted_eventCount = ghost_withdrawCompleted_eventCount + 1;
    if (t0 == DepositForwardedToStrategyEvent())
        ghost_depositForwardedToStrategy_eventCount = ghost_depositForwardedToStrategy_eventCount + 1;
    if (t0 == WithdrawForwardedToStrategyEvent())
        ghost_withdrawForwardedToStrategy_eventCount = ghost_withdrawForwardedToStrategy_eventCount + 1;
    if (t0 == CurrentStrategyOptimalEvent())
        ghost_currentStrategyOptimal_eventCount = ghost_currentStrategyOptimal_eventCount + 1;

    // ------------------------------------------------------------//
    if (t0 == DepositUpdateEvent()) ghost_totalUsdcDeposited = ghost_totalUsdcDeposited + bytes32ToUint256(t1);
    if (t0 == WithdrawUpdateEvent()) ghost_totalUsdcWithdrawn = ghost_totalUsdcWithdrawn + bytes32ToUint256(t1);
}

/*//////////////////////////////////////////////////////////////
                           FUNCTIONS
//////////////////////////////////////////////////////////////*/
// @review
// function 

/*//////////////////////////////////////////////////////////////
                           INVARIANTS
//////////////////////////////////////////////////////////////*/
invariant totalShares_consistency()
    getTotalShares() == ghost_shareMintUpdate_totalAmount_emitted - ghost_shareBurnUpdate_totalAmount_emitted;

// @review
// this wont work with crosschain certora and havocing (unless values passed to contract that emits events are constrained)
// invariant totalValue_consistency(env e)
//     getStrategy().chainSelector == getThisChainSelector() => 
//         getTotalValue(e) >= ghost_totalUsdcDeposited - ghost_totalUsdcWithdrawn;

// invariant stablecoinRedemptionIntegrity() 


/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
// --- deposit --- //
rule deposit_transfersUsdcToStrategy_when_parent_is_strategy() {
    env e;
    uint256 amountToDeposit;
    require getStrategy().chainSelector == getThisChainSelector();
    address strategyPool = getStrategyPool();

    uint256 depositorBalanceBefore = usdc.balanceOf(e.msg.sender);
    uint256 compoundBalanceBefore = usdc.balanceOf(getCompound());
    uint256 aaveBalanceBefore = usdc.balanceOf(addressesProvider.getPool());

    require strategyPool == getCompound() => compoundBalanceBefore + amountToDeposit <= max_uint256;
    require strategyPool == getAave() => aaveBalanceBefore + amountToDeposit <= max_uint256;
    require usdc.balanceOf(currentContract) == 0;
    require e.msg.sender != strategyPool && e.msg.sender != addressesProvider.getPool();

    deposit(e, amountToDeposit);

    assert strategyPool == getCompound() => usdc.balanceOf(getCompound()) == compoundBalanceBefore + amountToDeposit;
    assert strategyPool == getAave() => usdc.balanceOf(addressesProvider.getPool()) == aaveBalanceBefore + amountToDeposit;
    assert usdc.balanceOf(e.msg.sender) == depositorBalanceBefore - amountToDeposit;
}

// @review this is uncovering a critical edgecase bug and needs to be revisited.
rule deposit_mintsShares_when_parent_is_strategy() {
    env e;
    calldataarg args;
    require getStrategy().chainSelector == getThisChainSelector();
    
    uint256 shareSupplyBefore = share.totalSupply();
    uint256 totalSharesBefore = getTotalShares();

    /// @notice simulating initial admin deposit to mitigate inflation attack
    // // require getTotalValue(e) >= 1000000 && totalSharesBefore >= 1000000000000; // 1 usdc
    // require getTotalValue(e) >= 100000000 && totalSharesBefore >= 100000000000000; // 1 usdc
    // require share.balanceOf(0) == 10000000000000000000;
    /// @notice this rule passes with these ==
    /// edgecase uncovered with >=
    require getTotalValue(e) == 100000000 &&
        totalSharesBefore == 100000000000000000000;

    deposit(e, args);

    assert share.totalSupply() > shareSupplyBefore;
    assert getTotalShares() > totalSharesBefore;
}

rule deposit_emits_SharesMinted_when_parent_is_strategy() {
    env e;
    calldataarg args;
    require getStrategy().chainSelector == getThisChainSelector();

    require ghost_sharesMinted_eventCount == 0;
    deposit(e, args);
    assert ghost_sharesMinted_eventCount == 1;
}

rule deposit_emits_CCIPMessageSent_when_strategy_is_differentChain() {
    env e;
    uint256 amountToDeposit;
    require getStrategy().chainSelector != getThisChainSelector();

    require ghost_ccipMessageSent_eventCount == 0;
    deposit(e, amountToDeposit);
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 1; // DepositToStrategy
    assert ghost_ccipMessageSent_bridgeAmount_emitted == amountToDeposit;
}

// --- onTokenTransfer --- //
rule onTokenTransfer_decreases_totalShares() {
    env e;
    calldataarg args;

    uint256 totalSharesBefore = getTotalShares();

    onTokenTransfer(e, args);

    assert getTotalShares() < totalSharesBefore;
}

rule onTokenTransfer_emits_SharesBurned_and_ShareBurnUpdate_and_WithdrawInitiated() {
    env e;
    calldataarg args;

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

rule onTokenTransfer_emits_CCIPMessageSent_when_parent_is_strategyChain_and_withdrawChain_is_differentChain() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    uint64 withdrawChainSelector;
    require withdrawChainSelector != getThisChainSelector();
    bytes encodedWithdrawChainSelector = encodeUint64(withdrawChainSelector);
    require getStrategy().chainSelector == getThisChainSelector();

    uint256 expectedWithdrawAmount = calculateWithdrawAmount(getTotalValue(e), getTotalShares(), shareBurnAmount);

    require ghost_ccipMessageSent_eventCount == 0;
    onTokenTransfer(e, withdrawer, shareBurnAmount, encodedWithdrawChainSelector);
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 6; // WithdrawCallback
    assert ghost_ccipMessageSent_bridgeAmount_emitted == expectedWithdrawAmount;
}

rule onTokenTransfer_transfersUsdcToWithdrawer_when_parent_is_strategyChain_and_withdrawChain() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    bytes encodedWithdrawChainSelector = encodeUint64(getThisChainSelector());
    require getStrategy().chainSelector == getThisChainSelector();

    address strategyPool = getStrategyPool();

    uint256 expectedWithdrawAmount = calculateWithdrawAmount(getTotalValue(e), getTotalShares(), shareBurnAmount);
    uint256 usdcBalanceBefore = usdc.balanceOf(withdrawer);
    uint256 compoundBalanceBefore = usdc.balanceOf(getCompound());
    uint256 aaveBalanceBefore = usdc.balanceOf(addressesProvider.getPool());

    require strategyPool == getCompound() => compoundBalanceBefore - expectedWithdrawAmount >= 0;
    require strategyPool == getAave() => aaveBalanceBefore - expectedWithdrawAmount >= 0;

    require expectedWithdrawAmount > 0, "if the shareBurnAmount is worth less than 1 usdc wei, no usdc will be withdrawn (known issue)";
    require usdcBalanceBefore + expectedWithdrawAmount <= max_uint256;
    require withdrawer != strategyPool && withdrawer != addressesProvider.getPool();

    onTokenTransfer(e, withdrawer, shareBurnAmount, encodedWithdrawChainSelector);

    assert usdc.balanceOf(withdrawer) == usdcBalanceBefore + expectedWithdrawAmount;
    assert strategyPool == getCompound() => usdc.balanceOf(getCompound()) == compoundBalanceBefore - expectedWithdrawAmount;
    assert strategyPool == getAave() => usdc.balanceOf(addressesProvider.getPool()) == aaveBalanceBefore - expectedWithdrawAmount;
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

    address strategyPool = getStrategyPool();
    uint256 compoundBalanceBefore = usdc.balanceOf(getCompound());
    uint256 aaveBalanceBefore = usdc.balanceOf(addressesProvider.getPool());
    uint256 usdcBalanceBefore = usdc.balanceOf(currentContract);
    require usdcBalanceBefore >= usdcDepositAmount;

    require strategyPool == getCompound() => compoundBalanceBefore + usdcDepositAmount <= max_uint256;
    require strategyPool == getAave() => aaveBalanceBefore + usdcDepositAmount <= max_uint256;

    handleCCIPDepositToParent(e, tokenAmounts, encodedDepositData);

    assert strategyPool == getCompound() => usdc.balanceOf(getCompound()) == compoundBalanceBefore + usdcDepositAmount;
    assert strategyPool == getAave() => usdc.balanceOf(addressesProvider.getPool()) == aaveBalanceBefore + usdcDepositAmount;
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

rule handleCCIPDepositToParent_emits_CCIPMessageSent_and_ShareMintUpdate_when_depositChain_is_strategyChain() {
    env e;
    address depositor;
    uint256 usdcDepositAmount;
    uint256 totalValue; // irrelevant placeholder
    uint256 shareMintAmount; // irrelevant placeholder
    uint64 chainSelector;
    bytes encodedDepositData = buildEncodedDepositData(depositor, usdcDepositAmount, totalValue, shareMintAmount, chainSelector);
    Client.EVMTokenAmount[] tokenAmounts;
    require getStrategy().chainSelector != getThisChainSelector();
    require getStrategy().chainSelector == chainSelector;

    require ghost_ccipMessageSent_eventCount == 0;
    require ghost_shareMintUpdate_eventCount == 0;
    require ghost_shareMintUpdate_totalAmount_emitted == 0;
    handleCCIPDepositToParent(e, tokenAmounts, encodedDepositData);
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 3; // DepositCallbackChild
    assert ghost_ccipMessageSent_bridgeAmount_emitted == 0;
    assert ghost_shareMintUpdate_eventCount == 1;
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
    uint64 chainSelector;
    bytes encodedWithdrawData = buildEncodedWithdrawData(withdrawer, shareBurnAmount, totalShares, usdcWithdrawAmount, chainSelector);

    uint256 totalSharesBefore = getTotalShares();

    require ghost_shareBurnUpdate_eventCount == 0;
    handleCCIPWithdrawToParent(e, encodedWithdrawData);
    assert ghost_shareBurnUpdate_eventCount == 1;
    assert getTotalShares() == totalSharesBefore - shareBurnAmount;
}

rule handleCCIPWithdrawToParent_withdrawsUsdc_when_parent_is_strategy() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    uint256 totalShares;
    uint256 usdcWithdrawAmount;
    uint64 chainSelector;
    bytes encodedWithdrawData = buildEncodedWithdrawData(withdrawer, shareBurnAmount, totalShares, usdcWithdrawAmount, chainSelector);
    require getStrategy().chainSelector == getThisChainSelector();

    uint256 expectedWithdrawAmount = calculateWithdrawAmount(getTotalValue(e), getTotalShares(), shareBurnAmount);

    address strategyPool = getStrategyPool();
    uint256 compoundBalanceBefore = usdc.balanceOf(getCompound());
    uint256 aaveBalanceBefore = usdc.balanceOf(addressesProvider.getPool());
    require strategyPool == getCompound() => compoundBalanceBefore - expectedWithdrawAmount >= 0;
    require strategyPool == getAave() => aaveBalanceBefore - expectedWithdrawAmount >= 0;
    require withdrawer != strategyPool && withdrawer != addressesProvider.getPool();

    handleCCIPWithdrawToParent(e, encodedWithdrawData);

    assert strategyPool == getCompound() => usdc.balanceOf(getCompound()) == compoundBalanceBefore - expectedWithdrawAmount;
    assert strategyPool == getAave() => usdc.balanceOf(addressesProvider.getPool()) == aaveBalanceBefore - expectedWithdrawAmount;
}

rule handleCCIPWithdrawToParent_transferUsdcToWithdrawer_when_parent_is_strategy_and_withdrawChain() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    uint256 totalShares;
    uint256 usdcWithdrawAmount;
    uint64 chainSelector;
    bytes encodedWithdrawData = buildEncodedWithdrawData(withdrawer, shareBurnAmount, totalShares, usdcWithdrawAmount, chainSelector);
    require getStrategy().chainSelector == getThisChainSelector();
    require chainSelector == getThisChainSelector();

    uint256 expectedWithdrawAmount = calculateWithdrawAmount(getTotalValue(e), getTotalShares(), shareBurnAmount);

    uint256 usdcBalanceBefore = usdc.balanceOf(withdrawer);
    require usdcBalanceBefore + expectedWithdrawAmount <= max_uint256;
    require withdrawer != getStrategyPool() && withdrawer != addressesProvider.getPool();

    require ghost_withdrawCompleted_eventCount == 0;
    handleCCIPWithdrawToParent(e, encodedWithdrawData);
    assert ghost_withdrawCompleted_eventCount == 1;

    assert usdc.balanceOf(withdrawer) == usdcBalanceBefore + expectedWithdrawAmount;
}

rule handleCCIPWithdrawToParent_sendsUsdc_to_withdrawChain_when_parent_is_strategy() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    uint256 totalShares;
    uint256 usdcWithdrawAmount;
    uint64 chainSelector;
    bytes encodedWithdrawData = buildEncodedWithdrawData(withdrawer, shareBurnAmount, totalShares, usdcWithdrawAmount, chainSelector);

    require getStrategy().chainSelector == getThisChainSelector();
    require chainSelector != getThisChainSelector();

    uint256 expectedWithdrawAmount = calculateWithdrawAmount(getTotalValue(e), getTotalShares(), shareBurnAmount);

    require ghost_ccipMessageSent_eventCount == 0;
    handleCCIPWithdrawToParent(e, encodedWithdrawData);
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 6; // WithdrawCallback
    assert ghost_ccipMessageSent_bridgeAmount_emitted == expectedWithdrawAmount;
}

rule handleCCIPWithdrawToParent_forwardsToStrategy() {
    env e;
    address withdrawer;
    uint256 shareBurnAmount;
    uint256 totalShares;
    uint256 usdcWithdrawAmount;
    uint64 chainSelector;
    bytes encodedWithdrawData = buildEncodedWithdrawData(withdrawer, shareBurnAmount, totalShares, usdcWithdrawAmount, chainSelector);
    require getStrategy().chainSelector != getThisChainSelector();
    require getStrategy().chainSelector != chainSelector;

    require ghost_ccipMessageSent_eventCount == 0;
    require ghost_withdrawForwardedToStrategy_eventCount == 0;
    handleCCIPWithdrawToParent(e, encodedWithdrawData);
    assert ghost_withdrawForwardedToStrategy_eventCount == 1;
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 5; // WithdrawToStrategy
    assert ghost_ccipMessageSent_bridgeAmount_emitted == 0;
}

// --- setStrategy --- //
rule setStrategy_emits_CurrentStrategyOptimal_when_currentStrategy_is_optimal() {
    env e;
    uint64 chainSelector;
    IYieldPeer.Protocol protocol;

    IYieldPeer.Strategy oldStrategy = getStrategy();

    require oldStrategy.chainSelector == chainSelector && oldStrategy.protocol == protocol;

    require ghost_currentStrategyOptimal_eventCount == 0;
    setStrategy(e, chainSelector, protocol);
    assert ghost_currentStrategyOptimal_eventCount == 1;
    assert getStrategy() == oldStrategy;
}

rule setStrategy_updatesStrategy_when_newStrategy_is_different() {
    env e;
    uint64 chainSelector;
    IYieldPeer.Protocol protocol;

    IYieldPeer.Strategy oldStrategy = getStrategy();

    require oldStrategy.chainSelector != chainSelector || oldStrategy.protocol != protocol;

    require ghost_currentStrategyOptimal_eventCount == 0;
    require ghost_strategyUpdated_eventCount == 0;
    setStrategy(e, chainSelector, protocol);
    assert ghost_currentStrategyOptimal_eventCount == 0;
    assert ghost_strategyUpdated_eventCount == 1;
    assert getStrategy() != oldStrategy;
}

rule setStrategy_handlesLocalStrategyChange() {
    env e;
    uint64 chainSelector;
    IYieldPeer.Protocol protocol;

    IYieldPeer.Strategy oldStrategy = getStrategy();

    require oldStrategy.chainSelector == chainSelector &&
            oldStrategy.chainSelector == getThisChainSelector() &&
            oldStrategy.protocol != protocol;

    require oldStrategy.protocol == IYieldPeer.Protocol.Aave => currentContract.s_strategyPool == getAave();
    require oldStrategy.protocol == IYieldPeer.Protocol.Compound => currentContract.s_strategyPool == getCompound();

    uint256 totalValue = getTotalValue(e);
    require totalValue > 0;

    address strategyPool = getStrategyPool();
    uint256 compoundBalanceBefore = usdc.balanceOf(getCompound());
    uint256 aaveBalanceBefore = usdc.balanceOf(addressesProvider.getPool());
    require strategyPool == getCompound() => compoundBalanceBefore - totalValue >= 0 && aaveBalanceBefore + totalValue <= max_uint256;
    require strategyPool == getAave() => aaveBalanceBefore - totalValue >= 0 && compoundBalanceBefore + totalValue <= max_uint256;
    require usdc.balanceOf(currentContract) == 0;

    setStrategy(e, chainSelector, protocol);

    assert strategyPool == getCompound() => usdc.balanceOf(getCompound()) == 
        compoundBalanceBefore - totalValue && usdc.balanceOf(addressesProvider.getPool()) == aaveBalanceBefore + totalValue;
    assert strategyPool == getAave() => usdc.balanceOf(addressesProvider.getPool()) == 
        aaveBalanceBefore - totalValue && usdc.balanceOf(getCompound()) == compoundBalanceBefore + totalValue;
}

rule setStrategy_movesStrategyToNewChain() {
    env e;
    uint64 chainSelector;
    IYieldPeer.Protocol protocol;

    IYieldPeer.Strategy oldStrategy = getStrategy();

    require oldStrategy.chainSelector != chainSelector &&
            oldStrategy.chainSelector == getThisChainSelector();

    uint256 totalValue = getTotalValue(e);
    require totalValue > 0;

    address strategyPool = getStrategyPool();
    uint256 compoundBalanceBefore = usdc.balanceOf(getCompound());
    uint256 aaveBalanceBefore = usdc.balanceOf(addressesProvider.getPool());
    require strategyPool == getCompound() => compoundBalanceBefore - totalValue >= 0;
    require strategyPool == getAave() => aaveBalanceBefore - totalValue >= 0;
    require usdc.balanceOf(currentContract) == 0;

    require ghost_strategyUpdated_eventCount == 0;
    require ghost_ccipMessageSent_eventCount == 0;
    setStrategy(e, chainSelector, protocol);
    assert ghost_strategyUpdated_eventCount == 1;
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 8; // RebalanceNewStrategy
    assert ghost_ccipMessageSent_bridgeAmount_emitted == totalValue;

    assert strategyPool == getCompound() => usdc.balanceOf(getCompound()) == compoundBalanceBefore - totalValue;
    assert strategyPool == getAave() => usdc.balanceOf(addressesProvider.getPool()) == aaveBalanceBefore - totalValue;
}

rule setStrategy_forwardsRebalanceToOldStrategy() {
    env e;
    uint64 chainSelector;
    IYieldPeer.Protocol protocol;

    IYieldPeer.Strategy oldStrategy = getStrategy();

    require oldStrategy.chainSelector != getThisChainSelector() &&
            oldStrategy.chainSelector != chainSelector;

    require ghost_ccipMessageSent_eventCount == 0;
    setStrategy(e, chainSelector, protocol);
    assert ghost_ccipMessageSent_eventCount == 1;
    assert ghost_ccipMessageSent_txType_emitted == 7; // RebalanceOldStrategy
    assert ghost_ccipMessageSent_bridgeAmount_emitted == 0;
}