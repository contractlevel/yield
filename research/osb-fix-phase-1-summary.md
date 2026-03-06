# OSB Fix — Phase 1 Summary

## Background

An AI auditing tool flagged that both `ParentPeer` and `ChildPeer` burned shares **before** confirming a withdrawal succeeded cross-chain. On a failed CCIP delivery, the user's shares would be permanently destroyed with no USDC received and no recovery path.

Phase 1 addresses the cross-chain withdraw flow only. It defers the share burn and `s_totalShares` decrement until after the strategy chain has confirmed a successful withdrawal. Phase 2 (try/catch + `WithdrawFail`) is not yet implemented.

---

## Changes Made

### 1. `src/interfaces/IYieldPeer.sol` — Enum update

**What changed:**

- Renamed `WithdrawCallback` (was value 6) into two distinct types:
  - `WithdrawCallbackParent` (value 6): strategy chain → parent (deferred state update + route payment)
  - `WithdrawCallbackChild` (value 7): parent → withdraw chain child (burn shares + send USDC)
- All subsequent enum values shifted up by 1:
  - `RebalanceFromOldStrategy`: 7 → 8
  - `RebalanceToNewStrategy`: 8 → 9
  - `DepositPingPong`: 9 → 10
  - `WithdrawPingPong`: 10 → 11
- Updated `WithdrawToParent` comment to remove "update totalShares" (that update is now deferred)

**Why:** The old single `WithdrawCallback` type served two purposes — updating state on the parent and completing the transfer on the child. Splitting it allows the parent to act as a routing hub for the new deferred-update flow, and makes the message semantics explicit.

---

### 2. `src/peers/YieldPeer.sol` — Removed shared `_handleCCIPWithdrawCallback`

**What changed:**

- Deleted `_handleCCIPWithdrawCallback()` entirely.

**Why:** With the split into `WithdrawCallbackParent` and `WithdrawCallbackChild`, there is no longer shared behavior. Each peer now has its own handler. Keeping the base function would have been dead code.

---

### 3. `src/peers/ChildPeer.sol` — Deferred burn, new callback handler

**What changed:**

**a) `onTokenTransfer`**

- Removed `_burnShares(withdrawer, shareBurnAmount)`.

**Why:** The ERC677 `transferAndCall` mechanism already moves the shares to the peer contract before `onTokenTransfer` fires — so the shares are _held_ automatically. We just stopped burning them prematurely. The burn is now deferred to `_handleCCIPWithdrawCallbackChild` after the strategy confirms the withdrawal.

**b) `_handleCCIPWithdrawToStrategy`**

- Removed the local shortcut: previously, if `i_thisChainSelector == withdrawData.chainSelector` (strategy and withdraw chain are the same child), the function would transfer USDC directly to the withdrawer without going back to the parent.
- Now always sends `WithdrawCallbackParent` to the parent after a successful strategy withdrawal.

**Why:** The shortcut bypassed the parent's state update (`s_totalShares` decrement). Even though this is a same-chain-as-strategy scenario, the parent still needs to update its state. All successful strategy withdrawals must flow through `_handleCCIPWithdrawCallbackParent`.

**c) Added `_handleCCIPWithdrawCallbackChild`**

- Burns shares held by the peer.
- Validates and transfers USDC to the withdrawer.
- Emits `WithdrawCompleted`.

**Why:** This is the final step of the withdrawal on the child withdraw chain. By the time this message arrives from the parent, the strategy withdrawal is confirmed and `s_totalShares` has been decremented — it is now safe to burn shares and pay out USDC.

**d) Dispatch updated:** `WithdrawCallback` → `WithdrawCallbackChild` calling `_handleCCIPWithdrawCallbackChild`.

---

### 4. `src/peers/ParentPeer.sol` — Deferred state update, new routing logic

**What changed:**

**a) `onTokenTransfer`**

