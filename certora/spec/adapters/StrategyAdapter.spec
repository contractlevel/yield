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
definition onlyYieldPeer(method f) returns bool = 
    f.selector == sig:deposit(address, uint256).selector || 
    f.selector == sig:withdraw(address, uint256).selector;

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
        ghost_deposit_totalAmount_emitted[bytes32ToAddress(t1)] = 
        ghost_deposit_totalAmount_emitted[bytes32ToAddress(t1)] + bytes32ToUint256(t2);
    }
    if (t0 == WithdrawEvent()) {
        ghost_withdraw_eventCount = ghost_withdraw_eventCount + 1;
        ghost_withdraw_totalAmount_emitted[bytes32ToAddress(t1)] = 
        ghost_withdraw_totalAmount_emitted[bytes32ToAddress(t1)] + bytes32ToUint256(t2);
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
    address strategyPool = getStrategyPool();

    uint256 beforeBalance = usdc.balanceOf(strategyPool);

    require e.msg.sender != strategyPool, "StrategyPool will not be the YieldPeer/msg.sender";

    uint256 actualWithdrawn = withdraw(e, usdc, amount);
    require beforeBalance - actualWithdrawn >= 0, "should not cause underflow";

    uint256 afterBalance = usdc.balanceOf(strategyPool);
    assert afterBalance == beforeBalance - actualWithdrawn;
}

rule withdraw_decreases_tvl() {
    env e;
    uint256 amount;

    uint256 beforeTvl = getTotalValue(e, usdc);

    uint256 actualWithdrawn = withdraw(e, usdc, amount);

    uint256 afterTvl = getTotalValue(e, usdc);

    assert afterTvl == beforeTvl - actualWithdrawn;
}

rule withdraw_increases_yieldPeer_balance() {
    env e;
    uint256 amount;

    require e.msg.sender != getStrategyPool(), "StrategyPool will not be the YieldPeer/msg.sender";

    uint256 beforeBalance = usdc.balanceOf(currentContract.i_yieldPeer);

    uint256 actualWithdrawn = withdraw(e, usdc, amount);
    require beforeBalance + actualWithdrawn <= max_uint256;

    uint256 afterBalance = usdc.balanceOf(currentContract.i_yieldPeer);

    assert afterBalance == beforeBalance + actualWithdrawn;
}

rule withdraw_rebalanceWithdraw_zeroes_getTotalValue() {
    env e;
    withdraw(e, usdc, max_uint256);
    assert getTotalValue(e, usdc) == 0;
}

rule withdraw_emits_event() {
    env e;
    uint256 amount;

    require ghost_withdraw_eventCount == 0, "Starting at 0 emitted events";
    require ghost_withdraw_totalAmount_emitted[usdc] == 0, "0 emitted events, so 0 emitted amount";

    uint256 actualWithdrawn = withdraw(e, usdc, amount);

    assert ghost_withdraw_eventCount == 1;
    assert ghost_withdraw_totalAmount_emitted[usdc] == actualWithdrawn;
}

/// @notice a rebalance withdraw is when the amount passed is max_uint256
// @review
rule withdraw_rebalanceWithdraw_revertsWhen_actualWithdrawnIsLessThanTotalValue() {
    env e;
    uint256 amount = max_uint256;

    uint256 beforeTvl = getTotalValue(e, usdc);
    require beforeTvl > 0, "Ensure we test with non-zero TVL for meaningful withdrawal scenarios";

    // require compound

    /// @dev revert conditions not being verified
    require e.msg.sender == currentContract.i_yieldPeer;
    require e.msg.value == 0;

    withdraw@withrevert(e, usdc, amount);
    assert lastReverted;
}

/// @notice a user withdraw is when the amount passed is not max_uint256
rule withdraw_userWithdraw_revertsWhen_withdrawAmountExceedsTotalValue() {
    env e;
    uint256 amount;
    require amount > 0;
    require amount < max_uint256;

    uint256 beforeTvl = getTotalValue(e, usdc);
    require beforeTvl > 0, "Ensure we test with non-zero TVL for meaningful withdrawal scenarios";

    /// @dev revert condition being verified
    require amount > beforeTvl;

    /// @dev revert conditions not being verified
    require e.msg.sender == currentContract.i_yieldPeer;
    require e.msg.value == 0;

    withdraw@withrevert(e, usdc, amount);
    assert lastReverted;
}

// @review
// rule withdraw_userWithdraw_revertsWhen_incorrectWithdrawAmount() {}

rule withdraw_amountIntegrity() {
    env e;
    uint256 amount;
    uint256 totalValue = getTotalValue(e, usdc);
    uint256 actualWithdrawn = withdraw(e, usdc, amount);

    assert amount == max_uint256 => actualWithdrawn >= totalValue;
    assert amount != max_uint256 => actualWithdrawn >= amount;
}