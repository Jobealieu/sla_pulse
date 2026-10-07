import '../models/task_item.dart';
import 'format.dart';

enum SlaStatus {
  onTrack('On Track'),
  atRisk('At Risk'),
  overdue('Overdue'),
  completed('Completed');

  const SlaStatus(this.label);
  final String label;
}

/// A task is At Risk when the deadline is this close...
const atRiskWindow = Duration(hours: 48);

/// ...or when less than this share of its total time is left.
const atRiskShare = 0.25;

/// The SLA rules. `now` is passed in (never read inside) so the
/// same task always gives the same answer in tests.
///
/// 1. Done                                   -> Completed
/// 2. Deadline reached or passed             -> Overdue
/// 3. 48h or less left                       -> At Risk
/// 4. Less than 25% of (created..due) left   -> At Risk
/// 5. Anything else                          -> On Track
SlaStatus slaOf(TaskItem t, DateTime now) {
  if (t.isDone) return SlaStatus.completed;
  if (!now.isBefore(t.dueAt)) return SlaStatus.overdue;

  final left = t.dueAt.difference(now);
  if (left <= atRiskWindow) return SlaStatus.atRisk;

  final total = t.dueAt.difference(t.createdAt);
  if (total.inSeconds > 0 && left.inSeconds / total.inSeconds < atRiskShare) {
    return SlaStatus.atRisk;
  }
  return SlaStatus.onTrack;
}

/// Short live label for cards: "2d 4h left", "Overdue 3h", "Done on time".
String countdownLabel(TaskItem t, DateTime now) {
  if (t.isDone) {
    final done = t.completedAt ?? now;
    return done.isAfter(t.dueAt) ? 'Done ${formatSpan(done.difference(t.dueAt))} late' : 'Done on time';
  }
  if (!now.isBefore(t.dueAt)) return 'Overdue ${formatSpan(now.difference(t.dueAt))}';
  return '${formatSpan(t.dueAt.difference(now))} left';
}

/// One sentence that says WHICH rule fired. Shown on the details screen.
String slaReason(TaskItem t, DateTime now) {
  switch (slaOf(t, now)) {
    case SlaStatus.completed:
      return 'Marked done. It no longer counts against the deadline.';
    case SlaStatus.overdue:
      return 'The deadline has passed and the task is not done.';
    case SlaStatus.atRisk:
      final left = t.dueAt.difference(now);
      return left <= atRiskWindow
          ? 'Due within ${atRiskWindow.inHours} hours.'
          : 'Less than ${(atRiskShare * 100).round()}% of the planned time is left.';
    case SlaStatus.onTrack:
      return 'Plenty of time left before the deadline.';
  }
}

/// Project health from 0 to 100. Each task scores:
/// On Track 100, Completed on time 100, Completed late 60, At Risk 50, Overdue 0.
/// The ring shows the average. No tasks means nothing is slipping, so 100.
int healthScore(List<TaskItem> tasks, DateTime now) {
  if (tasks.isEmpty) return 100;
  var total = 0;
  for (final t in tasks) {
    total += switch (slaOf(t, now)) {
      SlaStatus.onTrack => 100,
      SlaStatus.completed => (t.completedAt ?? now).isAfter(t.dueAt) ? 60 : 100,
      SlaStatus.atRisk => 50,
      SlaStatus.overdue => 0,
    };
  }
  return (total / tasks.length).round();
}

String healthLabel(int score) {
  if (score >= 80) return 'Healthy';
  if (score >= 50) return 'Needs care';
  return 'Critical';
}

Map<SlaStatus, int> countBySla(List<TaskItem> tasks, DateTime now) {
  final counts = {for (final s in SlaStatus.values) s: 0};
  for (final t in tasks) {
    final s = slaOf(t, now);
    counts[s] = counts[s]! + 1;
  }
  return counts;
}

/// Most urgent first: Overdue, At Risk, On Track, Completed,
/// then the earliest deadline inside each group.
int compareUrgency(TaskItem a, TaskItem b, DateTime now) {
  final bySla = slaOf(a, now).index.compareTo(slaOf(b, now).index);
  return bySla != 0 ? bySla : a.dueAt.compareTo(b.dueAt);
}
