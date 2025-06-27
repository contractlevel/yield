"use client"

import { WalletConnection } from "@/components/wallet-connection"
import { CrossChainTransfer } from "@/components/cross-chain-transfer"
import { TransferHistory } from "@/components/transfer-history"
import { ArrowLeftRight } from "lucide-react"
import Link from "next/link"
import { Button } from "@/components/ui/button"
import { useWallet } from "@/contexts/wallet-context"

export default function BridgePage() {
  const { isConnected } = useWallet()

  return (
    <div className="min-h-screen bg-slate-50">
      <div className="mx-auto max-w-7xl px-6 py-8 lg:px-8">
        {/* Header */}
        <div className="mb-8 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Link href="/app">
              <Button variant="ghost" size="sm">
                ← Back to App
              </Button>
            </Link>
            <div>
              <h1 className="text-3xl font-bold text-slate-900 flex items-center gap-2">
                <ArrowLeftRight className="h-8 w-8" />
                Bridge YieldCoin
              </h1>
              <p className="text-slate-600">Transfer your YieldCoin across chains using CCIP</p>
            </div>
          </div>
          <WalletConnection />
        </div>

        {/* Main Content */}
        <div className="grid grid-cols-1 gap-8 lg:grid-cols-3">
          {/* Left Column - Transfer Interface */}
          <div className="lg:col-span-2">
            <CrossChainTransfer />
          </div>

          {/* Right Column - Transfer History (only show when connected) */}
          {isConnected && (
            <div>
              <TransferHistory />
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
