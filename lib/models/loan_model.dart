import 'package:cloud_firestore/cloud_firestore.dart';

class LoanModel {
  final String id;
  final String borrowerId;
  final String borrowerName;
  final int borrowerTrustScore;
  final double amount;
  final String duration;
  final String purpose;
  final String status;
  final double interestRate;
  final double interestAmount;
  final double totalRepayable;
  final bool latePenaltyApplied;
  final double repaidAmount;
  final double collateralAmount;
  final double collateralPercent;
  final bool collateralLocked;
  final bool collateralTransferred;
  final String? lenderId;
  final String? txHash;
  final int? blockNumber;
  final int? onChainLoanId;
  final DateTime? createdAt;

  LoanModel({
    required this.id,
    required this.borrowerId,
    required this.borrowerName,
    required this.borrowerTrustScore,
    required this.amount,
    required this.duration,
    required this.purpose,
    this.status = 'pending',
    this.interestRate = 0,
    this.interestAmount = 0,
    this.totalRepayable = 0,
    this.latePenaltyApplied = false,
    this.repaidAmount = 0,
    this.collateralAmount = 0,
    this.collateralPercent = 0,
    this.collateralLocked = false,
    this.collateralTransferred = false,
    this.lenderId,
    this.txHash,
    this.blockNumber,
    this.onChainLoanId,
    this.createdAt,
  });

  factory LoanModel.fromMap(Map<String, dynamic> data, String documentId) {
    return LoanModel(
      id: documentId,
      borrowerId: data['borrowerId'] ?? '',
      borrowerName: data['borrowerName'] ?? 'Unknown',
      borrowerTrustScore: data['borrowerTrustScore'] ?? 0,
      amount: (data['amount'] ?? 0).toDouble(),
      duration: data['duration'] ?? '',
      purpose: data['purpose'] ?? '',
      status: data['status'] ?? 'pending',
        interestRate: (data['interestRate'] ?? 0).toDouble(),
        interestAmount: (data['interestAmount'] ?? 0).toDouble(),
        totalRepayable: ((data['totalRepayable'] ??
              ((data['amount'] ?? 0).toDouble() +
                (data['interestAmount'] ?? 0).toDouble()))
            as num)
          .toDouble(),
          latePenaltyApplied: data['latePenaltyApplied'] ?? false,
      repaidAmount: (data['repaidAmount'] ?? 0).toDouble(),
      collateralAmount: (data['collateralAmount'] ?? 0).toDouble(),
      collateralPercent: (data['collateralPercent'] ?? 0).toDouble(),
      collateralLocked: data['collateralLocked'] ?? false,
      collateralTransferred: data['collateralTransferred'] ?? false,
      lenderId: data['lenderId'],
      txHash: data['txHash'],
      blockNumber: data['blockNumber'],
      onChainLoanId: data['onChainLoanId'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'borrowerId': borrowerId,
      'borrowerName': borrowerName,
      'borrowerTrustScore': borrowerTrustScore,
      'amount': amount,
      'duration': duration,
      'purpose': purpose,
      'status': status,
      'interestRate': interestRate,
      'interestAmount': interestAmount,
      'totalRepayable': totalRepayable > 0 ? totalRepayable : amount + interestAmount,
      'latePenaltyApplied': latePenaltyApplied,
      'repaidAmount': repaidAmount,
      'collateralAmount': collateralAmount,
      'collateralPercent': collateralPercent,
      'collateralLocked': collateralLocked,
      'collateralTransferred': collateralTransferred,
      'lenderId': lenderId,
      'txHash': txHash,
      'blockNumber': blockNumber,
      'onChainLoanId': onChainLoanId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
