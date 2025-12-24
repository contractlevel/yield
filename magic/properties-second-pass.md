# Properties Second Pass

## StrategyRegistry

### Spec Based Properties
- The function `setStrategyAdapter` should only be callable by the Owner
- The function `setStrategyAdapter` should emit `StrategyAdapterSet` event with the correct `protocolId` and `strategyAdapter`
- The function `getStrategyAdapter` should return the Strategy Adapter address for a given Protocol ID

### High Level Properties
- The mapping `s_strategyAdapters` should only be modified through `setStrategyAdapter`
- Setting a Strategy Adapter to `address(0)` should effectively deregister that Protocol

## YieldFees

### Spec Based Properties
- The function `setFeeRate` should revert if `newFeeRate` exceeds `MAX_FEE_RATE`
- The function `setFeeRate` should only be callable by an address with `FEE_RATE_SETTER_ROLE`
- The function `setFeeRate` should emit `FeeRateSet` event
- The function `withdrawFees` should only be callable by an address with `FEE_WITHDRAWER_ROLE`
- The function `withdrawFees` should revert if there are no Fees to withdraw
- The function `withdrawFees` should emit `FeesWithdrawn` event with the correct Fee Amount
- The initial Fee Rate should be set to `INITIAL_FEE_RATE` (1,000 = 0.1%)

### Variable Transitions
- The Fee Rate should never exceed `MAX_FEE_RATE` (10,000 = 1%)
- Calling `withdrawFees` should transfer all Fee Token balance to the caller
- The Fee calculation should follow the formula: `(amount * feeRate) / FEE_RATE_DIVISOR`

### High Level Properties
- The `s_feeRate` should only be modified through `setFeeRate`

## PausableWithAccessControl

### Spec Based Properties
- The function `emergencyPause` should only be callable by an address with `EMERGENCY_PAUSER_ROLE`
- The function `emergencyUnpause` should only be callable by an address with `EMERGENCY_UNPAUSER_ROLE`
- The function `emergencyPause` should set the contract to paused state
- The function `emergencyUnpause` should set the contract to unpaused state
- Granting a Role should add the address to `s_roleMembers[role]`
- Revoking a Role should remove the address from `s_roleMembers[role]`
- The function `getRoleMemberCount` should return the correct count of members for a Role
- The function `getRoleMember` should return the correct address at the given index for a Role

### State Transitions
- Only addresses with `EMERGENCY_PAUSER_ROLE` can trigger pause state transition
- Only addresses with `EMERGENCY_UNPAUSER_ROLE` can trigger unpause state transition

### High Level Properties
- The Role Members set for each Role should accurately reflect granted and revoked Roles

## StrategyAdapter

### Spec Based Properties
- All functions with `onlyYieldPeer` modifier should revert if `msg.sender` is not `i_yieldPeer`

### Access Control Properties
- Only the Yield Peer contract should be able to call `deposit` and `withdraw` functions on Strategy Adapters

## CompoundV3Adapter

### Spec Based Properties
- The function `deposit` should only be callable by the Yield Peer
- The function `deposit` should emit `Deposit` event with correct USDC address and Amount
- The function `deposit` should approve the Comet contract to spend USDC
- The function `deposit` should call `IComet.supply` with the correct USDC address and Amount
- The function `withdraw` should only be callable by the Yield Peer
- The function `withdraw` should emit `Withdraw` event with correct USDC address and Amount
- The function `withdraw` should call `IComet.withdraw` with the correct USDC address and Amount
- The function `withdraw` should transfer USDC to the Yield Peer
- The function `getTotalValue` should return the Comet balance of this contract
- The function `getStrategyPool` should return the Comet address

### Variable Transitions
- Calling `deposit` should increase the Comet balance of the adapter
- Calling `withdraw` should decrease the Comet balance of the adapter
- Calling `withdraw` should transfer USDC from the adapter to the Yield Peer

### High Level Properties
- The Total Value should equal the Comet balance of this adapter contract

## AaveV3Adapter

