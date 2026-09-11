import * as fs from 'fs';
import * as path from 'path';
import 'dotenv/config';

export interface NetworkConfig {
  name: string;
  chainId: number;
  rpcUrl: string;
  privateKey: string;
  loanAddress: string;
  beaconAddress: string;
  explorerUrl: string;
}

const DEFAULT_CONFIGS: Record<string, NetworkConfig> = {
  mainnet: {
    name: 'mainnet',
    chainId: 1,
    rpcUrl: process.env.MAINNET_RPC_URL || 'https://mainnet.infura.io/v3/' + (process.env.INFURA_API_KEY || ''),
    privateKey: process.env.PRIVATE_KEY || '',
    loanAddress: process.env.MAINNET_LOAN_ADDRESS || '',
    beaconAddress: process.env.MAINNET_BEACON_ADDRESS || '',
    explorerUrl: 'https://etherscan.io',
  },
  sepolia: {
    name: 'sepolia',
    chainId: 11155111,
    rpcUrl: process.env.SEPOLIA_RPC_URL || 'https://sepolia.infura.io/v3/' + (process.env.INFURA_API_KEY || ''),
    privateKey: process.env.PRIVATE_KEY || '',
    loanAddress: process.env.SEPOLIA_LOAN_ADDRESS || '',
    beaconAddress: process.env.SEPOLIA_BEACON_ADDRESS || '',
    explorerUrl: 'https://sepolia.etherscan.io',
  },
  holesky: {
    name: 'holesky',
    chainId: 17000,
    rpcUrl: process.env.HOLESKY_RPC_URL || 'https://holesky.infura.io/v3/' + (process.env.INFURA_API_KEY || ''),
    privateKey: process.env.PRIVATE_KEY || '',
    loanAddress: process.env.HOLESKY_LOAN_ADDRESS || '',
    beaconAddress: process.env.HOLESKY_BEACON_ADDRESS || '',
    explorerUrl: 'https://holesky.etherscan.io',
  },
  arbitrum: {
    name: 'arbitrum',
    chainId: 42161,
    rpcUrl: process.env.ARBITRUM_RPC_URL || 'https://arb-mainnet.g.alchemy.com/v2/' + (process.env.ALCHEMY_API_KEY || ''),
    privateKey: process.env.PRIVATE_KEY || '',
    loanAddress: process.env.ARBITRUM_LOAN_ADDRESS || '',
    beaconAddress: process.env.ARBITRUM_BEACON_ADDRESS || '',
    explorerUrl: 'https://arbiscan.io',
  },
  optimism: {
    name: 'optimism',
    chainId: 10,
    rpcUrl: process.env.OPTIMISM_RPC_URL || 'https://opt-mainnet.g.alchemy.com/v2/' + (process.env.ALCHEMY_API_KEY || ''),
    privateKey: process.env.PRIVATE_KEY || '',
    loanAddress: process.env.OPTIMISM_LOAN_ADDRESS || '',
    beaconAddress: process.env.OPTIMISM_BEACON_ADDRESS || '',
    explorerUrl: 'https://optimistic.etherscan.io',
  },
  polygon: {
    name: 'polygon',
    chainId: 137,
    rpcUrl: process.env.POLYGON_RPC_URL || 'https://polygon-mainnet.g.alchemy.com/v2/' + (process.env.ALCHEMY_API_KEY || ''),
    privateKey: process.env.PRIVATE_KEY || '',
    loanAddress: process.env.POLYGON_LOAN_ADDRESS || '',
    beaconAddress: process.env.POLYGON_BEACON_ADDRESS || '',
    explorerUrl: 'https://polygonscan.com',
  },
};

export function loadConfig(network?: string): NetworkConfig {
  const configPath = path.join(process.env.HOME || '~', '.zer-evm-config.json');
  let fileConfig: Record<string, string> = {};
  
  if (fs.existsSync(configPath)) {
    fileConfig = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
  }

  const networkName = network || fileConfig.network || process.env.ZER_NETWORK || 'sepolia';
  const config = DEFAULT_CONFIGS[networkName] || DEFAULT_CONFIGS.sepolia;

  // Override with environment variables and file config
  return {
    ...config,
    rpcUrl: fileConfig.rpcUrl || process.env.RPC_URL || config.rpcUrl,
    privateKey: fileConfig.privateKey || process.env.PRIVATE_KEY || config.privateKey,
    loanAddress: fileConfig.loanAddress || process.env.LOAN_ADDRESS || config.loanAddress,
    beaconAddress: fileConfig.beaconAddress || process.env.BEACON_ADDRESS || config.beaconAddress,
  };
}

export function getSupportedNetworks(): string[] {
  return Object.keys(DEFAULT_CONFIGS);
}
