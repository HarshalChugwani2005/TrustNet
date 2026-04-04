import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/loan_model.dart';
import '../services/loan_service.dart';
import '../utils/external_link.dart';
import '../theme/app_theme.dart';
import '../widgets/common_cards.dart';

class LedgerExplorerScreen extends StatelessWidget {
  const LedgerExplorerScreen({super.key});

  Future<void> _openScanner(String txHash) async {
    // Base Sepolia Explorer URL
    await openExternalLink('https://sepolia.basescan.org/tx/$txHash');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.x3 - 4),
        children: [
          Row(
            children: [
              const Icon(Icons.hub_outlined, color: primaryBlue, size: 28),
              const SizedBox(width: 10),
              Text(
                l10n.tr('global_ledger'),
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.tr('ledger_subtitle'),
            style: const TextStyle(color: mutedInk),
          ),
          const SizedBox(height: AppSpace.x2),
          StreamBuilder<List<LoanModel>>(
            stream: LoanService().streamAllTransactions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final txs = snapshot.data ?? [];
              if (txs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(l10n.tr('no_ledger_tx')),
                  ),
                );
              }

              return Column(
                children: txs.map((tx) => _buildTxCard(context, tx)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTxCard(BuildContext context, LoanModel tx) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoLabel(context, l10n.tr('transaction_hash'), tx.txHash ?? '0xPending...'),
              StatusBadge(
                label: tx.status.toUpperCase(),
                color: tx.status == 'approved' ? trustGreen : (tx.status == 'repaid' ? primaryBlue : warningAmber),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              _infoBlock(l10n.tr('block'), '#${tx.blockNumber ?? '???'}'),
              const SizedBox(width: 24),
              _infoBlock(l10n.tr('amount'), '₹${tx.amount.toStringAsFixed(0)}'),
              const SizedBox(width: 24),
              _infoBlock(l10n.tr('trust_score'), '${tx.borrowerTrustScore}'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person_pin_circle_outlined, size: 14, color: mutedInk),
              const SizedBox(width: 4),
              Text(
                '${l10n.tr('borrower')}: ${tx.borrowerName}',
                style: const TextStyle(fontSize: 12, color: mutedInk),
              ),
              const Spacer(),
              const Icon(Icons.history_toggle_off, size: 14, color: mutedInk),
              const SizedBox(width: 4),
              Text(
                tx.createdAt != null ? '${tx.createdAt!.day}/${tx.createdAt!.month}' : l10n.tr('pending'),
                style: const TextStyle(fontSize: 12, color: mutedInk),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoLabel(BuildContext context, String label, String value) {
    return InkWell(
      onTap: () => _openScanner(value),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: mutedInk),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.open_in_new, size: 10, color: primaryBlue),
            ],
          ),
          Text(
            value.length > 20 ? '${value.substring(0, 10)}...${value.substring(value.length - 10)}' : value,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: primaryBlue, decoration: TextDecoration.underline),
          ),
        ],
      ),
    );
  }

  Widget _infoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: mutedInk),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
