# New Invariants Plan

> Date: 2026-02-26
> Branch: `fix/adapter-withdraw-checks`

## Overview

All 4 steps of the modular handler refactor are complete and all tests pass. This plan identifies invariants that are not currently tested and should be added to `Invariant.t.sol`.

The existing invariants test: total share accounting, total value integrity, per-user redemption, event emission pairing (Deposit↔ShareMintUpdate, Withdraw↔ShareBurnUpdate), fee bookkeeping, fee rate bounds, strategy registry consistency, adapter drain after rebalance, and rebalance event counts.

The gaps fall into five categories:

1. **Amount flow consistency** — amounts emitted in events match amounts tracked in ghosts
2. **Emission count pairing** — 1:1 event relationships not yet checked
3. **PingPong completion** — deposits/withdrawals that bounce through the PingPong path always complete
4. **Per-user share balance** — per-user mint/burn accounting
5. **Adapter security** — access control and Compound anti-borrow

---

## Infrastructure Prerequisite: `ManualMockRouter`

The PingPong invariants (14 and 15) require a routing infrastructure change. The existing `MockCCIPRouter` from chainlink-local delivers messages **synchronously** — every `ccipSend` call immediately triggers `ccipReceive` on the destination within the same call frame. This means setting the strategy adapter to `address(0)` and then calling `deposit()` creates infinite recursion:

```
deposit() → ccipSend(DepositToStrategy)
  → strategy.ccipReceive() → adapter==0 → PingPong → ccipSend(DepositPingPong)
    → parent.ccipReceive() → retries → ccipSend(DepositToStrategy)
      → strategy.ccipReceive() → adapter STILL 0 → PingPong → ...
        → EVM call depth exceeded → REVERT (swallowed by fail_on_revert)
```

There is no point in this call stack where adapter state can be restored between the ping and the pong. The unit tests work because `ccipLocalSimulatorFork.switchChainAndRouteMessage` delivers one hop at a time, allowing `stdstore` writes between hops.

### Solution: `ManualMockRouter`

A new test contract that inherits `MockCCIPRouter` and adds a lazy delivery mode:

```solidity
contract ManualMockRouter is MockCCIPRouter {
    struct QueuedMessage {
        uint64 destChainSelector;
        Client.EVM2AnyMessage message;
        address sender;
    }

    QueuedMessage[] private s_queue;
    bool private s_lazyMode;

    function setLazyMode(bool lazy) external { s_lazyMode = lazy; }
    function queueLength() external view returns (uint256) { return s_queue.length; }

    function ccipSend(uint64 destChainSelector, Client.EVM2AnyMessage calldata message)
        external payable override returns (bytes32)
    {
        if (s_lazyMode) {
            s_queue.push(QueuedMessage(destChainSelector, message, msg.sender));
            return keccak256(abi.encode(s_queue.length, destChainSelector));
        }
        return super.ccipSend(destChainSelector, message);
    }

    function routeNext() external {
        require(s_queue.length > 0, "Queue empty");
        QueuedMessage memory m = s_queue[s_queue.length - 1];
        s_queue.pop();
        bool wasLazy = s_lazyMode;
        s_lazyMode = false;
        vm.prank(m.sender);
        super.ccipSend(m.destChainSelector, m.message);
        s_lazyMode = wasLazy;
    }
}
```

- **Normal operation** (`lazyMode = false`): identical to `MockCCIPRouter`. All existing handler functions are unaffected.
- **Lazy mode** (`lazyMode = true`): `ccipSend` queues rather than delivers. `routeNext()` delivers the next queued message synchronously (with lazy mode temporarily disabled to prevent re-queuing).

`Invariant.t.sol` is updated to deploy `ManualMockRouter` instead of `MockCCIPRouter`. All existing tests continue to pass because normal mode behaviour is unchanged.

### How the PingPong handler functions use it

```
depositPingPong() {
    router.setLazyMode(true);
    vm.store(strategyPeer, ADAPTER_SLOT, 0);         // set adapter to 0

    deposit();                                        // queues DepositToStrategy, does NOT deliver

    router.routeNext();    // deliver DepositToStrategy → adapter==0 → PingPong queued
    vm.store(strategyPeer, ADAPTER_SLOT, original);  // restore adapter ← gap between hops
    router.routeNext();    // deliver PingPong → parent retries → DepositToStrategy queued
    router.routeNext();    // deliver retry → adapter restored → deposits → SharesMinted queued
    // drain any remaining messages (ShareMintUpdate, CCIPMessageReceived, etc.)
    while (router.queueLength() > 0) { router.routeNext(); }

    router.setLazyMode(false);
}
```

