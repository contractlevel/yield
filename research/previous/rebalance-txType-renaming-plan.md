# Rebalance CcipTxType Renaming Plan

## Summary

Rename `RebalanceOldStrategy` → `RebalanceFromOldStrategy` and `RebalanceNewStrategy` → `RebalanceToNewStrategy` throughout the codebase.

The enum values in `src/interfaces/IYieldPeer.sol` have already been updated. This plan covers all remaining references.

Internal handler functions are also renamed for consistency:
- `_handleCCIPRebalanceOldStrategy` → `_handleCCIPRebalanceFromOldStrategy`
- `_handleCCIPRebalanceNewStrategy` → `_handleCCIPRebalanceToNewStrategy`

---

## Files to Update

### `src/` (code + natspec)

**`src/peers/ChildPeer.sol`**
- Line 117: natspec `RebalanceOldStrategy:` → `RebalanceFromOldStrategy:`
- Line 118: natspec `RebalanceNewStrategy:` → `RebalanceToNewStrategy:`
- Line 137: `CcipTxType.RebalanceOldStrategy` → `CcipTxType.RebalanceFromOldStrategy`
- Line 137: call `_handleCCIPRebalanceOldStrategy` → `_handleCCIPRebalanceFromOldStrategy`
- Line 138: `CcipTxType.RebalanceNewStrategy` → `CcipTxType.RebalanceToNewStrategy`
- Line 138: call `_handleCCIPRebalanceNewStrategy` → `_handleCCIPRebalanceToNewStrategy`
- Line 210: function declaration `_handleCCIPRebalanceOldStrategy` → `_handleCCIPRebalanceFromOldStrategy`
- Line 230: `CcipTxType.RebalanceNewStrategy` → `CcipTxType.RebalanceToNewStrategy`

**`src/peers/ParentPeer.sol`**
- Line 219: natspec `RebalanceNewStrategy:` → `RebalanceToNewStrategy:`
- Line 238: `CcipTxType.RebalanceNewStrategy` → `CcipTxType.RebalanceToNewStrategy`
- Line 238: call `_handleCCIPRebalanceNewStrategy` → `_handleCCIPRebalanceToNewStrategy`
- Line 456: `CcipTxType.RebalanceNewStrategy` → `CcipTxType.RebalanceToNewStrategy`
- Line 464: `CcipTxType.RebalanceOldStrategy` → `CcipTxType.RebalanceFromOldStrategy`

**`src/peers/YieldPeer.sol`**
- Line 254: function declaration `_handleCCIPRebalanceNewStrategy` → `_handleCCIPRebalanceToNewStrategy`

---

### `test/`

**`test/unit/rebalancer/OnReport.t.sol`**
- Line 24: variable `rebalanceNewStrategyTxType` → `rebalanceToNewStrategyTxType`, enum ref `CcipTxType.RebalanceNewStrategy` → `CcipTxType.RebalanceToNewStrategy`
- Line 25: variable `rebalanceOldStrategyTxType` → `rebalanceFromOldStrategyTxType`, enum ref `CcipTxType.RebalanceOldStrategy` → `CcipTxType.RebalanceFromOldStrategy`
- All other usages of `rebalanceNewStrategyTxType` / `rebalanceOldStrategyTxType` in this file updated accordingly
- Line 219: comment updated
- Line 261: comment updated

**`test/unit/parentPeer/ParentDeposit.t.sol`**
- Line 271: comment referencing `_handleCCIPRebalanceNewStrategy` → `_handleCCIPRebalanceToNewStrategy`

---

### `certora/`

**`certora/harness/ChildHarness.sol`**
- Line 33: function declaration `handleCCIPRebalanceOldStrategy` → `handleCCIPRebalanceFromOldStrategy`
- Line 34: internal call `_handleCCIPRebalanceOldStrategy` → `_handleCCIPRebalanceFromOldStrategy`

**`certora/harness/YieldHarness.sol`**
- Line 39: function declaration `handleCCIPRebalanceNewStrategy` → `handleCCIPRebalanceToNewStrategy`
- Line 40: internal call `_handleCCIPRebalanceNewStrategy` → `_handleCCIPRebalanceToNewStrategy`

**`certora/spec/child/Child.spec`**
- Line 407: section comment `handleCCIPRebalanceOldStrategy` → `handleCCIPRebalanceFromOldStrategy`
- Lines 408, 446, 489, 601: rule names `handleCCIPRebalanceOldStrategy_*` → `handleCCIPRebalanceFromOldStrategy_*`
- Lines 438, 479, 498: harness call `handleCCIPRebalanceOldStrategy` → `handleCCIPRebalanceFromOldStrategy`
- Line 500: comment `CcipTxType.RebalanceNewStrategy` → `CcipTxType.RebalanceToNewStrategy`
- Lines 623, 625: rule name and enum ref `RebalanceNewStrategy` → `RebalanceToNewStrategy`
- Line 603: enum ref `CcipTxType.RebalanceOldStrategy` → `CcipTxType.RebalanceFromOldStrategy`

**`certora/spec/yield/Yield.spec`**
- Lines 252–281: all `handleCCIPRebalanceNewStrategy` → `handleCCIPRebalanceToNewStrategy` (section comment, rule names, harness calls)

**`certora/spec/parent/Parent.spec`**
- Line 955: comment `RebalanceNewStrategy` → `RebalanceToNewStrategy`
- Line 975: comment `RebalanceOldStrategy` → `RebalanceFromOldStrategy`

---

### `README.md`

- Line 224: `RebalanceOldStrategy` → `RebalanceFromOldStrategy`
- Line 225: `RebalanceNewStrategy` → `RebalanceToNewStrategy`

---

### `research/previous/checks-invariants-plan.md`

- Line 36: `ChildPeer._handleCCIPRebalanceOldStrategy` → `ChildPeer._handleCCIPRebalanceFromOldStrategy`

---

## Order of Changes

1. `src/peers/YieldPeer.sol` — rename base function declaration first (other files call it)
2. `src/peers/ChildPeer.sol` — update natspec, dispatch, and handler declaration
3. `src/peers/ParentPeer.sol` — update natspec, dispatch, and call sites
4. `certora/harness/ChildHarness.sol` — update harness wrapper to match renamed internal
5. `certora/harness/YieldHarness.sol` — update harness wrapper to match renamed internal
6. `certora/spec/child/Child.spec` — update rule names, harness calls, enum refs, comments
7. `certora/spec/yield/Yield.spec` — update rule names, harness calls
8. `certora/spec/parent/Parent.spec` — update comments only
9. `test/unit/rebalancer/OnReport.t.sol` — update variable names, enum refs, comments
10. `test/unit/parentPeer/ParentDeposit.t.sol` — update comment
11. `README.md` — update documentation
12. `research/previous/checks-invariants-plan.md` — update reference
