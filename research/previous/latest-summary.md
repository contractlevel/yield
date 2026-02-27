# Latest Summary

> Date: 2026-02-26
> Branch: `fix/adapter-withdraw-checks`

## What Was Done Today

### 1. Invariants plan written (`research/invariants-plan.md`)

Audited the full existing invariant suite and identified five gap categories not yet covered:

1. **Amount flow consistency** — event-emitted amounts vs handler-tracked amounts
2. **Emission count pairing** — 1:1 relationships between paired events
3. **PingPong completion** — cross-chain bounce path always resolves
4. **Per-user share balance** — per-user mint/burn accounting
5. **Adapter security** — access control and Compound anti-borrow

A plan of 17 new invariants was designed across these categories, with a full implementation order.

### 2. PingPong architecture problem identified and solved

The original plan included two PingPong "symmetry" invariants (`DepositPingPongToParent_totalSum == DepositPingPongToChild_totalSum`). These had two problems:

1. **Logically wrong**: `DepositPingPongToParent` fires when a *child* is the strategy; `DepositPingPongToChild` fires when the *parent* is the strategy. They're from distinct scenarios, never paired.
2. **Practically untestable**: The existing `MockCCIPRouter` delivers CCIP messages synchronously within the same call frame. Setting the strategy adapter to `address(0)` and triggering a deposit creates infinite recursion (child → parent → child → ...) that hits the EVM call depth limit, reverts, and is silently swallowed by `fail_on_revert`. No events are captured.

**Solution designed: `ManualMockRouter`** — a new test contract that inherits `MockCCIPRouter` and adds a `lazyMode` toggle. When enabled, `ccipSend` queues messages instead of delivering them; `routeNext()` delivers one hop at a time. This replicates the `switchChainAndRouteMessage` pattern from the fork-based unit tests, giving the handler functions a gap between hops to restore adapter state. All existing handler functions are unaffected (normal mode behaviour is identical to `MockCCIPRouter`).

The PingPong invariants were replaced with completion-based ones: every `depositPingPong` / `withdrawPingPong` handler call must result in exactly one `SharesMinted` / `WithdrawCompleted` emission.

### 3. Invariants 1–11 implemented in `Invariant.t.sol`

All 12 planned invariants that require no new handler code were added (the user also absorbed the `StrategyUpdated` emission count check into the existing `invariant_rebalance_eventConsistency`, which is cleaner):

| Function | Category |
|---|---|
| `invariant_depositInitiated_amount_equals_userPrincipal` | Amount flow |
| `invariant_strategyAdapter_deposit_matchesPeerEmission` | Amount flow |
| `invariant_sharesBurned_matchesGhost` | Amount flow |
| `invariant_withdrawInitiated_matchesSharesBurned` | Amount flow |
| `invariant_feesWithdrawn_matchesGhost` | Amount flow |
| `invariant_sharesMinted_emissions_matchDeposits` | Emission count |
| `invariant_sharesBurned_emissions_matchWithdrawals` | Emission count |
| `invariant_ccip_sentEqualsReceived` | CCIP |
| `invariant_strategyUpdated_matchesDecodedReport` | Rebalance |
| `invariant_feeRate_consistentAcrossChains` | Fee rate |
| `invariant_feeRate_matchesGhost` | Fee rate |

All tests pass with `forge coverage`.

---

## What Is Next

The remaining invariants from `research/invariants-plan.md`, in implementation order:

### Step 1 — Invariant 13: `perUser_shareBalance_integrity`

Add a `getAdmin()` external view getter to `Handler.t.sol` to expose the `admin` address. Then add the invariant:

```solidity
handler.forEachUser(this.checkPerUserShareBalanceIntegrity);
// plus a separate check for admin
```

This checks `share.balanceOf(user) == ghost_totalSharesMintedPerUser[user] - ghost_totalSharesBurnedPerUser[user]` for every user. All required ghosts already exist.

### Step 2 — `ManualMockRouter` + PingPong handler functions (invariants 14 & 15)

**2a. Deploy `ManualMockRouter`** in `Invariant.t.sol` `setUp()`, replacing `MockCCIPRouter`. This is `~80` lines inheriting `MockCCIPRouter` with a queue and `lazyMode` flag. Run the full suite to confirm no regressions.

**2b. Add `depositPingPong` and `withdrawPingPong`** to `Handler.t.sol`. Each function:
1. Switches router to lazy mode
2. Reads `parent.getStrategy().chainSelector` to find the strategy peer
3. Stores the current adapter address, then `vm.store`s it to `address(0)`
4. Triggers a deposit/withdraw (message is queued, not delivered)
5. Calls `routeNext()` step by step — branching on whether strategy is on parent or a child chain — restoring the adapter at the correct gap between the PingPong bounce and the retry
6. Drains any remaining queued messages
7. Records whether `SharesMinted` / `WithdrawCompleted` was emitted (completion counter)
8. Switches router back to normal mode

**2c. Add the two new ghosts** (`ghost_depositPingPong_calls`, `ghost_depositPingPong_completions`, and equivalents for withdraw) to `Ghosts.t.sol`.

**2d. Add the two invariants** and register the handler functions in `setUp()` targetSelector.

**Why this matters:** The existing unit tests (`ChildDepositPingPong`, `ParentDepositPingPong`, etc.) verify PingPong under controlled single scenarios. The invariant handler will fuzz over all combinations of deposit chains, strategy chain positions, deposit amounts, and sequences of preceding operations — exercising the PingPong path under emergent state that unit tests cannot anticipate.

### Step 3 — Invariant 16: `strategyAdapter_onlyYieldPeer`

Add two boolean ghost flags and an `attemptUnauthorizedAdapterAccess()` handler function that tries to call `deposit()` and `withdraw()` on each of the 6 deployed adapters as a random non-peer address. The invariant asserts both flags remain false. This fuzz-tests the `onlyYieldPeer` modifier across all adapters.

### Step 4 — Invariant 17: `compoundAdapter_noBorrowing`

A simple three-assertion invariant reading `IComet.borrowBalanceOf()` for each of the three Compound adapters. `IComet` is already imported; no new code is needed beyond the invariant function itself.
