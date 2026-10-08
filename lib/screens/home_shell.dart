import 'package:flutter/material.dart';

import 'dashboard/dashboard_screen.dart';
import 'profile/profile_screen.dart';
import 'team/team_screen.dart';

/// The four main tabs with a bottom NavigationBar.
///
/// We build only the selected tab (no IndexedStack). Switching tabs
/// creates the screen again, so it always reads fresh data from SQLite.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_index) {
        0 => DashboardScreen(onSeeAll: () => _select(1)),
        1 => const _ComingSoon('Tasks'),
        2 => const TeamScreen(),
        _ => const ProfileScreen(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.view_agenda_outlined), selectedIcon: Icon(Icons.view_agenda_rounded), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups_rounded), label: 'Team'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

/// Temporary tab body until the teammate who owns this tab merges their screen.
class _ComingSoon extends StatelessWidget {
  const _ComingSoon(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: Text('Coming soon')),
      );
}
