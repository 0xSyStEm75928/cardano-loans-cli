import { expect } from "chai";
import { ethers } from "hardhat";
import { Loan, BeaconNFT } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("Loan", function () {
  let loan: Loan;
  let beaconNFT: BeaconNFT;
  let owner: SignerWithAddress;
  let borrower: SignerWithAddress;
  let lender: SignerWithAddress;

  beforeEach(async function () {
    [owner, borrower, lender] = await ethers.getSigners();

    const BeaconNFT = await ethers.getContractFactory("BeaconNFT");
    beaconNFT = await BeaconNFT.deploy();
    await beaconNFT.waitForDeployment();

    const Loan = await ethers.getContractFactory("Loan");
    loan = await Loan.deploy(await beaconNFT.getAddress());
    await loan.waitForDeployment();
  });

  describe("Ask", function () {
    it("Should create an ask", async function () {
      const loanAsset = ethers.ZeroAddress;
      const principal = ethers.parseEther("1");
      const term = 2592000; // 30 days

      await expect(loan.connect(borrower).createAsk(loanAsset, principal, term, []))
        .to.emit(loan, "AskCreated")
        .withArgs(0, borrower.address, loanAsset, principal);

      const ask = await loan.asks(0);
      expect(ask.borrower).to.equal(borrower.address);
      expect(ask.principal).to.equal(principal);
      expect(ask.active).to.be.true;
    });

    it("Should close an ask", async function () {
      await loan.connect(borrower).createAsk(ethers.ZeroAddress, ethers.parseEther("1"), 2592000, []);
      
      await expect(loan.connect(borrower).closeOrUpdateAsk(0))
        .to.emit(loan, "AskClosed")
        .withArgs(0);

      const ask = await loan.asks(0);
      expect(ask.active).to.be.false;
    });
  });

  describe("Offer", function () {
    it("Should create an offer", async function () {
      const loanAsset = ethers.ZeroAddress;
      const principal = ethers.parseEther("1");

      await expect(loan.connect(lender).createOffer(
        borrower.address,
        loanAsset,
        principal,
        604800, // epoch
        2592000, // term
        5, // interest num
        100, // interest den
        false,
        ethers.parseEther("0.1"),
        0,
        0,
        0,
        [],
        [],
        false,
        604800,
        0
      )).to.emit(loan, "OfferCreated");

      const offer = await loan.offers(0);
      expect(offer.lender).to.equal(lender.address);
      expect(offer.principal).to.equal(principal);
      expect(offer.active).to.be.true;
    });
  });

  describe("Loan Lifecycle", function () {
    it("Should accept offer and create loan", async function () {
      // Create offer
      await loan.connect(lender).createOffer(
        borrower.address,
        ethers.ZeroAddress,
        ethers.parseEther("1"),
        604800,
        2592000,
        5,
        100,
        false,
        ethers.parseEther("0.1"),
        0,
        0,
        0,
        [],
        [],
        false,
        604800,
        0
      );

      // Accept offer
      await expect(loan.connect(borrower).acceptOffer(0))
        .to.emit(loan, "LoanAccepted");

      const activeLoan = await loan.activeLoans(0);
      expect(activeLoan.borrower).to.equal(borrower.address);
      expect(activeLoan.lender).to.equal(lender.address);
      expect(activeLoan.active).to.be.true;
    });
  });
});
