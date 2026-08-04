import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/router/route_names.dart';
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
      body: access.when(
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
          final membershipRole = state.currentOrganization!.role.toUpperCase();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: <Widget>[
              if (!canManagePolicies)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      l10n.administrationReadOnlyNotice,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: Text(l10n.administrationAccessProfileTitle),
                  subtitle: Text(
                    l10n.administrationAccessProfileSubtitle(membershipRole),
                  ),
                ),
              ),
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
              Card(
                child: SwitchListTile(
                  title: Text(l10n.administrationFreezePublishingTitle),
                  subtitle: Text(l10n.administrationOperationsUnavailable),
                  value: false,
                  onChanged: null,
                ),
              ),
              Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.history_outlined),
                      title: Text(l10n.administrationReleaseHistoryTitle),
                      subtitle: Text(l10n.administrationReleaseHistorySubtitle),
                      trailing: Icon(chevron),
                      onTap: canViewReleaseOps
                          ? () => context.go(RouteNames.productionReleasePath)
                          : null,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.health_and_safety_outlined),
                      title: Text(l10n.administrationOperationalReadinessTitle),
                      subtitle: Text(
                        l10n.administrationOperationalReadinessSubtitle,
                      ),
                      trailing: Icon(chevron),
                      onTap: canViewReleaseOps
                          ? () => context.go(RouteNames.productionReleasePath)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.gavel_outlined),
                label: Text(l10n.administrationApplyPoliciesButton),
              ),
            ],
          );
        },
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
