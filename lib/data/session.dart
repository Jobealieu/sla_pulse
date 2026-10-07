import '../models/member.dart';

/// Who is signed in for this run of the app.
/// (The sign in flow and saving it to disk come later.)
class Session {
  Session._();

  static Member? current;
}
