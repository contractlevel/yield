# Contract Dependencies Analysis

## AaveV3Adapter.sol
### deposit
Storage Slots Read:
- i_yieldPeer (immutable)
- i_aavePoolAddressesProvider (immutable)

Storage Slots Written:
- None (only external contract state)

Calls:
- _getAavePool
- _approveToken
- IPool(aavePool).supply

is called by:
- YieldPeer._depositToStrategy (via IStrategyAdapter interface)

### withdraw
Storage Slots Read:
- i_yieldPeer (immutable)
- i_aavePoolAddressesProvider (immutable)

Storage Slots Written:
- None (only external contract state)

Calls:
- _getAavePool
- IPool(aavePool).withdraw
- _transferTokenTo

is called by:
- YieldPeer._withdrawFromStrategy (via IStrategyAdapter interface)

### getTotalValue
Storage Slots Read:
- i_aavePoolAddressesProvider (immutable)

Storage Slots Written:
- None

Calls:
- _getAavePool
- IPool(aavePool).getReserveData
- IERC20(aTokenAddress).balanceOf

is called by:
- YieldPeer._getTotalValueFromStrategy (via IStrategyAdapter interface)

### getPoolAddressesProvider
Storage Slots Read:
- i_aavePoolAddressesProvider (immutable)

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

### getStrategyPool
Storage Slots Read:
- i_aavePoolAddressesProvider (immutable)

Storage Slots Written:
- None

Calls:
- IPoolAddressesProvider(i_aavePoolAddressesProvider).getPool

is called by:
- External callers

### _getAavePool
Storage Slots Read:
- i_aavePoolAddressesProvider (immutable)

Storage Slots Written:
- None

Calls:
- IPoolAddressesProvider(i_aavePoolAddressesProvider).getPool

is called by:
- deposit
- withdraw
- getTotalValue

---

## CompoundV3Adapter.sol
### deposit
Storage Slots Read:
- i_yieldPeer (immutable)
- i_comet (immutable)

Storage Slots Written:
- None (only external contract state)

Calls:
- _approveToken
- IComet(i_comet).supply

is called by:
- YieldPeer._depositToStrategy (via IStrategyAdapter interface)

### withdraw
Storage Slots Read:
- i_yieldPeer (immutable)
- i_comet (immutable)

Storage Slots Written:
- None (only external contract state)

Calls:
- IComet(i_comet).withdraw
- _transferTokenTo

is called by:
- YieldPeer._withdrawFromStrategy (via IStrategyAdapter interface)

### getTotalValue
Storage Slots Read:
- i_comet (immutable)

Storage Slots Written:
- None

Calls:
- IComet(i_comet).balanceOf

is called by:
- YieldPeer._getTotalValueFromStrategy (via IStrategyAdapter interface)

### getStrategyPool
Storage Slots Read:
- i_comet (immutable)

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

---

## StrategyAdapter.sol (Abstract)
### _transferTokenTo
Storage Slots Read:
- None

Storage Slots Written:
- None (only token state)

Calls:
- IERC20(token).safeTransfer

is called by:
- AaveV3Adapter.withdraw
- CompoundV3Adapter.withdraw

### _approveToken
Storage Slots Read:
- None

Storage Slots Written:
- None (only token state)

Calls:
- IERC20(token).safeIncreaseAllowance

is called by:
- AaveV3Adapter.deposit
- CompoundV3Adapter.deposit

---

## StrategyRegistry.sol
### setStrategyAdapter
Storage Slots Read:
- None

Storage Slots Written:
- s_strategyAdapters[protocolId]

Calls:
- None

is called by:
- External admin (owner)

### getStrategyAdapter
Storage Slots Read:
- s_strategyAdapters[protocolId]

Storage Slots Written:
- None

Calls:
- None

is called by:
- YieldPeer._getStrategyAdapterFromProtocol
- Rebalancer._onReport

---

## YieldFees.sol (Abstract)
### withdrawFees
Storage Slots Read:
- s_feeRate (indirectly, via balance check)

Storage Slots Written:
- None (only token state)

Calls:
- IERC20(feeToken).balanceOf
- IERC20(feeToken).safeTransfer

is called by:
- External role holder (FEE_WITHDRAWER_ROLE)

### _calculateFee
Storage Slots Read:
- s_feeRate

Storage Slots Written:
- None

Calls:
- None

is called by:
- YieldPeer._initiateDeposit

### setFeeRate
Storage Slots Read:
- None

Storage Slots Written:
- s_feeRate

Calls:
- None

is called by:
- External role holder (FEE_RATE_SETTER_ROLE)

### getFeeRate
Storage Slots Read:
- s_feeRate

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

### getFeeRateDivisor
Storage Slots Read:
- None

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

### getMaxFeeRate
Storage Slots Read:
- None

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

---

## PausableWithAccessControl.sol (Abstract)
### emergencyPause
Storage Slots Read:
- s_roleMembers[EMERGENCY_PAUSER_ROLE] (via modifier)

