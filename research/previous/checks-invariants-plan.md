# Strategy Adapter Invariant Testing Plan

> Branch: `fix/adapter-withdraw-checks`
> Date: 2026-02-14

## Overview

This document outlines a comprehensive plan for adding invariant testing for `AaveV3Adapter` and `CompoundV3Adapter` using the existing `Handler.t.sol` and `Invariant.t.sol` infrastructure. The adapters have two key operations: `deposit` and `withdraw`, with `withdraw` supporting both normal amounts and the MAX sentinel (`type(uint256).max`).

---

## Branch Review Summary

### Key Changes in `fix/adapter-withdraw-checks`

**1. Adapter Withdraw Logic Overhaul**

Both adapters now handle two cases:
- **MAX Sentinel** (`type(uint256).max`): Used during rebalancing to withdraw everything
- **User Withdraw**: Normal amount-specified withdrawals

**2. Key Differences Between Adapters**

| Aspect | AaveV3Adapter | CompoundV3Adapter |
|--------|---------------|-------------------|
| Balance tracking | Uses `aTokenAddress.balanceOf()` | Uses `IComet.balanceOf()` |
| MAX handling | Aave handles MAX internally | Comet handles MAX internally |
| Withdraw method | `IPool.withdraw()` returns amount | Comet doesn't return; need before/after balance diff |
| Anti-borrow check | Not needed (Aave reverts internally) | Added `WithdrawAmountExceedsTotalValue` check |

**3. Peer Changes**

Now passing `type(uint256).max` instead of `totalValue` during rebalancing. The return value from `_withdrawFromStrategy` is now captured and used in:
- `ParentPeer._rebalanceParentToParent`
- `ParentPeer._rebalanceParentToChild`
- `ChildPeer._handleCCIPRebalanceOldStrategy`

**4. Existing Invariant**

`invariant_strategyAdapter_maxSentinel_withdrawsAllProtocolBalance` - verifies adapter balance is 0 (or <1e6 dust) after MAX withdrawal.

---

## Invariants to Test

### Priority 1: Core Safety Invariants

| # | Invariant | Description | Risk if Violated |
|---|-----------|-------------|------------------|
| 1 | **MAX Withdrawal Drains Balance** | After `withdraw(type(uint256).max)`, `getTotalValue() == 0` (or < dust) | Funds stuck in protocol |
| 2 | **No Compound Borrowing** | `withdraw(amount)` where `amount > getTotalValue()` must revert | Adapter enters debt position |
| 3 | **Actual >= Requested** | For non-MAX withdrawals, `actualWithdrawnAmount >= requestedAmount` | User receives less than expected |
| 4 | **Transfer Integrity** | After withdraw, YieldPeer receives exactly `actualWithdrawnAmount` | Funds lost in transit |

### Priority 2: Accounting Invariants

| # | Invariant | Description | Risk if Violated |
|---|-----------|-------------|------------------|
| 5 | **Value Non-Negative** | `getTotalValue() >= 0` always | Accounting error |
| 6 | **Deposit Increases Value** | After `deposit(X)`, `getTotalValue()` increases by ~X | Deposit not credited |
| 7 | **Interest Non-Negative** | Over time without withdrawals, `getTotalValue()` should not decrease | Protocol accounting bug |

### Priority 3: Access Control Invariants

| # | Invariant | Description | Risk if Violated |
|---|-----------|-------------|------------------|
| 8 | **Only YieldPeer Access** | All `deposit`/`withdraw` from non-YieldPeer revert | Unauthorized access |

---

## Implementation Plan

### Phase 1: Ghost Variables (Handler.t.sol)

Add new ghost variables to track adapter-specific state:

```solidity
// ============ ADAPTER GHOST VARIABLES ============

// Deposit tracking
uint256 public ghost_adapter_totalDeposited;
uint256 public ghost_adapter_lastDepositAmount;
uint256 public ghost_adapter_totalValueBeforeLastDeposit;
uint256 public ghost_adapter_totalValueAfterLastDeposit;

// Withdraw tracking
uint256 public ghost_adapter_totalWithdrawn;
uint256 public ghost_adapter_lastWithdrawRequested;
uint256 public ghost_adapter_lastWithdrawActual;
uint256 public ghost_adapter_totalValueBeforeLastWithdraw;
uint256 public ghost_adapter_totalValueAfterLastWithdraw;

// MAX sentinel tracking (already exists, but extend)
uint256 public ghost_maxSentinelWithdrawals; // already exists
uint256 public ghost_maxSentinelAdapterBalanceAfter; // already exists
uint256 public ghost_maxSentinelTotalValueBefore;
uint256 public ghost_maxSentinelActualWithdrawn;

// Interest accrual tracking
uint256 public ghost_adapter_totalValueAtLastCheck;
uint256 public ghost_adapter_blockAtLastCheck;
bool public ghost_adapter_valueDecreased; // should always be false

// Access control tracking
bool public ghost_adapter_unauthorizedDepositSucceeded;
bool public ghost_adapter_unauthorizedWithdrawSucceeded;
```

