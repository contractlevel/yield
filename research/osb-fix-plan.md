# Optimistic Share Burn (OSB) Fix Plan

## Background

An AI audit tool flagged:

> **3. Optimistic Share Burn Before Withdrawal Confirmation**
> Likelihood: 80% | Impact: High | Severity: HIGH
>
> Both ParentPeer and ChildPeer burn shares BEFORE confirming withdrawal succeeds.
> ChildPeer is worse as it burns before cross-chain confirmation. Users permanently lose
> shares if withdrawal fails.

The root cause is simple: both peers call `_burnShares()` immediately in `onTokenTransfer()`,
before any strategy withdrawal or cross-chain confirmation occurs.

**Key observation:** Because withdrawal is triggered via `share.transferAndCall(peer, amount, "")`,
the ERC677 standard transfers shares from the user to the peer contract BEFORE calling
`onTokenTransfer()`. This means shares are already physically held in the peer contract
when `onTokenTransfer()` fires. The fix is therefore straightforward: **don't call
`_burnShares()` immediately — the shares are already held safely in the peer.**

---

## Current Withdrawal Flows (Problem)

The following traces are derived directly from the source. `←` marks the bugs.

### Scenario A: ChildPeer initiated, Parent is strategy

**CCIP hops:** Child → Parent (WithdrawToParent), Parent → Child (WithdrawCallback + USDC)

```
1. ChildPeer.onTokenTransfer()                               [ChildPeer.sol:89-105]
   _burnShares(withdrawer, shareBurnAmount)                  ← BUG: immediate burn
   withdrawData = _buildWithdrawData(withdrawer, shareBurnAmount, i_thisChainSelector)
   _ccipSend(i_parentChainSelector, WithdrawToParent, withdrawData, ZERO_BRIDGE_AMOUNT)
   emit WithdrawInitiated(withdrawer, shareBurnAmount, i_thisChainSelector)

2. ParentPeer._handleCCIPWithdrawToParent()                  [ParentPeer.sol:334-344]
   withdrawData.totalShares = s_totalShares
   s_totalShares -= withdrawData.shareBurnAmount             ← premature state update
   emit ShareBurnUpdate(shareBurnAmount, sourceChainSelector, ...)
   → _handleCCIPWithdraw(s_strategy, withdrawData)

3. ParentPeer._handleCCIPWithdraw() — strategy.chainSelector == i_thisChainSelector
                                                             [ParentPeer.sol:350-374]
   activeStrategyAdapter = _getActiveStrategyAdapter()       (adapter != 0 path)
   withdrawData.usdcWithdrawAmount =
       _withdrawFromStrategyAndGetUsdcWithdrawAmount(activeStrategyAdapter, withdrawData)
   _ccipSend(withdrawData.chainSelector, WithdrawCallback, withdrawData, usdcWithdrawAmount)
   (withdrawData.chainSelector == child chain)

4. YieldPeer._handleCCIPWithdrawCallback()                   [YieldPeer.sol:239-246]
   (dispatched on ChildPeer via _handleCCIPMessage)
   CCIPOperations._validateTokenAmounts(tokenAmounts, usdc, usdcWithdrawAmount)
   _transferUsdcTo(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount)
   emit WithdrawCompleted(withdrawer, usdcWithdrawAmount)
```

### Scenario B: ChildPeer A initiated, ChildPeer B is strategy

**CCIP hops:** Child A → Parent (WithdrawToParent), Parent → Child B (WithdrawToStrategy), Child B → Child A (WithdrawCallback + USDC)

```
1. ChildPeer A.onTokenTransfer()                             [ChildPeer.sol:89-105]
   _burnShares(withdrawer, shareBurnAmount)                  ← BUG: immediate burn
   withdrawData = _buildWithdrawData(withdrawer, shareBurnAmount, i_thisChainSelector)
   (withdrawData.chainSelector == Child A chain)
   _ccipSend(i_parentChainSelector, WithdrawToParent, withdrawData, ZERO_BRIDGE_AMOUNT)
   emit WithdrawInitiated(withdrawer, shareBurnAmount, i_thisChainSelector)

2. ParentPeer._handleCCIPWithdrawToParent()                  [ParentPeer.sol:334-344]
   withdrawData.totalShares = s_totalShares
   s_totalShares -= withdrawData.shareBurnAmount             ← premature state update
   emit ShareBurnUpdate(...)
   → _handleCCIPWithdraw(s_strategy, withdrawData)

3. ParentPeer._handleCCIPWithdraw() — strategy.chainSelector != i_thisChainSelector
                                                             [ParentPeer.sol:375-382]
   emit WithdrawForwardedToStrategy(shareBurnAmount, strategy.chainSelector)
   _ccipSend(strategy.chainSelector, WithdrawToStrategy, withdrawData, ZERO_BRIDGE_AMOUNT)
   (strategy.chainSelector == Child B chain)

4. ChildPeer B._handleCCIPWithdrawToStrategy()               [ChildPeer.sol:179-203]
   (adapter != 0, i_thisChainSelector != withdrawData.chainSelector)
   withdrawData.usdcWithdrawAmount =
       _withdrawFromStrategyAndGetUsdcWithdrawAmount(activeStrategyAdapter, withdrawData)
   _ccipSend(withdrawData.chainSelector, WithdrawCallback, withdrawData, usdcWithdrawAmount)
   (withdrawData.chainSelector == Child A chain)

5. YieldPeer._handleCCIPWithdrawCallback()                   [YieldPeer.sol:239-246]
   (dispatched on Child A)
   _validateTokenAmounts(...)
   _transferUsdcTo(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount)
   emit WithdrawCompleted(...)
```

### Scenario C: ChildPeer A initiated, ChildPeer A is also strategy

**CCIP hops:** Child A → Parent (WithdrawToParent), Parent → Child A (WithdrawToStrategy), then local completion

