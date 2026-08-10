import 'package:flutter/material.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/models/platform_help_status.dart';

/// Renders one platform's real, verified readiness — shared by
/// `AboutSystemScreen`'s "المنصات المدعومة" section and the guide's "بقية
/// المنصات" section, so the classification is computed once
/// ([platformHelpStatuses]) and only ever rendered twice, never
/// re-derived.
class PlatformStatusCard extends StatelessWidget {
  const PlatformStatusCard({super.key, required this.status});

  final PlatformHelpStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, tone) = switch (status.readiness) {
      PlatformReadiness.availableBeta => (
        l10n.platformStatusAvailableBeta,
        PillTone.success,
      ),
      PlatformReadiness.partial => (
        l10n.platformStatusPartial,
        PillTone.warning,
      ),
      PlatformReadiness.comingSoonMock => (
        l10n.platformStatusComingSoon,
        PillTone.neutral,
      ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  status.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                StatusPill(label: label, tone: tone),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                _capabilityChip(
                  context,
                  l10n.platformStatusConnect,
                  status.canConnect,
                ),
                _capabilityChip(
                  context,
                  l10n.platformStatusDiscoverPages,
                  status.canDiscoverPages,
                ),
                _capabilityChip(
                  context,
                  l10n.platformStatusTestConnection,
                  status.canTestConnection,
                ),
                _capabilityChip(
                  context,
                  l10n.platformStatusPublish,
                  status.canPublish,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _capabilityChip(BuildContext context, String label, bool value) {
    final l10n = AppLocalizations.of(context)!;
    return StatusPill(
      icon: value ? Icons.check_circle_outline : Icons.remove_circle_outline,
      label:
          '$label: ${value ? l10n.platformStatusYes : l10n.platformStatusNo}',
      tone: value ? PillTone.success : PillTone.neutral,
    );
  }
}
