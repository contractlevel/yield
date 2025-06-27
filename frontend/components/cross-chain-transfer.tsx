"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Badge } from "@/components/ui/badge"
import { Loader2, ArrowRight, RefreshCw, ExternalLink } from "lucide-react"
import { SUPPORTED_CHAINS, CONTRACTS, CHAIN_SELECTORS } from "@/lib/config"
import { useWallet } from "@/contexts/wallet-context"
import { useYieldCoinBalance } from "@/hooks/use-yieldcoin-balance"
import { useToast } from "@/hooks/use-toast"
import { ToastAction } from "@/components/ui/toast"
import * as CCIP from "@chainlink/ccip-js"
import { createWalletClient, createPublicClient, custom, http } from "viem"
import { sepolia, baseSepolia } from "viem/chains"

export function CrossChainTransfer() {
  const { address, chainId, isConnected } = useWallet()
  const { balance: yieldCoinBalance, isLoading: isLoadingBalance } = useYieldCoinBalance(address, chainId)
  const { toast } = useToast()

  const [amount, setAmount] = useState("")
  const [destinationChainId, setDestinationChainId] = useState<string>("")
  const [isApproving, setIsApproving] = useState(false)
  const [isTransferring, setIsTransferring] = useState(false)
  const [needsApproval, setNeedsApproval] = useState(true)
  const [estimatedFee, setEstimatedFee] = useState<string | null>(null)
  const [isEstimatingFee, setIsEstimatingFee] = useState(false)

  const sourceChain = SUPPORTED_CHAINS.find((chain) => chain.id === chainId)
  const destinationChain = SUPPORTED_CHAINS.find((chain) => chain.id.toString() === destinationChainId)

  // Initialize CCIP client
  const ccipClient = CCIP.createClient()

  const getViemChain = (chainId: number) => {
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

  const getBlockExplorerUrl = (chainId: number, txHash: string) => {
    const chain = SUPPORTED_CHAINS.find((c) => c.id === chainId)
    return `${chain?.blockExplorer}/tx/${txHash}`
  }

  const estimateFee = async () => {
    if (!chainId || !destinationChainId || !amount || !address) return

    const routerAddress = CONTRACTS.CCIP_ROUTER[chainId as keyof typeof CONTRACTS.CCIP_ROUTER]
    const yieldCoinAddress = CONTRACTS.YIELDCOIN[chainId as keyof typeof CONTRACTS.YIELDCOIN]
    const destChainSelector = CHAIN_SELECTORS[Number.parseInt(destinationChainId) as keyof typeof CHAIN_SELECTORS]

    if (!routerAddress || !yieldCoinAddress || !destChainSelector) return

    setIsEstimatingFee(true)

    try {
      const viemChain = getViemChain(chainId)
      const publicClient = createPublicClient({
        chain: viemChain,
        transport: http(),
      })

      const amountWei = BigInt(Math.floor(Number.parseFloat(amount) * 1e18))

      // Use CCIP SDK to get fee
      const fee = await ccipClient.getFee({
        client: publicClient,
        routerAddress: routerAddress as `0x${string}`,
        tokenAddress: yieldCoinAddress as `0x${string}`,
        amount: amountWei,
        destinationAccount: address as `0x${string}`,
        destinationChainSelector: destChainSelector,
      })

      // Convert fee to ETH for display
      const feeInEth = (Number(fee) / 1e18).toFixed(6)
      setEstimatedFee(feeInEth)

      console.log("CCIP Fee estimated:", feeInEth, "ETH")
    } catch (error) {
      console.error("Fee estimation failed:", error)
      setEstimatedFee("0.01") // Fallback estimate
    } finally {
      setIsEstimatingFee(false)
    }
  }

  const handleApprove = async () => {
    if (!window.ethereum || !chainId || !address || !amount) {
      console.error("Missing requirements:", { ethereum: !!window.ethereum, chainId, address, amount })
      return
    }

    const routerAddress = CONTRACTS.CCIP_ROUTER[chainId as keyof typeof CONTRACTS.CCIP_ROUTER]
    const yieldCoinAddress = CONTRACTS.YIELDCOIN[chainId as keyof typeof CONTRACTS.YIELDCOIN]

    if (!routerAddress || !yieldCoinAddress) {
      console.error("Missing contract addresses:", { routerAddress, yieldCoinAddress })
      return
    }

    setIsApproving(true)

    try {
      const viemChain = getViemChain(chainId)

      // Create wallet client with proper account
      const walletClient = createWalletClient({
        account: address as `0x${string}`,
        chain: viemChain,
        transport: custom(window.ethereum),
      })

      const amountWei = BigInt(Math.floor(Number.parseFloat(amount) * 1e18))

      console.log("Approving with CCIP SDK:")
      console.log("- Chain:", viemChain.name)
      console.log("- Account:", address)
      console.log("- Router:", routerAddress)
      console.log("- Token:", yieldCoinAddress)
      console.log("- Amount:", amountWei.toString())

      // Use CCIP SDK to approve - but don't wait for receipt initially
      const approvalPromise = ccipClient.approveRouter({
        client: walletClient,
        routerAddress: routerAddress as `0x${string}`,
        tokenAddress: yieldCoinAddress as `0x${string}`,
        amount: amountWei,
        waitForReceipt: false, // Don't wait initially
      })

      // Get the transaction hash immediately
      const { txHash } = await approvalPromise

      console.log("Approval transaction sent:", txHash)

      // Show toast immediately when transaction is sent
      toast({
        variant: "success",
        title: "Approval Transaction Sent",
        description: `Approving ${amount} YieldCoin for bridging`,
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

      // Now wait for confirmation in the background
      const { txReceipt } = await ccipClient.approveRouter({
        client: walletClient,
        routerAddress: routerAddress as `0x${string}`,
        tokenAddress: yieldCoinAddress as `0x${string}`,
        amount: amountWei,
        waitForReceipt: true,
      })

      console.log("Approval confirmed:", txReceipt)
      setNeedsApproval(false)
      setIsApproving(false)
    } catch (error) {
      console.error("Approval failed:", error)
      setIsApproving(false)
      toast({
        variant: "destructive",
        title: "Approval Failed",
        description: error instanceof Error ? error.message : "Transaction was rejected or failed",
      })
    }
  }

  const handleTransfer = async () => {
    if (!window.ethereum || !chainId || !address || !amount || !destinationChainId) return

    const routerAddress = CONTRACTS.CCIP_ROUTER[chainId as keyof typeof CONTRACTS.CCIP_ROUTER]
    const yieldCoinAddress = CONTRACTS.YIELDCOIN[chainId as keyof typeof CONTRACTS.YIELDCOIN]
    const destChainSelector = CHAIN_SELECTORS[Number.parseInt(destinationChainId) as keyof typeof CHAIN_SELECTORS]

    if (!routerAddress || !yieldCoinAddress || !destChainSelector) return

    setIsTransferring(true)

    try {
      const viemChain = getViemChain(chainId)

      // Create wallet client with proper account
      const walletClient = createWalletClient({
        account: address as `0x${string}`,
        chain: viemChain,
        transport: custom(window.ethereum),
      })

      const amountWei = BigInt(Math.floor(Number.parseFloat(amount) * 1e18))

      console.log("Transferring with CCIP SDK:")
      console.log("- Chain:", viemChain.name)
      console.log("- Account:", address)
      console.log("- Router:", routerAddress)
      console.log("- Token:", yieldCoinAddress)
      console.log("- Amount:", amountWei.toString())
      console.log("- Destination Chain Selector:", destChainSelector)
      console.log("- Destination Account:", address)

      // Use CCIP SDK to transfer tokens (paying fee with native token)
      const { txHash, messageId } = await ccipClient.transferTokens({
        client: walletClient,
        routerAddress: routerAddress as `0x${string}`,
        tokenAddress: yieldCoinAddress as `0x${string}`,
        amount: amountWei,
        destinationAccount: address as `0x${string}`,
        destinationChainSelector: destChainSelector,
        // feeTokenAddress not specified = pay with native token
      })

      console.log("Transfer transaction sent:", txHash, "Message ID:", messageId)

      // Show toast immediately when transaction is sent
      toast({
        variant: "success",
        title: "Bridge Transaction Sent",
        description: `Bridging ${amount} YieldCoin to ${destinationChain?.shortName}`,
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

      // Add pending transfer to history immediately
      const pendingTransfer = {
        id: txHash,
        amount: amount,
        fromChain: chainId,
        toChain: Number.parseInt(destinationChainId),
        status: "pending" as const,
        timestamp: new Date().toISOString(),
        txHash: txHash,
        ccipMessageId: messageId,
      }

      // Trigger a custom event to add the pending transfer
      window.dispatchEvent(new CustomEvent("newPendingTransfer", { detail: pendingTransfer }))

      setTimeout(() => {
        setAmount("")
        setNeedsApproval(true)
        setIsTransferring(false)
      }, 2000)
    } catch (error) {
      console.error("Transfer failed:", error)
      setIsTransferring(false)
      toast({
        variant: "destructive",
        title: "Bridge Failed",
        description: error instanceof Error ? error.message : "Transaction was rejected or failed",
      })
    }
  }

  const isValidAmount = amount && Number.parseFloat(amount) > 0
  const maxAmount = Number.parseFloat(yieldCoinBalance)
  const canTransfer = isValidAmount && destinationChainId && chainId?.toString() !== destinationChainId

  // Estimate fee when amount or destination changes
  useState(() => {
    if (canTransfer && !isEstimatingFee) {
      estimateFee()
    }
  })

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <ArrowRight className="h-5 w-5" />
          Cross-Chain Transfer
        </CardTitle>
        <CardDescription>
          Transfer your YieldCoin between chains using Chainlink CCIP. Your yield continues to accrue during transfer.
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Source Chain */}
        <div className="space-y-2">
          <Label>From Chain</Label>
          <div className="flex items-center justify-between p-3 border rounded-lg bg-slate-50">
            <span className="font-medium">{sourceChain?.name || "Connect Wallet"}</span>
            <Badge variant="outline" className="ml-2">
              {isLoadingBalance ? <RefreshCw className="h-3 w-3 animate-spin" /> : `${yieldCoinBalance} YIELD`}
            </Badge>
          </div>
        </div>

        {/* Destination Chain */}
        <div className="space-y-2">
          <Label>To Chain</Label>
          <Select value={destinationChainId} onValueChange={setDestinationChainId}>
            <SelectTrigger>
              <SelectValue placeholder="Select destination chain" />
            </SelectTrigger>
            <SelectContent>
              {SUPPORTED_CHAINS.filter((chain) => chain.id !== chainId).map((chain) => (
                <SelectItem key={chain.id} value={chain.id.toString()}>
                  {chain.name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        {/* Amount */}
        <div className="space-y-2">
          <Label htmlFor="transfer-amount">Amount (YieldCoin)</Label>
          <Input
            id="transfer-amount"
            type="number"
            placeholder="0.00"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            className="text-lg"
            disabled={!isConnected}
          />
          <div className="flex justify-between text-sm text-slate-600">
            <span>Available: {yieldCoinBalance} YieldCoin</span>
            <button
              className="text-green-600 hover:text-green-700"
              onClick={() => setAmount(yieldCoinBalance)}
              disabled={!isConnected || maxAmount === 0}
            >
              Max
            </button>
          </div>
        </div>

        {/* Transfer Summary */}
        {canTransfer && (
          <div className="rounded-lg bg-slate-50 p-4 space-y-3">
            <div className="flex justify-between text-sm">
              <span>Transfer Amount:</span>
              <span className="font-medium">{amount} YieldCoin</span>
            </div>
            <div className="flex justify-between text-sm">
              <span>From:</span>
              <span className="font-medium">{sourceChain?.shortName}</span>
            </div>
            <div className="flex justify-between text-sm">
              <span>To:</span>
              <span className="font-medium">{destinationChain?.shortName}</span>
            </div>
            <div className="flex justify-between text-sm">
              <span>Estimated Time:</span>
              <span className="font-medium text-green-600">10-20 minutes</span>
            </div>
            <div className="flex justify-between text-sm">
              <span>CCIP Fee:</span>
              <span className="font-medium">
                {isEstimatingFee ? (
                  <RefreshCw className="h-3 w-3 animate-spin inline" />
                ) : (
                  `~${estimatedFee || "0.01"} ETH`
                )}
              </span>
            </div>
          </div>
        )}

        {/* Action Buttons */}
        <div className="space-y-3">
          {needsApproval && canTransfer && (
            <Button
              onClick={handleApprove}
              disabled={!canTransfer || isApproving || maxAmount === 0}
              className="w-full bg-slate-600 hover:bg-slate-700 text-white"
            >
              {isApproving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              {isApproving ? "Approving..." : "Approve YieldCoin"}
            </Button>
          )}

          <Button
            onClick={handleTransfer}
            disabled={!canTransfer || needsApproval || isTransferring || maxAmount === 0}
            className="w-full bg-emerald-600 hover:bg-emerald-700 text-white"
          >
            {isTransferring && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            {isTransferring ? "Bridging..." : "Bridge YieldCoin"}
          </Button>
        </div>

        {/* Info */}
        <div className="text-xs text-slate-500 space-y-1">
          <p>• Cross-chain transfers are powered by Chainlink CCIP</p>
          <p>• Your YieldCoin continues earning yield during transfer</p>
          <p>• Transfers typically complete in 10-20 minutes</p>
          <p>• CCIP fees are paid in the native token of the source chain</p>
        </div>
      </CardContent>
    </Card>
  )
}