### Phase 2: Handler Function Modifications

#### 2.1 Modify `_handleOnReportLogs()` to capture more data

The existing `_handleOnReportLogs` already tracks `WithdrawFromStrategy` events. Extend it to capture:

```solidity
// In _handleOnReportLogs(), extend the MAX sentinel tracking:
if (logs[i].topics[0] == withdrawFromStrategyEvent) {
    uint256 withdrawAmount = uint256(logs[i].topics[2]);
    address adapterAddress = address(uint160(uint256(logs[i].topics[1])));

    if (withdrawAmount == type(uint256).max) {
        ghost_maxSentinelWithdrawals++;

        // Capture total value BEFORE (from DepositToStrategy event that preceded it, or track separately)
        // This requires reading the adapter's getTotalValue before the rebalance

        uint256 adapterBalanceAfter = IStrategyAdapter(adapterAddress).getTotalValue(address(usdc));
        ghost_maxSentinelAdapterBalanceAfter = adapterBalanceAfter;
    }
}
```

#### 2.2 Add new handler function: `directAdapterDeposit()`

Create a handler function that directly tests adapter deposit behavior (bypasses peer logic for isolated testing):

```solidity
/// @notice Direct adapter deposit test - for isolated adapter testing
/// @param adapterSeed Seed to select which adapter to test
/// @param depositAmount Amount to deposit
function directAdapterDeposit(uint256 adapterSeed, uint256 depositAmount) public {
    depositAmount = bound(depositAmount, MIN_DEPOSIT_AMOUNT, MAX_DEPOSIT_AMOUNT);

    // Select an adapter (parent's Aave or Compound adapter)
    address adapter = adapterSeed % 2 == 0
        ? address(aaveV3AdapterParent)
        : address(compoundV3AdapterParent);

    // Get value before deposit
    uint256 valueBefore = IStrategyAdapter(adapter).getTotalValue(address(usdc));
    ghost_adapter_totalValueBeforeLastDeposit = valueBefore;
    ghost_adapter_lastDepositAmount = depositAmount;

    // Deal USDC to adapter and deposit via parent peer
    deal(address(usdc), address(parent), depositAmount);
    _changePrank(address(parent));
    usdc.transfer(adapter, depositAmount);
    IStrategyAdapter(adapter).deposit(address(usdc), depositAmount);

    // Get value after deposit
    uint256 valueAfter = IStrategyAdapter(adapter).getTotalValue(address(usdc));
    ghost_adapter_totalValueAfterLastDeposit = valueAfter;
    ghost_adapter_totalDeposited += depositAmount;

    _stopPrank();
}
```

#### 2.3 Add new handler function: `directAdapterWithdraw()`

```solidity
/// @notice Direct adapter withdraw test - for isolated adapter testing
/// @param adapterSeed Seed to select which adapter to test
/// @param withdrawAmount Amount to withdraw (can be type(uint256).max for MAX sentinel)
function directAdapterWithdraw(uint256 adapterSeed, uint256 withdrawAmount, bool useMaxSentinel) public {
    // Select adapter
    address adapter = adapterSeed % 2 == 0
        ? address(aaveV3AdapterParent)
        : address(compoundV3AdapterParent);

    uint256 totalValue = IStrategyAdapter(adapter).getTotalValue(address(usdc));
    if (totalValue == 0) return; // Nothing to withdraw

    // Determine actual withdraw amount
    uint256 actualRequestedAmount;
    if (useMaxSentinel) {
        actualRequestedAmount = type(uint256).max;
        ghost_maxSentinelTotalValueBefore = totalValue;
    } else {
        // Bound to available balance
        withdrawAmount = bound(withdrawAmount, 1, totalValue);
        actualRequestedAmount = withdrawAmount;
    }

    ghost_adapter_totalValueBeforeLastWithdraw = totalValue;
    ghost_adapter_lastWithdrawRequested = actualRequestedAmount;

    // Get peer balance before
    uint256 peerBalanceBefore = usdc.balanceOf(address(parent));

    // Perform withdrawal
    _changePrank(address(parent));
    uint256 actualWithdrawn = IStrategyAdapter(adapter).withdraw(address(usdc), actualRequestedAmount);
    _stopPrank();

    // Track results
    ghost_adapter_lastWithdrawActual = actualWithdrawn;
    ghost_adapter_totalValueAfterLastWithdraw = IStrategyAdapter(adapter).getTotalValue(address(usdc));
    ghost_adapter_totalWithdrawn += actualWithdrawn;

    if (useMaxSentinel) {
        ghost_maxSentinelWithdrawals++;
        ghost_maxSentinelActualWithdrawn = actualWithdrawn;
        ghost_maxSentinelAdapterBalanceAfter = ghost_adapter_totalValueAfterLastWithdraw;
    }

    // Verify transfer integrity
    uint256 peerBalanceAfter = usdc.balanceOf(address(parent));
    if (peerBalanceAfter - peerBalanceBefore != actualWithdrawn) {
        // This would indicate a transfer integrity failure
        // Could add a ghost flag for this
    }
}
```

