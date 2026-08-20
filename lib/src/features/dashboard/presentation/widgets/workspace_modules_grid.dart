import 'package:flutter/material.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/status_pill.dart';
import 'dashboard_section_card.dart';

class WorkspaceModule {
  const WorkspaceModule({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  /// Only set where a real count is already available with no new fetch
  /// (see dashboard_screen.dart) — never invented just to fill a badge.
  final String? badge;
}

class WorkspaceModulesGrid extends StatelessWidget {
  const WorkspaceModulesGrid({super.key, required this.modules});

  final List<WorkspaceModule> modules;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DashboardSectionCard(
      title: l10n.workspaceModulesTitle,
      subtitle: l10n.workspaceModulesSubtitle,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 4
              : constraints.maxWidth >= 640
              ? 3
              : 2;
          final spacing = 12.0;
          final cardWidth =
              (constraints.maxWidth - (spacing * (columns - 1))) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: modules
                .map(
                  (module) => SizedBox(
                    width: cardWidth,
                    child: _ModuleTile(module: module),
                  ),
                )
                .toList(growable: false),
          );
        },
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.module});

  final WorkspaceModule module;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        label: module.title,
        hint: module.description,
        child: InkWell(
          onTap: module.onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Icon(module.icon, color: colorScheme.primary),
                    if (module.badge != null)
                      StatusPill(label: module.badge!, tone: PillTone.success),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  module.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  module.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
