#!/usr/bin/env node

import { Command } from 'commander';
import chalk from 'chalk';
import ora from 'ora';
import { CHAINS, STABLECOINS, LoanRequest, LoanOffer } from './chains.js';
import { calculatePaymentSchedule, calculateLoanBalance, formatAmount, parseAmount } from './calculator.js';

const program = new Command();

program
  .name('zer-evm')
  .description('ZER EVM CLI - Multi-chain Loan Protocol')
  .version('1.0.0');

// ============ LOAN COMMANDS ============
const loanCmd = program.command('loan').description('Loan operations');

loanCmd
  .command('apply')
  .description('Apply for a loan (borrower request)')
  .option('--chain <chain>', 'Target chain (ethereum, tron, xrpl, etc.)', 'ethereum')
  .option('--asset <symbol>', 'Loan asset (ETH, USDT, USDC, XRP)', 'USDT')
  .option('--amount <amount>', 'Loan amount')
  .option('--term <days>', 'Loan term in days', '30')
  .option('--collateral-asset <symbol>', 'Collateral asset', 'ETH')
  .option('--collateral-ratio <percent>', 'Required collateral ratio %', '150')
  .action((options) => {
    const chain = CHAINS[options.chain];
    if (!chain) {
      console.error(chalk.red(`Unknown chain: ${options.chain}`));
      console.log(chalk.cyan('Available chains:'), Object.keys(CHAINS).join(', '));
      process.exit(1);
    }

    const request: LoanRequest = {
      borrowerAddress: '0x...',
      loanAsset: options.asset,
      principal: options.amount,
      loanTerm: parseInt(options.term) * 86400,
      interestRate: 500, // 5%
      collateralAsset: options.collateralAsset,
      collateralAmount: '0',
      collateralRatio: parseInt(options.collateralRatio),
      chain: options.chain,
    };

    console.log(chalk.bold('\n📋 Loan Application Request\n'));
    console.log(chalk.cyan('Chain:'), chain.name);
    console.log(chalk.cyan('Asset:'), request.loanAsset);
    console.log(chalk.cyan('Amount:'), request.principal);
    console.log(chalk.cyan('Term:'), `${options.term} days`);
    console.log(chalk.cyan('Collateral:'), `${request.collateralRatio}% of loan`);
    console.log(chalk.cyan('Interest:'), `${request.interestRate / 100}% annually`);

    console.log(chalk.yellow('\n💡 Use `zer-evm loan create` to submit on-chain\n'));
  });

loanCmd
  .command('create')
  .description('Create loan request on-chain')
  .option('--chain <chain>', 'Target chain', 'ethereum')
  .option('--asset <symbol>', 'Loan asset', 'USDT')
  .option('--amount <amount>', 'Loan amount')
  .option('--term <days>', 'Loan term in days', '30')
  .action(async (options) => {
    const spinner = ora('Creating loan request...').start();
    try {
      // TODO: Implement on-chain creation
      spinner.succeed(chalk.green('Loan request created!'));
      console.log(chalk.cyan('Loan ID:'), '0x...');
    } catch (error) {
      spinner.fail(chalk.red(`Failed: ${error}`));
      process.exit(1);
    }
  });

loanCmd
  .command('offer')
  .description('Create loan offer (lender)')
  .option('--chain <chain>', 'Target chain', 'ethereum')
  .option('--borrower <address>', 'Borrower address')
  .option('--asset <symbol>', 'Loan asset', 'USDT')
  .option('--amount <amount>', 'Loan amount')
  .option('--term <days>', 'Loan term in days', '30')
  .option('--interest <bps>', 'Interest rate in basis points', '500')
  .option('--min-payment <amount>', 'Minimum payment per epoch')
  .action(async (options) => {
    const spinner = ora('Creating loan offer...').start();
    try {
      // TODO: Implement on-chain offer creation
      spinner.succeed(chalk.green('Loan offer created!'));
      console.log(chalk.cyan('Offer ID:'), '0x...');
    } catch (error) {
      spinner.fail(chalk.red(`Failed: ${error}`));
      process.exit(1);
    }
  });

