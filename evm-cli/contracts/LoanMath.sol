// SPDX-License-Identifier: JSSH-2026-0001
pragma solidity ^0.8.24;

/// @title LoanMath - Mathematical operations for loan protocol
/// @notice Implements interest, penalty, and balance calculations
contract LoanMath {
    /// @notice Apply interest to balance: balance * (1 + interest)
    function applyInterest(
        uint256 balNum,
        uint256 balDen,
        uint256 interestNum,
        uint256 interestDen
    ) public pure returns (uint256 newBalNum, uint256 newBalDen) {
        uint256 totalNum = balNum * (interestDen + interestNum);
        uint256 totalDen = balDen * interestDen;
        uint256 g = _gcd(totalNum, totalDen);
        return (totalNum / g, totalDen / g);
    }

    /// @notice Subtract payment from balance
    function subtractPayment(
        uint256 paymentAmount,
        uint256 balNum,
        uint256 balDen
    ) public pure returns (uint256 newBalNum, uint256 newBalDen) {
        uint256 totalNum = balNum - balDen * paymentAmount;
        return (totalNum, balDen);
    }

    /// @notice Apply interest N times with penalties
    function applyInterestNTimes(
        bool penalize,
        uint8 penaltyType,
        uint256 penaltyValue,
        uint256 times,
        uint256 interestNum,
        uint256 interestDen,
        uint256 balNum,
        uint256 balDen,
        bool compounding
    ) public pure returns (uint256 newBalNum, uint256 newBalDen) {
        if (times == 0) {
            uint256 g0 = _gcd(balNum, balDen);
            return (balNum / g0, balDen / g0);
        }

        uint256 currentNum = balNum;
        uint256 currentDen = balDen;
        uint256 currentInterestNum = compounding ? interestNum : 0;
        uint256 currentInterestDen = compounding ? interestDen : 1;

        for (uint256 i = 0; i < times; i++) {
            if (penalize) {
                if (penaltyType == 1) {
                    // Fixed fee
                    currentNum = (currentNum + penaltyValue * currentDen) * (currentInterestDen + currentInterestNum);
                    currentDen = currentDen * currentInterestDen;
                } else if (penaltyType == 2) {
                    // Percent fee
                    uint256 feeNum = penaltyValue;
                    uint256 feeDen = 100;
                    currentNum = currentNum * (feeDen + feeNum) * (currentInterestDen + currentInterestNum);
                    currentDen = currentDen * feeDen * currentInterestDen;
                } else {
                    // No penalty
                    currentNum = currentNum * (currentInterestDen + currentInterestNum);
                    currentDen = currentDen * currentInterestDen;
                }
            } else {
                currentNum = currentNum * (currentInterestDen + currentInterestNum);
                currentDen = currentDen * currentInterestDen;
            }
        }

        uint256 g1 = _gcd(currentNum, currentDen);
        return (currentNum / g1, currentDen / g1);
    }

    /// @notice Calculate next epoch boundary
    function nextBoundary(
        uint256 lastBoundary,
        uint256 epochDuration,
        uint256 currentTime
    ) public pure returns (uint256) {
        uint256 boundary = lastBoundary + epochDuration;
        while (boundary <= currentTime) {
            boundary += epochDuration;
        }
        return boundary;
    }

    /// @notice Calculate collateral ratio
    function calculateCollateralRatio(
        uint256 collateralAmount,
        uint256 collateralRate,
        uint256 loanAmount,
        uint256 loanRate
    ) public pure returns (uint256) {
        return (collateralAmount * collateralRate) / (loanAmount * loanRate);
    }

    /// @notice Check if loan is in default
    function isLoanInDefault(
        uint256 loanExpiration,
        uint256 currentConsecutiveMisses,
        uint256 maxConsecutiveMisses,
        uint256 currentTime
    ) public pure returns (bool) {
        return currentTime > loanExpiration || 
               currentConsecutiveMisses > maxConsecutiveMisses;
    }

    /// @notice GCD calculation
    function _gcd(uint256 a, uint256 b) internal pure returns (uint256) {
        while (b != 0) {
            uint256 temp = b;
            b = a % b;
            a = temp;
        }
        return a;
    }

    /// @notice Calculate loan balance at specific time
    function calculateLoanBalance(
        uint256 principalNum,
        uint256 principalDen,
        uint256 interestNum,
        uint256 interestDen,
        uint256 startTime,
        uint256 currentTime,
        uint256 epochDuration,
        bool compounding
    ) public pure returns (uint256 balanceNum, uint256 balanceDen) {
        if (epochDuration == 0) {
            // Simple interest
            uint256 elapsed = currentTime - startTime;
            uint256 periods = elapsed / epochDuration;
            if (periods == 0) {
                return (principalNum, principalDen);
            }
            return applyInterestNTimes(
                false,
                0,
                0,
                periods,
                interestNum,
                interestDen,
                principalNum,
                principalDen,
                compounding
            );
        }
        return (principalNum, principalDen);
    }
}