Storage Slots Written:
- _paused (from Pausable)

Calls:
- _pause

is called by:
- External role holder (EMERGENCY_PAUSER_ROLE)

### emergencyUnpause
Storage Slots Read:
- s_roleMembers[EMERGENCY_UNPAUSER_ROLE] (via modifier)

Storage Slots Written:
- _paused (from Pausable)

Calls:
- _unpause

is called by:
- External role holder (EMERGENCY_UNPAUSER_ROLE)

### _grantRole
Storage Slots Read:
- None (reads from parent via super)

Storage Slots Written:
- s_roleMembers[role]

Calls:
- super._grantRole
- s_roleMembers[role].add

is called by:
- AccessControlDefaultAdminRules functions

### _revokeRole
Storage Slots Read:
- None (reads from parent via super)

Storage Slots Written:
- s_roleMembers[role]

Calls:
- super._revokeRole
- s_roleMembers[role].remove

is called by:
- AccessControlDefaultAdminRules functions

### getRoleMember
Storage Slots Read:
- s_roleMembers[role]

Storage Slots Written:
- None

Calls:
- s_roleMembers[role].at

is called by:
- External callers

### getRoleMemberCount
Storage Slots Read:
- s_roleMembers[role]

Storage Slots Written:
- None

Calls:
- s_roleMembers[role].length

is called by:
- External callers

### getRoleMembers
Storage Slots Read:
- s_roleMembers[role]

Storage Slots Written:
- None

Calls:
- s_roleMembers[role].values

is called by:
- External callers

---

## CREReceiver.sol (Abstract)
### onReport
Storage Slots Read:
- s_keystoneForwarder
- s_workflows[decodedId]

Storage Slots Written:
- None

Calls:
- _decodeMetadata
- _onReport

is called by:
- Chainlink Keystone Forwarder

### supportsInterface
Storage Slots Read:
- None

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

### _bytesToHexString
Storage Slots Read:
- None

Storage Slots Written:
- None

Calls:
- None

is called by:
- setWorkflow

### _decodeMetadata
Storage Slots Read:
- None

Storage Slots Written:
- None

Calls:
- None (assembly)

is called by:
- onReport

### _onReport
Storage Slots Read:
- None (abstract)

Storage Slots Written:
- None (abstract)

Calls:
- None (abstract, implemented by Rebalancer)

is called by:
- onReport

### setKeystoneForwarder
Storage Slots Read:
- None

Storage Slots Written:
- s_keystoneForwarder

Calls:
- None

is called by:
- External owner

### setWorkflow
Storage Slots Read:
- None

Storage Slots Written:
- s_workflows[workflowId]

Calls:
- _bytesToHexString

is called by:
- External owner

### removeWorkflow
Storage Slots Read:
- s_workflows[workflowId]

Storage Slots Written:
- s_workflows[workflowId] (delete)

Calls:
- None

is called by:
- External owner

### getKeystoneForwarder
Storage Slots Read:
- s_keystoneForwarder

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

### getWorkflow
Storage Slots Read:
- s_workflows[workflowId]

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

---

## Rebalancer.sol
### _onReport
Storage Slots Read:
- s_parentPeer
- s_strategyRegistry

Storage Slots Written:
- None

Calls:
- IParentPeer(s_parentPeer).getAllowedChain
- IStrategyRegistry(s_strategyRegistry).getStrategyAdapter
- IParentPeer(s_parentPeer).setStrategy

is called by:
- CREReceiver.onReport

### setParentPeer
Storage Slots Read:
- None

Storage Slots Written:
- s_parentPeer

Calls:
- None

is called by:
- External owner

### setStrategyRegistry
Storage Slots Read:
- None

Storage Slots Written:
- s_strategyRegistry

Calls:
- None

is called by:
- External owner

### getParentPeer
Storage Slots Read:
- s_parentPeer

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

### getStrategyRegistry
Storage Slots Read:
- s_strategyRegistry

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

### getCurrentStrategy
Storage Slots Read:
- s_parentPeer

Storage Slots Written:
- None

Calls:
- IParentPeer(s_parentPeer).getStrategy

is called by:
- External callers (for CRE)

---

## YieldPeer.sol (Abstract)
### deposit
Storage Slots Read:
- None (abstract)

Storage Slots Written:
- None (abstract)

Calls:
- None (abstract, implemented by ChildPeer and ParentPeer)

is called by:
- External users

### onTokenTransfer
Storage Slots Read:
- None (abstract)

Storage Slots Written:
- None (abstract)

Calls:
- None (abstract, implemented by ChildPeer and ParentPeer)

is called by:
- Share token via transferAndCall

### _ccipReceive
Storage Slots Read:
- s_allowedChains[sourceChainSelector]
- s_peers[sourceChainSelector]

Storage Slots Written:
- None

Calls:
- _handleCCIPMessage

