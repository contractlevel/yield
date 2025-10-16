# Research for new YieldCoin system roles
- George Gorzhiyev

## Overview and Challenge
Thinking of custom and granular roles to avoid centralization around using only "onlyOwner". The challenge is to break it up into roles that make sense, group tasks but not make so many roles it gets confusing and ridiculous.

### How many usages of onlyOwner in YieldCoin?
#### (14) - as of Oct 13, 2025

--> (4) in modules/Rebalancer.sol

--> (1) in modules/StrategyRegistry.sol

--> (2) in modules/YieldFees.sol

--> (2) in peers/ParentPeer.sol

--> (4) in peers/YieldPeer.sol

--> (1) in token/Share.sol

## Deeper Look 
--> (4) in modules/Rebalancer.sol
```solidity
    setUpkeepAddress(address upkeepAddress) external onlyOwner {} /// @notice Set the Chainlink Automation upkeep address
    setForwarder(address forwarder) external onlyOwner {} /// @notice Sets the Chainlink Automation forwarder
    setParentPeer(address parentPeer) external onlyOwner {} /// @notice Sets the ParentPeer contract address
    setStrategyRegistry(address strategyRegistry) external onlyOwner {} /// @notice Sets the strategy registry
```

--> (1) in modules/StrategyRegistry.sol
```solidity
    setStrategyAdapter(bytes32 protocolId, address strategyAdapter) external onlyOwner {} /// @notice Setter for registering and deregistering a strategy adapter
```

--> (2) in modules/YieldFees.sol
```solidity
    withdrawFees(address feeToken) external onlyOwner {} /// @notice Withdraws the fees
    setFeeRate(uint256 newFeeRate) external onlyOwner {} /// @notice Sets the fee rate
```

--> (2) in peers/ParentPeer.sol
```solidity
    setInitialActiveStrategy(bytes32 protocolId) external onlyOwner {} /// @notice Sets the initial active strategy
    setRebalancer(address rebalancer) external onlyOwner {} /// @notice Sets the rebalancer (address)
```

--> (4) in peers/YieldPeer.sol
```solidity
    setAllowedChain(uint64 chainSelector, bool isAllowed) external onlyOwner {} /// @notice Set chains that are allowed to send CCIP messages to this peer
    setAllowedPeer(uint64 chainSelector, address peer) external onlyOwner {} /// @notice Set the peer contract for an allowed chain selector
    setCCIPGasLimit(uint256 gasLimit) external onlyOwner {} /// @notice Set the CCIP gas limit
    setStrategyRegistry(address strategyRegistry) external onlyOwner {} /// @notice Set the strategy registry (address)
```

--> (1) in token/Share.sol
```solidity
    setCCIPAdmin(address newAd) external onlyOwner {} /// @notice Transfers the CCIPAdmin role to a new address
```

## Patterns (according to AI - Grok)
1. **Integration/Configuration Setters** *(e.g., setUpkeepAddress, setForwarder, setParentPeer, setStrategyRegistry, setRebalancer, setCCIPGasLimit)*: 
These update addresses or params for external services (Chainlink Automation, CCIP) or internal dependencies. High-risk if misused, as they could redirect funds or break integrations.

2. **Strategy Management** *(e.g., setStrategyAdapter, setInitialActiveStrategy)*: 
Controls protocol strategies, which likely affect yield generation or rebalancing. Needs separation to allow specialized oversight without full admin access.

3. **Fee Management** *(e.g., withdrawFees, setFeeRate)*: 
Handles economic parameters and withdrawals. Often isolated to prevent unauthorized drains.

4. **CCIP-Specific Controls** *(e.g., setAllowedChain, setAllowedPeer, setCCIPAdmin*): 
Manages cross-chain messaging security. Aligns with Chainlink's emphasis on secure CCIP configs.

## Thoughts & Brainstorming

<u>*ROUGH first Ideas for roles as system is currently:*</u>

`setInitialActiveStrategy` - in *peers/ParentPeer.sol* probably needs to stay as onlyOwner so when system is deployed by owner it can be used to set a strategy immediately too. Since it's a one time call, no point in making a special role for it.