- When **parent is the strategy** (`strategy.chainSelector == i_thisChainSelector`): state updates (`s_totalShares -= shareBurnAmount`, `_burnShares`) happen _after_ `_getTotalValueFromStrategy` and `_calculateWithdrawAmount`. The key sequence is now: calculate → update state → withdraw → pay. Previously this was slightly different ordering with the burn happening before the calculation.
- When **parent is NOT the strategy**: shares are held (not burned), `s_totalShares` is NOT decremented. Sends `WithdrawToStrategy` directly to the strategy chain with a `totalShares` snapshot.
- The cross-chain branch no longer decrements state or burns — it just holds and sends.

**Why:** For local (parent-is-strategy) withdrawals, the strategy withdrawal is immediate and within the same call, so it's still safe to update state here. For cross-chain, we cannot know if the strategy withdrawal will succeed until the callback arrives, so all state updates are deferred.

**b) `_handleCCIPWithdrawToParent`**

- Removed `sourceChainSelector` parameter (was unused).
- Removed `s_totalShares` decrement and `ShareBurnUpdate` emission.
- Now only snapshots `s_totalShares` into `withdrawData.totalShares` and calls `_routeWithdraw`.

**Why:** The parent is purely a router at this point. Decrementing state before knowing whether the strategy withdrawal succeeded is exactly the bug we are fixing.

**c) `_handleCCIPWithdraw` renamed to `_routeWithdraw`**

- In the parent-is-strategy branch: performs strategy withdrawal, decrements `s_totalShares`, emits `ShareBurnUpdate`, and sends `WithdrawCallbackChild` to the withdraw chain. State update happens _after_ confirmed withdrawal.
- In the adapter-is-zero branch (TVL in transit): emits `WithdrawPingPongToChild`, sends `WithdrawPingPong` to the withdraw chain child.
- In the strategy-is-elsewhere branch: forwards `WithdrawToStrategy` to the strategy chain.

**Why:** Renamed for clarity — this function routes, not handles a CCIP message. The name `_handleCCIPWithdraw` was ambiguous about what it did. The decrement is now co-located with the confirmed withdrawal, not before it.

**d) Added `_handleCCIPWithdrawCallbackParent`**

- Called when the child strategy sends `WithdrawCallbackParent` back to the parent with the `usdcWithdrawAmount`.
- **Always** decrements `s_totalShares` and emits `ShareBurnUpdate` first.
- If `withdrawData.chainSelector == i_thisChainSelector`: burns shares from the parent peer and transfers USDC locally. Emits `WithdrawCompleted`.
- If `withdrawData.chainSelector != i_thisChainSelector`: forwards `WithdrawCallbackChild` with USDC to the withdraw chain child.

**Why:** This is the deferred state update point for cross-chain withdrawals where the strategy is a child chain. It is the counterpart to the deferred point in `_routeWithdraw` for parent-is-strategy flows. All code paths that update `s_totalShares` during a withdrawal now follow the same invariant: update only after strategy confirms.

**e) `_handleCCIPMessage` dispatch updated:**

- `WithdrawToParent` handler call signature updated (no `sourceChainSelector`).
- `WithdrawCallback` → `WithdrawCallbackParent` calling `_handleCCIPWithdrawCallbackParent`.
- NatSpec updated to reflect new message types.

---

### 5. `test/unit/childPeer/ChildWithdraw.t.sol` — Updated hops + new mid-flow test

**What changed:**

- NatSpec updated across all tests to use Scenario labels (A, B, C) and document CCIP hops.
- **Scenario C** (`strategyIsChild`): 2 hops → 4 hops. The old shortcut that skipped the parent callback is gone; the full round-trip now occurs: opt→base→opt→base→opt.
- **Scenario B** (`strategyIsChainC`): 3 hops → 4 hops. Same reason — all withdrawals now flow through `WithdrawCallbackParent`.
- Added `test_yield_child_onTokenTransfer_sharesHeldByPeer_notBurned`: after `transferAndCall` (before routing any CCIP), asserts that the peer holds shares and total supply has not decreased.

**Why:** Tests must reflect the new CCIP hop count. The mid-flow test directly verifies the Phase 1 deferred-burn guarantee — something the end-to-end tests cannot do because they complete all hops.

