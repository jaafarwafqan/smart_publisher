import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_curves.dart';
import '../../../../core/theme/app_duration.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/adaptive_content_width.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../organizations/application/current_organization_access.dart';

class AdministrationScreen extends ConsumerStatefulWidget {
  const AdministrationScreen({super.key});

  @override
  ConsumerState<AdministrationScreen> createState() =>
      _AdministrationScreenState();
}

class _AdministrationScreenState extends ConsumerState<AdministrationScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final access = ref.watch(currentOrganizationAccessProvider);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final chevron = isRtl ? Icons.chevron_left : Icons.chevron_right;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.administrationAppBarTitle)),
      body: AdaptiveContentWidth(
        child: access.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _AdministrationAccessUnavailable(
            message: l10n.administrationReadOnlyNotice,
          ),
          data: (state) {
            if (!state.hasActiveOrganization) {
              return _AdministrationAccessUnavailable(
                message: l10n.administrationReadOnlyNotice,
              );
            }

            final canManagePolicies = state.hasPermission(
              OrganizationPermissions.settingsManage,
            );
            final canViewReleaseOps = canManagePolicies;
            final membershipRole = state.currentOrganization!.role
                .toUpperCase();

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: <Widget>[
                if (!canManagePolicies)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        l10n.administrationReadOnlyNotice,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (!canManagePolicies) const SizedBox(height: AppSpacing.sm),
                AnimatedContainer(
                  duration: AppDuration.slow,
                  curve: AppCurves.standard,
                  decoration: BoxDecoration(
                    color: canManagePolicies
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Card(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: Icon(
                        Icons.admin_panel_settings_outlined,
                        color: canManagePolicies
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      title: Text(l10n.administrationAccessProfileTitle),
                      subtitle: Text(
                        l10n.administrationAccessProfileSubtitle(
                          membershipRole,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  child: SwitchListTile(
                    title: Text(l10n.administrationMaintenanceModeTitle),
                    subtitle: Text(l10n.administrationOperationsUnavailable),
                    value: false,
                    // There is no authenticated/audited backend operation for
                    // this yet. A local switch would falsely imply production
                    // maintenance mode changed, so it stays visibly disabled.
                    onChanged: null,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  child: SwitchListTile(
                    title: Text(l10n.administrationFreezePublishingTitle),
                    subtitle: Text(l10n.administrationOperationsUnavailable),
                    value: false,
                    onChanged: null,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        leading: const Icon(Icons.history_outlined),
                        title: Text(l10n.administrationReleaseHistoryTitle),
                        subtitle: Text(
                          l10n.administrationReleaseHistorySubtitle,
                        ),
                        trailing: Icon(chevron),
                        onTap: canViewReleaseOps
                            ? () =>
                                  context.push(RouteNames.productionReleasePath)
                            : null,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.health_and_safety_outlined),
                        title: Text(
                          l10n.administrationOperationalReadinessTitle,
                        ),
                        subtitle: Text(
                          l10n.administrationOperationalReadinessSubtitle,
                        ),
                        trailing: Icon(chevron),
                        onTap: canViewReleaseOps
                            ? () =>
                                  context.push(RouteNames.productionReleasePath)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.gavel_outlined),
                  label: Text(l10n.administrationApplyPoliciesButton),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdministrationAccessUnavailable extends StatelessWidget {
  const _AdministrationAccessUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppEmptyState(
        message: message,
        icon: Icons.admin_panel_settings_outlined,
        showCard: false,
      ),
    );
  }
}
