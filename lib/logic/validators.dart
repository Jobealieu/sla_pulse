/// Form validators. Each returns null when the value is valid,
/// or a message that the TextFormField shows under the field.
/// Expected bad input is a normal case, so we return a message
/// instead of throwing.
class Validators {
  Validators._();

  static final _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static final _name = RegExp(r"^[A-Za-z][A-Za-z .']*$");
  static final _pin = RegExp(r'^\d{4}$');

  static String? taskTitle(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Give the task a title';
    if (v.length < 3) return 'Title must be at least 3 characters';
    if (v.length > 60) return 'Keep the title under 60 characters';
    return null;
  }

  static String? description(String? value) {
    if ((value?.trim().length ?? 0) > 300) return 'Keep the description under 300 characters';
    return null;
  }

  static String? assignee(int? memberId) => memberId == null ? 'Choose who owns this task' : null;

  /// A new deadline must be in the future. When editing, an unchanged
  /// deadline is allowed even if it already passed (the task is just Overdue).
  static String? deadline(DateTime? value, {required DateTime now, DateTime? original}) {
    if (value == null) return 'Pick a deadline';
    if (value == original) return null;
    if (!value.isAfter(now)) return 'The deadline must be in the future';
    return null;
  }

  static String? personName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter a name';
    if (v.length < 2) return 'Name is too short';
    if (v.length > 40) return 'Keep the name under 40 characters';
    if (!_name.hasMatch(v)) return 'Use letters, spaces, dots or apostrophes only';
    return null;
  }

  static String? role(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter a role';
    if (v.length > 40) return 'Keep the role under 40 characters';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter an email address';
    if (!_email.hasMatch(v)) return 'Enter a valid email, like name@alustudent.com';
    return null;
  }

  static String? pin(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter your 4 digit PIN';
    if (!_pin.hasMatch(v)) return 'PIN must be exactly 4 digits';
    return null;
  }
}
