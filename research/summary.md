# Modular Stablecoin Support — Implementation Summary

## What Was Done

### 1. `src/peers/YieldPeer.sol` — Foundation (COMPLETE)
- Added `IERC20Metadata` import
- Added `YieldPeer__StablecoinNotSupported(bytes32)` error
- Changed `s_activeStablecoinId` (bytes32) → `s_activeStablecoin` (address) — avoids double storage read
- Renamed `_updateActiveStablecoinId` → `_updateActiveStablecoin` — resolves address from registry
- Renamed `_getActiveStablecoinId` → `_getActiveStablecoin` — returns address directly
- Changed virtual `deposit(uint256)` → `deposit(bytes32 stablecoinId, uint256 amount)` to match interface
- Updated `_initiateDeposit` to accept `(bytes32 stablecoinId, uint256 amount)`, return `(uint256 amountMinusFee, address stablecoin)`, validate via registry
- Updated `_depositToStrategy(adapter, amount)` → `_depositToStrategy(adapter, asset, amount)` — uses `IERC20(asset).safeTransfer` and `IStrategyAdapter.deposit(asset, amount)`
- Updated `_withdrawFromStrategy(adapter, amount)` → `_withdrawFromStrategy(adapter, asset, amount)`
- Updated `_depositToStrategyAndGetTotalValue` to accept `address asset`, normalize returned totalValue to system decimals (6 dec)
- Updated `_withdrawFromStrategyAndGetUsdcWithdrawAmount` to accept `address asset`, handle normalization/denormalization, swap to USDC if needed
- Fixed `_swapStablecoins` slippage for cross-decimal swaps (normalize to system decimals, denormalize to output decimals, then apply BPS)
- Fixed `_getTotalValue()` to use `s_activeStablecoin` and normalize return value
- Fixed `_handleCCIPRebalanceNewStrategy` to pass correct stablecoin to `_depositToStrategy`
- Added `_normalizeToUsdcDecimals(uint256, uint8)` and `_denormalizeFromUsdcDecimals(uint256, uint8)` pure helpers
- Added `getActiveStablecoin()` public getter (matching existing `getActiveStrategyAdapter()` pattern)

### 2. `src/peers/ParentPeer.sol` — System-wide support (COMPLETE)
- Added `IERC20Metadata` import
- Added `s_supportedStablecoins` mapping, `ParentPeer__StablecoinNotSupported` error, `SupportedStablecoinSet` event
- Added `setSupportedStablecoin(bytes32, bool)` setter (CONFIG_ADMIN_ROLE)
- Added `getSupportedStablecoin(bytes32)` getter
- Updated `_revertIfStrategyIsNotSupported` to check `s_supportedStablecoins`
- Fixed `deposit()`: local strategy swaps to strategy stablecoin + normalizes for share math; remote strategy swaps to USDC for bridge
- Fixed `onTokenTransfer()`: local strategy normalizes, denormalizes, swaps to USDC for withdrawal
- Fixed `_handleCCIPDepositToParent()`: swaps bridged USDC to strategy stablecoin if needed, normalizes totalValue
- Fixed `_handleCCIPWithdraw()`: passes `s_activeStablecoin` to updated helper
- Fixed `_rebalanceParentToParent`: passes asset to withdraw/deposit helpers
- Fixed `_rebalanceParentToChild`: passes asset to withdraw helper
- Updated `setInitialActiveStrategy` to use `_updateActiveStablecoin`

### 3. `src/peers/ChildPeer.sol` — Flow fixes (COMPLETE)
- Added `IERC20Metadata` import
- Fixed `deposit()`: local strategy swaps to strategy stablecoin + normalizes; remote swaps to USDC for bridge
- Fixed `_handleCCIPDepositToStrategy()`: swaps bridged USDC to strategy stablecoin if needed
- Fixed `_handleCCIPWithdrawToStrategy()`: passes `s_activeStablecoin`
- Fixed `_handleCCIPRebalanceOldStrategy()`: changed param from `bytes32 oldStablecoinId` to `address oldStablecoin`, passes asset to helpers
- Updated `_handleCCIPMessage` call site: passes `_getActiveStablecoin()` instead of `_getActiveStablecoinId()`
- Added `@review currently only supporting withdrawing in USDC` comments

