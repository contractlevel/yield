// Contract addresses - updated with deployed contracts
export const CONTRACTS = {
  // Parent contract on Ethereum Sepolia (changed from Base)
  PARENT_PEER: {
    address: "0xBE679979Eaec355d1030d6f117Ce5B4b5388318E", // ParentPeer on Eth Sepolia
    chainId: 11155111, // Ethereum Sepolia
  },
  // Child contracts
  CHILD_PEERS: {
    BASE_SEPOLIA: {
      address: "0x94563Bfe55D8Df522FE94e7D60D2D949ef21BF1c", // Child on Base Sepolia
      chainId: 84532,
    },
    AVALANCHE_FUJI: {
      address: "0xc19688E191dEB933B99cc78D94c227784c8062F9", // Child on Avalanche Fuji
      chainId: 43113,
    },
  },
  // YieldCoin token addresses per chain
  YIELDCOIN: {
    11155111: "0x37D13c62D2FDe4A400e2018f2fA0e3da6b15718D", // Eth Sepolia
    84532: "0x2DF8c615858B479cBC3Bfef3bBfE34842d7AaA90", // Base Sepolia
    43113: "0x2891C37D5104446d10dc29eA06c25C6f0cA233Ec", // Avalanche Fuji
  },
  // SharePool (CCIP pool) addresses per chain
  SHAREPOOL: {
    11155111: "0x9CF6491ace3FDD614FB8209ec98dcF98b1e70e4D", // Eth Sepolia
    84532: "0xEF13904800eFA60BB1ea5f70645Fc55609F00320", // Base Sepolia
    43113: "0x9bf12E915461A48bc61ddca5f295A0E20BBBa5D7", // Avalanche Fuji
  },
  // CCIP Router addresses per chain
  CCIP_ROUTER: {
    11155111: "0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59", // Eth Sepolia
    84532: "0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93", // Base Sepolia
    43113: "0xF694E193200268f9a4868e4Aa017A0118C9a8177", // Avalanche Fuji
  },
  // USDC addresses per chain (unchanged)
  USDC: {
    11155111: "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238", // Eth Sepolia
    84532: "0x036CbD53842c5426634e7929541eC2318f3dCF7e", // Base Sepolia
    43113: "0x5425890298aed601595a70AB815c96711a31Bc65", // Avalanche Fuji
  },
} as const

// CCIP Chain Selectors
export const CHAIN_SELECTORS = {
  11155111: "16015286601757825753", // ETH_SEPOLIA_CHAIN_SELECTOR
  84532: "10344971235874465080", // BASE_SEPOLIA_CHAIN_SELECTOR
  43113: "14767482510784806043", // AVALANCHE_FUJI_CHAIN_SELECTOR
} as const

// Protocol enum mapping
export const PROTOCOLS = {
  0: "Aave",
  1: "Compound",
} as const

export const SUPPORTED_CHAINS = [
  {
    id: 11155111,
    name: "Ethereum Sepolia",
    shortName: "Ethereum",
    rpcUrl: "https://sepolia.infura.io/v3/YOUR_INFURA_KEY",
    blockExplorer: "https://sepolia.etherscan.io",
    isParent: true, // Mark as parent chain
  },
  {
    id: 84532,
    name: "Base Sepolia",
    shortName: "Base",
    rpcUrl: "https://sepolia.base.org",
    blockExplorer: "https://sepolia.basescan.org",
    isParent: false,
  },
  {
    id: 43113,
    name: "Avalanche Fuji",
    shortName: "Avalanche",
    rpcUrl: "https://api.avax-test.network/ext/bc/C/rpc",
    blockExplorer: "https://testnet.snowtrace.io",
    isParent: false,
  },
] as const
