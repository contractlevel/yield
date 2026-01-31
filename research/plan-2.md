# Modular Stablecoin Support - Implementation Plan

## Summary

Move from USDC-only to multi-stablecoin (USDC, USDT, GHO, etc.) support. All stablecoin decimals supported.

**Core principle:** Share math uses "system decimals" (6, matching USDC). Strategy adapters operate in native decimals. Swaps and normalization happen at boundaries. CCIP always bridges USDC.

**User decisions:**
- Support ALL decimals (6-dec USDC/USDT, 18-dec GHO, etc.)
- Withdrawals always return USDC for now (`@review` for future user-choice)
- Keep separate state vars (`s_activeStrategyAdapter` + `s_activeStablecoinId`)

---

## Changes by File

### 1. `src/peers/YieldPeer.sol` — Foundation changes

**a) Rename constant + add imports, constants, errors, helpers:**
- Rename `USDC_DECIMALS = 1e6` → `USDC_SCALING_FACTOR = 1e6` (update 3 usages in YieldPeer + 1 natspec in ParentPeer)
- Add `uint8 internal constant USDC_DECIMALS = 6`
- Import `IERC20Metadata` from OpenZeppelin (needed: `IERC20` does not include `decimals()`)
- Add error `YieldPeer__StablecoinNotSupported(bytes32 stablecoinId)`
- Add `_normalizeToUsdcDecimals(uint256 amount, uint8 fromDecimals) → uint256` — pure, scales to 6 dec
- Add `_denormalizeFromUsdcDecimals(uint256 amount, uint8 toDecimals) → uint256` — pure, scales from 6 dec
- Add `_getActiveStablecoinAddress() → address` — view, resolves `s_activeStablecoinId` via registry

**b) Update `_depositToStrategy(adapter, amount)` → `_depositToStrategy(adapter, asset, amount)`:**
- Replace `_transferUsdcTo(strategyAdapter, amount)` with `IERC20(asset).safeTransfer(strategyAdapter, amount)`
- Replace `IStrategyAdapter(...).deposit(address(i_usdc), amount)` with `.deposit(asset, amount)`

**c) Update `_withdrawFromStrategy(adapter, amount)` → `_withdrawFromStrategy(adapter, asset, amount)`:**
- Replace `IStrategyAdapter(...).withdraw(address(i_usdc), amount)` with `.withdraw(asset, amount)`

**d) Update `_depositToStrategyAndGetTotalValue` → add `address asset` param:**
- Use `asset` for `_getTotalValueFromStrategy` and `_depositToStrategy`
- Normalize returned totalValue: `_normalizeToUsdcDecimals(rawTotal, IERC20Metadata(asset).decimals())`

**e) Update `_withdrawFromStrategyAndGetUsdcWithdrawAmount` — now handles normalization + swap:**
- Get raw totalValue in native decimals, normalize for share math
- Call `_calculateWithdrawAmount` with normalized values (returns 6-dec result)
- Denormalize result back to native decimals for actual withdrawal
- Withdraw in native decimals via updated `_withdrawFromStrategy`
- If asset != USDC: swap to USDC via `_swapStablecoins`; set `withdrawData.usdcWithdrawAmount`

**f) Fix `_swapStablecoins` slippage for cross-decimal swaps:**
- **Current bug:** `amountOutMin = (amountIn * 0.995)` assumes same decimals. Swapping 1000e18 GHO→USDC gives `amountOutMin ≈ 995e18` which is wrong for 6-dec output — would always revert.
- **Fix:** Normalize amountIn to system decimals, denormalize to output decimals, then apply BPS:
  ```
  normalizedIn = _normalizeToUsdcDecimals(amountIn, decimalsIn)
  expectedOut = _denormalizeFromUsdcDecimals(normalizedIn, decimalsOut)
  amountOutMin = expectedOut * (BPS_DENOMINATOR - MAX_SLIPPAGE_BPS) / BPS_DENOMINATOR
  ```

**g) Fix `_initiateDeposit`:**
- Resolve stablecoin address first, then check minimum: `amount < 10 ** IERC20Metadata(stablecoin).decimals()`
- Replace misleading error: `YieldPeer__StablecoinNotSupported(stablecoinId)` instead of `YieldPeer__ChainNotAllowed(0)`

**h) Fix `_getTotalValue()`:**
- Use `_getActiveStablecoinAddress()` instead of `address(i_usdc)`
- Normalize return value to system decimals

**i) Fix `_handleCCIPRebalanceNewStrategy`:**
- Pass correct stablecoin to updated `_depositToStrategy(adapter, targetStablecoin, amount)`

---

### 2. `src/peers/ParentPeer.sol` — System-wide stablecoin support + flow fixes