is called by:
- CCIP Router

### _handleCCIPMessage
Storage Slots Read:
- None (abstract)

Storage Slots Written:
- None (abstract)

Calls:
- None (abstract, implemented by ChildPeer and ParentPeer)

is called by:
- _ccipReceive

### _ccipSend
Storage Slots Read:
- s_peers[destChainSelector]
- s_ccipGasLimit
- i_usdc (immutable)
- i_link (immutable)
- i_ccipRouter (immutable)

Storage Slots Written:
- None (only token allowances)

Calls:
- CCIPOperations._prepareTokenAmounts
- CCIPOperations._buildCCIPMessage
- CCIPOperations._handleCCIPFees
- IRouterClient(i_ccipRouter).ccipSend

is called by:
- ChildPeer.deposit
- ChildPeer.onTokenTransfer
- ChildPeer._handleCCIPDepositToStrategy
- ChildPeer._handleCCIPWithdrawToStrategy
- ChildPeer._handleCCIPRebalanceOldStrategy
- ParentPeer.deposit
- ParentPeer.onTokenTransfer
- ParentPeer._handleCCIPDepositToParent
- ParentPeer._handleCCIPDepositCallbackParent
- ParentPeer._handleCCIPWithdraw
- ParentPeer._handleCCIPWithdrawPingPong
- ParentPeer._rebalanceParentToChild
- ParentPeer._rebalanceChildToOther

### _handleCCIPWithdrawCallback
Storage Slots Read:
- i_usdc (immutable)

Storage Slots Written:
- None

Calls:
- _decodeWithdrawData
- CCIPOperations._validateTokenAmounts
- _transferUsdcTo

is called by:
- ChildPeer._handleCCIPMessage
- ParentPeer._handleCCIPMessage

### _handleCCIPRebalanceNewStrategy
Storage Slots Read:
- s_strategyRegistry
- s_activeStrategyAdapter
- i_thisChainSelector (immutable)

Storage Slots Written:
- s_activeStrategyAdapter

Calls:
- _updateActiveStrategyAdapter
- _depositToStrategy

is called by:
- ChildPeer._handleCCIPMessage
- ParentPeer._handleCCIPMessage

### _updateActiveStrategyAdapter
Storage Slots Read:
- i_thisChainSelector (immutable)
- s_strategyRegistry

Storage Slots Written:
- s_activeStrategyAdapter

Calls:
- _getStrategyAdapterFromProtocol

is called by:
- _handleCCIPRebalanceNewStrategy
- ChildPeer._handleCCIPRebalanceOldStrategy
- ParentPeer._rebalanceParentToParent
- ParentPeer._rebalanceParentToChild
- ParentPeer.setInitialActiveStrategy

### _depositToStrategy
Storage Slots Read:
- i_usdc (immutable)

Storage Slots Written:
- None (only token state)

Calls:
- _transferUsdcTo
- IStrategyAdapter(strategyAdapter).deposit

is called by:
- _handleCCIPRebalanceNewStrategy
- ChildPeer._handleCCIPRebalanceOldStrategy
- ParentPeer.deposit
- ParentPeer._handleCCIPDepositToParent
- ParentPeer._rebalanceParentToParent

### _withdrawFromStrategy
Storage Slots Read:
- i_usdc (immutable)

Storage Slots Written:
- None

Calls:
- IStrategyAdapter(strategyAdapter).withdraw

is called by:
- ChildPeer._handleCCIPRebalanceOldStrategy
- ParentPeer.onTokenTransfer
- ParentPeer._handleCCIPWithdraw
- ParentPeer._rebalanceParentToParent
- ParentPeer._rebalanceParentToChild
- YieldPeer._withdrawFromStrategyAndGetUsdcWithdrawAmount

### _depositToStrategyAndGetTotalValue
Storage Slots Read:
- i_usdc (immutable)

Storage Slots Written:
- None

Calls:
- _getTotalValueFromStrategy
- _depositToStrategy

is called by:
- ChildPeer.deposit
- ChildPeer._handleCCIPDepositToStrategy

### _withdrawFromStrategyAndGetUsdcWithdrawAmount
Storage Slots Read:
- i_usdc (immutable)

Storage Slots Written:
- None

Calls:
- _getTotalValueFromStrategy
- _calculateWithdrawAmount
- _withdrawFromStrategy

is called by:
- ChildPeer._handleCCIPWithdrawToStrategy
- ParentPeer._handleCCIPWithdraw

### _initiateDeposit
Storage Slots Read:
- s_feeRate (via _calculateFee)
- i_usdc (immutable)
- i_thisChainSelector (immutable)

Storage Slots Written:
- None (only token state)

Calls:
- _transferUsdcFrom
- _calculateFee

is called by:
- ChildPeer.deposit
- ParentPeer.deposit

### _transferUsdcTo
Storage Slots Read:
- i_usdc (immutable)

Storage Slots Written:
- None (only token state)

