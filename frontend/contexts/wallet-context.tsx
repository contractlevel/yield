"use client"

import { createContext, useContext, useState, useEffect, type ReactNode } from "react"
import { SUPPORTED_CHAINS } from "@/lib/config"

interface WalletContextType {
  isConnected: boolean
  address: string | null
  chainId: number | null
  isConnecting: boolean
  connectWallet: () => Promise<void>
  switchChain: (chainId: number) => Promise<void>
}

const WalletContext = createContext<WalletContextType | undefined>(undefined)

export function WalletProvider({ children }: { children: ReactNode }) {
  const [isConnected, setIsConnected] = useState(false)
  const [address, setAddress] = useState<string | null>(null)
  const [chainId, setChainId] = useState<number | null>(null)
  const [isConnecting, setIsConnecting] = useState(false)

  const connectWallet = async () => {
    if (typeof window.ethereum === "undefined") {
      alert("Please install MetaMask to use this app")
      return
    }

    setIsConnecting(true)
    try {
      const accounts = await window.ethereum.request({
        method: "eth_requestAccounts",
      })

      const chainId = await window.ethereum.request({
        method: "eth_chainId",
      })

      setAddress(accounts[0])
      setChainId(Number.parseInt(chainId, 16))
      setIsConnected(true)
    } catch (error) {
      console.error("Failed to connect wallet:", error)
    } finally {
      setIsConnecting(false)
    }
  }

  const switchChain = async (targetChainId: number) => {
    if (!window.ethereum) return

    try {
      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: `0x${targetChainId.toString(16)}` }],
      })

      // Manually update the chainId state after successful switch
      setChainId(targetChainId)
    } catch (error: any) {
      console.error("Chain switch error:", error)
      // Chain not added to wallet
      if (error.code === 4902) {
        const chain = SUPPORTED_CHAINS.find((c) => c.id === targetChainId)
        if (chain) {
          try {
            await window.ethereum.request({
              method: "wallet_addEthereumChain",
              params: [
                {
                  chainId: `0x${targetChainId.toString(16)}`,
                  chainName: chain.name,
                  rpcUrls: [chain.rpcUrl],
                  blockExplorerUrls: [chain.blockExplorer],
                  nativeCurrency: {
                    name: "ETH",
                    symbol: "ETH",
                    decimals: 18,
                  },
                },
              ],
            })
            // Update chainId after adding and switching
            setChainId(targetChainId)
          } catch (addError) {
            console.error("Failed to add chain:", addError)
          }
        }
      }
    }
  }

  useEffect(() => {
    if (typeof window !== "undefined" && window.ethereum) {
      // Only check if already connected, don't auto-connect
      window.ethereum
        .request({ method: "eth_accounts" })
        .then((accounts: string[]) => {
          if (accounts.length > 0) {
            // Only set as connected if there are accounts (user previously connected)
            setAddress(accounts[0])
            setIsConnected(true)
            // Get current chain
            return window.ethereum.request({ method: "eth_chainId" })
          }
        })
        .then((chainId: string) => {
          if (chainId) {
            const parsedChainId = Number.parseInt(chainId, 16)
            console.log("Initial chain ID:", parsedChainId)
            setChainId(parsedChainId)
          }
        })
        .catch((error) => {
          console.error("Failed to get initial wallet state:", error)
        })

      const handleAccountsChanged = (accounts: string[]) => {
        console.log("Accounts changed:", accounts)
        if (accounts.length === 0) {
          setIsConnected(false)
          setAddress(null)
          setChainId(null)
        } else {
          setAddress(accounts[0])
          setIsConnected(true)
        }
      }

      const handleChainChanged = (chainId: string) => {
        const parsedChainId = Number.parseInt(chainId, 16)
        console.log("Chain changed event:", chainId, "->", parsedChainId)
        setChainId(parsedChainId)

        // Force a re-render by updating the state
        setTimeout(() => {
          console.log("Chain ID updated to:", parsedChainId)
        }, 100)
      }

      window.ethereum.on("accountsChanged", handleAccountsChanged)
      window.ethereum.on("chainChanged", handleChainChanged)

      return () => {
        if (window.ethereum) {
          window.ethereum.removeListener("accountsChanged", handleAccountsChanged)
          window.ethereum.removeListener("chainChanged", handleChainChanged)
        }
      }
    }
  }, [])

  return (
    <WalletContext.Provider
      value={{
        isConnected,
        address,
        chainId,
        isConnecting,
        connectWallet,
        switchChain,
      }}
    >
      {children}
    </WalletContext.Provider>
  )
}

export function useWallet() {
  const context = useContext(WalletContext)
  if (context === undefined) {
    throw new Error("useWallet must be used within a WalletProvider")
  }
  return context
}