```
1. ChildPeer A.onTokenTransfer()                             [ChildPeer.sol:89-105]
   _burnShares(withdrawer, shareBurnAmount)                  ← BUG: immediate burn
   withdrawData = _buildWithdrawData(withdrawer, shareBurnAmount, i_thisChainSelector)
   (withdrawData.chainSelector == Child A chain)
   _ccipSend(i_parentChainSelector, WithdrawToParent, withdrawData, ZERO_BRIDGE_AMOUNT)
   emit WithdrawInitiated(...)

2. ParentPeer._handleCCIPWithdrawToParent()                  [ParentPeer.sol:334-344]
   withdrawData.totalShares = s_totalShares
   s_totalShares -= withdrawData.shareBurnAmount             ← premature state update
   emit ShareBurnUpdate(...)
   → _handleCCIPWithdraw(s_strategy, withdrawData)

3. ParentPeer._handleCCIPWithdraw() — strategy.chainSelector != i_thisChainSelector
                                                             [ParentPeer.sol:375-382]
   (s_strategy.chainSelector == Child A; parent is not strategy)
   _ccipSend(Child A, WithdrawToStrategy, withdrawData, ZERO_BRIDGE_AMOUNT)

4. ChildPeer A._handleCCIPWithdrawToStrategy()               [ChildPeer.sol:179-203]
   (adapter != 0, i_thisChainSelector == withdrawData.chainSelector ← same chain)
   withdrawData.usdcWithdrawAmount =
       _withdrawFromStrategyAndGetUsdcWithdrawAmount(activeStrategyAdapter, withdrawData)
   emit WithdrawCompleted(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount)
   _transferUsdcTo(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount)
   (local transfer — no further CCIP)
```

### Scenario D: ParentPeer initiated, Parent is also strategy

**CCIP hops:** None — fully local

```
1. ParentPeer.onTokenTransfer()                              [ParentPeer.sol:139-191]
   totalShares = s_totalShares
   s_totalShares -= shareBurnAmount                          ← BUG: premature state update
   emit ShareBurnUpdate(shareBurnAmount, i_thisChainSelector, totalShares - shareBurnAmount)
   emit WithdrawInitiated(withdrawer, shareBurnAmount, i_thisChainSelector)
   _burnShares(withdrawer, shareBurnAmount)                  ← BUG: immediate burn

   strategy.chainSelector == i_thisChainSelector (parent IS strategy):
   activeStrategyAdapter = _getActiveStrategyAdapter()       (reverts if addr(0))
   totalValue = _getTotalValueFromStrategy(activeStrategyAdapter, usdc)
   usdcWithdrawAmount = _calculateWithdrawAmount(totalValue, totalShares, shareBurnAmount)
   if usdcWithdrawAmount != 0: _withdrawFromStrategy(activeStrategyAdapter, usdcWithdrawAmount)
   emit WithdrawCompleted(withdrawer, usdcWithdrawAmount)
   if usdcWithdrawAmount != 0: _transferUsdcTo(withdrawer, usdcWithdrawAmount)
```

### Scenario E: ParentPeer initiated, strategy is on ChildPeer

**CCIP hops:** Parent → Child (WithdrawToStrategy), Child → Parent (WithdrawCallback + USDC)

```
1. ParentPeer.onTokenTransfer()                              [ParentPeer.sol:139-191]
   totalShares = s_totalShares
   s_totalShares -= shareBurnAmount                          ← BUG: premature state update
   emit ShareBurnUpdate(...)
   emit WithdrawInitiated(...)
   _burnShares(withdrawer, shareBurnAmount)                  ← BUG: immediate burn

   strategy.chainSelector != i_thisChainSelector (strategy is on child):
   withdrawData = _buildWithdrawData(withdrawer, shareBurnAmount, i_thisChainSelector)
   (withdrawData.chainSelector == parent chain)
   withdrawData.totalShares = totalShares
   _ccipSend(strategy.chainSelector, WithdrawToStrategy, withdrawData, ZERO_BRIDGE_AMOUNT)
   (sent DIRECTLY to child strategy — no WithdrawToParent involved)

2. ChildPeer._handleCCIPWithdrawToStrategy()                 [ChildPeer.sol:179-203]
   (adapter != 0, i_thisChainSelector != withdrawData.chainSelector)
   withdrawData.usdcWithdrawAmount =
       _withdrawFromStrategyAndGetUsdcWithdrawAmount(activeStrategyAdapter, withdrawData)
   _ccipSend(withdrawData.chainSelector, WithdrawCallback, withdrawData, usdcWithdrawAmount)
   (withdrawData.chainSelector == parent chain)

3. YieldPeer._handleCCIPWithdrawCallback()                   [YieldPeer.sol:239-246]
   (dispatched on ParentPeer via _handleCCIPMessage)
   _validateTokenAmounts(...)
   _transferUsdcTo(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount)
   emit WithdrawCompleted(...)
```

---

## New Withdrawal Flows (Fix)

The two-phase approach:

1. **Initiation:** Shares are held (not burned) in the peer contract
2. **Confirmation:** Shares are burned only after strategy withdrawal succeeds; or returned if it fails

### New CcipTxType Enum Values

```solidity
enum CcipTxType {
    DepositToParent,          // 0  - unchanged
    DepositToStrategy,        // 1  - unchanged
    DepositCallbackParent,    // 2  - unchanged
    DepositCallbackChild,     // 3  - unchanged
    WithdrawToParent,         // 4  - unchanged
    WithdrawToStrategy,       // 5  - unchanged
    WithdrawCallbackChild,    // 6  - RENAMED from WithdrawCallback (integer value unchanged)
    WithdrawCallbackParent,   // 7  - NEW (Phase 1)
    RebalanceFromOldStrategy, // 8  - was 7 (integer value +1)
    RebalanceToNewStrategy,   // 9  - was 8 (integer value +1)
    DepositPingPong,          // 10 - was 9 (integer value +1)
    WithdrawPingPong,         // 11 - was 10 (integer value +1)
    WithdrawFail              // 12 - NEW (Phase 2)
}
```

**Important notes on integer values:**