### Spec Based Properties
- The function `deposit` should only be callable by the Yield Peer
- The function `deposit` should emit `Deposit` event with correct USDC address and Amount
- The function `deposit` should approve the Aave Pool to spend USDC
- The function `deposit` should call `IPool.supply` with correct parameters
- The function `withdraw` should only be callable by the Yield Peer
- The function `withdraw` should emit `Withdraw` event with correct USDC address and Amount
- The function `withdraw` should revert if `withdrawnAmount` does not equal requested `amount`
- The function `withdraw` should transfer USDC to the Yield Peer
- The function `getTotalValue` should return the AToken balance of this contract
- The function `getPoolAddressesProvider` should return the Pool Addresses Provider
- The function `getStrategyPool` should return the Aave Pool address

### Variable Transitions
- Calling `deposit` should mint ATokens to the adapter
- Calling `withdraw` should burn ATokens from the adapter
- Calling `withdraw` should transfer USDC from the adapter to the Yield Peer

### High Level Properties
- The Total Value should equal the AToken balance of this adapter contract
- The Aave Pool address should be retrieved dynamically from the Pool Addresses Provider

## CREReceiver

### Spec Based Properties
- The function `onReport` should only accept calls from the Keystone Forwarder
- The function `onReport` should revert if `msg.sender` is not `s_keystoneForwarder`
- The function `onReport` should revert if the Workflow ID is not registered
- The function `onReport` should revert if the Workflow Owner does not match
- The function `onReport` should revert if the Workflow Name does not match
- The function `onReport` should emit `OnReportSecurityChecksPassed` event after validation
- The function `setKeystoneForwarder` should only be callable by the Owner
- The function `setKeystoneForwarder` should revert if setting to `address(0)`
- The function `setKeystoneForwarder` should emit `KeystoneForwarderSet` event
- The function `setWorkflow` should only be callable by the Owner
- The function `setWorkflow` should revert if `workflowId` is `bytes32(0)`
- The function `setWorkflow` should revert if `workflowOwner` is `address(0)`
- The function `setWorkflow` should revert if `workflowName` is empty
- The function `setWorkflow` should emit `WorkflowSet` event
- The function `removeWorkflow` should only be callable by the Owner
- The function `removeWorkflow` should emit `WorkflowRemoved` event
- The function `removeWorkflow` should delete the Workflow from `s_workflows`
- The function `supportsInterface` should return `true` for `IReceiver` interface

### Doomsday Checks
- A malicious Keystone Forwarder should never be able to call `onReport`
- A Workflow with mismatched metadata should never pass validation

### High Level Properties
- Only registered Workflows with matching ID, Owner, and Name should pass validation
- The Workflow Name encoding should follow Chainlink CRE guidelines (SHA256 hash -> hex encode -> first 10 chars)

## Rebalancer

### Spec Based Properties
- The function `_onReport` should decode the report into a Strategy struct
- The function `_onReport` should check if Chain Selector is allowed in Parent Peer
- The function `_onReport` should emit `InvalidChainSelectorInReport` if Chain Selector not allowed
- The function `_onReport` should check if Protocol ID exists in Strategy Registry
- The function `_onReport` should emit `InvalidProtocolIdInReport` if Protocol Adapter is `address(0)`
- The function `_onReport` should emit `ReportDecoded` if validation passes
- The function `_onReport` should call `IParentPeer.setStrategy` with new Strategy
- The function `setParentPeer` should only be callable by the Owner
- The function `setParentPeer` should revert if setting to `address(0)`
- The function `setParentPeer` should emit `ParentPeerSet` event
- The function `setStrategyRegistry` should only be callable by the Owner
- The function `setStrategyRegistry` should revert if setting to `address(0)`
- The function `setStrategyRegistry` should emit `StrategyRegistrySet` event
- The function `getCurrentStrategy` should return the current Strategy from Parent Peer

### Valid States
- A valid CRE Report should contain a Strategy with an allowed Chain Selector
- A valid CRE Report should contain a Strategy with a registered Protocol ID

### High Level Properties
- Only the Keystone Forwarder should trigger strategy updates via `onReport`
- Invalid Chain Selectors and Protocol IDs should not cause reverts, but should emit events and return early

## Share

### Spec Based Properties
- The function `setCCIPAdmin` should only be callable by the Owner
- The function `setCCIPAdmin` should emit `CCIPAdminTransferred` event
- The function `setCCIPAdmin` should update `s_ccipAdmin` to the new Admin
- The function `getCCIPAdmin` should return the current CCIP Admin
- The function `mint` should only be callable by addresses with `MINTER_ROLE`
- The function `mint` should increase the Total Supply
- The function `mint` should increase the recipient's balance
- The function `burn` should only be callable by addresses with `BURNER_ROLE`
- The function `burn` should decrease the Total Supply
- The function `burn` should decrease the sender's balance
- The token should be named "YieldCoin"
- The token symbol should be "YIELD"
- The token decimals should be `18`

