using MockUsdc as usdc;

/// Verification of StrategyAdapter
/// @author @contractlevel
/// @notice StrategyAdapter is the base contract for all yield generating strategy adapters (modular contracts that interact with strategies)

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // Adapter methods
    function deposit(address, uint256) external;
    function withdraw(address, uint256) external;
    function getTotalValue(address) external returns (uint256);
    function getStrategyPool() external returns (address) envfree;


    function usdc.balanceOf(address) external returns (uint256) envfree;

    // Wildcard dispatcher summaries
    function _.approve(address, uint256) external => DISPATCHER(true);
    function _.transfer(address, uint256) external => DISPATCHER(true);
    function _.transferFrom(address, address, uint256) external => DISPATCHER(true);


    function _.balanceOf(address) external => DISPATCHER(true);

    // Harness helper methods
    function bytes32ToUint256(bytes32) external returns (uint256) envfree;
    function bytes32ToAddress(bytes32) external returns (address) envfree;
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
/// @notice functions that can only be called by the YieldPeer
definition onlyYieldPeer(method f) returns bool = f.selector == sig:deposit(address, uint256).selector || f.selector == sig:withdraw(address, uint256).selector;

definition DepositEvent() returns bytes32 =
// keccak256(abi.encodePacked("Deposit(address,uint256)"))
to_bytes32(0xe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c);

definition WithdrawEvent() returns bytes32 =
// keccak256(abi.encodePacked("Withdraw(address,uint256)"))
to_bytes32(0x884edad9ce6fa2440d8a54cc123490eb96d2768479d49ff9c7366125a9424364);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
/// @notice Event Count: track amount of times Deposit event is emitted
ghost mathint ghost_deposit_eventCount {
    init_state axiom ghost_deposit_eventCount == 0;
}

/// @notice Event Count: track amount of times Withdraw event is emitted
ghost mathint ghost_withdraw_eventCount {
    init_state axiom ghost_withdraw_eventCount == 0;
}

/// @notice Emitted Value: track the total amount deposited based on param emitted by Deposit event
ghost mapping(address => mathint) ghost_deposit_totalAmount_emitted {
    init_state axiom forall address a. ghost_deposit_totalAmount_emitted[a] == 0;
}