**NatSpec for Scenarios D and E** in `ParentWithdraw.t.sol` still needs updating to match the A/B/C/D/E labeling convention. Scenario E hop count is unchanged (2 routing calls); only NatSpec changes needed.

---

## Key Implementation Notes

### `_burnShares` — burns from `address(this)`, not from `from`

`_burnShares(address from, uint256 amount)` calls `i_share.burn(amount)` internally, which burns `amount` shares from the caller (`address(this)` — the peer contract). The `from` parameter is **only used for event attribution** in `SharesBurned(from, amount)`. This is intentional and correct:

- After ERC677 `transferAndCall`, shares are held at the peer (`address(this)`), not at the withdrawer.
- Calling `_burnShares(withdrawData.withdrawer, ...)` correctly attributes the burn to the original withdrawer in the event while burning from the peer's own balance.
- This applies in both `_handleCCIPWithdrawCallbackChild` (ChildPeer holds shares) and `_handleCCIPWithdrawCallbackParent` when `chainSelector == i_thisChainSelector` (ParentPeer holds shares in Scenario E).

---

## CCIP Flow Diagrams (After Phase 1)

### Scenario A — Child initiates, strategy is on Parent

```
child.onTokenTransfer (holds shares)
  → opt→base: WithdrawToParent
    → base._handleCCIPWithdrawToParent → _routeWithdraw (parent IS strategy)
      → withdrawFromStrategy, decrement s_totalShares
      → base→opt: WithdrawCallbackChild
        → opt._handleCCIPWithdrawCallbackChild
          → burnShares, transferUSDC to withdrawer
```

### Scenario B — Child initiates, strategy is another Child

```
child.onTokenTransfer (holds shares)
  → opt→base: WithdrawToParent
    → base._handleCCIPWithdrawToParent → _routeWithdraw (parent NOT strategy)
      → base→eth: WithdrawToStrategy
        → eth._handleCCIPWithdrawToStrategy
          → withdrawFromStrategy
          → eth→base: WithdrawCallbackParent
            → base._handleCCIPWithdrawCallbackParent
              → decrement s_totalShares
              → base→opt: WithdrawCallbackChild
                → opt._handleCCIPWithdrawCallbackChild
                  → burnShares, transferUSDC to withdrawer
```

### Scenario C — Child initiates, strategy is same Child

```
child.onTokenTransfer (holds shares)
  → opt→base: WithdrawToParent
    → base._handleCCIPWithdrawToParent → _routeWithdraw (parent NOT strategy)
      → base→opt: WithdrawToStrategy
        → opt._handleCCIPWithdrawToStrategy
          → withdrawFromStrategy
          → opt→base: WithdrawCallbackParent
            → base._handleCCIPWithdrawCallbackParent
              → decrement s_totalShares
              → base→opt: WithdrawCallbackChild
                → opt._handleCCIPWithdrawCallbackChild
                  → burnShares, transferUSDC to withdrawer
```

### Scenario D — Parent initiates, strategy is on Parent (unchanged)

```
parent.onTokenTransfer
  → local: calculate, decrement s_totalShares, burnShares, withdrawFromStrategy, transferUSDC
```

### Scenario E — Parent initiates, strategy is on Child

```
parent.onTokenTransfer (holds shares)
  → base→opt: WithdrawToStrategy
    → opt._handleCCIPWithdrawToStrategy
      → withdrawFromStrategy
      → opt→base: WithdrawCallbackParent
        → base._handleCCIPWithdrawCallbackParent
          → decrement s_totalShares
          → burnShares (shares held by baseParentPeer), transferUSDC locally
```

---

## What Needs to Happen Next

### 1. Complete Phase 1 Unit Tests

**Completed this session:**
- `test_yield_child_onTokenTransfer_sharesHeldByPeer_notBurned` added to `ChildWithdraw.t.sol` — asserts shares are held at the child peer (not burned) immediately after `transferAndCall`, before any CCIP routing.

