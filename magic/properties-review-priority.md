# Properties Review Priority Order

This document lists the order in which contracts and functions should be reviewed for property specification. The order is based on dependency complexity - simpler contracts with fewer dependencies should be reviewed first, followed by more complex ones.

## Priority Level 1: Libraries and Pure Functions (No State Dependencies)

### 1. Roles.sol
- **Complexity**: Minimal (only constants)
- **Storage Slots**: 0
- **Function Calls**: 0
- **Why First**: No dependencies, just constant definitions

### 2. DataStructures.sol
- **Complexity**: Very Low
- **Storage Slots**: 0 (pure library functions)
- **Function Calls**: 0 (pure functions)
- **Why First**: Pure functions with no state or external dependencies
- **Functions to Review**:
  - buildDepositData
  - buildWithdrawData

### 3. CCIPOperations.sol
- **Complexity**: Low-Medium
- **Storage Slots**: 0 (library, operates on passed state)
- **Function Calls**: 3-4 per function (external token/router calls)
- **Why Early**: Library functions with limited external dependencies
- **Functions to Review**:
  - _buildCCIPMessage
  - _validateTokenAmounts
  - _prepareTokenAmounts
  - _handleCCIPFees

## Priority Level 2: Simple Modules with Limited State

### 4. StrategyRegistry.sol
- **Complexity**: Low
- **Storage Slots**: 1 (s_strategyAdapters mapping)
- **Function Calls**: 0 external, simple mapping operations
- **Why Early**: Simple state management, no complex dependencies
- **Functions to Review**:
  - setStrategyAdapter
  - getStrategyAdapter

### 5. YieldFees.sol
- **Complexity**: Low-Medium
- **Storage Slots**: 1 (s_feeRate)
- **Function Calls**: 2-3 per function (token operations)
- **Why Early**: Limited state, straightforward fee calculations
- **Functions to Review**:
  - _calculateFee
  - setFeeRate
  - getFeeRate
  - getFeeRateDivisor
  - getMaxFeeRate
  - withdrawFees

### 6. PausableWithAccessControl.sol
- **Complexity**: Medium
- **Storage Slots**: 2 (s_roleMembers + inherited _paused)
- **Function Calls**: 2-3 per function (role management)
- **Why Early**: Core access control module, needed for understanding other contracts
- **Functions to Review**:
  - emergencyPause
  - emergencyUnpause
  - _grantRole
  - _revokeRole
  - getRoleMember
  - getRoleMemberCount
  - getRoleMembers

## Priority Level 3: Strategy Adapters (Isolated Components)

### 7. StrategyAdapter.sol
- **Complexity**: Low
- **Storage Slots**: 1 (i_yieldPeer immutable)
- **Function Calls**: 1 per function (token operations)
- **Why Mid-Level**: Base contract for adapters, limited interactions
- **Functions to Review**:
  - _transferTokenTo
  - _approveToken

### 8. CompoundV3Adapter.sol
- **Complexity**: Low-Medium
- **Storage Slots**: 2 (i_yieldPeer, i_comet immutables)
- **Function Calls**: 2-3 per function (strategy-specific)
- **Why Mid-Level**: Self-contained strategy logic
- **Functions to Review**:
  - deposit
  - withdraw
  - getTotalValue
  - getStrategyPool

### 9. AaveV3Adapter.sol
- **Complexity**: Medium
- **Storage Slots**: 2 (i_yieldPeer, i_aavePoolAddressesProvider immutables)
- **Function Calls**: 3-4 per function (strategy-specific with pool resolution)
- **Why Mid-Level**: Similar to Compound but with additional pool address resolution
- **Functions to Review**:
  - deposit
  - withdraw
  - getTotalValue
  - getPoolAddressesProvider
  - getStrategyPool
  - _getAavePool

## Priority Level 4: Governance and Automation Modules

### 10. CREReceiver.sol
- **Complexity**: Medium-High
- **Storage Slots**: 2 (s_workflows mapping, s_keystoneForwarder)
- **Function Calls**: 2-4 per function (workflow validation)
- **Why Mid-Level**: Isolated oracle/automation module with specific validation logic
- **Functions to Review**:
  - onReport
  - supportsInterface
  - _bytesToHexString
  - _decodeMetadata
  - _onReport (abstract)
  - setKeystoneForwarder
  - setWorkflow
  - removeWorkflow
  - getKeystoneForwarder
  - getWorkflow

