"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Loader2, ArrowUpRight, RefreshCw, ExternalLink } from "lucide-react"
import { CONTRACTS, SUPPORTED_CHAINS } from "@/lib/config"
import { useWallet } from "@/contexts/wallet-context"
import { useYieldCoinBalance } from "@/hooks/use-yieldcoin-balance"
import { useToast } from "@/hooks/use-toast"
import { ToastAction } from "@/components/ui/toast"

// viem utilities for chain-agnostic reads
import { createPublicClient, http, type Chain } from "viem"
import { sepolia, baseSepolia } from "viem/chains"

function getViemChain(chainId: number): Chain {
  switch (chainId) {
    case 11155111:
      return sepolia
    case 84532:
      return baseSepolia
    case 43113:
      return {
        id: 43113,
        name: "Avalanche Fuji",
        nativeCurrency: { name: "AVAX", symbol: "AVAX", decimals: 18 },
        rpcUrls: {
          default: { http: ["https://api.avax-test.network/ext/bc/C/rpc"] },
          public: { http: ["https://api.avax-test.network/ext/bc/C/rpc"] },
        },
        blockExplorers: {
          default: { name: "SnowTrace", url: "https://testnet.snowtrace.io" },
        },
        testnet: true,
      }
    default:
      return sepolia
  }
}

// ABIs for the read-only calls
const PEER_ABI = [
  {
    type: "function",
    name: "getTotalValue",
    stateMutability: "view",
    inputs: [],
    outputs: [{ type: "uint256" }],
  },
] as const

const PARENT_ABI = [
  {
    type: "function",
    name: "getTotalShares",
    stateMutability: "view",
    inputs: [],
    outputs: [{ type: "uint256" }],
  },
] as const

