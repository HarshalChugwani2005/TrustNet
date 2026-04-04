import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/loan_model.dart';
import '../providers/user_provider.dart';
import '../services/loan_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_cards.dart';

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
  final _durationController = TextEditingController();
  final _purposeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _durationController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final amountText = _amountController.text.trim();
    final duration = _durationController.text.trim();
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

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      final loan = LoanModel(
        id: '',
        borrowerId: user.uid,
        borrowerName: user.fullName,
        borrowerTrustScore: user.trustScore,
        amount: amount,
        duration: duration,
        purpose: purpose,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Loan')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.x3 - 4),
        children: [
          const StatusBadge(label: 'Step 1 of 2', color: primaryBlue),
          const SizedBox(height: 10),
          TrustScoreCard(score: widget.trustScore),
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
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Loan amount',
              helperText: 'Example: 5000',
              prefixIcon: const Icon(Icons.currency_rupee_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _durationController,
            decoration: InputDecoration(
              labelText: 'Duration',
              hintText: 'e.g., 3 months',
              helperText: 'Choose realistic repayment time',
              prefixIcon: const Icon(Icons.calendar_month_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
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
            return Center(child: Text('Error: ${snapshot.error}'));
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
                        Text(
                          'Amount: ₹${item.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: ink),
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

  Future<void> _updateStatus(String status) async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final lenderId = status == 'approved' ? userProvider.currentUser?.uid : null;
      
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Text('Requested amount: ₹${widget.loan.amount.toStringAsFixed(0)}'),
                const SizedBox(height: 6),
                Text('Duration: ${widget.loan.duration}'),
                const SizedBox(height: 6),
                Text('Purpose: ${widget.loan.purpose}'),
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
          final totalRepaid = repaidLoans.fold<double>(0, (sum, loan) => sum + loan.amount);

          // Simplified interest calculation (5% interest)
          final actualReturns = totalRepaid * 1.05;

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
                    Text('Completed (Repaid): ₹${totalRepaid.toStringAsFixed(0)}'),
                    const SizedBox(height: 6),
                    Text('Total Returns Received: ₹${actualReturns.toStringAsFixed(0)}'),
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
                            subtitle: Text('${loan.duration} • ${loan.status.toUpperCase()}'),
                            trailing: isRepaid 
                              ? const StatusBadge(label: 'Repaid', color: trustGreen)
                              : const StatusBadge(label: 'Active', color: primaryBlue),
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
          
          final emiAmount = activeLoan.amount / durationMonths;
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
                    Text('Duration: ${activeLoan.duration}'),
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

  Future<void> _payLoan(LoanModel loan) async {
    setState(() => _isPaying = true);
    try {
      await LoanService().repayLoan(loan);
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: trustGreen, size: 42),
          title: const Text('Payment successful'),
          content: const Text(
            'Your payment was recorded. +5 Trust Score added!',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // go back to dashboard
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SectionCard(
                  title: 'Repay Loan',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${loan.amount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: ink),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: const LinearProgressIndicator(value: 0.0, minHeight: 9),
                      ),
                      const SizedBox(height: 8),
                      Text('Purpose: ${loan.purpose}', style: const TextStyle(color: mutedInk)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          FilledButton(
                            onPressed: _isPaying ? null : () => _payLoan(loan),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                              child: _isPaying 
                                 ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(color: Colors.white, strokeWidth:2))
                                 : const Text('Pay Now in Full'),
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