#### 2.4 Add handler function: `attemptUnauthorizedAdapterAccess()`

```solidity
/// @notice Attempt unauthorized access to adapter functions
/// @param callerSeed Seed to generate random unauthorized caller
/// @param adapterSeed Seed to select adapter
function attemptUnauthorizedAdapterAccess(uint256 callerSeed, uint256 adapterSeed) public {
    address unauthorizedCaller = _seedToAddress(callerSeed);

    // Make sure caller is not the yield peer
    vm.assume(unauthorizedCaller != address(parent));
    vm.assume(unauthorizedCaller != address(child1));
    vm.assume(unauthorizedCaller != address(child2));

    address adapter = adapterSeed % 2 == 0
        ? address(aaveV3AdapterParent)
        : address(compoundV3AdapterParent);

    // Try unauthorized deposit
    _changePrank(unauthorizedCaller);
    try IStrategyAdapter(adapter).deposit(address(usdc), 1e6) {
        ghost_adapter_unauthorizedDepositSucceeded = true;
    } catch {}

    // Try unauthorized withdraw
    try IStrategyAdapter(adapter).withdraw(address(usdc), 1e6) {
        ghost_adapter_unauthorizedWithdrawSucceeded = true;
    } catch {}

    _stopPrank();
}
```

#### 2.5 Add handler function: `checkInterestAccrual()`

```solidity
/// @notice Check that interest accrues non-negatively
/// @param adapterSeed Seed to select adapter
function checkInterestAccrual(uint256 adapterSeed) public {
    address adapter = adapterSeed % 2 == 0
        ? address(aaveV3AdapterParent)
        : address(compoundV3AdapterParent);

    uint256 currentValue = IStrategyAdapter(adapter).getTotalValue(address(usdc));

    // Only check if we have a previous reading and time has passed
    if (ghost_adapter_blockAtLastCheck != 0 && block.number > ghost_adapter_blockAtLastCheck) {
        if (currentValue < ghost_adapter_totalValueAtLastCheck) {
            ghost_adapter_valueDecreased = true;
        }
    }

    ghost_adapter_totalValueAtLastCheck = currentValue;
    ghost_adapter_blockAtLastCheck = block.number;
}
```

### Phase 3: Invariant Functions (Invariant.t.sol)

#### 3.1 MAX Withdrawal Drains Balance (Already Exists - Extend)

The existing `invariant_strategyAdapter_maxSentinel_withdrawsAllProtocolBalance` is good. Consider adding:

```solidity
/// @dev After MAX withdrawal, actual withdrawn should equal or exceed the pre-withdrawal total value
function invariant_strategyAdapter_maxSentinel_withdrawsAtLeastTotalValue() public view {
    uint256 maxSentinelWithdrawals = handler.ghost_maxSentinelWithdrawals();

    if (maxSentinelWithdrawals > 0) {
        uint256 totalValueBefore = handler.ghost_maxSentinelTotalValueBefore();
        uint256 actualWithdrawn = handler.ghost_maxSentinelActualWithdrawn();

        assertTrue(
            actualWithdrawn >= totalValueBefore,
            "Invariant violated: MAX sentinel should withdraw at least the total value"
        );
    }
}
```

#### 3.2 Actual Withdrawn >= Requested

```solidity
/// @dev For non-MAX withdrawals, actual withdrawn should be >= requested
function invariant_strategyAdapter_withdrawActualGteRequested() public view {
    uint256 lastRequested = handler.ghost_adapter_lastWithdrawRequested();
    uint256 lastActual = handler.ghost_adapter_lastWithdrawActual();

    // Only check if not MAX sentinel (MAX sentinel is handled separately)
    if (lastRequested != type(uint256).max && lastRequested > 0) {
        assertTrue(
            lastActual >= lastRequested,
            "Invariant violated: Actual withdrawn should be >= requested amount"
        );
    }
}
```

#### 3.3 Deposit Increases Value

