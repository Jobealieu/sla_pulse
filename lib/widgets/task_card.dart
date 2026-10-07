import 'package:flutter/material.dart';

import '../logic/format.dart';
import '../logic/sla.dart';
import '../models/member.dart';
import '../models/task_item.dart';
import '../theme.dart';
import 'member_avatar.dart';
import 'sla_badge.dart';

/// One task in a list. Reused by the dashboard, task list and member profile.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.assignee,
    required this.now,
    this.onTap,
  });

  final TaskItem task;
  final Member? assignee;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sla = slaOf(task, now);
    final urgent = sla == SlaStatus.overdue || sla == SlaStatus.atRisk;
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        // IntrinsicHeight lets the coloured strip on the left stretch
        // to the full height of the content next to it.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: slaColor(sla)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                decoration: task.isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SlaBadge(sla),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.flag_rounded, size: 15, color: _priorityColor(task.priority, scheme)),
                          const SizedBox(width: 4),
                          Text(task.priority.label, style: muted),
                          const SizedBox(width: 12),
                          Icon(Icons.timer_outlined, size: 15, color: urgent ? slaColor(sla) : scheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              countdownLabel(task, now),
                              overflow: TextOverflow.ellipsis,
                              style: muted?.copyWith(
                                color: urgent ? slaColor(sla) : null,
                                fontWeight: urgent ? FontWeight.w700 : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          MemberAvatar(assignee, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(assignee?.name ?? 'Unassigned', overflow: TextOverflow.ellipsis, style: muted),
                          ),
                          Text(formatDate(task.dueAt), style: muted),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _priorityColor(Priority p, ColorScheme scheme) => switch (p) {
      Priority.high => const Color(0xFFF04438),
      Priority.medium => const Color(0xFFF79009),
      Priority.low => scheme.onSurfaceVariant,
    };
