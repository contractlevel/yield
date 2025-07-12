using MockUsdc as usdc;

/// Verification of StrategyAdapter
/// @author @contractlevel
/// @notice StrategyAdapter is the base contract for all yield generating strategy adapters (modular contracts that interact with strategies)

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // Adapter methods
    function deposit(address,uint256) external;
    function withdraw(address,uint256) external;
    function getTotalValue(address) external returns (uint256);

    // External methods
    function usdc.balanceOf(address) external returns (uint256) envfree;

    // Wildcard dispatcher summaries
    function _.approve(address,uint256) external => DISPATCHER(true);
    function _.transfer(address,uint256) external => DISPATCHER(true);
    function _.transferFrom(address,address,uint256) external => DISPATCHER(true);
    
    // Harness helper methods
    function bytes32ToUint256(bytes32) external returns (uint256) envfree;
    function bytes32ToAddress(bytes32) external returns (address) envfree;
    /// @notice This must be defined in the harness of the strategy adapter being verified
    function getStrategyPool() external returns (address) envfree;
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
/// @notice functions that can only be called by the YieldPeer
definition onlyYieldPeer(method f) returns bool = 
    f.selector == sig:deposit(address,uint256).selector ||
    f.selector == sig:withdraw(address,uint256).selector;

definition DepositEvent() returns bytes32 =
// keccak256(abi.encodePacked("Deposit(address,uint256)"))
    to_bytes32(0xe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c);

definition WithdrawEvent() returns bytes32 =
// keccak256(abi.encodePacked("Withdraw(address,uint256)"))
    to_bytes32(0x884edad9ce6fa2440d8a54cc123490eb96d2768479d49ff9c7366125a9424364);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
/// @notice EventCount: track amount of Deposit event is emitted
ghost mathint ghost_deposit_eventCount {
    init_state axiom ghost_deposit_eventCount == 0;
}

/// @notice EventCount: track amount of Withdraw event is emitted
ghost mathint ghost_withdraw_eventCount {
    init_state axiom ghost_withdraw_eventCount == 0;
}

/// @notice Emitted Value Count: track the total amount deposited based on param emitted by Deposit event
ghost mapping(address => mathint) ghost_deposit_totalAmount_emitted {
    init_state axiom forall address a. ghost_deposit_totalAmount_emitted[a] == 0;
}

/// @notice Emitted Value Count: track the amount withdrawn based on param emitted by Withdraw event
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
                           INVARIANTS
//////////////////////////////////////////////////////////////*/
/// tvl >= deposit_totalAmount_emitted - withdraw_totalAmount_emitted
// invariant totalValue_integrity(env e, address asset)
//     getTotalValue(e, asset) >= ghost_deposit_totalAmount_emitted[asset] - ghost_withdraw_totalAmount_emitted[asset];

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
rule onlyYieldPeer_revertsWhen_notYieldPeer(method f) filtered {f -> onlyYieldPeer(f)} {
    env e;
    calldataarg args;
    require e.msg.sender != currentContract.i_yieldPeer, 
        "onlyYieldPeer functions should always revert if the caller is not the YieldPeer";
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

// @review this does exactly the same as deposit_increases_strategy_balance and deposit_decreases_currentContract_balance
/// do we want less code or quicker debugging? probably quicker debugging
/// why? well if we introduce a new adapter and we run the spec on it, and there is a fail, then we can see clearly by glancing at the prover output
/// but if we have a single rule that checks more than one thing, then we have to read the output to see which one failed
rule deposit_balanceIntegrity() {
    env e;
    uint256 amount;
    require amount > 0, "We are assuming there won't be deposits of 0. (There wont)";

    uint256 strategyBalanceBefore = usdc.balanceOf(getStrategyPool());
    require strategyBalanceBefore + amount <= max_uint256, "should not cause overflow";

    uint256 adapterBalanceBefore = usdc.balanceOf(currentContract);
    require adapterBalanceBefore - amount >= 0, "should not cause underflow";

    deposit(e, usdc, amount);

    uint256 strategyBalanceAfter = usdc.balanceOf(getStrategyPool());
    assert strategyBalanceAfter == strategyBalanceBefore + amount;

    uint256 adapterBalanceAfter = usdc.balanceOf(currentContract);
    assert adapterBalanceAfter == adapterBalanceBefore - amount;
}

rule deposit_increases_tvl() {
    env e;
    uint256 amount;
    require amount > 0, "We are assuming there won't be deposits of 0. (There wont)";

    uint256 beforeTvl = getTotalValue(e, usdc);
    require beforeTvl + amount <= max_uint256, "should not cause overflow";

    deposit(e, usdc, amount);

    uint256 afterTvl = getTotalValue(e, usdc);
    assert afterTvl == beforeTvl + amount;
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

    uint256 beforeBalance = usdc.balanceOf(getStrategyPool());
    require beforeBalance - amount >= 0, "should not cause underflow";

    require e.msg.sender != getStrategyPool(), "StrategyPool will not be the YieldPeer/msg.sender";

    withdraw(e, usdc, amount);

    uint256 afterBalance = usdc.balanceOf(getStrategyPool());
    assert afterBalance == beforeBalance - amount;
}

rule withdraw_decreases_tvl() {
    env e;
    uint256 amount;
    require amount > 0, "We are assuming there won't be withdrawals of 0. (There wont)";

    uint256 beforeTvl = getTotalValue(e, usdc);
    require beforeTvl - amount >= 0, "should not cause underflow";

    withdraw(e, usdc, amount);

    uint256 afterTvl = getTotalValue(e, usdc);
    assert afterTvl == beforeTvl - amount;
}

rule withdraw_increases_yieldPeer_balance() {
    env e;
    uint256 amount;
    require amount > 0, "We are assuming there won't be withdrawals of 0. (There wont)";

    uint256 beforeBalance = usdc.balanceOf(currentContract.i_yieldPeer);
    require beforeBalance + amount <= max_uint256, "should not cause overflow";

    require e.msg.sender != getStrategyPool(), "StrategyPool will not be the YieldPeer/msg.sender";

    withdraw(e, usdc, amount);

    uint256 afterBalance = usdc.balanceOf(currentContract.i_yieldPeer);
    assert afterBalance == beforeBalance + amount;
}

rule withdraw_emits_event() {
    env e;
    uint256 amount;

    require ghost_withdraw_eventCount == 0, "Starting at 0 emitted events";
    require ghost_withdraw_totalAmount_emitted[usdc] == 0, "0 emitted events, so 0 emitted amount";

    withdraw(e, usdc, amount);

    assert ghost_withdraw_eventCount == 1;
    assert ghost_withdraw_totalAmount_emitted[usdc] == amount;
}