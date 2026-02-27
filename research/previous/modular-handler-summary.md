# Modular Invariant Handler — Progress Summary

## Status: ALL STEPS COMPLETE (pending compile verification)

---

## Step 1: `test/invariant/modules/Ghosts.sol` — COMPLETE

**Added:**
- `import {IYieldPeer}` — required for `CcipTxType` and `Strategy` types used throughout
- **SYSTEM AGGREGATE** section at the top — running totals and cross-contract state, split into sub-sections:
  - *Deposits*: `ghost_totalUsdcDeposited`, `ghost_totalUsdcDeposited_userPrincipal`, per-user principal mapping, per-user fees mapping, per-user shares minted mapping
  - *Withdrawals*: `ghost_totalSharesBurned`, per-user shares burned mapping, `ghost_event_totalUsdcWithdrawnPerUser` mapping
  - *Fees*: `ghost_totalFeesWithdrawnInStablecoin`, `ghost_feeRate`
  - *Strategy*: `ghost_previousStrategy` (type `IYieldPeer.Strategy`)
  - *Flags*: `ghost_flag_nonFeeWithdrawer_withdrewFees`
- **DEPOSIT TRACKING** sub-section (within SYSTEM AGGREGATE) — `DepositRecord` struct and `ghost_userDeposits` mapping (moved from Handler)
- **Two new WithdrawFromStrategy rebalance ghosts** in YIELDPEER EVENTS section:
  - `ghost_yieldPeer_event_WithdrawFromStrategy_rebalance_emissions`
  - `ghost_yieldPeer_event_WithdrawFromStrategy_rebalance_param_strategyAdapter`
- **STRATEGY ADAPTER EVENTS** section — Deposit and Withdraw event ghosts, using `param_usdc` (matching the actual event signature `Deposit(address indexed usdc, uint256 indexed amount)`)
- **YIELDFEES EVENTS** section — FeeRateSet, FeeTaken, FeesWithdrawn ghosts
- **CRE RECEIVER EVENTS** section — OnReportSecurityChecksPassed, KeystoneForwarderSet, WorkflowSet, WorkflowRemoved ghosts

**Fixed:**
- `CcipTxType` → `IYieldPeer.CcipTxType` (2 occurrences in CCIPMessageSent/Received ghosts)
- `Strategy` → `IYieldPeer.Strategy` (in PARENT STATE section)

**NOTE: The SHARE section was left untouched.** The existing ghost declarations there (`ghost_share_state_balanceOf_totalAcrossChains`, `ghost_share_state_crosschain_totalSupply`) are placeholders with no clear definition — the `@dev` comment on `ghost_share_state_crosschain_totalSupply` is empty. These need owner review before any changes are made. See `@review` comment at end of file.

---

## Step 2: `test/invariant/modules/Events.sol` — COMPLETE

**Fixed:**
- `bytes eventSignature` → `bytes32 sig` (topics are `bytes32`, not `bytes`)
- Added `import {Vm} from "forge-std/Vm.sol";`
- Added `import {IYieldPeer}` (for `CcipTxType` casting in crosschain log handler)
- Fixed import path for `Ghosts` to `"./Ghosts.sol"`
- All event signature constants changed from `bytes internal` to `bytes32 internal constant`

**Completed log handlers:**

| Function | Events handled |
|---|---|
| `_handleDepositLogs` | DepositInitiated, DepositToStrategy, SharesMinted, ShareMintUpdate, DepositForwardedToStrategy, DepositPingPongToChild, DepositPingPongToParent, StrategyAdapter Deposit |
| `_handleWithdrawLogs` | WithdrawInitiated, WithdrawFromStrategy (+ MAX sentinel rebalance detection), WithdrawCompleted, SharesBurned, ShareBurnUpdate, WithdrawForwardedToStrategy, WithdrawPingPongToChild, WithdrawPingPongToParent, StrategyAdapter Withdraw |
| `_handleRebalanceLogs` | StrategyUpdated, ReportDecoded, OnReportSecurityChecksPassed |
| `_handleCrosschainLogs` | CCIPMessageSent, CCIPMessageReceived |
| `_handleFeeAndAdminLogs` | FeeRateSet, FeeTaken, FeesWithdrawn, KeystoneForwarderSet, WorkflowSet, WorkflowRemoved |