- `WithdrawCallback` (6) is renamed to `WithdrawCallbackChild` but keeps integer value 6. Any in-flight CCIP messages with value 6 are unaffected.
- `RebalanceFromOldStrategy`, `RebalanceToNewStrategy`, `DepositPingPong`, and `WithdrawPingPong` each shift up by 1. Certora specs use hardcoded integers for these — all occurrences must be updated.

### New Flow: ChildPeer initiated, Parent is strategy (Scenario A)

```
1. ChildPeer A.onTokenTransfer()
   shares HELD in Child A (not burned) — already transferred by ERC677
   withdrawData = _buildWithdrawData(withdrawer, shareBurnAmount, i_thisChainSelector)
   emit WithdrawInitiated(withdrawer, shareBurnAmount, i_thisChainSelector)
   _ccipSend(i_parentChainSelector, WithdrawToParent, withdrawData, ZERO_BRIDGE_AMOUNT)

2. ParentPeer._handleCCIPWithdrawToParent()
   withdrawData.totalShares = s_totalShares   (snapshot for calculation, NO decrement)
   → _handleCCIPWithdraw(s_strategy, withdrawData)

3. ParentPeer._handleCCIPWithdraw() — parent IS strategy
   _withdrawFromStrategyAndGetUsdcWithdrawAmount(activeStrategyAdapter, withdrawData)
   s_totalShares -= withdrawData.shareBurnAmount         ← state update moved here
   emit ShareBurnUpdate(shareBurnAmount, withdrawData.chainSelector, s_totalShares)
   _ccipSend(withdrawData.chainSelector, WithdrawCallbackChild, withdrawData, usdcWithdrawAmount)

4. ChildPeer A._handleCCIPWithdrawCallbackChild()
   CCIPOperations._validateTokenAmounts(tokenAmounts, usdc, usdcWithdrawAmount)
   _burnShares(withdrawData.withdrawer, withdrawData.shareBurnAmount)  ← burn moved here
   _transferUsdcTo(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount)
   emit WithdrawCompleted(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount)
```

### New Flow: ChildPeer A initiated, ChildPeer B is strategy (Scenario B)

```
1. ChildPeer A.onTokenTransfer()
   shares HELD in Child A (not burned)
   withdrawData = _buildWithdrawData(withdrawer, shareBurnAmount, i_thisChainSelector)
   emit WithdrawInitiated(...)
   _ccipSend(i_parentChainSelector, WithdrawToParent, withdrawData, ZERO_BRIDGE_AMOUNT)

2. ParentPeer._handleCCIPWithdrawToParent()
   withdrawData.totalShares = s_totalShares   (NO decrement)
   → _handleCCIPWithdraw(s_strategy, withdrawData)

3. ParentPeer._handleCCIPWithdraw() — parent NOT strategy
   emit WithdrawForwardedToStrategy(...)
   _ccipSend(Child B, WithdrawToStrategy, withdrawData, ZERO_BRIDGE_AMOUNT)

4. ChildPeer B._handleCCIPWithdrawToStrategy()
   _withdrawFromStrategyAndGetUsdcWithdrawAmount(...)
   i_thisChainSelector != withdrawData.chainSelector (Child B != Child A)
   _ccipSend(i_parentChainSelector, WithdrawCallbackParent, withdrawData, usdcWithdrawAmount)

5. ParentPeer._handleCCIPWithdrawCallbackParent()
   s_totalShares -= withdrawData.shareBurnAmount         ← state update moved here
   emit ShareBurnUpdate(shareBurnAmount, withdrawData.chainSelector, s_totalShares)
   withdrawData.chainSelector != i_thisChainSelector (Child A != parent)
   CCIPOperations._validateTokenAmounts(tokenAmounts, usdc, usdcWithdrawAmount)
   _ccipSend(Child A, WithdrawCallbackChild, withdrawData, usdcWithdrawAmount)

6. ChildPeer A._handleCCIPWithdrawCallbackChild()
   CCIPOperations._validateTokenAmounts(tokenAmounts, usdc, usdcWithdrawAmount)
   _burnShares(withdrawData.withdrawer, withdrawData.shareBurnAmount)  ← burn moved here
   _transferUsdcTo(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount)
   emit WithdrawCompleted(...)
```

### New Flow: ChildPeer initiated, same chain is strategy (Scenario C)

USDC is always bridged to parent immediately — there is no same-chain shortcut. Although
`withdrawData.chainSelector == i_thisChainSelector`, USDC follows the same path as all
other child-initiated withdrawals. See Known Issue #5 for the gas/cost trade-off.

```
1. ChildPeer A.onTokenTransfer()
   shares HELD in Child A (not burned)
   withdrawData = _buildWithdrawData(withdrawer, shareBurnAmount, i_thisChainSelector)
   emit WithdrawInitiated(...)
   _ccipSend(i_parentChainSelector, WithdrawToParent, withdrawData, ZERO_BRIDGE_AMOUNT)

2. ParentPeer._handleCCIPWithdrawToParent()
   withdrawData.totalShares = s_totalShares   (NO decrement)
   → _handleCCIPWithdraw(s_strategy, withdrawData)

3. ParentPeer._handleCCIPWithdraw() — parent NOT strategy (Child A is strategy)
   _ccipSend(Child A, WithdrawToStrategy, withdrawData, ZERO_BRIDGE_AMOUNT)

4. ChildPeer A._handleCCIPWithdrawToStrategy()
   _withdrawFromStrategyAndGetUsdcWithdrawAmount(...)
   USDC bridged to parent immediately (never held in peer balance)
   _ccipSend(i_parentChainSelector, WithdrawCallbackParent, withdrawData, usdcWithdrawAmount)

5. ParentPeer._handleCCIPWithdrawCallbackParent()
   s_totalShares -= withdrawData.shareBurnAmount
   emit ShareBurnUpdate(...)
   withdrawData.chainSelector != i_thisChainSelector (Child A != parent)
   CCIPOperations._validateTokenAmounts(tokenAmounts, usdc, usdcWithdrawAmount)
   _ccipSend(Child A, WithdrawCallbackChild, withdrawData, usdcWithdrawAmount)

6. ChildPeer A._handleCCIPWithdrawCallbackChild()
   CCIPOperations._validateTokenAmounts(tokenAmounts, usdc, usdcWithdrawAmount)
   _burnShares(withdrawData.withdrawer, withdrawData.shareBurnAmount)
   _transferUsdcTo(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount)
   emit WithdrawCompleted(...)
```

