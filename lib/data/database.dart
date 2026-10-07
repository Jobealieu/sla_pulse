import 'package:sqflite/sqflite.dart';

import '../models/activity.dart';
import '../models/member.dart';
import '../models/task_item.dart';

/// Single place that talks to SQLite.
///
/// Why SQLite instead of SharedPreferences: tasks point to members
/// (assignee_id) and activity rows point to tasks (task_id). Those are
/// relations, so real tables with foreign keys fit better than JSON strings.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  // Storing the Future (not the Database) means two screens asking at the
  // same time still share one open call.
  Future<Database>? _db;
  Future<Database> get _database => _db ??= _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      '$dir/sla_pulse.db',
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE members (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            role TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            pin TEXT NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT NOT NULL DEFAULT '',
            assignee_id INTEGER NOT NULL REFERENCES members(id),
            priority TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            due_at INTEGER NOT NULL,
            completed_at INTEGER
          )''');
        await db.execute('''
          CREATE TABLE activity (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
            message TEXT NOT NULL,
            at INTEGER NOT NULL
          )''');
        await _seed(db);
      },
    );
  }

  /// Demo data, created once on first launch. Dates are relative to "now"
  /// so every SLA status is visible the first time the app opens.
  Future<void> _seed(Database db) async {
    const team = [
      Member(name: 'Alieu O Jobe', role: 'Project Lead and Flutter Developer', email: 'a.jobe@alustudent.com', pin: '1234'),
      Member(name: 'Binthia Nitonde', role: 'UI Designer and Auth Developer', email: 'n.binthia@alustudent.com', pin: '1234'),
      Member(name: 'Mwizerwa Keza Megane', role: 'Mobile Developer', email: 'm.mwizerwa@alustudent.com', pin: '1234'),
      Member(name: 'Nirere Sayinzoga', role: 'QA and Forms Developer', email: 'n.sayinzoga@alustudent.com', pin: '1234'),
    ];
    final ids = <int>[];
    for (final m in team) {
      ids.add(await db.insert('members', m.toMap()..remove('id')));
    }

    final now = DateTime.now();
    DateTime ago(int hours) => now.subtract(Duration(hours: hours));
    DateTime ahead(int hours) => now.add(Duration(hours: hours));

    final tasks = [
      TaskItem(title: 'Design the sign in screen', description: 'Profile picker plus PIN sheet that matches our colour system.', assigneeId: ids[1], priority: Priority.high, status: TaskStatus.done, createdAt: ago(144), dueAt: ago(48), completedAt: ago(72)),
      TaskItem(title: 'Set up the SQLite schema', description: 'Members, tasks and activity tables with foreign keys.', assigneeId: ids[0], priority: Priority.high, status: TaskStatus.inProgress, createdAt: ago(72), dueAt: ahead(5)),
      TaskItem(title: 'Write SLA unit tests', description: 'Cover every rule boundary, including the exact deadline.', assigneeId: ids[0], priority: Priority.medium, createdAt: ago(96), dueAt: ago(6)),
      TaskItem(title: 'Build task list filters', description: 'Search, SLA filter chips and sorting.', assigneeId: ids[2], priority: Priority.medium, status: TaskStatus.inProgress, createdAt: ago(24), dueAt: ahead(144)),
      TaskItem(title: 'Validate the create task form', description: 'Title length, assignee and a deadline in the future.', assigneeId: ids[3], priority: Priority.high, createdAt: ago(48), dueAt: ahead(30)),
      TaskItem(title: 'Prepare the demo script', description: 'Each member explains the part they built.', assigneeId: ids[1], priority: Priority.low, createdAt: ago(24), dueAt: ahead(216)),
      TaskItem(title: 'Build the team members screen', description: 'Workload meter for every member.', assigneeId: ids[3], priority: Priority.medium, createdAt: ago(120), dueAt: ahead(72)),
      TaskItem(title: 'Record the walkthrough video', assigneeId: ids[2], priority: Priority.low, status: TaskStatus.done, createdAt: ago(120), dueAt: ahead(24), completedAt: ago(1)),
    ];
    for (final t in tasks) {
      final id = await db.insert('tasks', t.toMap()..remove('id'));
      final owner = team[ids.indexOf(t.assigneeId)].firstName;
      await db.insert('activity', Activity(taskId: id, message: '$owner created this task', at: t.createdAt).toMap()..remove('id'));
    }
  }

  // Members

  Future<List<Member>> members() async {
    final rows = await (await _database).query('members', orderBy: 'name');
    return rows.map(Member.fromMap).toList();
  }

  Future<Member?> member(int id) async {
    final rows = await (await _database).query('members', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Member.fromMap(rows.first);
  }

  Future<bool> emailExists(String email) async {
    final rows = await (await _database).query(
      'members',
      where: 'LOWER(email) = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
    return rows.isNotEmpty;
  }

  Future<int> insertMember(Member m) async =>
      (await _database).insert('members', m.toMap()..remove('id'));

  // Tasks

  Future<List<TaskItem>> tasks() async {
    final rows = await (await _database).query('tasks', orderBy: 'due_at');
    return rows.map(TaskItem.fromMap).toList();
  }

  Future<TaskItem?> task(int id) async {
    final rows = await (await _database).query('tasks', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : TaskItem.fromMap(rows.first);
  }

  /// Insert the task and its first activity row in one transaction,
  /// so we never end up with a task that has no history (or the reverse).
  Future<int> insertTask(TaskItem t, String actor) async {
    return (await _database).transaction((txn) async {
      final id = await txn.insert('tasks', t.toMap()..remove('id'));
      await txn.insert('activity', Activity(taskId: id, message: '$actor created this task', at: DateTime.now()).toMap()..remove('id'));
      return id;
    });
  }

  Future<void> updateTask(TaskItem t, String activityMessage) async {
    await (await _database).transaction((txn) async {
      await txn.update('tasks', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
      await txn.insert('activity', Activity(taskId: t.id!, message: activityMessage, at: DateTime.now()).toMap()..remove('id'));
    });
  }

  /// Activity rows are removed automatically by ON DELETE CASCADE.
  Future<void> deleteTask(int id) async {
    await (await _database).delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Activity

  Future<List<Activity>> activityFor(int taskId) async {
    final rows = await (await _database).query(
      'activity',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'at DESC, id DESC',
    );
    return rows.map(Activity.fromMap).toList();
  }
}
