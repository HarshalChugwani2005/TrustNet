import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/loan_model.dart';
import '../providers/user_provider.dart';
import '../services/loan_service.dart';
import '../services/virtual_wallet_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_cards.dart';

String _mapWalletErrorMessage(Object error, {String fallback = 'Something went wrong'}) {
  final lowered = error.toString().toLowerCase();
  if ((lowered.contains('insufficient') && lowered.contains('wallet')) ||
      lowered.contains('dart exception thrown from converted future')) {
    return 'insufficient balance in wallet';
  }
  if (lowered.contains('new borrower first-30-days limit')) {
    return 'For first 30 days, you can keep only 1 loan in process. '
        'Second request is allowed only after first loan is repaid on time.';
  }
  if (lowered.contains('new lender first-30-days limit')) {
    return 'For first 30 days, you can approve only 1 loan in process. '
        'Next approval is allowed only after borrower repayment.';
  }
  return fallback;
}

class BorrowerRequestLoanScreen extends StatefulWidget {
  final int trustScore;

  const BorrowerRequestLoanScreen({
    super.key,
    required this.trustScore,
  });

  @override
  State<BorrowerRequestLoanScreen> createState() =>
      _BorrowerRequestLoanScreenState();
}

class _BorrowerRequestLoanScreenState extends State<BorrowerRequestLoanScreen> {
  final _amountController = TextEditingController();
  final _durationValueController = TextEditingController(text: '1');
  final _purposeController = TextEditingController();
  bool _isLoading = false;
  String _durationUnit = 'month';

  String get _selectedDurationText {
    final parsedValue = int.tryParse(_durationValueController.text.trim()) ?? 1;
    final safeValue = parsedValue <= 0 ? 1 : parsedValue;
    final suffix = safeValue == 1 ? _durationUnit : '${_durationUnit}s';
    return '$safeValue $suffix';
  }

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

  static const double _baseInterestRate = 0.05;

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

  double _durationInYears(int value, String unit) {
    final safeValue = value <= 0 ? 1 : value;
    if (unit == 'day') {
      return safeValue / 365;
    }
    if (unit == 'year') {
      return safeValue.toDouble();
    }
    return safeValue / 12;
  }

