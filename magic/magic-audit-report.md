# Security Audit Report - Yield Protocol

**Audit Date:** December 22, 2025
**Protocol:** Yield - Cross-Chain Yield Optimization Protocol
**Auditor:** Claude Sonnet 4.5 via Audit Naive Phase 6 Agent

## Executive Summary

This security audit was conducted on the Yield Protocol, a cross-chain yield optimization system that enables users to deposit USDC across multiple chains and automatically rebalances funds to maximize yield across different DeFi protocols (Aave V3, Compound V3).

**Overall Risk Assessment:** HIGH

The audit identified **20 issues** across the protocol. After applying the severity classification system, no issues qualify as CRITICAL severity. The system demonstrates several high-severity vulnerabilities that could lead to loss of user funds, accounting corruption, and denial of service under specific conditions.

### Summary of Findings

| Severity | Count | Description |
|----------|-------|-------------|
| CRITICAL | 0 | No issues that enable unconditional asset theft |
| HIGH | 10 | Issues that could lead to asset loss, accounting corruption, or permanent DoS |
| MEDIUM | 0 | No medium severity issues after reclassification |
| LOW | 3 | Issues with minor impact, rounding or validation issues |
| INFORMATIONAL | 4 | Documentation and configuration issues |
| ADMIN MISTAKE | 3 | Issues requiring admin misconfiguration |
| INTEGRATION RISK | 1 | External dependency risk |

**Total Issues Identified:** 20

---

## High Severity Issues

### 1. CompoundV3Adapter Withdrawal Validation Failure
**Likelihood: 90% | Impact: High | Severity: HIGH**

**Description:**
CompoundV3Adapter has NO validation on actual withdrawn amounts from Compound V3. It always transfers the full requested amount regardless of what Comet actually withdrew, causing system-wide accounting corruption.

**Location:** `/app/repo/src/adapters/CompoundV3Adapter.sol:45-49`

**Impact:**
- TVL accounting desynchronizes
- Share price calculations corrupted for ALL users
- Adapter residual balance can be drained
- Future withdrawals fail (DoS)

**Recommendation:**
```solidity
function withdraw(address usdc, uint256 amount) external onlyYieldPeer {
    emit Withdraw(usdc, amount);

    uint256 balanceBefore = IERC20(usdc).balanceOf(address(this));
    IComet(i_comet).withdraw(usdc, amount);
    uint256 balanceAfter = IERC20(usdc).balanceOf(address(this));
    uint256 actualWithdrawn = balanceAfter - balanceBefore;

    if (actualWithdrawn < amount) revert CompoundV3Adapter__InsufficientWithdrawAmount();
    _transferTokenTo(usdc, i_yieldPeer, actualWithdrawn);
}
```

---

### 2. Cross-Chain State Desynchronization During Rebalancing
**Likelihood: 95% | Impact: High | Severity: HIGH**

**Description:**
During cross-chain rebalancing, ParentPeer updates state immediately while ChildPeer receives update via CCIP with minutes to hours of latency, creating guaranteed state desync window where users cannot access the system.

**Location:**
- `/app/repo/src/peers/ParentPeer.sol:203-225`
- `/app/repo/src/peers/ChildPeer.sol:56-79, 196-211`

**Impact:**
- Operations routed to wrong chain or fail entirely
- Deposits create circular routing (Parent→Child→Parent)
- Funds stuck in transit messages
- Users cannot access system (DoS)

**Recommendation:**
Implement deposit/withdrawal queuing or pausing during rebalancing operations to prevent state desynchronization issues.

---

### 3. Optimistic Share Burn Before Withdrawal Confirmation
**Likelihood: 80% | Impact: High | Severity: HIGH**

**Description:**
Both ParentPeer and ChildPeer burn shares BEFORE confirming withdrawal succeeds. ChildPeer is worse as it burns before cross-chain confirmation. Users permanently lose shares if withdrawal fails.

**Location:**
- `/app/repo/src/peers/ParentPeer.sol:154`
- `/app/repo/src/peers/ChildPeer.sol:98`

**Impact:**
- Permanent user fund loss if withdrawal fails
- No recovery mechanism for failed cross-chain messages
- Strategy withdrawal failures result in burned shares with no USDC received

