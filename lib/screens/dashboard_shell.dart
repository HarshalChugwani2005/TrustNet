import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'home_dashboard.dart';
import 'notifications_profile.dart';
import 'ledger_explorer.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = [
      const HomeDashboardScreen(),
      const LedgerExplorerScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey<int>(_index),
          child: pages[_index],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), label: l10n.tr('home')),
          NavigationDestination(
            icon: const Icon(Icons.hub_outlined),
            label: l10n.tr('ledger'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.notifications_none_rounded),
            label: l10n.tr('notifications'),
          ),
          NavigationDestination(icon: const Icon(Icons.person_outline), label: l10n.tr('profile')),
        ],
      ),
    );
  }
}
