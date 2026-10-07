/// One line in a task's history, e.g. "Binthia moved this to Done".
class Activity {
  final int? id;
  final int taskId;
  final String message;
  final DateTime at;

  const Activity({
    this.id,
    required this.taskId,
    required this.message,
    required this.at,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'task_id': taskId,
        'message': message,
        'at': at.millisecondsSinceEpoch,
      };

  factory Activity.fromMap(Map<String, Object?> map) => Activity(
        id: map['id'] as int,
        taskId: map['task_id'] as int,
        message: map['message'] as String,
        at: DateTime.fromMillisecondsSinceEpoch(map['at'] as int),
      );
}
