import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../l10n/app_localizations.dart';
import '../models/notification_model.dart';
import '../providers/user_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_cards.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    if (user == null) {
      return Center(child: Text(l10n.tr('please_log_in')));
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.x2 + 2),
        children: [
          Text(
            l10n.tr('notifications_title'),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.tr('notifications_subtitle'),
            style: const TextStyle(color: mutedInk),
          ),
          const SizedBox(height: AppSpace.x2),
          StreamBuilder<List<NotificationModel>>(
            stream: NotificationService().streamUserNotifications(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(
                    child: Text(l10n.tr('no_notifications'), style: const TextStyle(color: mutedInk)),
                  ),
                );
              }

              return Column(
                children: notifications.map(
                  (item) {
                    final isApprove = item.title.toLowerCase().contains('approve');
                    final isRepaid = item.title.toLowerCase().contains('repaid') || item.title.toLowerCase().contains('received');
                    final iconColor = isApprove || isRepaid ? trustGreen : primaryBlue;
                    final iconData = isApprove || isRepaid ? Icons.check_circle_outline : Icons.info_outline;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardSurface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: border.withValues(alpha: 0.7)),
                        boxShadow: AppShadow.light,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Icon(iconData, color: iconColor),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      timeago.format(item.createdAt),
                                      style: const TextStyle(color: mutedInk, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(item.message, style: const TextStyle(color: mutedInk)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _shortWalletAddress(String address) {
    if (address.length <= 14) {
      return address;
    }

    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  int _countOnTimeCompletedLoans(QuerySnapshot<Map<String, dynamic>> snapshot) {
    var count = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString().toLowerCase();
      if (status != 'repaid') {
        continue;
      }

      final events = data['repaymentEvents'];
      var hasLateEvent = false;
      if (events is List) {
        for (final rawEvent in events) {
          if (rawEvent is! Map) {
            continue;
          }
          final eventType = (rawEvent['eventType'] ?? '').toString();
          if (eventType.startsWith('late') || eventType == 'missed_cycle') {
            hasLateEvent = true;
            break;
          }
        }
      }

      if (!hasLateEvent) {
        count += 1;
      }
    }

    return count;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;

    if (userProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final name = user?.fullName ?? l10n.tr('user_name');
    final role = user?.role ?? l10n.tr('guest');
    final trustScore = user?.trustScore ?? 74;
    final emailInfo = user?.email ?? l10n.tr('not_available');
    final phoneInfo = (user?.phone ?? '').isEmpty ? l10n.tr('not_available') : user!.phone;
    final walletAddress = user?.walletAddress;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.x3 - 4),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: softBlue,
                child: Icon(Icons.person, size: 40, color: primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.tr('verified_user'), style: const TextStyle(color: mutedInk)),
                  ],
                ),
              ),
              TrustBadge(label: l10n.tr('low_risk')),
            ],
          ),
          const SizedBox(height: AppSpace.x2),
          TrustScoreCard(score: trustScore),
          const SizedBox(height: AppSpace.x2 - 2),
          SectionCard(
            title: l10n.tr('account'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 18, color: primaryBlue),
                    const SizedBox(width: 8),
                    Text('${l10n.tr('email')}: $emailInfo'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.switch_account_outlined,
                        size: 18, color: primaryBlue),
                    const SizedBox(width: 8),
                    Text('${l10n.tr('role')}: ${role.toUpperCase()}'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined,
                        size: 18, color: primaryBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.tr('wallet_address')),
                          const SizedBox(height: 4),
                          Text(
                            walletAddress == null
                                ? l10n.tr('wallet_not_linked')
                                : _shortWalletAddress(walletAddress),
                            style: TextStyle(
                              color: walletAddress == null ? mutedInk : ink,
                              fontFamily: walletAddress == null ? null : 'monospace',
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (walletAddress != null)
                      IconButton(
                        tooltip: l10n.tr('copy_wallet_address'),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: walletAddress));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.tr('wallet_copied'))),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.x2 - 2),
          SectionCard(
            title: l10n.tr('trust_history'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TrustBadge(label: l10n.tr('secure_transparent')),
                const SizedBox(height: 10),
                Text('${l10n.tr('phone')}: $phoneInfo'),
                const SizedBox(height: 6),
                if (user == null)
                  Text('0 ${l10n.tr('loans_completed_on_time')}')
                else
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('loans')
                        .where('borrowerId', isEqualTo: user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final data = snapshot.data;
                      final count = data == null ? 0 : _countOnTimeCompletedLoans(data);
                      return Text('$count ${l10n.tr('loans_completed_on_time')}');
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.x2 - 2),
          SectionCard(
            title: l10n.tr('settings'),
            child: Column(
              children: [
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: user == null
                      ? const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty()
                      : FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data();
                    final notificationsEnabled =
                        data?['notificationsEnabled'] is bool
                            ? data!['notificationsEnabled'] as bool
                            : true;

                    return SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.notifications_active_outlined),
                      title: Text(l10n.tr('notification_preferences')),
                      subtitle: Text(l10n.tr('toggle_notifications')),
                      value: notificationsEnabled,
                      onChanged: user == null
                          ? null
                          : (value) async {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .set(
                                {'notificationsEnabled': value},
                                SetOptions(merge: true),
                              );
                            },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.x2),
          OutlinedButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
            },
            icon: const Icon(Icons.logout),
            label: Text(l10n.tr('logout')),
          )
        ],
      ),
    );
  }
}