**Recommendation:**
Implement two-phase withdrawal:
1. First: Withdraw from strategy or send cross-chain message
2. Only after success: Burn shares
3. Add recovery mechanism for failed withdrawals

---

### 4. Ping-Pong Message Loop Without Prevention
**Likelihood: 75% | Impact: High | Severity: HIGH**

**Description:**
Deposit ping-pong mechanism lacks loop prevention. During rebalancing or state desync, deposits can bounce between chains indefinitely until gas exhausted.

**Location:**
- `/app/repo/src/peers/ChildPeer.sol:56-79, 166-178`
- `/app/repo/src/peers/ParentPeer.sol:237-296`

**Impact:**
- LINK fees drain with each hop
- User funds stuck in failed messages
- No recovery mechanism

**Recommendation:**
Add hop counter to prevent infinite loops:
```solidity
struct DepositData {
    address depositor;
    uint256 amount;
    uint256 totalValue;
    uint256 shareMintAmount;
    uint64 destinationChainSelector;
    uint8 hopCount;  // Add this field
}

// Validate and increment on each hop
require(depositData.hopCount < MAX_HOPS, "Too many hops");
depositData.hopCount++;
```

---

### 5. AaveV3Adapter Strict Equality Check
**Likelihood: 75% | Impact: High | Severity: HIGH**

**Description:**
AaveV3Adapter enforces strict equality on withdrawal amounts, but Aave interest accrues continuously causing inevitable mismatches. Composed with ParentPeer burning shares first, this guarantees user fund loss.

**Location:** `/app/repo/src/adapters/AaveV3Adapter.sol:59`

**Impact:**
- Transaction reverts if Aave returns slightly different amount
- Shares already burned before check
- User receives nothing
- Permanent loss

**Recommendation:**
```solidity
if (withdrawnAmount < amount) revert AaveV3Adapter__IncorrectWithdrawAmount();
// Transfer actual withdrawn amount
_transferTokenTo(usdc, i_yieldPeer, withdrawnAmount);
```

---

### 6. InactiveStrategyAdapter DoS During Rebalancing
**Likelihood: 70% | Impact: High | Severity: HIGH**

**Description:**
When strategy is on this chain but activeStrategyAdapter = address(0) during rebalancing, all deposits and withdrawals revert, creating guaranteed DoS.

**Location:** `/app/repo/src/peers/ParentPeer.sol:94-97, 160-163`

**Impact:**
- System unavailable during message transit (5-30 minutes)
- User frustration and potential abandonment

**Recommendation:**
Implement queuing mechanism or allow operations with zero adapter by holding funds temporarily.

---

### 7. Rebalancer Uninitialized totalValue
**Likelihood: 70% | Impact: High | Severity: HIGH**

**Description:**
In Rebalancer.checkLog, totalValue variable declared but only initialized in one branch. Child-to-child rebalancing uses totalValue=0, causing state corruption.

**Location:** `/app/repo/src/modules/Rebalancer.sol:148-158`

**Impact:**
- State corrupted between ParentPeer and ChildPeers
- Users deposit to wrong chain (no funds)
- Withdrawals fail due to state inconsistency

**Recommendation:**
```solidity
uint256 totalValue = 0; // Explicit initialization
if (oldChainSelector == thisChainSelector && chainSelector != thisChainSelector) {
    txType = IYieldPeer.CcipTxType.RebalanceNewStrategy;
    totalValue = IYieldPeer(parentPeer).getTotalValue();
} else {
    txType = IYieldPeer.CcipTxType.RebalanceOldStrategy;
    // totalValue intentionally 0 for this case - document this
}
```

---

### 8. ChildPeer Trusts ParentPeer Without Validation
**Likelihood: 25% | Impact: High | Severity: HIGH**

**Description:**
ChildPeer accepts all messages from ParentPeer without validating data contents. Compromised or buggy Parent can mint unlimited shares.

**Location:** `/app/repo/src/peers/ChildPeer.sol:166-178`

**Impact:**
- Unlimited share minting if Parent compromised
- Share dilution if Parent bug
- System-wide accounting corruption

