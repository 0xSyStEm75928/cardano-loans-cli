/// ZER EVM CLI - Loan Calculator
/// Handles interest, penalties, and balance calculations

export interface LoanParams {
  principal: bigint;
  interestRateBps: number;  // Basis points (100 = 1%)
  loanTermSeconds: number;
  epochDurationSeconds: number;
  minPayment: bigint;
  penaltyType: 'none' | 'fixed' | 'percent';
  penaltyValue: bigint;
}

export interface PaymentSchedule {
  epoch: number;
  dueDate: number;
  minPayment: bigint;
  interestAccrued: bigint;
  totalDue: bigint;
}

export interface LoanBalance {
  outstanding: bigint;
  totalInterest: bigint;
  totalPaid: bigint;
  nextPaymentDue: number;
  isDefaulted: boolean;
}

/// Calculate simple interest
export function calculateSimpleInterest(
  principal: bigint,
  rateBps: number,
  durationSeconds: number
): bigint {
  // principal * rate * duration / (365.25 days * 24h * 3600s * 10000 bps)
  const SECONDS_PER_YEAR = BigInt(365.25 * 24 * 60 * 60);
  const BPS_DENOMINATOR = BigInt(10000);
  
  return (principal * BigInt(rateBps) * BigInt(durationSeconds)) / 
         (SECONDS_PER_YEAR * BPS_DENOMINATOR);
}

/// Calculate compound interest
export function calculateCompoundInterest(
  principal: bigint,
  rateBps: number,
  periods: number
): bigint {
  // Simplified: principal * (1 + rate)^periods
  // Using integer math with scaling
  const SCALE = BigInt(1e18);
  const rateScaled = (BigInt(rateBps) * SCALE) / BigInt(10000);
  const onePlusRate = SCALE + rateScaled;
  
  let result = principal * SCALE;
  for (let i = 0; i < periods; i++) {
    result = (result * onePlusRate) / SCALE;
  }
  
  return result / SCALE;
}

/// Calculate payment schedule
export function calculatePaymentSchedule(params: LoanParams): PaymentSchedule[] {
  const schedule: PaymentSchedule[] = [];
  const startTime = Math.floor(Date.now() / 1000);
  const epochs = Math.ceil(params.loanTermSeconds / params.epochDurationSeconds);
  
  let accumulatedInterest = BigInt(0);
  
  for (let i = 0; i < epochs; i++) {
    const dueDate = startTime + (i + 1) * params.epochDurationSeconds;
    
    // Calculate interest for this epoch
    const epochInterest = calculateSimpleInterest(
      params.principal,
      params.interestRateBps,
      params.epochDurationSeconds
    );
    
    accumulatedInterest += epochInterest;
    
    // Calculate penalty if applicable
    let penalty = BigInt(0);
    if (params.penaltyType === 'fixed') {
      penalty = params.penaltyValue;
    } else if (params.penaltyType === 'percent') {
      penalty = (params.minPayment * params.penaltyValue) / BigInt(10000);
    }
    
    const totalDue = params.minPayment + epochInterest + penalty;
    
    schedule.push({
      epoch: i + 1,
      dueDate,
      minPayment: params.minPayment,
      interestAccrued: epochInterest,
      totalDue,
    });
  }
  
  return schedule;
}

/// Calculate current loan balance
export function calculateLoanBalance(
  params: LoanParams,
  payments: bigint[],
  currentTime: number
): LoanBalance {
  const startTime = Math.floor(Date.now() / 1000) - params.loanTermSeconds;
  const elapsed = currentTime - startTime;
  const epochsPassed = Math.floor(elapsed / params.epochDurationSeconds);
  
  // Calculate total interest accrued
  const totalInterest = calculateSimpleInterest(
    params.principal,
    params.interestRateBps,
    elapsed
  );
  
  // Calculate total paid
  const totalPaid = payments.reduce((sum, p) => sum + p, BigInt(0));
  
  // Calculate outstanding
  const outstanding = params.principal + totalInterest - totalPaid;
  
  // Check if defaulted
  const lastPaymentTime = payments.length > 0 ? currentTime : startTime;
  const missedEpochs = epochsPassed - payments.length;
  const isDefaulted = missedEpochs > 3; // Default after 3 missed payments
  
  return {
    outstanding: outstanding > BigInt(0) ? outstanding : BigInt(0),
    totalInterest,
    totalPaid,
    nextPaymentDue: startTime + (epochsPassed + 1) * params.epochDurationSeconds,
    isDefaulted,
  };
}

/// Calculate collateral requirements
export function calculateCollateralRequired(
  loanAmount: bigint,
  collateralRatio: number, // percentage (e.g., 150 = 150%)
  assetPrice: bigint,      // price in smallest unit
  collateralPrice: bigint  // price in smallest unit
): bigint {
  // collateral = (loanAmount * collateralRatio * assetPrice) / (collateralPrice * 100)
  const ratio = BigInt(collateralRatio);
  const hundred = BigInt(100);
  
  return (loanAmount * ratio * assetPrice) / (collateralPrice * hundred);
}

/// Format amount for display
export function formatAmount(amount: bigint, decimals: number): string {
  const divisor = BigInt(10 ** decimals);
  const whole = amount / divisor;
  const fraction = amount % divisor;
  
  if (fraction === BigInt(0)) {
    return whole.toString();
  }
  
  const fractionStr = fraction.toString().padStart(decimals, '0').replace(/0+$/, '');
  return `${whole}.${fractionStr}`;
}

/// Parse amount from string
export function parseAmount(amount: string, decimals: number): bigint {
  const parts = amount.split('.');
  const whole = BigInt(parts[0] || '0');
  const fraction = parts[1] || '';
  
  const fractionBigInt = BigInt(fraction.padEnd(decimals, '0').slice(0, decimals));
  
  return whole * BigInt(10 ** decimals) + fractionBigInt;
}