### 11. Rebalancer.sol
- **Complexity**: Medium-High
- **Storage Slots**: 2 (s_parentPeer, s_strategyRegistry)
- **Function Calls**: 3-4 per function (parent peer and registry interactions)
- **Why Mid-Level**: Depends on CREReceiver and interacts with ParentPeer
- **Functions to Review**:
  - _onReport
  - setParentPeer
  - setStrategyRegistry
  - getParentPeer
  - getStrategyRegistry
  - getCurrentStrategy

## Priority Level 5: Token Contracts

### 12. Share.sol
- **Complexity**: Low-Medium
- **Storage Slots**: 1 (s_ccipAdmin) + inherited ERC677 state
- **Function Calls**: Inherited from BurnMintERC677
- **Why Mid-Level**: Core token with standard functionality
- **Functions to Review**:
  - setCCIPAdmin
  - getCCIPAdmin
  - mint (inherited)
  - burn (inherited)

### 13. SharePool.sol
- **Complexity**: Low
- **Storage Slots**: Inherited from BurnMintTokenPool
- **Function Calls**: Inherited
- **Why Mid-Level**: Simple CCIP token pool wrapper
- **Functions to Review**:
  - Constructor initialization

## Priority Level 6: Core Protocol - Base Abstract Contract

### 14. YieldPeer.sol (Abstract Base)
- **Complexity**: Very High
- **Storage Slots**: 9 (multiple mappings and state variables)
- **Function Calls**: 5-15+ per function (extensive cross-contract interactions)
- **Why Later**: Foundation for both Child and Parent, needs understanding of all lower-level contracts
- **Functions to Review in Order**:

#### 6a. View/Pure Helper Functions (Simplest)
  - _convertUsdcToShare
  - _convertShareToUsdc
  - _revertIfZeroAmount
  - _revertIfMsgSenderIsNotShare
  - _decodeDepositData
  - _decodeWithdrawData
  - _buildDepositData
  - _buildWithdrawData

#### 6b. Simple Getters
  - getThisChainSelector
  - getAllowedChain
  - getAllowedPeer
  - getLink
  - getUsdc
  - getShare
  - getIsStrategyChain
  - getCCIPGasLimit
  - getStrategyRegistry
  - getActiveStrategyAdapter
  - getStrategyAdapter

#### 6c. Setters
  - setAllowedChain
  - setAllowedPeer
  - setCCIPGasLimit
  - setStrategyRegistry

#### 6d. Internal Strategy Helpers
  - _getStrategyAdapterFromProtocol
  - _getActiveStrategyAdapter
  - _getTotalValueFromStrategy
  - _calculateWithdrawAmount
  - _decodeWithdrawChainSelector

#### 6e. Token Transfer Functions
  - _transferUsdcTo
  - _transferUsdcFrom
  - _mintShares
  - _burnShares

#### 6f. Strategy Interaction Functions
  - _depositToStrategy
  - _withdrawFromStrategy
  - _depositToStrategyAndGetTotalValue
  - _withdrawFromStrategyAndGetUsdcWithdrawAmount
  - _updateActiveStrategyAdapter

#### 6g. Deposit/Withdraw Initiation
  - _initiateDeposit
  - getTotalValue
  - _getTotalValue

#### 6h. CCIP Message Handling
  - _ccipSend
  - _ccipReceive
  - _handleCCIPWithdrawCallback
  - _handleCCIPRebalanceNewStrategy
  - _handleCCIPMessage (abstract)

#### 6i. Abstract Functions
  - deposit (abstract)
  - onTokenTransfer (abstract)

## Priority Level 7: Core Protocol - Child Peer

### 15. ChildPeer.sol
- **Complexity**: Very High
- **Storage Slots**: 1 additional (i_parentChainSelector) + all inherited from YieldPeer
- **Function Calls**: 10-20+ per function (complex cross-chain flows)
- **Why Second-to-Last**: Depends on YieldPeer and all strategy contracts
- **Functions to Review in Order**:

#### 7a. Simple Getter
  - getParentChainSelector

