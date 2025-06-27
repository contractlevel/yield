"use client"

import { useState } from "react"
import { WalletConnection } from "@/components/wallet-connection"
import { DepositCard } from "@/components/deposit-card"
import { WithdrawCard } from "@/components/withdraw-card"
import { Portfolio } from "@/components/portfolio"
import { StrategyInfo } from "@/components/strategy-info"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { ArrowLeftRight } from "lucide-react"
import Link from "next/link"
import { Button } from "@/components/ui/button"
import { useWallet } from "@/contexts/wallet-context"

export default function AppPage() {
  const [activeTab, setActiveTab] = useState("deposit")
  const { isConnected } = useWallet()

  return (
    <div className="min-h-screen bg-slate-50">
      {/* Header */}
      <div className="bg-white border-b border-slate-200">
        <div className="mx-auto max-w-7xl px-6 py-6 lg:px-8">
          <div className="flex items-center justify-between">
            <div>
              <Link href="/" className="group">
                <h1 className="text-2xl font-bold text-slate-900 group-hover:text-emerald-600 transition-colors cursor-pointer">
                  YieldCoin
                </h1>
              </Link>
              <p className="text-slate-600">Maximize your stablecoin yield across chains</p>
            </div>
            <div className="flex items-center gap-4">
              <Link href="/bridge">
                <Button variant="outline" className="border-slate-300 text-slate-700 hover:bg-slate-50">
                  <ArrowLeftRight className="mr-2 h-4 w-4" />
                  Bridge YieldCoin
                </Button>
              </Link>
              <WalletConnection />
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="mx-auto max-w-7xl px-6 py-8 lg:px-8">
        <div className="grid grid-cols-1 gap-8 lg:grid-cols-3">
          {/* Left Column - Actions */}
          <div className="lg:col-span-2">
            <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
              <TabsList className="grid w-full grid-cols-2 bg-white border border-slate-200">
                <TabsTrigger
                  value="deposit"
                  className="data-[state=active]:bg-emerald-50 data-[state=active]:text-emerald-700 data-[state=active]:border-emerald-200"
                >
                  Deposit
                </TabsTrigger>
                <TabsTrigger
                  value="withdraw"
                  className="data-[state=active]:bg-emerald-50 data-[state=active]:text-emerald-700 data-[state=active]:border-emerald-200"
                >
                  Withdraw
                </TabsTrigger>
              </TabsList>

              <TabsContent value="deposit" className="mt-6">
                <DepositCard />
              </TabsContent>

              <TabsContent value="withdraw" className="mt-6">
                <WithdrawCard />
              </TabsContent>
            </Tabs>
          </div>

          {/* Right Column - Info */}
          <div className="space-y-6">
            {/* Only show Portfolio when wallet is connected */}
            {isConnected && <Portfolio />}
            <StrategyInfo />
          </div>
        </div>
      </div>
    </div>
  )
}
