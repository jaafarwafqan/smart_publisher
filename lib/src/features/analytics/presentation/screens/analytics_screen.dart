import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/adaptive_content_width.dart';
import '../../../../shared/widgets/animated_count_text.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../dashboard/presentation/utils/platform_label.dart';
import '../../application/analytics_dashboard_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(analyticsDashboardProvider);
    final data = dataAsync.valueOrNull;
    final rows = data?.rows ?? const <PostAnalyticsViewModel>[];
    final dashboard = data?.dashboard;

    // AsyncLoading only means "no cached value to show yet" — a refresh()
    // keeps the previous rows/dashboard visible (copyWithPrevious) rather
    // than blanking the screen.
    final loading = dataAsync.isLoading && !dataAsync.hasValue;
    final errorMessage = dataAsync.hasError
        ? (dataAsync.error is StateError
              ? (dataAsync.error! as StateError).message
              : dataAsync.error.toString())
        : data?.dashboardErrorMessage;

    final totalReach =
        dashboard?.totalReach ??
        rows.fold<int>(0, (sum, row) => sum + row.metric.reach);
    final totalImpressions =
        dashboard?.totalImpressions ??
        rows.fold<int>(0, (sum, row) => sum + row.metric.impressions);
    final totalEngagement =
        dashboard?.totalEngagement ??
        rows.fold<int>(0, (sum, row) => sum + row.metric.engagement);
    final averageRate =
        dashboard?.averageEngagementRate ??
        (rows.isEmpty
            ? 0.0
            : rows.fold<double>(
                    0,
                    (sum, row) => sum + row.metric.engagementRate,
                  ) /
                  rows.length);

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.analyticsAppBarTitle)),
      body: AdaptiveContentWidth(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(analyticsDashboardProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: <Widget>[
              Text(
                l10n.analyticsSubtitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: <Widget>[
                  _MetricCard(
                    label: l10n.analyticsMetricReach,
                    value: totalReach,
                  ),
                  _MetricCard(
                    label: l10n.analyticsMetricImpressions,
                    value: totalImpressions,
                  ),
                  _MetricCard(
                    label: l10n.analyticsMetricEngagement,
                    value: totalEngagement,
                  ),
                  _MetricCard(
                    label: l10n.analyticsMetricAvgEngagementRate,
                    value: averageRate * 100,
                    suffix: '%',
                    fractionDigits: 2,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _RecommendationTile(
                          icon: Icons.schedule_outlined,
                          label: l10n.analyticsBestTimeToPost,
                          value: dashboard?.bestPublishHour == null
                              ? l10n.analyticsNotEnoughData
                              : _formatHour(
                                  dashboard!.bestPublishHour!,
                                  l10n.localeName,
                                ),
                        ),
                      ),
                      const VerticalDivider(width: 24),
                      Expanded(
                        child: _RecommendationTile(
                          icon: Icons.trending_up_outlined,
                          label: l10n.analyticsBestPlatform,
                          value: dashboard?.bestPlatform == null
                              ? l10n.analyticsNotEnoughData
                              : platformLabel(dashboard!.bestPlatform!),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (loading)
                const Center(child: CircularProgressIndicator())
              else if (errorMessage != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(errorMessage),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          onPressed: () => ref
                              .read(analyticsDashboardProvider.notifier)
                              .refresh(),
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.commonRetry),
                        ),
                      ],
                    ),
                  ),
                )
              else if (rows.isEmpty)
                AppEmptyState(
                  message: l10n.analyticsNoPostsYet,
                  icon: Icons.insights_outlined,
                )
              else
                ...rows.map(
                  (row) => Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            row.post.title.isEmpty
                                ? l10n.postUntitled
                                : row.post.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.sm,
                            children: <Widget>[
                              _MiniStat(
                                label: l10n.analyticsMetricReach,
                                value: '${row.metric.reach}',
                              ),
                              _MiniStat(
                                label: l10n.analyticsMetricImpressions,
                                value: '${row.metric.impressions}',
                              ),
                              _MiniStat(
                                label: l10n.analyticsMetricClicks,
                                value: '${row.metric.clicks}',
                              ),
                              _MiniStat(
                                label: l10n.analyticsMetricShares,
                                value: '${row.metric.shares}',
                              ),
                              _MiniStat(
                                label: l10n.analyticsMetricReactions,
                                value: '${row.metric.reactions}',
                              ),
                              _MiniStat(
                                label: l10n.analyticsMetricEngagementRate,
                                value:
                                    '${(row.metric.engagementRate * 100).toStringAsFixed(2)}%',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatHour(int hour, String localeName) {
  final dateTime = DateTime(2026, 1, 1, hour);
  return DateFormat.jm(localeName).format(dateTime);
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.suffix = '',
    this.fractionDigits = 0,
  });

  final String label;
  final num value;
  final String suffix;
  final int fractionDigits;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 165,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              AnimatedCountText(
                value: value,
                suffix: suffix,
                fractionDigits: fractionDigits,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$label: $value'),
    );
  }
}
