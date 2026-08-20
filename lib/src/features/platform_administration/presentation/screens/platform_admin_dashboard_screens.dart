part of 'platform_admin_screens.dart';

class PlatformAdministrationScreen extends ConsumerWidget {
  const PlatformAdministrationScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authSessionControllerProvider).logout();
    await ref.read(activeOrganizationStoreProvider).clear();
    ref.invalidate(authStateProvider);
    ref.invalidate(currentUserRoleProvider);
    ref.invalidate(currentPlatformAdminProvider);
    ref.invalidate(currentOrganizationAccessProvider);
    // See login_screen.dart: RouteGuardSnapshotCache is not a Riverpod
    // provider and survives the invalidations above — without this, the
    // next account to sign in on this tab can inherit this super_admin
    // session's cached platform-admin decision.
    ref.read(routeGuardSnapshotCacheProvider).invalidate();
    if (!context.mounted) {
      return;
    }
    context.go(RouteNames.loginPath);
  }

  void _showPlatformAdminGuide(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.platformAdminGuideDialogTitle),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _AdminGuidePoint(
                  title: l10n.platformAdminCreateOrgButton,
                  body: l10n.platformAdminGuideCreateOrgBody,
                ),
                _AdminGuidePoint(
                  title: l10n.platformAdminManageUsersButton,
                  body: l10n.platformAdminGuideUsersBody,
                ),
                _AdminGuidePoint(
                  title: l10n.platformAdminOAuthSettingsButton,
                  body: l10n.platformAdminGuideOAuthBody,
                ),
                _AdminGuidePoint(
                  title: l10n.platformAdminAuditLogButton,
                  body: l10n.platformAdminGuideAuditBody,
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => context.push(RouteNames.aboutPath),
            child: Text(l10n.platformAdminAboutSystemButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.platformAdminAppBarTitle),
        actions: <Widget>[
          // A direct one-click shortcut to /platform/users right next to
          // the header title — the existing "إدارة مستخدمي النظام" quick
          // action further down the dashboard body still exists too, but
          // requires scrolling; super_admin sees everything from this
          // workspace, so the most-used management surface belongs in
          // the header itself.
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: () => context.push(RouteNames.platformUsersPath),
            icon: const Icon(Icons.manage_accounts_outlined),
            label: Text(l10n.platformAdminManageUsersShortcut),
          ),
          IconButton(
            tooltip: l10n.platformAdminRefreshTooltip,
            onPressed: () => ref.invalidate(platformDashboardProvider),
            icon: const Icon(Icons.refresh),
          ),
          // Sprint (Help Center, 2026-08-10): a super_admin session never
          // reaches /help (RouteGuards bounces it straight back to
          // /platform — see the isPlatformAdmin branch) — this in-page
          // dialog is the one place a platform administrator gets guide
          // content, per the explicit instruction not to route them into
          // the organization-scoped guide automatically.
          IconButton(
            tooltip: l10n.platformAdminGuideButton,
            onPressed: () => _showPlatformAdminGuide(context),
            icon: const Icon(Icons.help_outline),
          ),
          IconButton(
            tooltip: l10n.logoutTooltip,
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: AdaptiveContentWidth(
        child: FutureBuilder<PlatformDashboardData>(
          future: ref.watch(platformDashboardProvider.future),
          builder: (context, snapshot) {
            final state = snapshot.connectionState != ConnectionState.done
                ? AppAsyncState.loading
                : snapshot.hasError
                ? AppAsyncState.error
                : AppAsyncState.content;
            return AppAsyncSwitcher(
              state: state,
              loading: const Center(child: CircularProgressIndicator()),
              error: _PlatformErrorState(
                error: snapshot.error,
                onRetry: () => ref.invalidate(platformDashboardProvider),
              ),
              empty: const SizedBox.shrink(),
              // Dart evaluates constructor arguments eagerly, regardless
              // of which one AppAsyncSwitcher's internal switch actually
              // picks — content: snapshot.data! used to run on every
              // single build, including the very first one (data is
              // still null while state == loading), throwing before the
              // switch ever got a chance to select `loading` instead.
              content: snapshot.hasData
                  ? _PlatformDashboardContent(data: snapshot.data!)
                  : const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}

class _PlatformDashboardContent extends StatelessWidget {
  const _PlatformDashboardContent({required this.data});

  final PlatformDashboardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: <Widget>[
        Text(
          l10n.platformAdminOverviewTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.platformAdminOverviewSubtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        // Fixed at 3 columns on desktop so the 6 metrics below form two
        // equal rows rather than "4 then 2" wasting half the trailing row
        // (2026-08-12 audit finding) — AdaptiveCardGrid still steps down to
        // 2/1 columns on narrower widths.
        AdaptiveCardGrid(
          breakpoints: const <AdaptiveGridBreakpoint>[
            AdaptiveGridBreakpoint(minWidth: 720, columns: 3),
            AdaptiveGridBreakpoint(minWidth: 480, columns: 2),
            AdaptiveGridBreakpoint(minWidth: 0, columns: 1),
          ],
          items: <Widget>[
            _MetricCard(
              l10n.platformAdminMetricOrgsTotal,
              data.organizationsTotal,
              Icons.domain_outlined,
            ),
            _MetricCard(
              l10n.platformAdminMetricOrgsActive,
              data.organizationsActive,
              Icons.verified_outlined,
            ),
            _MetricCard(
              l10n.platformAdminMetricOrgsInactive,
              data.organizationsInactive,
              Icons.pause_circle_outline,
            ),
            _MetricCard(
              l10n.platformAdminMetricUsersTotal,
              data.usersTotal,
              Icons.people_outline,
            ),
            _MetricCard(
              l10n.platformAdminMetricUsersNew30d,
              data.usersLast30Days,
              Icons.person_add_alt_1_outlined,
            ),
            _MetricCard(
              l10n.platformAdminMetricOrgsWithoutOwner,
              data.organizationsWithoutActiveOwner,
              Icons.warning_amber_outlined,
              danger: data.organizationsWithoutActiveOwner > 0,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: <Widget>[
            FilledButton.icon(
              onPressed: () =>
                  context.push(RouteNames.platformOrganizationsPath),
              icon: const Icon(Icons.domain_add_outlined),
              label: Text(l10n.platformAdminManageOrgsButton),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push(RouteNames.platformUsersPath),
              icon: const Icon(Icons.manage_accounts_outlined),
              label: Text(l10n.platformAdminManageUsersButton),
            ),
            // Sprint D (role/permission remediation): App ID/App Secret for
            // every organization's shared OAuth providers is now
            // super_admin-only on the backend (moved off the legacy Spatie
            // system-settings permission) — this was the one entry point
            // missing from the platform admin workspace to actually reach
            // that screen; previously it had no navigation link anywhere.
            OutlinedButton.icon(
              onPressed: () =>
                  context.push(RouteNames.oauthProviderSettingsPath),
              icon: const Icon(Icons.vpn_key_outlined),
              label: Text(l10n.platformAdminOAuthSettingsButton),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push(RouteNames.platformAuditLogPath),
              icon: const Icon(Icons.fact_check_outlined),
              label: Text(l10n.platformAdminAuditLogButton),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(
          title: l10n.platformAdminLatestOrgsTitle,
          onViewAll: () => context.push(RouteNames.platformOrganizationsPath),
        ),
        if (data.latestOrganizations.isEmpty)
          AppEmptyState(
            compact: true,
            title: l10n.platformAdminNoRecentOrgsTitle,
            message: l10n.platformAdminNoRecentOrgsMessage,
          )
        else
          ...data.latestOrganizations.map(
            (organization) => _OrganizationTile(
              organization: organization,
              onTap: () => context.push(
                RouteNames.platformOrganizationDetailPath.replaceFirst(
                  ':id',
                  organization.id.toString(),
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(
          title: l10n.platformAdminLatestUsersTitle,
          onViewAll: () => context.push(RouteNames.platformUsersPath),
        ),
        if (data.latestUsers.isEmpty)
          AppEmptyState(
            compact: true,
            title: l10n.platformAdminNoRecentUsersTitle,
            message: l10n.platformAdminNoRecentUsersMessage,
          )
        else
          ...data.latestUsers.map((user) => _UserTile(user: user)),
      ],
    );
  }
}