export function WithdrawCard() {
  const { address, chainId, isConnected } = useWallet()
  const {
    balance: yieldCoinBalance,
    isLoading: isLoadingBalance,
    error: balanceError,
  } = useYieldCoinBalance(address, chainId)
  const { toast } = useToast()

  const [amount, setAmount] = useState("")
  const [selectedChainId, setSelectedChainId] = useState<string>("")
  const [isWithdrawing, setIsWithdrawing] = useState(false)
  const [calculatedUsdcAmount, setCalculatedUsdcAmount] = useState("0.00")
  const [isCalculatingAmount, setIsCalculatingAmount] = useState(false)

  const getBlockExplorerUrl = (chainId: number, txHash: string) => {
    const chain = SUPPORTED_CHAINS.find((c) => c.id === chainId)
    return `${chain?.blockExplorer}/tx/${txHash}`
  }

  const getPeerContractAddress = (chainId: number) => {
    switch (chainId) {
      case 11155111: // Ethereum Sepolia
        return CONTRACTS.PARENT_PEER.address
      case 84532: // Base Sepolia
        return CONTRACTS.CHILD_PEERS.BASE_SEPOLIA.address
      case 43113: // Avalanche Fuji
        return CONTRACTS.CHILD_PEERS.AVALANCHE_FUJI.address
      default:
        return null
    }
  }

  const calculateUsdcAmount = async () => {
    if (!chainId || !amount || Number.parseFloat(amount) === 0) {
      setCalculatedUsdcAmount("0.00")
      return
    }

    const peerContractAddress = getPeerContractAddress(chainId)
    if (!peerContractAddress) {
      setCalculatedUsdcAmount("0.00")
      return
    }

    setIsCalculatingAmount(true)

    try {
      const shareBurnAmount = BigInt(Math.floor(Number.parseFloat(amount) * 1e18))

      // 1) Get totalValue from peer on current chain
      const currentChain = getViemChain(chainId)
      const peerClient = createPublicClient({
        chain: currentChain,
        transport: http(),
      })
      const totalValue: bigint = await peerClient.readContract({
        address: peerContractAddress as `0x${string}`,
        abi: PEER_ABI,
        functionName: "getTotalValue",
      })

      // 2) Get totalShares from parent on Sepolia
      const parentClient = createPublicClient({
        chain: sepolia,
        transport: http(),
      })
      const totalShares: bigint = await parentClient.readContract({
        address: CONTRACTS.PARENT_PEER.address as `0x${string}`,
        abi: PARENT_ABI,
        functionName: "getTotalShares",
      })

      console.log("Calculation inputs:")
      console.log("- Total Value:", totalValue.toString())
      console.log("- Total Shares:", totalShares.toString())
      console.log("- Share Burn Amount:", shareBurnAmount.toString())

      // Implement the contract's calculation logic
      const INITIAL_SHARE_PRECISION = BigInt(1e12)

      // shareWithdrawAmount = ((totalValue * INITIAL_SHARE_PRECISION * shareBurnAmount) / totalShares)
      const shareWithdrawAmount = (totalValue * INITIAL_SHARE_PRECISION * shareBurnAmount) / totalShares

      // usdcWithdrawAmount = shareWithdrawAmount / INITIAL_SHARE_PRECISION
      const usdcWithdrawAmount = shareWithdrawAmount / INITIAL_SHARE_PRECISION

      // Convert to human readable format (USDC has 6 decimals)
      const usdcAmountFormatted = (Number(usdcWithdrawAmount) / 1e6).toFixed(6)
      setCalculatedUsdcAmount(usdcAmountFormatted)

      console.log("Calculated USDC amount:", usdcAmountFormatted)
    } catch (error) {
      console.error("Failed to calculate USDC amount:", error)
      setCalculatedUsdcAmount("0.00")
    } finally {
      setIsCalculatingAmount(false)
    }
  }

  // Calculate USDC amount when amount changes
  useEffect(() => {
    const timer = setTimeout(() => {
      calculateUsdcAmount()
    }, 500) // Debounce for 500ms

    return () => clearTimeout(timer)
  }, [amount, chainId])

  const handleWithdraw = async () => {
    if (!window.ethereum || !chainId || !address || !amount || !selectedChainId) {
      console.error("Missing requirements for withdrawal")
      return
    }

    const yieldCoinAddress = CONTRACTS.YIELDCOIN[chainId as keyof typeof CONTRACTS.YIELDCOIN]
    const peerContractAddress = getPeerContractAddress(chainId)

    if (!yieldCoinAddress || !peerContractAddress) {
      console.error("Contract addresses not found for this chain")
      return
    }

    setIsWithdrawing(true)

    try {
      // Convert amount to wei (YieldCoin has 18 decimals)
      const amountWei = BigInt(Math.floor(Number.parseFloat(amount) * 1e18))

      // Encode the destination chain ID as bytes data for transferAndCall
      const destinationChainId = Number.parseInt(selectedChainId)

      // If withdrawing to the same chain, use empty data
      // If withdrawing to a different chain, encode the destination chain ID
      let dataBytes = "0x"
      if (destinationChainId !== chainId) {
        // Cross-chain withdrawal - encode destination chain ID
        const destinationChainIdHex = destinationChainId.toString(16).padStart(64, "0")
        dataBytes = `0x${destinationChainIdHex}`
      }

      // Create transferAndCall transaction data
      // transferAndCall(address to, uint256 amount, bytes data)
      let transferAndCallData
      if (destinationChainId === chainId) {
        // Same chain withdrawal - simpler encoding with empty data
        transferAndCallData = `0x4000aea0000000000000000000000000${peerContractAddress.slice(2).toLowerCase()}${amountWei.toString(16).padStart(64, "0")}00000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000`
      } else {
        // Cross-chain withdrawal - include destination chain ID
        const destinationChainIdHex = destinationChainId.toString(16).padStart(64, "0")
        transferAndCallData = `0x4000aea0000000000000000000000000${peerContractAddress.slice(2).toLowerCase()}${amountWei.toString(16).padStart(64, "0")}0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000${destinationChainIdHex}`
      }

      console.log("Withdraw transaction details:")
      console.log("- YieldCoin address:", yieldCoinAddress)
      console.log("- Peer contract address:", peerContractAddress)
      console.log("- Amount (wei):", amountWei.toString())
      console.log("- Destination chain ID:", destinationChainId)
      console.log("- Same chain withdrawal:", destinationChainId === chainId)
      console.log("- Data bytes:", dataBytes)
      console.log("- Full transaction data:", transferAndCallData)

      const txHash = await window.ethereum.request({
        method: "eth_sendTransaction",
        params: [
          {
            from: address,
            to: yieldCoinAddress,
            data: transferAndCallData,
          },
        ],
      })

      console.log("Withdraw transaction sent:", txHash)

      // Show success toast with block explorer link immediately
      toast({
        variant: "success",
        title: "Withdrawal Transaction Sent",
        description: `Withdrawing ${amount} YieldCoin to ${SUPPORTED_CHAINS.find((c) => c.id === destinationChainId)?.shortName}`,
        action: (
          <ToastAction altText="View transaction">
            <a
              href={getBlockExplorerUrl(chainId, txHash)}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1 text-green-700 hover:text-green-800"
            >
              View Tx <ExternalLink className="h-3 w-3" />
            </a>
          </ToastAction>
        ),
      })

      // Reset form after successful withdrawal
      setTimeout(() => {
        setAmount("")
        setSelectedChainId("")
        setIsWithdrawing(false)
      }, 2000)
    } catch (error) {
      console.error("Withdrawal failed:", error)
      setIsWithdrawing(false)

      // Show error toast
      toast({
        variant: "destructive",
        title: "Withdrawal Failed",
        description: error instanceof Error ? error.message : "Transaction was rejected or failed",
      })
    }
  }

  const isValidAmount = amount && Number.parseFloat(amount) > 0
  const selectedChain = SUPPORTED_CHAINS.find((chain) => chain.id.toString() === selectedChainId)
  const maxAmount = Number.parseFloat(yieldCoinBalance)

  return (
    <Card className="bg-white border-slate-200 shadow-sm">
      <CardHeader className="pb-4">
        <CardTitle className="flex items-center gap-2 text-slate-900">
          <ArrowUpRight className="h-5 w-5 text-emerald-600" />
          Withdraw USDC
        </CardTitle>
        <CardDescription className="text-slate-600">Redeem your YieldCoin for USDC plus earned yield</CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="space-y-2">
          <Label htmlFor="withdraw-amount" className="text-slate-700 font-medium">
            Amount (YieldCoin)
          </Label>
          <Input
            id="withdraw-amount"
            type="number"
            placeholder="0.00"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            className="text-lg border-slate-300 focus:border-emerald-500 focus:ring-emerald-500"
            max={maxAmount}
            disabled={!isConnected}
          />
          <div className="flex justify-between text-sm text-slate-600">
            <div className="flex items-center gap-2">
              <span>
                Balance:{" "}
                {!isConnected ? (
                  "Connect wallet"
                ) : isLoadingBalance ? (
                  <span className="inline-flex items-center gap-1">
                    <RefreshCw className="h-3 w-3 animate-spin" />
                    Loading...
                  </span>
                ) : balanceError ? (
                  <span className="text-red-600">Error loading</span>
                ) : (
                  `${yieldCoinBalance} YieldCoin`
                )}
              </span>
            </div>
            <button
              className="text-emerald-600 hover:text-emerald-700 disabled:text-slate-400 font-medium"
              onClick={() => setAmount(yieldCoinBalance)}
              disabled={!isConnected || isLoadingBalance || balanceError !== null || maxAmount === 0}
            >
              Max
            </button>
          </div>
        </div>

        <div className="space-y-2">
          <Label className="text-slate-700 font-medium">Withdraw to Chain</Label>
          <Select value={selectedChainId} onValueChange={setSelectedChainId}>
            <SelectTrigger className="border-slate-300 focus:border-emerald-500 focus:ring-emerald-500">
              <SelectValue placeholder="Select destination chain" />
            </SelectTrigger>
            <SelectContent>
              {SUPPORTED_CHAINS.map((chain) => (
                <SelectItem key={chain.id} value={chain.id.toString()}>
                  {chain.name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        <div className="rounded-lg bg-slate-50 border border-slate-200 p-4">
          <div className="flex justify-between text-sm">
            <span className="text-slate-600">You will receive:</span>
            <span className="font-medium text-slate-900">
              {isCalculatingAmount ? (
                <span className="inline-flex items-center gap-1">
                  <RefreshCw className="h-3 w-3 animate-spin" />
                  Calculating...
                </span>
              ) : (
                `${calculatedUsdcAmount} USDC`
              )}
            </span>
          </div>
          <div className="flex justify-between text-sm mt-2">
            <span className="text-slate-600">Destination:</span>
            <span className="font-medium text-slate-900">{selectedChain?.shortName || "Select chain"}</span>
          </div>
        </div>

        <Button
          onClick={handleWithdraw}
          disabled={!isConnected || !isValidAmount || !selectedChainId || isWithdrawing || maxAmount === 0}
          className="w-full bg-emerald-600 hover:bg-emerald-700 text-white"
        >
          {isWithdrawing && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
          {isWithdrawing ? "Withdrawing..." : "Withdraw"}
        </Button>

        <p className="text-xs text-slate-500">
          Withdraw your YieldCoin to receive USDC plus any earned yield. Cross-chain withdrawals may take a few minutes
          to complete.
        </p>
      </CardContent>
    </Card>
  )
}
