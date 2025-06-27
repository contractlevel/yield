"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { TrendingUp, Wallet, RefreshCw, ChevronDown } from "lucide-react"
import { useWallet } from "@/contexts/wallet-context"
import { useTotalYieldCoinBalance } from "@/hooks/use-total-yieldcoin-balance"
import { SUPPORTED_CHAINS } from "@/lib/config"
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from "@/components/ui/collapsible"

export function Portfolio() {
  const { address, isConnected } = useWallet()
  const {
    chainBalances,
    totalBalance,
    isLoading: isLoadingBalance,
    error: balanceError,
    refetch,
  } = useTotalYieldCoinBalance(address)

  const [portfolio, setPortfolio] = useState({
    usdValue: "0.00",
    totalEarned: "0.00",
    apy: "8.5",
  })

  const [showBreakdown, setShowBreakdown] = useState(false)

  // Calculate USD value based on total YieldCoin balance
  useEffect(() => {
    if (totalBalance && !isLoadingBalance && !balanceError) {
      const balance = Number.parseFloat(totalBalance)
      const usdValue = (balance * 1.045).toFixed(2) // Assuming some yield has been earned
      const totalEarned = (balance * 0.045).toFixed(2) // 4.5% earned yield for demo

      setPortfolio({
        usdValue,
        totalEarned,
        apy: "8.5",
      })
    } else if (!isLoadingBalance) {
      setPortfolio({
        usdValue: "0.00",
        totalEarned: "0.00",
        apy: "8.5",
      })
    }
  }, [totalBalance, isLoadingBalance, balanceError])

  const getChainName = (chainId: number) => {
    return SUPPORTED_CHAINS.find((chain) => chain.id === chainId)?.shortName || "Unknown"
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Wallet className="h-5 w-5" />
          Your Portfolio
          <Button
            variant="ghost"
            size="sm"
            onClick={refetch}
            disabled={isLoadingBalance}
            className="ml-auto h-6 w-6 p-0"
          >
            <RefreshCw className={`h-3 w-3 ${isLoadingBalance ? "animate-spin" : ""}`} />
          </Button>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="space-y-2">
          <div className="flex justify-between items-center">
            <span className="text-sm text-slate-600">Total YieldCoin Balance</span>
            <span className="font-mono font-medium">
              {!isConnected ? (
                "Connect wallet"
              ) : isLoadingBalance ? (
                <span className="inline-flex items-center gap-1">
                  <RefreshCw className="h-3 w-3 animate-spin" />
                  Loading...
                </span>
              ) : balanceError ? (
                <span className="text-red-600">Error</span>
              ) : (
                `${totalBalance} YIELD`
              )}
            </span>
          </div>

          {/* Chain Breakdown */}
          {isConnected && !isLoadingBalance && !balanceError && chainBalances.length > 0 && (
            <Collapsible open={showBreakdown} onOpenChange={setShowBreakdown}>
              <CollapsibleTrigger asChild>
                <Button variant="ghost" size="sm" className="w-full justify-between h-6 px-0 text-xs text-slate-500">
                  <span>View breakdown by chain</span>
                  <ChevronDown className={`h-3 w-3 transition-transform ${showBreakdown ? "rotate-180" : ""}`} />
                </Button>
              </CollapsibleTrigger>
              <CollapsibleContent className="space-y-1 mt-2">
                {chainBalances.map((chainBalance) => {
                  const balance = Number.parseFloat(chainBalance.balance)
                  if (balance === 0) return null

                  return (
                    <div
                      key={chainBalance.chainId}
                      className="flex justify-between items-center text-xs text-slate-600 pl-2"
                    >
                      <span>{getChainName(chainBalance.chainId)}:</span>
                      <span className="font-mono">{chainBalance.balance} YIELD</span>
                    </div>
                  )
                })}
              </CollapsibleContent>
            </Collapsible>
          )}

          <div className="flex justify-between items-center">
            <span className="text-sm text-slate-600">USD Value</span>
            <span className="font-mono font-medium">${portfolio.usdValue}</span>
          </div>

          <div className="flex justify-between items-center">
            <span className="text-sm text-slate-600">Total Earned</span>
            <span className="font-mono font-medium text-green-600">+${portfolio.totalEarned}</span>
          </div>
        </div>

        <div className="pt-4 border-t">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <TrendingUp className="h-4 w-4 text-green-600" />
              <span className="text-sm font-medium">Current APY</span>
            </div>
            <Badge variant="secondary" className="bg-green-100 text-green-800">
              {portfolio.apy}%
            </Badge>
          </div>
        </div>

        <div className="pt-2">
          <div className="text-xs text-slate-500">
            Your YieldCoin automatically earns yield from the highest-performing strategies across chains. Balance shown
            is the sum across all supported chains.
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
