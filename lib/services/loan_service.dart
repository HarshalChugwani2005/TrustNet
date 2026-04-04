import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/loan_model.dart';
import 'lending_contract_service.dart';
import 'notification_service.dart';
import 'wallet_bridge_service.dart';

class LoanService {
  LoanService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String _generateTxHash() {
    final random = Random();
    const chars = '0123456789abcdef';
    return '0x${List.generate(40, (_) => chars[random.nextInt(16)]).join()}';
  }

  int _generateBlock() {
    return 14000000 + Random().nextInt(100000);
  }

  Future<void> requestLoan(LoanModel loan) async {
    final docRef = _firestore.collection('loans').doc();
    String txHash = _generateTxHash();
    int blockNumber = _generateBlock();
    int? onChainLoanId;
    bool usedOnChain = false;

    try {
      final wallet = await WalletBridgeService().ensureWalletForUser(loan.borrowerId);
      final onChainResult = await LendingContractService().requestLoan(
        privateKeyHex: wallet.privateKeyHex,
        firebaseUid: loan.borrowerId,
        amount: loan.amount,
        duration: loan.duration,
        purpose: loan.purpose,
      );
      txHash = onChainResult.txHash;
      blockNumber = onChainResult.blockNumber ?? blockNumber;
      onChainLoanId = 100 + Random().nextInt(900);
      usedOnChain = true;
    } catch (_) {
      usedOnChain = false;
    }

    final loanWithChainInfo = LoanModel(
      id: docRef.id,
      borrowerId: loan.borrowerId,
      borrowerName: loan.borrowerName,
      borrowerTrustScore: loan.borrowerTrustScore,
      amount: loan.amount,
      duration: loan.duration,
      purpose: loan.purpose,
      status: 'pending',
      txHash: txHash,
      blockNumber: blockNumber,
      onChainLoanId: onChainLoanId,
    );

    await docRef.set({
      ...loanWithChainInfo.toMap(),
      'executionMode': usedOnChain ? 'onchain' : 'simulated',
      'chainNetwork': 'base-sepolia',
    });
  }

  Stream<List<LoanModel>> streamAllTransactions() {
    return _firestore.collection('loans').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => LoanModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Stream<List<LoanModel>> streamPendingLoans() {
    return _firestore
        .collection('loans')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => LoanModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) {
            final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          return list;
        });
  }

  Stream<List<LoanModel>> streamBorrowerLoans(String borrowerId) {
    return _firestore
        .collection('loans')
        .where('borrowerId', isEqualTo: borrowerId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => LoanModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) {
            final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          return list;
        });
  }

  Stream<List<LoanModel>> streamLenderLoans(String lenderId) {
    return _firestore
        .collection('loans')
        .where('lenderId', isEqualTo: lenderId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => LoanModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) {
            final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          return list;
        });
  }

  Future<void> updateLoanStatus(LoanModel loan, String status, {String? lenderId}) async {
    String txHash = _generateTxHash();
    int blockNumber = _generateBlock();
    bool usedOnChain = false;

    if (lenderId != null && loan.onChainLoanId != null) {
      try {
        final wallet = await WalletBridgeService().ensureWalletForUser(lenderId);
        final result = await LendingContractService().updateLoanStatus(
          privateKeyHex: wallet.privateKeyHex,
          onChainLoanId: loan.onChainLoanId!,
          status: status,
        );
        txHash = result.txHash;
        usedOnChain = true;
      } catch (_) {
        usedOnChain = false;
      }
    }

    final Map<String, dynamic> data = {
      'status': status,
      'txHash': txHash,
      'blockNumber': blockNumber,
      'executionMode': usedOnChain ? 'onchain' : 'simulated',
    };

    if (lenderId != null) {
      data['lenderId'] = lenderId;
    }

    await _firestore.collection('loans').doc(loan.id).update(data);

    final action = status == 'approved' ? 'approved' : 'rejected';
    await NotificationService().sendNotification(
      targetUserId: loan.borrowerId,
      title: 'Loan $status',
      message: 'Your loan request for ₹${loan.amount.toStringAsFixed(0)} was $action.',
    );
  }

  Future<void> repayLoan(LoanModel loan) async {
    String txHash = _generateTxHash();
    int blockNumber = _generateBlock();
    bool usedOnChain = false;

    if (loan.onChainLoanId != null) {
      try {
        final wallet = await WalletBridgeService().ensureWalletForUser(loan.borrowerId);
        final result = await LendingContractService().updateLoanStatus(
          privateKeyHex: wallet.privateKeyHex,
          onChainLoanId: loan.onChainLoanId!,
          status: 'repaid',
        );
        txHash = result.txHash;
        usedOnChain = true;
      } catch (_) {
        usedOnChain = false;
      }
    }

    final batch = _firestore.batch();
    final loanRef = _firestore.collection('loans').doc(loan.id);
    batch.update(loanRef, {
      'status': 'repaid',
      'txHash': txHash,
      'blockNumber': blockNumber,
      'executionMode': usedOnChain ? 'onchain' : 'simulated',
    });

    final userRef = _firestore.collection('users').doc(loan.borrowerId);
    batch.update(userRef, {'trustScore': FieldValue.increment(5)});

    await batch.commit();

    if (loan.lenderId != null && loan.lenderId!.isNotEmpty) {
      await NotificationService().sendNotification(
        targetUserId: loan.lenderId!,
        title: 'Repayment Received',
        message: 'The loan of ₹${loan.amount.toStringAsFixed(0)} to ${loan.borrowerName} was fully repaid.',
      );
    }
  }
}
