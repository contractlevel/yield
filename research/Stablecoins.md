# Stablecoin Integration Research

## Overview

Research document for integrating stablecoin swapping capabilities into the yield protocol. This document explores various DEX options, integration approaches, and considerations for cross-chain stablecoin operations.

---

Emerging Questions during research:

- What if we deposit to DEX LPs? Some are "AAVE boosted" --- seemingly lower APY % than AAVE, needs investigation
- What about the newer EVM chains? Some are CCIP connected + institutional usage is already there
- There are additional Chain-specific DEXs, with substantially bigger pools for USDC/USDT. Consider making own DEX Aggregator for such cases, or search for established ones. (eg Blackhole on AVAX with 24M USDC/USDT pool `0x859592a4a469610e573f96ef87a0e5565f9a94c8`, Aerodrome on BASE with 2.7M `0xa41bc0affba7fd420d186b84899d7ab2ac57fcd1`)

## Fundamental Limitations & Risks

### 1. Liquidity Constraints

**USDC/USDT Liquidity Fragmentation**

- Chain-specific liquidity limitations
- **Potential Solution**: Concero/Lanca unified liquidity approach

**Critical Questions:**

- Is current liquidity sufficient for full TVL swaps?
- Will large TVL impact APR through slippage?

### 2. Rebalancing Frequency Optimization

**Slippage vs. Performance Trade-off**

- Frequent rebalancing may cause more loss than gain
- Large TVL + frequent rebalancing = significant slippage costs
- Large TVL deposits might/will impact Strategy APY %, need to account for that before switching strategies
- This can also be attacked to mess with Rebalancer
- **Solution**: Optimize rebalancing frequency based on TVL size, more Rebalancer logic to handle Strategy changes due to own TVL deposits

### 3. Single-Point-of-Failure Risks

**USDC/Concero Dependency**

- Dependency on single routing mechanism
- **Mitigation**: Implement monitoring and fallback routes
- **Goal**: Multi-path routing for redundancy

### 4. TVL Risk Management

**Error Handling & Fallback Logic**

- Failed swaps put entire TVL at risk
- **Protection**: TWAP mechanisms
- **Requirement**: Robust error recovery systems

### 5. Security Considerations

**Attack Surface Expansion**

- Each integration introduces new attack vectors
- **Mitigation**: Comprehensive security audits
- **Strategy**: Minimal viable integration approach

### 6. Gas Cost Optimization

**Scaling Challenges**

- Gas costs increase with user deposit volume
- Small deposits still require full swap processing
- **Solution**: Implement batching mechanisms

### 7. Emergency Scenarios

**Depeg Risk Management**

- Handle stablecoin depeg events
- **Requirement**: Emergency pause and withdrawal mechanisms
- **Protection**: Circuit breakers for extreme market conditions

## DEX Integration Options

### Uniswap V4