### Variable Transitions
- Minting Shares should increase Total Supply by the mint Amount
- Burning Shares should decrease Total Supply by the burn Amount
- Only addresses with `MINTER_ROLE` can increase the Total Supply
- Only addresses with `BURNER_ROLE` can decrease the Total Supply

### High Level Properties
- The Total Supply should equal the sum of all balances across all addresses
- The CCIP Admin can only be changed by the Owner

## YieldPeer

### Spec Based Properties
- The function `deposit` should revert if `amountToDeposit` is less than `1e6` (1 USDC)
- The function `deposit` should revert if the contract is paused
- The function `onTokenTransfer` should revert if `msg.sender` is not the Share token
- The function `onTokenTransfer` should revert if `shareBurnAmount` is `0`
- The function `onTokenTransfer` should revert if the contract is paused
- The function `_ccipReceive` should revert if the source Chain Selector is not allowed
- The function `_ccipReceive` should revert if the sender is not an allowed Peer
- The function `_ccipReceive` should emit `CCIPMessageReceived` event
- The function `_ccipSend` should emit `CCIPMessageSent` event
- The function `_ccipSend` should revert if insufficient LINK balance for Fees
- The function `_initiateDeposit` should revert if `amountToDeposit` is less than `USDC_DECIMALS`
- The function `_initiateDeposit` should transfer USDC from depositor to the contract
- The function `_initiateDeposit` should calculate and take a Fee if `s_feeRate` is non-zero
- The function `_initiateDeposit` should emit `FeeTaken` if Fee is greater than `0`
- The function `_initiateDeposit` should emit `DepositInitiated` event
- The function `_depositToStrategy` should emit `DepositToStrategy` event
- The function `_depositToStrategy` should transfer USDC to the Strategy Adapter
- The function `_depositToStrategy` should call `IStrategyAdapter.deposit`
- The function `_withdrawFromStrategy` should emit `WithdrawFromStrategy` event
- The function `_withdrawFromStrategy` should call `IStrategyAdapter.withdraw`
- The function `_mintShares` should emit `SharesMinted` event
- The function `_mintShares` should call `IShare.mint`
- The function `_burnShares` should emit `SharesBurned` event
- The function `_burnShares` should call `IShare.burn`
- The function `_handleCCIPWithdrawCallback` should validate Token Amounts
- The function `_handleCCIPWithdrawCallback` should transfer USDC to the withdrawer
- The function `_handleCCIPWithdrawCallback` should emit `WithdrawCompleted` event
- The function `_handleCCIPRebalanceNewStrategy` should update the Active Strategy Adapter
- The function `_handleCCIPRebalanceNewStrategy` should deposit to the new Strategy if Token Amounts exist
- The function `_updateActiveStrategyAdapter` should set `s_activeStrategyAdapter` to the new adapter if on this chain
- The function `_updateActiveStrategyAdapter` should set `s_activeStrategyAdapter` to `address(0)` if on different chain
- The function `_updateActiveStrategyAdapter` should emit `ActiveStrategyAdapterUpdated` event
- The function `setAllowedChain` should only be callable by addresses with `CROSS_CHAIN_ADMIN_ROLE`
- The function `setAllowedChain` should emit `AllowedChainSet` event
- The function `setAllowedPeer` should only be callable by addresses with `CROSS_CHAIN_ADMIN_ROLE`
- The function `setAllowedPeer` should revert if Chain Selector is not allowed
- The function `setAllowedPeer` should emit `AllowedPeerSet` event
- The function `setCCIPGasLimit` should only be callable by addresses with `CROSS_CHAIN_ADMIN_ROLE`
- The function `setCCIPGasLimit` should emit `CCIPGasLimitSet` event
- The function `setStrategyRegistry` should only be callable by addresses with `CONFIG_ADMIN_ROLE`
- The function `setStrategyRegistry` should emit `StrategyRegistrySet` event
- The function `getTotalValue` should revert if this chain is not the Strategy Chain
- The function `_decodeWithdrawChainSelector` should revert if the decoded Chain Selector is not allowed
- The function `_decodeWithdrawChainSelector` should default to `i_thisChainSelector` if data is empty