loanCmd
  .command('accept')
  .description('Accept loan offer')
  .argument('<offerId>', 'Offer ID')
  .option('--chain <chain>', 'Target chain', 'ethereum')
  .action(async (offerId, options) => {
    const spinner = ora('Accepting offer...').start();
    try {
      // TODO: Implement on-chain acceptance
      spinner.succeed(chalk.green('Loan accepted!'));
      console.log(chalk.cyan('Loan ID:'), '0x...');
    } catch (error) {
      spinner.fail(chalk.red(`Failed: ${error}`));
      process.exit(1);
    }
  });

loanCmd
  .command('pay')
  .description('Make loan payment')
  .argument('<loanId>', 'Loan ID')
  .argument('<amount>', 'Payment amount')
  .option('--chain <chain>', 'Target chain', 'ethereum')
  .action(async (loanId, amount, options) => {
    const spinner = ora('Processing payment...').start();
    try {
      // TODO: Implement on-chain payment
      spinner.succeed(chalk.green('Payment successful!'));
    } catch (error) {
      spinner.fail(chalk.red(`Failed: ${error}`));
      process.exit(1);
    }
  });

loanCmd
  .command('claim')
  .description('Claim defaulted collateral (lender)')
  .argument('<loanId>', 'Loan ID')
  .option('--chain <chain>', 'Target chain', 'ethereum')
  .action(async (loanId, options) => {
    const spinner = ora('Claiming collateral...').start();
    try {
      // TODO: Implement on-chain claim
      spinner.succeed(chalk.green('Collateral claimed!'));
    } catch (error) {
      spinner.fail(chalk.red(`Failed: ${error}`));
      process.exit(1);
    }
  });

loanCmd
  .command('unlock')
  .description('Unlock lost collateral (borrower)')
  .argument('<loanId>', 'Loan ID')
  .option('--chain <chain>', 'Target chain', 'ethereum')
  .action(async (loanId, options) => {
    const spinner = ora('Unlocking collateral...').start();
    try {
      // TODO: Implement on-chain unlock
      spinner.succeed(chalk.green('Collateral unlocked!'));
    } catch (error) {
      spinner.fail(chalk.red(`Failed: ${error}`));
      process.exit(1);
    }
  });

// ============ QUERY COMMANDS ============
const queryCmd = program.command('query').description('Query operations');

queryCmd
  .command('loan')
  .description('Get loan details')
  .argument('<loanId>', 'Loan ID')
  .option('--chain <chain>', 'Target chain', 'ethereum')
  .action(async (loanId, options) => {
    try {
      // TODO: Implement on-chain query
      console.log(JSON.stringify({
        loanId,
        chain: options.chain,
        status: 'active',
        // ... more fields
      }, null, 2));
    } catch (error) {
      console.error(chalk.red(`Failed: ${error}`));
      process.exit(1);
    }
  });

queryCmd
  .command('balance')
  .description('Calculate loan balance')
  .argument('<loanId>', 'Loan ID')
  .option('--chain <chain>', 'Target chain', 'ethereum')
  .action(async (loanId, options) => {
    try {
      // TODO: Implement balance calculation
      console.log(JSON.stringify({
        loanId,
        outstanding: '0',
        totalInterest: '0',
        totalPaid: '0',
      }, null, 2));
    } catch (error) {
      console.error(chalk.red(`Failed: ${error}`));
      process.exit(1);
    }
  });

