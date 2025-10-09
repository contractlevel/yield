# Additional Stablecoin Integration Research

## Initial Questions Oct 7 2025

### What are the options for swapping between stablecoins?

for each of the dex options can you show what the integration would look like?
please make the params relevant to our system and mention all contracts/interfaces we'd need to integrate for just a simple clean swap

- UniV4,

```javascript

import { UniversalRouter } from "@uniswap/universal-router/contracts/UniversalRouter.sol";
import { Commands } from "@uniswap/universal-router/contracts/libraries/Commands.sol";
import { IPoolManager } from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import { IV4Router } from "@uniswap/v4-periphery/src/interfaces/IV4Router.sol";
import { Actions } from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import { IPermit2 } from "@uniswap/permit2/src/interfaces/IPermit2.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { StateLibrary } from "@uniswap/v4-core/src/libraries/StateLibrary.sol";

    constructor(address _router, address _poolManager, address _permit2) {
        router = UniversalRouter(payable(_router)); // Main Interface for executing swaps
        poolManager = IPoolManager(_poolManager);  // Interface for interacting with v4 pools
        permit2 = IPermit2(_permit2);             // Interface to interact with Permit2, provides enhanced token approval functionality
    }

    function swapExactInputSingle(
    PoolKey calldata key, // PoolKey struct that identifies the v4 pool
    uint128 amountIn, // Exact amount of tokens to swap
    uint128 minAmountOut, // Minimum amount of output tokens expected
    uint256 deadline // Timestamp after which the transaction will revert
) external returns (uint256 amountOut) {
   //...implementation of swap
   }
```

- PROS:
  Hooks allow custom logic, MEV PROTECTION
  Single contract reduces gas costs
  Adds gas optimizations

- CONS:
  More complex due to hooks, audit hooks
  New (2024), liquidity still migrating -- USDC/USDT Pool on Ethereum v4 24.8M, on v3 22.4 M || Base Pool: 300k || Arb Pool: v4 8.6M v3 2.8M

- UniV3:

```javascript
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

function swapUSDTForUSDC(uin256 amountIn) external returns(uint256 amountOut){
   //*TransferHelper code for transfering amount to Swapper.sol or/and TransferHelper code for approving router
   // fee:   The fee tier of the pool, used to determine the correct pool contract in which to execute the swap
   // deadline: the unix time after which a swap will fail, to protect against long-pending transactions and wild swings in prices
   // sqrtPriceLimitX96:  this value can be used to set the limit for the price the swap will push the pool to, which can help protect against price impact or for setting up logic in a variety of price-relevant mechanisms.

   ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: USDT,
                tokenOut: USDC,
                fee: feeTier,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: minOut,
                sqrtPriceLimitX96: priceLimit
            });
        // The call to `exactInputSingle` executes the swap.
        // swapRouter set in constructor or more complex logic for choosing
        amountOut = swapRouter.exactInputSingle(params);
}
```

- PROS:

Deep liquidity (mentioned above), better efficiency for swaps, low slippage 0.01% fee tier for stables
Multiple chains with strong USDC/USDT liquidity
Battle-tested

- CONS:

Higher gas costs than v2
((check chain deployments))

- UniV2, OUDATED, just skip

```javascript

```

- PROS:

Simple architecture
Lower gas costs than v3
Easy integration

- CONS:

Less liquidity depth for stables
Phasing out
Slippage (?)

- Lanca (Concero),

  2 options: SDK-Based Integration(Javascript/TS) and Smart-Contract Integration(Solidity)

