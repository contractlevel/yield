"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Clock, ExternalLink, CheckCircle, AlertCircle, RefreshCw } from "lucide-react"
import { SUPPORTED_CHAINS } from "@/lib/config"
import { useWallet } from "@/contexts/wallet-context"

interface Transfer {
  id: string
  amount: string
  fromChain: number
  toChain: number
  status: "pending" | "completed" | "failed"
  timestamp: string
  txHash?: string
  ccipMessageId?: string
}

// Local storage key for transfers
const TRANSFERS_STORAGE_KEY = "yieldcoin-transfers"

export function TransferHistory() {
  const { address } = useWallet()
  const [transfers, setTransfers] = useState<Transfer[]>([])
  const [isLoading, setIsLoading] = useState(true)

  // Load transfers from local storage on component mount
  useEffect(() => {
    if (address) {
      const storedTransfers = localStorage.getItem(`${TRANSFERS_STORAGE_KEY}-${address.toLowerCase()}`)
      if (storedTransfers) {
        try {
          setTransfers(JSON.parse(storedTransfers))
        } catch (e) {
          console.error("Failed to parse stored transfers:", e)
        }
      }

      // Add the specific completed transaction from CCIP explorer
      const specificTx: Transfer = {
        id: "0xd0c3e338c66bad81412c92ad7b76681b977464fa85350201b9830bfaf5250956",
        amount: "1.0",
        fromChain: 11155111, // Ethereum Sepolia
        toChain: 43113, // Avalanche Fuji
        status: "completed",
        timestamp: "2025-06-18T10:40:24Z", // From the screenshot
        txHash: "0xd0c3e338c66bad81412c92ad7b76681b977464fa85350201b9830bfaf5250956",
        ccipMessageId: "0x7f91c48fe14b5d9c6f472afa45551be29d4ff930e51711c99c8e61a980f0ed58",
      }

      // Check if we already have this transaction
      setTransfers((prev) => {
        if (!prev.some((t) => t.id === specificTx.id)) {
          const updatedTransfers = [specificTx, ...prev]
          // Save to local storage
          localStorage.setItem(`${TRANSFERS_STORAGE_KEY}-${address.toLowerCase()}`, JSON.stringify(updatedTransfers))
          return updatedTransfers
        }
        return prev
      })

      setIsLoading(false)
    }
  }, [address])

  // Listen for new pending transfers
  useEffect(() => {
    const handleNewPendingTransfer = (event: CustomEvent) => {
      const newTransfer = event.detail as Transfer

      setTransfers((prev) => {
        // Check if we already have this transfer
        if (prev.some((t) => t.id === newTransfer.id)) {
          return prev
        }

        const updatedTransfers = [newTransfer, ...prev]

        // Save to local storage if we have an address
        if (address) {
          localStorage.setItem(`${TRANSFERS_STORAGE_KEY}-${address.toLowerCase()}`, JSON.stringify(updatedTransfers))
        }

        return updatedTransfers
      })
    }

    window.addEventListener("newPendingTransfer", handleNewPendingTransfer as EventListener)

    return () => {
      window.removeEventListener("newPendingTransfer", handleNewPendingTransfer as EventListener)
    }
  }, [address])

  // Add some demo transfers if we don't have any
  useEffect(() => {
    if (!isLoading && transfers.length === 0) {
      // Simulate loading transfer history - only completed transfers for demo
      const mockTransfers: Transfer[] = [
        {
          id: "1",
          amount: "100.00",
          fromChain: 84532, // Base
          toChain: 11155111, // Ethereum
          status: "completed",
          timestamp: "2025-06-18T10:30:00Z",
          txHash: "0x1234567890abcdef1234567890abcdef12345678",
          ccipMessageId: "0xabcd...efgh",
        },
      ]

      const timer = setTimeout(() => {
        setTransfers((prev) => {
          // Only add mock transfers if we don't already have them
          const existingIds = prev.map((t) => t.id)
          const newMockTransfers = mockTransfers.filter((t) => !existingIds.includes(t.id))

          const updatedTransfers = [...prev, ...newMockTransfers]

          // Save to local storage if we have an address
          if (address) {
            localStorage.setItem(`${TRANSFERS_STORAGE_KEY}-${address.toLowerCase()}`, JSON.stringify(updatedTransfers))
          }

          return updatedTransfers
        })
      }, 1000)

      return () => clearTimeout(timer)
    }
  }, [isLoading, transfers.length, address])

  const getChainName = (chainId: number) => {
    return SUPPORTED_CHAINS.find((chain) => chain.id === chainId)?.shortName || "Unknown"
  }

  const getBlockExplorerUrl = (chainId: number, txHash: string) => {
    const chain = SUPPORTED_CHAINS.find((c) => c.id === chainId)
    return `${chain?.blockExplorer}/tx/${txHash}`
  }

  const getCCIPExplorerUrl = (messageId: string) => {
    return `https://ccip.chain.link/msg/${messageId}`
  }

  const getStatusIcon = (status: Transfer["status"]) => {
    switch (status) {
      case "completed":
        return <CheckCircle className="h-4 w-4 text-green-600" />
      case "pending":
        return <Clock className="h-4 w-4 text-yellow-600 animate-pulse" />
      case "failed":
        return <AlertCircle className="h-4 w-4 text-red-600" />
    }
  }

  const getStatusColor = (status: Transfer["status"]) => {
    switch (status) {
      case "completed":
        return "bg-green-100 text-green-800"
      case "pending":
        return "bg-yellow-100 text-yellow-800"
      case "failed":
        return "bg-red-100 text-red-800"
    }
  }

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="flex items-center gap-2">
          <Clock className="h-5 w-5" />
          Transfer History
        </CardTitle>
        <Button variant="ghost" size="sm" className="h-8 w-8 p-0" onClick={() => setIsLoading(true)}>
          <RefreshCw className="h-4 w-4" />
          <span className="sr-only">Refresh</span>
        </Button>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="flex justify-center items-center py-8">
            <RefreshCw className="h-8 w-8 animate-spin text-emerald-600" />
          </div>
        ) : transfers.length === 0 ? (
          <div className="text-center py-8 text-slate-500">
            <Clock className="h-12 w-12 mx-auto mb-4 opacity-50" />
            <p>No transfers yet</p>
            <p className="text-sm">Your cross-chain transfers will appear here</p>
          </div>
        ) : (
          <div className="space-y-4">
            {transfers.map((transfer) => (
              <div key={transfer.id} className="border rounded-lg p-4 space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    {getStatusIcon(transfer.status)}
                    <span className="font-medium">{transfer.amount} YieldCoin</span>
                  </div>
                  <Badge className={getStatusColor(transfer.status)}>{transfer.status}</Badge>
                </div>

                <div className="flex items-center justify-between text-sm text-slate-600">
                  <span>
                    {getChainName(transfer.fromChain)} → {getChainName(transfer.toChain)}
                  </span>
                  <span>{new Date(transfer.timestamp).toLocaleDateString()}</span>
                </div>

                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                  {transfer.txHash && (
                    <div className="flex items-center gap-2">
                      <span className="text-xs text-slate-500">Transaction:</span>
                      <a
                        href={getBlockExplorerUrl(transfer.fromChain, transfer.txHash)}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center gap-1 text-green-600 hover:text-green-700"
                      >
                        <Button variant="ghost" size="sm" className="h-6 px-2 text-xs">
                          <ExternalLink className="h-3 w-3 mr-1" />
                          View Tx
                        </Button>
                      </a>
                    </div>
                  )}

                  {transfer.ccipMessageId && (
                    <div className="flex items-center gap-2">
                      <span className="text-xs text-slate-500">CCIP:</span>
                      <a
                        href={getCCIPExplorerUrl(transfer.ccipMessageId)}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center gap-1 text-blue-600 hover:text-blue-700"
                      >
                        <Button variant="ghost" size="sm" className="h-6 px-2 text-xs">
                          <ExternalLink className="h-3 w-3 mr-1" />
                          Track CCIP
                        </Button>
                      </a>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  )
}