**Recommendation:**
Add validation even for trusted Parent:
```solidity
uint256 internal constant MAX_SHARES_PER_MINT = 1_000_000_000 * 1e18;

function _handleCCIPDepositCallbackChild(bytes memory data) internal {
    DepositData memory depositData = _decodeDepositData(data);

    require(depositData.shareMintAmount > 0, "Zero shares");
    require(depositData.shareMintAmount <= MAX_SHARES_PER_MINT, "Excessive shares");
    require(depositData.depositor != address(0), "Invalid depositor");

    if (depositData.destinationChainSelector == i_thisChainSelector) {
        _mintShares(depositData.depositor, depositData.shareMintAmount);
    }
}
```

---

### 9. YieldFees withdrawFees Can Drain User Withdrawal Funds
**Likelihood: 65% | Impact: High | Severity: HIGH**

**Description:**
YieldFees.withdrawFees takes entire USDC balance, but ParentPeer temporarily holds USDC during withdrawal operations. Race condition allows FEE_WITHDRAWER_ROLE to steal user funds.

**Location:** `/app/repo/src/modules/YieldFees.sol:66-74`

**Recommendation:**
Track accumulated fees separately:
```solidity
uint256 internal s_accumulatedFees;

function _calculateFee(uint256 stablecoinDepositAmount) internal returns (uint256 fee) {
    fee = s_feeRate;
    if (fee != 0) {
        fee = (stablecoinDepositAmount * fee) / FEE_RATE_DIVISOR;
        s_accumulatedFees += fee;
    }
}

function withdrawFees(address feeToken) external onlyRole(Roles.FEE_WITHDRAWER_ROLE) {
    uint256 fees = s_accumulatedFees;
    if (fees == 0) revert YieldFees__NoFeesToWithdraw();

    s_accumulatedFees = 0;
    emit FeesWithdrawn(fees);
    IERC20(feeToken).safeTransfer(msg.sender, fees);
}
```

---

### 10. ParentPeer State Updated Before Deposit Confirmed
**Likelihood: 40% | Impact: High | Severity: HIGH**

**Description:**
In deposit function, s_totalShares is incremented before deposit to strategy is confirmed. If deposit fails, accounting becomes incorrect.

**Location:** `/app/repo/src/peers/ParentPeer.sol:103-114`

**Recommendation:**
```solidity
uint256 shareMintAmount = _calculateMintAmount(totalValue, amountToDeposit);

// Deposit FIRST
_depositToStrategy(activeStrategyAdapter, amountToDeposit);

// THEN update state
s_totalShares += shareMintAmount;
emit ShareMintUpdate(shareMintAmount, i_thisChainSelector, s_totalShares);

// Finally mint shares
_mintShares(msg.sender, shareMintAmount);
```

---

## Low Severity Issues

### 11. ParentPeer Zero USDC Withdrawal Allowed
**Likelihood: 35% | Impact: Low | Severity: LOW**

**Description:**
Withdrawal flow allows usdcWithdrawAmount to be zero. Users can burn shares but receive no USDC due to rounding.

**Location:** `/app/repo/src/peers/ParentPeer.sol:167-176`

**Recommendation:**
```solidity
uint256 usdcWithdrawAmount = _calculateWithdrawAmount(totalValue, totalShares, shareBurnAmount);
if (usdcWithdrawAmount == 0) revert ParentPeer__ZeroWithdrawalAmount();
_withdrawFromStrategy(activeStrategyAdapter, usdcWithdrawAmount);
```

---

### 12. Allowance Accumulation in Strategy Adapters
**Likelihood: 30% | Impact: Low | Severity: LOW**

**Description:**
Both AaveV3Adapter and CompoundV3Adapter use safeIncreaseAllowance, which can accumulate over time if protocols don't consume full allowance.

**Location:**
- `/app/repo/src/adapters/AaveV3Adapter.sol:46`
- `/app/repo/src/adapters/CompoundV3Adapter.sol:37`
- `/app/repo/src/modules/StrategyAdapter.sol:64`

