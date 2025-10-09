# Stablecoin Integration Research

## Overview

Research document for integrating stablecoin swapping capabilities into the yield protocol. This document explores various DEX options, integration approaches, and considerations for cross-chain stablecoin operations.

---

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
- **Solution**: Optimize rebalancing frequency based on TVL size

### 3. Single-Point-of-Failure Risks

**USDC/Concero Dependency**

- Dependency on single routing mechanism
- **Mitigation**: Implement monitoring and fallback routes
- **Goal**: Multi-path routing for redundancy

### 4. TVL Risk Management

**Error Handling & Fallback Logic**

- Failed swaps put entire TVL at risk
- **Protection**: TWAP (Time-Weighted Average Price) mechanisms
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

**Integration Example:**

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
    address _permit2
  ) {
    router = UniversalRouter(payable(_router));
    poolManager = IPoolManager(_poolManager);
    permit2 = IPermit2(_permit2);
  }

  function swapExactInputSingle(
    PoolKey calldata key,
    uint128 amountIn,
    uint128 minAmountOut,
    uint256 deadline
  ) external returns (uint256 amountOut) {
    // Implementation of swap
  }
}

```

**Pros:**

- ✅ Hooks allow custom logic and MEV protection
- ✅ Single contract reduces gas costs
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

**Integration Example:**

```javascript
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract UniswapV3Swapper {
  ISwapRouter public swapRouter;

  function swapUSDTForUSDC(uint256 amountIn)
    external
    returns (uint256 amountOut)
  {
    // TransferHelper code for transferring amount to Swapper.sol
    // TransferHelper code for approving router

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

**Two Integration Options:**

1. SDK-Based Integration (JavaScript/TypeScript)
2. Smart Contract Integration (Solidity)

**SDK Integration Example:**

```typescript
import { LancaClient } from "@lanca/sdk";
import type { ILancaClientConfig, IExecutionConfig } from "@lanca/sdk";
import { createWalletClient, http, custom } from "viem";

// Initialize LancaClient
const lancaClient = new LancaClient(config);

// Create route
const route = await lancaClient.getRoute({
  fromChainId: 1, // Ethereum
  toChainId: 8453, // Base
  fromToken: "USDT",
  toToken: "USDC",
  amount: "1000000", // 1 USDT (6 decimals)
  fromAddress: "0x...",
  toAddress: "0x...",
  slippageTolerance: "0.5",
});

// Create wallet client for authorization
const walletClient = createWalletClient({
  chain: ethereum,
  transport: custom(window.ethereum!),
});

// Execution configuration
const executionConfig: IExecutionConfig = {
  switchChainHook: async (chainId: number) => {
    console.log(`Switching to chain: ${chainId}`);
  },
  updateRouteStatusHook: (route: IRouteType) => console.log(route),
};

// Execute route
const routeWithStatus = await lancaClient.executeRoute(
  route,
  walletClient,
  executionConfig
);

// Get route status
const routeStatus = await lancaClient.getRouteStatus(routeId);
```

**Pros:**

- ✅ Native CCIP integration (aligned with our stack)
- ✅ Cross-chain swaps in a single transaction
- ✅ Better rates through Concero optimization
- ✅ ~0 slippage for bridging (mint/burn mechanism)

**Cons:**

- ❌ Limited adoption currently
- ❌ May require significant integration time
- ❌ Learning curve for Concero ecosystem

### XSwap

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

**Integration Example:**

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
