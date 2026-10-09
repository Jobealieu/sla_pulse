import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'data/session.dart';
import 'models/member.dart';
import 'models/task_item.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/home_shell.dart';
import 'screens/tasks/task_details_screen.dart';
import 'screens/tasks/task_form_screen.dart';
import 'screens/team/add_member_screen.dart';
import 'screens/team/member_profile_screen.dart';
import 'theme.dart';

/// Every screen you can push has a name here. Screens call
/// Navigator.pushNamed with one of these names (plus arguments)
/// instead of importing each other, which keeps them decoupled.
class AppRoutes {
  static const signIn = '/signin';
  static const home = '/home';
  static const task = '/task';
  static const taskForm = '/task/form';
  static const member = '/member';
  static const newMember = '/member/new';

  static Route<dynamic>? generate(RouteSettings settings) {
    final Widget? page = switch (settings.name) {
      AppRoutes.signIn => const SignInScreen(),
      AppRoutes.home => const HomeShell(),
      AppRoutes.task => TaskDetailsScreen(taskId: settings.arguments! as int),
      AppRoutes.taskForm =>
        TaskFormScreen(existing: settings.arguments as TaskItem?),
      AppRoutes.member =>
        MemberProfileScreen(member: settings.arguments! as Member),
      AppRoutes.newMember => const AddMemberScreen(),
      _ => null,
    };
    if (page == null) return null;
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}

class SlaPulseApp extends StatefulWidget {
  const SlaPulseApp({super.key, this.startDark = false, this.signedIn = false});

  final bool startDark;
  final bool signedIn;

  /// Lets any screen below reach the theme switch: SlaPulseApp.of(context).setDark(true)
  static SlaPulseAppState of(BuildContext context) =>
      context.findAncestorStateOfType<SlaPulseAppState>()!;

  @override
  State<SlaPulseApp> createState() => SlaPulseAppState();
}

class SlaPulseAppState extends State<SlaPulseApp> {
  late bool _dark = widget.startDark;

  bool get isDark => _dark;

  /// setState rebuilds MaterialApp with the new themeMode,
  /// then the choice is saved so it survives a restart.
  Future<void> setDark(bool value) async {
    setState(() => _dark = value);
    await Session.setDarkMode(value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SLA Pulse',
      debugShowCheckedModeBanner: false,
      // Let mouse drags scroll lists too (the emulator often sends mouse, not touch).
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: PointerDeviceKind.values.toSet(),
      ),
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      home: widget.signedIn ? const HomeShell() : const SignInScreen(),
      onGenerateRoute: AppRoutes.generate,
    );
  }
}
