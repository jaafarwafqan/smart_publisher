import 'package:flutter/material.dart';

class DashboardStat {
  const DashboardStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({super.key, required this.stat});

  final DashboardStat stat;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(stat.icon, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 14),
            Text(
              stat.value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(stat.label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
