import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_curves.dart';
import '../../../../core/theme/app_duration.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/adaptive_content_width.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../core/router/route_names.dart';
import '../../application/current_organization_access.dart';
import '../../domain/entities/organization_entity.dart';

class OrganizationSwitcherScreen extends ConsumerStatefulWidget {
  const OrganizationSwitcherScreen({super.key});

  @override
  ConsumerState<OrganizationSwitcherScreen> createState() =>
      _OrganizationSwitcherScreenState();
}

class _OrganizationSwitcherScreenState
    extends ConsumerState<OrganizationSwitcherScreen> {
  int? _switchingId;

  Future<void> _switchTo(OrganizationEntity organization) async {
    final current = ref
        .read(currentOrganizationAccessProvider)
        .valueOrNull
        ?.currentOrganization;
    if (current?.id == organization.id) {
      return;
    }

    setState(() => _switchingId = organization.id);
    final result = await ref
        .read(organizationRepositoryProvider)
        .switchTo(organization.id);

    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() => _switchingId = null);
    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? l10n.orgSwitcherFailedToSwitch),
        ),
      );
      return;
    }

    // Refresh the one shared organization/membership source before entering
    // a protected route. This removes stale grants from the prior tenant.
    ref.invalidate(currentOrganizationAccessProvider);
    try {
      final refreshed = await ref.read(
        currentOrganizationAccessProvider.future,
      );
      if (!refreshed.hasActiveOrganization) {
        throw const OrganizationAccessException(
          'No active organization was returned after switching.',
        );
      }
    } on OrganizationAccessException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.orgSwitcherFailedToLoad)));
      return;
    }

    if (!mounted) {
      return;
    }
    context.go(RouteNames.dashboardPath);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final access = ref.watch(currentOrganizationAccessProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.orgSwitcherAppBarTitle)),
      body: AdaptiveContentWidth(
        child: access.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _OrganizationLoadError(
            message: error is OrganizationAccessException
                ? error.message
                : l10n.orgSwitcherFailedToLoad,
            onRetry: () => ref.invalidate(currentOrganizationAccessProvider),
          ),
          data: (state) => _OrganizationList(
            organizations: state.memberships,
            activeOrganizationId: state.currentOrganization?.id,
            switchingId: _switchingId,
            l10n: l10n,
            onSwitch: _switchTo,
          ),
        ),
      ),
    );
  }
}

class _OrganizationList extends StatelessWidget {
  const _OrganizationList({
    required this.organizations,
    required this.activeOrganizationId,
    required this.switchingId,
    required this.l10n,
    required this.onSwitch,
  });

  final List<OrganizationEntity> organizations;
  final int? activeOrganizationId;
  final int? switchingId;
  final AppLocalizations l10n;
  final ValueChanged<OrganizationEntity> onSwitch;

  @override
  Widget build(BuildContext context) {
    if (organizations.isEmpty) {
      return Center(
        child: AppEmptyState(
          message: l10n.orgSwitcherEmpty,
          icon: Icons.business_outlined,
          showCard: false,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: organizations.length + (activeOrganizationId == null ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (activeOrganizationId == null && index == 0) {
          return Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(l10n.orgSwitcherSelectActive),
            ),
          );
        }

        final organization =
            organizations[activeOrganizationId == null ? index - 1 : index];
        final isActive = activeOrganizationId == organization.id;
        final isSwitching = switchingId == organization.id;

        return Semantics(
          selected: isActive,
          child: AnimatedContainer(
            duration: AppDuration.slow,
            curve: AppCurves.standard,
            padding: EdgeInsetsDirectional.only(
              start: isActive ? AppSpacing.xs : 0,
            ),
            decoration: BoxDecoration(
              color: isActive ? Theme.of(context).colorScheme.primary : null,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Card(
              color: isActive
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    organization.name.isEmpty
                        ? '?'
                        : organization.name[0].toUpperCase(),
                  ),
                ),
                title: Text(organization.name),
                subtitle: Text(_organizationRoleLabel(organization.role, l10n)),
                trailing: AnimatedSwitcher(
                  duration: AppDuration.normal,
                  switchInCurve: AppCurves.standard,
                  switchOutCurve: AppCurves.standard,
                  child: isActive
                      ? Chip(
                          key: const ValueKey<String>('active'),
                          avatar: const Icon(Icons.check_circle_outline),
                          label: Text(l10n.orgSwitcherActiveChip),
                        )
                      : isSwitching
                      ? const SizedBox(
                          key: ValueKey<String>('switching'),
                          width: AppSizes.iconMd,
                          height: AppSizes.iconMd,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : OutlinedButton(
                          key: const ValueKey<String>('available'),
                          onPressed: () => onSwitch(organization),
                          child: Text(l10n.orgSwitcherSwitchButton),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OrganizationLoadError extends StatelessWidget {
  const _OrganizationLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.orgSwitcherRetry),
            ),
          ],
        ),
      ),
    );
  }
}

String _organizationRoleLabel(String role, AppLocalizations l10n) {
  switch (role) {
    case 'owner':
      return l10n.orgSwitcherRoleOwner;
    case 'admin':
      return l10n.orgSwitcherRoleAdmin;
    case 'manager':
      return l10n.orgSwitcherRoleManager;
    case 'editor':
      return l10n.orgSwitcherRoleEditor;
    case 'viewer':
      return l10n.orgSwitcherRoleViewer;
    default:
      return role;
  }
}
