import 'package:shared_preferences/shared_preferences.dart';

import '../models/member.dart';
import 'database.dart';

/// Who is signed in, plus the theme choice.
///
/// Why SharedPreferences here (and not SQLite): these are two tiny
/// key value settings, not records. SharedPreferences is built exactly
/// for small values like that.
class Session {
  Session._();

  /// The signed in member for this run of the app.
  static Member? current;

  static const _userKey = 'current_user_id';
  static const _darkKey = 'dark_mode';

  static Future<void> signIn(Member m) async {
    current = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userKey, m.id!);
  }

  static Future<void> signOut() async {
    current = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  /// Called once at startup. Returns true if a saved user was found,
  /// so the app can skip the sign in screen.
  static Future<bool> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_userKey);
    if (id == null) return false;
    current = await AppDatabase.instance.member(id);
    return current != null;
  }

  static Future<bool> darkMode() async =>
      (await SharedPreferences.getInstance()).getBool(_darkKey) ?? false;

  static Future<void> setDarkMode(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_darkKey, value);
}
