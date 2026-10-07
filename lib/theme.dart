import 'package:flutter/material.dart';

import 'logic/sla.dart';

/// Brand colour. Every other UI colour is generated from this seed
/// by Material 3, so the whole app stays consistent.
const brand = Color(0xFF5B5BD6);

/// SLA colours are fixed (not generated) so a status always
/// looks the same on every screen and in both themes.
Color slaColor(SlaStatus s) => switch (s) {
      SlaStatus.onTrack => const Color(0xFF12B76A),
      SlaStatus.atRisk => const Color(0xFFF79009),
      SlaStatus.overdue => const Color(0xFFF04438),
      SlaStatus.completed => const Color(0xFF7A869A),
    };

/// Colour is never the only signal: every status also has its own icon.
IconData slaIcon(SlaStatus s) => switch (s) {
      SlaStatus.onTrack => Icons.trending_up_rounded,
      SlaStatus.atRisk => Icons.schedule_rounded,
      SlaStatus.overdue => Icons.error_outline_rounded,
      SlaStatus.completed => Icons.task_alt_rounded,
    };

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: brand, brightness: brightness).copyWith(
    surface: dark ? const Color(0xFF0E1116) : const Color(0xFFF5F6FA),
    surfaceContainerLow: dark ? const Color(0xFF171C24) : Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: 'Jakarta',
  );
}
