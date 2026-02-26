# Modular Invariant Handler Plan

## Goal

Refactor the invariant test suite into a clean, modular structure. Each file has a single, clear responsibility. The result should be easy to read, maintain, and extend.

---

## Final Architecture

```
test/invariant/
├── Handler.t.sol       — Fuzz actions, state ghost updates, setup, deposit tracking
├── Invariant.t.sol     — Invariant assertions only (migrated to new ghost names)
└── modules/
    ├── Ghosts.sol      — All ghost variable declarations (pure storage)
    ├── Events.sol      — Event signatures + log handlers (inherits Ghosts)
    └── Actors.sol      — (future: user actor management)
```

**Inheritance chain:** `Handler is Test, Events` where `Events is Ghosts`

---

## Ghost Naming Schemes

Two naming schemes, depending on the ghost's scope:

**Per-contract ghosts** (in their own dedicated section per contract):
```
ghost_{contract}_{event|state}_{EventName|stateVarName}_{param}
```
- `{contract}` — the specific contract (e.g. `yieldPeer`, `parent`, `strategyAdapter`)
- `{event|state}` — whether it mirrors an event emission or a state variable
- `{EventName|stateVarName}` — the event or variable being tracked
- `{param}` — the specific parameter, or derived suffixes (`emissions`, `amount_totalSum`)

**System aggregate ghosts** (in their own section at the top of Ghosts.sol):
```
ghost_{name}
```
No contract prefix. No forced `event`/`state` label — these span multiple contracts and are a mix of computation sources. Use `ghost_event_` prefix only when the ghost is unambiguously and exclusively event-derived (e.g. `ghost_event_totalUsdcWithdrawnPerUser`). NatSpec clarifies each one.

---

## File Responsibilities

---

### `Ghosts.sol` — Pure storage

No logic, no `vm` calls. Abstract contract. All sections use Foundry layout headers.

**Required imports:** `IYieldPeer` (for `CcipTxType` and `Strategy`)

#### Section order (top to bottom):

---

**1. SYSTEM AGGREGATE** ← new, at the top

Running totals and cross-contract ghost state. Cannot be attributed to a single contract. Organised into sub-sections. Updated by Handler state helpers (never in log handlers).

```
// Deposits
/// @dev total USDC deposited across all peers (raw, including fees)
ghost_totalUsdcDeposited

/// @dev total USDC deposited across all peers minus fees (user principal)
ghost_totalUsdcDeposited_userPrincipal

/// @dev total USDC deposited per user minus fees (user principal)
mapping(address user => uint256 usdcAmount) ghost_totalUsdcDepositedPerUser_userPrincipal

/// @dev total fees taken in stablecoin per user — computed via _calculateFee at deposit time
mapping(address user => uint256 feeAmount) ghost_totalFeesTakenInStablecoinPerUser

/// @dev total shares minted per user — accumulated via SharesMinted event ghost during deposit
mapping(address user => uint256 shareAmount) ghost_totalSharesMintedPerUser

// Withdrawals
/// @dev total shares burned system-wide — from the shareBurnAmount passed to transferAndCall (not from events)
ghost_totalSharesBurned

/// @dev total shares burned per user — from transferAndCall
mapping(address user => uint256 shareAmount) ghost_totalSharesBurnedPerUser

/// @dev total USDC withdrawn per user — accumulated via WithdrawCompleted event ghost
mapping(address user => uint256 usdcAmount) ghost_event_totalUsdcWithdrawnPerUser

// Fees
/// @dev total fees withdrawn in stablecoin — accumulated during withdrawFees action
ghost_totalFeesWithdrawnInStablecoin

/// @dev current fee rate — mirrors fee rate set in setFeeRate action
ghost_feeRate

// Strategy
/// @dev the strategy stored in parent before onReport changed it
IYieldPeer.Strategy ghost_previousStrategy

/// @dev the strategy adapter's stablecoin balance after a MAX sentinel withdrawal during rebalance
ghost_strategyAdapter_balanceAfter_rebalanceWithdraw

// Flags
/// @dev true if a non-FeeWithdrawer address ever successfully called withdrawFees
bool ghost_flag_nonFeeWithdrawer_withdrewFees
```

**DEPOSIT TRACKING sub-section** (within SYSTEM AGGREGATE):

```solidity
struct DepositRecord {
    address user;
    uint256 amount;    // total deposit amount including fee
    uint256 feeRate;
    uint256 timestamp;
    uint256 fee;
}
/// @dev each user's full deposit history, used for fee cross-checking invariants
mapping(address user => DepositRecord[]) public ghost_userDeposits;
```