```javascript
import { LancaClient } from "@lanca/sdk";
import type { ILancaClientConfig, IExecutionConfig } from "@lanca/sdk";
import { createWalletClient, http, custom } from "viem";

// Code... Set up ILancaClientConfig
 const lancaClient = new LancaClient(config) // Create LancaClient

 //createRoute
const route = await lancaClient.getRoute({
   fromChainId: ...,
   toChainId: ...,
   fromToken: ...,
   toToken: ...,
	amount: ...,
	fromAddress: ...,
	toAddress: ...,
	slippageTolerance: '0.5',
})

// creates a wallet client for authorization
const walletClient = createWalletClient({
	chain: ...,
	transport: custom(window.ethereum!),
})

 // executionConfig
const executionConfig: IExecutionConfig = {
	switchChainHook: async (chainId: number) => {
		console.log(chainId)
	},
	updateRouteStatusHook: (route: IRouteType) => console.log(route),
}

// executeRoute, does the swap if specified
const routeWithStatus = await lancaClient.executeRoute(route, walletClient, executionConfig)

//retrieve the current status of the route, including any updates or changes that have occurred during the exchange process
const routeStatus = await lancaClient.getRouteStatus(
	'0x231b5f78e90bf71996fd65a05c93a0d0fdb562a2cd8eb6944a833c80bae39b3e',
)
```

- PROS:

Native CCIP Integration - Aligned with stack
Cross-Chain SWAPS in a single tx
Better rates (?? -> Concero!)
~0 slippage for bridging -mint/burn

- CONS:

Adoption (?)
May take time to integrate/understand (-> Concero!)

- XSwap,

```javascript

```

- PROS:

sounds great

- CONS:

eaaaarly stage

- Cowswap - INCOMPATIBLE with CCIP message flow

  - PROS:

  Strong MEV protection
  Virtually 0 slippage
  Mainly on EVM, that's fine

  - CONS:

  Mainly on EVM, that's fine for now
  Executes in batches, may slow whole process
  Cross-Chain via CCIP might be tricky (?)

- Curve Finance ||

Vyper Contracts -> Solidity: Needs Interface implementation from official curve docs step by step

```javascript
 function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
```

- PROS:

Built for stablecoins
Deepest Liquidity Eth 3Pool DAI/USDC/USDT 177M
Multi-Chain
Fees at 0.04% typically
Minimal Slippage

- CONS:

Adding more stables other than USDC/USDT/DAI tricky
((Check availability across chains))

(more?)

- DEX Aggregators (1inch, Paraswap, etc) - Overkill for just USDC/USDT swaps

  - CONS:

  Dependancy on aforementioned DEXs liquidity, extra steps, GAS/API complexity, front-running???

### What do we need to be concerned about for liquidity? What are the fundamental limitations to what we are trying to achieve?

- Chain-Specific Liquidity Depth
- Stablecoin Support vastly different across protocols/chains (whitelisted stables)
- Fragmentation of each protocol's liquidity: multiple chains, pool versions, fees, in the future we might need to choose where and when we do each swap based on multiple factors and end up with USDC preswapping being the most efficient. LANCA specifically addresses that by treating chain pools together (->Concero!)
- Liquidity Reliability: Exit during volatility, shouldn't be the case for v1, chains' strongest pair is usually USDC/USDT
- Slippage: pre-execution slippage estimation, deep pools
- Depeg? Circuit breakers?
- Monitor pools of choice
- Implement fallback routes?
- Use Curve

### What are implications on liquidity of USDC being the stablecoin with the most CCIP lanes?

- Is it substantially better to always pre-emptively swap to USDC?
  YES, USDT has no 1st phase lanes except ETH, Optimism(?) and BASE
  - USDC deep liquidity on Ethereum, Base (USDT substantially low), Arbitrum, Avalanche, Polygon
  - native mint/burn, no wrappers
  - lower fees (? -> concero)
    Design system with USDC as cross-chain standard,
    SWAP to USDC on source if Parent/Child deposit -> CrossChain
    SWAP from USDC on destination
    minimizes complexity and leverages CCIP,

### What do we need to think about in terms of slippage?

- Consider: We want to lose as little to slippage as possible whilst still having successful transactions.

  - Tight slippage tolerance: low slippage settings 0.5% for large trades, ensures it executes if price impact is small, although might cause Tx failures, latency
  - Max Pool Depth: Route through the deepest available pools, avoid small DEX pools
  - Stable Pools: Pools having deeper liquidity might be bc of higher fees, so liq providers choose them. Find 0.05% stable pools, ideal for pegged pairs
  - Route via Pegged Bridges for 0 cross-chain slippage
  - Very low slippage tolerance -> Tx reverting risk, balance of slippage and tx success
  - Maybe query Chainlink for fair prices and compare to decide acceptable slippage before the swap
  - Cumulative Slippage from 2+ swaps
  - Time sensitivity, deadline checks
  - Route splitting for very large swaps? Might be needed due to TVL being swapped from (cross-chain)Strategy to Strategy

