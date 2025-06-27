"use client"

import { useState } from "react"
import { CONTRACTS, CHAIN_SELECTORS, PROTOCOLS, SUPPORTED_CHAINS } from "@/lib/config"

interface StrategyInfo {
  protocol: string
  chainId: number
  chainName: string
  isLoading: boolean
  error: string | null
}

export function useStrategy() {
  const [strategyInfo, setStrategyInfo] = useState<StrategyInfo>({
    protocol: "Aave", // Default to known values
    chainId: 84532, // Base Sepolia
    chainName: "Base",
    isLoading: false, // Start with false since we're using fallback
    error: null,
  })

  const fetchStrategy = async () => {
    // Only try to fetch if user has explicitly connected wallet
    if (!window.ethereum) {
      return // Just use fallback values
    }

    setStrategyInfo((prev) => ({ ...prev, isLoading: true, error: null }))

    try {
      // Don't auto-switch chains, just try the call
      const result = await window.ethereum.request({
        method: "eth_call",
        params: [
          {
            to: CONTRACTS.PARENT_PEER.address,
            data: "0x4b2edeaf", // getStrategy() selector
          },
          "latest",
        ],
      })

      if (result && result !== "0x" && result !== "0x0" && result.length > 2) {
        // Parse the result
        const cleanResult = result.slice(2)
        const chainSelectorHex = cleanResult.slice(0, 64)
        const chainSelector = BigInt("0x" + chainSelectorHex).toString()
        const protocolHex = cleanResult.slice(64, 128)
        const protocol = Number.parseInt(protocolHex.slice(-2), 16)

        const chainEntry = Object.entries(CHAIN_SELECTORS).find(([_, selector]) => selector === chainSelector)

        if (chainEntry) {
          const chainId = chainEntry[0]
          const chain = SUPPORTED_CHAINS.find((c) => c.id === Number.parseInt(chainId))
          const protocolName = PROTOCOLS[protocol as keyof typeof PROTOCOLS] || "Aave"

          setStrategyInfo({
            protocol: protocolName,
            chainId: Number.parseInt(chainId),
            chainName: chain?.shortName || "Base",
            isLoading: false,
            error: null,
          })
          return
        }
      }
    } catch (error) {
      console.log("Strategy fetch failed, using fallback:", error)
    }

    // Always fall back to known values
    setStrategyInfo({
      protocol: "Aave",
      chainId: 84532, // Base Sepolia
      chainName: "Base",
      isLoading: false,
      error: null,
    })
  }

  const refetch = () => {
    fetchStrategy()
  }

  // Don't auto-fetch on mount, just use fallback values
  // Only fetch when explicitly requested via refetch
  return { ...strategyInfo, refetch }
}
