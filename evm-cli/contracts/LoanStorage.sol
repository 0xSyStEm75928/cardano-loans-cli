// SPDX-License-Identifier: JSSH-2026-0001
pragma solidity ^0.8.24;

/// @title LoanStorage - Core data structures for ZER EVM Loan Protocol
/// @notice Maps Cardano Loan datums to EVM storage patterns
contract LoanStorage {
    /// @notice Loan request from borrower
    struct Ask {
        address borrower;
        address loanAsset;
        uint256 principal;
        uint256 loanTerm;
        address[] collateral;
        bool active;
        uint256 createdAt;
    }

    /// @notice Loan offer from lender
    struct Offer {
        address lender;
        address lenderAddress;
        address loanAsset;
        uint256 principal;
        uint256 epochDuration;
        uint256 loanTerm;
        uint256 loanInterestNum;
        uint256 loanInterestDen;
        bool compoundingInterest;
        uint256 minPayment;
        uint8 penaltyType; // 0: None, 1: Fixed, 2: Percent
        uint256 penaltyValue;
        uint256 maxConsecutiveMisses;
        address[] collateralAssets;
        uint256[] collateralRates;
        bool collateralIsSwappable;
        uint256 claimPeriod;
        uint256 offerExpiration;
        bool active;
        uint256 createdAt;
    }

    /// @notice Active loan state
    struct ActiveLoan {
        uint256 loanId;
        address borrower;
        address lender;
        address lenderAddress;
        address loanAsset;
        uint256 principal;
        uint256 epochDuration;
        uint256 lastEpochBoundary;
        uint256 loanTerm;
        uint256 loanInterestNum;
        uint256 loanInterestDen;
        bool compoundingInterest;
        uint256 minPayment;
        uint8 penaltyType;
        uint256 penaltyValue;
        uint256 maxConsecutiveMisses;
        address[] collateralAssets;
        uint256[] collateralRates;
        bool collateralIsSwappable;
        uint256 claimExpiration;
        uint256 loanExpiration;
        uint256 loanOutstandingNum;
        uint256 loanOutstandingDen;
        uint256 totalEpochPayments;
        uint256 currentConsecutiveMisses;
        bool active;
        uint256 createdAt;
    }

    /// @notice Payment record
    struct Payment {
        uint256 loanId;
        address borrower;
        address lender;
        uint256 amount;
        uint256 timestamp;
        bool processed;
    }

    /// @notice Loan action types (maps to Cardano LoanRedeemer)
    enum LoanAction {
        CloseOrUpdateAsk,
        CloseOrUpdateOffer,
        AcceptOffer,
        MakePayment,
        SpendWithKeyNFT,
        UpdateLenderAddress,
        Unlock
    }

    /// @notice Penalty types
    enum PenaltyType {
        None,
        Fixed,
        Percent
    }
}
