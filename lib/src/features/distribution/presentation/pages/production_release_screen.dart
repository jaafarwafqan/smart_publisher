import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/release/release_config.dart';

class ProductionReleaseScreen extends ConsumerStatefulWidget {
  const ProductionReleaseScreen({super.key});

  @override
  ConsumerState<ProductionReleaseScreen> createState() =>
      _ProductionReleaseScreenState();
}

class _ProductionReleaseScreenState
    extends ConsumerState<ProductionReleaseScreen> {
  List<_ReleaseCheckItem>? _checks;

  List<_ReleaseCheckItem> _buildChecks(AppLocalizations l10n) {
    return <_ReleaseCheckItem>[
      _ReleaseCheckItem(label: l10n.releaseCheckTestsPassed),
      _ReleaseCheckItem(label: l10n.releaseCheckAnalyzeClean),
      _ReleaseCheckItem(label: l10n.releaseCheckApiContracts),
      _ReleaseCheckItem(label: l10n.releaseCheckSecretsVerified),
      _ReleaseCheckItem(label: l10n.releaseCheckQueueChecks),
      _ReleaseCheckItem(label: l10n.releaseCheckObservability),
      _ReleaseCheckItem(label: l10n.releaseCheckRunbook),
      _ReleaseCheckItem(label: l10n.releaseCheckRollback),
      _ReleaseCheckItem(label: l10n.releaseCheckSignoff),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final checks = _checks ??= _buildChecks(l10n);
    final config = ReleaseConfig.fromEnvironment();
    final completed = checks.where((item) => item.done).length;
    final progress = checks.isEmpty ? 0.0 : completed / checks.length;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.releaseAppBarTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.releaseChannelLabel(config.wireValue.toUpperCase()),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                  Text(
                    l10n.releaseReadinessLabel(
                      (progress * 100).toStringAsFixed(0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(l10n.releaseActionsUnavailable),
            ),
          ),
          const SizedBox(height: 12),
          ...checks.map(
            (item) => Card(
              child: CheckboxListTile(
                title: Text(item.label),
                value: item.done,
                // A local checkbox cannot attest that CI, staging, or a
                // rollback actually completed. This screen is read-only
                // until a backend release/audit API exists.
                onChanged: null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.releaseCommandsTitle),
                  const SizedBox(height: 8),
                  const SelectableText('flutter test'),
                  const SelectableText('flutter analyze'),
                  const SelectableText(
                    'bash scripts/release/deploy_release.sh',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.rocket_launch_outlined),
            label: Text(l10n.releaseStartButton),
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
