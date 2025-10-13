# Research for new YieldCoin system roles
- George Gorzhiyev

## Overview
How many usages of onlyOwner in YieldCoin?
14 (as of Oct 13, 2025)
---
-> 4 in modules/Rebalancer.sol

-> 1 in modules/StrategyRegistry.sol

-> 2 in modules/YieldFees.sol

-> 2 in peers/ParentPeer.sol

-> 4 in peers/YieldPeer.sol

-> 1 in token/Share.sol

## Deeper look 
-> 4 in modules/Rebalancer.sol

    ```solidity
    setUpkeepAddress(address upkeepAddress) external onlyOwner {} /// @notice Set the Chainlink Automation upkeep address
    setForwarder(address forwarder) external onlyOwner {} /// @notice Sets the Chainlink Automation forwarder
    setParentPeer(address parentPeer) external onlyOwner {} /// @notice Sets the ParentPeer contract address
    setStrategyRegistry(address strategyRegistry) external onlyOwner {} /// @notice Sets the strategy registry
    ```

-> 1 in modules/StrategyRegistry.sol

    ```solidity
    setStrategyAdapter(bytes32 protocolId, address strategyAdapter) external onlyOwner {} /// @notice Setter for registering and deregistering a strategy adapter
    ```

-> 2 in modules/YieldFees.sol

    ```solidity
    withdrawFees(address feeToken) external onlyOwner {} /// @notice Withdraws the fees
    setFeeRate(uint256 newFeeRate) external onlyOwner {} /// @notice Sets the fee rate
    ```

-> 2 in peers/ParentPeer.sol

    ```solidity
    setInitialActiveStrategy(bytes32 protocolId) external onlyOwner {} /// @notice Sets the initial active strategy
    setRebalancer(address rebalancer) external onlyOwner {} /// @notice Sets the rebalancer (address)
    ```

-> 4 in peers/YieldPeer.sol

    ```solidity
    setAllowedChain(uint64 chainSelector, bool isAllowed) external onlyOwner {} /// @notice Set chains that are allowed to send CCIP messages to this peer
    setAllowedPeer(uint64 chainSelector, address peer) external onlyOwner {} /// @notice Set the peer contract for an allowed chain selector
    setCCIPGasLimit(uint256 gasLimit) external onlyOwner {} /// @notice Set the CCIP gas limit
    setStrategyRegistry(address strategyRegistry) external onlyOwner {} /// @notice Set the strategy registry (address)
    ```

-> 1 in token/Share.sol

    ```solidity
    setCCIPAdmin(address newAd) external onlyOwner {} /// @notice Transfers the CCIPAdmin role to a new address
    ```


Patterns (according to AI)

1. **Integration/Configuration Setters** *(e.g., setUpkeepAddress, setForwarder, setParentPeer, setStrategyRegistry, setRebalancer, setCCIPGasLimit)*: 
These update addresses or params for external services (Chainlink Automation, CCIP) or internal dependencies. High-risk if misused, as they could redirect funds or break integrations.

2. **Strategy Management** *(e.g., setStrategyAdapter, setInitialActiveStrategy)*: 
Controls protocol strategies, which likely affect yield generation or rebalancing. Needs separation to allow specialized oversight without full admin access.

3. **Fee Management** *(e.g., withdrawFees, setFeeRate)*: 
Handles economic parameters and withdrawals. Often isolated to prevent unauthorized drains.

4. **CCIP-Specific Controls** *(e.g., setAllowedChain, setAllowedPeer, setCCIPAdmin*): 
Manages cross-chain messaging security. Aligns with Chainlink's emphasis on secure CCIP configs.