Note: the exact number of `routeNext()` calls varies by deposit path (parent-is-strategy vs child-is-strategy). The handler function must handle both cases based on `parent.getStrategy().chainSelector`.

---

## New Invariants (no new code required)

All invariants below use existing ghost variables and live contract reads. No new ghosts or handler functions are needed.

---

### 1. `invariant_depositInitiated_amount_equals_userPrincipal`

```
ghost_yieldPeer_event_DepositInitiated_param_amount_totalSum == ghost_totalUsdcDeposited_userPrincipal
```

**Why:** `DepositInitiated` emits `amountToDepositMinusFee`. `ghost_totalUsdcDeposited_userPrincipal` = sum(depositAmount - fee) for every deposit. These must be equal.

**Catches:** Fee deducted incorrectly before emitting, or wrong amount emitted in `DepositInitiated`.

---

### 2. `invariant_strategyAdapter_deposit_matchesPeerEmission`

```
ghost_strategyAdapter_event_Deposit_param_amount_totalSum == ghost_yieldPeer_event_DepositToStrategy_param_amount_totalSum
```

**Why:** Every `DepositToStrategy(adapter, amount)` emitted by the peer must correspond to a `Deposit(usdc, amount)` emitted by the adapter with the same amount. These are always in the same transaction, so the totals must match.

**Catches:** Funds lost between the peer and the adapter during deposit. Also verifies that the adapter emits the event with the correct amount.

---

### 3. `invariant_sharesBurned_matchesGhost`

```
ghost_yieldPeer_event_SharesBurned_param_amount_totalSum == ghost_totalSharesBurned
```

**Why:** `ghost_totalSharesBurned` accumulates `shareBurnAmount` directly from `transferAndCall` in the handler. `ghost_yieldPeer_event_SharesBurned_param_amount_totalSum` accumulates the amount from the `SharesBurned` event. Both should track the same quantity.

**Catches:** Discrepancy between what the peer burned and what the share token emitted.

---

### 4. `invariant_withdrawInitiated_matchesSharesBurned`

```
ghost_yieldPeer_event_WithdrawInitiated_param_amount_totalSum == ghost_totalSharesBurned
```

**Why:** `WithdrawInitiated` emits `shareBurnAmount`. `ghost_totalSharesBurned` accumulates `shareBurnAmount`. Both should equal the total shares burned system-wide.

**Catches:** Wrong amount emitted in `WithdrawInitiated`, or shares burned without a `WithdrawInitiated` event.

---

### 5. `invariant_feesWithdrawn_matchesGhost`

```
ghost_yieldFees_event_FeesWithdrawn_param_amount_totalSum == ghost_totalFeesWithdrawnInStablecoin
```

**Why:** `ghost_totalFeesWithdrawnInStablecoin` is updated in the handler before withdrawal with the peer balance. `ghost_yieldFees_event_FeesWithdrawn_param_amount_totalSum` accumulates from emitted events. These should agree.

**Catches:** Wrong amount emitted in `FeesWithdrawn`, or fees withdrawn without an event.

---

### 6. `invariant_sharesMinted_emissions_matchDeposits`

```
ghost_yieldPeer_event_SharesMinted_emissions == ghost_yieldPeer_event_DepositInitiated_emissions
```

**Why:** Every deposit emits exactly one `DepositInitiated` and exactly one `SharesMinted`. The peer that mints shares emits `SharesMinted` once per completed deposit.

**Catches:** Missing mint (shares not minted), double mint, or a deposit that completes without minting.

---

### 7. `invariant_sharesBurned_emissions_matchWithdrawals`

```
ghost_yieldPeer_event_SharesBurned_emissions == ghost_yieldPeer_event_WithdrawInitiated_emissions
```

**Why:** Every withdrawal burns shares exactly once. `WithdrawInitiated` and `SharesBurned` are both emitted once per `transferAndCall` call.

**Catches:** Missing burn, double burn, or withdrawal initiated without burning shares.

---

### 8. `invariant_ccip_sentEqualsReceived`

```
ghost_yieldPeer_event_CCIPMessageSent_emissions == ghost_yieldPeer_event_CCIPMessageReceived_emissions
```

