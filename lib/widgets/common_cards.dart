import 'package:flutter/material.dart';

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
    return Container(
      padding: const EdgeInsets.all(AppSpace.x2),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.medium,
        border: Border.all(color: border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: softGreen,
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
                const Text(
                  'Repay on time to unlock faster approvals and better terms.',
                  style: TextStyle(color: mutedInk),
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
