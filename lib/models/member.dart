/// A person on the team. Stored in the `members` table.
class Member {
  final int? id;
  final String name;
  final String role;
  final String email;

  /// Demo sign in PIN. There is no real authentication in this app,
  /// so the PIN only protects against tapping the wrong profile.
  final String pin;

  const Member({
    this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.pin,
  });

  List<String> get _parts => name.trim().split(RegExp(r'\s+'));

  String get firstName => _parts.first;

  String get initials {
    final parts = _parts;
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'role': role,
        'email': email,
        'pin': pin,
      };

  factory Member.fromMap(Map<String, Object?> map) => Member(
        id: map['id'] as int,
        name: map['name'] as String,
        role: map['role'] as String,
        email: map['email'] as String,
        pin: map['pin'] as String,
      );
}
