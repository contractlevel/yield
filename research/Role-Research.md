# YieldCoin Roles
- George Gorzhiyev

## Overview and Challenge
Thinking of custom and granular roles to avoid centralization around using only "onlyOwner". The challenge is to break it up into roles that make sense.

## What does Chainlink use for access control?
Chainlink contracts, across the board, use `onlyOwner` with an Ownable2StepMsger as an implementation. Occasional deviations like token pool admin checks and an "admin", but generally, including various settings, it is `onlyOwner`. It functions as a sort of "system admin" on each contract.

Roles seem to come more into play with their Payment Abstraction system, which is used to collect fees for Chainlink services, send them to a "parent" chain, where a swap automator will swap them on Uniswap V3 for LINK and then send the LINK to a reserve contract for people to withdraw from.

The roles work as both restricting the contract that could call it and the user. There appears to be multiple addresses of each type of role.

## Consideration of roles for YieldCoin
### Where we need roles (as a baseline)
* Admin role, that can grant/revoke roles and be a possible contract owner
* Config setters, both cross-chain and general system ones
* System pauser/unpausers in case of emergency
* Roles around fees, both to set a system fee for deposits and for withdrawing fees from Peers
### What those roles will be
* DEFAULT_ADMIN_ROLE 
* CONFIG_ADMIN_ROLE, CROSS_CHAIN_ADMIN_ROLE
* EMERGENCY_PAUSER_ROLE, EMERGENCY_UNPAUSER_ROLE
* FEE_RATE_ADJUSTER_ROLE, FEE_WITHDRAWER_ROLE
### Any other important considerations
* Emergency withdraw role for withdrawing the TVL funds from a protocol in case of YieldCoin compromise.

* An asset admin role to allow adding/removing new stablecoins as well as adjusting TVL swap parameters. Although this depends on how adjustable these params will be, as in, will it be governed by a DAO or just an admin?

* UPDATE: Probably not needed. - Dust collector role that can go to protocols and withdraw any dust leftover from rebalancing latency that may have accrued APY. Depending on how often swaps/rebalancing happens, there may be a protocol  that sits with leftover TVL dust that accrues a chunk.

* Depending on how swapping is done, may need a swapper role.

### How many usages of onlyOwner in YieldCoin?
#### (14) - as of Oct 16, 2025

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

`setInitialActiveStrategy` - in *peers/ParentPeer.sol* probably needs to stay as onlyOwner so when system is deployed by owner it can be used to set a strategy immediately too. Since it's a one time call, no point in making a special role for it.