Calls:
- i_usdc.safeTransfer

is called by:
- _depositToStrategy
- _transferUsdcFrom
- _handleCCIPWithdrawCallback
- ChildPeer._handleCCIPWithdrawToStrategy
- ParentPeer.onTokenTransfer

### _transferUsdcFrom
Storage Slots Read:
- i_usdc (immutable)

Storage Slots Written:
- None (only token state)

Calls:
- i_usdc.safeTransferFrom

is called by:
- _initiateDeposit

### _mintShares
Storage Slots Read:
- i_share (immutable)

Storage Slots Written:
- None (only token state)

Calls:
- i_share.mint

is called by:
- ChildPeer._handleCCIPDepositCallbackChild
- ParentPeer.deposit
- ParentPeer._handleCCIPDepositCallbackParent

### _burnShares
Storage Slots Read:
- i_share (immutable)

Storage Slots Written:
- None (only token state)

Calls:
- i_share.burn

is called by:
- ChildPeer.onTokenTransfer
- ParentPeer.onTokenTransfer

### _decodeWithdrawChainSelector
Storage Slots Read:
- s_allowedChains[withdrawChainSelector]
- i_thisChainSelector (immutable)

Storage Slots Written:
- None

Calls:
- None

is called by:
- ChildPeer.onTokenTransfer
- ParentPeer.onTokenTransfer

### _buildDepositData
Storage Slots Read:
- i_thisChainSelector (immutable)

Storage Slots Written:
- None

Calls:
- DataStructures.buildDepositData

is called by:
- ChildPeer.deposit
- ParentPeer.deposit

### _buildWithdrawData
Storage Slots Read:
- None

Storage Slots Written:
- None

Calls:
- DataStructures.buildWithdrawData

is called by:
- ChildPeer.onTokenTransfer
- ParentPeer.onTokenTransfer

### _getTotalValueFromStrategy
Storage Slots Read:
- None

Storage Slots Written:
- None

Calls:
- IStrategyAdapter(strategyAdapter).getTotalValue

is called by:
- _depositToStrategyAndGetTotalValue
- _withdrawFromStrategyAndGetUsdcWithdrawAmount
- ChildPeer._handleCCIPRebalanceOldStrategy
- ParentPeer.deposit
- ParentPeer.onTokenTransfer
- ParentPeer._handleCCIPDepositToParent
- ParentPeer._rebalanceParentToParent
- ParentPeer._rebalanceParentToChild
- YieldPeer._getTotalValue

### _getStrategyAdapterFromProtocol
Storage Slots Read:
- s_strategyRegistry

Storage Slots Written:
- None

Calls:
- IStrategyRegistry(s_strategyRegistry).getStrategyAdapter

is called by:
- _updateActiveStrategyAdapter

### _getActiveStrategyAdapter
Storage Slots Read:
- s_activeStrategyAdapter

Storage Slots Written:
- None

Calls:
- None

is called by:
- ChildPeer.deposit
- ChildPeer._handleCCIPDepositToStrategy
- ChildPeer._handleCCIPWithdrawToStrategy
- ChildPeer._handleCCIPRebalanceOldStrategy
- ParentPeer.deposit
- ParentPeer.onTokenTransfer
- ParentPeer._handleCCIPDepositToParent
- ParentPeer._handleCCIPWithdraw
- ParentPeer._rebalanceParentToParent
- ParentPeer._rebalanceParentToChild
- YieldPeer._getTotalValue

### _calculateWithdrawAmount
Storage Slots Read:
- None

Storage Slots Written:
- None

Calls:
- _convertUsdcToShare
- _convertShareToUsdc

is called by:
- _withdrawFromStrategyAndGetUsdcWithdrawAmount
- ParentPeer.onTokenTransfer

### _convertUsdcToShare
Storage Slots Read:
- None

Storage Slots Written:
- None

Calls:
- None

is called by:
- _calculateWithdrawAmount
- ParentPeer._calculateMintAmount

### _convertShareToUsdc
Storage Slots Read:
- None

Storage Slots Written:
- None

Calls:
- None

is called by:
- _calculateWithdrawAmount

### _revertIfZeroAmount
Storage Slots Read:
- None

Storage Slots Written:
- None

Calls:
- None

is called by:
- ChildPeer.onTokenTransfer
- ParentPeer.onTokenTransfer

### _revertIfMsgSenderIsNotShare
Storage Slots Read:
- i_share (immutable)

Storage Slots Written:
- None

Calls:
- None

is called by:
- ChildPeer.onTokenTransfer
- ParentPeer.onTokenTransfer

### _decodeDepositData
Storage Slots Read:
- None

Storage Slots Written:
- None

Calls:
- None

is called by:
- ChildPeer._handleCCIPDepositToStrategy
- ChildPeer._handleCCIPDepositCallbackChild
- ParentPeer._handleCCIPDepositCallbackParent

