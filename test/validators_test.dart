import 'package:flutter_test/flutter_test.dart';
import 'package:sla_pulse/logic/validators.dart';

void main() {
  final now = DateTime(2026, 10, 10, 12);

  test('task title', () {
    expect(Validators.taskTitle(''), isNotNull);
    expect(Validators.taskTitle('   '), isNotNull); // spaces only
    expect(Validators.taskTitle('ab'), isNotNull);
    expect(Validators.taskTitle('a' * 61), isNotNull);
    expect(Validators.taskTitle('Fix login'), isNull);
  });

  test('description is optional but capped', () {
    expect(Validators.description(''), isNull);
    expect(Validators.description(null), isNull);
    expect(Validators.description('a' * 301), isNotNull);
  });

  test('assignee is required', () {
    expect(Validators.assignee(null), isNotNull);
    expect(Validators.assignee(3), isNull);
  });

  test('deadline must be in the future unless unchanged', () {
    final past = now.subtract(const Duration(hours: 1));
    expect(Validators.deadline(null, now: now), isNotNull);
    expect(Validators.deadline(past, now: now), isNotNull);
    expect(Validators.deadline(now, now: now), isNotNull); // exactly now is not the future
    expect(Validators.deadline(now.add(const Duration(minutes: 5)), now: now), isNull);
    expect(Validators.deadline(past, now: now, original: past), isNull); // editing an overdue task
  });

  test('email', () {
    expect(Validators.email(''), isNotNull);
    expect(Validators.email('nirere'), isNotNull);
    expect(Validators.email('a@b'), isNotNull);
    expect(Validators.email('n.sayinzoga@alustudent.com'), isNull);
  });

  test('pin must be exactly 4 digits', () {
    expect(Validators.pin(''), isNotNull);
    expect(Validators.pin('123'), isNotNull);
    expect(Validators.pin('12a4'), isNotNull);
    expect(Validators.pin('12345'), isNotNull);
    expect(Validators.pin('1234'), isNull);
  });

  test('person name', () {
    expect(Validators.personName('A'), isNotNull);
    expect(Validators.personName('R2D2'), isNotNull);
    expect(Validators.personName("Mwizerwa Keza Megane"), isNull);
  });
}