---

**2. YIELDPEER STATE** — existing, keep as-is

**3. YIELDPEER EVENTS** — existing, keep as-is

**4. PARENT STATE** — existing, keep as-is

**5. PARENT EVENTS** — existing, keep as-is

**6. CHILD EVENTS** — existing, keep as-is

**7. REBALANCER EVENTS** — existing, keep as-is

---

**8. STRATEGY ADAPTER STATE** ← new section

```
/// @dev balance of the strategy adapter in the underlying protocol after a MAX sentinel withdrawal
/// @dev note: ghost_strategyAdapter_balanceAfter_rebalanceWithdraw in SYSTEM AGGREGATE tracks
/// @dev the most recent rebalance withdrawal across all calls to onReport
ghost_strategyAdapter_state_balanceAfter_lastWithdraw
```

Wait — this is a per-adapter, per-action value. The system aggregate ghost captures the most recent MAX withdrawal specifically (which is what the invariant needs). This section is still useful for tracking the last withdrawal regardless of whether it was a rebalance. Keep both.

---

**9. STRATEGY ADAPTER EVENTS** ← new section

```
ghost_strategyAdapter_event_Deposit_emissions
ghost_strategyAdapter_event_Deposit_param_strategyAdapter
ghost_strategyAdapter_event_Deposit_param_amount
ghost_strategyAdapter_event_Deposit_param_amount_totalSum

ghost_strategyAdapter_event_Withdraw_emissions
ghost_strategyAdapter_event_Withdraw_param_strategyAdapter
ghost_strategyAdapter_event_Withdraw_param_amount
ghost_strategyAdapter_event_Withdraw_param_amount_totalSum
```

---

**10. YIELDFEES EVENTS** ← new section

```
ghost_yieldFees_event_FeeRateSet_emissions
ghost_yieldFees_event_FeeRateSet_param_feeRate

ghost_yieldFees_event_FeeTaken_emissions
ghost_yieldFees_event_FeeTaken_param_amount
ghost_yieldFees_event_FeeTaken_param_amount_totalSum

ghost_yieldFees_event_FeesWithdrawn_emissions
ghost_yieldFees_event_FeesWithdrawn_param_amount
ghost_yieldFees_event_FeesWithdrawn_param_amount_totalSum
```

---

**11. CRE RECEIVER EVENTS** ← new section

```
ghost_creReceiver_event_OnReportSecurityChecksPassed_emissions
ghost_creReceiver_event_OnReportSecurityChecksPassed_param_workflowId
ghost_creReceiver_event_OnReportSecurityChecksPassed_param_workflowOwner
ghost_creReceiver_event_OnReportSecurityChecksPassed_param_workflowName

ghost_creReceiver_event_KeystoneForwarderSet_emissions
ghost_creReceiver_event_KeystoneForwarderSet_param_forwarder

ghost_creReceiver_event_WorkflowSet_emissions
ghost_creReceiver_event_WorkflowSet_param_workflowId
ghost_creReceiver_event_WorkflowSet_param_workflowOwner
ghost_creReceiver_event_WorkflowSet_param_workflowName

ghost_creReceiver_event_WorkflowRemoved_emissions
ghost_creReceiver_event_WorkflowRemoved_param_workflowId
ghost_creReceiver_event_WorkflowRemoved_param_workflowOwner
ghost_creReceiver_event_WorkflowRemoved_param_workflowName
```

---

**12. SHARE** — existing, review for completeness

---

### `Events.sol` — Event signatures + log handlers

Inherits `Ghosts`. Updates **event ghosts only**. No assertions. No state ghost updates.

**Bug fixes required:**
- `bytes eventSignature` → `bytes32 eventSignature` (topics are `bytes32`)
- Add `import {Vm} from "forge-std/Vm.sol";`
- Add `import {IYieldPeer} from "../../src/interfaces/IYieldPeer.sol";`

**Event signatures:** All kept as `bytes32 internal constant` via `keccak256(...)`. Add missing ones for `StrategyAdapter`, `YieldFees`, `CREReceiver`.

**Log handling pattern:**

```solidity
function _handleLogs() internal {
    Vm.Log[] memory logs = vm.getRecordedLogs();
    _handleDepositLogs(logs);
    _handleWithdrawLogs(logs);
    _handleRebalanceLogs(logs);
    _handleCrosschainLogs(logs);
    _handleFeeAndAdminLogs(logs);
}
```