### _decodeWithdrawData
Storage Slots Read:
- None

Storage Slots Written:
- None

Calls:
- None

is called by:
- _handleCCIPWithdrawCallback
- ChildPeer._handleCCIPWithdrawToStrategy
- ParentPeer._handleCCIPWithdrawToParent
- ParentPeer._handleCCIPWithdrawPingPong

### _getTotalValue
Storage Slots Read:
- s_activeStrategyAdapter
- i_usdc (immutable)

Storage Slots Written:
- None

Calls:
- _getActiveStrategyAdapter
- _getTotalValueFromStrategy

is called by:
- YieldPeer.getTotalValue

### setAllowedChain
Storage Slots Read:
- s_roleMembers[CROSS_CHAIN_ADMIN_ROLE] (via modifier)

Storage Slots Written:
- s_allowedChains[chainSelector]

Calls:
- None

is called by:
- External role holder (CROSS_CHAIN_ADMIN_ROLE)

### setAllowedPeer
Storage Slots Read:
- s_roleMembers[CROSS_CHAIN_ADMIN_ROLE] (via modifier)
- s_allowedChains[chainSelector]

Storage Slots Written:
- s_peers[chainSelector]

Calls:
- None

is called by:
- External role holder (CROSS_CHAIN_ADMIN_ROLE)

### setCCIPGasLimit
Storage Slots Read:
- s_roleMembers[CROSS_CHAIN_ADMIN_ROLE] (via modifier)

Storage Slots Written:
- s_ccipGasLimit

Calls:
- None

is called by:
- External role holder (CROSS_CHAIN_ADMIN_ROLE)

### setStrategyRegistry
Storage Slots Read:
- s_roleMembers[CONFIG_ADMIN_ROLE] (via modifier)

Storage Slots Written:
- s_strategyRegistry

Calls:
- None

is called by:
- External role holder (CONFIG_ADMIN_ROLE)

### getThisChainSelector
Storage Slots Read:
- i_thisChainSelector (immutable)

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

### getAllowedChain
Storage Slots Read:
- s_allowedChains[chainSelector]

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers
- Rebalancer._onReport

### getAllowedPeer
Storage Slots Read:
- s_peers[chainSelector]

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

### getLink
Storage Slots Read:
- i_link (immutable)

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

### getUsdc
Storage Slots Read:
- i_usdc (immutable)

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

### getShare
Storage Slots Read:
- i_share (immutable)

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

### getIsStrategyChain
Storage Slots Read:
- s_activeStrategyAdapter

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

### getCCIPGasLimit
Storage Slots Read:
- s_ccipGasLimit

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

### getTotalValue
Storage Slots Read:
- s_activeStrategyAdapter
- i_usdc (immutable)

Storage Slots Written:
- None

Calls:
- _getTotalValue

is called by:
- External callers

### getStrategyAdapter
Storage Slots Read:
- s_strategyRegistry

Storage Slots Written:
- None

Calls:
- _getStrategyAdapterFromProtocol

is called by:
- External callers

### getActiveStrategyAdapter
Storage Slots Read:
- s_activeStrategyAdapter

Storage Slots Written:
- None

Calls:
- _getActiveStrategyAdapter

is called by:
- External callers

### getStrategyRegistry
Storage Slots Read:
- s_strategyRegistry

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

---

## ChildPeer.sol
### deposit
Storage Slots Read:
- s_feeRate (via _initiateDeposit)
- s_activeStrategyAdapter
- s_strategyRegistry (via _getActiveStrategyAdapter)
- i_usdc (immutable)
- i_thisChainSelector (immutable)
- i_parentChainSelector (immutable)
- s_peers[i_parentChainSelector]
- s_ccipGasLimit
- i_link (immutable)
- i_ccipRouter (immutable)
- _paused (from Pausable)

Storage Slots Written:
- None (only token state)

Calls:
- _initiateDeposit
- _getActiveStrategyAdapter
- _buildDepositData
- _depositToStrategyAndGetTotalValue
- _ccipSend

is called by:
- External users

### onTokenTransfer
Storage Slots Read:
- i_share (immutable)
- s_allowedChains[withdrawChainSelector]
- i_thisChainSelector (immutable)
- i_parentChainSelector (immutable)
- s_peers[i_parentChainSelector]
- s_ccipGasLimit
- i_link (immutable)
- i_ccipRouter (immutable)
- _paused (from Pausable)

Storage Slots Written:
- None (only token state)

Calls:
- _revertIfMsgSenderIsNotShare
- _revertIfZeroAmount
- _burnShares
- _buildWithdrawData
- _decodeWithdrawChainSelector
- _ccipSend

is called by:
- Share token via transferAndCall

### _handleCCIPMessage
Storage Slots Read:
- s_activeStrategyAdapter
- s_strategyRegistry (via various calls)
- i_usdc (immutable)
- i_share (immutable)
- i_thisChainSelector (immutable)
- i_parentChainSelector (immutable)
- s_peers (via _ccipSend calls)
- s_ccipGasLimit (via _ccipSend calls)
- i_link (immutable)
- i_ccipRouter (immutable)