### Do we need additional contract(s) for DEX integration?

Depends on DEX vs Cross-Chain Swap Abstraction choice. If we use multiple DEX's - YES! Need to handle logic and paths for routing/swaps

- What are the additional requirements for it?
  Swapper.sol

  1. DEX Abstraction

     - Unified interface for multiple DEXs
     - Adapt pattern for each DEX
     - Add/Remove DEXs

  2. Route optimization

     - Query multiple DEXs
     - Select best rate
     - Split routes for large trades

  3. Slippage Protection

     - Auto slippage calculations
     - MinOut enforcements

  4. MEV

     - MEV-protected relayers

  5. Safety Mechanics

     - Deadline enforcements
     - Emergency Pausing

  6. Gas Optimizations

     - Batch operations where possible (TVL moving + deposits happening?)
     - Efficient encoding
     - Token approvals?

  7. Monitoring

     - Event emissions for all swaps
     - Slippage tracking

  8. Upgradeability

     - Allow more DEXs
     - Allow more Stables
     - Various adjustments

  9. More considerations

     - Failed swap handling
     - Before or after CCIP message? - Obviously depends on where we initiate the swap, but which contract sends the CCIP message afterall?
     - Including, testing and succesfully implementing swap logic inside CCIP Messages introduces huge headaches, advil insufficient
     - Audit complexity

### Can Concero abstract the swap process through cross-chain messages also facilitating DEX swaps or is it always a 2-step process?

1. ASK DURING CONCERO MEET:

   - Can we include data to facilitate swaps (cross-chain swapping) ?
     - Which services can be plug-N-play?
     - Does Lanca do exactly that for them?
     - v1 / v2 ?
     - Ask for walkthrough by team member

2. Use Concero Embedded Swaps

   - CCIP message includes fromToken, toToken, minOutput
   - Concero executes swaps with their integrated DEXs
   - Single Tx

   ASK Concero:

   - Slippage protection handling?
   - Swap fallback logic?

3. Hybrid Approach
   - Concero for CCIP messaging, USDC Bridgin
   - Implement own Swapper.sol for source and destination chain swaps
   - Include destination swap parameters in CCIP message
     => Flex, optimizable, better error handling, transparent to us (and users?)

### How do we minimize MEV via Uniswap?

- UniswapX: Offers protection against MEV, meta-aggregator, currently on ETH and BASE
- UniswapWallet : Private Pools

- Large trades on shallow pools are getting hit by MEV -> Trade on deep liquidity pools
- Front-running less profitable with 0.01-0.1% spreads, MEV minimal for stablecoin swaps

- Protection Strategies:
  - Flashbots Protect: sends Tx directly to builders (slower)
  - MEV Blocker: RPC endpoint that prevents front-running
  - Uniswap v4 has hooks that allow custom MEV protection

### Fundamental Limitations

- USDC/USDT Liquidity on each chain // Liquidity Fragmentation (Maybe Concero/Lanca fixes)

  - Is it enough for us to a whole TVL swap for deposit?
  - If the TVL becomes big enough, will the APR change?

- Rebalancing Frequency

  - Is this something that might cause more loss than gain due to slippage?
  - How often will the rebalancing happen? Too often & TVL big -> $$ lost to slippage, users lose potential gains

- USDC as bridge, Concero as bridge

- Dependancy on single-point routing
- Ideally: monitoring/fallback routes

- TVL Handling

  - Error Handling, Fallback Logic
  - If swaps revert/not favourable, the whole TVL is at risk
  - TWAP

- Attack Surface

  - Each integration introduces more and more potential attack vectors

- GAS Costs

  - Ramping up due to user deposits
  - Small deposits will still be swapped back and forth and handled into the strategy
  - Might need batching

- Edge Case of DEPEG

  - Handle emergency