**Still needed in `test/unit/parentPeer/ParentWithdraw.t.sol`:**

- NatSpec updates for Scenarios D and E (to match the A/B/C labeling convention and CCIP hop documentation used in `ChildWithdraw.t.sol`). Note: the Scenario E hop count does NOT change after Phase 1 — it remains 2 routing calls (base→opt `WithdrawToStrategy`, opt→base `WithdrawCallbackParent` with USDC). Only NatSpec needs updating.
- `test_yield_parent_onTokenTransfer_sharesHeldByPeer_notBurned` — Scenario E: after `transferAndCall` (before routing), assert `baseParentPeer` holds shares, `getTotalShares()` unchanged, total supply unchanged.
- `test_yield_parent_withdraw_totalSharesNotDecrementedBeforeStrategyConfirms` — Scenario E: after routing base→opt (`WithdrawToStrategy`) but before routing opt→base (`WithdrawCallbackParent`), assert `getTotalShares()` equals pre-withdrawal value.

These mid-flow tests check state between CCIP hops, which is the only way to directly verify the deferred-update guarantee in fork tests.

**Unit test scope: end-to-end fork coverage is sufficient.** No need for isolated `_handleCCIPWithdrawCallbackParent`/`Child` tests — the existing full-flow tests combined with the mid-flow tests provide adequate coverage.

### 2. Invariants

**Analysis: existing invariants are sufficient for Phase 1.** The ManualMockRouter delivers all hops synchronously in the invariant test suite, so the invariant checker always sees completed (not in-flight) state. Every existing invariant still holds:

- `invariant_shares_Share_totalSupply_equalsParentTotalShares` — the core guarantee that totalSupply and s_totalShares remain consistent. This was the property most at risk from the OSB bug and it still passes.
- `invariant_shares_totalShares_equalsSumOfHolderBalances` — already includes `share.balanceOf(address(parent))` to account for shares the parent peer may legitimately hold (e.g., fee-related). Would already catch permanently stuck shares at children via the imbalance it would create with `getTotalShares()`.
- `invariant_shares_totalShares_equalsMintedMinusBurned` — still holds; deferred burn/decrement just changes when within a tx they occur, not whether they occur.
- `invariant_withdraw_WithdrawInitiated_SharesBurned_WithdrawCompleted_ShareBurnUpdate_emissionConsistency` — all four events still fire exactly once per withdrawal, just potentially later in the tx chain.

**Potential future invariant:** `invariant_peers_children_noSharesHeld` — asserts `share.balanceOf(child1) == 0` and `share.balanceOf(child2) == 0` at the end of every handler action. This directly documents that children should never permanently hold shares (Phase 1 guarantee). Note: the parent is excluded because it may legitimately hold shares for other reasons (already handled by existing `equalsSumOfHolderBalances` invariant). Deferred — revisit once Phase 2 is complete, as the fail-path return mechanism also affects this property.

### 2. Certora Harness Updates (`certora/harness/` — `.sol` files)

The harnesses expose internal functions and their signatures changed. These are breaking compilation errors that must be fixed before Certora can run:

**`certora/harness/ParentHarness.sol`:**

- `handleCCIPWithdrawToParent(bytes memory data, uint64 sourceChainSelector)` → remove `sourceChainSelector` parameter; update call to `_handleCCIPWithdrawToParent(data)`.
- `handleCCIPWithdraw(bytes memory encodedWithdrawData)` → rename to `handleCCIPRouteWithdraw` (or equivalent), update call to `_routeWithdraw(s_strategy, withdrawData)`.
- Add `handleCCIPWithdrawCallbackParent(Client.EVMTokenAmount[] memory tokenAmounts, bytes memory data)` exposing `_handleCCIPWithdrawCallbackParent`.

**`certora/harness/ChildHarness.sol`:**

- Add `handleCCIPWithdrawCallbackChild(Client.EVMTokenAmount[] memory tokenAmounts, bytes memory data)` exposing `_handleCCIPWithdrawCallbackChild`.

### 3. Certora Spec Updates (`certora/spec/` — `.spec` files)