**Why:** Whether the router is in normal or lazy mode, every message that is routed must be received. In normal mode this is guaranteed by synchronous delivery. In lazy mode the handler functions drain the queue completely before returning, so all sent messages are delivered by the time each handler call ends.

**Catches:** Routing bugs, messages sent to wrong destination, handler functions that fail to drain the queue.

---

### 9. `invariant_strategyUpdated_emissions_matchRebalances`

```
ghost_parent_event_StrategyUpdated_emissions == ghost_rebalances
```

**Why:** Every successful rebalance calls `parent.rebalance()` which calls `_setStrategy()` which emits `StrategyUpdated`. No other code path emits `StrategyUpdated`. So `StrategyUpdated` emissions == rebalances performed.

**Catches:** Missing `StrategyUpdated` event, extra `StrategyUpdated`, or rebalance completing without updating strategy.

---

### 10. `invariant_strategyUpdated_matchesDecodedReport`

```solidity
if (handler.ghost_rebalances() > 0) {
    assertEq(
        handler.ghost_parent_event_StrategyUpdated_param_chainSelector(),
        handler.ghost_rebalancer_event_ReportDecoded_param_chainSelector(),
        "StrategyUpdated chain selector must match decoded CRE report"
    );
    assertEq(
        handler.ghost_parent_event_StrategyUpdated_param_protocolId(),
        handler.ghost_rebalancer_event_ReportDecoded_param_protocolId(),
        "StrategyUpdated protocolId must match decoded CRE report"
    );
}
```

**Why:** The `StrategyUpdated` event should contain the exact same strategy that was decoded from the CRE report. The existing `invariant_decodedCREReportStrategy_matchesParentStrategy` checks decoded report vs live state. This checks decoded report vs emitted event — a separate code path.

**Catches:** Mismatch between what was decoded, what was emitted, and what was stored.

---

### 11. `invariant_feeRate_consistentAcrossChains`

```
parent.getFeeRate() == child1.getFeeRate() == child2.getFeeRate()
```

In practice, assert each child equals parent:
```solidity
handler.forEachChainSelector(this.checkFeeRateConsistencyPerChainSelector);
```

**Why:** The handler's `setFeeRate` calls all three peers atomically. They should always have the same fee rate. The existing `invariant_feeRate_bounds` only checks `<= maxFeeRate`, not cross-chain consistency.

**Catches:** One peer's fee rate call silently failing, leaving chains out of sync.

---

### 12. `invariant_feeRate_matchesGhost`

```
ghost_feeRate == parent.getFeeRate()
```

**Why:** `ghost_feeRate` mirrors the fee rate set in `setFeeRate`. Combined with invariant 11, this also implies `ghost_feeRate == child1.getFeeRate() == child2.getFeeRate()`.

**Catches:** Ghost not updated correctly when fee rate changes.

---

### 13. `invariant_perUser_shareBalance_integrity`

```solidity
handler.forEachUser(this.checkPerUserShareBalanceIntegrity);

function checkPerUserShareBalanceIntegrity(address user) external view {
    uint256 minted = handler.ghost_totalSharesMintedPerUser(user);
    uint256 burned = handler.ghost_totalSharesBurnedPerUser(user);
    assertEq(
        share.balanceOf(user),
        minted - burned,
        "Invariant violated: User share balance must equal minted minus burned"
    );
}
```

Also check admin separately:
```solidity
assertEq(
    handler.getAdminShareBalance(),
    handler.ghost_totalSharesMintedPerUser(admin) - handler.ghost_totalSharesBurnedPerUser(admin)
);
```

**Why:** The global share integrity invariants check totals. This checks the per-user invariant. `ghost_totalSharesMintedPerUser` is accumulated from `SharesMinted` events; `ghost_totalSharesBurnedPerUser` is accumulated from `shareBurnAmount` in `transferAndCall`. Their difference must equal the current balance.

**Note:** The admin address used in the check needs to be exposed from the handler. A `getAdmin()` external view function should be added to Handler.

**Catches:** Shares minted to wrong user, shares burned from wrong user, double-counting.

---

## New Invariants Requiring New Code

---

### 14. `invariant_depositPingPong_alwaysCompletes`

**Requires:** `ManualMockRouter` + new ghosts + `depositPingPong()` handler function.

**Ghosts to add:**
```solidity
uint256 public ghost_depositPingPong_calls;
uint256 public ghost_depositPingPong_completions;
```

