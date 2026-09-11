import { ethers } from 'ethers';
import * as fs from 'fs';
import * as path from 'path';
import { loadConfig } from './config';

// Load compiled contract ABIs from Hardhat artifacts at runtime
function loadArtifact(contractName: string): { abi: any } {
  const artifactPath = path.join(
    __dirname,
    '..',
    'artifacts',
    'contracts',
    `${contractName}.sol`,
    `${contractName}.json`
  );
  return JSON.parse(fs.readFileSync(artifactPath, 'utf-8'));
}

export interface Ask {
  borrower: string;
  loanAsset: string;
  principal: bigint;
  loanTerm: bigint;
  collateral: string[];
  active: boolean;
  createdAt: bigint;
}

export interface Offer {
  lender: string;
  lenderAddress: string;
  loanAsset: string;
  principal: bigint;
  epochDuration: bigint;
  loanTerm: bigint;
  loanInterestNum: bigint;
  loanInterestDen: bigint;
  compoundingInterest: boolean;
  minPayment: bigint;
  penaltyType: number;
  penaltyValue: bigint;
  maxConsecutiveMisses: bigint;
  collateralAssets: string[];
  collateralRates: bigint[];
  collateralIsSwappable: boolean;
  claimPeriod: bigint;
  offerExpiration: bigint;
  active: boolean;
  createdAt: bigint;
}

export interface ActiveLoan {
  loanId: bigint;
  borrower: string;
  lender: string;
  lenderAddress: string;
  loanAsset: string;
  principal: bigint;
  epochDuration: bigint;
  lastEpochBoundary: bigint;
  loanTerm: bigint;
  loanInterestNum: bigint;
  loanInterestDen: bigint;
  compoundingInterest: boolean;
  minPayment: bigint;
  penaltyType: number;
  penaltyValue: bigint;
  maxConsecutiveMisses: bigint;
  collateralAssets: string[];
  collateralRates: bigint[];
  collateralIsSwappable: boolean;
  claimExpiration: bigint;
  loanExpiration: bigint;
  loanOutstandingNum: bigint;
  loanOutstandingDen: bigint;
  totalEpochPayments: bigint;
  currentConsecutiveMisses: bigint;
  active: boolean;
  createdAt: bigint;
}

export interface CreateOfferParams {
  borrower: string;
  loanAsset: string;
  principal: bigint;
  epochDuration: bigint;
  loanTerm: bigint;
  loanInterestNum: bigint;
  loanInterestDen: bigint;
  compoundingInterest: boolean;
  minPayment: bigint;
  penaltyType: number;
  penaltyValue: bigint;
  maxConsecutiveMisses: bigint;
  claimPeriod: bigint;
}

export class LoanClient {
  private provider: ethers.Provider;
  private signer: ethers.Signer;
  private loanContract: ethers.Contract;
  private beaconContract: ethers.Contract;

  constructor(provider: ethers.Provider, signer: ethers.Signer, config: any) {
    this.provider = provider;
    this.signer = signer;
    this.loanContract = new ethers.Contract(config.loanAddress, loadArtifact('Loan').abi, signer);
    this.beaconContract = new ethers.Contract(config.beaconAddress, loadArtifact('BeaconNFT').abi, signer);
  }

  static async fromEnv(): Promise<LoanClient> {
    const config = loadConfig();
    const provider = new ethers.JsonRpcProvider(config.rpcUrl);
    const wallet = new ethers.Wallet(config.privateKey, provider);
    return new LoanClient(provider, wallet, config);
  }

  async createAsk(
    loanAsset: string,
    principal: bigint,
    loanTerm: bigint,
    collateral: string[]
  ): Promise<bigint> {
    const tx = await this.loanContract.createAsk(loanAsset, principal, loanTerm, collateral);
    const receipt = await tx.wait();
    const event = receipt.logs.find((log: any) => log.fragment?.name === 'AskCreated');
    return event?.args?.[0] ?? 0n;
  }

  async createOffer(params: CreateOfferParams): Promise<bigint> {
    const tx = await this.loanContract.createOffer(
      params.borrower,
      params.loanAsset,
      params.principal,
      params.epochDuration,
      params.loanTerm,
      params.loanInterestNum,
      params.loanInterestDen,
      params.compoundingInterest,
      params.minPayment,
      params.penaltyType,
      params.penaltyValue,
      params.maxConsecutiveMisses,
      [], // collateralAssets
      [], // collateralRates
      false, // collateralIsSwappable
      params.claimPeriod,
      0 // offerExpiration
    );
    const receipt = await tx.wait();
    const event = receipt.logs.find((log: any) => log.fragment?.name === 'OfferCreated');
    return event?.args?.[0] ?? 0n;
  }