### Variable Transitions
- Depositing to Strategy should increase the Total Value in the Strategy
- Withdrawing from Strategy should decrease the Total Value in the Strategy
- Minting Shares should increase the Share balance of the recipient
- Burning Shares should decrease the Share balance of the sender
- Setting an Allowed Chain should update `s_allowedChains[chainSelector]`
- Setting an Allowed Peer should update `s_peers[chainSelector]`

### High Level Properties
- The Active Strategy Adapter should be `address(0)` when the Strategy is on a different chain
- The Active Strategy Adapter should be non-zero when the Strategy is on this chain
- Only allowed Chain Selectors can send CCIP messages to this Peer
- Only allowed Peers can send CCIP messages for their respective Chain Selectors

### Doomsday Checks
- A User should never be able to deposit less than 1 USDC
- A CCIP message from an unauthorized chain should never be processed
- A CCIP message from an unauthorized Peer should never be processed
- The contract should never process User operations when paused

### DOS Invariants
- Depositing should never permanently lock User funds
- Withdrawing should always be possible if the User has sufficient Shares
- CCIP messages should always be processable when properly formatted and authorized

## ChildPeer

### Spec Based Properties
- The function `deposit` should revert if the contract is paused
- The function `deposit` should handle Case 1: This Child is the Strategy
- The function `deposit` should handle Case 2: This Child is not the Strategy
- Case 1: The function `deposit` should deposit to Strategy and get Total Value
- Case 1: The function `deposit` should send `DepositCallbackParent` message to Parent
- Case 2: The function `deposit` should send `DepositToParent` message with USDC
- The function `onTokenTransfer` should revert if the contract is paused
- The function `onTokenTransfer` should revert if `msg.sender` is not the Share token
- The function `onTokenTransfer` should revert if `shareBurnAmount` is `0`
- The function `onTokenTransfer` should burn Shares
- The function `onTokenTransfer` should send `WithdrawToParent` message
- The function `onTokenTransfer` should emit `WithdrawInitiated` event
- The function `_handleCCIPDepositToStrategy` should validate Token Amounts
- The function `_handleCCIPDepositToStrategy` should deposit to Strategy if Active Strategy Adapter exists
- The function `_handleCCIPDepositToStrategy` should ping-pong back to Parent if no Active Strategy Adapter
- The function `_handleCCIPDepositToStrategy` should emit `DepositPingPongToParent` for ping-pong case
- The function `_handleCCIPDepositCallbackChild` should mint Shares to the depositor
- The function `_handleCCIPWithdrawToStrategy` should withdraw from Strategy if Active Strategy Adapter exists
- The function `_handleCCIPWithdrawToStrategy` should transfer USDC directly if withdraw Chain equals this Chain
- The function `_handleCCIPWithdrawToStrategy` should send USDC via CCIP if withdraw Chain differs
- The function `_handleCCIPWithdrawToStrategy` should ping-pong back to Parent if no Active Strategy Adapter
- The function `_handleCCIPWithdrawToStrategy` should emit `WithdrawPingPongToParent` for ping-pong case
- The function `_handleCCIPWithdrawToStrategy` should emit `WithdrawCompleted` if completing on this chain
- The function `_handleCCIPRebalanceOldStrategy` should withdraw from old Strategy Adapter
- The function `_handleCCIPRebalanceOldStrategy` should deposit to new Strategy Adapter if on same chain
- The function `_handleCCIPRebalanceOldStrategy` should send USDC via CCIP if new Strategy on different chain
- The function `_handleCCIPRebalanceOldStrategy` should send `RebalanceNewStrategy` message with USDC
- The function `getParentChainSelector` should return `i_parentChainSelector`

### State Transitions
- Deposit flow when Child is Strategy: Deposit -> Strategy -> Parent Callback -> Mint Shares
- Deposit flow when Child is not Strategy: Deposit -> Parent (forward)
- Withdraw flow: Burn Shares -> Parent -> Strategy (or ping-pong)
- Rebalance flow from this chain: Old Strategy Withdraw -> New Strategy Deposit or CCIP Send

### Variable Transitions
- Depositing should transfer USDC from User to Child (if not Strategy) or to Strategy (if Strategy)
- Withdrawing should burn Shares from the User
- Rebalancing should move all USDC from old Strategy to new Strategy