### New Flow: ParentPeer initiated, strategy is a child (Scenario E)

```
1. ParentPeer.onTokenTransfer()
   shares HELD in Parent (not burned)
   totalShares = s_totalShares   (NO decrement)
   emit WithdrawInitiated(withdrawer, shareBurnAmount, i_thisChainSelector)
   withdrawData = _buildWithdrawData(withdrawer, shareBurnAmount, i_thisChainSelector)
   (withdrawData.chainSelector == parent chain)
   withdrawData.totalShares = totalShares
   _ccipSend(strategy.chainSelector, WithdrawToStrategy, withdrawData, ZERO_BRIDGE_AMOUNT)

2. ChildPeer._handleCCIPWithdrawToStrategy()
   _withdrawFromStrategyAndGetUsdcWithdrawAmount(...)
   i_thisChainSelector != withdrawData.chainSelector (child != parent)
   _ccipSend(i_parentChainSelector, WithdrawCallbackParent, withdrawData, usdcWithdrawAmount)

3. ParentPeer._handleCCIPWithdrawCallbackParent()
   s_totalShares -= withdrawData.shareBurnAmount         ← state update moved here
   emit ShareBurnUpdate(...)
   withdrawData.chainSelector == i_thisChainSelector ← parent IS the withdraw chain
   CCIPOperations._validateTokenAmounts(tokenAmounts, usdc, usdcWithdrawAmount)
   _burnShares(withdrawData.withdrawer, withdrawData.shareBurnAmount)  ← burn moved here
   _transferUsdcTo(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount)
   emit WithdrawCompleted(...)
```

### Local Flow: ParentPeer initiated, Parent is also strategy (Scenario D, Phase 1: unchanged)

This case — where the parent is both the withdraw chain and the strategy — has no CCIP
involved. **This case is not changed in Phase 1.** The optimistic burn remains for now.
Phase 2 adds try/catch here. See Phase 2 section below.

---

## Phase 1: WithdrawCallback Refactoring

### 1. `IYieldPeer.sol`

- Rename `WithdrawCallback` (6) → `WithdrawCallbackChild` (stays at 6)
- Insert `WithdrawCallbackParent` at position 7 (immediately after `WithdrawCallbackChild`)
- `RebalanceFromOldStrategy` shifts 7 → 8, `RebalanceToNewStrategy` shifts 8 → 9,
  `DepositPingPong` shifts 9 → 10, `WithdrawPingPong` shifts 10 → 11
- Add `WithdrawFail` (12) at end (Phase 2)

### 2. `YieldPeer.sol`

- **Remove** `_handleCCIPWithdrawCallback()` entirely. It is replaced by the
  parent/child-specific handlers below.

### 3. `ChildPeer.sol`

#### `onTokenTransfer()`

Remove `_burnShares(withdrawer, shareBurnAmount)`. Shares are held in this contract
(already transferred by ERC677 before this function fires). Everything else unchanged.

```solidity
// REMOVE this line:
_burnShares(withdrawer, shareBurnAmount);
```

#### `_handleCCIPWithdrawToStrategy()`

Replace the existing body. USDC is always bridged to parent with `WithdrawCallbackParent`,
regardless of whether the withdraw chain is this chain or another. The old direct-transfer
local path (`if (i_thisChainSelector == withdrawData.chainSelector) _transferUsdcTo(...)`)
is removed entirely.

```solidity
function _handleCCIPWithdrawToStrategy(bytes memory data) internal {
    WithdrawData memory withdrawData = _decodeWithdrawData(data);
    address activeStrategyAdapter = _getActiveStrategyAdapter();
    if (activeStrategyAdapter != address(0)) {
        withdrawData.usdcWithdrawAmount =
            _withdrawFromStrategyAndGetUsdcWithdrawAmount(activeStrategyAdapter, withdrawData);
        _ccipSend(
            i_parentChainSelector,
            CcipTxType.WithdrawCallbackParent,
            abi.encode(withdrawData),
            withdrawData.usdcWithdrawAmount
        );
    } else {
        emit WithdrawPingPongToParent(withdrawData.shareBurnAmount);
        _ccipSend(
            i_parentChainSelector, CcipTxType.WithdrawPingPong, abi.encode(withdrawData), ZERO_BRIDGE_AMOUNT
        );
    }
}
```

#### New `_handleCCIPWithdrawCallbackChild()`

Receives `WithdrawCallbackChild` from parent. Burns shares (held in this contract since
`onTokenTransfer`). USDC always arrives via CCIP token transfer when `usdcWithdrawAmount > 0`.

```solidity
/// @notice Handles the CCIP message for a withdraw callback to this child chain
/// @notice Burns shares (held in this contract since onTokenTransfer) and sends USDC to withdrawer
/// @notice USDC always arrives via CCIP token transfer when usdcWithdrawAmount > 0
/// @param tokenAmounts The token amounts in the message
/// @param data The message data - decodes to WithdrawData
function _handleCCIPWithdrawCallbackChild(
    Client.EVMTokenAmount[] memory tokenAmounts,
    bytes memory data
) internal {
    WithdrawData memory withdrawData = _decodeWithdrawData(data);
    if (withdrawData.usdcWithdrawAmount != 0) {
        CCIPOperations._validateTokenAmounts(tokenAmounts, address(i_usdc), withdrawData.usdcWithdrawAmount);
    }
    _burnShares(withdrawData.withdrawer, withdrawData.shareBurnAmount);
    if (withdrawData.usdcWithdrawAmount != 0) {
        _transferUsdcTo(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount);
    }
    emit WithdrawCompleted(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount);
}
```

