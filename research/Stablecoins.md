# Additional Stablecoin Integration Research

## Initial Questions Oct 7 2025

### What are the options for swapping between stablecoins?

- UniV4, UniV3, UniV2, Lanca (Concero), XSwap, Cowswap (more?)

### What do we need to be concerned about for liquidity?

- Based on each option above.

### What are implications on liquidity of USDC being the stablecoin with the most CCIP lanes?

- Is it substantially better to always pre-emptively swap to USDC?

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