**Recommendation:**
```solidity
function _approveToken(address token, address spender, uint256 amount) internal {
    uint256 currentAllowance = IERC20(token).allowance(address(this), spender);
    if (currentAllowance >= amount) return;

    if (currentAllowance > 0) {
        IERC20(token).safeApprove(spender, 0);
    }
    IERC20(token).safeApprove(spender, amount);
}
```

---

### 13. SharePool Empty Allowlist Configuration
**Likelihood: 40% | Impact: Low | Severity: LOW**

**Description:**
SharePool initialized with empty allowlist. Pool cannot be used until post-deployment configuration.

**Location:** `/app/repo/src/token/SharePool.sol:14`

**Recommendation:**
Accept initial allowlist in constructor or document post-deployment setup clearly.

---

## Informational Severity Issues

### 14. Share Token Misleading Comment on Transfer Pattern
**Likelihood: 5% | Impact: Informational | Severity: INFORMATIONAL**

**Description:**
Comment states "2-step ownership transfer is used" for CCIPAdmin role, but setCCIPAdmin implements single-step transfer.

**Location:** `/app/repo/src/token/Share.sol:33-42`

**Recommendation:**
Update comment to reflect actual implementation or implement 2-step transfer pattern.

---

### 15. SharePool No Validation in Constructor
**Likelihood: 30% | Impact: Informational | Severity: INFORMATIONAL**

**Description:**
SharePool constructor passes parameters to parent without validation. Invalid addresses could result in non-functional pool during deployment but would be caught during testing.

**Location:** `/app/repo/src/token/SharePool.sol:13-15`

**Recommendation:**
Add validation before calling parent constructor (noting Solidity 0.8.26 requirements).

---

### 16. BurnMintERC677 Double Transfer Event Emission
**Likelihood: N/A | Impact: Informational | Severity: INFORMATIONAL**

**Description:**
ERC677 implementation emits TWO Transfer events during transferAndCall - both standard ERC20 and ERC677 variants, causing potential double-counting in off-chain systems.

**Location:** `/app/repo/lib/chainlink/contracts/src/v0.8/shared/token/ERC677/ERC677.sol:13-19`

**Recommendation:**
Accept current behavior as it's consistent with Chainlink implementation, but document clearly.

---

### 17. Rebalancer Unvalidated Remote Script Parameters
**Likelihood: 20% | Impact: Informational | Severity: INFORMATIONAL**

**Description:**
Rebalancing functions only check that caller is Rebalancer, but don't validate parameters. Compromised Rebalancer can pass malicious strategy data. However, this requires the trusted Rebalancer role to be compromised first.

**Location:** `/app/repo/src/peers/ParentPeer.sol:203-225`

**Recommendation:**
Add parameter validation even for trusted Rebalancer:
- Validate chain selector is in allowed list
- Validate protocol exists in registry
- Validate totalValue matches actual balance

---

## Admin Mistake Severity Issues

### 18. Share Token No Maximum Supply Protection
**Likelihood: 25% | Impact: Admin Mistake | Severity: ADMIN MISTAKE**

**Description:**
Share token initialized with maxSupply of 0 (unlimited). No protection against excessive minting if minter roles compromised.

**Location:** `/app/repo/src/token/Share.sol:25`

**Recommendation:**
```solidity
constructor() BurnMintERC677("YieldCoin", "YIELD", 18, 1_000_000_000 * 1e18) {
    s_ccipAdmin = msg.sender;
}
```

---

### 19. StrategyRegistry No Validation of Strategy Adapter
**Likelihood: 45% | Impact: Admin Mistake | Severity: ADMIN MISTAKE**

**Description:**
setStrategyAdapter allows owner to set any address without validating it's a contract or implements required interface. This is an admin configuration error.

**Location:** `/app/repo/src/modules/StrategyRegistry.sol:45-47`

**Recommendation:**
```solidity
function setStrategyAdapter(bytes32 protocolId, address strategyAdapter) external onlyOwner {
    if (strategyAdapter != address(0)) {
        require(strategyAdapter.code.length > 0, "Not a contract");

        try IStrategyAdapter(strategyAdapter).getTotalValue(address(0)) returns (uint256) {
            // Valid
        } catch {
            revert("Invalid adapter interface");
        }
    }

    s_strategyAdapters[protocolId] = strategyAdapter;
    emit StrategyAdapterSet(protocolId, strategyAdapter);
}
```

