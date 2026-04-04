// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract TrustNetLendingPool {
    enum LoanStatus {
        Requested,
        Approved,
        Repaid,
        Rejected
    }

    struct Loan {
        uint256 id;
        address borrower;
        string firebaseUid;
        uint256 amountWei;
        uint32 durationDays;
        bytes32 purposeHash;
        LoanStatus status;
        uint64 createdAt;
    }

    uint256 public nextLoanId;
    mapping(uint256 => Loan) public loans;

    event LoanRequested(
        uint256 indexed loanId,
        address indexed borrower,
        string firebaseUid,
        uint256 amountWei,
        uint32 durationDays,
        bytes32 purposeHash
    );

    event LoanStatusUpdated(uint256 indexed loanId, LoanStatus status);

    function requestLoan(
        uint256 amountWei,
        uint32 durationDays,
        bytes32 purposeHash,
        string calldata firebaseUid
    ) external {
        require(amountWei > 0, "amount=0");
        require(durationDays > 0, "duration=0");
        require(bytes(firebaseUid).length > 0, "uid-empty");

        uint256 loanId = ++nextLoanId;
        loans[loanId] = Loan({
            id: loanId,
            borrower: msg.sender,
            firebaseUid: firebaseUid,
            amountWei: amountWei,
            durationDays: durationDays,
            purposeHash: purposeHash,
            status: LoanStatus.Requested,
            createdAt: uint64(block.timestamp)
        });

        emit LoanRequested(
            loanId,
            msg.sender,
            firebaseUid,
            amountWei,
            durationDays,
            purposeHash
        );
    }

    function setLoanStatus(uint256 loanId, LoanStatus status) external {
        Loan storage loan = loans[loanId];
        require(loan.id != 0, "loan-not-found");

        loan.status = status;
        emit LoanStatusUpdated(loanId, status);
    }
}