#### `_handleCCIPMessage()` dispatch

- Replace: `if (txType == CcipTxType.WithdrawCallback) _handleCCIPWithdrawCallback(...)`
- With: `if (txType == CcipTxType.WithdrawCallbackChild) _handleCCIPWithdrawCallbackChild(tokenAmounts, data)`
- Phase 2 will also add: `if (txType == CcipTxType.WithdrawFail) _handleCCIPWithdrawFail(data)`

### 4. `ParentPeer.sol`

#### `onTokenTransfer()` — cross-chain case (strategy is not on parent)

Remove `s_totalShares -= shareBurnAmount`, its `ShareBurnUpdate` emit, and
`_burnShares(withdrawer, shareBurnAmount)`. Shares are held in this contract.
`totalShares` snapshot is still captured for the strategy calculation — it just isn't
decremented here anymore.

```solidity
// REMOVE these lines:
s_totalShares -= shareBurnAmount;
emit ShareBurnUpdate(shareBurnAmount, i_thisChainSelector, totalShares - shareBurnAmount);
_burnShares(withdrawer, shareBurnAmount);

// KEEP:
uint256 totalShares = s_totalShares;                  // snapshot for calculation
emit WithdrawInitiated(withdrawer, shareBurnAmount, i_thisChainSelector);
// withdrawData.totalShares = totalShares — still set as before
// _ccipSend to strategy — unchanged
```

#### `onTokenTransfer()` — local case (parent is strategy): UNCHANGED IN PHASE 1

Phase 2 introduces try/catch and the `WithdrawFail` path for this local case.

#### `_handleCCIPWithdrawToParent()`

Remove `s_totalShares -= withdrawData.shareBurnAmount` and its `ShareBurnUpdate` emit.
The `totalShares` snapshot is still read and set on `withdrawData` for calculation purposes.

```solidity
function _handleCCIPWithdrawToParent(bytes memory data, uint64 sourceChainSelector) internal {
    WithdrawData memory withdrawData = _decodeWithdrawData(data);
    withdrawData.totalShares = s_totalShares;         // KEEP: snapshot for calculation
    // REMOVE: s_totalShares -= withdrawData.shareBurnAmount;
    // REMOVE: emit ShareBurnUpdate(...);
    _handleCCIPWithdraw(s_strategy, withdrawData);
}
```

#### `_handleCCIPWithdraw()` — parent-is-strategy branch

Change from sending `WithdrawCallback` to: updating state and sending `WithdrawCallbackChild`.
Since the parent IS the strategy handler here, no `WithdrawCallbackParent` round-trip is needed.

```solidity
// Old:
_ccipSend(withdrawData.chainSelector, CcipTxType.WithdrawCallback, abi.encode(withdrawData), withdrawData.usdcWithdrawAmount);

// New:
s_totalShares -= withdrawData.shareBurnAmount;
emit ShareBurnUpdate(withdrawData.shareBurnAmount, withdrawData.chainSelector, s_totalShares);
_ccipSend(
    withdrawData.chainSelector,
    CcipTxType.WithdrawCallbackChild,
    abi.encode(withdrawData),
    withdrawData.usdcWithdrawAmount
);
```

Note: `withdrawData.chainSelector` is the withdraw chain (where shares are held).
`ShareBurnUpdate` uses `withdrawData.chainSelector` (not `sourceChainSelector`) because
that is the chain from which shares originated.

#### New `_handleCCIPWithdrawCallbackParent()`

Receives `WithdrawCallbackParent` from a child strategy. Updates `s_totalShares`. Then
either: completes the withdrawal locally (if parent is the withdraw chain), or forwards
`WithdrawCallbackChild` to the withdraw chain.

```solidity
/// @notice Handles the CCIP callback from a child strategy confirming withdrawal succeeded
/// @notice Updates s_totalShares and either completes locally or forwards to withdraw chain
/// @notice USDC always arrives via CCIP token transfer when usdcWithdrawAmount > 0
/// @param tokenAmounts The token amounts (USDC)
/// @param data The message data - decodes to WithdrawData
function _handleCCIPWithdrawCallbackParent(
    Client.EVMTokenAmount[] memory tokenAmounts,
    bytes memory data
) internal {
    WithdrawData memory withdrawData = _decodeWithdrawData(data);
    s_totalShares -= withdrawData.shareBurnAmount;
    emit ShareBurnUpdate(withdrawData.shareBurnAmount, withdrawData.chainSelector, s_totalShares);

    if (withdrawData.chainSelector == i_thisChainSelector) {
        // Parent is the withdraw chain: burn shares held here, transfer USDC, complete
        if (withdrawData.usdcWithdrawAmount != 0) {
            CCIPOperations._validateTokenAmounts(tokenAmounts, address(i_usdc), withdrawData.usdcWithdrawAmount);
        }
        _burnShares(withdrawData.withdrawer, withdrawData.shareBurnAmount);
        if (withdrawData.usdcWithdrawAmount != 0) {
            _transferUsdcTo(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount);
        }
        emit WithdrawCompleted(withdrawData.withdrawer, withdrawData.usdcWithdrawAmount);
    } else {
        // Withdraw chain is a child: validate USDC and forward
        if (withdrawData.usdcWithdrawAmount != 0) {
            CCIPOperations._validateTokenAmounts(tokenAmounts, address(i_usdc), withdrawData.usdcWithdrawAmount);
        }
        _ccipSend(
            withdrawData.chainSelector,
            CcipTxType.WithdrawCallbackChild,
            data,
            withdrawData.usdcWithdrawAmount
        );
    }
}
```

#### `_handleCCIPMessage()` dispatch

- Replace: `if (txType == CcipTxType.WithdrawCallback) _handleCCIPWithdrawCallback(...)`
- With: `if (txType == CcipTxType.WithdrawCallbackParent) _handleCCIPWithdrawCallbackParent(tokenAmounts, data)`
- Phase 2 will also add: `if (txType == CcipTxType.WithdrawFail) _handleCCIPWithdrawFail(data)`

