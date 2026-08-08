import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../shared/widgets/adaptive_content_width.dart';
import '../../../../shared/widgets/animated_count_text.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../dashboard/presentation/utils/platform_label.dart';
import '../../domain/entities/analytics_dashboard_entity.dart';
import '../../domain/entities/analytics_metric_entity.dart';
import '../../../posts/domain/entities/post_entity.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  bool _loading = true;
  List<_PostAnalyticsViewModel> _rows = const <_PostAnalyticsViewModel>[];
  AnalyticsDashboardEntity? _dashboard;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final postsResult = await ref.read(postRepositoryProvider).getPosts();

    if (postsResult.isFailure) {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _loading = false;
        _error = postsResult.message ?? l10n.analyticsFailedToLoad;
      });
      return;
    }

    final posts = postsResult.data ?? const <PostEntity>[];
    final repository = ref.read(analyticsRepositoryProvider);
    final rows = <_PostAnalyticsViewModel>[];

    if (posts.isNotEmpty) {
      final metricsResult = await repository.getPostsMetrics(
        posts.map((post) => post.id).toList(growable: false),
      );

      if (metricsResult.isFailure) {
        if (!mounted) {
          return;
        }
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _loading = false;
          _error = metricsResult.message ?? l10n.analyticsFailedToLoad;
        });
        return;
      }

      final metricsByPostId = <String, AnalyticsMetricEntity>{
        for (final metric
            in metricsResult.data ?? const <AnalyticsMetricEntity>[])
          metric.postId: metric,
      };

      for (final post in posts) {
        final metric = metricsByPostId[post.id];
        if (metric != null) {
          rows.add(_PostAnalyticsViewModel(post: post, metric: metric));
        }
      }
    }

    rows.sort((a, b) => b.metric.engagement.compareTo(a.metric.engagement));

    final dashboardResult = await repository.getDashboard();

    if (!mounted) {
      return;
    }

    setState(() {
      _rows = rows;
      _dashboard = dashboardResult.data;
      _error = dashboardResult.isFailure ? dashboardResult.message : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalReach =
        _dashboard?.totalReach ??
        _rows.fold<int>(0, (sum, row) => sum + row.metric.reach);
    final totalImpressions =
        _dashboard?.totalImpressions ??
        _rows.fold<int>(0, (sum, row) => sum + row.metric.impressions);
    final totalEngagement =
        _dashboard?.totalEngagement ??
        _rows.fold<int>(0, (sum, row) => sum + row.metric.engagement);
    final averageRate =
        _dashboard?.averageEngagementRate ??
        (_rows.isEmpty
            ? 0.0
            : _rows.fold<double>(
                    0,
                    (sum, row) => sum + row.metric.engagementRate,
                  ) /
                  _rows.length);

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.analyticsAppBarTitle)),
      body: AdaptiveContentWidth(
        child: RefreshIndicator(
          onRefresh: _loadAnalytics,
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
                spacing: 10,
                runSpacing: 10,
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
                          value: _dashboard?.bestPublishHour == null
                              ? l10n.analyticsNotEnoughData
                              : _formatHour(
                                  _dashboard!.bestPublishHour!,
                                  l10n.localeName,
                                ),
                        ),
                      ),
                      const VerticalDivider(width: 24),
                      Expanded(
                        child: _RecommendationTile(
                          icon: Icons.trending_up_outlined,
                          label: l10n.analyticsBestPlatform,
                          value: _dashboard?.bestPlatform == null
                              ? l10n.analyticsNotEnoughData
                              : platformLabel(_dashboard!.bestPlatform!),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(_error!),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          onPressed: _loadAnalytics,
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.commonRetry),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_rows.isEmpty)
                AppEmptyState(
                  message: l10n.analyticsNoPostsYet,
                  icon: Icons.insights_outlined,
                )
              else
                ..._rows.map(
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
                            spacing: 12,
                            runSpacing: 10,
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

class _PostAnalyticsViewModel {
  const _PostAnalyticsViewModel({required this.post, required this.metric});

  final PostEntity post;
  final AnalyticsMetricEntity metric;
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
