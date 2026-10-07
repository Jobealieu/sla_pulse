import 'package:flutter/material.dart';

import 'app.dart';
import 'data/database.dart';
import 'data/session.dart';

Future<void> main() async {
  // Needed before using plugins (SQLite) ahead of runApp.
  WidgetsFlutterBinding.ensureInitialized();
  // Until the sign in screen exists, start as the first member.
  final members = await AppDatabase.instance.members();
  Session.current = members.isEmpty ? null : members.first;
  runApp(const SlaPulseApp());
}