**Code Integration:** See [Uniswap V4 Integration](#uniswap-v4-integration) for implementation details.

**Pros:**

- ✅ Hooks allow custom logic and MEV protection
- ✅ Singleton contract reduces gas costs, liquidity depth increased
- ✅ Advanced gas optimizations

**Cons:**

- ❌ More complex due to hooks (requires audit)
- ❌ New protocol (2024), liquidity still migrating
- ❌ Current liquidity: USDC/USDT Pool on Ethereum v4 24.8M, v3 22.4M

**Liquidity Status:**

- Ethereum: v4 24.8M, v3 22.4M
- Base: v4 300k
- Arbitrum: v4 8.6M, v3 2.8M

### Uniswap V3

**Code Integration:** See [Uniswap V3 Integration](#uniswap-v3-integration) for implementation details.

**Pros:**

- ✅ Deep liquidity across multiple chains
- ✅ Better efficiency for swaps
- ✅ Low slippage with 0.01% fee tier for stables
- ✅ Battle-tested protocol
- ✅ Strong USDC/USDT liquidity on multiple chains

**Cons:**

- ❌ Higher gas costs than V2
- ❌ Requires chain deployment verification

### Uniswap V2

_Note: Considered outdated for stablecoin swaps_

**Pros:**

- ✅ Simple architecture
- ✅ Lower gas costs than V3
- ✅ Easy integration

**Cons:**

- ❌ Less liquidity depth for stables
- ❌ Protocol phasing out
- ❌ Higher slippage for stablecoin pairs

---

### Lanca (Concero)

**Code Integration:** See [Lanca (Concero) Integration](#lanca-concero-integration) for implementation details.

**Two Integration Options:**

1. SDK-Based Integration (JavaScript/TypeScript)
2. Smart Contract Integration (Solidity)

**Pros:**

- ✅ Native CCIP integration (aligned with our stack)
- ✅ Cross-chain swaps in a single transaction
- ✅ Better rates through Concero optimization
- ✅ ~0 slippage for bridging (mint/burn mechanism)

**Cons:**

- ❌ Limited adoption currently
- ❌ May require significant integration time
- ❌ Learning curve for Concero ecosystem

### XSwap --- Ongoing talks on discord with their support for more information!

**Pros:**

- ✅ Promising technology

**Cons:**

- ❌ Very early stage development
- ❌ Limited documentation and adoption

---

### Cowswap

_Note: INCOMPATIBLE with CCIP message flow_

**Pros:**

- ✅ Strong MEV protection
- ✅ Virtually 0 slippage
- ✅ EVM compatible

**Cons:**

- ❌ Batch execution may slow process
- ❌ Cross-chain via CCIP integration challenges
- ❌ Limited to EVM chains

---

### Curve Finance

**Code Integration:** See [Curve Finance Integration](#curve-finance-integration) for implementation details.

**Pros:**

- ✅ Built specifically for stablecoins
- ✅ Deepest liquidity: Eth 3Pool DAI/USDC/USDT 177M
- ✅ Multi-chain deployment
- ✅ Low fees (0.04% typically)
- ✅ Minimal slippage for stablecoin pairs

**Cons:**

- ❌ Adding stables beyond USDC/USDT/DAI is complex
- ❌ Requires chain availability verification
- ❌ Vyper contracts need Solidity interface implementation

---

### DEX Aggregators (1inch, Paraswap, etc.)

_Note: Overkill for simple USDC/USDT swaps_

**Cons:**

- ❌ Dependency on underlying DEX liquidity
- ❌ Additional complexity and gas costs
- ❌ API complexity and potential front-running risks
- ❌ Unnecessary overhead for straightforward stablecoin swaps

---

## Liquidity Considerations & Limitations

### Key Concerns

#### 1. Chain-Specific Liquidity Depth

- Different chains have varying liquidity depths for stablecoin pairs
- USDC/USDT pairs typically have the deepest liquidity across most chains
- Need to verify liquidity availability before executing large swaps

#### 2. Stablecoin Support Fragmentation

- Stablecoin support varies significantly across protocols and chains
- Whitelisted stables differ between DEXs and chains
- Some chains may not support certain stablecoins

#### 3. Liquidity Fragmentation

- Multiple chains, pool versions, and fee tiers create fragmentation
- Future need to choose optimal swap locations based on multiple factors
- USDC pre-swapping may become the most efficient approach
- **Lanca/Concero addresses this by treating cross-chain pools as unified**

#### 4. Liquidity Reliability

- Risk of liquidity exit during high volatility periods
- V1 should focus on most liquid pairs (typically USDC/USDT)
- Need circuit breakers for extreme market conditions

#### 5. Slippage Management

- Pre-execution slippage estimation required
- Route through deepest available pools
- Implement dynamic slippage tolerance based on trade size

#### 6. Risk Mitigation Strategies

- Monitor pool health and liquidity
- Implement fallback routes for failed swaps
- Consider Curve Finance for stablecoin-specific pools
- Depeg protection mechanisms

---

## USDC as Cross-Chain Standard

### CCIP Lane Analysis

**Question:** Is it substantially better to always pre-emptively swap to USDC?

**Answer: YES** - USDT has limited 1st phase CCIP lanes (only ETH, Optimism, and Base)

### USDC Advantages

#### 1. Superior CCIP Coverage

- **USDC**: Deep liquidity on Ethereum, Base, Arbitrum, Avalanche, Polygon
- **USDT**: Substantially lower liquidity on Base, limited CCIP lanes

#### 2. Native Integration Benefits

- Native mint/burn mechanism (no wrappers required)
- Lower bridging fees through Concero
- Direct CCIP integration

#### 3. Recommended Architecture

```
Source Chain: Any Stablecoin → USDC → CCIP Bridge
Destination Chain: CCIP Bridge → USDC → Target Stablecoin
```

**Benefits:**

- ✅ Minimizes complexity
- ✅ Leverages CCIP infrastructure
- ✅ Reduces bridging costs
- ✅ Standardizes cross-chain operations

---

## Slippage Management Strategy

### Core Principle

**Goal:** Minimize slippage while ensuring transaction success

### Slippage Optimization Techniques

#### 1. Dynamic Slippage Tolerance

- **Large trades**: 0.5% slippage tolerance
- **Small trades**: Tighter tolerance (0.1-0.3%)
- **Risk**: Very low tolerance may cause transaction failures

#### 2. Pool Selection Strategy

- Route through deepest available pools
- Avoid small DEX pools with limited liquidity
- Target 0.05% fee stable pools (ideal for pegged pairs)
- Higher fee pools often have deeper liquidity

#### 3. Cross-Chain Slippage Mitigation

- Use pegged bridges for 0 cross-chain slippage
- Leverage Concero's mint/burn mechanism
- Minimize intermediate swaps

#### 4. Advanced Slippage Management

- Query Chainlink for fair prices pre-swap
- Compare market rates to determine acceptable slippage
- Implement deadline checks for time sensitivity
- Consider cumulative slippage from multiple swaps

#### 5. Large Trade Handling

- Route splitting for very large swaps
- Essential for TVL movements between cross-chain strategies
- Distribute across multiple pools to minimize impact

---

## Contract Architecture Requirements

### Do we need additional contracts for DEX integration?

**Answer:** Depends on DEX vs Cross-Chain Swap Abstraction choice. If using multiple DEXs - **YES!**

### Swapper.sol Requirements

#### 1. DEX Abstraction Layer

- Unified interface for multiple DEXs
- Adapter pattern for each DEX integration
- Dynamic DEX addition/removal capability

#### 2. Route Optimization Engine

- Query multiple DEXs for best rates
- Intelligent route selection algorithm
- Route splitting for large trades

#### 3. Slippage Protection System

- Automatic slippage calculations
- Minimum output enforcement
- Dynamic tolerance adjustment

#### 4. MEV Protection

- MEV-protected relayers integration
- Private mempool routing options

#### 5. Safety Mechanisms

- Deadline enforcement
- Emergency pause functionality
- Circuit breakers for extreme conditions

#### 6. Gas Optimization

- Batch operations where possible
- Efficient encoding for CCIP messages
- Optimized token approval patterns

#### 7. Monitoring & Analytics

- Comprehensive event emissions
- Slippage tracking and reporting
- Performance metrics collection

#### 8. Upgradeability Framework

- Modular DEX integration
- Dynamic stablecoin support
- Configurable parameters

#### 9. Critical Considerations

- **Failed swap handling**: Robust error recovery
- **CCIP message timing**: Before or after swap execution
- **Integration complexity**: Swap logic in CCIP messages adds significant complexity
- **Audit requirements**: Increased surface area for security reviews

---

## Concero Integration Strategy

### Can Concero abstract the swap process through cross-chain messages?

### Integration Options

#### 1. Concero Embedded Swaps

**Approach:** Single transaction with embedded swap logic

```
CCIP Message: { fromToken, toToken, minOutput, swapParams }
Concero: Executes swaps with integrated DEXs
```

**Questions for Concero Team:**

- Can we include swap data in cross-chain messages?
- Which services are plug-and-play compatible?
- Does Lanca provide this functionality?
- v1 vs v2 capabilities?
- Slippage protection handling?
- Swap fallback logic implementation?
- Are the swap data encrypted, can we encrypt to minimize attacks

#### 2. Hybrid Approach

**Architecture:**

- Concero: CCIP messaging + USDC bridging
- Custom Swapper.sol: Source and destination chain swaps
- CCIP message: Includes destination swap parameters

**Benefits:**

- ✅ Maximum flexibility and optimization
- ✅ Better error handling and transparency
- ✅ Custom slippage and routing logic
- ✅ Full control over swap execution

#### 3. Questions for Concero Meeting

- Cross-chain swap data inclusion capabilities
- Integrated DEX service availability
- Lanca integration specifics
- Version compatibility (v1/v2)
- Team walkthrough request

---

## MEV Protection Strategies

### Uniswap MEV Mitigation

#### 1. UniswapX Integration

- **MEV Protection**: Meta-aggregator with built-in protection
- **Availability**: Currently on Ethereum and Base
- **Benefits**: Advanced MEV protection for large trades

#### 2. UniswapWallet Private Pools

- Private pool functionality
- Reduced MEV exposure for sensitive trades

#### 3. Pool Selection Strategy

- **Deep Liquidity Focus**: Trade on pools with highest liquidity
- **Shallow Pool Risk**: Large trades on shallow pools are MEV targets
- **Stablecoin Advantage**: 0.01-0.1% spreads make front-running less profitable

#### 4. Protection Mechanisms

##### Flashbots Protect

- Sends transactions directly to builders
- **Trade-off**: Slower execution for MEV protection

##### MEV Blocker

- RPC endpoint that prevents front-running
- Real-time MEV protection

##### Uniswap V4 Hooks

- Custom MEV protection through hooks
- Advanced protection strategies
- Programmable MEV mitigation

---

## DEX Integration Code Examples

This section contains detailed code implementation examples for each DEX integration option. Use these as reference when implementing the actual integration.

### Uniswap V4 Integration

- Interaction Model: To use Uniswap v4, you do not call swap directly. You call the unlock function, which then calls your contract back. Inside this callback, your contract calls swap.

- Smart Contract Intermediaries: All interactions with the PoolManager's core functions must be performed through a smart contract that implements the IUnlockCallback interface.

This is used for the low-level, direct interaction with PoolManager.

```javascript
import {SafeCallback} from "v4-periphery/src/base/SafeCallback.sol";

contract IntegratingContract is SafeCallback {
    constructor(IPoolManager _poolManager) SafeCallback(_poolManager) {}
    function unlockCallback(bytes calldata rawData) external returns (bytes memory);
}
```

- Transient Storage for Efficiency: The lock is implemented using gas-efficient transient storage (tstore/tload), which maintains state only for the duration of a single transaction.

- Enforced Currency Settlement: The NonzeroDeltaCount mechanism guarantees that all token deltas are fully settled, ensuring the pool's accounting is balanced before a transaction can succeed.

This is used for the high-level, recommended approach using the Universal Router.

Libraries for interacting with the Universal Router:

```javascript
forge install uniswap/v4-core
forge install uniswap/v4-periphery
forge install uniswap/permit2
forge install uniswap/universal-router
forge install uniswap/v3-core
forge install uniswap/v2-core
forge install OpenZeppelin/openzeppelin-contracts
```

```javascript
import { UniversalRouter } from "@uniswap/universal-router/contracts/UniversalRouter.sol";
import { Commands } from "@uniswap/universal-router/contracts/libraries/Commands.sol";
import { IPoolManager } from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import { IV4Router } from "@uniswap/v4-periphery/src/interfaces/IV4Router.sol";
import { Actions } from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import { IPermit2 } from "@uniswap/permit2/src/interfaces/IPermit2.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { StateLibrary } from "@uniswap/v4-core/src/libraries/StateLibrary.sol";

contract UniswapV4Swapper {
  UniversalRouter public router;
  IPoolManager public poolManager;
  IPermit2 public permit2;

  constructor(
    address _router,
    address _poolManager,
    address _permit2,
    address _usdt,
    address _usdc
  ) {
    router = UniversalRouter(payable(_router));
    poolManager = IPoolManager(_poolManager);
    permit2 = IPermit2(_permit2);
    USDT = _usdt;
    USDC = _usdc;
  }

  struct PoolKey {
    /// @notice The lower currency of the pool, sorted numerically.
    ///         For native ETH, Currency currency0 = Currency.wrap(address(0));
    Currency currency0;
    /// @notice The higher currency of the pool, sorted numerically
    Currency currency1;
    /// @notice The pool LP fee, capped at 1_000_000. If the highest bit is 1, the pool has a dynamic fee and must be exactly equal to 0x800000
    uint24 fee;
    /// @notice Ticks that involve positions must be a multiple of tick spacing
    int24 tickSpacing;
    /// @notice The hooks of the pool
    IHooks hooks;
}

//This function first approves Permit2 to spend the token, then uses Permit2 to approve the UniversalRouter with a specific amount and expiration time
function approveTokenWithPermit2(
    address token,
    uint160 amount,
    uint48 expiration
) external {
    IERC20(token).approve(address(permit2), type(uint256).max);
    permit2.approve(token, address(router), amount, expiration);
}

  function swapExactInputSingle(
    PoolKey calldata key, // PoolKey struct that identifies the v4 pool
    uint128 amountIn,     // Exact amount of tokens to swap
    uint128 minAmountOut, // Minimum amount of output tokens expected
    uint256 deadline      // Timestamp after which the transaction will rever
  ) external returns (uint256 amountOut) {
    // Implementation of swap
  }
}
```

### Uniswap V3 Integration

```javascript
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract UniswapV3Swapper {
  ISwapRouter public swapRouter;
  address public constant USDT = 0x12345;
  address public constant USDC = 0x54321;
  uint24 public constant FEE_TIER = 100;

  //*Deposit & Withdraw with _swapUSDTForUSDC call
  // code...
  //


  function _swapUSDTForUSDC(uint256 amountIn)
    external
    returns (uint256 amountOut)
  {
    // TransferHelper code for transferring amount to Swapper.sol
    // TransferHelper code for approving router

    // set up parameters based on preference
    // can ExactOutputSingleParams as well
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
      .ExactInputSingleParams({
        tokenIn: USDT,
        tokenOut: USDC,
        fee: feeTier, // Fee tier of the pool (0.01% for stables)
        recipient: msg.sender,
        deadline: block.timestamp,
        amountIn: amountIn,
        amountOutMinimum: minOut,
        sqrtPriceLimitX96: priceLimit // Price limit for MEV protection
      });

    amountOut = swapRouter.exactInputSingle(params);
  }
}
```

### Lanca (Concero) Integration

#### Lanca for Bridging USDC + Message, Concero for Messages

==> Abstracted Bridge & Swap discontinued.

### Curve Finance Integration

`cast interface from https://polygonscan.com/address/0xF0d4c12A5768D806021F80a262B4d39d26C58b8D`

```javascript
// Curve uses Vyper contracts, requires Solidity interface implementation
interface ICurvePool {
  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external returns (uint256);
}

contract CurveSwapper {
  ICurvePool public curvePool;

  function swapStablecoins(
    int128 fromIndex,
    int128 toIndex,
    uint256 amountIn,
    uint256 minAmountOut
  ) external returns (uint256 amountOut) {
    amountOut = curvePool.exchange(fromIndex, toIndex, amountIn, minAmountOut);
  }
}
```

https://github.com/ensuro/swap-library

### Balancer Integration

https://github.com/balancer/balancer-v3-monorepo/tree/main

---

### USDC & USDT Liquidity Pools Across Chains

| Chain         | Protocol   | Pool                   | Fee Tier | Liquidity     | Notes                       | Pool Address                                                                                                                                 |
| ------------- | ---------- | ---------------------- | -------- | ------------- | --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| **Ethereum**  | Uniswap V3 | USDC/USDT              | 0.01%    | $25.1M        | Add. 1M pool                | `0x3416cf6c708da44db2624d63ea0aaef7113527c6`                                                                                                 |
|               | Uniswap V4 | USDC/USDT              | -        | $23.8M        | Add. 0.75M pool             | `v4 PoolId: 0x8aa4e11cbdf30eedc92100f4c8a31ff748e201d44712cc8c90d189edaa8e4e47`                                                              |
|               | Curve      | 3Pool (USDC/USDT/DAI)  | -        | $177M         |                             | `0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7`                                                                                                 |
|               | Balancer   | 3Pool (USDC/USDT/GHO)  | -        | $23.6M        | AAVE boosted                | `0x85b2b559bc2d21104c4defdd6efca8a20343361d`                                                                                                 |
| **Arbitrum**  | Uniswap V3 | USDC/USD₮0             | 0.01%    | $3.5M         | Add. shallow                | `0xbe3ad6a5669dc0b8b12febc03608860c31e2eef6`                                                                                                 |
|               | Uniswap V4 | USDC/USD₮0             | -        | $7.8M         |                             | `v4 0xab05003a63d2f34ac7eec4670bca3319f0e3d2f62af5c2b9cbd69d03fd804fd2`                                                                      |
|               | Curve      | USDC/USD₮0             | -        | $3.9M         |                             | `0x7f90122BF0700F9E7e1F688fe926940E8839F353`                                                                                                 |
|               | Balancer   | 3Pool (USDC/USD₮0/GHO) | -        | $11M          | AAVE boosted                | `0x19B001e6Bc2d89154c18e2216eec5C8c6047b6d8`                                                                                                 |
| **Avalanche** | Uniswap V3 | USDC/USDt              | 0.01%    | $635K         | USDt used                   | `0x804226cA4EDb38e7eF56D16d16E92dc3223347A0`                                                                                                 |
|               | Uniswap V4 | USDC/USDt              | -        | $400K         | USDt used                   | `v4 0x8dc096ecc5cb7565daa9615d6b6b4e6d1ffb3b16cca4e0971dfaf0ed9cb55c63`                                                                      |
|               | Curve      | USDC/USDt              | -        | $150K-2M      | weird??                     | [Curve Avalanche](https://www.curve.finance/dex/avalanche/pools?filter=usd&sortBy=tvl)                                                       |
|               | Balancer   | 3Pool USDC/GHO/USDt    | -        | $314K         | AAVE boosted                | `0xfCec3c8D86329DEfB548202Fe1b86Ff2188603A8`                                                                                                 |
| **Base**      | Uniswap V3 | USDC/USDT              | 0.01%    | $137K         |                             | `0xd56da2b74ba826f19015e6b7dd9dae1903e85da1`                                                                                                 |
|               | Uniswap V4 | USDC/USDT              | -        | $320K         | 2 Pools                     | `v4 0x841c1a22d9a505cbba3e9bf90fd43e1201a09932ca0a90816579346be5f092af` `0xf13203ddbf2c9816a79b656a1a952521702715d92fea465b84ae2ed6e94a7f22` |
|               | Balancer   | USDC/USDT              | -        | $20K          |                             | `0xa42c17f94558430cd8f8ef3d924e761084fca6f0`                                                                                                 |
|               | Curve      | 4Pool                  | -        |               | no USDT                     | [Curve Base](https://www.curve.finance/dex/base/pools?filter=usd)                                                                            |
| **Polygon**   | Uniswap V3 | USDC.e/USDT0           | 0.01%    | $854K + $500K | 2Pools: USDC, USDC.e, USDT0 | `0xDaC8A8E6DBf8c690ec6815e0fF03491B2770255D` & `0x31083a78e11b18e450fd139f9abea98cd53181b7`                                                  |
|               | Uniswap V4 | USDC/USDT0             | -        | $244.6K       | Add 100K USDC.e/USDT0 pool  | `v4 0xa37d3e6da98dfeb7dc8103a6614f586916a6e04d41ea0a929bc19a029de1a399`                                                                      |
|               | Curve      | 5Pool                  | -        | $3.8M         | wBTC,wETH mixed             | `0x92215849c439E1f8612b6646060B4E3E5ef822cC`                                                                                                 |
|               | Balancer   | 4Pool V2               | -        | $98K          | DAI, miMATIC                | `0x06df3b2bbb68adc8b0e302443692037ed9f91b42`                                                                                                 |
| **Optimism**  | Uniswap V3 | USDC/USDT              | 0.01%    | $240.6K       | Add. USDC.e                 | `0xa73c628eaf6e283e26a7b1f8001cf186aa4c0e8e` & `0xF1F199342687A7d78bCC16fce79fa2665EF870E1`                                                  |
|               | Uniswap V4 | USDC/USDT              | -        | $392.3K       |                             | `v4 0xebe9db89947dd14b34817843231b74044084b04d5b4fea5b4cd1b433b3e5b99f`                                                                      |
|               | Curve      | 3Pool USDC/USDT/DAI    | -        | $200K         |                             | `0x1337BedC9D22ecbe766dF105c9623922A27963EC`                                                                                                 |
|               | Balancer   | USDC/USDT              | -        | $10K          | 99-1 weighted               |                                                                                                                                              |

## Traditional DEX vs PMMs

### Bebop

#### What is Bebop?

Bebop is a trading app and a suite of APIs that finds the best route for any trade, executing trades for any tokens in any size at the best prices, created by Wintermute.

It uses a dual model system of:

1. **Request for Quote (RFQ) on-chain:**

   - Sources liquidity from private market makers who constantly stream their pricing to Bebop
   - Orders are sent to private market makers and then settled on-chain

2. **Bebop JAM:**
   - Just-In-Time aggregation model designed to complement the existing RFQ system, offering trade outcomes with optimal prices and even the possibility of trade surpluses
   - Solvers compete to find best execution paths, combining both liquidity from private (market makers) and on-chain sources

**Bebop JAM contracts + Comprehensive README:** https://github.com/bebop-dex/bebop-jam-contracts

#### How it works:

1. User requests a quote
2. Private Market Makers provide quotes with gas included
3. User accepts or rejects quote
4. Smart contract settles the trade without Bebop taking custody of fund

#### The Appeal

- ✅ Price certainty / zero slippage in RFQ mode (max slippage 0.2%)
- ✅ No MEV
- ✅ Maker Depth: USDT Liquidity on certain chains is dry and a solution needs to be found
- ✅ Multi-Chain support: Ethereum, Avalanche, Arbitrum, Base, Optimism, Polygon supported
- ✅ Offers API/router for path-finding, quoting and solver matching
- ✅ Includes GAS in final price

#### The Problems

- ❌ **API Dependency:** This sounds simpler than it is. Bebop requires API calls to get RFQ quotes, submit trades. Cannot be done purely on-chain which means => Chainlink Functions, additional point of failure, more complex than direct DEX integration

- ❌ **Trust:** Need to trust Bebop for everything. We can only verify if quote is better than DEX, not overall.

- ❌ **Quote Validity Time:** RFQ quotes expire (~60 seconds)

  **What this means:**

  - Time 0: Rebalance threshold triggered, Functions Call to Parent Peer (maybe to Bebop API simultaneously)
  - Time 30: Parent Peer updated, Rebalance initiated, CCIP/Lanca/Concero Calls started
  - Time 120 (Optimistic): Withdraw from protocol
  - Time 240: USDC burned on old Strategy chained // or deposited to Bebop on old chain ===>>> Makes CCIP obsolete!
  - Time 360: Bebop quote EXPIRED (Need to check expiration for confirmation) Need new quote
  - Time ???: dynamically getting quote at this point is unfeasible

- ❌ **Centralization Risk:** API goes down, MMs paused, hack, private oracles for their pricing, we might need to check their test suite (reentrancy through them?)

**For all those risks, we'll have to introduce fallbacks -> Traditional AMMs implementation still needs to happen**

#### Comparison

| Feature                    | Bebop                           | Curve Finance                     | Uniswap V3                           |
| -------------------------- | ------------------------------- | --------------------------------- | ------------------------------------ |
| **Slippage**               | 0% (RFQ mode), max 0.2%         | Minimal for stables (~0.01-0.05%) | Low with 0.01% fee tier (~0.01-0.1%) |
| **MEV Protection**         | ✅ Complete protection          | ❌ Vulnerable to MEV              | ❌ Vulnerable to MEV                 |
| **Price Certainty**        | ✅ Guaranteed execution price   | ❌ Price impact varies            | ❌ Price impact varies               |
| **Gas Costs**              | ✅ Included in quote            | ❌ User pays gas                  | ❌ User pays gas                     |
| **Integration Complexity** | ❌ High (API dependency)        | ✅ Direct contract calls          | ✅ Direct contract calls             |
| **Multi-Chain Support**    | ✅ 6 chains supported           | ✅ Multi-chain deployment         | ✅ Multi-chain deployment            |
| **Liquidity Depth**        | ✅ Private MM + on-chain        | ✅ Deepest for stables (177M ETH) | ✅ Deep liquidity (25M+ ETH)         |
| **Trust Model**            | ❌ Centralized (API dependency) | ✅ Decentralized                  | ✅ Decentralized                     |
| **Quote Validity**         | ❌ ~60 seconds expiration       | ✅ Real-time pricing              | ✅ Real-time pricing                 |
| **Fallback Mechanisms**    | ❌ Requires AMM fallback        | ✅ Built-in redundancy            | ✅ Multiple pools available          |
| **Audit Requirements**     | ❌ API + contract audits        | ✅ Battle-tested contracts        | ✅ Battle-tested contracts           |
| **CCIP Compatibility**     | ❌ Complex (quote timing)       | ✅ Direct integration             | ✅ Direct integration                |
| **Best Use Case**          | Large trades, MEV-sensitive     | Stablecoin swaps                  | General token swaps                  |
| **Risk Level**             | Medium (centralization)         | Low (proven)                      | Low (proven)                         |

**Recommendation**: Use conventional AMMs (Curve/Uniswap V3) for V1 implementation due to:

- Simpler integration with CCIP
- No API dependencies
- Proven track record
- Better suited for automated rebalancing

Consider Bebop for V2 if MEV protection becomes critical for large TVL movements.

**OR**: Hybrid approach for V1 implementation by:

- Using AMMs as the default on-chain swap path
- Interating Bebop as an optonal route / fallback when AMM quores are unfavourable or have high slippage // at this point are we comfortable thinking of a DEX solver as a solution?
- Using Bebop for large TVL swaps (>$1M/$3M depending on specific chain liquidity depth)

#### Further questions

- Which chains are available for RFQ API / JAM Api. (eg: Base on RFQ not JAM)
- Quotes and quote expiration
- Solver response time
- Bebop's contract security, github test suites questionable
