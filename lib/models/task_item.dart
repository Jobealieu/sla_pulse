enum Priority {
  low('Low'),
  medium('Medium'),
  high('High');

  const Priority(this.label);
  final String label;
}

/// The workflow status a person sets by hand.
/// The SLA status (On Track, At Risk, ...) is NOT stored here,
/// it is calculated from the deadline in lib/logic/sla.dart.
enum TaskStatus {
  todo('To Do'),
  inProgress('In Progress'),
  done('Done');

  const TaskStatus(this.label);
  final String label;
}

/// A project task. Stored in the `tasks` table.
class TaskItem {
  final int? id;
  final String title;
  final String description;
  final int assigneeId;
  final Priority priority;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime dueAt;
  final DateTime? completedAt;

  const TaskItem({
    this.id,
    required this.title,
    this.description = '',
    required this.assigneeId,
    this.priority = Priority.medium,
    this.status = TaskStatus.todo,
    required this.createdAt,
    required this.dueAt,
    this.completedAt,
  });

  bool get isDone => status == TaskStatus.done;

  /// Copy for form edits. Status changes go through [withStatus]
  /// so completedAt always stays in sync with the status.
  TaskItem copyWith({
    int? id,
    String? title,
    String? description,
    int? assigneeId,
    Priority? priority,
    DateTime? dueAt,
  }) =>
      TaskItem(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        assigneeId: assigneeId ?? this.assigneeId,
        priority: priority ?? this.priority,
        status: status,
        createdAt: createdAt,
        dueAt: dueAt ?? this.dueAt,
        completedAt: completedAt,
      );

  /// Moving to Done stamps the completion time, moving away clears it.
  TaskItem withStatus(TaskStatus next, DateTime now) => TaskItem(
        id: id,
        title: title,
        description: description,
        assigneeId: assigneeId,
        priority: priority,
        status: next,
        createdAt: createdAt,
        dueAt: dueAt,
        completedAt: next == TaskStatus.done ? (completedAt ?? now) : null,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'assignee_id': assigneeId,
        'priority': priority.name,
        'status': status.name,
        'created_at': createdAt.millisecondsSinceEpoch,
        'due_at': dueAt.millisecondsSinceEpoch,
        'completed_at': completedAt?.millisecondsSinceEpoch,
      };

  factory TaskItem.fromMap(Map<String, Object?> map) {
    final completed = map['completed_at'] as int?;
    return TaskItem(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      assigneeId: map['assignee_id'] as int,
      priority: Priority.values.byName(map['priority'] as String),
      status: TaskStatus.values.byName(map['status'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      dueAt: DateTime.fromMillisecondsSinceEpoch(map['due_at'] as int),
      completedAt:
          completed == null ? null : DateTime.fromMillisecondsSinceEpoch(completed),
    );
  }
}
