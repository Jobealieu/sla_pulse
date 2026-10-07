import 'package:flutter/material.dart';

import '../logic/sla.dart';
import '../theme.dart';

/// Pill that shows an SLA status with its colour AND icon.
class SlaBadge extends StatelessWidget {
  const SlaBadge(this.status, {super.key});

  final SlaStatus status;

  @override
  Widget build(BuildContext context) {
    final color = slaColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(slaIcon(status), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