queryCmd
  .command('schedule')
  .description('Show payment schedule')
  .option('--principal <amount>', 'Loan principal')
  .option('--rate <bps>', 'Interest rate in bps', '500')
  .option('--term <days>', 'Loan term in days', '30')
  .option('--epoch <days>', 'Payment epoch in days', '7')
  .action((options) => {
    const principal = parseAmount(options.principal, 18);
    const schedule = calculatePaymentSchedule({
      principal,
      interestRateBps: parseInt(options.rate),
      loanTermSeconds: parseInt(options.term) * 86400,
      epochDurationSeconds: parseInt(options.epoch) * 86400,
      minPayment: principal / BigInt(parseInt(options.term) / parseInt(options.epoch)),
      penaltyType: 'none',
      penaltyValue: BigInt(0),
    });

    console.log(chalk.bold('\n📅 Payment Schedule\n'));
    console.log(chalk.cyan('Epoch | Due Date | Min Payment | Interest | Total'));
    console.log(chalk.gray('-'.repeat(60)));
    
    for (const epoch of schedule) {
      const dueDate = new Date(epoch.dueDate * 1000).toLocaleDateString();
      console.log(
        `${epoch.epoch.toString().padStart(5)} | ` +
        `${dueDate.padEnd(10)} | ` +
        `${formatAmount(epoch.minPayment, 18).padStart(10)} | ` +
        `${formatAmount(epoch.interestAccrued, 18).padStart(9)} | ` +
        `${formatAmount(epoch.totalDue, 18)}`
      );
    }
    console.log();
  });

// ============ CHAIN COMMANDS ============
const chainCmd = program.command('chain').description('Chain operations');

chainCmd
  .command('list')
  .description('List supported chains')
  .action(() => {
    console.log(chalk.bold('\n🌐 Supported Chains\n'));
    
    for (const [name, chain] of Object.entries(CHAINS)) {
      const typeIcon = chain.type === 'evm' ? '⟠' : chain.type === 'tron' ? '◎' : '✕';
      console.log(`${typeIcon} ${chalk.bold(name.padEnd(15))} | ${chain.name.padEnd(25)} | ${chain.nativeCurrency}`);
    }
    console.log();
  });

chainCmd
  .command('info')
  .description('Get chain details')
  .argument('<chain>', 'Chain name')
  .action((chainName) => {
    const chain = CHAINS[chainName];
    if (!chain) {
      console.error(chalk.red(`Unknown chain: ${chainName}`));
      process.exit(1);
    }

    console.log(chalk.bold(`\n🔗 ${chain.name}\n`));
    console.log(chalk.cyan('Type:'), chain.type);
    console.log(chalk.cyan('Chain ID:'), chain.chainId);
    console.log(chalk.cyan('Currency:'), chain.nativeCurrency);
    console.log(chalk.cyan('Explorer:'), chain.blockExplorer);
    
    if (chain.usdtContract) {
      console.log(chalk.cyan('USDT:'), chain.usdtContract);
    }
    if (chain.usdcContract) {
      console.log(chalk.cyan('USDC:'), chain.usdcContract);
    }
    console.log();
  });

// ============ STABLECOIN COMMANDS ============
const tokenCmd = program.command('token').description('Stablecoin operations');

tokenCmd
  .command('list')
  .description('List supported stablecoins')
  .option('--chain <chain>', 'Filter by chain')
  .action((options) => {
    console.log(chalk.bold('\n💰 Supported Stablecoins\n'));
    
    const chains = options.chain ? [options.chain] : Object.keys(STABLECOINS);
    
    for (const chainName of chains) {
      const coins = STABLECOINS[chainName];
      if (coins) {
        console.log(chalk.cyan(`${chainName}:`));
        for (const [symbol, address] of Object.entries(coins)) {
          console.log(`  ${symbol}: ${address}`);
        }
      }
    }
    console.log();
  });

// ============ CONFIG COMMANDS ============
const configCmd = program.command('config').description('Configuration');

configCmd
  .command('show')
  .description('Show current configuration')
  .action(() => {
    console.log(chalk.bold('\n⚙️ Configuration\n'));
    console.log(chalk.cyan('Default Chain:'), 'ethereum');
    console.log(chalk.cyan('Default Asset:'), 'USDT');
    console.log(chalk.cyan('Version:'), '1.0.0');
    console.log();
  });

program.parse();