#### 7b. CCIP Message Handlers (from simplest to most complex)
  - _handleCCIPDepositCallbackChild (simple mint)
  - _handleCCIPWithdrawCallback (inherited, verify behavior)
  - _handleCCIPRebalanceNewStrategy (inherited, verify behavior)
  - _handleCCIPDepositToStrategy (medium complexity)
  - _handleCCIPWithdrawToStrategy (medium-high complexity)
  - _handleCCIPRebalanceOldStrategy (high complexity - handles both local and remote rebalance)

#### 7c. Main Entry Points
  - deposit (high complexity - two cases)
  - onTokenTransfer (high complexity - withdrawal flow)

#### 7d. Router
  - _handleCCIPMessage (routes to all handlers)

## Priority Level 8: Core Protocol - Parent Peer (Most Complex)

### 16. ParentPeer.sol
- **Complexity**: Extremely High
- **Storage Slots**: 4 additional (s_totalShares, s_strategy, s_rebalancer, s_initialActiveStrategySet) + all inherited
- **Function Calls**: 15-30+ per function (most complex cross-chain orchestration)
- **Why Last**: Depends on everything, manages global state, orchestrates entire system
- **Functions to Review in Order**:

#### 8a. Simple Getters
  - getStrategy
  - getTotalShares
  - getRebalancer

#### 8b. Setters
  - setRebalancer
  - setInitialActiveStrategy

#### 8c. View Functions
  - _calculateMintAmount

#### 8d. Rebalance Helpers (from simplest to most complex)
  - _rebalanceChildToOther (just forwards message)
  - _rebalanceParentToParent (local rebalance)
  - _rebalanceParentToChild (remote rebalance with funds)

#### 8e. Strategy Management
  - _setAndHandleStrategyChange (orchestrates rebalancing)
  - setStrategy (entry point for rebalancer)

#### 8f. CCIP Message Handlers (from simplest to most complex)
  - _handleCCIPWithdrawCallback (inherited, verify behavior)
  - _handleCCIPRebalanceNewStrategy (inherited, verify behavior)
  - _handleCCIPDepositCallbackParent (medium complexity)
  - _handleCCIPWithdrawPingPong (medium-high complexity)
  - _handleCCIPWithdraw (high complexity - shared withdraw logic)
  - _handleCCIPWithdrawToParent (high complexity - updates total shares)
  - _handleCCIPDepositToParent (very high complexity - multiple cases)

#### 8g. Main Entry Points
  - deposit (very high complexity - multiple cases with strategy check)
  - onTokenTransfer (very high complexity - withdrawal with strategy check)

#### 8h. Router
  - _handleCCIPMessage (routes to all handlers)

---

## Review Strategy Notes

### General Approach:
1. **Bottom-Up**: Start with libraries and simple modules that have no dependencies
2. **Interface Understanding**: Ensure you understand the interfaces before the implementations
3. **State Tracking**: Pay special attention to how state variables change as you move up the hierarchy
4. **Cross-Contract Invariants**: By the time you reach ChildPeer and ParentPeer, you should understand:
   - How s_totalShares is maintained globally
   - How deposits flow through the system
   - How withdrawals are calculated and executed
   - How rebalancing affects all components
   - How CCIP messages maintain consistency

### Key Invariants to Track:
1. **Total Shares Invariant**: s_totalShares on ParentPeer equals sum of all minted shares across all chains
2. **Value Conservation**: TVL should be conserved during rebalancing
3. **Share Value Consistency**: Share value should be consistent across all chains
4. **Fee Accounting**: Fees are properly collected and tracked
5. **Access Control**: Only authorized addresses can call privileged functions
6. **Pausing**: When paused, user-facing functions should revert
7. **CCIP Message Sequencing**: Message flows should maintain state consistency
8. **Strategy Adapter Correctness**: Active strategy adapter should match strategy state

### Function Complexity Metrics Used:
- **Storage Slots Read/Written**: More slots = higher complexity
- **External Calls**: More calls = higher complexity
- **Conditional Logic**: More branches = higher complexity
- **Cross-Contract Dependencies**: More contracts involved = higher complexity
- **State Changes**: More state mutations = higher risk

### Priority Rationale:
- **Priority 1-3**: Pure functions, simple state, isolated modules (can be verified independently)
- **Priority 4-5**: Governance and token modules (moderate dependencies)
- **Priority 6**: Base protocol logic (foundation for everything)
- **Priority 7-8**: Complex orchestration layers (require understanding of all lower levels)

By following this order, you build up knowledge progressively and can use simpler contracts to verify assumptions about more complex ones.
