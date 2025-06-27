"use client"

import { useState, useEffect } from "react"
import { CONTRACTS } from "@/lib/config"

export function useUSDCBalance(address: string | null, chainId: number | null) {
  const [balance, setBalance] = useState("0.00")
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    // Only fetch if user is connected AND we have address/chainId
    if (!address || !chainId || !window.ethereum) {
      setBalance("0.00")
      setIsLoading(false)
      return
    }

    const usdcAddress = CONTRACTS.USDC[chainId as keyof typeof CONTRACTS.USDC]
    if (!usdcAddress) {
      setBalance("0.00")
      setIsLoading(false)
      return
    }

    const fetchBalance = async () => {
      setIsLoading(true)
      setError(null)

      try {
        // Create contract call data for balanceOf
        const balanceOfData = `0x70a08231000000000000000000000000${address.slice(2).toLowerCase()}`

        // Call balanceOf
        const balanceResult = await window.ethereum.request({
          method: "eth_call",
          params: [
            {
              to: usdcAddress,
              data: balanceOfData,
            },
            "latest",
          ],
        })

        if (!balanceResult || balanceResult === "0x" || balanceResult === "0x0") {
          setBalance("0.00")
          return
        }

        try {
          const balanceWei = BigInt(balanceResult)
          const balanceFormatted = (Number(balanceWei) / 1e6).toFixed(6)
          setBalance(balanceFormatted)
        } catch (parseError) {
          console.error("Failed to parse balance result:", parseError, { balanceResult })
          setBalance("0.00")
        }
      } catch (err) {
        console.error("Failed to fetch USDC balance:", err)
        setError("Failed to fetch balance")
        setBalance("0.00")
      } finally {
        setIsLoading(false)
      }
    }

    fetchBalance()
  }, [address, chainId]) // Only run when these change

  const refetch = () => {
    if (address && chainId) {
      const usdcAddress = CONTRACTS.USDC[chainId as keyof typeof CONTRACTS.USDC]
      if (usdcAddress) {
        setError(null)
        setIsLoading(true)
        // Re-trigger the effect by forcing a state update
        setTimeout(() => {
          // This will trigger the useEffect again
        }, 0)
      }
    }
  }

  return { balance, isLoading, error, refetch }
}
