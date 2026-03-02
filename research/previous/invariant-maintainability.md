# Invariant.t.sol — Readability & Maintainability Plan

## Goals

- Group all invariants into logical sections with banner headers
- Place each `check*` helper immediately after its corresponding `invariant_*` function
- Rename all invariants (and their helpers) to a consistent pattern
- Consolidate redundant emission-count invariants
- Remove `invariant_feeRate_matchesGhost` (flagged superfluous)
- Address relevant `// @review` comments in `Invariant.t.sol`
- Keep everything in one file; do not touch `Ghosts.t.sol`, `Events.t.sol`, or `Handler.t.sol`

---

## Naming Convention

### Invariant functions

```
invariant_{group}_{EventA/Subject}_{property/relationship}
```

- `{group}` — one of: `system`, `deposit`, `withdraw`, `shares`, `fees`, `strategy`, `rebalance`, `crosschain`
- `{EventA/Subject}` — the event name(s) or state concept being checked (camelCase, matching the actual event name)
- `{property/relationship}` — what property is asserted (e.g. `emissionConsistency`, `equalsUserPrincipal`, `withinBounds`)

When an invariant checks a pair or group of events for emission consistency, all event names are included:
```
invariant_deposit_DepositInitiated_ShareMintUpdate_SharesMinted_emissionConsistency
```

### Check helper functions

```
check{Description}Per{Entity}
```

Where `{Entity}` is `User` or `ChainSelector`.

---

## Ordering Within Groups

Priority: **A → B → C**

1. **Lifecycle (A)** — follow the sequence events occur in the protocol
2. **Simple → Complex (B)** — emission count checks before amount flow before state integrity
3. **Event → State (C)** — event-consistency checks before state-integrity checks

In practice this means within each group:
1. Emission count checks (simple; event-level)
2. Amount flow / param checks (medium; cross-event)
3. State integrity checks (most complex; often `forEachUser`)

---

## Section Structure

```
VARIABLES       (unchanged)
SETUP           (unchanged)
INVARIANTS
  ├── SYSTEM
  ├── DEPOSIT
  ├── WITHDRAW
  ├── SHARES
  ├── FEES
  ├── STRATEGY
  ├── REBALANCE
  └── CROSSCHAIN
UTILITY         (unchanged)
```

---

## Complete Invariant Mapping

### Before → After summary (31 → 27)

