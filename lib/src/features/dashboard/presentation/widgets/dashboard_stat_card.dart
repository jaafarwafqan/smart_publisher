import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/animated_count_text.dart';

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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(stat.icon, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: AppSpacing.lg),
            _StatValue(value: stat.value),
            const SizedBox(height: AppSpacing.xs),
            Text(stat.label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _StatValue extends StatelessWidget {
  const _StatValue({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800);
    final numericValue = int.tryParse(value);

    if (numericValue == null) {
      return Text(value, style: style);
    }

    return AnimatedCountText(value: numericValue, style: style);
  }
}
