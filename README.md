# SLA Pulse

**See what is slipping before it slips.**

SLA Pulse is a Flutter mobile app that helps a small software team manage project tasks, assign owners, set deadlines and see at a glance which work needs attention. Every task gets a live SLA status (On Track, At Risk, Overdue or Completed) worked out from its deadline.

Built for the Mobile Application Development course (Formative Assignment 1) at African Leadership University.

## Team

| Member | Module | Branch |
|---|---|---|
| Alieu O Jobe | Project setup, models, SQLite database, SLA engine, theme, dashboard and health ring | `feature/core_dashboard` |
| Nirere Sayinzoga | Create and edit task form, validators, team members, member profile, add member | `feature/task_form_team` |
| Binthia Nitonde | Sign in and user selection, session, profile and settings, dark mode | `feature/auth_profile` |
| Mwizerwa Keza Megane | Task list (search, filters, sort, swipe), task details, status updates, activity timeline | `feature/task_list_details` |

## What makes it different

1. **SLA Health Ring.** A custom drawn ring (CustomPainter, no chart package) that splits the project by SLA status and shows a health score from 0 to 100.
2. **Live countdowns.** Every task shows "2d 4h left" or "Overdue 3h", refreshed every minute, so a task can turn At Risk or Overdue while you watch.
3. **Needs Attention list.** The dashboard puts Overdue and At Risk work first, most urgent on top.
4. **Workload meter.** Each member shows Available, Busy or Overloaded from their open tasks.
5. **Activity timeline.** Every create, edit and status change is saved in its own table and shown on the task.
6. **Swipe to complete with Undo**, and **dark mode** that is remembered after a restart.

## SLA rules

The SLA status is calculated every time it is shown and is never saved, so it can never go out of date.

| Status | Rule |
|---|---|
| Completed | The task status is Done |
| Overdue | Not done and the deadline has been reached or passed |
| At Risk | Not done and 48 hours or less are left, **or** less than 25% of the time between creation and deadline is left |
| On Track | Everything else |

Health score: each task scores On Track 100, Completed on time 100, Completed late 60, At Risk 50, Overdue 0. The ring shows the average.

Workload: 0 to 2 open tasks is Available, 3 to 4 is Busy, 5 or more is Overloaded.

## Screens

1. Sign In and User Selection (profile picker plus 4 digit PIN)
2. Dashboard (health ring, stat tiles, Needs Attention)
3. Task List (search, SLA filter chips, Mine filter, sort, swipe to complete)
4. Task Details (SLA card, status switcher, activity timeline, edit, delete)
5. Create and Edit Task (validated form)
6. Team Members (workload meter per member)
7. Member Profile (contact, numbers, assigned tasks)
8. Add Member (validated form with duplicate email check)
9. Profile and Settings (dark mode, SLA rules, about, sign out)

## Technical decisions

**Local storage.** SQLite (`sqflite`) stores members, tasks and activity because they are related records: a task points to its assignee and an activity row points to its task. Foreign keys keep that data consistent and `ON DELETE CASCADE` removes a task's history with it. `shared_preferences` stores only two small settings: the signed in user id and the dark mode choice.

**State management.** `setState()` in StatefulWidgets. Each screen loads data from SQLite into its State, and every change follows the same loop: user action, write to SQLite, reload, `setState()`, and the UI rebuilds.

**Navigation.** A bottom `NavigationBar` switches between four tabs. Other screens are opened with named routes defined in one place (`AppRoutes` in `lib/app.dart`). Screens pass only ids or objects as route arguments and refresh when the pushed screen returns.

**Validation.** Form validators live in `lib/logic/validators.dart` and return a message instead of throwing, because bad input is expected. Custom `FormField`s let the assignee chips and deadline picker take part in normal Form validation.

## Project structure

```
lib/
  main.dart                 start up, restore session and theme
  app.dart                  MaterialApp, theme switch, named routes
  theme.dart                colours, SLA colours and icons
  models/                   Member, TaskItem, Activity
  data/                     SQLite database and session
  logic/                    SLA rules, validators, formatting
  widgets/                  shared UI pieces (TaskCard, SlaBadge, Panel...)
  screens/                  one folder per feature
test/
  sla_test.dart             SLA rule boundaries and health score
  validators_test.dart      every form rule
```

## Run it

Requires Flutter 3.27 or newer.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Run on an Android emulator or a real phone. Demo PIN for every seeded member: `1234`.

To reset the demo data, uninstall the app from the emulator and run it again.