| Old name | New name | Change |
|---|---|---|
| `invariant_stablecoinRedemptionIntegrity` | `invariant_system_stablecoinRedemption_perUser_integrity` | Move to SYSTEM |
| `invariant_totalValue_integrity` | `invariant_system_totalValue_exceedsNetDeposits` | Move to SYSTEM |
| `invariant_depositInitiated_shareMintUpdate_consistency` + `invariant_sharesMinted_emissions_matchDeposits` | `invariant_deposit_DepositInitiated_ShareMintUpdate_SharesMinted_emissionConsistency` | **Consolidated** |
| `invariant_depositInitiated_amount_equals_userPrincipal` | `invariant_deposit_DepositInitiated_amount_equalsUserPrincipal` | Rename |
| `invariant_strategyAdapter_deposit_matchesPeerEmission` | `invariant_deposit_DepositToStrategy_amount_matchesStrategyAdapterDeposit` | Rename |
| `invariant_withdrawCompleted_shareBurnUpdate_consistency` + `invariant_sharesBurned_emissions_matchWithdrawals` | `invariant_withdraw_WithdrawInitiated_SharesBurned_WithdrawCompleted_ShareBurnUpdate_emissionConsistency` | **Consolidated** |
| `invariant_withdrawInitiated_matchesSharesBurned` + `invariant_sharesBurned_matchesGhost` | `invariant_withdraw_WithdrawInitiated_SharesBurned_amount_equalsGhostSharesBurned` | **Consolidated** |
| `invariant_totalShares_integrity` | `invariant_shares_totalShares_equalsMintedMinusBurned` | Rename |
| `invariant_totalShareBalances_integrity` | `invariant_shares_totalShares_equalsSumOfHolderBalances` | Rename |
| `invariant_shareBalance_perUser_integrity` | `invariant_shares_ShareBalance_perUser_equalsMintedMinusBurned` | Rename |
| `invariant_feeRate_bounds` | `invariant_fees_FeeRate_withinBounds` | Rename |
| `invariant_feeRate_consistentAcrossChains` | `invariant_fees_FeeRate_consistentAcrossChains` | Rename |
| `invariant_feeRate_matchesGhost` | *(removed)* | **Removed** |
| `invariant_fee_integrity_perUser` | `invariant_fees_FeeTaken_amount_perUser_equalsSumOfDepositFees` | Rename |
| `invariant_totalFees_equals_sumOfDepositFees` | `invariant_fees_FeeTaken_amount_equalsSumOfDepositFees` | Rename |
| `invariant_fees_consistency` | `invariant_fees_FeeTaken_FeesWithdrawn_balanceConsistency` | Rename (keep `// @review`) |
| `invariant_feesWithdrawn_matchesGhost` | `invariant_fees_FeesWithdrawn_amount_matchesGhost` | Rename |
| `invariant_feeWithdrawal_onlyOwner` | `invariant_fees_FeesWithdrawn_onlyFeeWithdrawer` | Rename |
| `invariant_activeProtocol_registered` | `invariant_strategy_activeProtocol_registeredInStrategyRegistry` | Rename |
| `invariant_adapterMatchesRegistryOnActiveChain` | `invariant_strategy_activeAdapter_matchesStrategyRegistry` | Rename |
| `invariant_activeStrategyAdapter_consistency` | `invariant_strategy_ActiveStrategyAdapterUpdated_consistencyPerChain` | Rename |
| `invariant_rebalance_eventConsistency` | `invariant_rebalance_WithdrawFromStrategy_OnReportSecurityChecksPassed_StrategyUpdated_emissionConsistency` | Rename |
| `invariant_decodedCREReportStrategy_matchesParentStrategy` | `invariant_rebalance_ReportDecoded_matchesParentStrategy` | Rename |
| `invariant_strategyUpdated_matchesDecodedReport` | `invariant_rebalance_StrategyUpdated_matchesReportDecoded` | Rename |
| `invariant_strategyAdapter_rebalance_withdrawsTotalValue` | `invariant_rebalance_WithdrawFromStrategy_drainsTotalValue` | Rename |
| `invariant_ccip_sentEqualsReceived` | `invariant_crosschain_CCIPMessageSent_CCIPMessageReceived_emissionConsistency` | Rename |
| `invariant_depositPingPong_alwaysCompletes` | `invariant_crosschain_depositPingPong_alwaysCompletes` | Rename |
| `invariant_withdrawPingPong_alwaysCompletes` | `invariant_crosschain_withdrawPingPong_alwaysCompletes` | Rename |

---

## Check Helper Renames

| Old name | New name |
|---|---|
| `checkRedemptionIntegrityPerUser` | `checkStablecoinRedemptionPerUser` |
| `checkTotalDepositsAgainstTotalValuePerChainSelector` | `checkTotalValueExceedsNetDepositsPerChainSelector` |
| `checkShareBalanceIntegrityPerUser` | `checkShareBalanceIntegrityPerUser` *(unchanged — already clear)* |
| `checkActiveStrategyAdapterPerChainSelector` | `checkActiveStrategyAdapterConsistencyPerChainSelector` |
| `checkFeeRateBoundsPerChainSelector` | `checkFeeRateWithinBoundsPerChainSelector` |
| `checkFeeRateConsistencyPerChainSelector` | `checkFeeRateConsistencyPerChainSelector` *(unchanged)* |
| `checkFeeIntegrityPerUser` | `checkFeeAmountIntegrityPerUser` |

---

## Detailed Group Breakdown

### SYSTEM
The two highest-level protocol solvency properties. These sit at the top, above all groups, to signal their importance.

```
1. invariant_system_stablecoinRedemption_perUser_integrity   [per-user, forEachUser]
     checkStablecoinRedemptionPerUser

2. invariant_system_totalValue_exceedsNetDeposits            [per-chain, forEachChainSelector]
     checkTotalValueExceedsNetDepositsPerChainSelector
```

---

### DEPOSIT
Ordered: emission count → amount flow (no per-user state integrity in this group; that lives in SHARES).

```
1. invariant_deposit_DepositInitiated_ShareMintUpdate_SharesMinted_emissionConsistency
   // CONSOLIDATED: was invariant_depositInitiated_shareMintUpdate_consistency
   //             + invariant_sharesMinted_emissions_matchDeposits
   // Asserts: DepositInitiated_emissions == ShareMintUpdate_emissions
   //          DepositInitiated_emissions == SharesMinted_emissions

2. invariant_deposit_DepositInitiated_amount_equalsUserPrincipal
   // Amount flow: total DepositInitiated amounts == ghost_totalUsdcDeposited_userPrincipal

3. invariant_deposit_DepositToStrategy_amount_matchesStrategyAdapterDeposit
   // Amount flow: total DepositToStrategy amounts == total StrategyAdapter Deposit amounts
```

