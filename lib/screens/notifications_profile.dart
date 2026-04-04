import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/notification_model.dart';
import '../providers/user_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_cards.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    if (user == null) {
      return const Center(child: Text('Please log in.'));
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.x2 + 2),
        children: [
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Stay updated with approvals, reminders, and security alerts.',
            style: TextStyle(color: mutedInk),
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
                return const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(
                    child: Text('You have no notifications right now.', style: TextStyle(color: mutedInk)),
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

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;

    if (userProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final name = user?.fullName ?? 'User Name';
    final role = user?.role ?? 'Guest';
    final trustScore = user?.trustScore ?? 74;
    final emailInfo = user?.email ?? 'Not available';
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
                    const Text('Verified User', style: TextStyle(color: mutedInk)),
                  ],
                ),
              ),
              const TrustBadge(label: 'Low Risk'),
            ],
          ),
          const SizedBox(height: AppSpace.x2),
          TrustScoreCard(score: trustScore),
          const SizedBox(height: AppSpace.x2 - 2),
          SectionCard(
            title: 'Account',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 18, color: primaryBlue),
                    const SizedBox(width: 8),
                    Text('Email: $emailInfo'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.switch_account_outlined,
                        size: 18, color: primaryBlue),
                    const SizedBox(width: 8),
                    Text('Role: ${role.toUpperCase()}'),
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
                          const Text('Wallet Address'),
                          const SizedBox(height: 4),
                          Text(
                            walletAddress == null
                                ? 'Wallet not linked yet'
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
                        tooltip: 'Copy wallet address',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: walletAddress));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Wallet address copied')),
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
          const SectionCard(
            title: 'Trust & History',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TrustBadge(label: '100% Secure & Transparent'),
                SizedBox(height: 10),
                Text('Phone: +91 98xxxxxx76'),
                SizedBox(height: 6),
                Text('2 loans completed on time'),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.x2 - 2),
          const SectionCard(
            title: 'Settings',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.notifications_active_outlined),
                  title: Text('Notification Preferences'),
                  subtitle: Text('Manage reminders and updates'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.security_outlined),
                  title: Text('Privacy & Security'),
                  subtitle: Text('Device and account protection'),
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
            label: const Text('Logout'),
          )
        ],
      ),
    );
  }
}