  double _round2(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  Future<void> _addFunds(String userId) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Wallet Funds'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount',
            hintText: 'e.g. 2000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              Navigator.of(context).pop(parsed);
            },
            child: const Text('Add'),
          )
        ],
      ),
    );

    if (amount == null || amount <= 0) {
      return;
    }

    await VirtualWalletService().addFunds(userId: userId, amount: amount);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('₹${amount.toStringAsFixed(0)} added to your wallet.')),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _durationValueController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final amountText = _amountController.text.trim();
    final durationValueText = _durationValueController.text.trim();
    final duration = _selectedDurationText;
    final purpose = _purposeController.text.trim();

    if (amountText.isEmpty || duration.isEmpty || purpose.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    final durationValue = int.tryParse(durationValueText);
    if (durationValue == null || durationValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid duration value.')),
      );
      return;
    }

    final collateralPercent = _collateralPercentFromTrustScore(widget.trustScore);
    final collateralEstimate = amount * collateralPercent;
    if (collateralEstimate > amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collateral cannot be greater than requested amount.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      final collateralPercent = _collateralPercentFromTrustScore(user.trustScore);
      final collateralEstimate = amount * collateralPercent;
      final interestRate = _interestRateFromTrustScore(user.trustScore);
      final durationYears = _durationInYears(durationValue, _durationUnit);
      final interestAmount = _round2(amount * interestRate * durationYears);
      final totalRepayable = _round2(amount + interestAmount);
      if (user.walletBalance < collateralEstimate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('insufficient balance in wallet')),
        );
        return;
      }

      final loan = LoanModel(
        id: '',
        borrowerId: user.uid,
        borrowerName: user.fullName,
        borrowerTrustScore: user.trustScore,
        amount: amount,
        duration: duration,
        purpose: purpose,
        interestRate: interestRate,
        interestAmount: interestAmount,
        totalRepayable: totalRepayable,
      );

      await LoanService().requestLoan(loan);

      if (!mounted) return;
      
      // Simulation of blockchain mining/confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Broadcasting to ledger... Smart contract signed.')),
      );
      
      await Future<void>.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Transaction confirmed! Block mined.')),
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final friendlyMessage = _mapWalletErrorMessage(
        e,
        fallback: 'Failed to submit request',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyMessage)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;
    final amountPreview = double.tryParse(_amountController.text.trim()) ?? 0;
    final durationValuePreview =
      int.tryParse(_durationValueController.text.trim()) ?? 1;
    final collateralPercent = _collateralPercentFromTrustScore(widget.trustScore);
    final collateralPreview = amountPreview <= 0 ? 0 : amountPreview * collateralPercent;
    final interestRate = _interestRateFromTrustScore(widget.trustScore);
    final durationYears = _durationInYears(durationValuePreview, _durationUnit);
    final interestPreview = amountPreview <= 0
      ? 0
      : _round2(amountPreview * interestRate * durationYears);
    final totalRepayablePreview =
      amountPreview <= 0 ? 0 : _round2(amountPreview + interestPreview);

    return Scaffold(
      appBar: AppBar(title: const Text('Request Loan')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.x3 - 4),
        children: [
          const StatusBadge(label: 'Step 1 of 2', color: primaryBlue),
          const SizedBox(height: 10),
          TrustScoreCard(score: widget.trustScore),
          const SizedBox(height: 10),
          SectionCard(
            title: 'Virtual Wallet',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available: ₹${(user?.walletBalance ?? 0).toStringAsFixed(0)}'),
                const SizedBox(height: 4),
                Text('Locked collateral: ₹${(user?.lockedBalance ?? 0).toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                Text(
                  'Collateral estimate: ₹${collateralPreview.toStringAsFixed(0)} (${(collateralPercent * 100).toStringAsFixed(0)}%)',
                  style: const TextStyle(color: mutedInk),
                ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: user == null ? null : () => _addFunds(user.uid),
                  child: const Text('Add Funds to Wallet'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.x2 - 2),
          const Text(
            'Loan Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter clear details so lenders can review quickly.',
            style: TextStyle(color: mutedInk),
          ),
          const SizedBox(height: AppSpace.x2 - 4),
          TextField(
            controller: _amountController,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Loan amount',
              helperText: 'Example: 5000',
              prefixIcon: const Icon(Icons.currency_rupee_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _durationValueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Duration Value',
                    prefixIcon: const Icon(Icons.calendar_month_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _durationUnit,
                  decoration: InputDecoration(
                    labelText: 'Duration Unit',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'day', child: Text('Days')),
                    DropdownMenuItem(value: 'month', child: Text('Months')),
                    DropdownMenuItem(value: 'year', child: Text('Years')),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _durationUnit = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose realistic repayment time',
            style: TextStyle(color: mutedInk, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _purposeController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Purpose',
              hintText: 'Describe why you need this loan',
              helperText: 'Short and specific reasons are trusted faster',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Repayment Summary',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Principal: ₹${amountPreview.toStringAsFixed(0)}'),
                const SizedBox(height: 4),
                Text('Base interest: ${(_baseInterestRate * 100).toStringAsFixed(0)}% p.a.'),
                const SizedBox(height: 4),
                Text('Trust-adjusted rate: ${(interestRate * 100).toStringAsFixed(0)}% p.a.'),
                const SizedBox(height: 4),
                Text(
                  'Interest for $_selectedDurationText: ₹${interestPreview.toStringAsFixed(0)}',
                  style: const TextStyle(color: mutedInk),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total payable: ₹${totalRepayablePreview.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.x2),
          FilledButton(
            onPressed: _isLoading ? null : _submitRequest,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit Loan Request'),
            ),
          ),
        ],
      ),
    );
  }
}

class LenderLoanRequestsScreen extends StatelessWidget {
  const LenderLoanRequestsScreen({super.key});

  List<Widget> _borrowerBadges(LoanModel loan) {
    final badges = <Widget>[const StatusBadge(label: 'Profile Verified', color: primaryBlue)];
    if (loan.collateralLocked || loan.collateralAmount > 0) {
      badges.add(const StatusBadge(label: 'Collateral Secured', color: warningAmber));
    }
    if (loan.borrowerTrustScore >= 80) {
      badges.add(const StatusBadge(label: 'High Trust', color: trustGreen));
    }
    return badges;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loan Requests')),
      body: StreamBuilder<List<LoanModel>>(
        stream: LoanService().streamPendingLoans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                _mapWalletErrorMessage(
                  snapshot.error!,
                  fallback: 'Unable to load loan requests',
                ),
              ),
            );
          }

          final loans = snapshot.data ?? [];
          if (loans.isEmpty) {
            return const Center(
              child: Text(
                'No pending loan requests found.',
                style: TextStyle(color: mutedInk),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpace.x2),
            children: [
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusBadge(label: 'All Requests', color: primaryBlue),
                  StatusBadge(label: 'Pending Review', color: warningAmber),
                ],
              ),
              const SizedBox(height: AppSpace.x2 - 4),
              ...loans.map(
                (item) => InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LenderBorrowerDetailsScreen(loan: item),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardSurface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: border),
                      boxShadow: AppShadow.light,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.borrowerName,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w700),
                              ),
                            ),
                            StatusBadge(
                              label: '${item.borrowerTrustScore}',
                              color: item.borrowerTrustScore >= 75
                                  ? trustGreen
                                  : warningAmber,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _borrowerBadges(item),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Amount: ₹${item.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Interest: ₹${item.interestAmount.toStringAsFixed(0)} at ${(item.interestRate * 100).toStringAsFixed(0)}% p.a.',
                          style: const TextStyle(color: mutedInk),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total payable: ₹${item.totalRepayable.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Collateral: ₹${item.collateralAmount.toStringAsFixed(0)} (${(item.collateralPercent * 100).toStringAsFixed(0)}%)',
                          style: const TextStyle(color: mutedInk),
                        ),
                        const SizedBox(height: 2),
                        Text('Purpose: ${item.purpose}'),
                        const SizedBox(height: 10),
                        const Row(
                          children: [
                            Icon(Icons.open_in_new_rounded,
                                size: 16, color: primaryBlue),
                            SizedBox(width: 6),
                            Text(
                              'Review borrower details',
                              style: TextStyle(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class LenderBorrowerDetailsScreen extends StatefulWidget {
  final LoanModel loan;

  const LenderBorrowerDetailsScreen({
    super.key,
    required this.loan,
  });

  @override
  State<LenderBorrowerDetailsScreen> createState() =>
      _LenderBorrowerDetailsScreenState();
}

class _LenderBorrowerDetailsScreenState
    extends State<LenderBorrowerDetailsScreen> {
  bool _isLoading = false;

  List<Widget> _borrowerBadges() {
    final badges = <Widget>[const StatusBadge(label: 'Profile Verified', color: primaryBlue)];
    if (widget.loan.collateralLocked || widget.loan.collateralAmount > 0) {
      badges.add(const StatusBadge(label: 'Collateral Secured', color: warningAmber));
    }
    if (widget.loan.borrowerTrustScore >= 80) {
      badges.add(const StatusBadge(label: 'High Trust', color: trustGreen));
    }
    return badges;
  }

  Future<void> _addFunds(String userId) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Wallet Funds'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount',
            hintText: 'e.g. 5000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              Navigator.of(context).pop(parsed);
            },
            child: const Text('Add'),
          )
        ],
      ),
    );

    if (amount == null || amount <= 0) {
      return;
    }

    await VirtualWalletService().addFunds(userId: userId, amount: amount);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('₹${amount.toStringAsFixed(0)} added to your wallet.')),
    );
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final lender = userProvider.currentUser;
      final lenderId = lender?.uid;

      if (lenderId == null || lenderId.isEmpty) {
        throw StateError('Unable to determine the current lender.');
      }

      if (status == 'approved' && (lender?.walletBalance ?? 0) < widget.loan.amount) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('insufficient balance in wallet')),
        );
        return;
      }
      
      await LoanService().updateLoanStatus(
        widget.loan, 
        status, 
        lenderId: lenderId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'approved'
              ? 'Approved ${widget.loan.borrowerName}. Funds transferred.'
              : 'Rejected ${widget.loan.borrowerName}. Borrower notified.'),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const LenderReturnsScreen(), // Navigate away after action
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = _mapWalletErrorMessage(
        e,
        fallback: 'Unable to update loan status',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lender = Provider.of<UserProvider>(context).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Borrower Details')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.x3 - 4),
        children: [
          const StatusBadge(label: 'Step 2 of 2', color: primaryBlue),
          const SizedBox(height: 10),
          TrustScoreCard(score: widget.loan.borrowerTrustScore),
          const SizedBox(height: AppSpace.x2 - 2),
          SectionCard(
            title: widget.loan.borrowerName,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _borrowerBadges(),
                ),
                const SizedBox(height: 8),
                Text('Requested amount: ₹${widget.loan.amount.toStringAsFixed(0)}'),
                const SizedBox(height: 6),
                Text(
                  'Base interest: 5% p.a. • Applied rate: ${(widget.loan.interestRate * 100).toStringAsFixed(0)}% p.a.',
                  style: const TextStyle(color: mutedInk),
                ),
                const SizedBox(height: 6),
                Text(
                  'Interest for ${widget.loan.duration}: ₹${widget.loan.interestAmount.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 6),
                Text(
                  'Total borrower payable: ₹${widget.loan.totalRepayable.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Collateral locked: ₹${widget.loan.collateralAmount.toStringAsFixed(0)} (${(widget.loan.collateralPercent * 100).toStringAsFixed(0)}%)',
                ),
                const SizedBox(height: 6),
                Text('Duration: ${widget.loan.duration}'),
                const SizedBox(height: 6),
                Text('Purpose: ${widget.loan.purpose}'),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.x2 - 2),
          SectionCard(
            title: 'Lender Wallet',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available balance: ₹${(lender?.walletBalance ?? 0).toStringAsFixed(0)}'),
                const SizedBox(height: 6),
                Text('Required for disbursement: ₹${widget.loan.amount.toStringAsFixed(0)}'),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: lender == null ? null : () => _addFunds(lender.uid),
                  child: const Text('Add Funds to Wallet'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.x2 - 2),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _isLoading ? null : () => _updateStatus('rejected'),
                  child: const Text('Reject Loan'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _isLoading ? null : () => _updateStatus('approved'),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Text('Approve Loan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LenderReturnsScreen extends StatelessWidget {
  const LenderReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Track Repayments & Returns')),
      body: StreamBuilder<List<LoanModel>>(
        stream: LoanService().streamLenderLoans(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final loans = snapshot.data ?? [];
          final activeLoans = loans.where((l) => l.status == 'approved').toList();
          final repaidLoans = loans.where((l) => l.status == 'repaid').toList();
          
          final totalInvested = activeLoans.fold<double>(0, (sum, loan) => sum + loan.amount);
            final totalPrincipalRepaid =
              repaidLoans.fold<double>(0, (sum, loan) => sum + loan.amount);
            final totalReturnsReceived =
              repaidLoans.fold<double>(0, (sum, loan) => sum + loan.repaidAmount);
            final totalInterestEarned =
              (totalReturnsReceived - totalPrincipalRepaid).clamp(0.0, double.infinity);

          return ListView(
            padding: const EdgeInsets.all(AppSpace.x3 - 4),
            children: [
              SectionCard(
                title: 'Investment Summary',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active Investments: ₹${totalInvested.toStringAsFixed(0)}'),
                    const SizedBox(height: 6),
                    Text('Completed principal: ₹${totalPrincipalRepaid.toStringAsFixed(0)}'),
                    const SizedBox(height: 6),
                    Text('Interest earned: ₹${totalInterestEarned.toStringAsFixed(0)}'),
                    const SizedBox(height: 6),
                    Text('Total Returns Received: ₹${totalReturnsReceived.toStringAsFixed(0)}'),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: loans.isEmpty ? 0 : repaidLoans.length / loans.length, 
                        minHeight: 9,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Collection rate: ${(loans.isEmpty ? 0 : (repaidLoans.length / loans.length * 100)).toStringAsFixed(0)}%',
                      style: const TextStyle(color: mutedInk),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: 'Portfolio Details',
                child: loans.isEmpty
                    ? const Text('No investment history yet.', style: TextStyle(color: mutedInk))
                    : Column(
                        children: loans.map((loan) {
                          final isRepaid = loan.status == 'repaid';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              isRepaid ? Icons.check_circle : Icons.payments_rounded, 
                              color: isRepaid ? trustGreen : primaryBlue,
                            ),
                            title: Text('₹${loan.amount.toStringAsFixed(0)} - ${loan.borrowerName}'),
                            subtitle: Text(
                              '${loan.duration} • ${loan.status.toUpperCase()} • Payable ₹${loan.totalRepayable.toStringAsFixed(0)}',
                            ),
                            trailing: isRepaid
                                ? const StatusBadge(label: 'Repaid', color: trustGreen)
                                : TextButton(
                                    onPressed: () async {
                                      try {
                                        await LoanService().updateLoanStatus(
                                          loan,
                                          'defaulted',
                                          lenderId: user.uid,
                                        );
                                        if (!context.mounted) {
                                          return;
                                        }
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Marked ${loan.borrowerName} as defaulted. Collateral claimed.',
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        if (!context.mounted) {
                                          return;
                                        }
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Could not mark default: $e')),
                                        );
                                      }
                                    },
                                    child: const Text('Mark Default'),
                                  ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class LoanDetailsScreen extends StatelessWidget {
  const LoanDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Loan Details')),
      body: StreamBuilder<List<LoanModel>>(
        stream: LoanService().streamBorrowerLoans(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final loans = snapshot.data ?? [];
          final activeLoans = loans.where((l) => l.status != 'repaid').toList();
          final activeLoan = activeLoans.isNotEmpty ? activeLoans.first : (loans.isNotEmpty ? loans.first : null);

          if (activeLoan == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "You don't have any loan history to view details for right now.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: mutedInk, fontSize: 16),
                ),
              ),
            );
          }

          // Extract digits for duration to split EMI equally
          final durationMatch = RegExp(r'\d+').firstMatch(activeLoan.duration);
          final durationMonths = durationMatch != null ? int.parse(durationMatch.group(0)!) : 4;
          
            final totalPayable = activeLoan.totalRepayable > 0
              ? activeLoan.totalRepayable
              : activeLoan.amount;
            final emiAmount = totalPayable / durationMonths;
          final isRepaid = activeLoan.status == 'repaid';
          
          // Generate realistic dates scaling into the future
          final baseDate = activeLoan.createdAt ?? DateTime.now();
          final schedule = List.generate(durationMonths, (index) {
             final date = baseDate.add(Duration(days: 30 * (index + 1)));
             final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
             final dateStr = '${date.day} ${months[date.month - 1]} ${date.year}';
             return (dateStr, '₹${emiAmount.toStringAsFixed(0)}', isRepaid);
          });

          return ListView(
            padding: const EdgeInsets.all(AppSpace.x3 - 4),
            children: [
              SectionCard(
                title: 'Contract Info',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount: ₹${activeLoan.amount.toStringAsFixed(0)}'),
                    const SizedBox(height: 6),
                    Text(
                      'Interest: ₹${activeLoan.interestAmount.toStringAsFixed(0)} at ${(activeLoan.interestRate * 100).toStringAsFixed(0)}% p.a.',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total payable: ₹${totalPayable.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text('Duration: ${activeLoan.duration}'),
                    const SizedBox(height: 6),
                    Text(
                      'Collateral: ₹${activeLoan.collateralAmount.toStringAsFixed(0)} (${(activeLoan.collateralPercent * 100).toStringAsFixed(0)}%)',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'TX Hash: ${activeLoan.txHash?.substring(0, 16)}...',
                      style: const TextStyle(fontFamily: 'monospace', color: primaryBlue, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        StatusBadge(
                          label: activeLoan.status.toUpperCase(), 
                          color: activeLoan.status == 'pending' ? warningAmber : trustGreen,
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.x2 - 2),
              SectionCard(
                title: 'Repayment Timeline',
                child: Column(
                  children: schedule
                      .map(
                        (entry) => Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Icon(
                                  entry.$3
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: entry.$3 ? trustGreen : const Color(0xFF9AA9BE),
                                ),
                                if (entry != schedule.last)
                                  Container(
                                    height: 38,
                                    width: 2,
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    color: const Color(0xFFD5E0EF),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(entry.$1,
                                        style:
                                            const TextStyle(fontWeight: FontWeight.w700, color: ink)),
                                    Text(entry.$2),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class RepaymentScreen extends StatefulWidget {
  const RepaymentScreen({super.key});

  @override
  State<RepaymentScreen> createState() => _RepaymentScreenState();
}

class _RepaymentScreenState extends State<RepaymentScreen> {
  bool _isPaying = false;
  final Map<String, double> _selectedPayments = {};

  Future<void> _payLoan(LoanModel loan, double amountToPay) async {
    setState(() => _isPaying = true);
    try {
      final isFullyRepaid = await LoanService().repayLoan(
        loan,
        paymentAmount: amountToPay,
      );
      _selectedPayments.remove(loan.id);
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: trustGreen, size: 42),
          title: const Text('Payment successful'),
          content: Text(
            isFullyRepaid
                ? 'Loan closed successfully. Trust score updated with this repayment.'
                : '₹${amountToPay.toStringAsFixed(0)} paid successfully. Trust score increased gradually based on repayment progress.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = _mapWalletErrorMessage(
        e,
        fallback: 'Unable to process repayment',
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Repayment')),
      body: StreamBuilder<List<LoanModel>>(
        stream: LoanService().streamBorrowerLoans(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final loans = snapshot.data ?? [];
          final activeLoans = loans.where((l) => l.status == 'approved').toList();

          if (activeLoans.isEmpty) {
            return const Center(child: Text('No active loans require repayment.', style: TextStyle(color: mutedInk)));
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpace.x3 - 4),
            children: activeLoans.map((loan) {
              final double payableAmount =
                (loan.totalRepayable > 0 ? loan.totalRepayable : loan.amount).toDouble();
              final double repaidAmount = loan.repaidAmount.clamp(0.0, payableAmount).toDouble();
              final double remainingAmount = (payableAmount - repaidAmount)
                .clamp(0.0, payableAmount)
                .toDouble();
              final double minPayment = remainingAmount < 1 ? remainingAmount : 1.0;
              final double selectedAmount = remainingAmount <= 0
                  ? 0.0
                  : (_selectedPayments[loan.id] ?? remainingAmount)
                      .clamp(minPayment, remainingAmount)
                      .toDouble();
              final double progress = payableAmount <= 0
                  ? 0.0
                : (repaidAmount / payableAmount).clamp(0.0, 1.0).toDouble();

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SectionCard(
                  title: 'Repay Loan',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${payableAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: ink),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Principal: ₹${loan.amount.toStringAsFixed(0)} • Interest: ₹${loan.interestAmount.toStringAsFixed(0)}',
                        style: const TextStyle(color: mutedInk),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Repaid: ₹${repaidAmount.toStringAsFixed(0)} • Remaining: ₹${remainingAmount.toStringAsFixed(0)}',
                        style: const TextStyle(color: mutedInk),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(value: progress, minHeight: 9),
                      ),
                      const SizedBox(height: 8),
                      Text('Purpose: ${loan.purpose}', style: const TextStyle(color: mutedInk)),
                      const SizedBox(height: 12),
                      if (remainingAmount > 1) ...[
                        Text(
                          'Pay now: ₹${selectedAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Slider(
                          value: selectedAmount,
                          min: 1,
                          max: remainingAmount,
                          divisions: math.min(100, remainingAmount.round()),
                          label: selectedAmount.toStringAsFixed(0),
                          onChanged: _isPaying
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedPayments[loan.id] = value;
                                  });
                                },
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          FilledButton(
                            onPressed: _isPaying || remainingAmount <= 0
                                ? null
                                : () => _payLoan(loan, selectedAmount),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                              child: _isPaying 
                                 ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(color: Colors.white, strokeWidth:2))
                                 : Text('Pay ₹${selectedAmount.toStringAsFixed(0)}'),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
