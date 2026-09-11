/// Multi-chain support for ZER EVM CLI
/// Supports: Ethereum, Tron, XRP Ledger, BSC, Polygon, Arbitrum, Optimism

export interface ChainConfig {
  name: string;
  chainId: number;
  type: 'evm' | 'tron' | 'xrpl';
  nativeCurrency: string;
  rpcUrls: string[];
  blockExplorer: string;
  loanContract?: string;
  beaconContract?: string;
  usdtContract?: string;
  usdcContract?: string;
}

export const CHAINS: Record<string, ChainConfig> = {
  // EVM Chains
  ethereum: {
    name: 'Ethereum Mainnet',
    chainId: 1,
    type: 'evm',
    nativeCurrency: 'ETH',
    rpcUrls: [
      'https://mainnet.infura.io/v3/',
      'https://eth.llamarpc.com',
      'https://rpc.ankr.com/eth'
    ],
    blockExplorer: 'https://etherscan.io',
    usdtContract: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
    usdcContract: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'
  },
  sepolia: {
    name: 'Ethereum Sepolia',
    chainId: 11155111,
    type: 'evm',
    nativeCurrency: 'ETH',
    rpcUrls: ['https://sepolia.infura.io/v3/'],
    blockExplorer: 'https://sepolia.etherscan.io',
    usdtContract: '0x71695C66E238F8f0b918A2cB1995E3eB287e832D',
    usdcContract: '0x1c7D4B196Cb0C7B01d06436aD7a1A9C3a5C51812'
  },
  holesky: {
    name: 'Ethereum Holesky',
    chainId: 17000,
    type: 'evm',
    nativeCurrency: 'ETH',
    rpcUrls: ['https://holesky.infura.io/v3/'],
    blockExplorer: 'https://holesky.etherscan.io'
  },
  bsc: {
    name: 'BNB Smart Chain',
    chainId: 56,
    type: 'evm',
    nativeCurrency: 'BNB',
    rpcUrls: [
      'https://bsc-dataseed.binance.org',
      'https://rpc.ankr.com/bsc'
    ],
    blockExplorer: 'https://bscscan.com',
    usdtContract: '0x55d398326f99059fF775485246999027B3197955',
    usdcContract: '0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d'
  },
  polygon: {
    name: 'Polygon PoS',
    chainId: 137,
    type: 'evm',
    nativeCurrency: 'MATIC',
    rpcUrls: [
      'https://polygon-rpc.com',
      'https://rpc.ankr.com/polygon'
    ],
    blockExplorer: 'https://polygonscan.com',
    usdtContract: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
    usdcContract: '0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359'
  },
  arbitrum: {
    name: 'Arbitrum One',
    chainId: 42161,
    type: 'evm',
    nativeCurrency: 'ETH',
    rpcUrls: [
      'https://arb1.arbitrum.io/rpc',
      'https://rpc.ankr.com/arbitrum'
    ],
    blockExplorer: 'https://arbiscan.io',
    usdtContract: '0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9',
    usdcContract: '0xaf88d065e77c8cC2239327C5EDb3A432268e5831'
  },
  optimism: {
    name: 'OP Mainnet',
    chainId: 10,
    type: 'evm',
    nativeCurrency: 'ETH',
    rpcUrls: [
      'https://mainnet.optimism.io',
      'https://rpc.ankr.com/optimism'
    ],
    blockExplorer: 'https://optimistic.etherscan.io',
    usdtContract: '0x94b008aA00579c1307B0EF2c499aD98a8ce58e58',
    usdcContract: '0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85'
  },

  // Tron (using TronWeb)
  tron: {
    name: 'TRON Mainnet',
    chainId: 1,
    type: 'tron',
    nativeCurrency: 'TRX',
    rpcUrls: ['https://api.trongrid.io'],
    blockExplorer: 'https://tronscan.org',
    usdtContract: 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t'
  },
  tron_nile: {
    name: 'TRON Nile Testnet',
    chainId: 1,
    type: 'tron',
    nativeCurrency: 'TRX',
    rpcUrls: ['https://nile.trongrid.io'],
    blockExplorer: 'https://nile.tronscan.org',
    usdtContract: 'TXYZopYRdj2D9XRtbG411XZZ3kM5VkAeBf'
  },

  // XRP Ledger
  xrpl: {
    name: 'XRP Ledger Mainnet',
    chainId: 0,
    type: 'xrpl',
    nativeCurrency: 'XRP',
    rpcUrls: [
      'https://xrplcluster.com',
      'https://s1.ripple.com'
    ],
    blockExplorer: 'https://xrpscan.com'
  },
  xrpl_testnet: {
    name: 'XRP Ledger Testnet',
    chainId: 0,
    type: 'xrpl',
    nativeCurrency: 'XRP',
    rpcUrls: ['https://testnet.xrpl-labs.com'],
    blockExplorer: 'https://testnet.xrpscan.com'
  }
};

