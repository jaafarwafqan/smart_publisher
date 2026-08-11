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
import '../../../../shared/widgets/status_pill.dart';
import '../../../../core/router/guard_state_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../auth/application/auth_session_controller.dart';
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

  // Sprint (2026-08-11): fetched once and reused by the empty-membership
  // welcome header below — same source dashboard_screen.dart's own header
  // already reads (local session state, no extra network round trip).
  late final Future<AuthSession?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = ref.read(authSessionControllerProvider).currentSession();
  }

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

  // Sprint A (role/permission remediation): this screen is now the primary
  // landing state for a freshly registered account with zero memberships —
  // not a rare edge case. A user parked here (no organization yet) must
  // still be able to leave the session, so the app bar needs its own logout
  // action rather than relying on a settings screen this account can't
  // necessarily reach. Same provider-invalidation sequence as
  // PlatformAdminScreens' logout.
  Future<void> _logout() async {
    await ref.read(authSessionControllerProvider).logout();
    await ref.read(activeOrganizationStoreProvider).clear();
    ref.invalidate(authStateProvider);
    ref.invalidate(currentUserRoleProvider);
    ref.invalidate(currentPlatformAdminProvider);
    ref.invalidate(currentOrganizationAccessProvider);
    if (!mounted) {
      return;
    }
    context.go(RouteNames.loginPath);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final access = ref.watch(currentOrganizationAccessProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orgSwitcherAppBarTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.helpIconTooltip,
            onPressed: () => context.push(RouteNames.helpCenterPath),
            icon: const Icon(Icons.help_outline),
          ),
          IconButton(
            tooltip: l10n.logoutTooltip,
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
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
            sessionFuture: _sessionFuture,
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
    required this.sessionFuture,
  });

  final List<OrganizationEntity> organizations;
  final int? activeOrganizationId;
  final int? switchingId;
  final AppLocalizations l10n;
  final ValueChanged<OrganizationEntity> onSwitch;
  final Future<AuthSession?> sessionFuture;

  @override
  Widget build(BuildContext context) {
    if (organizations.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Sprint (2026-08-11): a freshly self-registered account lands
            // here with zero memberships — this used to be a bare "no
            // organization" empty state with nothing recognizing the
            // account that was just created. Guarded with hasData (not
            // `snapshot.data!` eagerly — see AppAsyncSwitcher's docblock for
            // why that pattern crashed platform_admin_screens.dart) so it
            // simply doesn't render until the local session read resolves,
            // which is near-instant since currentSession() reads storage
            // only, no network round trip.
            FutureBuilder<AuthSession?>(
              future: sessionFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: _WelcomeHeader(session: snapshot.data!, l10n: l10n),
                );
              },
            ),
            AppEmptyState(
              title: l10n.orgSwitcherEmptyTitle,
              message: l10n.orgSwitcherEmpty,
              icon: Icons.business_outlined,
              showCard: false,
              // Not an error state — a self-registered account with no
              // organization yet is expected and normal now (see Sprint A).
              // The only account-level screen reachable without an
              // organization is two-factor setup (route_guards.dart grants
              // it to every authenticated user regardless of membership),
              // so it stands in as the "manage my account" affordance here.
              actionLabel: l10n.orgSwitcherEmptyAccountAction,
              onAction: () => context.push(RouteNames.twoFactorSetupPath),
            ),
          ],
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

// Sprint (2026-08-11): mirrors dashboard_screen.dart's own gradient
// _Header + StatusPill combination so a freshly registered account sees
// the same "welcome, this is who you're signed in as" chrome it will see
// again the moment it actually reaches the dashboard, rather than an
// unrelated, less polished look-and-feel here.
class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.session, required this.l10n});

  final AuthSession session;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = session.user.name.trim().isEmpty
        ? l10n.dashboardAuthenticatedUserFallback
        : session.user.name;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[colorScheme.primary, colorScheme.primaryContainer],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.orgSwitcherWelcomeTitle(name),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: colorScheme.onPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.orgSwitcherWelcomeSubtitle(l10n.appName),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: <Widget>[
              StatusPill(
                icon: Icons.person_outline,
                label: name,
                foregroundColor: colorScheme.onPrimary,
                backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.14),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              StatusPill(
                icon: Icons.mail_outline,
                label: session.user.email.trim().isEmpty
                    ? l10n.dashboardNoEmailFallback
                    : session.user.email,
                foregroundColor: colorScheme.onPrimary,
                backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.14),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
            ],
          ),
        ],
      ),
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
