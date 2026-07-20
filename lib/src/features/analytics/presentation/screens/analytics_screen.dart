import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
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
    final posts = postsResult.data ?? const <PostEntity>[];

    final repository = ref.read(analyticsRepositoryProvider);
    final rows = <_PostAnalyticsViewModel>[];

    for (final post in posts) {
      final metricResult = await repository.getPostMetrics(post.id);
      if (metricResult.isSuccess && metricResult.data != null) {
        rows.add(
          _PostAnalyticsViewModel(post: post, metric: metricResult.data!),
        );
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

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            Text(
              'Performance overview, post-level metrics, and engagement trends.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _MetricCard(label: 'Reach', value: '$totalReach'),
                _MetricCard(label: 'Impressions', value: '$totalImpressions'),
                _MetricCard(label: 'Engagement', value: '$totalEngagement'),
                _MetricCard(
                  label: 'Avg. Engagement Rate',
                  value: '${(averageRate * 100).toStringAsFixed(2)}%',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_rows.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No posts available for analytics yet.'),
                ),
              )
            else
              ..._rows.map(
                (row) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          row.post.title.isEmpty
                              ? 'Untitled post'
                              : row.post.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: <Widget>[
                            _MiniStat(
                              label: 'Reach',
                              value: '${row.metric.reach}',
                            ),
                            _MiniStat(
                              label: 'Impressions',
                              value: '${row.metric.impressions}',
                            ),
                            _MiniStat(
                              label: 'Clicks',
                              value: '${row.metric.clicks}',
                            ),
                            _MiniStat(
                              label: 'Shares',
                              value: '${row.metric.shares}',
                            ),
                            _MiniStat(
                              label: 'Reactions',
                              value: '${row.metric.reactions}',
                            ),
                            _MiniStat(
                              label: 'Engagement Rate',
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
    );
  }
}

class _PostAnalyticsViewModel {
  const _PostAnalyticsViewModel({required this.post, required this.metric});

  final PostEntity post;
  final AnalyticsMetricEntity metric;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 165,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              Text(
                value,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$label: $value'),
    );
  }
}