### 5. PingPong Verification

`_handleCCIPWithdrawPingPong` requires **no changes**. Trace:

1. `totalShares` is captured in `_handleCCIPWithdrawToParent` and stored in `withdrawData.totalShares`
2. Strategy child receives `WithdrawToStrategy`, strategy adapter is zero → sends `WithdrawPingPong`
3. Parent `_handleCCIPWithdrawPingPong` decodes the `withdrawData` (already has `totalShares` set) and calls `_handleCCIPWithdraw` — it does NOT re-read `s_totalShares`
4. Shares remain held on the withdraw chain throughout the ping-pong
5. `_handleCCIPWithdrawPingPong` correctly re-routes the existing `withdrawData` unchanged

---

## Phase 2: try/catch + WithdrawFail

### Overview

Phase 2 adds the failure recovery path. If `IStrategyAdapter.withdraw()` reverts,
a `WithdrawFail` CCIP message is sent to the withdraw chain, which returns the held
shares to the user.

### New `YieldPeer._handleCCIPWithdrawFail()`

Placed in the base `YieldPeer` because both Parent and Child may be the withdraw chain.

```solidity
/// @notice Handles a failed withdrawal by returning held shares to the user
/// @notice Shares were held in this contract since onTokenTransfer — they are not burned
/// @param data The message data - decodes to WithdrawData
function _handleCCIPWithdrawFail(bytes memory data) internal {
    WithdrawData memory withdrawData = _decodeWithdrawData(data);
    i_share.transfer(withdrawData.withdrawer, withdrawData.shareBurnAmount);
}
```

Note: no `s_totalShares` update is needed here because it was never decremented for this withdrawal.

### Changes to `ChildPeer._handleCCIPWithdrawToStrategy()`

Wrap `IStrategyAdapter.withdraw()` in try/catch. Only the external adapter call is wrapped —
the `getTotalValue` (view) and amount calculation (pure) cannot fail.

```solidity
function _handleCCIPWithdrawToStrategy(bytes memory data) internal {
    WithdrawData memory withdrawData = _decodeWithdrawData(data);
    address activeStrategyAdapter = _getActiveStrategyAdapter();
    if (activeStrategyAdapter != address(0)) {
        uint256 totalValue = _getTotalValueFromStrategy(activeStrategyAdapter, address(i_usdc));
        uint256 usdcWithdrawAmount =
            _calculateWithdrawAmount(totalValue, withdrawData.totalShares, withdrawData.shareBurnAmount);

        if (usdcWithdrawAmount != 0) {
            // @notice WithdrawFromStrategy is emitted BEFORE the try/catch because the external
            // call may revert. The event indicates a withdrawal was ATTEMPTED, not necessarily
            // completed. If the catch branch is taken, the WithdrawFail path returns shares to user.
            emit WithdrawFromStrategy(activeStrategyAdapter, usdcWithdrawAmount);
            try IStrategyAdapter(activeStrategyAdapter).withdraw(address(i_usdc), usdcWithdrawAmount)
                returns (uint256 actualWithdrawn)
            {
                withdrawData.usdcWithdrawAmount = actualWithdrawn;
                _ccipSend(
                    i_parentChainSelector,
                    CcipTxType.WithdrawCallbackParent,
                    abi.encode(withdrawData),
                    actualWithdrawn
                );
            } catch {
                // If the withdraw chain is this chain, cannot CCIP to self — return shares directly
                if (withdrawData.chainSelector == i_thisChainSelector) {
                    i_share.transfer(withdrawData.withdrawer, withdrawData.shareBurnAmount);
                } else {
                    _ccipSend(
                        withdrawData.chainSelector,
                        CcipTxType.WithdrawFail,
                        abi.encode(withdrawData),
                        ZERO_BRIDGE_AMOUNT
                    );
                }
            }
        } else {
            // usdcWithdrawAmount == 0: treat as success — see known issues
            _ccipSend(
                i_parentChainSelector,
                CcipTxType.WithdrawCallbackParent,
                abi.encode(withdrawData),
                ZERO_BRIDGE_AMOUNT
            );
        }
    } else {
        emit WithdrawPingPongToParent(withdrawData.shareBurnAmount);
        _ccipSend(
            i_parentChainSelector, CcipTxType.WithdrawPingPong, abi.encode(withdrawData), ZERO_BRIDGE_AMOUNT
        );
    }
}
```

### Changes to `ParentPeer._handleCCIPWithdraw()` — parent-is-strategy branch

Same try/catch pattern. Since parent is the strategy and state handler, failure sends
`WithdrawFail` directly to the withdraw chain.

```solidity
if (strategy.chainSelector == i_thisChainSelector) {
    address activeStrategyAdapter = _getActiveStrategyAdapter();
    if (activeStrategyAdapter != address(0)) {
        uint256 totalValue = _getTotalValueFromStrategy(activeStrategyAdapter, address(i_usdc));
        uint256 usdcWithdrawAmount =
            _calculateWithdrawAmount(totalValue, withdrawData.totalShares, withdrawData.shareBurnAmount);

        if (usdcWithdrawAmount != 0) {
            // @notice See note on WithdrawFromStrategy event in _handleCCIPWithdrawToStrategy
            emit WithdrawFromStrategy(activeStrategyAdapter, usdcWithdrawAmount);
            try IStrategyAdapter(activeStrategyAdapter).withdraw(address(i_usdc), usdcWithdrawAmount)
                returns (uint256 actualWithdrawn)
            {
                withdrawData.usdcWithdrawAmount = actualWithdrawn;
                s_totalShares -= withdrawData.shareBurnAmount;
                emit ShareBurnUpdate(withdrawData.shareBurnAmount, withdrawData.chainSelector, s_totalShares);
                _ccipSend(
                    withdrawData.chainSelector,
                    CcipTxType.WithdrawCallbackChild,
                    abi.encode(withdrawData),
                    actualWithdrawn
                );
            } catch {
                _ccipSend(
                    withdrawData.chainSelector,
                    CcipTxType.WithdrawFail,
                    abi.encode(withdrawData),
                    ZERO_BRIDGE_AMOUNT
                );
            }
        } else {
            // usdcWithdrawAmount == 0: treat as success — see known issues
            s_totalShares -= withdrawData.shareBurnAmount;
            emit ShareBurnUpdate(withdrawData.shareBurnAmount, withdrawData.chainSelector, s_totalShares);
            _ccipSend(
                withdrawData.chainSelector,
                CcipTxType.WithdrawCallbackChild,
                abi.encode(withdrawData),
                ZERO_BRIDGE_AMOUNT
            );
        }
    } else {
        // ping pong (unchanged)
    }
}
```

