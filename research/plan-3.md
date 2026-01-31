# Plan 3: Sync ParentPeer and ChildPeer with Updated YieldPeer

## Overview

After auditing all stablecoin and decimal handling, here are the changes needed plus comprehensive documentation.

---

## Decimal Handling Documentation

### The Two Decimal Contexts

1. **Native Decimals**: The token's actual decimals (e.g., USDC=6, DAI=18)
2. **System Decimals**: USDC decimals (6) used for share math and CCIP bridging

### When to Use Each

| Context | Use Native Decimals | Use System Decimals (6) |
|---------|--------------------|-----------------------|
| Strategy deposits | ✓ | |
| Strategy withdrawals | ✓ | |
| Strategy getTotalValue | ✓ (returns native) | |
| Swap inputs/outputs | ✓ | |
| Share mint calculation | | ✓ |
| Share withdraw calculation | | ✓ |
| CCIP bridge amounts | | ✓ (USDC is bridged) |

### Function Decimal Contracts

```
LOW-LEVEL FUNCTIONS (no scaling, work in native decimals):

_getTotalValueFromStrategy(adapter, asset)
  └─ Returns: NATIVE decimals of asset

_depositToStrategy(adapter, stablecoin, amount)
  └─ Expects: amount in NATIVE decimals of stablecoin

_withdrawFromStrategy(adapter, stablecoin, amount)
  └─ Expects: amount in NATIVE decimals of stablecoin

_swapStablecoins(tokenIn, tokenOut, amountIn)
  └─ Input:  amountIn in NATIVE decimals of tokenIn
  └─ Output: amountOut in NATIVE decimals of tokenOut


HIGH-LEVEL FUNCTIONS (handle scaling internally):

_depositToStrategyAndGetTotalValue(adapter, stablecoin, amount)
  └─ Input:  amount in NATIVE decimals
  └─ Output: totalValue in SYSTEM decimals (6)
  └─ Purpose: For share calculation after deposit

_withdrawFromStrategyAndGetUsdcWithdrawAmount(adapter, stablecoin, withdrawData)
  └─ Input:  withdrawData.totalShares, withdrawData.shareBurnAmount
  └─ Output: usdcWithdrawAmount in SYSTEM decimals (6)
  └─ Purpose: Complete withdraw flow with swap to USDC
```

---

## YieldPeer Changes

### 1. Add `_getActiveStablecoin()` internal getter

```solidity
/// @notice Helper function to get the active stablecoin
/// @return activeStablecoin The active stablecoin address
function _getActiveStablecoin() internal view returns (address activeStablecoin) {
    activeStablecoin = s_activeStablecoin;
}
```

### 2. Update `_getTotalValueFromStrategy` documentation

```solidity
/// @notice Helper function to get the total value from the strategy
/// @param strategyAdapter The strategy adapter to get the total value from
/// @param asset The asset to get the total value from
/// @return totalValue The total value in NATIVE DECIMALS of the asset (not scaled to system decimals)
function _getTotalValueFromStrategy(address strategyAdapter, address asset)
```

---

## ParentPeer Changes

### 1. Rename scaling functions (5 occurrences)

Replace all `_normalizeToUsdcDecimals` → `_scaleToUsdcDecimals`
Replace all `_denormalizeFromUsdcDecimals` → `_scaleFromUsdcDecimals`

### 2. Replace update calls with `_updateActiveStrategy`