Each sub-function receives the full `logs` array. `vm.getRecordedLogs()` is called exactly once. Sub-functions update only event ghosts for their domain — no assertions, no state ghost updates.

`_handleRebalanceLogs` handles `WithdrawFromStrategy` and updates:
- `ghost_yieldPeer_event_WithdrawFromStrategy_emissions`
- `ghost_yieldPeer_event_WithdrawFromStrategy_rebalance_emissions` (when amount == `type(uint256).max`)

Note: `ghost_strategyAdapter_balanceAfter_rebalanceWithdraw` is **NOT** updated here. It is updated in `_updateRebalanceStateGhosts` in Handler, which reads `ghost_yieldPeer_event_WithdrawFromStrategy_param_strategyAdapter` (set here) to know which adapter to query.

`_handleFeeAndAdminLogs` handles `FeeTaken`, `FeesWithdrawn`, `FeeRateSet`.

`_handleCrosschainLogs` handles `CCIPMessageSent`, `CCIPMessageReceived`.

---

### `Handler.t.sol` — Actions + state ghost updates

Inherits `Events` (which inherits `Ghosts`). Also inherits `Test`.

**What is removed:**
- All inline ghost variable declarations → `Ghosts.sol`
- All inline event signature constants → `Events.sol`
- `_handleDepositLogs()`, `_handleWithdrawLogs()`, `_handleOnReportLogs()` and their assertions

**Action function pattern:**

```solidity
function deposit(...) public returns (address depositor) {
    // ... setup and bound inputs ...
    vm.recordLogs();
    _deposit(depositor, depositAmount, peer);
    _handleLogs();                                       // event ghosts updated
    _updateDepositStateGhosts(depositor, depositAmount); // state ghosts updated
}

function withdraw(...) public {
    // ...
    vm.recordLogs();
    share.transferAndCall(peer, shareBurnAmount, "");
    _handleLogs();
    _updateWithdrawStateGhosts(withdrawer, shareBurnAmount);
}

function onReport(...) public {
    // ...
    ghost_previousStrategy = parent.getStrategy();       // captured BEFORE the call
    vm.recordLogs();
    rebalancer.onReport(workflowMetadata, report);
    _handleLogs();
    _updateRebalanceStateGhosts();
}

function withdrawFees(...) public {
    // ...
    _updateFeesStateGhosts(availableFees);
    // ... execute withdrawals ...
}

function setFeeRate(uint256 feeRate) public {
    // ...
    ghost_feeRate = feeRate;
    // ... execute ...
}
```

**State ghost update helpers (internal, on Handler):**

```solidity
/// @dev updates system aggregate ghosts after a deposit
/// @dev must be called after _handleLogs() — reads ghost_yieldPeer_event_SharesMinted_param_amount
function _updateDepositStateGhosts(address depositor, uint256 depositAmount) internal {
    uint256 fee = _calculateFee(depositAmount);
    uint256 userPrincipal = depositAmount - fee;

    ghost_totalUsdcDeposited += depositAmount;
    ghost_totalUsdcDeposited_userPrincipal += userPrincipal;
    ghost_totalUsdcDepositedPerUser_userPrincipal[depositor] += userPrincipal;
    ghost_totalFeesTakenInStablecoinPerUser[depositor] += fee;

    // reads event ghost set during _handleLogs() — intentional documented dependency
    ghost_totalSharesMintedPerUser[depositor] += ghost_yieldPeer_event_SharesMinted_param_amount;

    _recordDeposit(depositor, depositAmount);
}

/// @dev updates system aggregate ghosts after a withdrawal
/// @dev must be called after _handleLogs() — reads ghost_yieldPeer_event_WithdrawCompleted_param_amount
function _updateWithdrawStateGhosts(address withdrawer, uint256 shareBurnAmount) internal {
    ghost_totalSharesBurned += shareBurnAmount;
    ghost_totalSharesBurnedPerUser[withdrawer] += shareBurnAmount;

    // reads event ghost set during _handleLogs() — intentional documented dependency
    ghost_event_totalUsdcWithdrawnPerUser[withdrawer] +=
        ghost_yieldPeer_event_WithdrawCompleted_param_amount;
}

/// @dev updates system aggregate ghosts after a rebalance (onReport)
/// @dev must be called after _handleLogs() — reads WithdrawFromStrategy event ghost
function _updateRebalanceStateGhosts() internal {
    if (ghost_yieldPeer_event_WithdrawFromStrategy_rebalance_emissions > 0) {
        address adapter = ghost_yieldPeer_event_WithdrawFromStrategy_param_strategyAdapter;
        ghost_strategyAdapter_balanceAfter_rebalanceWithdraw =
            IStrategyAdapter(adapter).getTotalValue(address(usdc));
    }
}

function _updateFeesStateGhosts(uint256 availableFees) internal {
    ghost_totalFeesWithdrawnInStablecoin += availableFees;
}
```