---

### 20. SharePool Constructor Parameter Validation
**Likelihood: 30% | Impact: Admin Mistake | Severity: ADMIN MISTAKE**

**Description:**
SharePool constructor accepts addresses without validation. Admin passing invalid addresses during deployment creates non-functional pool. This is a deployment-time admin error.

**Location:** `/app/repo/src/token/SharePool.sol:13-15`

**Recommendation:**
Add validation before calling parent constructor to prevent deployment-time admin errors.

---

## Integration Risk Issues

### 21. Rebalancer Remote Script Centralization Risk
**Likelihood: 40% | Impact: Integration Risk | Severity: INTEGRATION RISK**

**Description:**
Chainlink Functions request fetches JavaScript code from GitHub URL. If GitHub is compromised or unavailable, rebalancing logic can be compromised or fail. This is an external integration dependency issue.

**Location:** `/app/repo/src/modules/Rebalancer.sol:38-39`

**Recommendation:**
- Use script hash verification
- Consider inlining script if small enough
- Use IPFS with content addressing
- Add bounds checking in _fulfillRequest

---

## Systemic Risk Factors

1. **No Emergency Withdrawal Mechanism**
   - If critical bug found, no way to rescue user funds quickly
   - Users' funds locked during incident response

2. **Cross-Chain State Synchronization Assumptions**
   - System assumes eventual consistency
   - No handling for message reordering or permanent loss
   - s_totalShares must stay perfectly synced

3. **Trust Chain Through Multiple Components**
   - Rebalancer → StrategyRegistry → ParentPeer → Strategy Adapters
   - Each link trusts previous without validation
   - Single compromise point affects entire system

4. **External Dependency Risks**
   - Aave V3 upgrades (pool address changes)
   - Compound V3 utilization (liquidity constraints)
   - CCIP reliability (message delivery)
   - Chainlink Automation (forwarder security)
   - GitHub availability (remote script fetch)

5. **Accounting Desync Amplification**
   - Small errors compound over time
   - Multiple desync vectors
   - Share price corruption affects all users
   - No re-synchronization mechanism

---

## Recommended Immediate Actions

### Priority 1 (Implement Immediately Before Deployment):
1. Add withdrawal amount validation in CompoundV3Adapter
2. Use >= check instead of != in AaveV3Adapter withdrawal
3. Implement two-phase withdrawal (withdraw THEN burn shares)
4. Add hop counter to ping-pong mechanism (max 3-5 hops)
5. Track accumulated fees separately from operational balance

### Priority 2 (Implement Soon):
1. Add validation in ChildPeer for Parent messages
2. Implement deposit/withdrawal queuing during rebalancing
3. Fix uninitialized totalValue in Rebalancer
4. Add strategy adapter address validation in StrategyRegistry
5. Implement withdrawal confirmation mechanism for cross-chain ops

### Priority 3 (Architecture Review):
1. Review cross-chain state synchronization strategy
2. Add circuit breakers for rapid state changes
3. Implement emergency withdrawal mechanism
4. Add multi-sig or timelock for critical operations
5. Review trust assumptions throughout the system

---

## Conclusion

The Yield Protocol demonstrates sophisticated cross-chain yield optimization functionality but contains several high-severity vulnerabilities that **must be addressed before production deployment**. The most severe issues involve:

1. **Fund loss risks** from optimistic share burning before withdrawal confirmation
2. **Accounting corruption** from unvalidated withdrawal amounts
3. **State desynchronization** during cross-chain rebalancing operations
4. **DoS vectors** from message loops and inactive adapters

**Overall Recommendation:** DO NOT DEPLOY to production until Priority 1 issues are fully resolved and tested. Consider a security review from additional auditors before mainnet launch.

The protocol shows good design patterns in many areas (access control, pausability, modular architecture) but needs strengthening in cross-chain consistency guarantees and defensive validation throughout the stack.

After applying the proper severity classification system, no issues qualify as CRITICAL (which requires unconditional asset theft with no configuration requirement). The highest severity issues are HIGH, representing conditional asset loss, accounting corruption, and DoS scenarios.

---

**End of Report**