> Note: per project instructions, do not run or edit Certora specs directly. These are listed for awareness only — they will need to be addressed by the team when running Certora.

**Enum value shifts** (rules using `ghost_ccipMessageSent_txType_emitted`):

| Rule                                                                                           | Old assertion              | New assertion                  |
| ---------------------------------------------------------------------------------------------- | -------------------------- | ------------------------------ |
| `handleCCIPDepositToParent_ping_pongs_to_child_when_activeStrategyAdapter_is_zero`             | `== 9` (DepositPingPong)   | `== 10`                        |
| `handleCCIPWithdrawToParent_sendsUsdc_to_withdrawChain_when_parent_is_strategy`                | `== 6` (WithdrawCallback)  | `== 7` (WithdrawCallbackChild) |
| `handleCCIPWithdraw_forwardsToStrategy_and_emits_WithdrawPingPongToChild_when_Adapter_is_zero` | `== 10` (WithdrawPingPong) | `== 11`                        |

**Semantic changes** (rules whose invariants no longer hold after Phase 1):

> These will need to be verified by running the Certora prover and reviewing its output manually.

- `onTokenTransfer_decreases_totalShares`: Currently unconditional. Must add precondition `require getStrategy().chainSelector == getThisChainSelector()` — `s_totalShares` is now only decremented immediately when the parent IS the strategy.
- `onTokenTransfer_emits_SharesBurned_and_ShareBurnUpdate_and_WithdrawInitiated`: Same precondition needed — `SharesBurned` and `ShareBurnUpdate` are no longer emitted in `onTokenTransfer` for cross-chain withdrawals.
- `handleCCIPWithdrawToParent_updatesTotalShares_and_emits_ShareBurnUpdate`: Must be **deleted or completely rewritten** — `_handleCCIPWithdrawToParent` no longer updates `s_totalShares` or emits `ShareBurnUpdate`. That happens in `_routeWithdraw` (parent-is-strategy) or `_handleCCIPWithdrawCallbackParent` (child-is-strategy).
- `handleCCIPWithdrawToParent_withdrawsUsdc_when_parent_is_strategy` and `handleCCIPWithdrawToParent_sendsUsdc_to_withdrawChain_when_parent_is_strategy`: Harness signature changed (remove `sourceChainSelector` param from call); semantics are still largely correct (routing via `_routeWithdraw` still withdraws when parent is strategy).
- `handleCCIPWithdraw_*` rules: Harness function `handleCCIPWithdraw` must be renamed to match `handleCCIPRouteWithdraw` (or equivalent new name).

**New rules needed:**

- `handleCCIPWithdrawCallbackParent_decrements_totalShares`
- `handleCCIPWithdrawCallbackParent_emits_ShareBurnUpdate`
- `handleCCIPWithdrawCallbackParent_forwardsToChild_when_withdrawChain_is_notParent`
- `handleCCIPWithdrawCallbackParent_completesWithdraw_when_withdrawChain_is_parent`
- `handleCCIPWithdrawCallbackChild_burnsShares_and_transfersUsdc`

### 4. Phase 2 — Try/Catch + `WithdrawFail`

After Phase 1 testing and Certora harness fixes are complete, Phase 2 can be implemented. Phase 2 adds the recovery mechanism for failed strategy withdrawals:

- Add `CcipTxType.WithdrawFail` (value 12)
- Wrap `_withdrawFromStrategyAndGetUsdcWithdrawAmount` in a try/catch in both `_handleCCIPWithdrawToStrategy` (ChildPeer) and `_routeWithdraw` (ParentPeer)
- On catch: send `WithdrawFail` back to the withdraw chain
- Add `_handleCCIPWithdrawFail` in `YieldPeer`: transfers held shares back to the withdrawer
- Add `WithdrawFailed` event
- New invariants: shares held by peer + shares in circulation == `s_totalShares` (during in-flight withdrawals); shares returned on fail; no double-return possible

Phase 2 introduces new Certora invariants and rules around the fail path and will require its own planning document.
