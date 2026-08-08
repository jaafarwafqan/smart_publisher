import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../analytics/domain/entities/analytics_summary_entity.dart';
import '../utils/platform_label.dart';
import 'dashboard_section_card.dart';

class PublishingHealthCard extends StatelessWidget {
  const PublishingHealthCard({
    super.key,
    required this.summary,
    required this.platformDistribution,
    required this.connectedAccounts,
    required this.totalAccounts,
  });

  final AnalyticsSummaryEntity summary;
  final Map<String, int> platformDistribution;
  final int connectedAccounts;
  final int totalAccounts;

  @override
  Widget build(BuildContext context) {
    final delivered = summary.published + summary.failed;
    final successRate = delivered == 0 ? 1.0 : summary.published / delivered;
    final needsAttention = delivered > 0 && summary.failed / delivered >= 0.05;

    final l10n = AppLocalizations.of(context)!;
    return DashboardSectionCard(
      title: l10n.publishingHealthTitle,
      subtitle: l10n.publishingHealthSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SuccessRateGauge(rate: successRate),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _StatusRow(
                      label: l10n.publishingHealthConnectedAccounts,
                      value: '$connectedAccounts/$totalAccounts',
                    ),
                    _StatusRow(
                      label: l10n.publishingHealthQueueHealth,
                      value: needsAttention
                          ? l10n.publishingHealthNeedsAttention
                          : l10n.publishingHealthStable,
                      isWarning: needsAttention,
                    ),
                    _StatusRow(
                      label: l10n.publishingHealthFailedDeliveries,
                      value: '${summary.failed}',
                      isWarning: summary.failed > 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (platformDistribution.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.publishingHealthDistributionByPlatform,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 160,
              child: _PlatformDistributionChart(
                distribution: platformDistribution,
              ),
            ),
          ] else ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            AppEmptyState(
              message: l10n.analyticsNotEnoughData,
              icon: Icons.bar_chart_outlined,
              compact: true,
              showCard: false,
              alignment: CrossAxisAlignment.start,
            ),
          ],
        ],
      ),
    );
  }
}

class _SuccessRateGauge extends StatelessWidget {
  const _SuccessRateGauge({required this.rate});

  final double rate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = (rate * 100).round();

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox(
            width: 96,
            height: 96,
            child: CircularProgressIndicator(
              value: rate.clamp(0, 1),
              strokeWidth: 10,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                rate >= 0.9 ? colorScheme.primary : colorScheme.error,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '$percent%',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                AppLocalizations.of(context)!.publishingHealthSuccess,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlatformDistributionChart extends StatelessWidget {
  const _PlatformDistributionChart({required this.distribution});

  final Map<String, int> distribution;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = entries.take(6).toList(growable: false);
    final maxCount = topEntries
        .map((entry) => entry.value)
        .fold<int>(0, (max, value) => value > max ? value : max);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxCount == 0 ? 1 : maxCount * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = platformLabel(topEntries[group.x].key);
              return BarTooltipItem(
                '$label\n${rod.toY.round()}',
                Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: colorScheme.onInverseSurface,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= topEntries.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    platformLabel(topEntries[index].key),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: <BarChartGroupData>[
          for (var i = 0; i < topEntries.length; i++)
            BarChartGroupData(
              x: i,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: topEntries[i].value.toDouble(),
                  color: colorScheme.primary,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  final String label;
  final String value;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isWarning ? colorScheme.error : colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
