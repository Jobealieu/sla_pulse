import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../logic/sla.dart';
import '../../models/member.dart';
import '../../models/task_item.dart';
import '../../theme.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/panel.dart';
import '../../widgets/task_card.dart';
import 'workload.dart';

/// One member: contact info, their numbers and every task they own.
class MemberProfileScreen extends StatefulWidget {
  const MemberProfileScreen({super.key, required this.member});

  final Member member;

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  List<TaskItem> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await AppDatabase.instance.tasks();
    if (!mounted) return;
    setState(() {
      _tasks = all.where((t) => t.assigneeId == widget.member.id).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = widget.member;
    final now = DateTime.now();
    final sorted = [..._tasks]..sort((a, b) => compareUrgency(a, b, now));
    final open = _tasks.where((t) => !t.isDone).length;
    final overdue = _tasks.where((t) => slaOf(t, now) == SlaStatus.overdue).length;
    final done = _tasks.length - open;

    return Scaffold(
      appBar: AppBar(title: Text(m.firstName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Panel(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      MemberAvatar(m, size: 72),
                      const SizedBox(height: 12),
                      Text(m.name, textAlign: TextAlign.center, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      Text(m.role, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mail_outline_rounded, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Flexible(child: Text(m.email, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      WorkloadMeter(openTasks: open),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _Count(value: open, label: 'Open'),
                          _Count(value: overdue, label: 'Overdue', color: slaColor(SlaStatus.overdue)),
                          _Count(value: done, label: 'Done', color: slaColor(SlaStatus.completed)),
                        ],
                      ),
                    ],
                  ),
                ),
                SectionHeader('Assigned tasks (${_tasks.length})'),
                if (sorted.isEmpty)
                  const Panel(
                    child: EmptyState(icon: Icons.inbox_rounded, title: 'No tasks yet', message: 'Tasks assigned to this member will show up here.'),
                  )
                else
                  for (final t in sorted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TaskCard(task: t, assignee: m, now: now),
                    ),
              ],
            ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label, this.color});

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