### Changes to `ParentPeer.onTokenTransfer()` — local case (parent is both strategy and withdraw chain)

This is the last remaining case with an optimistic burn. Phase 2 fixes it with local try/catch.

```solidity
if (strategy.chainSelector == i_thisChainSelector) {
    address activeStrategyAdapter = _getActiveStrategyAdapter();
    if (activeStrategyAdapter == address(0)) revert ParentPeer__InactiveStrategyAdapter();

    uint256 totalValue = _getTotalValueFromStrategy(activeStrategyAdapter, address(i_usdc));
    uint256 usdcWithdrawAmount = _calculateWithdrawAmount(totalValue, totalShares, shareBurnAmount);

    if (usdcWithdrawAmount != 0) {
        // @notice See note on WithdrawFromStrategy event in _handleCCIPWithdrawToStrategy
        emit WithdrawFromStrategy(activeStrategyAdapter, usdcWithdrawAmount);
        try IStrategyAdapter(activeStrategyAdapter).withdraw(address(i_usdc), usdcWithdrawAmount)
            returns (uint256 actualWithdrawn)
        {
            s_totalShares -= shareBurnAmount;
            emit ShareBurnUpdate(shareBurnAmount, i_thisChainSelector, s_totalShares);
            emit WithdrawCompleted(withdrawer, actualWithdrawn);
            _burnShares(withdrawer, shareBurnAmount);
            _transferUsdcTo(withdrawer, actualWithdrawn);
        } catch {
            // Return shares to user — they are held in this contract
            i_share.transfer(withdrawer, shareBurnAmount);
        }
    } else {
        // usdcWithdrawAmount == 0: treat as success — see known issues
        s_totalShares -= shareBurnAmount;
        emit ShareBurnUpdate(shareBurnAmount, i_thisChainSelector, s_totalShares);
        emit WithdrawCompleted(withdrawer, 0);
        _burnShares(withdrawer, shareBurnAmount);
    }
}
```

### `_handleCCIPMessage()` dispatch updates (both peers)

Add to ChildPeer and ParentPeer:

```solidity
if (txType == CcipTxType.WithdrawFail) _handleCCIPWithdrawFail(data);
```

### `_withdrawFromStrategy()` helper

**Keep** `_withdrawFromStrategy()` for rebalance paths (`_rebalanceParentToParent`,
`_handleCCIPRebalanceFromOldStrategy`), which do not yet use try/catch. Phase 2 withdrawal
paths inline the withdrawal logic to accommodate try/catch.

---

## `s_totalShares` Update: Where it moves

| Scenario                             | Old location                  | New location                                      |
| ------------------------------------ | ----------------------------- | ------------------------------------------------- |
| Child initiated, parent is strategy  | `_handleCCIPWithdrawToParent` | `_handleCCIPWithdraw` (parent-is-strategy branch) |
| Child initiated, child B strategy    | `_handleCCIPWithdrawToParent` | `_handleCCIPWithdrawCallbackParent`               |
| Child initiated, same-chain strategy | `_handleCCIPWithdrawToParent` | `_handleCCIPWithdrawCallbackParent`               |
| Parent initiated, strategy is child  | `onTokenTransfer`             | `_handleCCIPWithdrawCallbackParent`               |
| Parent initiated, parent is strategy | `onTokenTransfer`             | `onTokenTransfer` (Phase 2: after successful try) |

## Share Burn: Where it moves

| Scenario                             | Old location                 | New location                                                 |
| ------------------------------------ | ---------------------------- | ------------------------------------------------------------ |
| Child initiated (any strategy)       | `ChildPeer.onTokenTransfer`  | `ChildPeer._handleCCIPWithdrawCallbackChild`                 |
| Parent initiated, strategy is child  | `ParentPeer.onTokenTransfer` | `ParentPeer._handleCCIPWithdrawCallbackParent`               |
| Parent initiated, parent is strategy | `ParentPeer.onTokenTransfer` | `ParentPeer.onTokenTransfer` (Phase 2: after successful try) |

---

## New Invariants

### Share Integrity

1. **Shares in-flight:** At any point, `share.balanceOf(peer) + ghost_totalSharesBurned == ghost_totalSharesMinted`. Shares held by the peer are in-between (minted but not yet burned or returned).

2. **Burn-after-confirm:** `SharesBurned` event MUST be preceded by either a `WithdrawCallbackChild` or `WithdrawCallbackParent` message arrival for the same withdrawer and amount. Shares are never burned at withdrawal initiation.

3. **Fail-returns-shares:** For every `WithdrawFail` handled, `share.balanceOf(withdrawer)` increases by `shareBurnAmount` and `s_totalShares` is unchanged.

4. **No double-burn:** Once `SharesBurned` is emitted for a given (withdrawer, shareBurnAmount), no further burn of those shares can occur.

### Withdrawal Completion

5. **WithdrawCompleted implies USDC received:** When `WithdrawCompleted` is emitted with `amount > 0`, the withdrawer's USDC balance must increase by that amount in the same transaction.

6. **s_totalShares consistency:** `s_totalShares == ghost_totalSharesMinted - ghost_totalSharesBurned` (existing invariant, unchanged — now just confirmed at a different point in the flow).