---

### WITHDRAW
Ordered: emission count → amount flow.

```
1. invariant_withdraw_WithdrawInitiated_SharesBurned_WithdrawCompleted_ShareBurnUpdate_emissionConsistency
   // CONSOLIDATED: was invariant_sharesBurned_emissions_matchWithdrawals
   //             + invariant_withdrawCompleted_shareBurnUpdate_consistency
   // Asserts: WithdrawInitiated_emissions == SharesBurned_emissions
   //          WithdrawCompleted_emissions == ShareBurnUpdate_emissions

2. invariant_withdraw_WithdrawInitiated_SharesBurned_amount_equalsGhostSharesBurned
   // CONSOLIDATED: was invariant_withdrawInitiated_matchesSharesBurned
   //             + invariant_sharesBurned_matchesGhost
   // Asserts: WithdrawInitiated_amount_totalSum == ghost_totalSharesBurned
   //          SharesBurned_amount_totalSum      == ghost_totalSharesBurned
```

---

### SHARES
Ordered: total state integrity (simple) → per-user state integrity (complex, forEachUser).

```
1. invariant_shares_totalShares_equalsMintedMinusBurned
   // State: parent.getTotalShares() == totalSharesMinted - totalSharesBurned

2. invariant_shares_totalShares_equalsSumOfHolderBalances
   // State: parent.getTotalShares() == sum of all holder share balances

3. invariant_shares_ShareBalance_perUser_equalsMintedMinusBurned   [per-user, forEachUser]
     checkShareBalanceIntegrityPerUser
```

---

### FEES
Ordered: rate configuration → deposit-time fee amounts → withdrawal consistency → access control.

```
1. invariant_fees_FeeRate_withinBounds                             [per-chain, forEachChainSelector]
     checkFeeRateWithinBoundsPerChainSelector

2. invariant_fees_FeeRate_consistentAcrossChains                   [per-chain, forEachChainSelector]
     checkFeeRateConsistencyPerChainSelector

3. invariant_fees_FeeTaken_amount_perUser_equalsSumOfDepositFees   [per-user, forEachUser]
     checkFeeAmountIntegrityPerUser

4. invariant_fees_FeeTaken_amount_equalsSumOfDepositFees

5. invariant_fees_FeeTaken_FeesWithdrawn_balanceConsistency
   // @review comment retained — fees architecture under redesign

6. invariant_fees_FeesWithdrawn_amount_matchesGhost

7. invariant_fees_FeesWithdrawn_onlyFeeWithdrawer
   // Access control flag — simplest assertion, last in group
```

**Removed:** `invariant_feeRate_matchesGhost` — superfluous meta-check on ghost bookkeeping, not a protocol invariant.

---

### STRATEGY
Ordered: protocol registered (prerequisite) → adapter matches registry → per-chain consistency (most complex).

```
1. invariant_strategy_activeProtocol_registeredInStrategyRegistry

2. invariant_strategy_activeAdapter_matchesStrategyRegistry

3. invariant_strategy_ActiveStrategyAdapterUpdated_consistencyPerChain   [per-chain, forEachChainSelector]
     checkActiveStrategyAdapterConsistencyPerChainSelector
```

---

### REBALANCE
Ordered: emission count → CRE report state match → StrategyUpdated param match → drain state change.

```
1. invariant_rebalance_WithdrawFromStrategy_OnReportSecurityChecksPassed_StrategyUpdated_emissionConsistency
   // Asserts: ghost_rebalances == WithdrawFromStrategy_rebalance_emissions
   //          ghost_rebalances == OnReportSecurityChecksPassed_emissions
   //          ghost_rebalances == StrategyUpdated_emissions

2. invariant_rebalance_ReportDecoded_matchesParentStrategy
   // ReportDecoded params match ParentPeer.getStrategy() state

3. invariant_rebalance_StrategyUpdated_matchesReportDecoded
   // StrategyUpdated event params match ReportDecoded event params

4. invariant_rebalance_WithdrawFromStrategy_drainsTotalValue
   // After MAX sentinel rebalance withdrawal, old adapter getTotalValue() < 1e6
```

---

### CROSSCHAIN
Ordered: CCIP message parity → ping-pong completion (deposit then withdraw).