Storage Slots Written:
- s_activeStrategyAdapter (via _updateActiveStrategyAdapter)

Calls:
- _handleCCIPDepositToStrategy
- _handleCCIPDepositCallbackChild
- _handleCCIPWithdrawToStrategy
- _handleCCIPWithdrawCallback
- _handleCCIPRebalanceOldStrategy
- _handleCCIPRebalanceNewStrategy

is called by:
- YieldPeer._ccipReceive

### _handleCCIPDepositToStrategy
Storage Slots Read:
- s_activeStrategyAdapter
- i_usdc (immutable)
- i_parentChainSelector (immutable)
- s_peers[i_parentChainSelector]
- s_ccipGasLimit
- i_link (immutable)
- i_ccipRouter (immutable)

Storage Slots Written:
- None

Calls:
- _decodeDepositData
- CCIPOperations._validateTokenAmounts
- _getActiveStrategyAdapter
- _depositToStrategyAndGetTotalValue
- _ccipSend

is called by:
- _handleCCIPMessage

### _handleCCIPDepositCallbackChild
Storage Slots Read:
- i_share (immutable)

Storage Slots Written:
- None (only token state)

Calls:
- _decodeDepositData
- _mintShares

is called by:
- _handleCCIPMessage

### _handleCCIPWithdrawToStrategy
Storage Slots Read:
- s_activeStrategyAdapter
- i_usdc (immutable)
- i_thisChainSelector (immutable)
- s_peers[withdrawData.chainSelector or i_parentChainSelector]
- s_ccipGasLimit
- i_link (immutable)
- i_ccipRouter (immutable)

Storage Slots Written:
- None

Calls:
- _decodeWithdrawData
- _getActiveStrategyAdapter
- _withdrawFromStrategyAndGetUsdcWithdrawAmount
- _transferUsdcTo
- _ccipSend

is called by:
- _handleCCIPMessage

### _handleCCIPRebalanceOldStrategy
Storage Slots Read:
- s_activeStrategyAdapter
- s_strategyRegistry
- i_usdc (immutable)
- i_thisChainSelector (immutable)
- s_peers[newStrategy.chainSelector]
- s_ccipGasLimit
- i_link (immutable)
- i_ccipRouter (immutable)

Storage Slots Written:
- s_activeStrategyAdapter

Calls:
- _getActiveStrategyAdapter
- _updateActiveStrategyAdapter
- _getTotalValueFromStrategy
- _withdrawFromStrategy
- _depositToStrategy
- _ccipSend

is called by:
- _handleCCIPMessage

### getParentChainSelector
Storage Slots Read:
- i_parentChainSelector (immutable)

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

---

## ParentPeer.sol
### deposit
Storage Slots Read:
- s_feeRate (via _initiateDeposit)
- s_strategy
- i_thisChainSelector (immutable)
- s_activeStrategyAdapter
- s_totalShares
- i_usdc (immutable)
- i_share (immutable)
- s_peers[strategy.chainSelector]
- s_ccipGasLimit
- i_link (immutable)
- i_ccipRouter (immutable)
- _paused (from Pausable)

Storage Slots Written:
- s_totalShares

Calls:
- _initiateDeposit
- _getActiveStrategyAdapter
- _getTotalValueFromStrategy
- _calculateMintAmount
- _depositToStrategy
- _mintShares
- _buildDepositData
- _ccipSend

is called by:
- External users

### onTokenTransfer
Storage Slots Read:
- i_share (immutable)
- s_allowedChains[withdrawChainSelector]
- i_thisChainSelector (immutable)
- s_totalShares
- s_strategy
- s_activeStrategyAdapter
- i_usdc (immutable)
- s_peers[strategy.chainSelector or withdrawChainSelector]
- s_ccipGasLimit
- i_link (immutable)
- i_ccipRouter (immutable)
- _paused (from Pausable)

Storage Slots Written:
- s_totalShares

Calls:
- _revertIfMsgSenderIsNotShare
- _revertIfZeroAmount
- _decodeWithdrawChainSelector
- _burnShares
- _getActiveStrategyAdapter
- _getTotalValueFromStrategy
- _calculateWithdrawAmount
- _withdrawFromStrategy
- _transferUsdcTo
- _buildWithdrawData
- _ccipSend

is called by:
- Share token via transferAndCall

### _handleCCIPMessage
Storage Slots Read:
- s_strategy
- s_activeStrategyAdapter
- s_totalShares
- s_strategyRegistry
- i_usdc (immutable)
- i_thisChainSelector (immutable)
- i_share (immutable)
- s_peers (via various _ccipSend calls)
- s_ccipGasLimit (via _ccipSend calls)
- i_link (immutable)
- i_ccipRouter (immutable)