/// Loan request structure (universal across chains)
export interface LoanRequest {
  // Borrower info
  borrowerAddress: string;
  
  // Loan terms
  loanAsset: string;        // 'ETH', 'USDT', 'USDC', 'XRP', etc.
  principal: string;         // Amount in smallest unit (wei, drops, sun)
  loanTerm: number;          // Duration in seconds
  interestRate: number;      // Annual rate in basis points (100 = 1%)
  
  // Collateral
  collateralAsset: string;   // Collateral token
  collateralAmount: string;  // Collateral amount
  collateralRatio: number;   // Required ratio in % (e.g., 150 = 150%)
  
  // Optional
  maxConsecutiveMisses?: number;
  claimPeriod?: number;      // After expiration
  
  // Chain selection
  chain: string;             // 'ethereum', 'tron', 'xrpl', etc.
}

/// Loan offer structure
export interface LoanOffer {
  lenderAddress: string;
  borrowerAddress: string;
  loanAsset: string;
  principal: string;
  loanTerm: number;
  interestRate: number;
  minPayment: string;
  penaltyType: 'none' | 'fixed' | 'percent';
  penaltyValue: string;
  collateralAssets: string[];
  collateralRates: number[];
  claimPeriod: number;
  chain: string;
}

/// Active loan state
export interface ActiveLoan {
  loanId: string;
  borrower: string;
  lender: string;
  loanAsset: string;
  principal: string;
  outstandingBalance: string;
  loanTerm: number;
  startTime: number;
  endTime: number;
  lastPaymentTime: number;
  totalPayments: string;
  consecutiveMisses: number;
  status: 'active' | 'defaulted' | 'completed' | 'claimed';
  chain: string;
}

/// Transaction result
export interface TxResult {
  txHash: string;
  chain: string;
  blockNumber?: number;
  gasUsed?: string;
  status: 'pending' | 'success' | 'failed';
}

/// Supported stablecoins per chain
export const STABLECOINS: Record<string, Record<string, string>> = {
  ethereum: {
    USDT: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
    USDC: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
    DAI: '0x6B175474E89094C44Da98b954EedeAC495271d0F'
  },
  bsc: {
    USDT: '0x55d398326f99059fF775485246999027B3197955',
    USDC: '0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d',
    BUSD: '0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56'
  },
  polygon: {
    USDT: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
    USDC: '0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359'
  },
  arbitrum: {
    USDT: '0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9',
    USDC: '0xaf88d065e77c8cC2239327C5EDb3A432268e5831'
  },
  tron: {
    USDT: 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t'
  }
};

/// Get chain config by name
export function getChainConfig(chainName: string): ChainConfig | undefined {
  return CHAINS[chainName.toLowerCase()];
}

/// Get all EVM chains
export function getEVMChains(): ChainConfig[] {
  return Object.values(CHAINS).filter(c => c.type === 'evm');
}

/// Get all Tron chains
export function getTronChains(): ChainConfig[] {
  return Object.values(CHAINS).filter(c => c.type === 'tron');
}

/// Get all XRP Ledger chains
export function getXRPLChains(): ChainConfig[] {
  return Object.values(CHAINS).filter(c => c.type === 'xrpl');
}