**Fee cross-checking:** Fees are computed via `_calculateFee(depositAmount)` (same formula as the contract) and stored in `ghost_totalFeesTakenInStablecoinPerUser`. This is independent of the event ghost `ghost_yieldFees_event_FeeTaken_param_amount_totalSum`. Invariants can cross-check these two against each other.

**What stays in Handler:**
- Constants, contract references, chain selector mappings, `SystemRoles`
- Constructor + setup
- Public fuzz action functions
- `_updateDepositStateGhosts`, `_updateWithdrawStateGhosts`, `_updateRebalanceStateGhosts`, `_updateFeesStateGhosts`
- `_recordDeposit` and `calculateExpectedFees*` helpers
- User/chain actor management (until Actors.sol)
- Utility functions

---

### `Invariant.t.sol` — Assertions only

Fully migrated to new ghost names. Assertions previously inside Handler log handlers become explicit invariants.

**Ghost name migration (old → new):**

| Old | New |
|---|---|
| `ghost_event_totalSharesMinted` | `ghost_parent_event_ShareMintUpdate_param_amount_totalSum` |
| `ghost_event_totalUsdcWithdrawn` | `ghost_yieldPeer_event_WithdrawCompleted_param_amount_totalSum` |
| `ghost_event_totalSharesBurned` (from events) | `ghost_parent_event_ShareBurnUpdate_param_amount_totalSum` |
| `ghost_event_depositInitiated_emissions` | `ghost_yieldPeer_event_DepositInitiated_emissions` |
| `ghost_event_shareMintUpdate_emissions` | `ghost_parent_event_ShareMintUpdate_emissions` |
| `ghost_event_withdrawCompleted_emissions` | `ghost_yieldPeer_event_WithdrawCompleted_emissions` |
| `ghost_event_shareBurnUpdate_emissions` | `ghost_parent_event_ShareBurnUpdate_emissions` |
| `ghost_event_feeTaken_emissions` | `ghost_yieldFees_event_FeeTaken_emissions` |
| `ghost_event_totalFeesTakenInStablecoin` | `ghost_yieldFees_event_FeeTaken_param_amount_totalSum` |
| `ghost_event_totalFeesTakenInStablecoinPerUser` | `ghost_totalFeesTakenInStablecoinPerUser` |
| `ghost_state_totalSharesBurned` | `ghost_totalSharesBurned` |
| `ghost_state_totalUsdcDeposited_userPrincipal` | `ghost_totalUsdcDeposited_userPrincipal` |
| `ghost_state_totalUsdcDepositedPerUser_userPrincipal` | `ghost_totalUsdcDepositedPerUser_userPrincipal` |
| `ghost_state_totalFeesWithdrawnInStablecoin` | `ghost_totalFeesWithdrawnInStablecoin` |
| `ghost_nonFeeWithdrawer_withdrewFees` | `ghost_flag_nonFeeWithdrawer_withdrewFees` |
| `ghost_event_totalUsdcWithdrawnPerUser` | `ghost_event_totalUsdcWithdrawnPerUser` (unchanged) |
| `ghost_maxSentinelAdapterBalanceAfter` | `ghost_strategyAdapter_balanceAfter_rebalanceWithdraw` |

**Broken references to fix:**

| Old (broken) | Replacement |
|---|---|
| `handler.ghost_flag_creReport_decoded()` | `handler.ghost_rebalancer_event_ReportDecoded_emissions() > 0` |
| `handler.ghost_maxSentinelWithdrawals()` | `handler.ghost_yieldPeer_event_WithdrawFromStrategy_rebalance_emissions()` |
| `handler.ghost_maxSentinelAdapterBalanceAfter()` | `handler.ghost_strategyAdapter_balanceAfter_rebalanceWithdraw()` |

**Dropping `ghost_flag_decodedStrategy_mismatchWithEmittedStrategy`:**

The two CRE invariants that relied on this flag and the broken `ghost_flag_creReport_decoded` can be replaced by a single clean invariant:

```solidity
/// @notice The strategy stored in ParentPeer must always match the last decoded CRE report
function invariant_decodedCREReportStrategy_matchesParentStrategy() public view {
    if (handler.ghost_rebalancer_event_ReportDecoded_emissions() == 0) return;
    assertEq(
        parent.getStrategy().chainSelector,
        handler.ghost_rebalancer_event_ReportDecoded_param_chainSelector(),
        "Invariant violated: ParentPeer strategy chain selector must match last decoded CRE report"
    );
    assertEq(
        parent.getStrategy().protocolId,
        handler.ghost_rebalancer_event_ReportDecoded_param_protocolId(),
        "Invariant violated: ParentPeer strategy protocolId must match last decoded CRE report"
    );
}
```

This is simpler, has no hidden log-handler flag logic, and since parent's state is updated atomically with `StrategyUpdated` in the same transaction, matching the last decoded report confirms event/state consistency. The flag is dropped entirely.

**New invariants** (promoting Handler assertions):

```solidity
invariant_depositInitiated_emittedOnEveryDeposit()
    // ghost_yieldPeer_event_DepositInitiated_emissions == total deposit count

invariant_feeTaken_emittedWhenFeeRateNonZero()
    // when ghost_feeRate > 0:
    // ghost_yieldFees_event_FeeTaken_emissions == ghost_yieldPeer_event_DepositInitiated_emissions

invariant_computedFees_matchEventFees()
    // ghost_yieldFees_event_FeeTaken_param_amount_totalSum ==
    // calculateTotalExpectedFeesFromDepositRecords()
    // cross-checks event-derived fees against independently computed fees
```

---

## Bug Fixes (before anything else)

1. `Events.sol`: `bytes eventSignature` → `bytes32 eventSignature`
2. `Events.sol`: add `import {Vm} from "forge-std/Vm.sol";`
3. `Events.sol`: add `import {IYieldPeer} from "../../src/interfaces/IYieldPeer.sol";`
4. `Ghosts.sol`: add `import {IYieldPeer} from "../../src/interfaces/IYieldPeer.sol";`
5. `Handler.t.sol`: fix `ghost_event_withdrawFromStrategy_emissions` → `ghost_yieldPeer_event_WithdrawFromStrategy_emissions`

---

## Implementation Order

Each step should compile and all tests should pass before moving to the next.

1. **Complete `Ghosts.sol`** — add SYSTEM AGGREGATE section (with sub-sections and NatSpec), add STRATEGY ADAPTER, YIELDFEES, CRE RECEIVER sections. Preserve all existing NatSpec from Handler.
2. **Fix and complete `Events.sol`** — fix bugs, add missing log handlers and event signatures.
3. **Refactor `Handler.t.sol`** — remove inline declarations, replace per-action log handlers with `_handleLogs()` + state update helpers.
4. **Migrate `Invariant.t.sol`** — update all ghost name references, fix broken references, drop flag, add new invariants, consolidate CRE invariants.

---

## Future: `Actors.sol`

Internal user actor helpers (`_seedToAddress`, `_createOrGetUser`, `_indexToUser`) and the `users` EnumerableSet can migrate here. `forEachUser` and `forEachChainSelector` must remain on Handler as they are called externally by `Invariant.t.sol`.

---

A few things worth flagging before you review it:
                                                                                                                                      
  1. One unresolved rough edge in the plan — the STRATEGY ADAPTER STATE section (section 8) got a bit muddled. I started writing
  ghost_strategyAdapter_state_balanceAfter_lastWithdraw but then caught myself mid-thought. The                                       
  ghost_strategyAdapter_balanceAfter_rebalanceWithdraw in the SYSTEM AGGREGATE section is what the invariant actually needs (the
  balance after a MAX sentinel withdrawal during rebalancing). The per-contract adapter state section may end up with additional
  ghosts as we flesh out the adapter invariants, but for now you might find section 8 slightly unclear — worth a read.
  2. The documented dependency pattern — where state update helpers intentionally read event ghosts set by _handleLogs() — appears
  three times (totalSharesMintedPerUser, totalUsdcWithdrawnPerUser, strategyAdapter_balanceAfter_rebalanceWithdraw). The comments make
   the ordering contract explicit, but if you feel this coupling is too implicit, one alternative is to have the action functions
  extract those values explicitly and pass them as parameters to the state helpers. Happy to discuss that if it bothers you.
  3. The ghost_flag_decodedStrategy_mismatchWithEmittedStrategy drop — the reasoning is in the plan. Let me know if you want to keep
  the flag after all.