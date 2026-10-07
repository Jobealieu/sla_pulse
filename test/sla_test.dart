import 'package:flutter_test/flutter_test.dart';
import 'package:sla_pulse/logic/format.dart';
import 'package:sla_pulse/logic/sla.dart';
import 'package:sla_pulse/models/task_item.dart';

void main() {
  // A fixed "now" so every test gives the same answer on any day.
  final now = DateTime(2026, 10, 10, 12);

  TaskItem task({required Duration createdAgo, required Duration dueIn, TaskStatus status = TaskStatus.todo, DateTime? completedAt}) =>
      TaskItem(
        title: 'Test',
        assigneeId: 1,
        status: status,
        createdAt: now.subtract(createdAgo),
        dueAt: now.add(dueIn),
        completedAt: completedAt,
      );

  group('slaOf', () {
    test('done is Completed even after the deadline', () {
      final t = task(createdAgo: const Duration(days: 5), dueIn: const Duration(days: -1), status: TaskStatus.done);
      expect(slaOf(t, now), SlaStatus.completed);
    });

    test('deadline passed and not done is Overdue', () {
      final t = task(createdAgo: const Duration(days: 5), dueIn: const Duration(hours: -1));
      expect(slaOf(t, now), SlaStatus.overdue);
    });

    test('exactly at the deadline counts as Overdue', () {
      final t = task(createdAgo: const Duration(days: 5), dueIn: Duration.zero);
      expect(slaOf(t, now), SlaStatus.overdue);
    });

    test('48 hours left is At Risk (boundary included)', () {
      final t = task(createdAgo: const Duration(days: 30), dueIn: const Duration(hours: 48));
      expect(slaOf(t, now), SlaStatus.atRisk);
    });

    test('49 hours left with lots of planned time is On Track', () {
      final t = task(createdAgo: const Duration(hours: 1), dueIn: const Duration(hours: 49));
      expect(slaOf(t, now), SlaStatus.onTrack);
    });

    test('less than 25% of planned time left is At Risk', () {
      // 20 day task with 4 days left = 20% left
      final t = task(createdAgo: const Duration(days: 16), dueIn: const Duration(days: 4));
      expect(slaOf(t, now), SlaStatus.atRisk);
    });

    test('30% of planned time left is On Track', () {
      // 20 day task with 6 days left = 30% left
      final t = task(createdAgo: const Duration(days: 14), dueIn: const Duration(days: 6));
      expect(slaOf(t, now), SlaStatus.onTrack);
    });

    test('created after its deadline does not divide by zero', () {
      final t = TaskItem(title: 'Odd', assigneeId: 1, createdAt: now.add(const Duration(days: 10)), dueAt: now.add(const Duration(days: 3)));
      expect(slaOf(t, now), SlaStatus.onTrack);
    });
  });

  group('healthScore', () {
    test('no tasks is 100', () => expect(healthScore([], now), 100));

    test('averages the task scores', () {
      final tasks = [
        task(createdAgo: const Duration(days: 1), dueIn: const Duration(days: 10)), // On Track 100
        task(createdAgo: const Duration(days: 1), dueIn: const Duration(hours: 5)), // At Risk 50
        task(createdAgo: const Duration(days: 1), dueIn: const Duration(hours: -5)), // Overdue 0
        task(createdAgo: const Duration(days: 3), dueIn: const Duration(days: -1), status: TaskStatus.done, completedAt: now), // late 60
      ];
      expect(healthScore(tasks, now), 53); // (100 + 50 + 0 + 60) / 4 = 52.5 -> 53
    });
  });

  group('labels', () {
    test('countdown shows time left and overdue time', () {
      expect(countdownLabel(task(createdAgo: const Duration(days: 1), dueIn: const Duration(hours: 52)), now), '2d 4h left');
      expect(countdownLabel(task(createdAgo: const Duration(days: 1), dueIn: const Duration(minutes: -90)), now), 'Overdue 1h 30m');
    });

    test('formatSpan handles under a minute', () {
      expect(formatSpan(const Duration(seconds: 20)), '<1m');
    });

    test('withStatus stamps and clears completedAt', () {
      final done = task(createdAgo: const Duration(days: 1), dueIn: const Duration(days: 1)).withStatus(TaskStatus.done, now);
      expect(done.completedAt, now);
      expect(done.withStatus(TaskStatus.inProgress, now).completedAt, isNull);
    });
  });
}
