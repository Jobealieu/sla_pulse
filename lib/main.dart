import 'package:flutter/material.dart';

import 'app.dart';
import 'data/session.dart';

Future<void> main() async {
  // Needed before using plugins (SQLite, SharedPreferences) ahead of runApp.
  WidgetsFlutterBinding.ensureInitialized();
  final dark = await Session.darkMode();
  final signedIn = await Session.restore();
  runApp(SlaPulseApp(startDark: dark, signedIn: signedIn));
}
