import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'theme.dart';

/// Every screen you can push has a name here. Screens call
/// Navigator.pushNamed with one of these names (plus arguments)
/// instead of importing each other, which keeps them decoupled.
class AppRoutes {
  static const home = '/home';

  static Route<dynamic>? generate(RouteSettings settings) {
    final Widget? page = switch (settings.name) {
      AppRoutes.home => const HomeShell(),
      _ => null,
    };
    if (page == null) return null;
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}

class SlaPulseApp extends StatelessWidget {
  const SlaPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SLA Pulse',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.light,
      home: const HomeShell(),
      onGenerateRoute: AppRoutes.generate,
    );
  }
}
