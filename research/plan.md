# Uniswap V3 Liquidity-Aware Stablecoin Swapping Implementation Plan                                                                                  
                                                                                                                                                        
  ## Overview                                                                                                                                           
                                                                                                                                                        
  Add Uniswap V3 integration for liquidity-aware stablecoin swapping during rebalancing. This enables the system to optimize yield across different     
  stablecoins (USDC, USDT, GHO, etc.) while factoring in swap liquidity constraints.                                                                    
                                                                                                                                                        
  **Supported Chains:** Avalanche, Ethereum, Base, Arbitrum, Optimism, Polygon                                                                          
                                                                                                                                                        
  ---                                                                                                                                                   
                                                                                                                                                        
  ## Part 1: Solidity Contracts                                                                                                                         
                                                                                                                                                        
  ### 1.1 Extend Strategy Struct                                                                                                                        
                                                                                                                                                        
  **File:** `src/interfaces/IYieldPeer.sol`                                                                                                             
                                                                                                                                                        
  ```solidity                                                                                                                                           
  struct Strategy {                                                                                                                                     
  bytes32 protocolId;    // keccak256("aave-v3") or keccak256("compound-v3")                                                                            
  bytes32 stablecoinId;  // NEW: keccak256("USDC"), keccak256("USDT"), keccak256("GHO")                                                                 
  uint64 chainSelector;                                                                                                                                 
  }                                                                                                                                                     
  ```                                                                                                                                                   
                                                                                                                                                        
  ### 1.2 New Interfaces                                                                                                                                
                                                                                                                                                        
  | File | Purpose |                                                                                                                                    
  |------|---------|                                                                                                                                    
  | `src/interfaces/IStablecoinRegistry.sol` | `getStablecoin(bytes32) -> address`, `isStablecoinSupported(bytes32) -> bool` |                          
  | `src/interfaces/ISwapper.sol` | `swapAssets(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMin) -> uint256` |                
                                                                                                                                                        
  ### 1.3 New Contracts                                                                                                                                 
                                                                                                                                                        
  | File | Purpose |                                                                                                                                    
  |------|---------|                                                                                                                                    
  | `src/modules/StablecoinRegistry.sol` | Maps stablecoinId -> address per chain (follows StrategyRegistry pattern) |                                  
  | `src/swappers/UniswapV3Swapper.sol` | Implements ISwapper using Uniswap V3 SwapRouter02 |                                                           
                                                                                                                                                        
  **UniswapV3Swapper key details:**                                                                                                                     
  - Immutable: `i_yieldPeer`, `i_swapRouter`, `i_quoter`                                                                                                
  - `onlyYieldPeer` modifier for access control                                                                                                         
  - Default fee tier: 500 (0.05% for stablecoins)                                                                                                       
  - Uses `SafeERC20` for token transfers                                                                                                                
                                                                                                                                                        
  ### 1.4 Modify Existing Contracts                                                                                                                     
                                                                                                                                                        
  **YieldPeer.sol** - Add:                                                                                                                              
  - State: `s_stablecoinRegistry`, `s_swapper`                                                                                                          
  - Setters with `CONFIG_ADMIN_ROLE`                                                                                                                    
  - Helper: `_swapStablecoins(tokenIn, tokenOut, amountIn, amountOutMin) -> amountOut`                                                                  
  - Helper: `_getStablecoinAddress(stablecoinId) -> address`                                                                                            
  - Constant: `bytes32 internal constant USDC_ID = keccak256("usdc")`                                                                                   
  - Constant: `uint256 internal constant MAX_SLIPPAGE_BPS = 50` (0.5%)                                                                                  
                                                                                                                                                        
  **ParentPeer.sol** - Modify `_rebalance()`:                                                                                                           
  - Check if `oldStrategy.stablecoinId != newStrategy.stablecoinId`                                                                                     
  - If swapping needed and old != USDC: swap to USDC before CCIP bridge                                                                                 
  - Include `newStrategy.stablecoinId` in CCIP message                                                                                                  
                                                                                                                                                        
  **ChildPeer.sol** - Modify `_handleCCIPRebalanceNewStrategy()`:                                                                                       
  - If `newStrategy.stablecoinId != USDC_ID`: swap USDC to target stablecoin after receiving bridge                                                     
                                                                                                                                                        
  ### 1.5 Slippage Tolerance                                                                                                                            
                                                                                                                                                        
  **Recommendation: 50 basis points (0.5%)**                                                                                                            
                                                                                                                                                        
  Justification:                                                                                                                                        
  - Stablecoin pools have concentrated liquidity around 1:1 peg                                                                                         
  - Typical price impact < 10 bps for reasonable sizes                                                                                                  
  - 50 bps provides MEV protection buffer                                                                                                               
  - Industry standard (Uniswap UI default for stablecoins)                                                                                              
                                                                                                                                                        
  ---                                                                                                                                                   
                                                                                                                                                        
  ## Part 2: CRE Workflow (Go)                                                                                                                          
                                                                                                                                                        
  ### 2.1 New Package Structure                                                                                                                         
                                                                                                                                                        
  ```                                                                                                                                                   
  cre/rebalance/workflow/internal/uniswapV3/                                                                                                            
  ├── types.go              # PoolState, SwapViability, LiquidityCheckParams                                                                            
  ├── interfaces.go         # UniswapV3PoolInterface, QuoterV2Interface                                                                                 
  ├── bindings.go           # newPoolBinding, newQuoterV2Binding                                                                                        
  ├── bindings_promise.go   # Async binding helpers                                                                                                     
  ├── read.go               # getPoolState, getLiquidity                                                                                                
  ├── calculate.go          # CalculatePriceImpact, CalculateMinAmountOut, IsSwapViable                                                                 
  ├── liquidity_promise.go  # CheckSwapLiquidityPromise (main entry point)                                                                              
  ├── deps.go               # Dependency injection                                                                                                      
  └── constants.go          # DefaultMaxSlippageBps = 50, fee tiers                                                                                     
  ```                                                                                                                                                   
                                                                                                                                                        
  ### 2.2 Key Functions                                                                                                                                 
                                                                                                                                                        
  ```go                                                                                                                                                 
  // Main entry point - checks if swap is viable                                                                                                        
  func CheckSwapLiquidityPromise(                                                                                                                       
  config *helper.Config,                                                                                                                                
  runtime cre.Runtime,                                                                                                                                  
  params *LiquidityCheckParams,                                                                                                                         
  ) cre.Promise[*SwapViability]                                                                                                                         
                                                                                                                                                        
  // Cross-chain swap viability (source swap + dest swap)                                                                                               
  func CheckMultiChainSwapViability(                                                                                                                    
  config *helper.Config,                                                                                                                                
  runtime cre.Runtime,                                                                                                                                  
  sourceChain, destChain uint64,                                                                                                                        
  sourceToken, destToken common.Address,                                                                                                                
  amount *big.Int,                                                                                                                                      
  maxSlippageBps uint32,                                                                                                                                
  ) cre.Promise[*SwapViability]                                                                                                                         
  ```                                                                                                                                                   
                                                                                                                                                        
  ### 2.3 Extend Strategy Type                                                                                                                          
                                                                                                                                                        
  **File:** `cre/rebalance/workflow/internal/onchain/types.go`                                                                                          
                                                                                                                                                        
  ```go                                                                                                                                                 
  type Strategy struct {                                                                                                                                
  ProtocolId    [32]byte                                                                                                                                
  ChainSelector uint64                                                                                                                                  
  StablecoinId  [32]byte  // NEW                                                                                                                        
  }                                                                                                                                                     
  ```                                                                                                                                                   
                                                                                                                                                        
  ### 2.4 Modify optimal.go                                                                                                                             
                                                                                                                                                        
  In `GetOptimalAndCurrentStrategyWithAPY()`:                                                                                                           
  1. For each candidate strategy where stablecoin differs from current:                                                                                 
  - Call `uniswapV3.CheckMultiChainSwapViability()`                                                                                                     
  - If not viable (insufficient liquidity or excessive slippage): skip candidate                                                                        
  - Factor swap cost into net APY comparison                                                                                                            
                                                                                                                                                        
  ### 2.5 Config Updates                                                                                                                                
                                                                                                                                                        
  **File:** `cre/rebalance/workflow/internal/helper/config.go`                                                                                          
                                                                                                                                                        
  Add to `EvmConfig`:                                                                                                                                   
  ```go                                                                                                                                                 
  UniswapV3QuoterV2Address     string       `json:"uniswapV3QuoterV2Address"`                                                                           
  UniswapV3SwapRouterAddress   string       `json:"uniswapV3SwapRouterAddress"`                                                                         
  MaxSwapSlippageBps           uint32       `json:"maxSwapSlippageBps"`                                                                                 
  StablecoinAddresses          map[string]string `json:"stablecoinAddresses"` // "usdt" -> "0x..."                                                      
  UniswapV3Pools               []PoolConfig `json:"uniswapV3Pools"`                                                                                     
  ```                                                                                                                                                   
                                                                                                                                                        
  ### 2.6 Contract Bindings                                                                                                                             
                                                                                                                                                        
  Generate Go bindings for:                                                                                                                             
  - Uniswap V3 Pool (`slot0`, `liquidity`, `token0`, `token1`, `fee`)                                                                                   
  - Uniswap V3 QuoterV2 (`quoteExactInputSingle`)                                                                                                       
                                                                                                                                                        
  ---                                                                                                                                                   
                                                                                                                                                        
  ## Part 3: Data Flow                                                                                                                                  
                                                                                                                                                        
  ### Rebalance with Stablecoin Swap (USDT@ChainA -> GHO@ChainB)                                                                                        
                                                                                                                                                        
  ```                                                                                                                                                   
  CRE Workflow:                                                                                                                                         
  1. Read current strategy (USDT/AaveV3/ChainA)                                                                                                         
  2. Check swap viability: USDT->USDC on A, USDC->GHO on B                                                                                              
  3. If viable, select GHO/AaveV3/ChainB as optimal                                                                                                     
                                                                                                                                                        
  Chain A (ParentPeer):                                                                                                                                 
  4. Withdraw USDT from AaveV3Adapter                                                                                                                   
  5. Swap USDT -> USDC via UniswapV3Swapper                                                                                                             
  6. CCIP send USDC + newStrategy to Chain B                                                                                                            
                                                                                                                                                        
  Chain B (ChildPeer):                                                                                                                                  
  7. Receive USDC from CCIP                                                                                                                             
  8. Swap USDC -> GHO via UniswapV3Swapper                                                                                                              
  9. Deposit GHO to AaveV3Adapter                                                                                                                       
  ```                                                                                                                                                   
                                                                                                                                                        
  ---                                                                                                                                                   
                                                                                                                                                        
  ## Part 4: Files to Create/Modify                                                                                                                     
                                                                                                                                                        
  ### New Files                                                                                                                                         
  | Path | Description |                                                                                                                                
  |------|-------------|                                                                                                                                
  | `src/interfaces/IStablecoinRegistry.sol` | Interface |                                                                                              
  | `src/interfaces/ISwapper.sol` | Interface |                                                                                                         
  | `src/modules/StablecoinRegistry.sol` | Registry contract |                                                                                          
  | `src/swappers/UniswapV3Swapper.sol` | Swapper implementation |                                                                                      
  | `cre/rebalance/workflow/internal/uniswapV3/*.go` | Full package (8 files) |                                                                         
                                                                                                                                                        
  ### Modified Files                                                                                                                                    
  | Path | Changes |                                                                                                                                    
  |------|---------|                                                                                                                                    
  | `src/interfaces/IYieldPeer.sol` | Add `stablecoinId` to Strategy struct |                                                                           
  | `src/peers/YieldPeer.sol` | Add registries, swap helper, constants |                                                                                
  | `src/peers/ParentPeer.sol` | Modify `_rebalance*` functions for swaps |                                                                             
  | `src/peers/ChildPeer.sol` | Modify `_handleCCIPRebalanceNewStrategy` |                                                                              
  | `cre/rebalance/workflow/internal/onchain/types.go` | Add `StablecoinId` to Strategy |                                                               
  | `cre/rebalance/workflow/internal/onchain/optimal.go` | Add liquidity checks |                                                                       
  | `cre/rebalance/workflow/internal/helper/config.go` | Add Uniswap config fields |                                                                    
  | `cre/rebalance/workflow/config.staging.json` | Add Uniswap addresses |                                                                              
                                                                                                                                                        
  ---                                                                                                                                                   
                                                                                                                                                        
  ## Part 5: Verification                                                                                                                               
                                                                                                                                                        
  ### Unit Tests                                                                                                                                        
  1. `StablecoinRegistry`: set/get stablecoin, ownership                                                                                                
  2. `UniswapV3Swapper`: swap execution, slippage protection, access control                                                                            
  3. `YieldPeer`: swap helper functions                                                                                                                 
  4. `ParentPeer`: rebalance with stablecoin change                                                                                                     
  5. `ChildPeer`: handle rebalance with swap                                                                                                            
  6. Go: `uniswapV3` package functions                                                                                                                  
                                                                                                                                                        
  ### Integration Tests                                                                                                                                 
  1. Full rebalance flow with stablecoin swap (fork test)                                                                                               
  2. CRE workflow with liquidity checks (mock Uniswap state)                                                                                            
                                                                                                                                                        
  ### Manual Testing                                                                                                                                    
  1. Deploy to testnet (Sepolia/Base Sepolia)                                                                                                           
  2. Execute rebalance that requires stablecoin swap                                                                                                    
  3. Verify swap execution and correct amounts                                                                                                          
                                                                                                                                                        
  ### Commands                                                                                                                                          
  ```bash                                                                                                                                               
  # Solidity tests                                                                                                                                      
  forge test --mt test_StablecoinRegistry                                                                                                               
  forge test --mt test_UniswapV3Swapper                                                                                                                 
  forge test --mt test_RebalanceWithSwap                                                                                                                
                                                                                                                                                        
  # Go tests                                                                                                                                            
  cd cre/rebalance && go test ./workflow/internal/uniswapV3/...                                                                                         
  cd cre/rebalance && go test ./workflow/internal/onchain/...                                                                                           
                                                                                                                                                        
  # Static analysis                                                                                                                                     
  slither . --filter-path lib                                                                                                                           
  ```                                                                                                                                                   
                                                                                                                                                        
  ---                                                                                                                                                   
                                                                                                                                                        
  ## Implementation Order                                                                                                                               
                                                                                                                                                        
  1. **Solidity interfaces** (IStablecoinRegistry, ISwapper)                                                                                            
  2. **StablecoinRegistry contract** + tests                                                                                                            
  3. **UniswapV3Swapper contract** + tests                                                                                                              
  4. **Extend Strategy struct** in IYieldPeer.sol                                                                                                       
  5. **YieldPeer modifications** (state, helpers)                                                                                                       
  6. **ParentPeer/ChildPeer modifications** (rebalance flow)                                                                                            
  7. **Go uniswapV3 package** (types, bindings, calculate, liquidity_promise)                                                                           
  8. **Go onchain modifications** (types, optimal)                                                                                                      
  9. **Config updates** (staging.json, config.go)                                                                                                       
  10. **Integration tests**                                                                                                                             
                               