### Cross-chain message parity

7. **Every `WithdrawToParent` resolves:** For every `WithdrawToParent` message, eventually exactly one of (`WithdrawCompleted`, `WithdrawFail` handled) occurs for the same withdrawer.

---

## Testing Requirements

### Phase 1 Unit Tests

New test files / additions needed:

**`ParentWithdraw.t.sol`**

- `test_yield_parent_withdraw_strategyIsNotParent_*`: verify shares are NOT burned in `onTokenTransfer`, are burned in `_handleCCIPWithdrawCallbackParent`
- `test_yield_parent_handleCCIPWithdrawCallbackParent_updatesState`: verify `s_totalShares` decrements, `ShareBurnUpdate` emitted
- `test_yield_parent_handleCCIPWithdrawCallbackParent_localCompletion`: parent is withdraw chain — burns shares, transfers USDC
- `test_yield_parent_handleCCIPWithdrawCallbackParent_forwardsToChild`: verify `WithdrawCallbackChild` sent with correct bridge amount

**`ChildWithdraw.t.sol`**

- `test_yield_child_onTokenTransfer_doesNotBurnShares`: verify share balance stays in child contract
- `test_yield_child_handleCCIPWithdrawCallbackChild_burnsShares_transfersUsdc`
- `test_yield_child_handleCCIPWithdrawCallbackChild_sameChainOptimisation`: no USDC in tokenAmounts, transfers from local balance

**Integration tests** — update existing tests to route through the new CCIP message types:

- All existing `test_yield_child_withdraw_*` and `test_yield_parent_withdraw_*` scenarios
- PingPong tests should pass without changes (verify)

### Phase 2 Unit Tests

**New `ChildWithdrawFail.t.sol`**

- `test_yield_child_withdraw_fail_strategyReverts_returnsShares`
- `test_yield_child_withdraw_fail_strategyReverts_doesNotUpdateTotalShares`
- `test_yield_child_withdraw_fail_strategyReverts_emitsNoSharesBurned`

**New `ParentWithdrawFail.t.sol`**

- `test_yield_parent_withdraw_fail_strategyReverts_returnsShares` (local case)
- `test_yield_parent_withdraw_fail_crosschain_returnsShares`
- `test_yield_parent_withdraw_fail_doesNotUpdateTotalShares`

---

## Certora Spec Updates

The Certora specs use hardcoded integers for `CcipTxType`. Required updates:

**`Child.spec`**

- Comment update: `// CcipTxType.WithdrawCallback` → `// CcipTxType.WithdrawCallbackChild` (integer 6 unchanged)
- `RebalanceFromOldStrategy`: any `== 7` → `== 8`
- `RebalanceToNewStrategy`: any `== 8` → `== 9`
- `DepositPingPong`: any `== 9` → `== 10`
- `WithdrawPingPong`: any `== 10` → `== 11`
- New rules for `WithdrawCallbackParent` (7) being sent from `_handleCCIPWithdrawToStrategy`
- Update `handleCCIPMessage_WithdrawCallback` rule → `handleCCIPMessage_WithdrawCallbackChild`
- Ghost + hook for `WithdrawCallbackParent` sent event
- Add `handleCCIPMessage_WithdrawFail` rule (Phase 2)

**`Parent.spec`**

- Same integer shifts for `RebalanceFromOldStrategy` (7→8), `RebalanceToNewStrategy` (8→9), `DepositPingPong` (9→10), `WithdrawPingPong` (10→11)
- New rules for `_handleCCIPWithdrawCallbackParent`: state update, routing
- Update `handleCCIPMessage_WithdrawCallback` rule → `handleCCIPMessage_WithdrawCallbackParent`
- Add `handleCCIPMessage_WithdrawFail` rule (Phase 2)

---

## Known Issues / Notes for Future Work

### 1. Nested CCIP failure (accepted risk)

If `WithdrawFail` itself fails to deliver (e.g., out of gas on destination chain), shares
are permanently locked in the peer contract with no on-chain recovery path. This risk is
accepted for now. A future task should consider a manual admin recovery function, e.g.:
`recoverLockedShares(address withdrawer, uint256 amount)` with access control.

### 2. `usdcWithdrawAmount == 0` treated as success (known edge case)

If a user burns shares of sufficiently small value that `_calculateWithdrawAmount` returns
zero, the withdrawal is treated as a success — shares are burned and 0 USDC is returned.
This is intentional: the `withdraw()` call is never made (so there is nothing to `catch`),
and returning shares would create an infinite retry loop with the same result. Future work
may consider a minimum withdrawal amount guard earlier in the flow.

### 3. `usdcWithdrawAmount` staleness in concurrent withdrawals

In the new flow, `s_totalShares` is not decremented until withdrawal confirmation. If two
withdrawals are in flight simultaneously, both may capture the same `totalShares` snapshot,
leading to slightly over-proportional USDC calculations. In practice this is bounded by
the liquidity in Aave/Compound (which is deep). Phase 2's try/catch is the safety net for
the extreme case where the pool cannot satisfy both withdrawals.

### 5. Same-chain withdrawal incurs extra CCIP hops (gas/cost trade-off)

When the strategy and withdraw chain are the same child (Scenario C), the withdrawal
now makes 4 CCIP hops: Child A→Parent, Parent→Child A, Child A→Parent (with USDC),
Parent→Child A (with USDC). A same-chain optimisation could reduce this to 2 hops by
holding USDC locally during the parent round-trip. This was deliberately removed for code
simplicity and to keep a uniform code path for all child-initiated withdrawals. If CCIP
costs become a concern for this scenario, the optimisation can be reintroduced.

### 4. Rebalance paths do not use try/catch (future work)

`_withdrawFromStrategy()` is retained for use in `_rebalanceParentToParent()` and
`_handleCCIPRebalanceFromOldStrategy()`. These paths do not yet have try/catch protection.
If a rebalance withdrawal fails, funds could be stuck. This should be addressed in a
dedicated rebalance-safety task.
