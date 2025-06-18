# YieldCoin aka Contract Level Yield (CLY)

This project is being built for the Chainlink Chromion Hackathon, and is an automated, crosschain, stablecoin yield optimizer, powered by Chainlink Automation, Functions, and CCIP.

Whatever the highest yield is for stablecoins across chains is what users can earn in one click with Contract Level Yield.

## Table of Contents

- [YieldCoin aka Contract Level Yield (CLY)](#yieldcoin-aka-contract-level-yield-cly)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [YieldCoin](#yieldcoin)
  - [Architecture](#architecture)
    - [ParentPeer](#parentpeer)
  - [DefiLlama Proxy API](#defillama-proxy-api)
  - [Testing](#testing)
    - [Unit Tests](#unit-tests)
    - [Invariant Tests](#invariant-tests)
    - [Other Tests](#other-tests)
  - [Formal Verification](#formal-verification)
  - [Testnet Deployments](#testnet-deployments)
    - [Eth Sepolia](#eth-sepolia)
    - [Base Sepolia](#base-sepolia)
    - [Avalanche Fuji](#avalanche-fuji)
  - [Testnet Transactions](#testnet-transactions)
    - [Rebalance](#rebalance)
    - [Deposit tx from chain c (avalanche) → parent (eth) → strategy (base)](#deposit-tx-from-chain-c-avalanche--parent-eth--strategy-base)
    - [Withdraw tx from chain c (avalanche) → parent (eth) → strategy (base)](#withdraw-tx-from-chain-c-avalanche--parent-eth--strategy-base)
    - [YieldCoin Bridge tx (eth -\> aval)](#yieldcoin-bridge-tx-eth---aval)
  - [Future Developments](#future-developments)

## Overview

**Problem statement**: "I want my stablecoins to earn the highest possible yield without having to monitor opportunities, then manually withdraw, bridge and deposit."

**Solution**: YieldCoin abstracts ALL of that crap away. Deposit your stablecoin into the CLY system from your chain of choice to earn the highest yield from the safest, most reliable services across the web3 ecosystem.

Stablecoin depositors receive a share token in return for their deposits, representing their share of the total value (deposits + yield) in the system. Depositing a stablecoin can also be considered buying YieldCoin. YieldCoin is the share received for depositing into the system, with the basic idea being that a holder will be able to sell (their YieldCoin) for a higher USD value than they bought it. This is because the stablecoin deposits will not go down in value, and reliable yield will be generated. Hence the name YieldCoin.

key invariant: a user must be able to withdraw the usdc amount they deposited - fees. this is definitely broken by the precision loss bug we already know

## YieldCoin

YieldCoin follows the [ERC677](https://github.com/ethereum/EIPs/issues/677) and [CCT](https://docs.chain.link/ccip/concepts/cross-chain-token) standards for maximum efficiency and interoperability. The YieldCoin CCIP pools are permissionless, allowing holders to move freely across chains. `ERC677.transferAndCall()` enables holders to withdraw USDC in a single tx, without having to approve the CLY infrastructure to transfer their YIELD first.

The more fees CLY generates, ie the more YieldCoin is bought, the more frequent the checks for the highest APY can become, as Chainlink fees are covered.

“one click highest yield”

## Architecture

The Contract Level Yield system that powers YieldCoin consists of a crosschain network of "Peer" contracts. `YieldPeer` contracts are deployed on each compatible chain, and act as entry points to the system. Currently the only supported stablecoin is `USDC` (due partially to its availability across chains with CCIP and the time constraints of the hackathon).

Users deposit their `USDC` into the CLY infrastructure from their chain of choice. In return they receive YieldCoin ($YIELD) tokens. The amount of YieldCoin a depositor is minted in exchange for their stablecoin deposit is proportional to how much of the system's total value (total deposits + generated yield) their stablecoin deposit is worth. The basic idea is that a user will always be able to redeem their YieldCoin for the stablecoin they deposited plus yield (minus fees, but fees haven't been implemented yet).

THAT LAST PARAGRAPH IS A BIT REPETITIVE WITH THE PREVIOUS SECTION // @review

There are two types of `YieldPeer` contracts: a `ParentPeer` and a `ChildPeer`. There is a single `ParentPeer` contract deployed across chains, with every other compatible chain hosting a `ChildPeer`. See [./src/peers](https://github.com/contractlevel/yield/tree/main/src/peers).

`YieldPeer` is an abstract contract that acts as the "base" for both the `ParentPeer` and `ChildPeer` contracts. The Parent and Child peers share some functionality, but also have functionality unique to their particular roles in the system. The shared `YieldPeer` functionality consists primarily of CCIP integrations and yield strategy interactions.

### ParentPeer

The `ParentPeer` tracks system wide state for Contract Level Yield, specifically the total shares (YieldCoin) minted, and the current yield strategy. `ParentPeer::s_totalShares` is the sum of all shares/YieldCoin that exists across chains. `ParentPeer::s_strategy` is a struct containing the chain selector and protocol of the current yield generating strategy.

The `ParentPeer` contract is extended with the `ParentCLF` contract - see [./src/peers/extensions/ParentCLF.sol](https://github.com/contractlevel/yield/blob/main/src/peers/extensions/ParentCLF.sol). `ParentCLF` inherits `ParentPeer` and implements Chainlink Functions functionality. As such, `ParentCLF` is the single `ParentPeer` instantiation deployed in the system. `ParentCLF` also implements functionality to make it compatible with Chainlink Automation.

`ParentRebalancer` - see [./src/modules/ParentRebalancer.sol](https://github.com/contractlevel/yield/blob/main/src/modules/ParentRebalancer.sol) - is deployed on the same chain as `ParentCLF`. The `ParentRebalancer` contract provides supplementary log trigger automation functionality to `ParentCLF`, as the `ParentCLF` contract is unfortunately too big to contain it all itself.

## DefiLlama Proxy API

```
cd functions/defillama-proxy
npm i
```

The `function.zip` file located in `functions/defillama-proxy` has been uploaded to AWS Lambda and deployed. This was needed because we are using the DefiLlama API to fetch data about APYs, but the payload response was too large for Chainlink Functions, so we filter on the server side via our proxy API.

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

The unit tests use a [fork of chainlink-local](https://github.com/contractlevel/chainlink-local). Since the unit tests are performed on forked mainnets, additional functionality was required from chainlink-local in order to facilitate USDC transfers. USDC transfers on CCIP integrate [Circle's CCTP](https://www.circle.com/cross-chain-transfer-protocol), which comes with additional checks that weren't included in the original chainlink-local. The CCTP architecture requires USDC transfer messages to be "validated by attesters". These messages need to be in a [specific format](https://github.com/circlefin/evm-cctp-contracts/blob/6e7513cdb2bee6bb0cddf331fe972600fc5017c9/src/MessageTransmitter.sol#L228-L247) and the attester's signatures need to be in a [specific order](https://github.com/circlefin/evm-cctp-contracts/blob/6e7513cdb2bee6bb0cddf331fe972600fc5017c9/src/MessageTransmitter.sol#L246-L247).

To achieve this, the changes were made to the [CCIPLocalSimulatorFork](https://github.com/contractlevel/chainlink-local/blob/main/src/ccip/CCIPLocalSimulatorFork.sol). A new function, [switchChainAndRouteMessageWithUSDC](https://github.com/contractlevel/chainlink-local/blob/519e854caaf1291c03bda3928674c922195fd629/src/ccip/CCIPLocalSimulatorFork.sol#L126-L155) was added, which is based on the original `switchChainAndRouteMessage`, except it also listens for CCTP's `MessageSent` event, and takes two arrays of attester addresses, and their private keys - values that can be easily simulated with [Foundry's makeAddrAndKey](https://getfoundry.sh/reference/forge-std/make-addr-and-key/).

The `offchainTokenData` array passed to the offRamp needed to contain the USDCTokenPool's `MessageAndAttestation` struct, which contains the message retrieved from the `MessageSent` event and the `attestation` created with the attester's and their private keys. To achieve this, another function was added, [\_createOffchainTokenData](https://github.com/contractlevel/chainlink-local/blob/519e854caaf1291c03bda3928674c922195fd629/src/ccip/CCIPLocalSimulatorFork.sol#L181-L238).

The unit tests for the Contract Level Yield contracts can be run with:

```
forge test --mt test_yield
```

### Invariant Tests

DISCUSS https://github.com/contractlevel/chainlink-local/commit/f56369e24807796e6bd636970d145bb6394a33f6 CHAINLINK-LOCAL FORK HERE

The invariant test suite also uses the fork of chainlink-local, and can be run with:

```
forge test --mt invariant
```

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

The `BasePeer` spec verifies mutual behavior of the Parent and Child Peers, so there are separate `conf` files for verifying each of them against it.

```
certoraRun ./certora/conf/child/BaseChild.conf
certoraRun ./certora/conf/parent/BaseParent.conf
```

The `Parent` and `Child` specs verify behaviors particular to their respective peers.

```
certoraRun ./certora/conf/parent/Parent.conf
certoraRun ./certora/conf/child/Child.conf
```

The `Yield` spec verifies internal properties of the abstract `YieldPeer` contract such as depositing to and withdrawing from strategies, as well as CCIP tx handling.

```
certoraRun ./certora/conf/Yield.conf
```

The `ParentCLF` spec verifies logic related to Chainlink Functions and Automation.

```
certoraRun ./certora/conf/parent/ParentCLF.conf --nondet_difficult_funcs
```

The `--nondet_difficult_funcs` flag is required for `ParentCLF` to [automatically summarize functions](https://docs.certora.com/en/latest/docs/prover/cli/options.html#nondet-difficult-funcs) in the `FunctionsRequest` library because otherwise the Certora Prover will timeout. The Certora Prover explores all possible paths and the `FunctionsRequest::encodeCBOR` includes an extremely high path count, making it difficult to verify.

## Testnet Deployments

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

### Rebalance

time based auto triggers CLF https://sepolia.etherscan.io/tx/0xc8159327d9c76b118c2caa10c9db513cc38c2c7a00e3c2f026df12d2b5e6190a

clf request callback https://sepolia.etherscan.io/tx/0x2521aea1c73c8ace2b5630b74c60857788944479e8dcd8a7a8362a74f8970a8b

log trigger auto https://sepolia.etherscan.io/tx/0x1099dbd2cd04403635b820cd17508aa7c56929bc99187b39a543a7b36cd50e4d

ccip rebalance https://ccip.chain.link/#/side-drawer/msg/0xb01894363f416f83171ee994cd043eacf4cc487bc2d8a589229d02c2649ed10b

dst tx: https://sepolia.basescan.org/tx/0x35f97388d654b63d80f4d9b88eab11fb4ee16a909862dd19338c8a758565a70c

### Deposit tx from chain c (avalanche) → parent (eth) → strategy (base)

deposit tx: https://testnet.snowtrace.io/tx/0x68b8118e9e9115e8f8956cc05edc06d8fe281f0955a762c830d98a7f87230a06?chainid=43113

deposit to parent: https://ccip.chain.link/#/side-drawer/msg/0x2a996da193b64a4c4c719921655e5fe57d8292914a48572cfafec02c5349bfc7

dst tx: https://sepolia.etherscan.io/tx/0x6685ae8f7c883ab2f83ea43afe838f51b1b8270eab16ebb26cc1782012766fc4

deposit to parent and deposit to strategy: https://ccip.chain.link/tx/0x6685ae8f7c883ab2f83ea43afe838f51b1b8270eab16ebb26cc1782012766fc4

strategy chain deposit: https://sepolia.basescan.org/tx/0x75e0f2ec96dde84126c8ec36f1bc5467c69bdb0b41e5c211e8ab99c65189baa3

deposit callback parent: https://ccip.chain.link/tx/0x75e0f2ec96dde84126c8ec36f1bc5467c69bdb0b41e5c211e8ab99c65189baa3

parent callback:

https://sepolia.etherscan.io/tx/0x905c386823c1bceeb07a51c4d67effff82f8db7e1d16f2349fe2ffd053263f8f

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

- more stablecoin support (swapping to one with highest yield)
- more chains
- more yield strategies/protocols
- fees
- svm compatability
- ccip calldata compression (should use solady.libZip for compressing/decompressing depositData, withdrawData and strategy struct)
- uniswap integration to allow users to "buy" yieldcoin with any asset, ie they pay with eth and it gets swapped to the usdc amount then deposited