**`_rebalanceParentToParent`:**
```solidity
/// @notice Handles strategy change when both old and new strategies are on this chain
function _rebalanceParentToParent(Strategy memory oldStrategy, Strategy calldata newStrategy) internal {
    address oldActiveStrategyAdapter = _getActiveStrategyAdapter();
    address oldStablecoin = _getStablecoinAddress(oldStrategy.stablecoinId);

    /// @dev update strategy - returns new adapter and stablecoin
    (address newActiveStrategyAdapter, address newStablecoin) = _updateActiveStrategy(newStrategy);

    /// @dev totalValue in NATIVE DECIMALS of oldStablecoin
    uint256 totalValue = _getTotalValueFromStrategy(oldActiveStrategyAdapter, oldStablecoin);
    if (totalValue != 0) {
        /// @dev withdraw in NATIVE DECIMALS
        _withdrawFromStrategy(oldActiveStrategyAdapter, oldStablecoin, totalValue);

        /// @dev swap if stablecoins differ (NATIVE → NATIVE)
        uint256 amountToDeposit = totalValue;
        if (oldStablecoin != newStablecoin) {
            amountToDeposit = _swapStablecoins(oldStablecoin, newStablecoin, totalValue);
        }

        /// @dev deposit in NATIVE DECIMALS of newStablecoin
        _depositToStrategy(newActiveStrategyAdapter, newStablecoin, amountToDeposit);
    }
}
```

**`_rebalanceParentToChild`:**
```solidity
/// @notice Handles strategy change from parent to child chain
function _rebalanceParentToChild(Strategy memory oldStrategy, Strategy memory newStrategy) internal {
    address oldActiveStrategyAdapter = _getActiveStrategyAdapter();
    address oldStablecoin = _getStablecoinAddress(oldStrategy.stablecoinId);

    /// @dev totalValue in NATIVE DECIMALS of oldStablecoin
    uint256 totalValue = _getTotalValueFromStrategy(oldActiveStrategyAdapter, oldStablecoin);

    /// @dev update strategy (sets adapter/stablecoin to address(0) since moving to different chain)
    _updateActiveStrategy(newStrategy);

    if (totalValue != 0) {
        /// @dev withdraw in NATIVE DECIMALS
        _withdrawFromStrategy(oldActiveStrategyAdapter, oldStablecoin, totalValue);

        /// @dev swap to USDC for CCIP bridge if needed
        uint256 bridgeAmount = totalValue;
        if (oldStablecoin != address(i_usdc)) {
            bridgeAmount = _swapStablecoins(oldStablecoin, address(i_usdc), totalValue);
        }

        /// @dev CCIP bridge amount in USDC decimals (6)
        _ccipSend(newStrategy.chainSelector, CcipTxType.RebalanceNewStrategy, abi.encode(newStrategy), bridgeAmount);
    } else {
        _ccipSend(newStrategy.chainSelector, CcipTxType.RebalanceNewStrategy, abi.encode(newStrategy), 0);
    }
}
```

**`setInitialActiveStrategy`:**
```solidity
s_strategy = Strategy({chainSelector: i_thisChainSelector, protocolId: protocolId, stablecoinId: effectiveStablecoinId});
_updateActiveStrategy(s_strategy);
```

### 3. DRY Refactor `onTokenTransfer` (Case 1: Parent is Strategy)

**Current (~17 lines of duplicate logic):**
```solidity
address activeStablecoin = s_activeStablecoin;
uint8 decimals = IERC20Metadata(activeStablecoin).decimals();
uint256 rawTotalValue = _getTotalValueFromStrategy(activeStrategyAdapter, activeStablecoin);
uint256 normalizedTotalValue = _normalizeToUsdcDecimals(rawTotalValue, decimals);

uint256 usdcWithdrawAmount = _calculateWithdrawAmount(normalizedTotalValue, totalShares, shareBurnAmount);

if (usdcWithdrawAmount != 0) {
    uint256 nativeWithdrawAmount = _denormalizeFromUsdcDecimals(usdcWithdrawAmount, decimals);
    _withdrawFromStrategy(activeStrategyAdapter, activeStablecoin, nativeWithdrawAmount);

    if (activeStablecoin != address(i_usdc)) {
        usdcWithdrawAmount = _swapStablecoins(activeStablecoin, address(i_usdc), nativeWithdrawAmount);
    }
}

emit WithdrawCompleted(withdrawer, usdcWithdrawAmount);
if (usdcWithdrawAmount != 0) _transferUsdcTo(withdrawer, usdcWithdrawAmount);
```

