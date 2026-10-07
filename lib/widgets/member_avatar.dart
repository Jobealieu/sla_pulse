import 'package:flutter/material.dart';

import '../models/member.dart';

const _palette = [
  Color(0xFF5B5BD6),
  Color(0xFF0E9384),
  Color(0xFFDD2590),
  Color(0xFFDC6803),
  Color(0xFF1570EF),
  Color(0xFF7839EE),
];

/// Initials in a coloured circle. The colour comes from the member id,
/// so the same person always gets the same colour.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar(this.member, {super.key, this.size = 40});

  final Member? member;
  final double size;

  @override
  Widget build(BuildContext context) {
    final m = member;
    final color = _palette[(m?.id ?? 0) % _palette.length];
    return Semantics(
      label: m?.name ?? 'Unassigned',
      excludeSemantics: true,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: color.withValues(alpha: 0.16),
        child: Text(
          m?.initials ?? '?',
          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: size * 0.36),
        ),
      ),
    );
  }
}
