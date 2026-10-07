import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/database.dart';
import '../../logic/sla.dart';
import '../../models/member.dart';
import '../../models/task_item.dart';
import '../../theme.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/panel.dart';
import 'workload.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  List<Member> _members = [];
  List<TaskItem> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final members = await AppDatabase.instance.members();
    final tasks = await AppDatabase.instance.tasks();
    if (!mounted) return;
    setState(() {
      _members = members;
      _tasks = tasks;
      _loading = false;
    });
  }

  Future<void> _addMember() async {
    final added = await Navigator.pushNamed(context, AppRoutes.newMember);
    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member added to the team')));
    }
    _load();
  }

  Future<void> _openMember(Member m) async {
    await Navigator.pushNamed(context, AppRoutes.member, arguments: m);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final open = _tasks.where((t) => !t.isDone).toList();
    final overdue = open.where((t) => slaOf(t, now) == SlaStatus.overdue).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team'),
        actions: [
          IconButton(tooltip: 'Add member', icon: const Icon(Icons.person_add_alt_1_rounded), onPressed: _addMember),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Panel(
                    child: Row(
                      children: [
                        _Metric(value: _members.length, label: 'Members'),
                        _Metric(value: open.length, label: 'Open tasks'),
                        _Metric(value: overdue, label: 'Overdue', color: slaColor(SlaStatus.overdue)),
                      ],
                    ),
                  ),
                  const SectionHeader('Workload'),
                  for (final m in _members)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MemberTile(
                        member: m,
                        open: open.where((t) => t.assigneeId == m.id).length,
                        overdue: open.where((t) => t.assigneeId == m.id && slaOf(t, now) == SlaStatus.overdue).length,
                        onTap: () => _openMember(m),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, this.color});

  final int value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: color)),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.open, required this.overdue, required this.onTap});

  final Member member;
  final int open;
  final int overdue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              MemberAvatar(member, size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    Text(member.role, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    WorkloadMeter(openTasks: open),
                    const SizedBox(height: 4),
                    Text('$open open, $overdue overdue', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