  async acceptOffer(offerId: bigint): Promise<bigint> {
    const tx = await this.loanContract.acceptOffer(offerId);
    const receipt = await tx.wait();
    const event = receipt.logs.find((log: any) => log.fragment?.name === 'LoanAccepted');
    return event?.args?.[0] ?? 0n;
  }

  async makePayment(loanId: bigint, amount: bigint): Promise<void> {
    const tx = await this.loanContract.makePayment(loanId, amount);
    await tx.wait();
  }

  async claimDefaultedCollateral(loanId: bigint): Promise<void> {
    const tx = await this.loanContract.claimDefaultedCollateral(loanId);
    await tx.wait();
  }

  async unlockLostCollateral(loanId: bigint): Promise<void> {
    const tx = await this.loanContract.unlockLostCollateral(loanId);
    await tx.wait();
  }

  async updateLenderAddress(loanId: bigint, newAddress: string): Promise<void> {
    const tx = await this.loanContract.updateLenderAddress(loanId, newAddress);
    await tx.wait();
  }

  async getActiveLoan(loanId: bigint): Promise<ActiveLoan> {
    const loan = await this.loanContract.activeLoans(loanId);
    return {
      loanId: loan.loanId,
      borrower: loan.borrower,
      lender: loan.lender,
      lenderAddress: loan.lenderAddress,
      loanAsset: loan.loanAsset,
      principal: loan.principal,
      epochDuration: loan.epochDuration,
      lastEpochBoundary: loan.lastEpochBoundary,
      loanTerm: loan.loanTerm,
      loanInterestNum: loan.loanInterestNum,
      loanInterestDen: loan.loanInterestDen,
      compoundingInterest: loan.compoundingInterest,
      minPayment: loan.minPayment,
      penaltyType: loan.penaltyType,
      penaltyValue: loan.penaltyValue,
      maxConsecutiveMisses: loan.maxConsecutiveMisses,
      collateralAssets: loan.collateralAssets,
      collateralRates: loan.collateralRates,
      collateralIsSwappable: loan.collateralIsSwappable,
      claimExpiration: loan.claimExpiration,
      loanExpiration: loan.loanExpiration,
      loanOutstandingNum: loan.loanOutstandingNum,
      loanOutstandingDen: loan.loanOutstandingDen,
      totalEpochPayments: loan.totalEpochPayments,
      currentConsecutiveMisses: loan.currentConsecutiveMisses,
      active: loan.active,
      createdAt: loan.createdAt,
    };
  }

  async getAsk(askId: bigint): Promise<Ask> {
    const ask = await this.loanContract.asks(askId);
    return {
      borrower: ask.borrower,
      loanAsset: ask.loanAsset,
      principal: ask.principal,
      loanTerm: ask.loanTerm,
      collateral: ask.collateral,
      active: ask.active,
      createdAt: ask.createdAt,
    };
  }

  async getOffer(offerId: bigint): Promise<Offer> {
    const offer = await this.loanContract.offers(offerId);
    return {
      lender: offer.lender,
      lenderAddress: offer.lenderAddress,
      loanAsset: offer.loanAsset,
      principal: offer.principal,
      epochDuration: offer.epochDuration,
      loanTerm: offer.loanTerm,
      loanInterestNum: offer.loanInterestNum,
      loanInterestDen: offer.loanInterestDen,
      compoundingInterest: offer.compoundingInterest,
      minPayment: offer.minPayment,
      penaltyType: offer.penaltyType,
      penaltyValue: offer.penaltyValue,
      maxConsecutiveMisses: offer.maxConsecutiveMisses,
      collateralAssets: offer.collateralAssets,
      collateralRates: offer.collateralRates,
      collateralIsSwappable: offer.collateralIsSwappable,
      claimPeriod: offer.claimPeriod,
      offerExpiration: offer.offerExpiration,
      active: offer.active,
      createdAt: offer.createdAt,
    };
  }

  async calculateBalance(loanId: bigint): Promise<{ balanceNum: bigint; balanceDen: bigint }> {
    const loan = await this.getActiveLoan(loanId);
    return {
      balanceNum: loan.loanOutstandingNum,
      balanceDen: loan.loanOutstandingDen,
    };
  }

  async getTokensByOwner(owner: string): Promise<bigint[]> {
    const balance = await this.beaconContract.balanceOf(owner);
    const tokens: bigint[] = [];
    for (let i = 0; i < Number(balance); i++) {
      const tokenId = await this.beaconContract.tokenOfOwnerByIndex(owner, i);
      tokens.push(tokenId);
    }
    return tokens;
  }

  async getLoanCount(): Promise<bigint> {
    return await this.loanContract.getLoanCount();
  }

  async getAskCount(): Promise<bigint> {
    return await this.loanContract.getAskCount();
  }

  async getOfferCount(): Promise<bigint> {
    return await this.loanContract.getOfferCount();
  }
}