**Key design decisions:**
- `WithdrawFromStrategy` MAX sentinel detection is in `_handleWithdrawLogs` (fires during both regular withdrawals and rebalancing; MAX sentinel `amount == type(uint256).max` detected inline)
- MAX sentinel amount is **excluded** from `ghost_yieldPeer_event_WithdrawFromStrategy_param_amount_totalSum` to avoid uint256 overflow
- All handlers receive the `Vm.Log[] memory logs` array (fetched once by `_handleLogs()`) — no repeated `vm.getRecordedLogs()` calls
- No assertions in any log handler — event ghosts only

---

## Step 3: `test/invariant/Handler.t.sol` — COMPLETE

**Removed:**
- All inline ghost variable declarations — now in `Ghosts.sol`
- All inline event signature constants — now in `Events.sol`
- `_handleDepositLogs()`, `_handleWithdrawLogs()`, `_handleOnReportLogs()` — replaced by `_handleLogs()` from `Events.sol`
- `DepositRecord` struct and `ghost_userDeposits` mapping — now in `Ghosts.sol`
- `IStrategyAdapter` import — `getTotalValue()` now called directly in `Invariant.t.sol`
- `getPreviousStrategy()` and `getLastCREReceivedStrategy()` getter functions — no longer needed (public ghosts have auto-getters; `ghost_event_lastCREReceivedStrategy` dropped entirely)
- `ghost_flag_decodedStrategy_mismatchWithEmittedStrategy` — dropped (invariant replaced)

**Added:**
- `import {Events} from "./modules/Events.sol";`
- `contract Handler is Test, Events` (with NatSpec comment: `/// @notice Events inherits Ghosts`)
- `_updateDepositStateGhosts(address depositor, uint256 depositAmount)` — called after `_handleLogs()`; reads `ghost_yieldPeer_event_SharesMinted_param_amount` (documented dependency)
- `_updateWithdrawStateGhosts(address withdrawer, uint256 shareBurnAmount)` — called after `_handleLogs()`; reads `ghost_yieldPeer_event_WithdrawCompleted_param_amount` (documented dependency)
- `_updateFeesStateGhosts(uint256 availableFees)` — increments `ghost_totalFeesWithdrawnInStablecoin`

**Updated action functions:**
- `deposit()`: `_handleLogs()` then `_updateDepositStateGhosts()`
- `withdraw()`: `_handleLogs()` then `_updateWithdrawStateGhosts()`
- `onReport()`: `ghost_previousStrategy = parent.getStrategy()` before call, `_handleLogs()` after
- `withdrawFees()`: `_updateFeesStateGhosts(availableFees)`, `ghost_flag_nonFeeWithdrawer_withdrewFees`
- `setFeeRate()`: `ghost_feeRate = feeRate`
- `_adminDeposit()`: `_handleLogs()` then `_updateDepositStateGhosts()`

---

## Step 4: `test/invariant/Invariant.t.sol` — COMPLETE

**Ghost names updated (old → new):**