**Handler function to add:**
```solidity
function depositPingPong(uint256 depositSeed, uint256 userSeed) public {
    ghost_depositPingPong_calls++;

    IYieldPeer.Strategy memory strategy = parent.getStrategy();
    address strategyPeer = _getPeer(strategy.chainSelector);
    address originalAdapter = IYieldPeer(strategyPeer).getActiveStrategyAdapter();

    router.setLazyMode(true);
    vm.store(address(strategyPeer), ACTIVE_ADAPTER_SLOT, bytes32(0));

    uint256 sharesMintedBefore = ghost_yieldPeer_event_SharesMinted_emissions;

    _doDeposit(depositSeed, userSeed);  // queues initial CCIP message

    // Route hop-by-hop, restoring adapter before the retry reaches strategy
    _routePingPongDeposit(strategy.chainSelector, strategyPeer, originalAdapter);

    if (ghost_yieldPeer_event_SharesMinted_emissions == sharesMintedBefore + 1) {
        ghost_depositPingPong_completions++;
    }

    router.setLazyMode(false);
}
```

Where `_routePingPongDeposit` routes messages step-by-step, restoring the adapter at the correct point between the PingPong bounce and the retry. The exact number of `routeNext()` calls differs depending on whether the strategy is on the parent chain or a child chain — `_routePingPongDeposit` branches on `strategy.chainSelector == parent.chainSelector`.

**Invariant:**
```solidity
function invariant_depositPingPong_alwaysCompletes() public view {
    assertEq(
        handler.ghost_depositPingPong_calls(),
        handler.ghost_depositPingPong_completions(),
        "Every depositPingPong call must complete with exactly one SharesMinted"
    );
}
```

**Why:** If the PingPong path has a bug (wrong amount forwarded, message lost, wrong adapter restored), the deposit will not complete and the completion counter will fall behind the call counter.

**Catches:** Amount manipulation in PingPong routing, retry sent to wrong peer, adapter not restored correctly, SharesMinted emitted zero or more than once per PingPong deposit.

---

### 15. `invariant_withdrawPingPong_alwaysCompletes`

**Requires:** `ManualMockRouter` + new ghosts + `withdrawPingPong()` handler function.

**Ghosts to add:**
```solidity
uint256 public ghost_withdrawPingPong_calls;
uint256 public ghost_withdrawPingPong_completions;
```

**Handler function to add:** Same structure as `depositPingPong` but calls `_doWithdraw` and checks for `WithdrawCompleted` emission rather than `SharesMinted`.

**Invariant:**
```solidity
function invariant_withdrawPingPong_alwaysCompletes() public view {
    assertEq(
        handler.ghost_withdrawPingPong_calls(),
        handler.ghost_withdrawPingPong_completions(),
        "Every withdrawPingPong call must complete with exactly one WithdrawCompleted"
    );
}
```

**Why:** Same argument as invariant 14 for the withdrawal path.

**Catches:** Amount manipulation in PingPong withdrawal routing, USDC not returned to user, WithdrawCompleted missing or doubled.

---

### 16. `invariant_strategyAdapter_onlyYieldPeer`

**Requires:** New ghost flags in Ghosts.t.sol + new handler function `attemptUnauthorizedAdapterAccess()`.

**Ghosts to add:**
```solidity
bool public ghost_flag_adapter_unauthorizedDepositSucceeded;
bool public ghost_flag_adapter_unauthorizedWithdrawSucceeded;
```

**Handler function to add:**
```solidity
function attemptUnauthorizedAdapterAccess(uint256 callerSeed, uint256 adapterSeed, uint256 depositAmount) public {
    address caller = _seedToAddress(callerSeed);
    vm.assume(caller != address(parent) && caller != address(child1) && caller != address(child2));

    address adapter = _selectAdapter(adapterSeed);

    depositAmount = bound(depositAmount, MIN_DEPOSIT_AMOUNT, MAX_DEPOSIT_AMOUNT);
    deal(address(usdc), caller, depositAmount);

    _changePrank(caller);
    try IStrategyAdapter(adapter).deposit(address(usdc), depositAmount) {
        ghost_flag_adapter_unauthorizedDepositSucceeded = true;
    } catch {}
    try IStrategyAdapter(adapter).withdraw(address(usdc), depositAmount) {
        ghost_flag_adapter_unauthorizedWithdrawSucceeded = true;
    } catch {}
    _stopPrank();
}
```