**a) Add `s_supportedStablecoins`:**
- `mapping(bytes32 => bool) internal s_supportedStablecoins`
- `setSupportedStablecoin(bytes32, bool)` with `CONFIG_ADMIN_ROLE`
- `getSupportedStablecoin(bytes32) → bool` getter
- `SupportedStablecoinSet` event
- `ParentPeer__StablecoinNotSupported` error
- Add stablecoin check to `_revertIfStrategyIsNotSupported()`

**b) Fix `deposit()`:**
- **Local strategy:** swap deposited stablecoin → strategy stablecoin (if different), normalize for share math, deposit in native decimals
- **Remote strategy:** swap deposited stablecoin → USDC (if different), bridge USDC
- Remove the current unconditional swap-to-USDC block (lines 94-98)

**c) Fix `onTokenTransfer()`:**
- When parent is strategy: withdraw in strategy stablecoin (native decimals), normalize for share math, denormalize for withdrawal, swap to USDC if needed
- Add `@review currently only supporting withdrawing in USDC`

**d) Fix `_handleCCIPDepositToParent()`:**
- When parent is strategy: swap bridged USDC → strategy stablecoin if needed, normalize totalValue for share math, deposit in native decimals

**e) Fix `_handleCCIPWithdraw()`:**
- Use updated `_withdrawFromStrategyAndGetUsdcWithdrawAmount` (which now handles normalization + swap internally)

**f) Fix rebalance methods:**
- `_rebalanceParentToParent`: pass `oldStablecoin`/`newStablecoin` to updated `_withdrawFromStrategy`/`_depositToStrategy`
- `_rebalanceParentToChild`: same pattern

---

### 3. `src/peers/ChildPeer.sol` — Flow fixes

**a) Fix `deposit()`:**
- **Local strategy (child is strategy):** swap to strategy stablecoin if different, normalize amount for `_buildDepositData`, deposit in native decimals
- **Remote (not strategy):** swap to USDC if different, bridge
- Remove the current unconditional swap-to-USDC block (lines 60-65)

**b) Fix `_handleCCIPDepositToStrategy()`:**
- Swap bridged USDC → strategy stablecoin if needed
- Pass correct asset to `_depositToStrategyAndGetTotalValue`
- `depositData.totalValue` is now normalized (returned by updated helper)
- `depositData.amount` stays in system decimals (it was USDC from CCIP)

**c) Fix `_handleCCIPWithdrawToStrategy()`:**
- Use updated `_withdrawFromStrategyAndGetUsdcWithdrawAmount` with active stablecoin

**d) Fix `_handleCCIPRebalanceOldStrategy()`:**
- Pass asset to updated `_withdrawFromStrategy`/`_depositToStrategy`

**e) Add `@review currently only supporting withdrawing in USDC` to `onTokenTransfer`**

---

### 4. Tests

**Update `BaseTest.t.sol`:**
- Call `parentPeer.setSupportedStablecoin(USDC_ID, true)` in setup
- Update strategy setup helpers to include `stablecoinId`

**All existing tests should pass unchanged** because normalization for 6-dec tokens is a no-op.

**New test scenarios** (follow naming: `test_yield_CONTRACT_FUNCTION_ACTION_CONDITION`):
1. Deposit non-USDC stablecoin, local strategy same stablecoin — no swap
2. Deposit USDC, local strategy uses GHO (18-dec) — swap + normalization
3. Deposit non-USDC, remote strategy — swap to USDC for bridge
4. Withdrawal from 18-dec strategy — normalize, denormalize, swap to USDC
5. Rebalance between different stablecoins (same chain, cross-chain)
6. Revert: deposit unsupported stablecoin
7. Revert: rebalance to unsupported stablecoin

---

## Implementation Order

| # | File | What |
|---|------|------|
| 1 | YieldPeer.sol | Normalization helpers, error, constant, `_getActiveStablecoinAddress` |
| 2 | YieldPeer.sol | Update `_depositToStrategy`, `_withdrawFromStrategy` signatures |
| 3 | YieldPeer.sol | Update composite helpers + `_swapStablecoins` slippage + `_initiateDeposit` + `_getTotalValue` |
| 4 | ParentPeer.sol | Add `s_supportedStablecoins` + validation |
| 5 | ParentPeer.sol | Fix `deposit()`, `onTokenTransfer()`, CCIP handlers, rebalance methods |
| 6 | ChildPeer.sol | Fix `deposit()`, CCIP handlers, rebalance handler |
| 7 | Tests | Update base setup, add multi-stablecoin test scenarios |

---

## Verification

```bash
forge clean && forge build          # compilation
forge test --mt test_yield          # all unit tests
forge test --mt invariant           # invariant tests
slither . --filter-path lib         # static analysis
```

Then: review all `@review:stablecoins` comments, remove resolved ones.
