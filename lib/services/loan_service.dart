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
  static const int _baseTrustScore = 50;
  static const int _minTrustScore = 0;
  static const int _maxTrustScore = 100;
  static const double _defaultPenaltyPoints = 25.0;

  String _generateTxHash() {
    final random = Random();
    const chars = '0123456789abcdef';
    return '0x${List.generate(40, (_) => chars[random.nextInt(16)]).join()}';
  }

  int _generateBlock() {
    return 14000000 + Random().nextInt(100000);
  }

  int _extractDurationMonths(String duration) {
    final match = RegExp(r'\d+').firstMatch(duration);
    final months = match == null ? 1 : int.tryParse(match.group(0) ?? '1') ?? 1;
    return months <= 0 ? 1 : months;
  }

  int _calculateTrustScoreFromRepaymentHistory({
    required double eventPoints,
    required int defaultedLoanCount,
  }) {
    final rawScore =
        _baseTrustScore + eventPoints - (defaultedLoanCount * _defaultPenaltyPoints);
    return rawScore.clamp(_minTrustScore.toDouble(), _maxTrustScore.toDouble()).round();
  }

  Future<void> _refreshBorrowerTrustScore(String borrowerId) async {
    final loansSnapshot = await _firestore
        .collection('loans')
        .where('borrowerId', isEqualTo: borrowerId)
        .get();

    var eventPoints = 0.0;
    var defaultedLoanCount = 0;

    for (final doc in loansSnapshot.docs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString().toLowerCase();
      if (status == 'defaulted' || status == 'written_off') {
        defaultedLoanCount += 1;
      }

      final events = data['repaymentEvents'];
      if (events is List) {
        for (final event in events) {
          if (event is Map<String, dynamic>) {
            final points = (event['points'] as num?)?.toDouble() ?? 0;
            eventPoints += points;
          } else if (event is Map) {
            final points = (event['points'] as num?)?.toDouble() ?? 0;
            eventPoints += points;
          }
        }
      }
    }

    final nextScore = _calculateTrustScoreFromRepaymentHistory(
      eventPoints: eventPoints,
      defaultedLoanCount: defaultedLoanCount,
    );

    await _firestore.collection('users').doc(borrowerId).set({
      'trustScore': nextScore,
      'trustScoreRaw':
          _baseTrustScore + eventPoints - (defaultedLoanCount * _defaultPenaltyPoints),
      'trustScoreUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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

    if (status == 'approved') {
      data['approvedAt'] = FieldValue.serverTimestamp();
      data['nextDueAt'] = Timestamp.fromDate(DateTime.now().add(const Duration(days: 30)));
      data['repaidAmount'] = 0.0;
      data['onTimeStreak'] = 0;
    }

    await _firestore.collection('loans').doc(loan.id).update(data);

    final action = status == 'approved' ? 'approved' : 'rejected';
    await NotificationService().sendNotification(
      targetUserId: loan.borrowerId,
      title: 'Loan $status',
      message: 'Your loan request for ₹${loan.amount.toStringAsFixed(0)} was $action.',
    );

    if (status == 'approved' ||
        status == 'repaid' ||
        status == 'defaulted' ||
        status == 'written_off') {
      await _refreshBorrowerTrustScore(loan.borrowerId);
    }
  }

  Future<bool> repayLoan(LoanModel loan, {required double paymentAmount}) async {
    final loanRef = _firestore.collection('loans').doc(loan.id);
    final latestSnapshot = await loanRef.get();
    final latestData = latestSnapshot.data() ?? <String, dynamic>{};

    final loanAmount = (latestData['amount'] ?? loan.amount).toDouble();
    final alreadyRepaid = ((latestData['repaidAmount'] ?? loan.repaidAmount) as num)
        .toDouble()
        .clamp(0.0, loanAmount);
    final remainingAmount = (loanAmount - alreadyRepaid).clamp(0.0, loanAmount);
    if (paymentAmount <= 0 || paymentAmount > remainingAmount) {
      throw Exception('Invalid repayment amount selected.');
    }

    final nextRepaidAmount = (alreadyRepaid + paymentAmount).clamp(0.0, loanAmount);
    final isFullyRepaid = nextRepaidAmount >= (loanAmount - 0.01);

    final durationText = (latestData['duration'] ?? loan.duration).toString();
    final durationMonths = _extractDurationMonths(durationText);
    final duePerCycle = loanAmount / durationMonths;

    final now = DateTime.now();
    final nextDueRaw = latestData['nextDueAt'];
    final nextDueAt = nextDueRaw is Timestamp
        ? nextDueRaw.toDate()
        : now.add(const Duration(days: 30));
    final daysLate = now.difference(nextDueAt).inDays;

    final coverageRatio = (paymentAmount / duePerCycle).clamp(0.0, 1.0);
    final onTimeInstallment = daysLate <= 0 && paymentAmount >= duePerCycle;
    var onTimeStreak = (latestData['onTimeStreak'] as num?)?.toInt() ?? 0;

    double points;
    String eventType;

    double onTimePointsByLoanAmount(double amount) {
      if (amount < 2000) {
        return 5.0;
      }
      if (amount < 5000) {
        return 8.0;
      }
      return 10.0;
    }

    final baseOnTimePoints = onTimePointsByLoanAmount(loanAmount);

    if (daysLate <= 0) {
      points = baseOnTimePoints * coverageRatio;
      eventType = onTimeInstallment ? 'on_time_installment' : 'on_time_partial';

      // Early repayment gets additional boost.
      if (daysLate < 0 && onTimeInstallment) {
        points += 2.0;
        eventType = 'early_repayment';
      }
    } else if (daysLate <= 3) {
      points = -3.0;
      eventType = 'late_1_3_days';
    } else if (daysLate <= 7) {
      points = -5.0;
      eventType = 'late_4_7_days';
    } else {
      points = -10.0;
      eventType = 'late_over_7_days';
    }

    if (onTimeInstallment) {
      onTimeStreak += 1;
    } else {
      onTimeStreak = 0;
    }

    DateTime? nextDueAtUpdate;
    if (!isFullyRepaid) {
      if (paymentAmount >= (duePerCycle * 0.5)) {
        final cyclesCovered = max(1, (paymentAmount / duePerCycle).floor());
        nextDueAtUpdate = nextDueAt.add(Duration(days: 30 * cyclesCovered));
      } else {
        nextDueAtUpdate = nextDueAt;
      }
    }

    String txHash = _generateTxHash();
    int blockNumber = _generateBlock();
    bool usedOnChain = false;

    if (loan.onChainLoanId != null && isFullyRepaid) {
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
    final Map<String, dynamic> loanUpdate = {
      'status': isFullyRepaid ? 'repaid' : 'approved',
      'repaidAmount': nextRepaidAmount,
      'txHash': txHash,
      'blockNumber': blockNumber,
      'executionMode': usedOnChain ? 'onchain' : 'simulated',
      'onTimeStreak': onTimeStreak,
      'lastRepaidAt': FieldValue.serverTimestamp(),
      'repaymentEvents': FieldValue.arrayUnion([
        {
          'paidAt': Timestamp.fromDate(now),
          'amount': paymentAmount,
          'daysLate': daysLate,
          'points': points,
          'eventType': eventType,
        }
      ]),
    };

    if (nextDueAtUpdate != null) {
      loanUpdate['nextDueAt'] = Timestamp.fromDate(nextDueAtUpdate);
    }

    batch.update(loanRef, loanUpdate);

    await batch.commit();
    await _refreshBorrowerTrustScore(loan.borrowerId);

    if (loan.lenderId != null && loan.lenderId!.isNotEmpty) {
      await NotificationService().sendNotification(
        targetUserId: loan.lenderId!,
        title: isFullyRepaid ? 'Loan Fully Repaid' : 'Partial Repayment Received',
        message: isFullyRepaid
            ? 'The loan of ₹${loanAmount.toStringAsFixed(0)} to ${loan.borrowerName} was fully repaid.'
            : '${loan.borrowerName} repaid ₹${paymentAmount.toStringAsFixed(0)}. Remaining balance: ₹${(loanAmount - nextRepaidAmount).toStringAsFixed(0)}.',
      );
    }

    return isFullyRepaid;
  }
}