```solidity
/// @dev After deposit, total value should increase by approximately the deposit amount
function invariant_strategyAdapter_depositIncreasesValue() public view {
    uint256 depositAmount = handler.ghost_adapter_lastDepositAmount();
    uint256 valueBefore = handler.ghost_adapter_totalValueBeforeLastDeposit();
    uint256 valueAfter = handler.ghost_adapter_totalValueAfterLastDeposit();

    if (depositAmount > 0 && valueBefore > 0) {
        // Allow for small rounding/dust differences (< 0.1%)
        uint256 expectedIncrease = depositAmount;
        uint256 actualIncrease = valueAfter - valueBefore;
        uint256 tolerance = expectedIncrease / 1000; // 0.1% tolerance

        assertTrue(
            actualIncrease >= expectedIncrease - tolerance,
            "Invariant violated: Deposit should increase total value by approximately deposit amount"
        );
    }
}
```

#### 3.4 Access Control

```solidity
/// @dev Only YieldPeer should be able to call deposit/withdraw
function invariant_strategyAdapter_onlyYieldPeerAccess() public view {
    assertFalse(
        handler.ghost_adapter_unauthorizedDepositSucceeded(),
        "Invariant violated: Unauthorized deposit should not succeed"
    );
    assertFalse(
        handler.ghost_adapter_unauthorizedWithdrawSucceeded(),
        "Invariant violated: Unauthorized withdraw should not succeed"
    );
}
```

#### 3.5 Interest Non-Negative

```solidity
/// @dev Total value should never decrease without explicit withdrawals (interest should accrue)
function invariant_strategyAdapter_interestNonNegative() public view {
    assertFalse(
        handler.ghost_adapter_valueDecreased(),
        "Invariant violated: Total value decreased without withdrawal (negative interest)"
    );
}
```

#### 3.6 Value Conservation During Rebalance

```solidity
/// @dev During rebalance, the total value withdrawn from old adapter should equal deposit to new adapter
/// This is already partially tested via existing invariants, but can be made more explicit
function invariant_strategyAdapter_rebalanceValueConservation() public view {
    // If a MAX sentinel withdrawal happened, verify the total system value is conserved
    // This requires tracking deposits to new strategy as well
    // Implementation depends on extending ghost variables to track rebalance flows
}
```

### Phase 4: Update Setup

In `Invariant.t.sol`, update the `setUp()` function to include new handler selectors:

```solidity
function setUp() public override {
    // ... existing setup ...

    /// @dev define appropriate function selectors - ADD NEW ONES
    bytes4[] memory selectors = new bytes4[](9);
    selectors[0] = Handler.deposit.selector;
    selectors[1] = Handler.withdraw.selector;
    selectors[2] = Handler.onReport.selector;
    selectors[3] = Handler.withdrawFees.selector;
    selectors[4] = Handler.setFeeRate.selector;
    // NEW: Direct adapter testing
    selectors[5] = Handler.directAdapterDeposit.selector;
    selectors[6] = Handler.directAdapterWithdraw.selector;
    selectors[7] = Handler.attemptUnauthorizedAdapterAccess.selector;
    selectors[8] = Handler.checkInterestAccrual.selector;

    /// @dev target handler and appropriate function selectors
    targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    targetContract(address(handler));
}
```

Also add adapter references to Handler constructor:

```solidity
// In Handler constructor, add:
AaveV3Adapter internal aaveV3AdapterParent;
CompoundV3Adapter internal compoundV3AdapterParent;

// And pass them in from Invariant.t.sol setUp()
```

---

## Testing Strategy

### Test Categories

1. **Happy Path**: Normal deposits/withdrawals work correctly
2. **Edge Cases**: MAX sentinel, dust amounts, zero values
3. **Attack Vectors**: Unauthorized access, over-withdrawal attempts
4. **State Transitions**: Rebalance scenarios, interest accrual

### Suggested Fuzz Run Configuration

```toml
# foundry.toml
[invariant]
runs = 256
depth = 50
fail_on_revert = false
```

### Recommended Test Order

1. Run existing invariants to verify nothing broke
2. Add ghost variables (no behavior change)
3. Add new handler functions one at a time
4. Add corresponding invariants and verify
5. Run extended fuzz campaigns

---

## Open Questions

1. **Handler scope**: Should the new direct adapter tests (`directAdapterDeposit`, `directAdapterWithdraw`) be separate from the existing flow-based tests, or integrated? Separate gives more isolated coverage but may miss integration bugs.

2. **Adapter references**: Should I pass the adapter references through the Handler constructor (cleaner) or access them via the strategy registry (more realistic)?

3. **Interest accrual testing**: The mocks may not actually accrue interest. Should we skip `invariant_strategyAdapter_interestNonNegative` or modify the mocks to simulate interest?