Storage Slots Written:
- s_totalShares (via various handlers)
- s_activeStrategyAdapter (via _handleCCIPRebalanceNewStrategy)

Calls:
- _handleCCIPDepositToParent
- _handleCCIPDepositCallbackParent
- _handleCCIPWithdrawToParent
- _handleCCIPWithdrawPingPong
- _handleCCIPWithdrawCallback
- _handleCCIPRebalanceNewStrategy

is called by:
- YieldPeer._ccipReceive

### _handleCCIPDepositToParent
Storage Slots Read:
- s_strategy
- i_usdc (immutable)
- i_thisChainSelector (immutable)
- s_activeStrategyAdapter
- s_totalShares
- i_share (immutable)
- s_peers[depositData.chainSelector or strategy.chainSelector]
- s_ccipGasLimit
- i_link (immutable)
- i_ccipRouter (immutable)

Storage Slots Written:
- s_totalShares

Calls:
- CCIPOperations._validateTokenAmounts
- _getActiveStrategyAdapter
- _getTotalValueFromStrategy
- _calculateMintAmount
- _depositToStrategy
- _ccipSend

is called by:
- _handleCCIPMessage

### _handleCCIPDepositCallbackParent
Storage Slots Read:
- s_totalShares
- i_thisChainSelector (immutable)
- i_share (immutable)
- s_peers[depositData.chainSelector]
- s_ccipGasLimit
- i_link (immutable)
- i_ccipRouter (immutable)

Storage Slots Written:
- s_totalShares

Calls:
- _decodeDepositData
- _calculateMintAmount
- _mintShares
- _ccipSend

is called by:
- _handleCCIPMessage

### _handleCCIPWithdrawToParent
Storage Slots Read:
- s_totalShares
- s_strategy
- s_activeStrategyAdapter
- i_usdc (immutable)
- i_thisChainSelector (immutable)
- s_peers[withdrawData.chainSelector or strategy.chainSelector]
- s_ccipGasLimit
- i_link (immutable)
- i_ccipRouter (immutable)

Storage Slots Written:
- s_totalShares

Calls:
- _decodeWithdrawData
- _handleCCIPWithdraw

is called by:
- _handleCCIPMessage

### _handleCCIPWithdraw
Storage Slots Read:
- s_activeStrategyAdapter
- i_usdc (immutable)
- i_thisChainSelector (immutable)
- s_peers[withdrawData.chainSelector or strategy.chainSelector]
- s_ccipGasLimit
- i_link (immutable)
- i_ccipRouter (immutable)

Storage Slots Written:
- None

Calls:
- _getActiveStrategyAdapter
- _withdrawFromStrategyAndGetUsdcWithdrawAmount
- _transferUsdcTo
- _ccipSend

is called by:
- _handleCCIPWithdrawToParent
- _handleCCIPWithdrawPingPong

### _handleCCIPWithdrawPingPong
Storage Slots Read:
- s_strategy
- s_activeStrategyAdapter
- i_usdc (immutable)
- i_thisChainSelector (immutable)
- s_peers[withdrawData.chainSelector or strategy.chainSelector]
- s_ccipGasLimit
- i_link (immutable)
- i_ccipRouter (immutable)

Storage Slots Written:
- None

Calls:
- _decodeWithdrawData
- _handleCCIPWithdraw

is called by:
- _handleCCIPMessage

### _setAndHandleStrategyChange
Storage Slots Read:
- s_strategy
- i_thisChainSelector (immutable)
- s_activeStrategyAdapter
- s_strategyRegistry
- i_usdc (immutable)
- s_peers[oldChainSelector or newStrategy.chainSelector]
- s_ccipGasLimit
- i_link (immutable)
- i_ccipRouter (immutable)

Storage Slots Written:
- s_strategy
- s_activeStrategyAdapter (via rebalance functions)

Calls:
- _rebalanceParentToParent
- _rebalanceParentToChild
- _rebalanceChildToOther

is called by:
- setStrategy

### _rebalanceParentToParent
Storage Slots Read:
- s_activeStrategyAdapter
- s_strategyRegistry
- i_usdc (immutable)
- i_thisChainSelector (immutable)

Storage Slots Written:
- s_activeStrategyAdapter

Calls:
- _getActiveStrategyAdapter
- _updateActiveStrategyAdapter
- _getTotalValueFromStrategy
- _withdrawFromStrategy
- _depositToStrategy

is called by:
- _setAndHandleStrategyChange

### _rebalanceParentToChild
Storage Slots Read:
- s_activeStrategyAdapter
- s_strategyRegistry
- i_usdc (immutable)
- i_thisChainSelector (immutable)
- s_peers[newStrategy.chainSelector]
- s_ccipGasLimit
- i_link (immutable)
- i_ccipRouter (immutable)

Storage Slots Written:
- s_activeStrategyAdapter