### High Level Properties
- The Parent Chain Selector should be immutable and set at deployment
- All deposits must route through the Parent for share calculation
- All withdrawals must route through the Parent for Total Shares tracking
- Ping-pong scenarios should handle temporary Strategy unavailability

### Doomsday Checks
- A User depositing on a Child should always receive Shares (eventually via callback)
- A User withdrawing on a Child should always receive USDC on their chosen chain
- Rebalancing should never lose USDC in transit

## ParentPeer

### Spec Based Properties
- The function `deposit` should revert if the contract is paused
- The function `deposit` should handle Case 1: This Parent is the Strategy
- The function `deposit` should handle Case 2: This Parent is not the Strategy
- Case 1: The function `deposit` should revert with `ParentPeer__InactiveStrategyAdapter` if Active Strategy Adapter is `address(0)`
- Case 1: The function `deposit` should get Total Value from Strategy
- Case 1: The function `deposit` should calculate Share Mint Amount
- Case 1: The function `deposit` should update `s_totalShares`
- Case 1: The function `deposit` should emit `ShareMintUpdate` event
- Case 1: The function `deposit` should deposit to Strategy
- Case 1: The function `deposit` should mint Shares to depositor
- Case 2: The function `deposit` should emit `DepositForwardedToStrategy` event
- Case 2: The function `deposit` should send `DepositToStrategy` message with USDC
- The function `onTokenTransfer` should revert if the contract is paused
- The function `onTokenTransfer` should revert if `msg.sender` is not the Share token
- The function `onTokenTransfer` should revert if `shareBurnAmount` is `0`
- The function `onTokenTransfer` should update `s_totalShares` by subtracting `shareBurnAmount`
- The function `onTokenTransfer` should emit `ShareBurnUpdate` event
- The function `onTokenTransfer` should emit `WithdrawInitiated` event
- The function `onTokenTransfer` should burn Shares
- Case 1: The function `onTokenTransfer` should revert with `ParentPeer__InactiveStrategyAdapter` if Active Strategy Adapter is `address(0)`
- Case 1: The function `onTokenTransfer` should calculate USDC Withdraw Amount
- Case 1: The function `onTokenTransfer` should withdraw from Strategy if USDC Amount is non-zero
- Case 1: The function `onTokenTransfer` should transfer USDC directly if withdraw Chain equals this Chain
- Case 1: The function `onTokenTransfer` should send USDC via CCIP if withdraw Chain differs
- Case 1: The function `onTokenTransfer` should emit `WithdrawCompleted` if completing on this chain
- Case 2: The function `onTokenTransfer` should send `WithdrawToStrategy` message
- The function `_handleCCIPDepositToParent` should validate Token Amounts
- The function `_handleCCIPDepositToParent` should handle deposit when Parent is Strategy
- The function `_handleCCIPDepositToParent` should handle deposit when Parent is not Strategy
- The function `_handleCCIPDepositToParent` should emit `DepositPingPongToChild` if Active Strategy Adapter is `address(0)`
- The function `_handleCCIPDepositToParent` should forward deposit to Strategy if not on Parent
- The function `_handleCCIPDepositToParent` should emit `DepositForwardedToStrategy` when forwarding
- The function `_handleCCIPDepositCallbackParent` should calculate Share Mint Amount
- The function `_handleCCIPDepositCallbackParent` should update `s_totalShares`
- The function `_handleCCIPDepositCallbackParent` should emit `ShareMintUpdate` event
- The function `_handleCCIPDepositCallbackParent` should mint Shares if deposit was on Parent
- The function `_handleCCIPDepositCallbackParent` should send callback to Child if deposit was on Child
- The function `_handleCCIPWithdrawToParent` should update `s_totalShares` by subtracting `shareBurnAmount`
- The function `_handleCCIPWithdrawToParent` should emit `ShareBurnUpdate` event
- The function `_handleCCIPWithdrawToParent` should call `_handleCCIPWithdraw` to process withdrawal
- The function `_handleCCIPWithdraw` should withdraw from Strategy if Parent is Strategy
- The function `_handleCCIPWithdraw` should emit `WithdrawPingPongToChild` if Active Strategy Adapter is `address(0)`
- The function `_handleCCIPWithdraw` should forward to Strategy if Parent is not Strategy
- The function `_handleCCIPWithdraw` should emit `WithdrawForwardedToStrategy` when forwarding
- The function `_handleCCIPWithdrawPingPong` should process withdrawal without updating state
- The function `setStrategy` should revert if `msg.sender` is not the Rebalancer
- The function `setStrategy` should call `_setAndHandleStrategyChange`
- The function `_setAndHandleStrategyChange` should emit `CurrentStrategyOptimal` if Strategy unchanged
- The function `_setAndHandleStrategyChange` should return early if Strategy unchanged
- The function `_setAndHandleStrategyChange` should update `s_strategy`
- The function `_setAndHandleStrategyChange` should emit `StrategyUpdated` event
- The function `_setAndHandleStrategyChange` should call `_rebalanceParentToParent` for local rebalance
- The function `_setAndHandleStrategyChange` should call `_rebalanceParentToChild` for Parent to Child rebalance
- The function `_setAndHandleStrategyChange` should call `_rebalanceChildToOther` for Child to Other rebalance
- The function `_rebalanceParentToParent` should withdraw from old Strategy
- The function `_rebalanceParentToParent` should deposit to new Strategy
- The function `_rebalanceParentToChild` should withdraw from old Strategy
- The function `_rebalanceParentToChild` should send `RebalanceNewStrategy` message with USDC
- The function `_rebalanceChildToOther` should send `RebalanceOldStrategy` message
- The function `_calculateMintAmount` should return `amount * INITIAL_SHARE_PRECISION` if Total Shares is `0`
- The function `_calculateMintAmount` should return at least `1` if calculation yields `0`
- The function `_calculateMintAmount` should use formula: `(convertedAmount * totalShares) / convertedTotalValue` otherwise
- The function `setInitialActiveStrategy` should only be callable by `DEFAULT_ADMIN_ROLE`
- The function `setInitialActiveStrategy` should revert if already set
- The function `setInitialActiveStrategy` should set `s_initialActiveStrategySet` to `true`
- The function `setInitialActiveStrategy` should set `s_strategy` with this Chain Selector
- The function `setInitialActiveStrategy` should update Active Strategy Adapter
- The function `setRebalancer` should only be callable by `CONFIG_ADMIN_ROLE`
- The function `setRebalancer` should emit `RebalancerSet` event
- The function `getStrategy` should return the current Strategy
- The function `getTotalShares` should return `s_totalShares`
- The function `getRebalancer` should return `s_rebalancer`