| Old | New |
|---|---|
| `ghost_event_totalSharesMinted` | `ghost_parent_event_ShareMintUpdate_param_amount_totalSum` |
| `ghost_event_totalUsdcWithdrawn` | `ghost_yieldPeer_event_WithdrawCompleted_param_amount_totalSum` |
| `ghost_state_totalSharesBurned` | `ghost_totalSharesBurned` |
| `ghost_event_depositInitiated_emissions` | `ghost_yieldPeer_event_DepositInitiated_emissions` |
| `ghost_event_shareMintUpdate_emissions` | `ghost_parent_event_ShareMintUpdate_emissions` |
| `ghost_event_withdrawCompleted_emissions` | `ghost_yieldPeer_event_WithdrawCompleted_emissions` |
| `ghost_event_shareBurnUpdate_emissions` | `ghost_parent_event_ShareBurnUpdate_emissions` |
| `ghost_event_feeTaken_emissions` | `ghost_yieldFees_event_FeeTaken_emissions` |
| `ghost_event_totalFeesTakenInStablecoin` | `ghost_yieldFees_event_FeeTaken_param_amount_totalSum` |
| `ghost_event_totalFeesTakenInStablecoinPerUser` | `ghost_totalFeesTakenInStablecoinPerUser` |
| `ghost_state_totalUsdcDeposited_userPrincipal` | `ghost_totalUsdcDeposited_userPrincipal` |
| `ghost_state_totalUsdcDepositedPerUser_userPrincipal` | `ghost_totalUsdcDepositedPerUser_userPrincipal` |
| `ghost_state_totalFeesWithdrawnInStablecoin` | `ghost_totalFeesWithdrawnInStablecoin` |
| `ghost_nonFeeWithdrawer_withdrewFees` | `ghost_flag_nonFeeWithdrawer_withdrewFees` |
| `ghost_event_totalUsdcWithdrawnPerUser` | `ghost_event_totalUsdcWithdrawnPerUser` (unchanged) |

**Broken references fixed:**

| Old (broken) | Replacement |
|---|---|
| `handler.ghost_flag_creReport_decoded()` | `handler.ghost_rebalancer_event_ReportDecoded_emissions() > 0` |
| `handler.ghost_maxSentinelWithdrawals()` | `handler.ghost_yieldPeer_event_WithdrawFromStrategy_rebalance_emissions()` |
| `handler.ghost_maxSentinelAdapterBalanceAfter()` | `IStrategyAdapter(handler.ghost_yieldPeer_event_WithdrawFromStrategy_rebalance_param_strategyAdapter()).getTotalValue(address(usdc))` called live |

**Invariants consolidated/replaced:**
- Dropped `invariant_decodedCREReportStrategy_matchesParentStrategyState` and `invariant_decodedCREReportStrategy_matches_emittedStrategy` (both relied on broken ghost references and the dropped `ghost_flag_decodedStrategy_mismatchWithEmittedStrategy`)
- Added `invariant_decodedCREReportStrategy_matchesParentStrategy()` — single clean replacement: compares `ghost_rebalancer_event_ReportDecoded_param_*` directly against `parent.getStrategy().*`
- Updated `invariant_strategyAdapter_rebalance_withdrawsTotalValue()` — now uses `ghost_yieldPeer_event_WithdrawFromStrategy_rebalance_emissions` as the guard and calls `IStrategyAdapter.getTotalValue()` live on `ghost_yieldPeer_event_WithdrawFromStrategy_rebalance_param_strategyAdapter`

**Note on two "new" invariants from the plan:**
- `invariant_depositInitiated_emittedOnEveryDeposit()` — not added; already fully covered by the existing `invariant_depositInitiated_shareMintUpdate_consistency()` (1:1 DepositInitiated vs ShareMintUpdate)
- `invariant_feeTaken_emittedWhenFeeRateNonZero()` — not added; too fragile to express correctly as a simple invariant when feeRate changes mid-run. The existing `invariant_totalFees_equals_sumOfDepositFees()` provides comprehensive fee correctness coverage

---

## Next Steps

1. **Compile and run** — verify all 4 files compile clean and invariant tests pass
2. **SHARE ghosts** — decide what `ghost_share_state_balanceOf_totalAcrossChains` and `ghost_share_state_crosschain_totalSupply` should actually track and add proper NatSpec
3. **`Actors.sol`** — migrate `_seedToAddress`, `_createOrGetUser`, `_indexToUser`, and the `users` EnumerableSet from Handler (note: `forEachUser` and `forEachChainSelector` must stay on Handler as they are called externally from Invariant.t.sol)
