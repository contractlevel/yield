# YieldCoin aka Contract Level Yield (CLY)

This project has been built for the Chainlink Chromion Hackathon, and is an automated, crosschain, stablecoin yield optimizer, powered by Chainlink Automation, Functions, and CCIP.

Whatever the highest yield is for stablecoins across chains is what users can earn in one click with Contract Level Yield (YieldCoin).

A live demo site with Ethereum, Base and Avalanche testnets is available at [contractlevel.com](https://contractlevel.com).

## Table of Contents

- [YieldCoin aka Contract Level Yield (CLY)](#yieldcoin-aka-contract-level-yield-cly)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [YieldCoin](#yieldcoin)
  - [Strategy](#strategy)
  - [Contracts/Architecture](#contractsarchitecture)
    - [YieldPeer](#yieldpeer)
      - [IYieldPeer Interface](#iyieldpeer-interface)
      - [Libraries](#libraries)
    - [ParentPeer](#parentpeer)
    - [ChildPeer](#childpeer)
  - [System Actors](#system-actors)
  - [Chainlink Integrations](#chainlink-integrations)
    - [Chainlink Automation](#chainlink-automation)
      - [Time-Based](#time-based)
      - [Log-Trigger](#log-trigger)
    - [Chainlink Functions](#chainlink-functions)
      - [Javascript](#javascript)
      - [Proxy API](#proxy-api)
    - [CCIP](#ccip)
      - [Custom CCIP Transaction Types](#custom-ccip-transaction-types)
  - [Transaction Flows](#transaction-flows)
    - [Rebalance](#rebalance)
      - [Rebalance when Old Strategy is Parent and New Strategy is Parent](#rebalance-when-old-strategy-is-parent-and-new-strategy-is-parent)
      - [Rebalance when Old Strategy is Parent and New Strategy is Child](#rebalance-when-old-strategy-is-parent-and-new-strategy-is-child)
      - [Rebalance when Old Strategy is Child and New Strategy is Parent](#rebalance-when-old-strategy-is-child-and-new-strategy-is-parent)
      - [Rebalance when Old Strategy is Child and New Strategy is Local Child](#rebalance-when-old-strategy-is-child-and-new-strategy-is-local-child)
      - [Rebalance when Old Strategy is Child and New Strategy is Remote Child](#rebalance-when-old-strategy-is-child-and-new-strategy-is-remote-child)
    - [Deposit](#deposit)
      - [Deposit on Parent when Parent is Strategy](#deposit-on-parent-when-parent-is-strategy)
      - [Deposit on Parent when Child is Strategy](#deposit-on-parent-when-child-is-strategy)
      - [Deposit on Child when Parent is Strategy](#deposit-on-child-when-parent-is-strategy)
      - [Deposit on Child when Local Child is Strategy](#deposit-on-child-when-local-child-is-strategy)
      - [Deposit on Child when Remote Child is Strategy](#deposit-on-child-when-remote-child-is-strategy)
    - [Withdraw](#withdraw)
      - [Withdraw on Parent when Parent is Strategy](#withdraw-on-parent-when-parent-is-strategy)
      - [Withdraw on Parent when Child is Strategy](#withdraw-on-parent-when-child-is-strategy)
      - [Withdraw on Child when Parent is Strategy](#withdraw-on-child-when-parent-is-strategy)
      - [Withdraw on Child when Local Child is Strategy](#withdraw-on-child-when-local-child-is-strategy)
      - [Withdraw on Child when Remote Child is Strategy](#withdraw-on-child-when-remote-child-is-strategy)
  - [Deploying](#deploying)
    - [LINK Token Funding](#link-token-funding)
  - [Testing](#testing)
    - [Unit Tests](#unit-tests)
      - [Unit test note](#unit-test-note)
    - [Invariant Tests](#invariant-tests)
    - [Other Tests](#other-tests)
  - [Formal Verification](#formal-verification)
  - [Known Issues](#known-issues)
    - [Burning small amounts of shares can result in 0 usdc withdrawn](#burning-small-amounts-of-shares-can-result-in-0-usdc-withdrawn)
  - [Testnet Deployments](#testnet-deployments)
    - [Eth Sepolia](#eth-sepolia)
    - [Base Sepolia](#base-sepolia)
    - [Avalanche Fuji](#avalanche-fuji)
  - [Testnet Transactions](#testnet-transactions)
    - [Rebalance New Strategy](#rebalance-new-strategy)
    - [Rebalance Old Strategy](#rebalance-old-strategy)
    - [Deposit tx from chain c (avalanche) → parent (eth) → strategy (base)](#deposit-tx-from-chain-c-avalanche--parent-eth--strategy-base)
    - [Withdraw tx from chain c (avalanche) → parent (eth) → strategy (base)](#withdraw-tx-from-chain-c-avalanche--parent-eth--strategy-base)
    - [YieldCoin Bridge tx (eth -\> aval)](#yieldcoin-bridge-tx-eth---aval)
  - [Future Developments](#future-developments)
  - [Challenges I ran into](#challenges-i-ran-into)
    - [Share Mint Calculation Bug](#share-mint-calculation-bug)
    - [Burning small amounts of shares (YieldCoin), worth less than the lowest possible value of USDC (6 decimals) resulted in reverts](#burning-small-amounts-of-shares-yieldcoin-worth-less-than-the-lowest-possible-value-of-usdc-6-decimals-resulted-in-reverts)
    - [USDC chainlink-local fork](#usdc-chainlink-local-fork)
    - [Proxy API](#proxy-api-1)
    - [Time management/knowing what to prioritize](#time-managementknowing-what-to-prioritize)
    - [Functions callback with max gas limit not being able to execute ccip sends](#functions-callback-with-max-gas-limit-not-being-able-to-execute-ccip-sends)
    - [Certora Formal Verification of contracts that use Chainlink FunctionsRequest library](#certora-formal-verification-of-contracts-that-use-chainlink-functionsrequest-library)
    - [Yield generating strategy protocols either not working on testnet or not existing](#yield-generating-strategy-protocols-either-not-working-on-testnet-or-not-existing)
    - [DefiLlama API not providing testnet data](#defillama-api-not-providing-testnet-data)
    - [Incorrect placement of `networkConfig` cache before `vm.startBroadcast` in deploy script](#incorrect-placement-of-networkconfig-cache-before-vmstartbroadcast-in-deploy-script)
  - [Frontend](#frontend)
  - [Additional Comments](#additional-comments)
  - [Acknowledgement](#acknowledgement)

## Overview

**Problem statement**: "I want my stablecoins to earn the highest possible yield without having to monitor opportunities, then manually withdraw, bridge and deposit."

**Solution**: YieldCoin abstracts ALL of that away. Deposit your stablecoin into the Contract Level Yield system, from your chain of choice, to earn the highest yield from the safest, most reliable services across the web3 ecosystem.

Stablecoin depositors receive YieldCoin, a share token, in return for their deposits, representing their share of the total value (deposits + yield) in the system. Depositing a stablecoin can also be considered "buying" YieldCoin. YieldCoin is the share received for depositing into the system, with the basic idea being that a holder will be able to "sell" (their YieldCoin) for a higher USD value than they bought it. This is because the stablecoin deposits will not go down in value, and reliable yield will be generated.

The protocol and chain with the highest APY, where the system funds are allocated is known as the `Strategy`.

## YieldCoin

YieldCoin follows the [ERC677](https://github.com/ethereum/EIPs/issues/677) and [CCT](https://docs.chain.link/ccip/concepts/cross-chain-token) standards for maximum efficiency and interoperability. The YieldCoin CCIP pools are permissionless, allowing holders to move freely across chains. `ERC677.transferAndCall()` enables holders to withdraw USDC in a single tx, without having to approve the CLY infrastructure to transfer their YIELD first. See [./src/token/Share.sol](https://github.com/contractlevel/yield/blob/main/src/token/Share.sol).

## Strategy

The "[Strategy](https://github.com/contractlevel/yield/blob/788c3c0a80279ee0f75e6977056173225cbc3f26/src/interfaces/IYieldPeer.sol#L5-L8)" refers to the chain and protocol the total system funds are allocated to generate the optimal yield. Low-risk, time-tested, and secure protocols have been selected for this initial prototype. For now the system supports Aave and Compound. As development progresses, the plan is to integrate as many strategy protocols as possible, without risking user funds. The system should always be able to withdraw all user deposits + yield generated. Therefore supplying USDC to earn APY from protocols like Aave and Compound is seen as a safe, low-risk yield strategy.

"Strategy rebalancing" or simply "rebalancing" refers to the automated process of withdrawing funds from the previous strategy and depositing them into the new strategy, to earn a higher yield.

The terms "current strategy" and "active strategy" are used interchangably.

"Old Strategy" refers to the Strategy funds are being withdrawn from during the rebalance process, and "New Strategy" refers to the Strategy those funds are being deposited to during the rebalance.

## Contracts/Architecture

The Contract Level Yield system that powers YieldCoin consists of a crosschain network of "Peer" contracts. `YieldPeer` contracts are deployed on each compatible chain, and act as entry points to the system. Currently the only supported stablecoin is `USDC` (due partially to its availability across chains with CCIP and the time constraints of the hackathon).

Users deposit their `USDC` into the CLY infrastructure from their chain of choice. In return they receive YieldCoin ($YIELD) tokens. The amount of YieldCoin a depositor is minted in exchange for their stablecoin deposit is proportional to how much of the system's total value (total deposits + generated yield) their stablecoin deposit is worth. The basic idea is that a user will always be able to redeem their YieldCoin for the stablecoin they deposited plus yield (minus fees, but fees haven't been implemented yet).

There are two types of `YieldPeer` contracts: a `ParentPeer` and a `ChildPeer`. There is a single `ParentPeer` contract deployed across chains, with every other compatible chain hosting a `ChildPeer`. See [./src/peers](https://github.com/contractlevel/yield/tree/main/src/peers).

### YieldPeer

[`YieldPeer`](https://github.com/contractlevel/yield/blob/main/src/peers/YieldPeer.sol) is an abstract contract that acts as the "base" for both the `ParentPeer` and `ChildPeer` contracts. The Parent and Child peers share some functionality, but also have functionality unique to their particular roles in the system. The shared `YieldPeer` functionality consists primarily of CCIP integrations and yield strategy interactions.

Contracts that inherit `YieldPeer` must implement the following functions:

- `deposit(uint256)` - user entry point for the system where USDC is deposited and YieldCoin is minted
- `onTokenTransfer(address,uint256,bytes)` - user exit point for the system where YieldCoin is burned and USDC is withdrawn
- `_handleCCIPMessage(CcipTxType,Client.EVMTokenAmount[],bytes,uint64)` - executed following `_ccipReceive` checks to handle various CCIP tx types

The Peer with the current active strategy will return a non-zero address from `YieldPeer::getStrategyPool()`.

#### IYieldPeer Interface

The [IYieldPeer interface](https://github.com/contractlevel/yield/blob/main/src/interfaces/IYieldPeer.sol) defines important structs and enums for the system, related to Strategy protocol and CCIP message handling, such as compatible strategies, custom types of CCIP txs, and what data is sent across chains for deposits and withdraws.

#### Libraries

Some logic from `YieldPeer` has been delegated to distinct libraries to improve maintainability.

[CCIPOperations](https://github.com/contractlevel/yield/blob/main/src/libraries/CCIPOperations.sol) contains logic for facilitating CCIP fees, creating CCIP messages, and handling bridged USDC token amounts.

[ProtocolOperations](https://github.com/contractlevel/yield/blob/main/src/libraries/ProtocolOperations.sol) contains logic for interacting with strategy protocols such as depositing, withdrawing, and querying the total value of the system.

[DataStructures](https://github.com/contractlevel/yield/blob/main/src/libraries/DataStructures.sol) contains logic for creating [DepositData](https://github.com/contractlevel/yield/blob/788c3c0a80279ee0f75e6977056173225cbc3f26/src/interfaces/IYieldPeer.sol#L28-L34) and [WithdrawData](https://github.com/contractlevel/yield/blob/788c3c0a80279ee0f75e6977056173225cbc3f26/src/interfaces/IYieldPeer.sol#L36-L42) structs, which are used in CCIP messages for deposits and withdraw respectively.

### ParentPeer

The [`ParentPeer`](https://github.com/contractlevel/yield/blob/main/src/peers/ParentPeer.sol) contract tracks system wide state for Contract Level Yield, specifically the total shares (YieldCoin) minted, and the current yield strategy. [`ParentPeer::s_totalShares`](https://github.com/contractlevel/yield/blob/788c3c0a80279ee0f75e6977056173225cbc3f26/src/peers/ParentPeer.sol#L26-L28) is the sum of all shares/YieldCoin that exists across chains. [`ParentPeer::s_strategy`](https://github.com/contractlevel/yield/blob/788c3c0a80279ee0f75e6977056173225cbc3f26/src/peers/ParentPeer.sol#L29-L30) is a struct containing the chain selector and protocol of the current yield generating strategy.

The `ParentPeer` contract is extended with the [`ParentCLF`](https://github.com/contractlevel/yield/blob/main/src/peers/extensions/ParentCLF.sol) contract. `ParentCLF` inherits `ParentPeer` and implements Chainlink Functions functionality. As such, `ParentCLF` is the single `ParentPeer` instantiation deployed in the system. `ParentCLF` also implements functionality to make it compatible with Chainlink Automation.

[`ParentRebalancer`](https://github.com/contractlevel/yield/blob/main/src/modules/ParentRebalancer.sol) is deployed on the same chain as `ParentCLF`. The `ParentRebalancer` contract provides supplementary log trigger automation functionality to `ParentCLF`, as the `ParentCLF` contract is unfortunately too big to contain it all itself.

### ChildPeer

The [`ChildPeer`](https://github.com/contractlevel/yield/blob/main/src/peers/ChildPeer.sol) is deployed on every chain except for the chain hosting the `ParentPeer`. Similar to `ParentPeer`, `ChildPeer` facilitates deposits, withdraws, and handling CCIP rebalance messages.

## System Actors

The only two actors in this system are stablecoin depositors and the owner of the contracts.

**Stablecoin depositors** deposit USDC and receive YieldCoin. They can then move their YieldCoin around chains or `transferAndCall()` it to a `YieldPeer` to redeem their USDC + yield.

The **Owner** sets various values required for the system to function, such as CCIP gas limit, Automation Forwarder and Upkeep addresses, and allowed chains and peers.

## Chainlink Integrations

Chainlink services provide essential functionality to the Contract Level Yield system. Automation, Functions and CCIP are combined to automate rebalances, and CCIP is also used where applicable in stablecoin deposits and withdraws.

### Chainlink Automation

Automation removes the need for any human/manual intervention for the system to consistently maintain the highest yield available.

#### Time-Based

The strategy rebalancing process starts with a pre-scheduled call from the Chainlink Automation service, to request the optimal strategy via Chainlink Functions. [`ParentCLF::sendCLFRequest()`](https://github.com/contractlevel/yield/blob/788c3c0a80279ee0f75e6977056173225cbc3f26/src/peers/extensions/ParentCLF.sol#L108-L109) is called by the Chainlink Automation `upkeep` address and requires no further configuration in the contract, other than access control preventing non-upkeep addresses from calling.

#### Log-Trigger

When a new strategy is set by the Chainlink Functions [`fulfillRequest()` callback](https://github.com/contractlevel/yield/blob/788c3c0a80279ee0f75e6977056173225cbc3f26/src/peers/extensions/ParentCLF.sol#L123-L152), a [`StrategyUpdated`](https://github.com/contractlevel/yield/blob/788c3c0a80279ee0f75e6977056173225cbc3f26/src/peers/ParentPeer.sol#L359) event is emitted. The `ParentRebalancer` will [check for this event](https://github.com/contractlevel/yield/blob/788c3c0a80279ee0f75e6977056173225cbc3f26/src/modules/ParentRebalancer.sol#L45-L96) and initiate CCIP rebalance txs when applicable.

### Chainlink Functions

Chainlink Functions is used to securely fetch and return the protocol and chain with the highest APY available, to update the current strategy.

#### Javascript

The inline Javascript `SOURCE` code passed to Chainlink Functions is defined as [a constant in `ParentCLF`](https://github.com/contractlevel/yield/blob/788c3c0a80279ee0f75e6977056173225cbc3f26/src/peers/extensions/ParentCLF.sol#L29-L32) and runs a remote script from the [project repo](https://github.com/contractlevel/yield/blob/main/functions/src.min.js).

[src.js](https://github.com/contractlevel/yield/blob/main/functions/src.js) demonstrates the logic of the remote script performed by the Chainlink Functions DON. To increase efficiency, the actual script that is run, is a [minimized equivalent](https://github.com/contractlevel/yield/blob/main/functions/src.min.js). The script queries and handles API data from the [DefiLlama Yield API](https://yields.llama.fi/pools).

Javascript logic related to Functions can be found in the [./functions directory](https://github.com/contractlevel/yield/tree/main/functions).

#### Proxy API

A proxy API was required for communicating between Chainlink Functions and the DefiLlama API, because the DefiLlama API payload response was too large for Chainlink Functions, so we filter on the server side via our proxy API.

To prepare the proxy API, navigate to its directory and install the dependencies:

```
cd functions/defillama-proxy
npm i
```

The `function.zip` file located in `functions/defillama-proxy` has been uploaded to AWS Lambda and deployed.

To prevent abuse, the url of the proxy API has been encrypted as an [offchain secret](https://www.npmjs.com/package/@chainlink/functions-toolkit#off-chain-hosted-secrets) and stored as [a constant in `ParentCLF`](https://github.com/contractlevel/yield/blob/788c3c0a80279ee0f75e6977056173225cbc3f26/src/peers/extensions/ParentCLF.sol#L33-L37).

### CCIP

CCIP faciliates secure crosschain communication and value transfer for rebalances, and, where applicable, deposits and withdraws. [Custom CCIP tx types have been defined](https://github.com/contractlevel/yield/blob/788c3c0a80279ee0f75e6977056173225cbc3f26/src/interfaces/IYieldPeer.sol#L15-L24) and are used to ensure receiving contracts correctly handle data and/or value.

#### Custom CCIP Transaction Types

- **0 - DepositToParent**: A deposit transaction from a `ChildPeer` to the `ParentPeer`. This is necessary to forward deposits to remote strategy chains.
- **1 - DepositToStrategy**: A deposit transaction from the `ParentPeer` to the active Strategy. This deposits funds in the strategy protocol and gets the `totalValue` of the system.
- **2 - DepositCallbackParent**: A callback transaction from the active Strategy to the `ParentPeer`. This returns the `totalValue`, which is used to calculate the `shareMintAmount` (how many YieldCoin a depositor should receive) and update `s_totalShares`.
- **3 - DepositCallbackChild**: A callback from the `ParentPeer` to the `ChildPeer` the deposit was initiated on. This mints shares/YieldCoin to the depositor.
- **4 - WithdrawToParent**: A withdraw from a `ChildPeer` to the `ParentPeer`. This forwards the withdrawal to the active strategy and updates `s_totalShares` to reflect the amount of YieldCoin burned when initiating the withdrawal.
- **5 - WithdrawToStrategy**: A withdraw from the `ParentPeer` to the active Strategy. This calculates the `usdcWithdrawAmount` and withdraws it from the active Strategy.
- **6 - WithdrawCallback**: A callback from the active Strategy to the withdraw chain. This sends the withdrawn USDC to the withdrawer.
- **7 - RebalanceOldStrategy**: A message from the `ParentPeer` to the old Strategy. This is to withdraw funds from the old Strategy to move to the new Strategy.
- **8 - RebalanceNewStrategy**: A value transfer from the old Strategy to the new Strategy. This is to deposit funds into the new Strategy.

## Transaction Flows

Transaction flows differ based on the nature of the transaction, its point of origin, and the location of the active Strategy.

### Rebalance

This diagram shows a (rough) high-level overview of the entire rebalance process.

![Rebalance Flow](./diagrams/rebalance/rebalance.jpg)

The following diagrams show individual rebalance flows for different scenarios.

#### Rebalance when Old Strategy is Parent and New Strategy is Parent

![Rebalance Local Parent Change](./diagrams/rebalance/oldParent-newParent.jpg)

#### Rebalance when Old Strategy is Parent and New Strategy is Child

![Rebalance Parent to Child](./diagrams/rebalance/oldParent-newChild.jpg)

#### Rebalance when Old Strategy is Child and New Strategy is Parent

![Rebalance Child to Parent](./diagrams/rebalance/oldChild-newParent.jpg)

#### Rebalance when Old Strategy is Child and New Strategy is Local Child

![Rebalance Child to Local Child](./diagrams/rebalance/oldChild-newLocalChild.jpg)

#### Rebalance when Old Strategy is Child and New Strategy is Remote Child

![Rebalance Child to Remote Child](./diagrams/rebalance/oldChild-newRemoteChild.jpg)

### Deposit

Deposits are initiated with `YieldPeer::deposit()` and require the `YieldPeer` being used to have been approved for spending the USDC to deposit.

See [Parent Deposit](https://github.com/contractlevel/yield/blob/788c3c0a80279ee0f75e6977056173225cbc3f26/src/peers/ParentPeer.sol#L78-L106) and [Child Deposit](https://github.com/contractlevel/yield/blob/788c3c0a80279ee0f75e6977056173225cbc3f26/src/peers/ChildPeer.sol#L44-L71).

Deposits will be handled differently depending on the chain of initiation and the location of the current strategy.

Deposit traces are required to include the `ParentPeer`, even if the deposit was made on the `ChildPeer` with the current strategy because the `ParentPeer`'s state must be updated to reflect the total shares/YieldCoin in the system.

#### Deposit on Parent when Parent is Strategy

![Deposit on Parent when Parent is Strategy](./diagrams/deposit/onParent-isParent.jpg)

#### Deposit on Parent when Child is Strategy

![Deposit on Parent when Child is Strategy](./diagrams/deposit/onParent-isChild.jpg)

#### Deposit on Child when Parent is Strategy

![Deposit on Child when Parent is Strategy](./diagrams/deposit/onChild-isParent.jpg)

#### Deposit on Child when Local Child is Strategy

![Deposit on Child when Local Child is Strategy](./diagrams/deposit/onChild-isLocalChild.jpg)

#### Deposit on Child when Remote Child is Strategy

![Deposit on Child when Remote Child is Strategy](./diagrams/deposit/onChild-isRemoteChild.jpg)

To clarify what is happening in this final image: when the deposit is made, the strategy is fetched from the parent, then the deposit is sent to the strategy, the tvl is returned to the parent, and then the parent returns the YieldCoin mint amount to the depositor.

### Withdraw

Withdrawals are executed using the YieldCoin token's `ERC677::transferAndCall()`, which checks if the receiving address has implemented `IERC677Receiver::onTokenTransfer()`, which the `YieldPeer`, `ParentPeer`, and `ChildPeer` contracts have.

See [Parent Withdraw](https://github.com/contractlevel/yield/blob/788c3c0a80279ee0f75e6977056173225cbc3f26/src/peers/ParentPeer.sol#L108-L169) and [Child Withdraw](https://github.com/contractlevel/yield/blob/788c3c0a80279ee0f75e6977056173225cbc3f26/src/peers/ChildPeer.sol#L73-L93).

The chain to receive the withdrawn USDC on can be different to the chain the withdrawal was initiated on, by passing an encoded chain selector as the `data` param in `transferAndCall()`. The tx will revert if the data does not decode to an allowed chain. If the data is left empty, the USDC will be withdrawn to the chain the withdrawal tx was initiated on.

Similar to deposits, the system will handle withdrawals differently depending on the chain of initiation and location of the current strategy.

_Note: These withdrawal diagrams assume the chain to withdraw to is the one the withdrawal initiated on. If the withdrawn USDC is requested to be sent to the withdrawer on another chain, the final USDC transfer and ccipReceive will pass through the `YieldPeer` on that chain._

#### Withdraw on Parent when Parent is Strategy

![Withdraw on Parent when Parent is Strategy](./diagrams/withdraw/onParent-isParent.jpg)

#### Withdraw on Parent when Child is Strategy

![Withdraw on Parent when Child is Strategy](./diagrams/withdraw/onParent-isChild.jpg)

#### Withdraw on Child when Parent is Strategy

![Withdraw on Child when Parent is Strategy](./diagrams/withdraw/onChild-isParent.jpg)

#### Withdraw on Child when Local Child is Strategy

![Withdraw on Child when Local Child is Strategy](./diagrams/withdraw/onChild-isLocalChild.jpg)

#### Withdraw on Child when Remote Child is Strategy

![Withdraw on Child when Remote Child is Strategy](./diagrams/withdraw/onChild-isRemoteChild.jpg)

To clarify what is happening in this final image: when the withdraw is initiated by burning YieldCoin with `transferAndCall()`, the strategy is fetched from the parent, then the YieldCoin/share burn amount is sent to the strategy, and then `USDC` is sent to the withdrawer.

## Deploying

The `ParentPeer` (`ParentCLF`) should be deployed first. This script will also deploy the `ParentRebalancer`, and YieldCoin `Share` and `SharePool` contracts, as well as call the necessary functions to make the pool permissionless and integrate it with CCIP. It also grants mint and burn roles for YieldCoin to the `ParentPeer` and CCIP pool, as well as setting storage in `ParentRebalancer`.

```
forge script script/deploy/DeployParent.s.sol --broadcast --account <YOUR_FOUNDRY_KEYSTORE> --rpc-url <PARENT_CHAIN_RPC_URL>
```

The Chainlink Automation forwarder address should be set in `ParentRebalancer::setForwarder()` and the Chainlink Automation upkeep address should be set in `ParentCLF::setUpkeepAddress()`.

The `ParentCLF`, `Share`, and `SharePool` addresses returned from running that script should be added to `NetworkConfig.peers` for both the Parent chain and any child chains.

Next deploy the `ChildPeer` and its YieldCoin `Share` and `SharePool` contracts. This will also perform the necessary actions to enable permissionless CCIP pool functionality and grant appropriate mint and burn roles for `YieldCoin`. This script should be run for every child chain.

```
forge script script/deploy/DeployChild.s.sol --broadcast --account <YOUR_FOUNDRY_KEYSTORE> --rpc-url <CHILD_CHAIN_RPC_URL>
```

For every deployed Child, take the `ChildPeer`, `Share`, and `SharePool` addresses and add them to the `NetworkConfig.peer` for all applicable chains, including the Parent.

Finally run the [`SetCrosschain`](https://github.com/contractlevel/yield/blob/main/script/interactions/SetCrosschain.s.sol) script for every chain. This will set the allowed chain selectors and peers for each chain, as well as enable the CCIP pools to work with each other.

```
forge script script/interactions/SetCrosschain.s.sol --broadcast --account <YOUR_FOUNDRY_KEYSTORE> --rpc-url <CHAIN_RPC_URL>
```

### LINK Token Funding

For the Contract Level Yield infrastructure to function, LINK is required for the following:

- Time-based Automation subscription on Parent chain
- Log-trigger Automation subscription on Parent chain
- Chainlink Functions subscription on Parent chain
- Every `YieldPeer` on every chain for CCIP txs

## Testing

This project was built with [Foundry](https://getfoundry.sh/introduction/installation/). To run the tests, Foundry and the project's dependancies need to be installed.

```
foundryup
forge install
```

### Unit Tests

The unit tests fork three mainnets, and as such require `RPC_URL`s in a `.env`.

```
ETH_MAINNET_RPC_URL=<your_rpc_url_here>
OPTIMISM_MAINNET_RPC_URL=<your_rpc_url_here>
BASE_MAINNET_RPC_URL=<your_rpc_url_here>
```

The unit tests use a [fork of chainlink-local](https://github.com/contractlevel/chainlink-local). Since the unit tests are performed on forked mainnets, additional functionality was required from chainlink-local in order to facilitate USDC transfers. USDC transfers on CCIP integrate [Circle's CCTP](https://www.circle.com/cross-chain-transfer-protocol), which comes with additional checks that weren't included in the original chainlink-local. The CCTP architecture requires USDC transfer messages to be "validated by attesters". These messages need to be in a [specific format](https://github.com/circlefin/evm-cctp-contracts/blob/6e7513cdb2bee6bb0cddf331fe972600fc5017c9/src/MessageTransmitter.sol#L228-L247) and the attesters' signatures need to be in a [specific order](https://github.com/circlefin/evm-cctp-contracts/blob/6e7513cdb2bee6bb0cddf331fe972600fc5017c9/src/MessageTransmitter.sol#L246-L247).

To achieve this, the changes were made to the [CCIPLocalSimulatorFork](https://github.com/contractlevel/chainlink-local/blob/main/src/ccip/CCIPLocalSimulatorFork.sol). A new function, [switchChainAndRouteMessageWithUSDC](https://github.com/contractlevel/chainlink-local/blob/519e854caaf1291c03bda3928674c922195fd629/src/ccip/CCIPLocalSimulatorFork.sol#L126-L155) was added, which is based on the original `switchChainAndRouteMessage`, except it also listens for CCTP's `MessageSent` event, and takes two arrays of attester addresses, and their private keys - values that can be easily simulated with [Foundry's makeAddrAndKey](https://getfoundry.sh/reference/forge-std/make-addr-and-key/).

The `offchainTokenData` array passed to the offRamp needed to contain the USDCTokenPool's `MessageAndAttestation` struct, which contains the message retrieved from the `MessageSent` event and the `attestation` created with the attesters and their private keys. To achieve this, another function was added, [\_createOffchainTokenData](https://github.com/contractlevel/chainlink-local/blob/519e854caaf1291c03bda3928674c922195fd629/src/ccip/CCIPLocalSimulatorFork.sol#L181-L238).

#### Unit test note

_NOTE: Some unit tests in [`CheckLog.t.sol`](https://github.com/contractlevel/yield/blob/main/test/unit/rebalancer/CheckLog.t.sol) will fail with `OnlySimulatedBackend()` unless the [`cannotExecute` modifier](https://github.com/contractlevel/yield/blob/0cd489dc7a2fb2b7f2f949db890038dd33925873/src/modules/ParentRebalancer.sol#L55) and [`test_yield_checkLog_revertsWhen_cannotExecute`](https://github.com/contractlevel/yield/blob/0cd489dc7a2fb2b7f2f949db890038dd33925873/test/unit/rebalancer/CheckLog.t.sol#L8-L12) has been temporarily commented out._

The unit tests for the Contract Level Yield contracts can be run with:

```
forge test --mt test_yield
```

### Invariant Tests

The invariant test suite also uses the fork of chainlink-local.

Given the nature of invariant fuzz runs, the invariant tests do not use the `CCIPLocalSimulatorFork` or forked mainnets, as the rpc calls would've been too excessive. These tests deploy the infrastructure locally and use chainlink-local's `CCIPLocalSimulator`. However the [`MockRouter`](https://github.com/contractlevel/chainlink-local/blob/main/test/mocks/MockRouter.sol) used needed to be forked, to enable [dynamic source chain selectors](https://github.com/contractlevel/chainlink-local/blob/519e854caaf1291c03bda3928674c922195fd629/test/mocks/MockRouter.sol#L117), otherwise the system wouldn't work because the security and functionality of the crosschain communication hinges on the validation of allowed chain selectors and peer contracts.

A gas check has been [bypassed](https://github.com/contractlevel/chainlink-local/blob/519e854caaf1291c03bda3928674c922195fd629/test/mocks/MockRouter.sol#L227-L230) in these tests because no matter what value was set for the CCIP gas limit, one of the fuzz runs would eventually fail with either `Not enough gas` or `Out of gas`. These mocked gas checks were not critical to the functionality that required testing, particularly when forked mainnets with non-mocked gas checks were already confirmed to be working, so instead of spending additional time on this detail, it was bypassed altogether.

Key invariants identified include:

- a user must be able to withdraw the usdc amount they deposited minus fees
- total YieldCoin minted across chains should be accurately tracked in Parent storage
- TVL should be more than or equal to net deposits

The invariant tests can be run with:

```
forge test --mt invariant
```

Invariant runs are set to 3000 and fail on revert is true.

### Other Tests

For the full Foundry test suite (which includes tests for mock contracts and scripts), run:

```
forge test
```

## Formal Verification

This project uses Certora for formal verification. A `CERTORAKEY` is required to use the Certora Prover. Get one [here](https://docs.certora.com/en/latest/docs/user-guide/install.html#step-3-set-the-personal-access-key-as-an-environment-variable).

```
export CERTORAKEY=<personal_access_key>
```

The [`BasePeer`](https://github.com/contractlevel/yield/blob/main/certora/spec/yield/BasePeer.spec) spec verifies mutual behavior of the Parent and Child Peers, so there are separate `conf` files for verifying each of them against it.

```
certoraRun ./certora/conf/child/BaseChild.conf
certoraRun ./certora/conf/parent/BaseParent.conf
```

The [`Parent`](https://github.com/contractlevel/yield/blob/main/certora/spec/parent/Parent.spec) and [`Child`](https://github.com/contractlevel/yield/blob/main/certora/spec/child/Child.spec) specs verify behaviors particular to their respective peers.

```
certoraRun ./certora/conf/parent/Parent.conf
certoraRun ./certora/conf/child/Child.conf
```

The [`Yield`](https://github.com/contractlevel/yield/blob/main/certora/spec/yield/Yield.spec) spec verifies internal properties of the abstract `YieldPeer` contract such as depositing to and withdrawing from strategies, as well as CCIP tx handling.

```
certoraRun ./certora/conf/Yield.conf
```

The [`ParentCLF`](https://github.com/contractlevel/yield/blob/main/certora/spec/parent/ParentCLF.spec) spec verifies logic related to Chainlink Functions and Automation.

```
certoraRun ./certora/conf/parent/ParentCLF.conf --nondet_difficult_funcs
```

The `--nondet_difficult_funcs` flag is required for `ParentCLF` to [automatically summarize functions](https://docs.certora.com/en/latest/docs/prover/cli/options.html#nondet-difficult-funcs) in the `FunctionsRequest` library because otherwise the Certora Prover will timeout. The Certora Prover explores all possible paths and the `FunctionsRequest::encodeCBOR` includes an extremely high path count, making it difficult to verify.

The [`Rebalancer`](https://github.com/contractlevel/yield/blob/main/certora/spec/parent/Rebalancer.spec) spec verifies the `ParentRebalancer` contract.

```
certoraRun ./certora/conf/parent/Rebalancer.conf
```

Verifying behaviour in the `checkLog()` function would result in vacuous rules with basic sanity enabled. I thought this was because of returning false when upkeep wasn't needed, and that reverting instead would improve the verification, but that resulted in vacuous rules too. For now basic sanity has been left enabled, and comments in the spec indicate the vacuous rules. Reverts instead of returning false when upkeep is not needed has been kept in place. It doesn't make any functional difference either way and is purely aesthetic, especially when both options deliver vacuous rules.

## Known Issues

### Burning small amounts of shares can result in 0 usdc withdrawn

It can take up to 3 CCIP txs to calculate the `usdcWithdrawAmount` based on the `shareBurnAmount`

Consider this scenario:

- `shareBurnAmount`withdrawal initiated on child1
- `totalShares` is on parent
- `totalValue` is on child2 (strategy)

These 3 values are required to calculate the `usdcWithdrawAmount`. When the `shareBurnAmount` is significantly small, the calculation can return less than the minimum amount of USDC to 6 decimals ($0.000001). This value is a significantly small fraction of a cent. If we tried to calculate this amount, it would return 0. Then if we try to withdraw this amount (0) from a yield strategy and send it across ccip to be transferred to the withdrawer, it would cause issues such as the transfer failing because the transferAmount is 0.

Therefore the current mitigation is to not withdraw or transfer anything if someone burns an amount of shares small enough that it is worth less than `0.000001 USDC`.

It is unlikely to expect anyone to want to withdraw such a small amount of dust, but this issue still needs to be documented.

We could add a min burn amount, and revert if this amount is not provided when a burn is attempted, but to do so would require the same above CCIP txs + extra ones just to tell the withdrawer that "no, we cant burn your insignificant amount of shares".

## Testnet Deployments

The Contract Level Yield infrastructure has been deployed across three testnets (Ethereum Sepolia, Base Sepolia, and Avalanche Fuji), in order to test the various onchain scenarios using Chainlink - all of which are successful.

Ethereum Sepolia is the Parent chain purely because it has open access to Log-trigger Automation (although access was granted to Log-trigger Automation on Base Sepolia after these deployments - thanks!).

[Mock contracts](https://github.com/contractlevel/yield/tree/main/test/mocks/testnet) were used in place of some strategy contracts either due to their unavailability on testnets or their testnet equivalents not behaving as expected. These mocks do not generate any yield, but otherwise behave as their mainnet counterparts would in terms of depositing and withdrawing funds in the context of the Contract Level Yield system.

The DefiLlama API does not provide testnet data, so mainnet data was used to determine the strategy protocol and chain.

### Eth Sepolia

ParentRebalancer: https://sepolia.etherscan.io/address/0x107C9A78c447c99289B84476f53620236114AbAa#code

ParentCLF: https://sepolia.etherscan.io/address/0xBE679979Eaec355d1030d6f117Ce5B4b5388318E#code

YieldCoin/share token: https://sepolia.etherscan.io/address/0x37D13c62D2FDe4A400e2018f2fA0e3da6b15718D#code

SharePool (YieldCoin CCIP pool): https://sepolia.etherscan.io/address/0x9CF6491ace3FDD614FB8209ec98dcF98b1e70e4D#code

### Base Sepolia

Child: https://sepolia.basescan.org/address/0x94563Bfe55D8Df522FE94e7D60D2D949ef21BF1c#code

YieldCoin/share token: https://sepolia.basescan.org/address/0x2DF8c615858B479cBC3Bfef3bBfE34842d7AaA90#code

SharePool (YieldCoin CCIP pool): https://sepolia.basescan.org/address/0xEF13904800eFA60BB1ea5f70645Fc55609F00320#code

### Avalanche Fuji

Child: https://testnet.snowtrace.io/address/0xc19688E191dEB933B99cc78D94c227784c8062F9/contract/43113/code

YieldCoin/share token: https://testnet.snowtrace.io/address/0x2891C37D5104446d10dc29eA06c25C6f0cA233Ec/contract/43113/code

SharePool (YieldCoin CCIP pool): https://testnet.snowtrace.io/address/0x9bf12E915461A48bc61ddca5f295A0E20BBBa5D7/contract/43113/code

## Testnet Transactions

### Rebalance New Strategy

time based auto triggers CLF https://sepolia.etherscan.io/tx/0xc8159327d9c76b118c2caa10c9db513cc38c2c7a00e3c2f026df12d2b5e6190a

clf request callback https://sepolia.etherscan.io/tx/0x2521aea1c73c8ace2b5630b74c60857788944479e8dcd8a7a8362a74f8970a8b

log trigger auto https://sepolia.etherscan.io/tx/0x1099dbd2cd04403635b820cd17508aa7c56929bc99187b39a543a7b36cd50e4d

ccip rebalance https://ccip.chain.link/#/side-drawer/msg/0xb01894363f416f83171ee994cd043eacf4cc487bc2d8a589229d02c2649ed10b

dst tx: https://sepolia.basescan.org/tx/0x35f97388d654b63d80f4d9b88eab11fb4ee16a909862dd19338c8a758565a70c

### Rebalance Old Strategy

time based: https://sepolia.etherscan.io/tx/0xfb4413c2b8aeb0f2b849c2c962da3407334af3693d63b2112d005438eb1e114b

functions: https://sepolia.etherscan.io/tx/0x99a22014821e742f247cfae3c66b363eae0022b1b8dd5516415ec26ee8389028

log trigger: https://sepolia.etherscan.io/tx/0x90af2045da5f9c65037f8337409cb2c369b1bfd084db965bbc5685e07bcf5d3f

rebalance old strategy: https://ccip.chain.link/#/side-drawer/msg/0x86a09a3f8c59d325703a8d7936834641fdf1b4cab3c25e1a64e38bf5e63d4210

rebalance new strategy: https://ccip.chain.link/tx/0x08689dcb0cb6cc6149788a107e089d811f598ed79867536105280f01d12f8abe#/side-drawer/msg/0xe219bc33fbd5b23d4a564ca3bc0cc917be75cd52d16a850a23a85fbf619ebe86

### Deposit tx from chain c (avalanche) → parent (eth) → strategy (base)

deposit tx: https://testnet.snowtrace.io/tx/0x68b8118e9e9115e8f8956cc05edc06d8fe281f0955a762c830d98a7f87230a06?chainid=43113

deposit to parent: https://ccip.chain.link/#/side-drawer/msg/0x2a996da193b64a4c4c719921655e5fe57d8292914a48572cfafec02c5349bfc7

dst tx: https://sepolia.etherscan.io/tx/0x6685ae8f7c883ab2f83ea43afe838f51b1b8270eab16ebb26cc1782012766fc4

deposit to parent and deposit to strategy: https://ccip.chain.link/tx/0x6685ae8f7c883ab2f83ea43afe838f51b1b8270eab16ebb26cc1782012766fc4

strategy chain deposit: https://sepolia.basescan.org/tx/0x75e0f2ec96dde84126c8ec36f1bc5467c69bdb0b41e5c211e8ab99c65189baa3

deposit callback parent: https://ccip.chain.link/tx/0x75e0f2ec96dde84126c8ec36f1bc5467c69bdb0b41e5c211e8ab99c65189baa3

parent callback: https://sepolia.etherscan.io/tx/0x905c386823c1bceeb07a51c4d67effff82f8db7e1d16f2349fe2ffd053263f8f

deposit callback child: https://ccip.chain.link/tx/0x905c386823c1bceeb07a51c4d67effff82f8db7e1d16f2349fe2ffd053263f8f

final tx minting yieldcoin/shares based on totalValue from strategy chain and totalShares from parent chain: https://testnet.snowtrace.io/tx/0x4c02081f317a22bc7c2d2768ae8e2e1144e0ad0b36a605fc2158a5b34d903123

### Withdraw tx from chain c (avalanche) → parent (eth) → strategy (base)

withdraw initiate with transferAndCall: https://testnet.snowtrace.io/tx/0x1c635d115f41651df0bb29559629e30e82ec8e51f564d73d2bba0a564d8efb0b?chainid=43113

withdraw to parent: https://ccip.chain.link/#/side-drawer/msg/0xc8ebdd6da9a925a7b7e24001f1fc95b8bb650ebee3cbe1cbb9135ed68240d9e7

parent tx where shares are updated: https://sepolia.etherscan.io/tx/0xd6c19a86d0afbd1367cfff0262be838cbfdcf87356767c3b272b0a447269667f

withdraw to strategy: https://ccip.chain.link/tx/0xd6c19a86d0afbd1367cfff0262be838cbfdcf87356767c3b272b0a447269667f#/side-drawer/msg/0xef446fc7fba9cb80ac96fc5fdc69f00fce8a374991828949cdd673373a8bb31b

withdraw from strategy: https://sepolia.basescan.org/tx/0x67271c1cf24250bb942c4e3bc3179ecda9b5bdaa46bda7671a3b4b9415953f70

withdraw callback: https://ccip.chain.link/tx/0x67271c1cf24250bb942c4e3bc3179ecda9b5bdaa46bda7671a3b4b9415953f70#/side-drawer/msg/0x1e5b3ddf52d453d81d4e1c0ec3c0532c90de025391a7f10b483f3c1083b497a0

withdraw success: https://testnet.snowtrace.io/tx/0xbf9a7952bfda2561dcc92e07fe0ca58fd50bc2e88f2920fc9f22a0e96f394162

### YieldCoin Bridge tx (eth -> aval)

ccip: https://ccip.chain.link/tx/0xd0c3e338c66bad81412c92ad7b76681b977464fa85350201b9830bfaf5250956#/side-drawer/msg/0x7f91c48fe14b5d9c6f472afa45551be29d4ff930e51711c99c8e61a980f0ed58

## Future Developments

- test suite needs improving (event params have not been fully verified and mutation testing has not finished. there are still pathways to explore.)
- fees (and automated Chainlink service payments)
- more stablecoin support (swapping to one with higher yield opportunities, such as USD1, USDT, etc.)
- more chains
- more yield strategies/protocols (such as Euler, Morpho)
- svm compatability
- ccip calldata compression (should use solady.libZip for compressing/decompressing depositData, withdrawData and strategy struct)
- uniswap integration to allow users to "buy" yieldcoin with any asset, ie they pay with eth and it gets swapped to the usdc amount then deposited

## Challenges I ran into

_This section has been added to the README because it would not all fit in the submission page for the hackathon._

There were many roadblocks of varying size for this submission. The most significant of which was a YieldCoin/share mint calculation logic bug that became apparent during invariant testing and formal verification.

### Share Mint Calculation Bug

This was the most significant challenge and went unresolved whilst prioritizing an eligible submission.

The invariant testing revealed cases where the amount of YieldCoin minted in exchange for USDC deposits was significantly less than it should have been, breaking a key invariant of the system: `users must always be able to withdraw their deposit`(minus fees when implemented).

I thought the issue was mitigated with something like [dead shares inflation attack mitigation](https://solodit.cyfrin.io/issues/l-18-vault-is-susceptible-to-inflation-attack-by-first-depositor-pashov-audit-group-none-hyperstable_2025-02-26-markdown) because the invariant tests were then passing.

The issue came up again during formal verification with Certora. Even though initial admin shares were minted, Certora revealed scenarios where a depositor was not receiving enough YieldCoin to withdraw their deposit - bad!

22nd - Unresolved because an eligible submission was priority.

24th - There was a problem with the share mint amount calculation in [ParentPeer::\_calculateMintAmount](https://github.com/contractlevel/yield/blob/788c3c0a80279ee0f75e6977056173225cbc3f26/src/peers/ParentPeer.sol#L410). That problem was the TVL being passed included the deposit amount. Both of these values are required to calculate the amount to mint. The fix to this was to subtract the amount from TVL.

The invariant discussed above is now fixed.

26th - The root cause of this issue was a [helper function](https://github.com/contractlevel/yield/blob/0cd489dc7a2fb2b7f2f949db890038dd33925873/src/peers/YieldPeer.sol#L286-L287) in the abstract YieldPeer contract. The function deposited an amount to the active strategy, and returned the TVL. The order of operations for these was incorrect. TVL was being read after the deposit, which was wrong. This took time to fix because there was also a single instance of the same operation being done, outside the function.

### Burning small amounts of shares (YieldCoin), worth less than the lowest possible value of USDC (6 decimals) resulted in reverts

If a user attempted to withdraw USDC by burning an amount of shares/YieldCoin worth _less_ than the lowest possible value of USDC (6 decimals), solidity would calculate the amount of USDC to withdraw as 0. This caused reverts when the smart contracts attempted to withdraw 0 from strategy protocols and transfer it to the withdrawer.

To mitigate this, the current approach is a bit of a compromise, but if someone tries to withdraw less than the lowest possible value of USDC, they receive nothing in exchange for burning their shares. This of course is not ideal, and is considered a [known issue](https://github.com/contractlevel/yield?tab=readme-ov-file#burning-small-amounts-of-shares-can-result-in-0-usdc-withdrawn), however it is unexpected that a user will attempt to withdraw such an insignificant amount, and doing so would benefit all other YieldCoin holders. Most importantly, this mitigation means the system doesn't revert/experience any weird DoS.

It is mitigated, but further research will be conducted on this. An option being explored is enforcing a minimum share burn amount, but the crosschain nature of some withdraw paths makes this tricky to enforce at the contract level.

### USDC chainlink-local fork

The current chainlink-local ccip simulator is amazing, but unfortunately doesn’t have support for USDC - the stablecoin with the most lanes on CCIP.

To fully test the system on forked mainnets, additional functionality in the `CCIPLocalSimulatorFork` was required to get past the additional CCTP checks for USDC. CCTP is Circle’s crosschain infrastructure for USDC that works alongside CCIP onchain.

Ultimately the [additional functionality](https://github.com/contractlevel/chainlink-local/blob/519e854caaf1291c03bda3928674c922195fd629/src/ccip/CCIPLocalSimulatorFork.sol#L125-L238) required was the monitoring for a [CCTP event](https://github.com/circlefin/evm-cctp-contracts/blob/6e7513cdb2bee6bb0cddf331fe972600fc5017c9/src/MessageTransmitter.sol#L362) and [pranking](https://getfoundry.sh/reference/cheatcodes/prank/) the CCTP [attesters](https://github.com/circlefin/evm-cctp-contracts/blob/6e7513cdb2bee6bb0cddf331fe972600fc5017c9/src/roles/Attestable.sol#L212-L230).

### Proxy API

Information pertaining to the “strategy” with the highest yield (ie the chain and the protocol) is fetched from the [DefiLlama API](https://yields.llama.fi/pools) which returns a HUGE response. The response was too much for Chainlink Functions, so a proxy API to filter for the relevant data was required.

I made one and deployed it to AWS Lambda. The url for the API could have been abused (unlikely for a hackathon project, but a required consideration for a production ready project) so the url had to be properly encrypted with the [functions-toolkit](https://www.npmjs.com/package/@chainlink/functions-toolkit#functions-utilities](https://www.npmjs.com/package/@chainlink/functions-toolkit#encrypting-secrets) and then stored as a [constant](https://github.com/contractlevel/yield/blob/0cd489dc7a2fb2b7f2f949db890038dd33925873/src/peers/extensions/ParentCLF.sol#L33-L37) in the YieldCoin FunctionsClient contract (`ParentCLF`). This value needed to be different for different chains due to the chain-specific parameters required when executing the encrypted secrets process. Even though Chainlink Functions is used on the Parent chain only, the Parent chain changed between testnet deployments, so the chain-specific parameters for secrets encryption had to be considered.

### Time management/knowing what to prioritize

There were a lot of parts to this project and knowing which bit to prioritize, and when, was a challenge. Once the unit coverage was complete I played around with adding more yield strategies and implementing fees, before deciding to focus on invariant tests. More yield strategies wasn’t exactly essential to demonstrate the full functionality of the Chainlink integrations and the system itself. Implementing fees was much the same.

As security is so integral to smart contract development, I decided more testing of the system so far was a higher priority than additional features that wouldn’t showcase any more Chainlink use and could be added later.

Juggling researching and fixing the share mint calculation logic bug with getting an eligible submission done was a time management/priority challenge too.

I didn’t get to implement everything I would’ve liked due to the time constraints, but that just means this project now has a [roadmap of future developments](https://github.com/contractlevel/yield?tab=readme-ov-file#future-developments).

### Functions callback with max gas limit not being able to execute ccip sends

This was a big issue that didn’t become apparent until the testnet stage. The original idea for the rebalancing process went like this: Time-based Automation sends request via Chainlink Functions to fetch yield strategy with highest APY, and then the fulfillRequest callback triggers CCIP rebalance messages.

I suspected the Functions max gas limit may have been the cause of the issue, however the Tenderly calltrace showed the transaction failing on an unrelated revert - very confusing! I ended up asking in the discord hackathon support channel and received a response which led to the confirmation of my initial suspicions.

Solving this issue required a second Automation implementation, to trigger the CCIP rebalance messages based on the Functions request callback. This could have been done with Custom Logic Automation, but that likely would’ve meant using additional, redundant storage slots, so I opted for Log-trigger Automation. The idea for this being when a better strategy was returned by Chainlink Functions, an event detailing it would be emitted, and then Log-trigger Automation would listen for the event, then execute CCIP rebalance messages based on it.

The chain that would have required the Log-trigger Automation was Base Sepolia, because that is where the ParentPeer/CLF contract (the one that interacts with Chainlink Functions) was deployed.

Log-trigger Automation on Base Sepolia required approval from the Chainlink team, which I applied for and was granted (thanks). However efficiently using the time between needing this functionality and being granted access to it was crucial. I redeployed the entire infrastructure, so that the Parent peer contract was now on Ethereum Sepolia because Log-trigger Automation on that chain did not require preapproval. A few hours after successfully executing the full rebalance transaction, I was granted access on Base Sepolia. I appreciated the fast approval from Chainlink, but the project needed to move ahead.

### Certora Formal Verification of contracts that use Chainlink FunctionsRequest library

The Certora prover is a formal verification tool that attempts to explore all paths of a transaction, however it has its limitations - particularly when verifying contracts with “high path count”, because it causes the prover to “timeout” and the verification job stops, incomplete.

In the past I mostly ran into this problem using it on contracts with significant assembly usage, but due to the heavy use of strings and bytes in `FunctionsRequest::encodeCBOR()`, the prover timed out.

This was solved by adding the [`nondet_difficult_funcs`](https://docs.certora.com/en/latest/docs/prover/cli/options.html#nondet-difficult-funcs) flag when running Certora, which automatically summarized view/pure functions that were previously non-summarized and difficult for the Prover to verify.

### Yield generating strategy protocols either not working on testnet or not existing

Aave and Compound were the protocols chosen as yield generating strategies for this initial prototype. Unfortunately they were not fully available across all required testnets, so I had to use mocks in their place on testnets. These mocks function identically to their official production equivalents, but do not actually generate any yield. They are merely used to demonstrate depositing and withdrawing from these strategies.

### DefiLlama API not providing testnet data

Mainnet data was used for the strategy with the highest APY and testnet transactions were based on this.

### Incorrect placement of `networkConfig` cache before `vm.startBroadcast` in deploy script

This issue caused the wrong USDC address to be set in the constructor for a testnet deployment and was fixed by moving the line caching the `networkConfig` to after the `vm.startBroadcast`.

## Frontend

The frontend was built with [Next.js](https://nextjs.org/) and "vibe coded" with [v0.dev](https://v0.dev/). The AI integrated the [CCIP SDK](https://docs.chain.link/ccip/ccip-javascript-sdk) perfectly in 2 prompts, yet getting aesthetic elements correct such as text alignment in the footer was a struggle. The frontend is deployed directly from Vercel/v0.dev.

To run the frontend locally:

```
cd frontend
npm i
npm run dev
```

## Additional Comments

The `DepositToStrategyCompleted` event is emitted in `YieldPeer::_depositToStrategyAndGetTotalValue()`.

The `DepositToStrategy` event is emitted in `YieldPeer::_depositToStrategy()`.

`_depositToStrategyAndGetTotalValue()` calls `_depositToStrategy()`.

```
    /// @notice Deposits USDC to the strategy and returns the total value of the system
    /// @param amount The amount of USDC to deposit
    /// @return totalValue The total value of the system // _getTotalValueAndDepositToStrategy
    function _depositToStrategyAndGetTotalValue(uint256 amount) internal returns (uint256 totalValue) {
        address strategyPool = _getStrategyPool();
        totalValue = _getTotalValueFromStrategy(strategyPool);
        _depositToStrategy(strategyPool, amount);
        emit DepositToStrategyCompleted(strategyPool, amount, totalValue);
    }

    /// @notice Internal helper to deposit to the strategy
    /// @param strategyPool The strategy pool to deposit to
    /// @param amount The amount of USDC to deposit
    /// @dev Emit DepositToStrategy event
    function _depositToStrategy(address strategyPool, uint256 amount) internal {
        ProtocolOperations._depositToStrategy(strategyPool, _getProtocolConfig(), amount);
        emit DepositToStrategy(strategyPool, amount);
    }
```

The naming of these events is slightly confusing (and needs further review), but their purposes differ in that `DepositToStrategyCompleted` is only emitted for user deposits. Whereas `DepositToStrategy` is emitted for both user deposits and rebalance deposits.

## Acknowledgement

The idea for this project was inspired by the [Concero V2 Whitepaper, Section 7.1](https://concero.io/v2_whitepaper.pdf).