**Refactored (5 lines, reuses tested logic from YieldPeer):**
```solidity
/// @dev build withdrawData for the helper function
WithdrawData memory withdrawData;
withdrawData.totalShares = totalShares;
withdrawData.shareBurnAmount = shareBurnAmount;

/// @dev handles: get totalValue, scale, calculate, withdraw, swap to USDC (with USDC optimization)
uint256 usdcWithdrawAmount = _withdrawFromStrategyAndGetUsdcWithdrawAmount(
    activeStrategyAdapter, s_activeStablecoin, withdrawData
);

emit WithdrawCompleted(withdrawer, usdcWithdrawAmount);
if (usdcWithdrawAmount != 0) _transferUsdcTo(withdrawer, usdcWithdrawAmount);
```

**Benefits:**
- Removes ~12 lines of duplicate code
- Uses already-tested function from YieldPeer
- `_withdrawFromStrategyAndGetUsdcWithdrawAmount` already has USDC optimization built-in
- Consistent behavior between local and CCIP withdrawals

### 4. Add USDC Optimization to `deposit` (Case 1: Parent is Strategy)

**Current:**
```solidity
uint8 decimals = IERC20Metadata(activeStablecoin).decimals();
uint256 totalValue =
    _scaleToUsdcDecimals(_getTotalValueFromStrategy(activeStrategyAdapter, activeStablecoin), decimals);
uint256 scaledAmount = _scaleToUsdcDecimals(depositAmount, decimals);
uint256 shareMintAmount = _calculateMintAmount(totalValue, scaledAmount);
```

**With USDC optimization:**
```solidity
uint256 totalValue;
uint256 scaledAmount;

/// @dev skip scaling if strategy uses USDC (already in system decimals)
if (activeStablecoin == address(i_usdc)) {
    totalValue = _getTotalValueFromStrategy(activeStrategyAdapter, activeStablecoin);
    scaledAmount = depositAmount;
} else {
    uint8 decimals = IERC20Metadata(activeStablecoin).decimals();
    totalValue = _scaleToUsdcDecimals(
        _getTotalValueFromStrategy(activeStrategyAdapter, activeStablecoin), decimals
    );
    scaledAmount = _scaleToUsdcDecimals(depositAmount, decimals);
}

uint256 shareMintAmount = _calculateMintAmount(totalValue, scaledAmount);
```

### 5. Add USDC Optimization to `_handleCCIPDepositToParent` (Case 1: Parent is Strategy)

**Current:**
```solidity
uint8 decimals = IERC20Metadata(activeStablecoin).decimals();
depositData.totalValue = _scaleToUsdcDecimals(
    _getTotalValueFromStrategy(activeStrategyAdapter, activeStablecoin), decimals
);
```

**With USDC optimization:**
```solidity
/// @dev skip scaling if strategy uses USDC (already in system decimals)
if (activeStablecoin == address(i_usdc)) {
    depositData.totalValue = _getTotalValueFromStrategy(activeStrategyAdapter, activeStablecoin);
} else {
    uint8 decimals = IERC20Metadata(activeStablecoin).decimals();
    depositData.totalValue = _scaleToUsdcDecimals(
        _getTotalValueFromStrategy(activeStrategyAdapter, activeStablecoin), decimals
    );
}
```

---

## ChildPeer Changes

### 1. Rename scaling function (1 occurrence)

Replace `_normalizeToUsdcDecimals` → `_scaleToUsdcDecimals`

### 2. Add USDC Optimization to `deposit` (Case 1: Child is Strategy)

**Current:**
```solidity
uint8 decimals = IERC20Metadata(activeStablecoin).decimals();
uint256 scaledAmount = _scaleToUsdcDecimals(depositAmount, decimals);

DepositData memory depositData = _buildDepositData(scaledAmount);
depositData.totalValue =
    _depositToStrategyAndGetTotalValue(activeStrategyAdapter, activeStablecoin, depositAmount);
```

