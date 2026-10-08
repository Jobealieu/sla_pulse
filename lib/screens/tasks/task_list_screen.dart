import 'dart:async';

import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/database.dart';
import '../../data/session.dart';
import '../../logic/sla.dart';
import '../../models/member.dart';
import '../../models/task_item.dart';
import '../../theme.dart';
import '../../widgets/panel.dart';
import '../../widgets/task_card.dart';

enum _Sort {
  urgency('Most urgent'),
  deadline('Deadline'),
  priority('Priority');

  const _Sort(this.label);
  final String label;
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _search = TextEditingController();
  List<TaskItem> _tasks = [];
  Map<int, Member> _members = {};
  bool _loading = true;
  DateTime _now = DateTime.now();
  Timer? _ticker;

  // View state. Changing any of these calls setState, and build()
  // recalculates the visible list from _tasks.
  String _query = '';
  SlaStatus? _filter; // null means All
  bool _mineOnly = false;
  _Sort _sort = _Sort.urgency;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _search.dispose();
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

  List<TaskItem> get _visible {
    final q = _query.trim().toLowerCase();
    final list = _tasks.where((t) {
      if (_filter != null && slaOf(t, _now) != _filter) return false;
      if (_mineOnly && t.assigneeId != Session.current?.id) return false;
      return q.isEmpty || t.title.toLowerCase().contains(q) || t.description.toLowerCase().contains(q);
    }).toList();
    final int Function(TaskItem, TaskItem) compare = switch (_sort) {
      _Sort.urgency => (a, b) => compareUrgency(a, b, _now),
      _Sort.deadline => (a, b) => a.dueAt.compareTo(b.dueAt),
      _Sort.priority => (a, b) => b.priority.index.compareTo(a.priority.index),
    };
    return list..sort(compare);
  }

  Future<void> _open(TaskItem t) async {
    await Navigator.pushNamed(context, AppRoutes.task, arguments: t.id);
    _load();
  }

  Future<void> _newTask() async {
    await Navigator.pushNamed(context, AppRoutes.taskForm);
    _load();
  }

  /// Swipe right to finish a task, with Undo in the SnackBar.
  Future<void> _complete(TaskItem t) async {
    final messenger = ScaffoldMessenger.of(context); // captured before the await
    final actor = Session.current?.firstName ?? 'Someone';
    await AppDatabase.instance.updateTask(t.withStatus(TaskStatus.done, DateTime.now()), '$actor marked this Done');
    await _load();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Marked "${t.title}" as done'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            // t is the snapshot from before the swipe, so saving it restores the old status.
            await AppDatabase.instance.updateTask(t, '$actor undid Done');
            _load();
          },
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = countBySla(_tasks, _now);
    final visible = _visible;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          PopupMenuButton<_Sort>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort_rounded),
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => [for (final s in _Sort.values) PopupMenuItem(value: s, child: Text(s.label))],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newTask,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New task'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search tasks',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                            ),
                      filled: true,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                // Horizontal chip strip: scrolls sideways on narrow phones.
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _chip(null, 'All', _tasks.length),
                      for (final s in SlaStatus.values) _chip(s, s.label, counts[s]!),
                      FilterChip(
                        label: const Text('Mine'),
                        selected: _mineOnly,
                        onSelected: (v) => setState(() => _mineOnly = v),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: visible.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              EmptyState(icon: Icons.search_off_rounded, title: 'No tasks here', message: 'Try another filter or clear the search.'),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                            itemCount: visible.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final t = visible[i];
                              return Dismissible(
                                key: ValueKey(t.id),
                                direction: t.isDone ? DismissDirection.none : DismissDirection.startToEnd,
                                // Return false: the card slides back and the reload shows the new status.
                                confirmDismiss: (_) async {
                                  await _complete(t);
                                  return false;
                                },
                                background: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  decoration: BoxDecoration(
                                    color: slaColor(SlaStatus.onTrack),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.task_alt_rounded, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text('Mark done', style: theme.textTheme.labelLarge?.copyWith(color: Colors.white)),
                                    ],
                                  ),
                                ),
                                child: TaskCard(task: t, assignee: _members[t.assigneeId], now: _now, onTap: () => _open(t)),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _chip(SlaStatus? status, String label, int count) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          avatar: status == null ? null : Icon(slaIcon(status), size: 16, color: slaColor(status)),
          label: Text('$label $count'),
          showCheckmark: false,
          selected: _filter == status,
          onSelected: (_) => setState(() => _filter = status),
        ),
      );
}