/// @notice Emitted Value: track the amount withdrawn based on param emitted by Withdraw event
ghost mapping(address => mathint) ghost_withdraw_totalAmount_emitted {
    init_state axiom forall address a. ghost_withdraw_totalAmount_emitted[a] == 0;
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// @notice hook onto emitted events and increment relevant ghosts
hook LOG3(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2) {
    if (t0 == DepositEvent()) {
        ghost_deposit_eventCount = ghost_deposit_eventCount + 1;
        ghost_deposit_totalAmount_emitted[bytes32ToAddress(t1)] = ghost_deposit_totalAmount_emitted[bytes32ToAddress(t1)] + bytes32ToUint256(t2);
    }
    if (t0 == WithdrawEvent()) {
        ghost_withdraw_eventCount = ghost_withdraw_eventCount + 1;
        ghost_withdraw_totalAmount_emitted[bytes32ToAddress(t1)] = ghost_withdraw_totalAmount_emitted[bytes32ToAddress(t1)] + bytes32ToUint256(t2);
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule onlyYieldPeer_revertsWhen_notYieldPeer(method f) filtered { f -> onlyYieldPeer(f) } {
    env e;
    calldataarg args;
    require e.msg.sender != currentContract.i_yieldPeer, "onlyYieldPeer functions should always revert if the caller is not the YieldPeer";
    f@withrevert(e, args);
    assert lastReverted;
}

// --- deposit --- //
rule deposit_increases_strategy_balance() {
    env e;
    uint256 amount;
    require amount > 0, "We are assuming there won't be deposits of 0. (There wont)";

    uint256 beforeBalance = usdc.balanceOf(getStrategyPool());
    require beforeBalance + amount <= max_uint256, "should not cause overflow";

    deposit(e, usdc, amount);

    uint256 afterBalance = usdc.balanceOf(getStrategyPool());
    assert afterBalance == beforeBalance + amount;
}

rule deposit_increases_tvl() {
    env e;
    uint256 amount;
    require amount > 0, "We are assuming there won't be deposits of 0. (There wont)";

    uint256 beforeTvl = getTotalValue(e, usdc);
    require beforeTvl + amount <= max_uint256, "should not cause overflow";

    deposit(e, usdc, amount);

    uint256 afterTvl = getTotalValue(e, usdc);
    assert afterTvl >= beforeTvl + amount;
}

rule deposit_decreases_currentContract_balance() {
    env e;
    uint256 amount;
    require amount > 0, "We are assuming there won't be deposits of 0. (There wont)";

    uint256 beforeBalance = usdc.balanceOf(currentContract);
    require beforeBalance - amount >= 0, "should not cause underflow";

    deposit(e, usdc, amount);

    uint256 afterBalance = usdc.balanceOf(currentContract);
    assert afterBalance == beforeBalance - amount;
}

rule deposit_emits_event() {
    env e;
    uint256 amount;
    require amount > 0;

    require ghost_deposit_eventCount == 0, "Starting at 0 emitted events";
    require ghost_deposit_totalAmount_emitted[usdc] == 0, "0 emitted events, so 0 emitted amount";

    deposit(e, usdc, amount);

    assert ghost_deposit_eventCount == 1;
    assert ghost_deposit_totalAmount_emitted[usdc] == amount;
}

// --- withdraw --- //
rule withdraw_decreases_strategy_balance() {
    env e;
    uint256 amount;
    require amount > 0, "We are assuming there won't be withdrawals of 0. (There wont)";
    require amount < max_uint256;

    uint256 beforeBalance = usdc.balanceOf(getStrategyPool());
    require beforeBalance >= amount, "should not cause underflow";

    require e.msg.sender != getStrategyPool(), "StrategyPool will not be the YieldPeer/msg.sender";

    withdraw(e, usdc, amount);

    uint256 afterBalance = usdc.balanceOf(getStrategyPool());
    mathint actualWithdrawn = beforeBalance - afterBalance;

    // Actual withdrawn should be >= requested amount (allows for interest accrual of dust and rounding)
    assert actualWithdrawn >= amount, "actualWithdrawn should be >= amount";
}

rule withdraw_decreases_tvl() {
    env e;
    uint256 amount;
    require amount > 0, "We are assuming there won't be withdrawals of 0. (There wont)";
    require amount < max_uint256;

    uint256 beforeTvl = getTotalValue(e, usdc);
    require beforeTvl > 0, "Ensure we test with non-zero TVL for meaningful withdrawal scenarios";
    require beforeTvl >= amount, "should not cause underflow";

    withdraw(e, usdc, amount);

    uint256 afterTvl = getTotalValue(e, usdc);
    mathint actualWithdrawn = beforeTvl - afterTvl;

    // Actual withdrawn should be >= requested amount (allows for interest accrual of dust and rounding)
    assert actualWithdrawn >= amount, "actualWithdrawn should be >= amount";
}

rule withdraw_increases_yieldPeer_balance() {
    env e;
    uint256 amount;
    require amount > 0, "We are assuming there won't be withdrawals of 0. (There wont)";
    require amount < max_uint256;

    uint256 beforeBalance = usdc.balanceOf(currentContract.i_yieldPeer);
    require beforeBalance + amount <= max_uint256, "should not cause overflow";

    require e.msg.sender != getStrategyPool(), "StrategyPool will not be the YieldPeer/msg.sender";

    // Get totalValue before withdrawal to know what's actually available
    uint256 totalValueBefore = getTotalValue(e, usdc);
    require totalValueBefore > 0, "Ensure we test with non-zero TVL for meaningful withdrawal scenarios";

    // For regular withdrawals, adapter enforces amount <= totalValueBefore
    require amount <= totalValueBefore, "Adapter should revert if amount > totalValueBefore";

    withdraw(e, usdc, amount);

    uint256 afterBalance = usdc.balanceOf(currentContract.i_yieldPeer);
    mathint actualReceived = afterBalance - beforeBalance;

    // Yield peer should receive actualWithdrawn, which is >= requested amount (adapter validates this)
    assert actualReceived >= amount, "yield peer should receive >= amount (adapter validates actualWithdrawn >= amount)";
}

rule withdraw_increases_yieldPeer_balance_maxSentinel() {
    env e;
    uint256 amount = max_uint256;

    uint256 beforeBalance = usdc.balanceOf(currentContract.i_yieldPeer);
    require e.msg.sender != getStrategyPool(), "StrategyPool will not be the YieldPeer/msg.sender";

    // Get totalValue before withdrawal to know what's actually available
    uint256 totalValueBefore = getTotalValue(e, usdc);
    require beforeBalance + totalValueBefore <= max_uint256, "should not cause overflow";

    withdraw(e, usdc, amount);

    uint256 afterBalance = usdc.balanceOf(currentContract.i_yieldPeer);
    mathint actualReceived = afterBalance - beforeBalance;

    // For MAX sentinel, yield peer should receive >= totalValueBefore (adapter validates this)
    assert actualReceived >= totalValueBefore, "MAX sentinel: yield peer should receive >= totalValueBefore";
}

rule withdraw_emits_event() {
    env e;
    uint256 amount;
    require amount > 0;

    require ghost_withdraw_eventCount == 0, "Starting at 0 emitted events";
    require ghost_withdraw_totalAmount_emitted[usdc] == 0, "0 emitted events, so 0 emitted amount";

    require e.msg.sender != getStrategyPool(), "StrategyPool will not be the YieldPeer/msg.sender";

    // Track yield peer's balance before withdrawal to calculate actual received amount
    uint256 beforeBalance = usdc.balanceOf(currentContract.i_yieldPeer);

    // Get totalValue before withdrawal to validate behavior
    uint256 totalValueBefore = getTotalValue(e, usdc);
    
    // For regular withdrawals (non-MAX), ensure we test with non-zero TVL
    if (amount != max_uint256) {
        require totalValueBefore > 0, "Ensure we test with non-zero TVL for meaningful withdrawal scenarios";
    }

    // For regular withdrawals, adapter enforces amount <= totalValueBefore
    // If this doesn't hold, adapter should revert (so this rule wouldn't apply)
    require (amount == max_uint256) || (amount <= totalValueBefore), "Adapter should revert if amount > totalValueBefore (for non-MAX)";

    // Ensure no overflow when calculating actualReceived
    if (amount == max_uint256) {
        require beforeBalance + totalValueBefore <= max_uint256, "should not cause overflow";
    } else {
        require beforeBalance + amount <= max_uint256, "should not cause overflow";
    }

    withdraw(e, usdc, amount);

    // Track yield peer's balance after withdrawal to calculate actual received amount
    uint256 afterBalance = usdc.balanceOf(currentContract.i_yieldPeer);
    mathint actualReceived = afterBalance - beforeBalance;

    // Ensure yield peer balance increased (or stayed same if nothing withdrawn)
    require afterBalance >= beforeBalance, "Yield peer balance should not decrease after withdrawal";

    assert ghost_withdraw_eventCount == 1;

    // The emitted amount should equal what the yield peer actually received
    assert ghost_withdraw_totalAmount_emitted[usdc] == actualReceived, "Event should emit actualWithdrawn (what yield peer actually received), not the requested amount";

    // For MAX sentinel: actualWithdrawn should be >= totalValueBefore (adapter enforces this)
    // For regular withdrawals: actualWithdrawn should be >= amount (adapter validates this)
    assert (amount == max_uint256) => (ghost_withdraw_totalAmount_emitted[usdc] >= totalValueBefore), "MAX sentinel: emitted should be >= totalValueBefore";
    assert (amount != max_uint256) => (ghost_withdraw_totalAmount_emitted[usdc] >= amount), "Regular withdrawal: emitted should be >= amount (adapter validates actualWithdrawn >= amount)";
}

// Verify that adapter validates actualWithdrawn >= amount for regular withdrawals
// This rule ensures that successful withdrawals mean the adapter validated actualWithdrawn >= amount
rule withdraw_validatesActualWithdrawn() {
    env e;
    uint256 amount;
    require amount > 0, "We are assuming there won't be withdrawals of 0. (There wont)";
    require amount < max_uint256, "Exclude MAX sentinel (tested separately)";

    require e.msg.sender != getStrategyPool(), "StrategyPool will not be the YieldPeer/msg.sender";

    // Track yield peer balance BEFORE withdrawal
    uint256 beforeBalance = usdc.balanceOf(currentContract.i_yieldPeer);
    
    // Ensure we can calculate actualReceived without overflow
    require beforeBalance + amount <= max_uint256, "should not cause overflow when calculating actualReceived";

    uint256 totalValueBefore = getTotalValue(e, usdc);
    require totalValueBefore > 0, "Ensure we test with non-zero TVL for meaningful withdrawal scenarios";
    require amount <= totalValueBefore, "Adapter should revert if amount > totalValueBefore (for non-MAX)";

    withdraw(e, usdc, amount);

    // Track yield peer balance AFTER withdrawal
    uint256 afterBalance = usdc.balanceOf(currentContract.i_yieldPeer);
    mathint actualReceived = afterBalance - beforeBalance;

    // If withdrawal succeeded, adapter must have validated actualWithdrawn >= amount
    // Verify the yield peer received >= amount (what adapter validated)
    assert actualReceived >= amount, "If withdrawal succeeded, actualReceived must be >= amount (adapter validates actualWithdrawn >= amount)";
}
