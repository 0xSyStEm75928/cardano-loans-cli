// SPDX-License-Identifier: JSSH-2026-0001
pragma solidity ^0.8.24;

import "./LoanStorage.sol";
import "./BeaconNFT.sol";
import "./LoanMath.sol";

/// @title Loan - Core loan logic for ZER EVM Protocol
/// @notice Implements Cardano Loans logic on EVM
contract Loan is LoanStorage {
    BeaconNFT public immutable beaconNFT;
    LoanMath public immutable loanMath;

    mapping(uint256 => Ask) public asks;
    mapping(uint256 => Offer) public offers;
    mapping(uint256 => ActiveLoan) public activeLoans;
    mapping(uint256 => Payment[]) public payments;

    uint256 public askNonce;
    uint256 public offerNonce;
    uint256 public loanNonce;

    event AskCreated(uint256 indexed askId, address indexed borrower, address loanAsset, uint256 principal);
    event AskClosed(uint256 indexed askId);
    event OfferCreated(uint256 indexed offerId, address indexed lender, address loanAsset, uint256 principal);
    event OfferClosed(uint256 indexed offerId);
    event LoanAccepted(uint256 indexed loanId, uint256 indexed offerId, address indexed borrower);
    event PaymentMade(uint256 indexed loanId, address indexed borrower, uint256 amount);
    event CollateralClaimed(uint256 indexed loanId, address indexed lender);
    event CollateralUnlocked(uint256 indexed loanId, address indexed borrower);
    event LenderAddressUpdated(uint256 indexed loanId, address indexed oldAddress, address indexed newAddress);

    modifier onlyLender(uint256 loanId) {
        require(activeLoans[loanId].lender == msg.sender, "Only lender");
        _;
    }

    modifier onlyBorrower(uint256 loanId) {
        require(activeLoans[loanId].borrower == msg.sender, "Only borrower");
        _;
    }

    modifier loanExists(uint256 loanId) {
        require(activeLoans[loanId].active, "Loan does not exist");
        _;
    }

    constructor(address _beaconNFT) {
        beaconNFT = BeaconNFT(_beaconNFT);
        loanMath = new LoanMath();
    }

    /// @notice Create a loan ask (borrower request)
    function createAsk(
        address loanAsset,
        uint256 principal,
        uint256 loanTerm,
        address[] calldata collateral
    ) external returns (uint256) {
        uint256 askId = askNonce++;
        asks[askId] = Ask({
            borrower: msg.sender,
            loanAsset: loanAsset,
            principal: principal,
            loanTerm: loanTerm,
            collateral: collateral,
            active: true,
            createdAt: block.timestamp
        });

        // Mint borrower beacon
        beaconNFT.mintBorrowerId(msg.sender, askId);

        emit AskCreated(askId, msg.sender, loanAsset, principal);
        return askId;
    }

    /// @notice Close or update a loan ask
    function closeOrUpdateAsk(uint256 askId) external {
        require(asks[askId].borrower == msg.sender, "Not your ask");
        require(asks[askId].active, "Ask not active");

        asks[askId].active = false;

        // Burn borrower beacon
        beaconNFT.borrowerBeacon(msg.sender, askId);

        emit AskClosed(askId);
    }

    /// @notice Create a loan offer (lender proposal)
    function createOffer(
        address borrower,
        address loanAsset,
        uint256 principal,
        uint256 epochDuration,
        uint256 loanTerm,
        uint256 loanInterestNum,
        uint256 loanInterestDen,
        bool compoundingInterest,
        uint256 minPayment,
        uint8 penaltyType,
        uint256 penaltyValue,
        uint256 maxConsecutiveMisses,
        address[] calldata collateralAssets,
        uint256[] calldata collateralRates,
        bool collateralIsSwappable,
        uint256 claimPeriod,
        uint256 offerExpiration
    ) external returns (uint256) {
        uint256 offerId = offerNonce++;
        offers[offerId] = Offer({
            lender: msg.sender,
            lenderAddress: msg.sender,
            loanAsset: loanAsset,
            principal: principal,
            epochDuration: epochDuration,
            loanTerm: loanTerm,
            loanInterestNum: loanInterestNum,
            loanInterestDen: loanInterestDen,
            compoundingInterest: compoundingInterest,
            minPayment: minPayment,
            penaltyType: penaltyType,
            penaltyValue: penaltyValue,
            maxConsecutiveMisses: maxConsecutiveMisses,
            collateralAssets: collateralAssets,
            collateralRates: collateralRates,
            collateralIsSwappable: collateralIsSwappable,
            claimPeriod: claimPeriod,
            offerExpiration: offerExpiration,
            active: true,
            createdAt: block.timestamp
        });

        // Mint lender beacon
        beaconNFT.mintLenderId(msg.sender, offerId);

        emit OfferCreated(offerId, msg.sender, loanAsset, principal);
        return offerId;
    }

    /// @notice Accept a loan offer and create active loan
    function acceptOffer(uint256 offerId) external returns (uint256) {
        Offer storage offer = offers[offerId];
        require(offer.active, "Offer not active");
        require(offer.lender != msg.sender, "Cannot accept own offer");
        require(
            offer.offerExpiration == 0 || block.timestamp <= offer.offerExpiration,
            "Offer expired"
        );

        uint256 loanId = loanNonce++;
        uint256 loanExpiration = block.timestamp + offer.loanTerm;
        uint256 claimExpiration = loanExpiration + offer.claimPeriod;

        // Calculate initial outstanding balance
        (uint256 outNum, uint256 outDen) = loanMath.applyInterest(
            offer.principal,
            1,
            offer.loanInterestNum,
            offer.loanInterestDen
        );

        activeLoans[loanId] = ActiveLoan({
            loanId: loanId,
            borrower: msg.sender,
            lender: offer.lender,
            lenderAddress: offer.lenderAddress,
            loanAsset: offer.loanAsset,
            principal: offer.principal,
            epochDuration: offer.epochDuration,
            lastEpochBoundary: block.timestamp,
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
            claimExpiration: claimExpiration,
            loanExpiration: loanExpiration,
            loanOutstandingNum: outNum,
            loanOutstandingDen: outDen,
            totalEpochPayments: 0,
            currentConsecutiveMisses: 0,
            active: true,
            createdAt: block.timestamp
        });

        // Mint loan beacons
        beaconNFT.mintLoanId(loanId, msg.sender, offer.lender);

        // Close offer
        offer.active = false;
        beaconNFT.lenderBeacon(offer.lender, offerId);

        emit LoanAccepted(loanId, offerId, msg.sender);
        return loanId;
    }

    /// @notice Make a payment on an active loan
    function makePayment(uint256 loanId, uint256 amount) external loanExists(loanId) onlyBorrower(loanId) {
        ActiveLoan storage loan = activeLoans[loanId];
        require(block.timestamp <= loan.loanExpiration, "Loan expired");
        require(amount > 0, "Payment must be > 0");

        // Apply interest and penalties if needed
        if (loan.epochDuration > 0) {
            uint256 times = (block.timestamp - loan.lastEpochBoundary - 1) / loan.epochDuration;
            if (times > 0) {
                (uint256 newOutNum, uint256 newOutDen) = loanMath.applyInterestNTimes(
                    loan.minPayment > loan.totalEpochPayments,
                    loan.penaltyType,
                    loan.penaltyValue,
                    times,
                    loan.loanInterestNum,
                    loan.loanInterestDen,
                    loan.loanOutstandingNum,
                    loan.loanOutstandingDen,
                    loan.compoundingInterest
                );

                loan.loanOutstandingNum = newOutNum;
                loan.loanOutstandingDen = newOutDen;
                loan.lastEpochBoundary += times * loan.epochDuration;

                if (loan.totalEpochPayments >= loan.minPayment) {
                    loan.totalEpochPayments = 0;
                }
            }
        }

        // Subtract payment
        loan.loanOutstandingNum = loan.loanOutstandingNum * loan.loanOutstandingDen - 
                                  amount * loan.loanOutstandingDen;
        loan.totalEpochPayments += amount;

        // Record payment
        payments[loanId].push(Payment({
            loanId: loanId,
            borrower: msg.sender,
            lender: loan.lender,
            amount: amount,
            timestamp: block.timestamp,
            processed: true
        }));

        // Transfer payment to lender
        (bool success, ) = loan.lenderAddress.call{value: amount}("");
        require(success, "Payment transfer failed");

        emit PaymentMade(loanId, msg.sender, amount);
    }

    /// @notice Claim defaulted collateral (lender)
    function claimDefaultedCollateral(uint256 loanId) 
        external 
        loanExists(loanId) 
        onlyLender(loanId) 
    {
        ActiveLoan storage loan = activeLoans[loanId];
        require(
            block.timestamp > loan.loanExpiration || 
            loan.currentConsecutiveMisses > loan.maxConsecutiveMisses,
            "Loan not defaulted"
        );

        // Burn all beacons
        beaconNFT.burnLoanId(loanId);

        loan.active = false;

        emit CollateralClaimed(loanId, msg.sender);
    }

    /// @notice Unlock lost collateral (borrower, after claim period)
    function unlockLostCollateral(uint256 loanId) 
        external 
        loanExists(loanId) 
        onlyBorrower(loanId) 
    {
        ActiveLoan storage loan = activeLoans[loanId];
        require(block.timestamp > loan.claimExpiration, "Claim period not passed");

        // Burn beacons except Key NFT
        beaconNFT.burnForUnlock(loanId, loan.borrower);

        loan.active = false;

        emit CollateralUnlocked(loanId, msg.sender);
    }

    /// @notice Update lender address
    function updateLenderAddress(uint256 loanId, address newAddress) 
        external 
        loanExists(loanId) 
        onlyLender(loanId) 
    {
        ActiveLoan storage loan = activeLoans[loanId];
        require(block.timestamp <= loan.loanExpiration, "Loan expired");

        address oldAddress = loan.lenderAddress;
        loan.lenderAddress = newAddress;

        emit LenderAddressUpdated(loanId, oldAddress, newAddress);
    }

    /// @notice Get loan count
    function getLoanCount() external view returns (uint256) {
        return loanNonce;
    }

    /// @notice Get ask count
    function getAskCount() external view returns (uint256) {
        return askNonce;
    }

    /// @notice Get offer count
    function getOfferCount() external view returns (uint256) {
        return offerNonce;
    }
}