```
1. invariant_crosschain_CCIPMessageSent_CCIPMessageReceived_emissionConsistency
   // CCIPMessageSent_emissions == CCIPMessageReceived_emissions

2. invariant_crosschain_depositPingPong_alwaysCompletes
   // ghost_depositPingPong_calls == ghost_depositPingPong_completions

3. invariant_crosschain_withdrawPingPong_alwaysCompletes
   // ghost_withdrawPingPong_calls == ghost_withdrawPingPong_completions
```

---

## `// @review` Comments to Address

| Location | Comment | Action |
|---|---|---|
| `invariant_fees_consistency` | `// @review instead of using .balanceOf...` | Leave — fees architecture under redesign |
| `invariant_activeProtocol_registered` | `// @review:certora` | Ignore — Certora comment, out of scope |
| `invariant_adapterMatchesRegistryOnActiveChain` | `// @review:certora` | Ignore — Certora comment, out of scope |
| `invariant_feeRate_matchesGhost` | `// @review probably superfluous` | Moot — invariant is removed |

---

## Drop Verification (31 → 27)

| # | Original | New location |
|---|---|---|
|1|`invariant_activeStrategyAdapter_consistency`|STRATEGY #3|
|2|`invariant_totalShares_integrity`|SHARES #1|
|3|`invariant_totalValue_integrity`|SYSTEM #2|
|4|`invariant_totalShareBalances_integrity`|SHARES #2|
|5|`invariant_withdrawCompleted_shareBurnUpdate_consistency`|consolidated → WITHDRAW #1|
|6|`invariant_depositInitiated_shareMintUpdate_consistency`|consolidated → DEPOSIT #1|
|7|`invariant_stablecoinRedemptionIntegrity`|SYSTEM #1|
|8|`invariant_fees_consistency`|FEES #5|
|9|`invariant_feeRate_bounds`|FEES #1|
|10|`invariant_fee_integrity_perUser`|FEES #3|
|11|`invariant_totalFees_equals_sumOfDepositFees`|FEES #4|
|12|`invariant_feeWithdrawal_onlyOwner`|FEES #7|
|13|`invariant_activeProtocol_registered`|STRATEGY #1|
|14|`invariant_adapterMatchesRegistryOnActiveChain`|STRATEGY #2|
|15|`invariant_decodedCREReportStrategy_matchesParentStrategy`|REBALANCE #2|
|16|`invariant_strategyAdapter_rebalance_withdrawsTotalValue`|REBALANCE #4|
|17|`invariant_rebalance_eventConsistency`|REBALANCE #1|
|18|`invariant_depositInitiated_amount_equals_userPrincipal`|DEPOSIT #2|
|19|`invariant_strategyAdapter_deposit_matchesPeerEmission`|DEPOSIT #3|
|20|`invariant_sharesBurned_matchesGhost`|consolidated → WITHDRAW #2|
|21|`invariant_withdrawInitiated_matchesSharesBurned`|consolidated → WITHDRAW #2|
|22|`invariant_feesWithdrawn_matchesGhost`|FEES #6|
|23|`invariant_sharesMinted_emissions_matchDeposits`|consolidated → DEPOSIT #1|
|24|`invariant_sharesBurned_emissions_matchWithdrawals`|consolidated → WITHDRAW #1|
|25|`invariant_ccip_sentEqualsReceived`|CROSSCHAIN #1|
|26|`invariant_strategyUpdated_matchesDecodedReport`|REBALANCE #3|
|27|`invariant_feeRate_consistentAcrossChains`|FEES #2|
|28|`invariant_feeRate_matchesGhost`|**REMOVED**|
|29|`invariant_shareBalance_perUser_integrity`|SHARES #3|
|30|`invariant_depositPingPong_alwaysCompletes`|CROSSCHAIN #2|
|31|`invariant_withdrawPingPong_alwaysCompletes`|CROSSCHAIN #3|

31 − 1 (removed) − 3 (consolidations) = **27**

---

## Implementation Steps

1. Delete `invariant_feeRate_matchesGhost` and its `// @review` comment
2. Replace the single `INVARIANTS` banner with eight sub-section banners: SYSTEM, DEPOSIT, WITHDRAW, SHARES, FEES, STRATEGY, REBALANCE, CROSSCHAIN
3. For each section: reorder, rename invariants and helpers per the mapping above, move each `check*` helper to immediately follow its `invariant_*`
4. Perform the three consolidations:
   - Deposit emission count (2 → 1)
   - Withdraw emission count (2 → 1)
   - Withdraw amount flow (2 → 1)
5. Verify no invariant or helper has been accidentally dropped (31 → 27)