Calls:
- _getActiveStrategyAdapter
- _getTotalValueFromStrategy
- _updateActiveStrategyAdapter
- _withdrawFromStrategy
- _ccipSend

is called by:
- _setAndHandleStrategyChange

### _rebalanceChildToOther
Storage Slots Read:
- s_peers[oldChainSelector]
- s_ccipGasLimit
- i_link (immutable)
- i_ccipRouter (immutable)

Storage Slots Written:
- None

Calls:
- _ccipSend

is called by:
- _setAndHandleStrategyChange

### _calculateMintAmount
Storage Slots Read:
- s_totalShares

Storage Slots Written:
- None

Calls:
- _convertUsdcToShare

is called by:
- ParentPeer.deposit
- ParentPeer._handleCCIPDepositToParent
- ParentPeer._handleCCIPDepositCallbackParent

### setStrategy
Storage Slots Read:
- s_rebalancer
- s_strategy
- i_thisChainSelector (immutable)
- s_activeStrategyAdapter
- s_strategyRegistry
- i_usdc (immutable)
- s_peers (via rebalance functions)
- s_ccipGasLimit (via rebalance functions)
- i_link (immutable)
- i_ccipRouter (immutable)

Storage Slots Written:
- s_strategy
- s_activeStrategyAdapter (via rebalance functions)

Calls:
- _setAndHandleStrategyChange

is called by:
- Rebalancer._onReport

### setInitialActiveStrategy
Storage Slots Read:
- s_roleMembers[DEFAULT_ADMIN_ROLE] (via modifier)
- s_initialActiveStrategySet
- i_thisChainSelector (immutable)
- s_strategyRegistry

Storage Slots Written:
- s_initialActiveStrategySet
- s_strategy
- s_activeStrategyAdapter

Calls:
- _updateActiveStrategyAdapter

is called by:
- External admin (DEFAULT_ADMIN_ROLE)

### setRebalancer
Storage Slots Read:
- s_roleMembers[CONFIG_ADMIN_ROLE] (via modifier)

Storage Slots Written:
- s_rebalancer

Calls:
- None

is called by:
- External role holder (CONFIG_ADMIN_ROLE)

### getStrategy
Storage Slots Read:
- s_strategy

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers
- Rebalancer.getCurrentStrategy

### getTotalShares
Storage Slots Read:
- s_totalShares

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

### getRebalancer
Storage Slots Read:
- s_rebalancer

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

---

## Share.sol
### setCCIPAdmin
Storage Slots Read:
- s_ccipAdmin

Storage Slots Written:
- s_ccipAdmin

Calls:
- None

is called by:
- External owner

### getCCIPAdmin
Storage Slots Read:
- s_ccipAdmin

Storage Slots Written:
- None

Calls:
- None

is called by:
- External callers

### mint
Storage Slots Read:
- s_roleMembers[MINTER_ROLE] (from BurnMintERC677)

Storage Slots Written:
- balances (from ERC20)
- totalSupply (from ERC20)

Calls:
- None (inherited from BurnMintERC677)

is called by:
- YieldPeer._mintShares

### burn
Storage Slots Read:
- s_roleMembers[BURNER_ROLE] (from BurnMintERC677)

Storage Slots Written:
- balances (from ERC20)
- totalSupply (from ERC20)

Calls:
- None (inherited from BurnMintERC677)

is called by:
- YieldPeer._burnShares

---

## SharePool.sol
No additional functions beyond BurnMintTokenPool

---

## CCIPOperations.sol (Library)
### _buildCCIPMessage
Storage Slots Read:
- None (pure function)

Storage Slots Written:
- None

Calls:
- Client._argsToBytes

is called by:
- YieldPeer._ccipSend

### _handleCCIPFees
Storage Slots Read:
- None (token balances)

Storage Slots Written:
- None (only token allowances)

Calls:
- IRouterClient(ccipRouter).getFee
- LinkTokenInterface(link).balanceOf
- IERC20(link).safeIncreaseAllowance

is called by:
- YieldPeer._ccipSend

### _prepareTokenAmounts
Storage Slots Read:
- None

Storage Slots Written:
- None (only token allowances)

Calls:
- usdc.safeIncreaseAllowance

is called by:
- YieldPeer._ccipSend

### _validateTokenAmounts
Storage Slots Read:
- None (pure function)

Storage Slots Written:
- None

Calls:
- None

is called by:
- YieldPeer._handleCCIPWithdrawCallback
- ChildPeer._handleCCIPDepositToStrategy
- ParentPeer._handleCCIPDepositToParent

---

## DataStructures.sol (Library)
### buildDepositData
Storage Slots Read:
- None (pure function)

Storage Slots Written:
- None

Calls:
- None

is called by:
- YieldPeer._buildDepositData

### buildWithdrawData
Storage Slots Read:
- None (pure function)

Storage Slots Written:
- None

Calls:
- None

is called by:
- YieldPeer._buildWithdrawData

---

## Roles.sol (Library)
No functions (only constants)
