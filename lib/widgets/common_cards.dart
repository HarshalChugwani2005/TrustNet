import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../models/loan_model.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpace.x2),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHigh : cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: isDark ? const [] : AppShadow.medium,
        border: Border.all(
          color: isDark ? scheme.outline.withValues(alpha: 0.45) : border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: AppSpace.x2 - 4),
          child,
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class TrustBadge extends StatelessWidget {
  final String label;

  const TrustBadge({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF123828) : softGreen,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user_outlined, size: 16, color: trustGreen),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: trustGreen,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class TrustScoreCard extends StatelessWidget {
  final int score;

  const TrustScoreCard({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final progress = score / 100;
    final riskLabel = score >= 80
        ? 'Low Risk'
        : score >= 65
            ? 'Moderate Risk'
            : 'Needs Improvement';

    final riskColor = score >= 80
        ? trustGreen
        : score >= 65
            ? warningAmber
            : const Color(0xFFC0392B);

    return SectionCard(
      title: 'Trust Score',
      trailing: StatusBadge(label: riskLabel, color: riskColor),
      child: Row(
        children: [
          SizedBox(
            height: 76,
            width: 76,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: const Color(0xFFD6E1F0),
                  valueColor: const AlwaysStoppedAnimation(trustGreen),
                ),
                Center(
                  child: Text(
                    '$score',
                    style:
                        const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score >= 75 ? 'Great momentum!' : 'Keep building trust',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  'Repay on time to unlock faster approvals and better terms.',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : mutedInk,
                  ),
                ),
                const SizedBox(height: 8),
                const TrustBadge(label: 'Verified User'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RiskExplainabilityPanel extends StatelessWidget {
  final UserModel? user;
  final List<LoanModel> loans;

  const RiskExplainabilityPanel({
    super.key,
    required this.user,
    required this.loans,
  });

  @override
  Widget build(BuildContext context) {
    final insight = _RiskInsight.build(user: user, loans: loans);

    return SectionCard(
      title: 'Risk Explainability',
      trailing: StatusBadge(label: insight.summaryLabel, color: insight.summaryColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            insight.summaryTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            insight.summaryBody,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : mutedInk,
            ),
          ),
          const SizedBox(height: 14),
          ...insight.signals.map(
            (signal) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RiskSignalRow(signal: signal),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: insight.tags,
          ),
        ],
      ),
    );
  }
}

class TrustGraphCard extends StatelessWidget {
  final UserModel user;
  final List<LoanModel> loans;

  const TrustGraphCard({
    super.key,
    required this.user,
    required this.loans,
  });

  @override
  Widget build(BuildContext context) {
    final insight = _TrustGraphInsight.fromData(user: user, loans: loans);

    return SectionCard(
      title: 'Trust Graph',
      trailing: StatusBadge(label: insight.reliabilityLabel, color: insight.reliabilityColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confidence propagates across your network',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            insight.summary,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : mutedInk,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrustGraphPainter(insight: insight, context: context),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(
                label: 'Network nodes: ${insight.totalNodes}',
                color: primaryBlue,
              ),
              StatusBadge(
                label: 'Lender links: ${insight.lenderNodes.length}',
                color: trustGreen,
              ),
              StatusBadge(
                label: 'Referral links: ${insight.referralNodes.length}',
                color: warningAmber,
              ),
            ],
          ),
          if (insight.lenderNodes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Lender confidence spread',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...insight.lenderNodes.take(3).map(
              (node) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _TrustSpreadRow(node: node, icon: Icons.account_balance_outlined),
              ),
            ),
          ],
          if (insight.referralNodes.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Referral confidence spread',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...insight.referralNodes.take(3).map(
              (node) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _TrustSpreadRow(node: node, icon: Icons.group_outlined),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrustSpreadRow extends StatelessWidget {
  final _TrustGraphNode node;
  final IconData icon;

  const _TrustSpreadRow({
    required this.node,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: node.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: node.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: node.color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              node.label,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '+${node.confidenceGain.toStringAsFixed(0)} conf',
            style: TextStyle(color: node.color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TrustGraphNode {
  final String id;
  final String label;
  final double confidenceGain;
  final Color color;

  const _TrustGraphNode({
    required this.id,
    required this.label,
    required this.confidenceGain,
    required this.color,
  });
}

class _TrustGraphInsight {
  final String reliabilityLabel;
  final Color reliabilityColor;
  final String summary;
  final double spreadFactor;
  final List<_TrustGraphNode> lenderNodes;
  final List<_TrustGraphNode> referralNodes;

  const _TrustGraphInsight({
    required this.reliabilityLabel,
    required this.reliabilityColor,
    required this.summary,
    required this.spreadFactor,
    required this.lenderNodes,
    required this.referralNodes,
  });

  int get totalNodes => 1 + lenderNodes.length + referralNodes.length;

  static _TrustGraphInsight fromData({required UserModel user, required List<LoanModel> loans}) {
    final completed = loans.where((loan) =>
        loan.status == 'repaid' || loan.status == 'defaulted' || loan.status == 'written_off').toList();
    final active = loans.where((loan) => loan.status == 'approved').toList();
    final reliable = completed.where((loan) => loan.status == 'repaid' && !loan.latePenaltyApplied).length;
    final defaults = completed.where((loan) =>
        loan.status == 'defaulted' || loan.status == 'written_off').length;
    final bestStreak = loans.fold<int>(
      0,
      (current, loan) => loan.onTimeStreak > current ? loan.onTimeStreak : current,
    );

    final repaymentProgressRatios = active
        .where((loan) => loan.totalRepayable > 0)
        .map((loan) => (loan.repaidAmount / loan.totalRepayable).clamp(0.0, 1.0))
        .toList();
    final partialProgress = repaymentProgressRatios.isEmpty
        ? 0.0
        : repaymentProgressRatios.reduce((a, b) => a + b) / repaymentProgressRatios.length;

    final recentRepayments = loans.where((loan) {
      final last = loan.lastRepaidAt;
      if (last == null) {
        return false;
      }
      return DateTime.now().difference(last).inDays <= 7;
    }).length;

    final completionReliability = completed.isEmpty ? 0.5 : reliable / completed.length;
    final streakSignal = (bestStreak / 6).clamp(0.0, 1.0);
    final recencySignal = recentRepayments > 0 ? 1.0 : 0.0;

    final spreadFactor = (
      (completionReliability * 0.40) +
      (partialProgress * 0.25) +
      (streakSignal * 0.20) +
      (recencySignal * 0.10) +
      ((user.trustScore / 100) * 0.15) -
      (defaults * 0.12)
    ).clamp(0.0, 1.0);

    final reliabilityLabel = spreadFactor >= 0.75
        ? 'High Network Trust'
        : spreadFactor >= 0.5
            ? 'Growing Trust'
            : 'Early Network Signal';
    final reliabilityColor = spreadFactor >= 0.75
        ? trustGreen
        : spreadFactor >= 0.5
            ? warningAmber
            : primaryBlue;

    final lenders = <String>{};
    for (final loan in loans) {
      final lenderId = loan.lenderId?.trim();
      if (lenderId != null && lenderId.isNotEmpty) {
        lenders.add(lenderId);
      }
    }

    final lenderNodes = lenders.take(6).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final lenderId = entry.value;
      final gain = (8 + (spreadFactor * 18) + math.max(0, user.trustScore - 50) * 0.08)
          .clamp(4.0, 30.0);
      return _TrustGraphNode(
        id: lenderId,
        label: _shortLabel('Lender', lenderId, index),
        confidenceGain: gain,
        color: trustGreen,
      );
    }).toList();

    final referralNodes = user.referralIds.take(6).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final referralId = entry.value;
      final gain = (5 + (spreadFactor * 14) + (user.trustScore / 100) * 4)
          .clamp(3.0, 24.0);
      return _TrustGraphNode(
        id: referralId,
        label: _shortLabel('Referral', referralId, index),
        confidenceGain: gain,
        color: warningAmber,
      );
    }).toList();

    final summary = recentRepayments > 0 || partialProgress > 0
      ? 'Latest repayment activity is boosting confidence spread across connected lenders and referrals in real time.'
      : completed.isEmpty
        ? 'Start repaying loans to activate stronger confidence spread to lenders and referrals.'
        : 'Reliable repayments increase confidence signals across connected lenders and referral links.';

    return _TrustGraphInsight(
      reliabilityLabel: reliabilityLabel,
      reliabilityColor: reliabilityColor,
      summary: summary,
      spreadFactor: spreadFactor,
      lenderNodes: lenderNodes,
      referralNodes: referralNodes,
    );
  }

  static String _shortLabel(String prefix, String id, int index) {
    final clean = id.trim();
    if (clean.length <= 8) {
      return '$prefix ${index + 1} ($clean)';
    }
    return '$prefix ${index + 1} (${clean.substring(0, 4)}...${clean.substring(clean.length - 3)})';
  }
}

class _TrustGraphPainter extends CustomPainter {
  final _TrustGraphInsight insight;
  final BuildContext context;

  const _TrustGraphPainter({required this.insight, required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.52);
    final baseRadius = math.min(size.width, size.height) * 0.28;
    final ambient = Paint()
      ..color = primaryBlue.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, baseRadius * 1.35, ambient);

    final borrowerPaint = Paint()..color = primaryBlue;
    final borrowerRadius = 16.0;
    canvas.drawCircle(center, borrowerRadius, borrowerPaint);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: 'You',
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy + 20));

    final nodes = <_PaintNode>[];
    final lenders = insight.lenderNodes;
    final referrals = insight.referralNodes;
    final lenderStep = lenders.isEmpty ? 0.0 : (math.pi * 1.1) / lenders.length;
    final referralStep = referrals.isEmpty ? 0.0 : (math.pi * 1.1) / referrals.length;

    for (var i = 0; i < lenders.length; i++) {
      final angle = math.pi * 1.95 + (lenderStep * i);
      nodes.add(_PaintNode(node: lenders[i], angle: angle, ring: 1.0));
    }
    for (var i = 0; i < referrals.length; i++) {
      final angle = math.pi * 0.95 + (referralStep * i);
      nodes.add(_PaintNode(node: referrals[i], angle: angle, ring: 0.78));
    }

    for (final paintNode in nodes) {
      final nodeDistance = baseRadius * (1.2 + (paintNode.ring * 0.5));
      final point = Offset(
        center.dx + math.cos(paintNode.angle) * nodeDistance,
        center.dy + math.sin(paintNode.angle) * nodeDistance,
      );

      final edge = Paint()
        ..color = paintNode.node.color.withValues(alpha: 0.3 + (insight.spreadFactor * 0.35))
        ..strokeWidth = 1.5 + (paintNode.node.confidenceGain / 16)
        ..style = PaintingStyle.stroke;
      canvas.drawLine(center, point, edge);

      final nodePaint = Paint()..color = paintNode.node.color;
      final nodeRadius = (5 + (paintNode.node.confidenceGain / 10)).clamp(5.0, 9.0);
      canvas.drawCircle(point, nodeRadius, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrustGraphPainter oldDelegate) {
    return oldDelegate.insight != insight;
  }
}

class _PaintNode {
  final _TrustGraphNode node;
  final double angle;
  final double ring;

  const _PaintNode({
    required this.node,
    required this.angle,
    required this.ring,
  });
}

class _RiskSignalRow extends StatelessWidget {
  final _RiskSignal signal;

  const _RiskSignalRow({required this.signal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: signal.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: signal.color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(signal.icon, color: signal.color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signal.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  signal.detail,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : mutedInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskSignal {
  final IconData icon;
  final String title;
  final String detail;
  final Color color;

  const _RiskSignal({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
  });
}

class _RiskInsight {
  final String summaryLabel;
  final Color summaryColor;
  final String summaryTitle;
  final String summaryBody;
  final List<_RiskSignal> signals;
  final List<Widget> tags;

  const _RiskInsight({
    required this.summaryLabel,
    required this.summaryColor,
    required this.summaryTitle,
    required this.summaryBody,
    required this.signals,
    required this.tags,
  });

  static _RiskInsight build({required UserModel? user, required List<LoanModel> loans}) {
    final score = user?.trustScore ?? 50;
    final profileComplete = user != null &&
        user.fullName.trim().isNotEmpty &&
        user.email.trim().isNotEmpty &&
        user.role.trim().isNotEmpty;
    final walletLinked = user?.walletAddress?.trim().isNotEmpty == true;

    final activeLoans = loans.where((loan) => loan.status == 'pending' || loan.status == 'approved').toList();
    final repaidLoans = loans.where((loan) => loan.status == 'repaid').toList();
    final lateLoans = loans.where((loan) {
      if (loan.latePenaltyApplied || loan.status == 'defaulted' || loan.status == 'written_off') {
        return true;
      }
      if (loan.status == 'approved' && loan.nextDueAt != null) {
        return loan.nextDueAt!.isBefore(DateTime.now());
      }
      return false;
    }).toList();

    final bestStreak = loans.fold<int>(0, (current, loan) => loan.onTimeStreak > current ? loan.onTimeStreak : current);
    final latestActiveLoan = activeLoans.isNotEmpty ? activeLoans.first : (loans.isNotEmpty ? loans.first : null);
    final collateralRate = latestActiveLoan == null || latestActiveLoan.amount <= 0
        ? 0.0
        : (latestActiveLoan.collateralPercent > 0
            ? latestActiveLoan.collateralPercent
            : latestActiveLoan.collateralAmount / latestActiveLoan.amount);
    final repaymentActivity = loans.where((loan) => loan.repaidAmount > 0 || loan.lastRepaidAt != null).length;

    final summaryLabel = score >= 80 && lateLoans.isEmpty
        ? 'Low Risk'
        : score >= 65 && lateLoans.isEmpty
            ? 'Moderate Risk'
            : 'Needs Review';
    final summaryColor = score >= 80 && lateLoans.isEmpty
        ? trustGreen
        : score >= 65 && lateLoans.isEmpty
            ? warningAmber
            : const Color(0xFFC0392B);

    final summaryTitle = lateLoans.isEmpty
        ? bestStreak >= 3
            ? 'Strong repayment behavior'
            : repaidLoans.isNotEmpty
                ? 'Positive payment history'
                : 'Limited repayment history'
        : 'Recent repayment risk detected';

    final summaryBody = lateLoans.isEmpty
        ? bestStreak >= 3
            ? 'The score is supported by an on-time repayment streak, verified identity, and lower collateral pressure.'
            : 'The borrower looks stable, but the system still uses identity, wallet linkage, and collateral size to judge confidence.'
        : 'Late or defaulted loans reduce confidence, so the app highlights repayment timing and collateral exposure more heavily.';

    final signals = <_RiskSignal>[
      _RiskSignal(
        icon: bestStreak >= 3 ? Icons.local_fire_department_outlined : Icons.history_outlined,
        title: 'Repayment streak',
        detail: bestStreak >= 3
            ? '$bestStreak on-time repayments in a row strengthen the score.'
            : bestStreak > 0
                ? '$bestStreak on-time repayment cycle${bestStreak == 1 ? '' : 's'} recorded.'
                : 'No on-time streak yet, so the score leans on other signals.',
        color: bestStreak >= 3 ? trustGreen : warningAmber,
      ),
      _RiskSignal(
        icon: lateLoans.isEmpty ? Icons.schedule_outlined : Icons.error_outline,
        title: 'Lateness',
        detail: lateLoans.isEmpty
            ? 'No late repayment signals are currently active.'
            : '${lateLoans.length} loan${lateLoans.length == 1 ? '' : 's'} show late or defaulted activity, which lowers trust.',
        color: lateLoans.isEmpty ? trustGreen : const Color(0xFFC0392B),
      ),
      _RiskSignal(
        icon: collateralRate <= 0.10 ? Icons.shield_outlined : Icons.warning_amber_outlined,
        title: 'Collateral ratio',
        detail: latestActiveLoan == null
            ? 'Collateral is not locked on an active loan yet.'
            : 'Current collateral is ${(collateralRate * 100).toStringAsFixed(0)}% of the loan amount, which is ${collateralRate <= 0.10 ? 'healthy' : 'cautious'} for risk control.',
        color: collateralRate <= 0.10 ? trustGreen : warningAmber,
      ),
      _RiskSignal(
        icon: repaymentActivity > 0 || activeLoans.isNotEmpty ? Icons.account_balance_wallet_outlined : Icons.hourglass_empty,
        title: 'Wallet activity',
        detail: repaymentActivity > 0 || activeLoans.isNotEmpty
            ? 'Wallet-linked lending activity is visible across ${loans.length} loan${loans.length == 1 ? '' : 's'} and repayment events.'
            : 'No wallet activity yet, so the profile has less behavioral evidence.',
        color: repaymentActivity > 0 || activeLoans.isNotEmpty ? primaryBlue : warningAmber,
      ),
      _RiskSignal(
        icon: profileComplete && walletLinked ? Icons.verified_user_outlined : Icons.badge_outlined,
        title: 'Verification level',
        detail: profileComplete && walletLinked
            ? 'Profile and wallet are linked, giving the system stronger identity assurance.'
            : profileComplete
                ? 'Profile is complete, but wallet linkage is still missing.'
                : 'Verification is partial, so the app keeps a conservative trust posture.',
        color: profileComplete && walletLinked ? trustGreen : warningAmber,
      ),
    ];

    final tags = <Widget>[
      StatusBadge(label: profileComplete ? 'Profile verified' : 'Profile incomplete', color: profileComplete ? primaryBlue : warningAmber),
      StatusBadge(label: walletLinked ? 'Wallet linked' : 'Wallet not linked', color: walletLinked ? trustGreen : warningAmber),
      StatusBadge(label: repaidLoans.isNotEmpty ? 'Repayment history' : 'No repayments yet', color: repaidLoans.isNotEmpty ? trustGreen : warningAmber),
      if (latestActiveLoan != null)
        StatusBadge(
          label: 'Active collateral ${(latestActiveLoan.collateralPercent * 100).toStringAsFixed(0)}%',
          color: latestActiveLoan.collateralPercent <= 0.10 ? trustGreen : warningAmber,
        ),
    ];

    return _RiskInsight(
      summaryLabel: summaryLabel,
      summaryColor: summaryColor,
      summaryTitle: summaryTitle,
      summaryBody: summaryBody,
      signals: signals,
      tags: tags,
    );
  }
}
