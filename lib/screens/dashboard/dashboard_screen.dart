import 'dart:async';

import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/database.dart';
import '../../data/session.dart';
import '../../logic/format.dart';
import '../../logic/sla.dart';
import '../../models/member.dart';
import '../../models/task_item.dart';
import '../../theme.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/panel.dart';
import '../../widgets/task_card.dart';
import 'health_ring.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday'
];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.onSeeAll});

  /// Lets the shell switch to the Tasks tab.
  final VoidCallback? onSeeAll;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<TaskItem> _tasks = [];
  Map<int, Member> _members = {};
  bool _loading = true;
  DateTime _now = DateTime.now();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    // Re-check every SLA once a minute, so a task can turn
    // At Risk or Overdue on screen without the user doing anything.
    _ticker = Timer.periodic(const Duration(minutes: 1),
        (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final tasks = await AppDatabase.instance.tasks();
    final members = await AppDatabase.instance.members();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _members = {for (final m in members) m.id!: m};
      _now = DateTime.now();
      _loading = false;
    });
  }

  Future<void> _openTask(TaskItem t) async {
    await Navigator.pushNamed(context, AppRoutes.task, arguments: t.id);
    _load();
  }

  Future<void> _newTask() async {
    await Navigator.pushNamed(context, AppRoutes.taskForm);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final me = Session.current;
    final counts = countBySla(_tasks, _now);
    final score = healthScore(_tasks, _now);
    final attention = _tasks.where((t) {
      final s = slaOf(t, _now);
      return s == SlaStatus.overdue || s == SlaStatus.atRisk;
    }).toList()
      ..sort((a, b) => compareUrgency(a, b, _now));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newTask,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New task'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${greeting(_now)},',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant)),
                              Text(
                                  '${_weekdays[_now.weekday - 1]}, ${formatDate(_now)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        MemberAvatar(me, size: 44),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Panel(
                      child: Row(
                        children: [
                          HealthRing(score: score, counts: counts),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Project health',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant)),
                                Text(healthLabel(score),
                                    style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 10),
                                for (final s in SlaStatus.values)
                                  _LegendRow(status: s, count: counts[s]!),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Two rows of two tiles. Rows of Expanded (instead of a fixed
                    // height grid) let tiles grow with large text without overflowing.
                    Row(
                      children: [
                        Expanded(
                            child: _StatTile(
                                icon: Icons.layers_rounded,
                                value: _tasks.length,
                                label: 'Total tasks',
                                color: theme.colorScheme.primary)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _StatTile(
                                icon: slaIcon(SlaStatus.onTrack),
                                value: counts[SlaStatus.onTrack]!,
                                label: 'On track',
                                color: slaColor(SlaStatus.onTrack))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _StatTile(
                                icon: slaIcon(SlaStatus.atRisk),
                                value: counts[SlaStatus.atRisk]!,
                                label: 'At risk',
                                color: slaColor(SlaStatus.atRisk))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _StatTile(
                                icon: slaIcon(SlaStatus.overdue),
                                value: counts[SlaStatus.overdue]!,
                                label: 'Overdue',
                                color: slaColor(SlaStatus.overdue))),
                      ],
                    ),
                    SectionHeader('Needs attention (${attention.length})',
                        action: 'See all', onAction: widget.onSeeAll),
                    if (attention.isEmpty)
                      const Panel(
                        child: EmptyState(
                          icon: Icons.celebration_rounded,
                          title: 'All clear',
                          message: 'Nothing is at risk or overdue right now.',
                        ),
                      )
                    else
                      for (final t in attention.take(5))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TaskCard(
                              task: t,
                              assignee: _members[t.assigneeId],
                              now: _now,
                              onTap: () => _openTask(t)),
                        ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.status, required this.count});

  final SlaStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(slaIcon(status), size: 14, color: slaColor(status)),
          const SizedBox(width: 6),
          Expanded(child: Text(status.label, style: style)),
          Text('$count', style: style?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  final IconData icon;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Panel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(label,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
