"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Loader2, DollarSign, RefreshCw, ExternalLink } from "lucide-react"
import { useWallet } from "@/contexts/wallet-context"
import { useUSDCBalance } from "@/hooks/use-usdc-balance"
import { CONTRACTS, SUPPORTED_CHAINS } from "@/lib/config"
import { useToast } from "@/hooks/use-toast"
import { ToastAction } from "@/components/ui/toast"

export function DepositCard() {
  const { address, chainId, isConnected } = useWallet()
  const { balance: usdcBalance, isLoading: isLoadingBalance, error: balanceError } = useUSDCBalance(address, chainId)
  const { toast } = useToast()

  const [amount, setAmount] = useState("")
  const [isApproving, setIsApproving] = useState(false)
  const [isDepositing, setIsDepositing] = useState(false)
  const [needsApproval, setNeedsApproval] = useState(true)

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

  const handleApprove = async () => {
    if (!window.ethereum || !chainId || !address || !amount) {
      console.error("Missing requirements for approval")
      return
    }

    const usdcAddress = CONTRACTS.USDC[chainId as keyof typeof CONTRACTS.USDC]
    if (!usdcAddress) {
      console.error("USDC not supported on this chain")
      return
    }

    // Get the spender address (peer contract)
    const spenderAddress = getPeerContractAddress(chainId)
    if (!spenderAddress) {
      console.error("Peer contract not found for this chain")
      return
    }

    setIsApproving(true)

    try {
      // Convert amount to wei (USDC has 6 decimals)
      const amountWei = BigInt(Math.floor(Number.parseFloat(amount) * 1e6)).toString(16)

      // Create approve transaction data
      // approve(address spender, uint256 amount)
      const approveData = `0x095ea7b3000000000000000000000000${spenderAddress.slice(2).toLowerCase()}${amountWei.padStart(64, "0")}`

      const txHash = await window.ethereum.request({
        method: "eth_sendTransaction",
        params: [
          {
            from: address,
            to: usdcAddress,
            data: approveData,
          },
        ],
      })

      console.log("Approval transaction sent:", txHash)

      // Show success toast with block explorer link
      toast({
        variant: "success",
        title: "Approval Transaction Sent",
        description: `Successfully approved ${amount} USDC`,
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

      // Wait a bit then check if approval was successful
      setTimeout(() => {
        setNeedsApproval(false)
        setIsApproving(false)
      }, 2000)
    } catch (error) {
      console.error("Approval failed:", error)
      setIsApproving(false)

      // Show error toast
      toast({
        variant: "destructive",
        title: "Approval Failed",
        description: "Transaction was rejected or failed",
      })
    }
  }

  const handleDeposit = async () => {
    if (!window.ethereum || !chainId || !address || !amount) {
      console.error("Missing requirements for deposit")
      return
    }

    const peerContractAddress = getPeerContractAddress(chainId)
    if (!peerContractAddress) {
      console.error("Peer contract not found for this chain")
      return
    }

    setIsDepositing(true)

    try {
      // Convert amount to wei (USDC has 6 decimals)
      const amountWei = BigInt(Math.floor(Number.parseFloat(amount) * 1e6)).toString(16)

      // Create deposit transaction data
      // deposit(uint256 amountToDeposit)
      const depositData = `0xb6b55f25${amountWei.padStart(64, "0")}`

      const txHash = await window.ethereum.request({
        method: "eth_sendTransaction",
        params: [
          {
            from: address,
            to: peerContractAddress,
            data: depositData,
          },
        ],
      })

      console.log("Deposit transaction sent:", txHash)

      // Show success toast with block explorer link
      toast({
        variant: "success",
        title: "Deposit Transaction Sent",
        description: `Successfully deposited ${amount} USDC`,
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

      // Reset form after successful deposit
      setTimeout(() => {
        setAmount("")
        setNeedsApproval(true) // Reset approval state for next deposit
        setIsDepositing(false)
      }, 2000)
    } catch (error) {
      console.error("Deposit failed:", error)
      setIsDepositing(false)

      // Show error toast
      toast({
        variant: "destructive",
        title: "Deposit Failed",
        description: "Transaction was rejected or failed",
      })
    }
  }

  const isValidAmount = amount && Number.parseFloat(amount) > 0
  const maxAmount = Number.parseFloat(usdcBalance)

  return (
    <Card className="bg-white border-slate-200 shadow-sm">
      <CardHeader className="pb-4">
        <CardTitle className="flex items-center gap-2 text-slate-900">
          <DollarSign className="h-5 w-5 text-emerald-600" />
          Deposit USDC
        </CardTitle>
        <CardDescription className="text-slate-600">
          Deposit USDC to start earning optimized yields across chains
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="space-y-2">
          <Label htmlFor="deposit-amount" className="text-slate-700 font-medium">
            Amount (USDC)
          </Label>
          <Input
            id="deposit-amount"
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
                  `${usdcBalance} USDC`
                )}
              </span>
            </div>
            <button
              className="text-emerald-600 hover:text-emerald-700 disabled:text-slate-400 font-medium"
              onClick={() => setAmount(usdcBalance)}
              disabled={!isConnected || isLoadingBalance || balanceError !== null || maxAmount === 0}
            >
              Max
            </button>
          </div>
        </div>

        <div className="rounded-lg bg-slate-50 border border-slate-200 p-4">
          <div className="flex justify-between text-sm">
            <span className="text-slate-600">You will receive:</span>
            <span className="font-medium text-slate-900">~{amount || "0"} YieldCoin</span>
          </div>
          <div className="flex justify-between text-sm mt-2">
            <span className="text-slate-600">Current APY:</span>
            <span className="text-emerald-600 font-semibold">8.5%</span>
          </div>
        </div>

        <div className="space-y-3">
          {needsApproval && (
            <Button
              onClick={handleApprove}
              disabled={!isConnected || !isValidAmount || isApproving || maxAmount === 0}
              className="w-full bg-slate-600 hover:bg-slate-700 text-white"
            >
              {isApproving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              {isApproving ? "Approving..." : "Approve USDC"}
            </Button>
          )}

          <Button
            onClick={handleDeposit}
            disabled={!isConnected || !isValidAmount || needsApproval || isDepositing || maxAmount === 0}
            className="w-full bg-emerald-600 hover:bg-emerald-700 text-white"
          >
            {isDepositing && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            {isDepositing ? "Depositing..." : "Deposit"}
          </Button>
        </div>

        <p className="text-xs text-slate-500">
          Your USDC will be automatically allocated to the highest-yielding strategy across supported protocols.
        </p>
      </CardContent>
    </Card>
  )
}
