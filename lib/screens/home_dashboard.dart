import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/loan_model.dart';
import '../providers/user_provider.dart';
import '../services/loan_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_cards.dart';
import 'loan_screens.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;
    
    if (userProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final role = user?.role ?? 'borrower';
    final trustScore = user?.trustScore ?? 50;
    final borrowerName = user?.fullName;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.x3 - 4, AppSpace.x2, AppSpace.x3 - 4,
            AppSpace.x3),
        children: [
          if (borrowerName != null && borrowerName.trim().isNotEmpty)
            Text(
              'Welcome, $borrowerName',
              style: const TextStyle(color: mutedInk, fontSize: 15),
            ),
          if (borrowerName != null && borrowerName.trim().isNotEmpty)
            const SizedBox(height: AppSpace.x1 - 2),
          const Text(
            'Decentralized Hub',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Transparent, P2P lending on the global ledger.',
            style: TextStyle(color: mutedInk),
          ),
          const SizedBox(height: AppSpace.x2),
          TrustScoreCard(score: trustScore),
          const SizedBox(height: AppSpace.x2 - 2),
          SectionCard(
            title: role == 'borrower' ? 'Borrower Wallet' : 'Lender Wallet',
            trailing: const TrustBadge(label: 'Virtual Money'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available balance: ₹${(user?.walletBalance ?? 0).toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Locked collateral: ₹${(user?.lockedBalance ?? 0).toStringAsFixed(0)}',
                  style: const TextStyle(color: mutedInk),
                ),
                const SizedBox(height: 6),
                Text(
                  role == 'borrower'
                      ? 'Collateral is locked as security deposit until repayment or default resolution.'
                      : 'Your wallet is used to fund approved loans and receives repayments/collateral claims.',
                  style: const TextStyle(color: mutedInk),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.x2 - 2),
          SectionCard(
            title: role == 'borrower' ? 'Active Loans' : 'Active Investments',
            child: user == null
                ? const SizedBox.shrink()
                : StreamBuilder<List<LoanModel>>(
                    stream: role == 'borrower'
                        ? LoanService().streamBorrowerLoans(user.uid)
                        : LoanService().streamLenderLoans(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final loans = snapshot.data ?? [];
                      if (loans.isEmpty) {
                        return Text(
                          role == 'borrower'
                              ? 'No active loans. Request one to quick-start.'
                              : 'No active investments globally.',
                          style: const TextStyle(color: mutedInk),
                        );
                      }

                      final recentLoans = loans.take(3).toList();
                      return Column(
                        children: recentLoans.map((loan) {
                          final isLast = loan == recentLoans.last;
                          return Column(
                            children: [
                              _loanTile(
                                role == 'borrower' ? 'TrustNet Loan' : loan.borrowerName,
                                '₹${loan.amount.toStringAsFixed(0)} • ${loan.duration}',
                                loan.status.substring(0, 1).toUpperCase() +
                                    loan.status.substring(1),
                              ),
                              if (!isLast) const Divider(height: 20),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSpace.x2 - 2),
          SectionCard(
            title: 'Quick Actions',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (role == 'borrower')
                  _actionChip(
                    icon: Icons.add_card,
                    label: 'Request Loan',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BorrowerRequestLoanScreen(
                            trustScore: trustScore,
                          ),
                        ),
                      );
                    },
                  ),
                if (role == 'borrower')
                  _actionChip(
                    icon: Icons.info_outline,
                    label: 'Loan Details',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LoanDetailsScreen(),
                        ),
                      );
                    },
                  ),
                if (role == 'borrower')
                  _actionChip(
                    icon: Icons.payments_outlined,
                    label: 'Repayment',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RepaymentScreen(),
                        ),
                      );
                    },
                  ),
                if (role != 'borrower')
                  _actionChip(
                    icon: Icons.list_alt_outlined,
                    label: 'View Loan Requests',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LenderLoanRequestsScreen(),
                        ),
                      );
                    },
                  ),
                if (role != 'borrower')
                  _actionChip(
                    icon: Icons.trending_up_outlined,
                    label: 'Track Returns',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LenderReturnsScreen(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.x2 - 2),
          SectionCard(
            title: 'Protocol Explorer',
            trailing: const TrustBadge(label: 'Public Ledger'),
            child: StreamBuilder<List<LoanModel>>(
              stream: LoanService().streamAllTransactions(),
              builder: (context, snapshot) {
                final txs = snapshot.data ?? [];
                if (txs.isEmpty) {
                  return const Text('Protocol is live. Awaiting transactions...',
                      style: TextStyle(color: mutedInk));
                }
                return Column(
                  children: txs.take(3).map((tx) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: softBlue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.hub_outlined, size: 12, color: primaryBlue),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${tx.txHash?.substring(0, 12)}...',
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: primaryBlue),
                                ),
                                Text(
                                  '${tx.borrowerName} signed ₹${tx.amount.toStringAsFixed(0)} contract',
                                  style: const TextStyle(fontSize: 12, color: mutedInk),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpace.x2 - 6),
          Row(
            children: [
              const Icon(Icons.security_outlined, color: trustGreen, size: 18),
              const SizedBox(width: 6),
              Text(
                role == 'borrower' ? 'Verified borrower mode' : 'Verified lender mode',
                style: const TextStyle(
                  color: trustGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            role == 'borrower'
                ? 'Borrower mode active: request -> wait approval -> repay to improve trust.'
                : 'Lender mode active: review borrowers -> approve/reject -> track returns.',
            style: const TextStyle(color: mutedInk),
          )
        ],
      ),
    );
  }

  Widget _loanTile(String title, String subtitle, String status) {
    final color = status == 'Approved' ? trustGreen : warningAmber;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: softBlue,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Icon(Icons.receipt_long, color: primaryBlue),
        ),
        const SizedBox(width: AppSpace.x2 - 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(color: mutedInk)),
            ],
          ),
        ),
        StatusBadge(label: status, color: color),
      ],
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 155,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: cardSurface,
          border: Border.all(color: border),
          boxShadow: AppShadow.light,
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryBlue),
            const SizedBox(width: 8),
            Expanded(child: Text(label, maxLines: 2)),
          ],
        ),
      ),
    );
  }
}
