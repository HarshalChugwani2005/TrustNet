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
      'lenderId': lenderId,
      'txHash': txHash,
      'blockNumber': blockNumber,
      'onChainLoanId': onChainLoanId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
