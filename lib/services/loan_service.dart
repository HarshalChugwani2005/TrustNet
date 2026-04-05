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
  static const double _baseInterestRate = 0.05;
  static const Duration _newUserRestrictionWindow = Duration(days: 30);

  double _collateralPercentFromTrustScore(int trustScore) {
    if (trustScore >= 80) {
      return 0.05;
    }
    if (trustScore >= 60) {
      return 0.10;
    }
    if (trustScore >= 40) {
      return 0.15;
    }
    return 0.25;
  }

  double _round2(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  double _readBalance(Map<String, dynamic> data, String key) {
    return (data[key] ?? 0).toDouble();
  }

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

  DateTime? _readDateTime(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  DateTime _loanCreatedAt(Map<String, dynamic> data) {
    return _readDateTime(data, const ['createdAt', 'created_at']) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  bool _isWithinNewUserWindow(Map<String, dynamic> userData) {
    final createdAt =
        _readDateTime(userData, const ['createdAt', 'accountCreatedAt', 'created_at']);
    if (createdAt == null) {
      return false;
    }
    return DateTime.now().isBefore(createdAt.add(_newUserRestrictionWindow));
  }

  bool _isInProcessLoanStatus(String status) {
    return status == 'pending' || status == 'approved';
  }

  bool _isFundedLoanStatus(String status) {
    return status == 'approved' ||
        status == 'repaid' ||
        status == 'defaulted' ||
        status == 'written_off';
  }

  bool _isLoanRepaidOnTime(Map<String, dynamic> loanData) {
    final status = (loanData['status'] ?? '').toString().toLowerCase();
    if (status != 'repaid') {
      return false;
    }

    final events = loanData['repaymentEvents'];
    if (events is List) {
      for (final event in events) {
        if (event is Map<String, dynamic>) {
          final eventType = (event['eventType'] ?? '').toString().toLowerCase();
          if (eventType.startsWith('late_')) {
            return false;
          }
        } else if (event is Map) {
          final eventType = (event['eventType'] ?? '').toString().toLowerCase();
          if (eventType.startsWith('late_')) {
            return false;
          }
        }
      }
    }

    return true;
  }

  double _durationInYears(String duration) {
    final valueMatch = RegExp(r'\d+').firstMatch(duration);
    final value = valueMatch == null ? 1 : int.tryParse(valueMatch.group(0) ?? '1') ?? 1;
    final safeValue = value <= 0 ? 1 : value;
    final normalized = duration.toLowerCase();

    if (normalized.contains('day')) {
      return safeValue / 365;
    }
    if (normalized.contains('year')) {
      return safeValue.toDouble();
    }
    return safeValue / 12;
  }

  double _interestRateFromTrustScore(int trustScore) {
    double adjustment;
    if (trustScore >= 80) {
      adjustment = -0.02;
    } else if (trustScore >= 60) {
      adjustment = -0.01;
    } else if (trustScore >= 40) {
      adjustment = 0.0;
    } else {
      adjustment = 0.02;
    }

    return (_baseInterestRate + adjustment).clamp(0.02, 0.20);
  }

  double calculateInterestAmount({
    required double amount,
    required String duration,
    required int trustScore,
  }) {
    final rate = _interestRateFromTrustScore(trustScore);
    final years = _durationInYears(duration);
    return _round2(amount * rate * years);
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
    final borrowerRef = _firestore.collection('users').doc(loan.borrowerId);

    final borrowerSnapshot = await borrowerRef.get();
    final borrowerUserData = borrowerSnapshot.data() ?? <String, dynamic>{};
    if (_isWithinNewUserWindow(borrowerUserData)) {
      final borrowerLoansSnapshot = await _firestore
          .collection('loans')
          .where('borrowerId', isEqualTo: loan.borrowerId)
          .get();

      final borrowerLoans = borrowerLoansSnapshot.docs
          .map((doc) => doc.data())
          .toList();

      final hasInProcessLoan = borrowerLoans.any((loanData) {
        final status = (loanData['status'] ?? '').toString().toLowerCase();
        return _isInProcessLoanStatus(status);
      });

      if (hasInProcessLoan) {
        throw Exception(
          'new borrower first-30-days limit: only one loan can be in process at a time.',
        );
      }

      final fundedLoans = borrowerLoans.where((loanData) {
        final status = (loanData['status'] ?? '').toString().toLowerCase();
        return _isFundedLoanStatus(status);
      }).toList();

      if (fundedLoans.isNotEmpty) {
        fundedLoans.sort(
          (a, b) => _loanCreatedAt(a).compareTo(_loanCreatedAt(b)),
        );

        final firstFundedLoan = fundedLoans.first;
        if (!_isLoanRepaidOnTime(firstFundedLoan)) {
          throw Exception(
            'new borrower first-30-days limit: repay first loan on time before requesting another.',
          );
        }
      }
    }

    int borrowerTrustScore = loan.borrowerTrustScore;
    var collateralPercent = _collateralPercentFromTrustScore(borrowerTrustScore);
    var collateralAmount = _round2(loan.amount * collateralPercent);
    var interestRate = _interestRateFromTrustScore(borrowerTrustScore);
    var interestAmount = calculateInterestAmount(
      amount: loan.amount,
      duration: loan.duration,
      trustScore: borrowerTrustScore,
    );
    var totalRepayable = _round2(loan.amount + interestAmount);

    await _firestore.runTransaction((transaction) async {
      final borrowerSnap = await transaction.get(borrowerRef);
      final borrowerData = borrowerSnap.data() ?? <String, dynamic>{};

        borrowerTrustScore =
          (borrowerData['trustScore'] as num?)?.toInt() ?? borrowerTrustScore;
      collateralPercent = _collateralPercentFromTrustScore(borrowerTrustScore);
      collateralAmount = _round2(loan.amount * collateralPercent);
        interestRate = _interestRateFromTrustScore(borrowerTrustScore);
        interestAmount = calculateInterestAmount(
          amount: loan.amount,
          duration: loan.duration,
          trustScore: borrowerTrustScore,
        );
        totalRepayable = _round2(loan.amount + interestAmount);

      if (collateralAmount > loan.amount) {
        throw Exception('Collateral cannot be greater than requested loan amount.');
      }

      final walletBalance = _readBalance(borrowerData, 'wallet_balance');
      final lockedBalance = _readBalance(borrowerData, 'locked_balance');

      if (walletBalance < collateralAmount) {
        throw Exception('insufficient balance in wallet');
      }

      transaction.set(
        borrowerRef,
        {
          'wallet_balance': _round2(walletBalance - collateralAmount),
          'locked_balance': _round2(lockedBalance + collateralAmount),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

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
      borrowerTrustScore: borrowerTrustScore,
      amount: loan.amount,
      duration: loan.duration,
      purpose: loan.purpose,
      status: 'pending',
      interestRate: interestRate,
      interestAmount: interestAmount,
      totalRepayable: totalRepayable,
      latePenaltyApplied: false,
      collateralAmount: collateralAmount,
      collateralPercent: collateralPercent,
      collateralLocked: true,
      collateralTransferred: false,
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

    final loanRef = _firestore.collection('loans').doc(loan.id);
    final effectiveLenderId = lenderId ?? loan.lenderId;

    await _firestore.runTransaction((transaction) async {
      final loanSnap = await transaction.get(loanRef);
      final loanData = loanSnap.data() ?? <String, dynamic>{};

      final borrowerId = (loanData['borrowerId'] ?? loan.borrowerId).toString();
      final borrowerRef = _firestore.collection('users').doc(borrowerId);
      final borrowerSnap = await transaction.get(borrowerRef);
      final borrowerData = borrowerSnap.data() ?? <String, dynamic>{};

      final collateralAmount = (loanData['collateralAmount'] ?? 0).toDouble();
      final collateralLocked = loanData['collateralLocked'] == true;
      final collateralTransferred = loanData['collateralTransferred'] == true;

      final update = <String, dynamic>{
        'status': status,
        'txHash': txHash,
        'blockNumber': blockNumber,
        'executionMode': usedOnChain ? 'onchain' : 'simulated',
      };

      if (effectiveLenderId != null && effectiveLenderId.isNotEmpty) {
        update['lenderId'] = effectiveLenderId;
      }

      if (status == 'approved') {
        if (effectiveLenderId == null || effectiveLenderId.isEmpty) {
          throw Exception('Lender is required to approve this loan.');
        }

        final lenderRef = _firestore.collection('users').doc(effectiveLenderId);
        final lenderSnap = await transaction.get(lenderRef);
        final lenderData = lenderSnap.data() ?? <String, dynamic>{};

        if (_isWithinNewUserWindow(lenderData)) {
          final lenderLoansSnapshot = await _firestore
              .collection('loans')
              .where('lenderId', isEqualTo: effectiveLenderId)
              .get();

          final lenderLoans = lenderLoansSnapshot.docs
              .map((doc) => doc.data())
              .toList();

          final fundedLoans = lenderLoans.where((loanData) {
            final status = (loanData['status'] ?? '').toString().toLowerCase();
            return _isFundedLoanStatus(status);
          }).toList();

          final hasInProcessInvestment = fundedLoans.any((loanData) {
            final status = (loanData['status'] ?? '').toString().toLowerCase();
            return status == 'approved';
          });

          if (hasInProcessInvestment) {
            throw Exception(
              'new lender first-30-days limit: only one approved loan can be in process at a time.',
            );
          }

          if (fundedLoans.isNotEmpty) {
            final hasAnyRepaid = fundedLoans.any((loanData) {
              final status = (loanData['status'] ?? '').toString().toLowerCase();
              return status == 'repaid';
            });

            if (!hasAnyRepaid) {
              throw Exception(
                'new lender first-30-days limit: next approval is allowed only after borrower repayment.',
              );
            }
          }
        }

        final lenderWallet = _readBalance(lenderData, 'wallet_balance');
        final borrowerWallet = _readBalance(borrowerData, 'wallet_balance');
        final loanAmount = (loanData['amount'] ?? loan.amount).toDouble();

        if (lenderWallet < loanAmount) {
          throw Exception('insufficient balance in wallet');
        }

        transaction.set(
          lenderRef,
          {
            'wallet_balance': _round2(lenderWallet - loanAmount),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        transaction.set(
          borrowerRef,
          {
            'wallet_balance': _round2(borrowerWallet + loanAmount),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        update['approvedAt'] = FieldValue.serverTimestamp();
        update['nextDueAt'] = Timestamp.fromDate(DateTime.now().add(const Duration(days: 30)));
        update['repaidAmount'] = 0.0;
        update['onTimeStreak'] = 0;
      }

      if (status == 'rejected' && collateralLocked && collateralAmount > 0) {
        final borrowerWallet = _readBalance(borrowerData, 'wallet_balance');
        final borrowerLocked = _readBalance(borrowerData, 'locked_balance');
        final releasable = min(collateralAmount, borrowerLocked);

        transaction.set(
          borrowerRef,
          {
            'wallet_balance': _round2(borrowerWallet + releasable),
            'locked_balance': _round2(borrowerLocked - releasable),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        update['collateralLocked'] = false;
        update['collateralReleasedAt'] = FieldValue.serverTimestamp();
      }

      if ((status == 'defaulted' || status == 'written_off') &&
          collateralLocked &&
          !collateralTransferred &&
          collateralAmount > 0) {
        if (effectiveLenderId == null || effectiveLenderId.isEmpty) {
          throw Exception('Lender is required to claim collateral on default.');
        }

        final lenderRef = _firestore.collection('users').doc(effectiveLenderId);
        final lenderSnap = await transaction.get(lenderRef);
        final lenderData = lenderSnap.data() ?? <String, dynamic>{};

        final borrowerLocked = _readBalance(borrowerData, 'locked_balance');
        final lenderWallet = _readBalance(lenderData, 'wallet_balance');
        final claimable = min(collateralAmount, borrowerLocked);

        transaction.set(
          borrowerRef,
          {
            'locked_balance': _round2(borrowerLocked - claimable),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        transaction.set(
          lenderRef,
          {
            'wallet_balance': _round2(lenderWallet + claimable),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        update['collateralLocked'] = false;
        update['collateralTransferred'] = true;
        update['collateralClaimedAmount'] = claimable;
        update['collateralClaimedAt'] = FieldValue.serverTimestamp();
      }

      transaction.update(loanRef, update);
    });

    final action = status == 'approved'
        ? 'approved'
        : status == 'rejected'
            ? 'rejected'
            : status;
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
    final repaymentTargetRaw =
        (latestData['totalRepayable'] ?? loan.totalRepayable) as num?;
    final repaymentTarget =
        (repaymentTargetRaw?.toDouble() ?? loanAmount).clamp(0.0, double.infinity);
    final alreadyRepaid = ((latestData['repaidAmount'] ?? loan.repaidAmount) as num)
        .toDouble()
        .clamp(0.0, repaymentTarget);

    final durationText = (latestData['duration'] ?? loan.duration).toString();
    final durationMonths = _extractDurationMonths(durationText);
    final duePerCycle = repaymentTarget / durationMonths;

    final now = DateTime.now();
    final nextDueRaw = latestData['nextDueAt'];
    final nextDueAt = nextDueRaw is Timestamp
        ? nextDueRaw.toDate()
        : now.add(const Duration(days: 30));
    final daysLate = now.difference(nextDueAt).inDays;

    final remainingAmount = (repaymentTarget - alreadyRepaid).clamp(0.0, repaymentTarget);
    if (paymentAmount <= 0 || paymentAmount > remainingAmount) {
      throw Exception('Invalid repayment amount selected.');
    }

    final nextRepaidAmount = (alreadyRepaid + paymentAmount).clamp(0.0, repaymentTarget);
    final isFullyRepaid = nextRepaidAmount >= (repaymentTarget - 0.01);

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

    final lenderId = (latestData['lenderId'] ?? loan.lenderId ?? '').toString();
    if (lenderId.isEmpty) {
      throw Exception('No lender linked to this loan yet.');
    }

    final borrowerRef = _firestore.collection('users').doc(loan.borrowerId);
    final lenderRef = _firestore.collection('users').doc(lenderId);

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

    await _firestore.runTransaction((transaction) async {
      final borrowerSnap = await transaction.get(borrowerRef);
      final lenderSnap = await transaction.get(lenderRef);
      final currentLoanSnap = await transaction.get(loanRef);

      final borrowerData = borrowerSnap.data() ?? <String, dynamic>{};
      final lenderData = lenderSnap.data() ?? <String, dynamic>{};
      final currentLoan = currentLoanSnap.data() ?? <String, dynamic>{};

      final borrowerWallet = _readBalance(borrowerData, 'wallet_balance');
      final lenderWallet = _readBalance(lenderData, 'wallet_balance');

      if (borrowerWallet < paymentAmount) {
        throw Exception('insufficient balance in wallet');
      }

      transaction.set(
        borrowerRef,
        {
          'wallet_balance': _round2(borrowerWallet - paymentAmount),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.set(
        lenderRef,
        {
          'wallet_balance': _round2(lenderWallet + paymentAmount),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (isFullyRepaid) {
        final borrowerLocked = _readBalance(borrowerData, 'locked_balance');
        final collateralAmount = (currentLoan['collateralAmount'] ?? 0).toDouble();
        final collateralLocked = currentLoan['collateralLocked'] == true;

        if (collateralLocked && collateralAmount > 0) {
          final releasable = min(collateralAmount, borrowerLocked);
          transaction.set(
            borrowerRef,
            {
              'wallet_balance': _round2((borrowerWallet - paymentAmount) + releasable),
              'locked_balance': _round2(borrowerLocked - releasable),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          loanUpdate['collateralLocked'] = false;
          loanUpdate['collateralReleasedAt'] = FieldValue.serverTimestamp();
        }
      }

      transaction.update(loanRef, loanUpdate);
    });

    await _refreshBorrowerTrustScore(loan.borrowerId);

    if (lenderId.isNotEmpty) {
      await NotificationService().sendNotification(
        targetUserId: lenderId,
        title: isFullyRepaid ? 'Loan Fully Repaid' : 'Partial Repayment Received',
        message: isFullyRepaid
            ? 'The loan of ₹${loanAmount.toStringAsFixed(0)} (total payable ₹${repaymentTarget.toStringAsFixed(0)}) to ${loan.borrowerName} was fully repaid.'
            : '${loan.borrowerName} repaid ₹${paymentAmount.toStringAsFixed(0)}. Remaining balance: ₹${(repaymentTarget - nextRepaidAmount).toStringAsFixed(0)}.',
      );
    }

    return isFullyRepaid;
  }
}
