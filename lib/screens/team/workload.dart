import 'package:flutter/material.dart';

import '../../logic/sla.dart';
import '../../theme.dart';

/// Open tasks at which a person counts as fully loaded.
const fullLoad = 5;

/// Workload rule: 0 to 2 open tasks Available, 3 to 4 Busy, 5 or more Overloaded.
({String label, Color color}) workloadOf(int openTasks) {
  if (openTasks >= fullLoad) return (label: 'Overloaded', color: slaColor(SlaStatus.overdue));
  if (openTasks >= 3) return (label: 'Busy', color: slaColor(SlaStatus.atRisk));
  return (label: 'Available', color: slaColor(SlaStatus.onTrack));
}

/// Bar plus label, so load is readable without relying on colour alone.
class WorkloadMeter extends StatelessWidget {
  const WorkloadMeter({super.key, required this.openTasks});

  final int openTasks;

  @override
  Widget build(BuildContext context) {
    final load = workloadOf(openTasks);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (openTasks / fullLoad).clamp(0.0, 1.0),
              minHeight: 6,
              color: load.color,
              backgroundColor: load.color.withValues(alpha: 0.15),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(load.label, style: TextStyle(color: load.color, fontWeight: FontWeight.w700, fontSize: 12)),
      ],
    );
  }
}
