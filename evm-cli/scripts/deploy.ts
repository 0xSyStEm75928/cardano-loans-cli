import { ethers } from 'hardhat';
import * as fs from 'fs';
import * as path from 'path';

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log('Deploying contracts with account:', deployer.address);
  console.log('Account balance:', (await ethers.provider.getBalance(deployer.address)).toString());

  // Deploy BeaconNFT
  console.log('\nDeploying BeaconNFT...');
  const BeaconNFT = await ethers.getContractFactory('BeaconNFT');
  const beaconNFT = await BeaconNFT.deploy();
  await beaconNFT.waitForDeployment();
  const beaconAddress = await beaconNFT.getAddress();
  console.log('BeaconNFT deployed to:', beaconAddress);

  // Deploy Loan
  console.log('\nDeploying Loan...');
  const Loan = await ethers.getContractFactory('Loan');
  const loan = await Loan.deploy(beaconAddress);
  await loan.waitForDeployment();
  const loanAddress = await loan.getAddress();
  console.log('Loan deployed to:', loanAddress);

  // Save deployment info
  const deploymentInfo = {
    network: (await ethers.provider.getNetwork()).name,
    chainId: (await ethers.provider.getNetwork()).chainId.toString(),
    deployer: deployer.address,
    beaconAddress: beaconAddress,
    loanAddress: loanAddress,
    timestamp: new Date().toISOString(),
  };

  const deploymentsDir = path.join(__dirname, '../deployments');
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir, { recursive: true });
  }

  const deploymentFile = path.join(deploymentsDir, `${deploymentInfo.chainId}.json`);
  fs.writeFileSync(deploymentFile, JSON.stringify(deploymentInfo, null, 2));
  console.log('\nDeployment info saved to:', deploymentFile);

  // Verify on Etherscan (if not local network)
  if (deploymentInfo.chainId !== '31337') {
    console.log('\nWaiting for block confirmations...');
    await loan.deploymentTransaction()?.wait(5);

    console.log('Verifying contracts on Etherscan...');
    try {
      await run('verify:verify', {
        address: beaconAddress,
        constructorArguments: [],
      });
      console.log('BeaconNFT verified');
    } catch (error) {
      console.log('BeaconNFT verification failed:', error);
    }

    try {
      await run('verify:verify', {
        address: loanAddress,
        constructorArguments: [beaconAddress],
      });
      console.log('Loan verified');
    } catch (error) {
      console.log('Loan verification failed:', error);
    }
  }

  console.log('\n✅ Deployment complete!');
  console.log('\nAdd these to your .env file:');
  console.log(`LOAN_ADDRESS=${loanAddress}`);
  console.log(`BEACON_ADDRESS=${beaconAddress}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