### State Transitions
- Rebalancing from Parent to Parent: Withdraw from Old -> Update State -> Deposit to New
- Rebalancing from Parent to Child: Withdraw from Old -> Update State -> CCIP Send to New
- Rebalancing from Child to Other: Send CCIP message to Old Child -> Old Child handles rest
- Deposit with ping-pong: Child -> Parent (forward) -> Parent ping-pong back -> retry
- Withdraw with ping-pong: Withdraw start -> Parent (forward) -> ping-pong back -> retry

### Variable Transitions
- The `s_totalShares` should increase when Shares are minted
- The `s_totalShares` should decrease when Shares are burned
- The `s_strategy` should only change via `setStrategy` or `setInitialActiveStrategy`
- Rebalancing should move all TVL from old Strategy to new Strategy without loss

### High Level Properties
- The `s_totalShares` should equal the sum of all Share balances across all chains
- The `s_totalShares` should equal `ghost_totalSharesMinted - ghost_totalSharesBurned`
- The Parent should be the single source of truth for Total Shares
- The Parent should be the single source of truth for the current Strategy
- Only the Rebalancer can trigger Strategy changes via `setStrategy`
- The Initial Active Strategy can only be set once by the Admin
- Strategy changes should preserve Total Value (TVL)

### Doomsday Checks
- A User depositing on Parent should never receive `0` Shares
- A User withdrawing on Parent should receive USDC proportional to their Share burn
- Rebalancing should never result in loss of TVL
- The `s_totalShares` should never become negative
- The `s_totalShares` should never exceed the actual sum of Share balances

### DOS Invariants
- Deposits should always be processable when not paused
- Withdrawals should always be processable when not paused
- Ping-pong should always eventually complete when Strategy becomes available
- Rebalancing should never permanently block deposits or withdrawals

### Dust Invariants
- Withdrawing all Shares should withdraw proportional USDC (no dust left in Strategy)
- The Share Mint Amount should never be `0` (enforced minimum of `1`)
