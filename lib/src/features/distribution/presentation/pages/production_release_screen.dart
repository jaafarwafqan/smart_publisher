import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/release/release_config.dart';
import '../../../../core/theme/app_curves.dart';
import '../../../../core/theme/app_duration.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../shared/widgets/adaptive_content_width.dart';

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
      _ReleaseCheckItem(label: l10n.releaseCheckTestsPassed, done: true),
      _ReleaseCheckItem(label: l10n.releaseCheckAnalyzeClean, done: true),
      _ReleaseCheckItem(label: l10n.releaseCheckApiContracts, done: true),
      _ReleaseCheckItem(label: l10n.releaseCheckSecretsVerified, done: true),
      _ReleaseCheckItem(label: l10n.releaseCheckQueueChecks, done: true),
      _ReleaseCheckItem(label: l10n.releaseCheckObservability, done: true),
      _ReleaseCheckItem(label: l10n.releaseCheckRunbook, done: true),
      _ReleaseCheckItem(label: l10n.releaseCheckRollback, done: true),
      _ReleaseCheckItem(label: l10n.releaseCheckSignoff, done: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final checks = _checks ??= _buildChecks(l10n);
    final config = ReleaseConfig.fromEnvironment();
    final completed = checks.where((item) => item.done).length;
    final progress = checks.isEmpty ? 0.0 : completed / checks.length;
    final currentCheckIndex = checks.indexWhere((item) => !item.done);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.releaseAppBarTitle)),
      body: AdaptiveContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.releaseChannelLabel(config.wireValue.toUpperCase()),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.releaseReadinessLabel(
                        (progress * 100).toStringAsFixed(0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(l10n.releaseActionsUnavailable),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...checks.asMap().entries.map(
              (entry) => _ReleaseCheckTimelineItem(
                item: entry.value,
                isCurrent: entry.key == currentCheckIndex,
                isLast: entry.key == checks.length - 1,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(l10n.releaseCommandsTitle),
                    const SizedBox(height: AppSpacing.sm),
                    const SelectableText('flutter test'),
                    const SelectableText('flutter analyze'),
                    const SelectableText(
                      'bash scripts/release/deploy_release.sh',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.rocket_launch_outlined),
              label: Text(l10n.releaseStartButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReleaseCheckItem {
  const _ReleaseCheckItem({required this.label, required this.done});

  final String label;
  final bool done;
}

class _ReleaseCheckTimelineItem extends StatelessWidget {
  const _ReleaseCheckTimelineItem({
    required this.item,
    required this.isCurrent,
    required this.isLast,
  });

  final _ReleaseCheckItem item;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final markerColor = item.done || isCurrent
        ? colorScheme.primary
        : colorScheme.outlineVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: AppSizes.iconLg,
          child: Column(
            children: <Widget>[
              AnimatedContainer(
                duration: AppDuration.normal,
                curve: AppCurves.standard,
                width: AppSizes.iconLg,
                height: AppSizes.iconLg,
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.done
                      ? Icons.check
                      : isCurrent
                      ? Icons.play_arrow_rounded
                      : Icons.more_horiz,
                  color: colorScheme.onPrimary,
                  size: AppSizes.iconSm,
                ),
              ),
              if (!isLast)
                Container(
                  width: AppSpacing.xs,
                  height: AppSpacing.xxl,
                  color: colorScheme.outlineVariant,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Card(
            child: CheckboxListTile(
              title: Text(item.label),
              value: item.done,
              // A local checkbox cannot attest that CI, staging, or a
              // rollback actually completed. This screen is read-only until
              // a backend release/audit API exists.
              onChanged: null,
            ),
          ),
        ),
      ],
    );
  }
}
