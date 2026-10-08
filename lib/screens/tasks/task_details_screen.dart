import 'dart:async';

import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/database.dart';
import '../../data/session.dart';
import '../../logic/format.dart';
import '../../logic/sla.dart';
import '../../models/activity.dart';
import '../../models/member.dart';
import '../../models/task_item.dart';
import '../../theme.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/panel.dart';

class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({super.key, required this.taskId});

  /// Only the id is passed in. The screen reads the latest copy
  /// from SQLite, so it never shows stale data after an edit.
  final int taskId;

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  TaskItem? _task;
  Member? _assignee;
  List<Activity> _activity = [];
  bool _loading = true;
  DateTime _now = DateTime.now();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final db = AppDatabase.instance;
    final task = await db.task(widget.taskId);
    final assignee = task == null ? null : await db.member(task.assigneeId);
    final activity = await db.activityFor(widget.taskId);
    if (!mounted) return;
    setState(() {
      _task = task;
      _assignee = assignee;
      _activity = activity;
      _now = DateTime.now();
      _loading = false;
    });
  }

  Future<void> _setStatus(TaskStatus next) async {
    final t = _task!;
    if (t.status == next) return;
    final actor = Session.current?.firstName ?? 'Someone';
    await AppDatabase.instance.updateTask(t.withStatus(next, DateTime.now()), '$actor moved this to ${next.label}');
    await _load(); // setState inside _load repaints the SLA card, segments and timeline
  }

  Future<void> _edit() async {
    await Navigator.pushNamed(context, AppRoutes.taskForm, arguments: _task);
    _load();
  }

  Future<void> _delete() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this task?'),
        content: const Text('The task and its activity history will be removed. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await AppDatabase.instance.deleteTask(widget.taskId);
    navigator.pop();
    messenger.showSnackBar(const SnackBar(content: Text('Task deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task details'),
        actions: [
          if (task != null) ...[
            IconButton(tooltip: 'Edit task', icon: const Icon(Icons.edit_outlined), onPressed: _edit),
            IconButton(tooltip: 'Delete task', icon: const Icon(Icons.delete_outline_rounded), onPressed: _delete),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : task == null
              ? const EmptyState(icon: Icons.search_off_rounded, title: 'Task not found', message: 'It may have been deleted.')
              : _body(context, task),
    );
  }

  Widget _body(BuildContext context, TaskItem task) {
    final theme = Theme.of(context);
    final sla = slaOf(task, _now);
    final color = slaColor(sla);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(task.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        if (task.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(task.description, style: muted),
        ],
        const SizedBox(height: 18),
        // The SLA card: colour, icon, the rule that fired, and a live countdown.
        Panel(
          color: color.withValues(alpha: 0.10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
                child: Icon(slaIcon(sla), color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SLA status', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    Text(sla.label, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: color)),
                    const SizedBox(height: 2),
                    Text(slaReason(task, _now), style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Text(countdownLabel(task, _now), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Panel(
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.person_outline_rounded,
                label: 'Assigned to',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MemberAvatar(_assignee, size: 24),
                    const SizedBox(width: 8),
                    Flexible(child: Text(_assignee?.name ?? 'Unassigned', overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              _InfoRow(icon: Icons.event_rounded, label: 'Deadline', child: Text(formatDateTime(task.dueAt))),
              _InfoRow(icon: Icons.flag_outlined, label: 'Priority', child: Text(task.priority.label)),
              _InfoRow(icon: Icons.schedule_rounded, label: 'Created', child: Text(formatDateTime(task.createdAt))),
            ],
          ),
        ),
        const SectionHeader('Update status'),
        SegmentedButton<TaskStatus>(
          showSelectedIcon: false,
          segments: [for (final s in TaskStatus.values) ButtonSegment(value: s, label: Text(s.label))],
          selected: {task.status},
          onSelectionChanged: (s) => _setStatus(s.first),
        ),
        const SectionHeader('Activity'),
        for (var i = 0; i < _activity.length; i++)
          _TimelineTile(activity: _activity[i], now: _now, isLast: i == _activity.length - 1),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.child});

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: DefaultTextStyle.merge(style: const TextStyle(fontWeight: FontWeight.w600), child: child),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.activity, required this.now, required this.isLast});

  final Activity activity;
  final DateTime now;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = theme.colorScheme.outlineVariant;
    // IntrinsicHeight makes the connector line as tall as the text beside it.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 16,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: line)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.message, style: theme.textTheme.bodyMedium),
                  Text(
                    '${timeAgo(activity.at, now)}, ${formatDateTime(activity.at)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
