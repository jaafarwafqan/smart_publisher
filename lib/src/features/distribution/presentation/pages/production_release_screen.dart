import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/release/release_config.dart';

class ProductionReleaseScreen extends ConsumerStatefulWidget {
  const ProductionReleaseScreen({super.key});

  @override
  ConsumerState<ProductionReleaseScreen> createState() => _ProductionReleaseScreenState();
}

class _ProductionReleaseScreenState extends ConsumerState<ProductionReleaseScreen> {
  late final List<_ReleaseCheckItem> _checks;

  @override
  void initState() {
    super.initState();
    _checks = <_ReleaseCheckItem>[
      _ReleaseCheckItem(label: 'All critical tests passed'),
      _ReleaseCheckItem(label: 'flutter analyze reports no issues'),
      _ReleaseCheckItem(label: 'API contracts validated for v1 endpoints'),
      _ReleaseCheckItem(label: 'Security keys and secrets verified'),
      _ReleaseCheckItem(label: 'Queue retry and circuit breaker checks completed'),
      _ReleaseCheckItem(label: 'Observability dashboards verified'),
      _ReleaseCheckItem(label: 'Incident runbook reviewed with on-call team'),
      _ReleaseCheckItem(label: 'Rollback strategy confirmed and tested'),
      _ReleaseCheckItem(label: 'Canary release percentage approved'),
      _ReleaseCheckItem(label: 'Stakeholder sign-off captured'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final config = ReleaseConfig.fromEnvironment();
    final completed = _checks.where((item) => item.done).length;
    final progress = _checks.isEmpty ? 0.0 : completed / _checks.length;
    final ready = progress >= 1.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Production Release')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Release Channel: ${config.channel.name.toUpperCase()}'),
                  const SizedBox(height: 6),
                  Text('Canary Percent: ${config.canaryPercent}%'),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                  Text('Readiness: ${(progress * 100).toStringAsFixed(0)}%'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._checks.map(
            (item) => Card(
              child: CheckboxListTile(
                title: Text(item.label),
                value: item.done,
                onChanged: (value) {
                  setState(() {
                    item.done = value ?? false;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const <Widget>[
                  Text('Release Commands'),
                  SizedBox(height: 8),
                  SelectableText('flutter test'),
                  SelectableText('flutter analyze'),
                  SelectableText('bash scripts/release/deploy_release.sh'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: ready
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Production release initiated successfully.')),
                    );
                  }
                : null,
            icon: const Icon(Icons.rocket_launch_outlined),
            label: const Text('Start Production Release'),
          ),
        ],
      ),
    );
  }
}

class _ReleaseCheckItem {
  _ReleaseCheckItem({required this.label}) : done = false;

  final String label;
  bool done;
}