Where `_selectAdapter` picks from the 6 deployed adapters (aave/compound × parent/child1/child2).

**Invariant:**
```solidity
function invariant_strategyAdapter_onlyYieldPeer() public view {
    assertFalse(handler.ghost_flag_adapter_unauthorizedDepositSucceeded(), "...");
    assertFalse(handler.ghost_flag_adapter_unauthorizedWithdrawSucceeded(), "...");
}
```

**Why:** `StrategyAdapter.onlyYieldPeer` is a critical security modifier. If it can be bypassed, anyone can drain the strategy.

**Catches:** `onlyYieldPeer` modifier misconfigured or missing, wrong `i_yieldPeer` set in constructor.

---

### 17. `invariant_compoundAdapter_noBorrowing`

**Requires:** `IComet` is already imported in `Invariant.t.sol`. The compound pool address and the adapter addresses are already accessible.

**Invariant:**
```solidity
function invariant_compoundAdapter_noBorrowing() public view {
    assertEq(IComet(networkConfig.protocols.comet).borrowBalanceOf(address(compoundV3AdapterParent)), 0, "...");
    assertEq(IComet(networkConfig.protocols.comet).borrowBalanceOf(address(compoundV3AdapterChild1)), 0, "...");
    assertEq(IComet(networkConfig.protocols.comet).borrowBalanceOf(address(compoundV3AdapterChild2)), 0, "...");
}
```

**Why:** `CompoundV3Adapter` has an explicit `WithdrawAmountExceedsTotalValue` check to prevent borrowing. This invariant verifies the check actually works — no adapter ever enters a debt position in Compound. If the borrow balance is ever non-zero, the adapter is effectively borrowing from the protocol with user funds as collateral.

**Catches:** Anti-borrow check failing, incorrect `supplyBalance` read, amount calculation overflow that bypasses the check.

---

## Summary Table

| # | Invariant | New Code? | Category |
|---|-----------|-----------|----------|
| 1 | `depositInitiated_amount_equals_userPrincipal` | None | Amount flow |
| 2 | `strategyAdapter_deposit_matchesPeerEmission` | None | Amount flow |
| 3 | `sharesBurned_matchesGhost` | None | Amount flow |
| 4 | `withdrawInitiated_matchesSharesBurned` | None | Amount flow |
| 5 | `feesWithdrawn_matchesGhost` | None | Amount flow |
| 6 | `sharesMinted_emissions_matchDeposits` | None | Emission count |
| 7 | `sharesBurned_emissions_matchWithdrawals` | None | Emission count |
| 8 | `ccip_sentEqualsReceived` | None | CCIP |
| 9 | `strategyUpdated_emissions_matchRebalances` | None | Rebalance |
| 10 | `strategyUpdated_matchesDecodedReport` | None | Rebalance |
| 11 | `feeRate_consistentAcrossChains` | None | Fee rate |
| 12 | `feeRate_matchesGhost` | None | Fee rate |
| 13 | `perUser_shareBalance_integrity` | `handler.getAdmin()` getter | Share accounting |
| 14 | `depositPingPong_alwaysCompletes` | `ManualMockRouter` + new ghosts + handler fn | PingPong |
| 15 | `withdrawPingPong_alwaysCompletes` | `ManualMockRouter` + new ghosts + handler fn | PingPong |
| 16 | `strategyAdapter_onlyYieldPeer` | New ghosts + handler function | Adapter security |
| 17 | `compoundAdapter_noBorrowing` | None (IComet already imported) | Adapter security |

---

## Implementation Order

1. Add invariants 1–13 (no new handler code beyond `getAdmin()` getter in step 2)
2. Add `getAdmin()` getter to Handler for invariant 13
3. Deploy `ManualMockRouter` in `Invariant.t.sol` setUp, replacing `MockCCIPRouter`; verify all existing tests still pass
4. Add PingPong ghosts + `depositPingPong()` + `withdrawPingPong()` handler functions + invariants 14–15
5. Add `depositPingPong` and `withdrawPingPong` to the targeted selectors in `setUp()`
6. Add ghost flags + `attemptUnauthorizedAdapterAccess()` + invariant 16
7. Add invariant 17 (IComet already available)
8. Add `attemptUnauthorizedAdapterAccess` to the targeted selectors in `setUp()`
