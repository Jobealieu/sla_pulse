import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/database.dart';
import '../../data/session.dart';
import '../../logic/sla.dart';
import '../../models/task_item.dart';
import '../../theme.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/panel.dart';

/// The signed in member's own page plus app settings.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<TaskItem> _mine = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await AppDatabase.instance.tasks();
    if (!mounted) return;
    setState(() => _mine = all.where((t) => t.assigneeId == Session.current?.id).toList());
  }

  Future<void> _toggleDark(bool value) async {
    await SlaPulseApp.of(context).setDark(value);
    if (mounted) setState(() {});
  }

  void _showRules() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How SLA status works'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RuleRow(SlaStatus.completed, 'The task is marked Done.'),
            _RuleRow(SlaStatus.overdue, 'The deadline has passed and the task is not done.'),
            _RuleRow(SlaStatus.atRisk, '48 hours or less left, or less than 25% of the planned time left.'),
            _RuleRow(SlaStatus.onTrack, 'Everything else.'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
      ),
    );
  }

  Future<void> _signOut() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will go back to the profile picker.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (sure != true) return;
    await Session.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.signIn, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final me = Session.current;
    final now = DateTime.now();
    final open = _mine.where((t) => !t.isDone).length;
    final overdue = _mine.where((t) => slaOf(t, now) == SlaStatus.overdue).length;
    final error = scheme.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Panel(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                MemberAvatar(me, size: 76),
                const SizedBox(height: 12),
                Text(me?.name ?? '', textAlign: TextAlign.center, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                Text(me?.role ?? '', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                Text(me?.email ?? '', textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: scheme.primary)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Stat(value: open, label: 'My open'),
                    _Stat(value: overdue, label: 'Overdue', color: slaColor(SlaStatus.overdue)),
                    _Stat(value: _mine.length - open, label: 'Done', color: slaColor(SlaStatus.completed)),
                  ],
                ),
              ],
            ),
          ),
          const SectionHeader('Settings'),
          // Material (not Container) so the ListTile ripple is drawn on this surface.
          Material(
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark mode'),
                  subtitle: const Text('Saved on this device'),
                  value: SlaPulseApp.of(context).isDark,
                  onChanged: _toggleDark,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.rule_rounded),
                  title: const Text('How SLA status works'),
                  onTap: _showRules,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('About SLA Pulse'),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'SLA Pulse',
                    applicationVersion: '1.0.0',
                    applicationLegalese: 'Mobile Application Development, African Leadership University',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.logout_rounded, color: error),
                  title: Text('Sign out', style: TextStyle(color: error, fontWeight: FontWeight.w700)),
                  onTap: _signOut,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.color});

  final int value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: color)),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow(this.status, this.rule);

  final SlaStatus status;
  final String rule;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(slaIcon(status), color: slaColor(status), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '${status.label}: ', style: const TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: rule),
            ])),
          ),
        ],
      ),
    );
  }
}
