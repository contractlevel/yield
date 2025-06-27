"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Target, ExternalLink, RefreshCw } from "lucide-react"
import { SUPPORTED_CHAINS, CONTRACTS } from "@/lib/config"
import { useStrategy } from "@/hooks/use-strategy"

export function StrategyInfo() {
  const { protocol, chainId, chainName, isLoading, error, refetch } = useStrategy()

  const currentChain = SUPPORTED_CHAINS.find((chain) => chain.id === chainId)

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Target className="h-5 w-5" />
          Current Strategy
          <Button variant="ghost" size="sm" onClick={refetch} disabled={isLoading} className="ml-auto h-6 w-6 p-0">
            <RefreshCw className={`h-3 w-3 ${isLoading ? "animate-spin" : ""}`} />
          </Button>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {error ? (
          <div className="text-center py-4">
            <p className="text-sm text-red-600 mb-2">Failed to load strategy</p>
            <p className="text-xs text-slate-500">{error}</p>
            <Button variant="outline" size="sm" onClick={refetch} className="mt-2">
              Try Again
            </Button>
          </div>
        ) : (
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span className="text-sm text-slate-600">Protocol</span>
              {isLoading ? (
                <div className="h-5 w-16 bg-slate-200 rounded animate-pulse" />
              ) : (
                <Badge variant="outline">{protocol}</Badge>
              )}
            </div>

            <div className="flex justify-between items-center">
              <span className="text-sm text-slate-600">Active Chain</span>
              <div className="flex items-center gap-2">
                {isLoading ? (
                  <div className="h-5 w-20 bg-slate-200 rounded animate-pulse" />
                ) : (
                  <>
                    <Badge variant="secondary">{chainName}</Badge>
                    {currentChain?.isParent && (
                      <Badge variant="outline" className="text-xs bg-emerald-50 text-emerald-700 border-emerald-200">
                        Parent
                      </Badge>
                    )}
                  </>
                )}
              </div>
            </div>

            <div className="flex justify-between items-center">
              <span className="text-sm text-slate-600">Total Value Locked</span>
              <span className="font-mono font-medium">$2,456,789</span>
            </div>

            <div className="flex justify-between items-center">
              <span className="text-sm text-slate-600">Current APY</span>
              <span className="font-mono font-medium text-green-600">8.5%</span>
            </div>
          </div>
        )}

        <div className="pt-4 border-t">
          <div className="flex items-center justify-between">
            <span className="text-sm text-slate-600">Strategy Status</span>
            <div className="flex items-center gap-2">
              <div
                className={`h-2 w-2 rounded-full ${error ? "bg-red-500" : isLoading ? "bg-yellow-500" : "bg-green-500"}`}
              ></div>
              <span className={`text-sm ${error ? "text-red-600" : isLoading ? "text-yellow-600" : "text-green-600"}`}>
                {error ? "Error" : isLoading ? "Loading" : "Active"}
              </span>
            </div>
          </div>
        </div>

        <div className="pt-2">
          <div className="text-xs text-slate-500">
            YieldCoin automatically monitors and switches to the highest-yielding opportunities across all supported
            protocols and chains.
          </div>
        </div>

        {currentChain && !error && (
          <div className="pt-2">
            <a
              href={`${currentChain.blockExplorer}/address/${
                currentChain.isParent
                  ? CONTRACTS.PARENT_PEER.address
                  : chainId === 84532
                    ? CONTRACTS.CHILD_PEERS.BASE_SEPOLIA.address
                    : CONTRACTS.CHILD_PEERS.AVALANCHE_FUJI.address
              }`}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1 text-green-600 hover:text-green-700"
            >
              View Contract on Explorer
              <ExternalLink className="h-3 w-3" />
            </a>
          </div>
        )}
      </CardContent>
    </Card>
  )
}
