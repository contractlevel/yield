# Additional Stablecoin Integration Research

## Initial Questions Oct 7 2025

### What are the options for swapping between stablecoins?

- UniV4,
  -PROS:
  Hooks allow custom logic, MEV PROTECTION
  Single contract reduces gas costs
  Adds gas optimizations

  -CONS:
  More complex due to hooks, audit hooks
  New (2024), liquidity still migrating

- UniV3:
  -PROS:
  Deep liquidity, better efficiency for swaps, low slippage
  Multiple chains with strong USDC/USDT liquidity
  Battle-tested

  -CONS:
  Higher gas costs than v2
  ((check chain deployments))

- UniV2,  
   -PROS:
  Simple architecture
  Lower gas costs than v3
  Easy integration

  -CONS:
  Less liquidity depth for stables
  Phasing out
  Slippage (?)

- Lanca (Concero),
  -PROS:
  Native CCIP Integration - Aligned with stack
  Cross-Chain SWAPS in a single tx
  Better rates (?? -> Concero!)
  ~0 slippage for bridging -mint/burn

  -CONS:
  Adoption (?)
  May take time to integrate/understand (-> Concero!)

- XSwap,
  -PROS:
  sounds great

  -CONS:
  eaaaarly stage

- Cowswap
  -PROS:
  Strong MEV protection
  Virtually 0 slippage
  Mainly on EVM, that's fine

  -CONS:
  Mainly on EVM, that's fine for now
  Executes in batches, may slow whole process
  Cross-Chain via CCIP might be tricky (?)

- Curve Finance
  -PROS:
  Built for stablecoins
  Deepest Liquidity
  Multi-Chain
  Fees at 0.04% typically
  Minimal Slippage

  -CONS:
  More complex integration due to various pool implementations
  Adding more stables other than USDC/USDT/DAI tricky
  ((Check availability across chains))

(more?)

- DEX Aggregators (1inch, Paraswap, etc):
  CONS: Dependancy on aforementioned DEXs liquidity, extra steps, GAS/API complexity, front-running???

### What do we need to be concerned about for liquidity?

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

### Do we need additional contract(s) for DEX integration?

- What are the additional requirements for it?

### Can Concero abstract the swap process through cross-chain messages also facilitating DEX swaps or is it always a 2-step process?

1. ASK DURING CONCERO MEET:
   - Can we include data to facilitate swaps (cross-chain swapping) ?
     - Which services can be plug-N-play?
     - Does Lanca do exactly that for them?
     - v1 / v2 ?
     - Ask for walkthrough by team member

### How do we minimize MEV via Uniswap?

- minAmountOut
-
-