* **Integration Management / System Admin Role**
    * `setUpkeepAddress`, `setForwarder`, `setParentPeer`, `setStrategyRegistry` - in *modules/Rebalancer.sol*
    * `setRebalancer` - in *peers/ParentPeer.sol*
    * `setStrategyRegistry` - in *peers/YieldPeer.sol*
    * A general 'system admin' role to set various addresses of protocol contracts. Is this managing too much?
    * Could possibly not have `setStrategyRegistry` and Strategy Management Role could handle that.
* **Strategy Management Role**
    * `setStrategyAdapter` - in *modules/StrategyRegistry.sol*
    * Manages adding new strategy adapters on each chains strategy registers.
    * Could also alternatively handle `setStrategyRegistry` on Rebalancer/Peers if a new Strategy Registry is deployed and function more of an admin for Strategys as a whole.
    * Could possibly also handle `setFeeRate` as a sort of 'financial manager' that does new strategy adapters and fees for the system.
* **Fee Management Role / Fee Withdrawer Role**
    * `withdrawFees`, `setFeeRate` - both in *modules/YieldFees.sol*
    * Role for withdrawing fees and setting the system fee rate. Alternatively, `setFeeRate` could be grouped with Strategy Management Role and this serve as a system fee withdrawer.
* **Cross-Chain Management Role**
    * `setCCIPAdmin` - in *token/Share.sol* ?? - maybe onlyOwner/Role Admin instead
    * `setAllowedChain`, `setAllowedPeer`, `setCCIPGasLimit` - in *peers/YieldPeer.sol*
    * Role to manage cross chain variables by setting ccip gas limits on each peer as well as allowed chains and peers. If/as new cross chain protocols are integrated, this role could handle those tasks.

<br>

<u>*ROUGH Ideas for roles based on new features:*</u>

* **Role Admin**
    * Role administrator for granting/removing roles from users. Probably needed if doing role based access control.
* **System Pauser Role** 
    * Pausing/unpausing the system in case of emergency. More necessary when/if Pausing is integrated.
* **Dust Collector Role** 
    * Possible 'janitorial' role that goes to protocols and checks if theres dust and collects it, this could even be a contract that checks all protocols in system for any value and withdraws it etc.
    * Perhaps the Fee Manager/Withdrawer could could this.
* **Swapper Role**
    * Specific role for swapping the TVL when rebalancing. Maybe this is redundant as this would be handled somewhere by the Rebalancer maybe?

## Other Resources
Chainlink Pausable with Access Control
https://github.com/code-423n4/2024-12-chainlink/blob/main/src/PausableWithAccessControl.sol

Chainlink Payment Abstraction Roles Library
https://github.com/code-423n4/2024-12-chainlink/blob/main/src/libraries/Roles.sol

## Must Haves (based on conversations)
    * EMERGENCY_PAUSER
    * CROSSCHAIN_ADMIN or CROSSCHAIN_SETTER
    * FEES_WITHDRAWER
    * Set fees different from fees withdrawer
    * Setter roles, possibly leave as onlyOwner
    * DEFAULT_ADMIN or ROLES_ADMIN

## What is Chainlink doing?
    * CCIP
        * Lots of "onlyOwner" use, no specific role other than for CCT token admin but otherwise "setters" are onlyOwner
        * LOTS of ownable2StepMessenger
        * Cross chain stuff like removing/add offRamps and such is still onlyOwner
        * Fee withdrawal has no access control but sends to a desginated fee aggregator contract on each chain (I think)
    * FeeQuoter
        * onlyOwner!
    * Workflow Registry
        * All the setters are onlyOwner!
    * DataFeeds
        * A fee admin for setting configs

    * Payment Abstraction
        * It's for Chainlink to collect payments for chainlink services
        * Contracts to take payment and use swaps to convert things to LINK
        *

    Roles seem more prominently used in Payment Abstraction and Fee Aggregation. 
    General system contract stuff all across Chainlink just heavily uses onlyOwner other than limit things to specific contracts which can call etc.

    Fee Aggregator contract is where Chainlink fees for services are sent to and from there the swapping and such happens.