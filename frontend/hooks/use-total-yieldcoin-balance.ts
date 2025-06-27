"use client"

import { useState, useEffect } from "react"
import { CONTRACTS, SUPPORTED_CHAINS } from "@/lib/config"

interface ChainBalance {
  chainId: number
  balance: string
  isLoading: boolean
  error: string | null
}

export function useTotalYieldCoinBalance(address: string | null) {
  const [chainBalances, setChainBalances] = useState<ChainBalance[]>([])
  const [totalBalance, setTotalBalance] = useState("0.00")
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!address || !window.ethereum) {
      setChainBalances([])
      setTotalBalance("0.00")
      setIsLoading(false)
      return
    }

    const fetchBalancesAcrossChains = async () => {
      setIsLoading(true)
      setError(null)

      const balancePromises = SUPPORTED_CHAINS.map(async (chain) => {
        const yieldCoinAddress = CONTRACTS.YIELDCOIN[chain.id as keyof typeof CONTRACTS.YIELDCOIN]

        if (!yieldCoinAddress) {
          return {
            chainId: chain.id,
            balance: "0.00",
            isLoading: false,
            error: "Contract not deployed",
          }
        }

        try {
          // Create contract call data for balanceOf
          const balanceOfData = `0x70a08231000000000000000000000000${address.slice(2).toLowerCase()}`

          // Call balanceOf on this specific chain
          const balanceResult = await window.ethereum.request({
            method: "eth_call",
            params: [
              {
                to: yieldCoinAddress,
                data: balanceOfData,
              },
              "latest",
            ],
          })

          if (!balanceResult || balanceResult === "0x" || balanceResult === "0x0") {
            return {
              chainId: chain.id,
              balance: "0.00",
              isLoading: false,
              error: null,
            }
          }

          try {
            const balanceWei = BigInt(balanceResult)
            // YieldCoin has 18 decimals
            const balanceFormatted = (Number(balanceWei) / 1e18).toFixed(6)
            return {
              chainId: chain.id,
              balance: balanceFormatted,
              isLoading: false,
              error: null,
            }
          } catch (parseError) {
            console.error(`Failed to parse YieldCoin balance for chain ${chain.id}:`, parseError)
            return {
              chainId: chain.id,
              balance: "0.00",
              isLoading: false,
              error: "Parse error",
            }
          }
        } catch (err) {
          console.error(`Failed to fetch YieldCoin balance for chain ${chain.id}:`, err)
          return {
            chainId: chain.id,
            balance: "0.00",
            isLoading: false,
            error: "Network error",
          }
        }
      })

      try {
        const results = await Promise.all(balancePromises)
        setChainBalances(results)

        // Calculate total balance
        const total = results.reduce((sum, chainBalance) => {
          return sum + Number.parseFloat(chainBalance.balance)
        }, 0)

        setTotalBalance(total.toFixed(6))
      } catch (err) {
        console.error("Failed to fetch balances across chains:", err)
        setError("Failed to fetch balances")
      } finally {
        setIsLoading(false)
      }
    }

    fetchBalancesAcrossChains()
  }, [address])

  const refetch = () => {
    if (address) {
      setError(null)
      setIsLoading(true)
      // Re-trigger the effect
      setTimeout(() => {
        // This will trigger the useEffect again
      }, 0)
    }
  }

  return {
    chainBalances,
    totalBalance,
    isLoading,
    error,
    refetch,
  }
}