**With USDC optimization:**
```solidity
/// @dev scale depositAmount to system decimals for share math
uint256 scaledAmount;
if (activeStablecoin == address(i_usdc)) {
    scaledAmount = depositAmount;
} else {
    scaledAmount = _scaleToUsdcDecimals(depositAmount, IERC20Metadata(activeStablecoin).decimals());
}

DepositData memory depositData = _buildDepositData(scaledAmount);
/// @dev _depositToStrategyAndGetTotalValue already has USDC optimization internally
depositData.totalValue =
    _depositToStrategyAndGetTotalValue(activeStrategyAdapter, activeStablecoin, depositAmount);
```

### 3. Refactor `_handleCCIPRebalanceOldStrategy`

```solidity
/// @notice Handles the CCIP message for a rebalance old strategy
/// @notice The message this function handles is sent by the Parent when the Strategy is updated
/// @dev All amounts are in NATIVE DECIMALS until swapping to USDC for bridge
/// @param data The data to decode - decodes to Strategy (chainSelector, protocolId, stablecoinId)
/// @param oldStablecoin The stablecoin address of the current (old) strategy
function _handleCCIPRebalanceOldStrategy(bytes memory data, address oldStablecoin) internal {
    /// @dev cache the old active strategy adapter BEFORE updating
    address oldActiveStrategyAdapter = _getActiveStrategyAdapter();

    /// @dev totalValue in NATIVE DECIMALS of oldStablecoin
    uint256 totalValue = _getTotalValueFromStrategy(oldActiveStrategyAdapter, oldStablecoin);

    /// @dev withdraw in NATIVE DECIMALS (must happen before _updateActiveStrategy overwrites adapter)
    if (totalValue != 0) _withdrawFromStrategy(oldActiveStrategyAdapter, oldStablecoin, totalValue);

    /// @dev update strategy - sets adapter + stablecoin, or both to address(0) if different chain
    Strategy memory newStrategy = abi.decode(data, (Strategy));
    (address newActiveStrategyAdapter, address newStablecoin) = _updateActiveStrategy(newStrategy);

    /// @dev if new strategy is on this chain, deposit locally (all in NATIVE DECIMALS)
    if (newStrategy.chainSelector == i_thisChainSelector) {
        uint256 amountToDeposit = totalValue;

        /// @dev swap if stablecoins differ: NATIVE(old) → NATIVE(new)
        if (oldStablecoin != newStablecoin && totalValue != 0) {
            amountToDeposit = _swapStablecoins(oldStablecoin, newStablecoin, totalValue);
        }

        /// @dev deposit in NATIVE DECIMALS of newStablecoin
        if (amountToDeposit != 0) _depositToStrategy(newActiveStrategyAdapter, newStablecoin, amountToDeposit);
    }
    /// @dev if new strategy is on different chain, swap to USDC and bridge
    else {
        uint256 bridgeAmount = totalValue;

        /// @dev swap to USDC for CCIP: NATIVE(old) → 6 dec (USDC native = system decimals)
        if (oldStablecoin != address(i_usdc) && totalValue != 0) {
            bridgeAmount = _swapStablecoins(oldStablecoin, address(i_usdc), totalValue);
        }

        /// @dev CCIP bridge amount in USDC decimals (6)
        _ccipSend(newStrategy.chainSelector, CcipTxType.RebalanceNewStrategy, data, bridgeAmount);
    }
}
```

---

## Summary Table

| File | Change | Priority |
|------|--------|----------|
| YieldPeer.sol | Add `_getActiveStablecoin()` getter | Required |
| YieldPeer.sol | Update `_getTotalValueFromStrategy` docs | Recommended |
| ParentPeer.sol | Rename 5 scaling function calls | Required |
| ParentPeer.sol | Replace 3 update calls with `_updateActiveStrategy` | Required |
| ParentPeer.sol | DRY refactor `onTokenTransfer` | Recommended |
| ParentPeer.sol | Add USDC optimization to `deposit` | Recommended |
| ParentPeer.sol | Add USDC optimization to `_handleCCIPDepositToParent` | Recommended |
| ChildPeer.sol | Rename 1 scaling function call | Required |
| ChildPeer.sol | Add USDC optimization to `deposit` | Recommended |
| ChildPeer.sol | Refactor `_handleCCIPRebalanceOldStrategy` | Required |
