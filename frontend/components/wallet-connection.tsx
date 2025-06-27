"use client"

import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Wallet, ChevronDown } from "lucide-react"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { SUPPORTED_CHAINS } from "@/lib/config"
import { useWallet } from "@/contexts/wallet-context"

export function WalletConnection() {
  const { isConnected, address, chainId, isConnecting, connectWallet, switchChain } = useWallet()

  console.log("WalletConnection render - chainId:", chainId) // Debug log

  const currentChain = SUPPORTED_CHAINS.find((chain) => chain.id === chainId)
  const isUnsupportedChain = chainId && !SUPPORTED_CHAINS.find((chain) => chain.id === chainId)

  console.log("Current chain found:", currentChain) // Debug log

  if (!isConnected) {
    return (
      <Button onClick={connectWallet} disabled={isConnecting}>
        <Wallet className="mr-2 h-4 w-4" />
        {isConnecting ? "Connecting..." : "Connect Wallet"}
      </Button>
    )
  }

  return (
    <div className="flex items-center gap-3">
      {currentChain && (
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="outline" size="sm">
              {currentChain.shortName}
              <ChevronDown className="ml-2 h-4 w-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent>
            {SUPPORTED_CHAINS.map((chain) => (
              <DropdownMenuItem
                key={chain.id}
                onClick={() => {
                  console.log("Switching to chain:", chain.id, chain.name) // Debug log
                  switchChain(chain.id)
                }}
                className={chainId === chain.id ? "bg-slate-100" : ""}
              >
                {chain.name}
                {chainId === chain.id && <span className="ml-2 text-green-600">✓</span>}
              </DropdownMenuItem>
            ))}
          </DropdownMenuContent>
        </DropdownMenu>
      )}
      {isUnsupportedChain && (
        <Badge variant="destructive" className="text-xs">
          Unsupported Chain
        </Badge>
      )}

      <Badge variant="secondary" className="font-mono">
        {address ? `${address.slice(0, 6)}...${address.slice(-4)}` : ""}
      </Badge>
    </div>
  )
}
