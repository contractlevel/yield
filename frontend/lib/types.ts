export interface UserBalance {
  yieldCoinBalance: string
  usdValue: string
  chainId: number
}

export interface StrategyInfo {
  protocol: string
  chainId: number
  chainName: string
  totalValue: string
  apy?: string
}

export interface DepositState {
  amount: string
  isApproving: boolean
  isDepositing: boolean
  needsApproval: boolean
  allowance: string
}

export interface WithdrawState {
  amount: string
  isWithdrawing: boolean
  selectedChainId: number
}