### 4. `src/interfaces/IYieldPeer.sol`
- Added `getActiveStablecoin()` to interface

### 5. `certora/harness/YieldHarness.sol`
- Updated `deposit`, `depositToStrategy`, `withdrawFromStrategy` signatures to match new source

### 6. `script/deploy/DeployParent.s.sol`
- Added `setSupportedStablecoin(USDC_ID, true)` call

### 7. Test Updates (PARTIAL — see remaining work)
- Added `_setSupportedStablecoins()` to `BaseTest.t.sol::setUp()`
- Added `setSupportedStablecoin(USDC_ID, true)` to `Invariant.t.sol::_deployInfra()`
- Fixed all 5 `stdstore` ping pong adapter writes to also write `getActiveStablecoin()`:
  - `ChildDepositPingPong.t.sol` (1 location)
  - `ChildWithdrawPingPong.t.sol` (1 location)
  - `ParentWithdrawPingPong.t.sol` (2 locations)
  - `ParentDepositPingPong.t.sol` (1 location)

---

## What Remains To Be Done

### Test Verification
- **Run `forge test --mt test_yield`** — 185/186 were passing before the last stdstore fixes. Need to verify all 186 now pass.
- **Run `forge test --mt invariant`** — invariant tests not yet verified.
- **Run `forge coverage`** — check coverage of new code paths.

### New Test Scenarios (NOT YET WRITTEN)
Per the plan, these new tests should be added (follow naming: `test_yield_CONTRACT_FUNCTION_ACTION_CONDITION`):

1. **Deposit non-USDC stablecoin, local strategy same stablecoin** — no swap needed
2. **Deposit USDC, local strategy uses GHO (18-dec)** — swap + normalization
3. **Deposit non-USDC, remote strategy** — swap to USDC for bridge
4. **Withdrawal from 18-dec strategy** — normalize, denormalize, swap to USDC
5. **Rebalance between different stablecoins** (same chain, cross-chain)
6. **Revert: deposit unsupported stablecoin**
7. **Revert: rebalance to unsupported stablecoin**

These tests will need:
- A mock 18-decimal stablecoin (e.g., MockGHO)
- A mock swapper that handles cross-decimal swaps
- StablecoinRegistry entries for the mock stablecoin
- `setSupportedStablecoin` for the mock stablecoin on ParentPeer

### Constants Update (FROM CLAUDE.md — NOT YET DONE)
The CLAUDE.md mentions renaming constants:
```
USDC_DECIMALS = 1e6  →  USDC_SCALING_FACTOR = 1e6
SHARE_DECIMALS = 1e18  →  SHARE_SCALING_FACTOR = 1e18
+ uint8 USDC_DECIMALS = 6
+ uint8 SHARE_DECIMALS = 18
```

I added `uint8 USDC_DECIMALS = 6` which is used by the normalization helpers. However, the rename of `USDC_DECIMALS` (1e6) → `USDC_SCALING_FACTOR` and `SHARE_DECIMALS` (1e18) → `SHARE_SCALING_FACTOR` has **NOT** been done yet. This is a separate rename that affects ~4 usages in YieldPeer and 1 natspec in ParentPeer.

**Update**: actually, looking at the code again, I see that the old `USDC_DECIMALS = 1e6` has already been defined separately as a constant. Since I added `uint8 USDC_DECIMALS = 6` for the normalization helpers, there may be a naming conflict with the old `USDC_DECIMALS = 1e6`. **Check if there's a conflict and do the rename to `USDC_SCALING_FACTOR`/`SHARE_SCALING_FACTOR`.**

### Review Items
- Search for all `@review` comments and resolve them
- Verify slither output: `slither . --filter-path lib`
