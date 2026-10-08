import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../data/session.dart';
import '../../logic/format.dart';
import '../../logic/validators.dart';
import '../../models/member.dart';
import '../../models/task_item.dart';
import '../../widgets/form_bits.dart';
import '../../widgets/member_avatar.dart';

/// Create a task (existing == null) or edit one (existing != null).
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.existing});

  final TaskItem? existing;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _description =
      TextEditingController(text: widget.existing?.description);
  late int? _assigneeId = widget.existing?.assigneeId;
  late DateTime? _dueAt = widget.existing?.dueAt;
  late Priority _priority = widget.existing?.priority ?? Priority.medium;
  late TaskStatus _status = widget.existing?.status ?? TaskStatus.todo;

  List<Member> _members = [];
  bool _saving = false;
  bool _dirty = false;
  // Errors only start showing live after the first Save attempt.
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    AppDatabase.instance.members().then((m) {
      if (mounted) setState(() => _members = m);
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _pickDeadline(FormFieldState<DateTime> field) async {
    final now = DateTime.now();
    final current = field.value ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: current.isBefore(now) ? now : current,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(current));
    if (time == null || !mounted) return;
    _setDeadline(field,
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  void _setDeadline(FormFieldState<DateTime> field, DateTime value) {
    field.didChange(
        value); // tells the Form the value changed (and re-validates)
    setState(() => _dueAt = value);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final actor = Session.current?.firstName ?? 'Someone';
    try {
      final old = widget.existing;
      if (old != null) {
        final updated = old
            .copyWith(
              title: _title.text.trim(),
              description: _description.text.trim(),
              assigneeId: _assigneeId,
              priority: _priority,
              dueAt: _dueAt,
            )
            .withStatus(_status, now);
        final changes = _changes(old, updated);
        await AppDatabase.instance.updateTask(
          updated,
          changes.isEmpty
              ? '$actor saved with no changes'
              : '$actor changed ${changes.join(', ')}',
        );
      } else {
        final task = TaskItem(
          title: _title.text.trim(),
          description: _description.text.trim(),
          assigneeId: _assigneeId!,
          priority: _priority,
          createdAt: now,
          dueAt: _dueAt!,
        ).withStatus(_status, now);
        await AppDatabase.instance.insertTask(task, actor);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Saving task failed: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not save the task. Please try again.')),
      );
    }
  }

  List<String> _changes(TaskItem a, TaskItem b) => [
        if (a.title != b.title) 'the title',
        if (a.description != b.description) 'the description',
        if (a.assigneeId != b.assigneeId) 'the assignee',
        if (a.dueAt != b.dueAt) 'the deadline',
        if (a.priority != b.priority) 'priority to ${b.priority.label}',
        if (a.status != b.status) 'status to ${b.status.label}',
      ];

  Future<bool> _confirmDiscard() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('Your edits to this task will be lost.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep editing')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard')),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // PopScope stops the back button from silently throwing away edits.
    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'Edit task' : 'New task')),
        body: Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          onChanged: _markDirty,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLength: 60,
                decoration: fieldDecoration('Task title', Icons.title_rounded,
                    hint: 'e.g. Build the login screen'),
                validator: Validators.taskTitle,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _description,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 5,
                maxLength: 300,
                decoration: fieldDecoration(
                    'Description (optional)', Icons.notes_rounded),
                validator: Validators.description,
              ),
              const FieldLabel('Assign to'),
              // A custom FormField so a chip picker can still take part
              // in Form validation like a normal text field.
              FormField<int>(
                initialValue: _assigneeId,
                validator: Validators.assignee,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final m in _members)
                          ChoiceChip(
                            avatar: MemberAvatar(m, size: 24),
                            label: Text(m.firstName),
                            showCheckmark: false,
                            selected: field.value == m.id,
                            onSelected: (_) {
                              field.didChange(m.id);
                              setState(() => _assigneeId = m.id);
                            },
                          ),
                      ],
                    ),
                    FieldError(field.errorText),
                  ],
                ),
              ),
              const FieldLabel('Deadline'),
              FormField<DateTime>(
                initialValue: _dueAt,
                validator: (v) => Validators.deadline(v,
                    now: DateTime.now(), original: widget.existing?.dueAt),
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _pickDeadline(field),
                      child: InputDecorator(
                        decoration: fieldDecoration(
                                'Date and time', Icons.event_rounded)
                            .copyWith(errorText: field.errorText),
                        child: Text(field.value == null
                            ? 'Tap to pick'
                            : formatDateTime(field.value!)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Shortcuts so a deadline is two taps, not six.
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                            label: const Text('In 1 hour'),
                            onPressed: () => _setDeadline(
                                field, now.add(const Duration(hours: 1)))),
                        ActionChip(
                            label: const Text('Tomorrow 5 PM'),
                            onPressed: () => _setDeadline(
                                field,
                                DateTime(
                                    now.year, now.month, now.day + 1, 17))),
                        ActionChip(
                            label: const Text('In 3 days'),
                            onPressed: () => _setDeadline(
                                field, now.add(const Duration(days: 3)))),
                        ActionChip(
                            label: const Text('In 1 week'),
                            onPressed: () => _setDeadline(
                                field, now.add(const Duration(days: 7)))),
                      ],
                    ),
                  ],
                ),
              ),
              const FieldLabel('Priority'),
              SegmentedButton<Priority>(
                showSelectedIcon: false,
                segments: [
                  for (final p in Priority.values)
                    ButtonSegment(value: p, label: Text(p.label))
                ],
                selected: {_priority},
                onSelectionChanged: (s) => setState(() {
                  _priority = s.first;
                  _dirty = true;
                }),
              ),
              const FieldLabel('Status'),
              SegmentedButton<TaskStatus>(
                showSelectedIcon: false,
                segments: [
                  for (final s in TaskStatus.values)
                    ButtonSegment(value: s, label: Text(s.label))
                ],
                selected: {_status},
                onSelectionChanged: (s) => setState(() {
                  _status = s.first;
                  _dirty = true;
                }),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                // Disabled while saving so a double tap cannot create two tasks.
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_rounded),
                label: Text(_isEdit ? 'Save changes' : 'Create task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
