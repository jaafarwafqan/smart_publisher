import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/base/pagination.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/router/guard_state_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/organizations/application/current_organization_access.dart';
import '../../../../features/organizations/presentation/screens/organization_audit_log_screen.dart';
import '../../../../shared/models/audit_log_entry.dart';
import '../../../../shared/widgets/adaptive_card_grid.dart';
import '../../../../shared/widgets/adaptive_content_width.dart';
import '../../../../shared/widgets/app_async_switcher.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../data/platform_admin_repository.dart';

const _membershipRoles = <String>[
  'owner',
  'admin',
  'manager',
  'editor',
  'viewer',
];

String _roleLabel(String role, AppLocalizations l10n) {
  return switch (role) {
    'owner' => l10n.platformAdminRoleOwner,
    'admin' => l10n.platformAdminRoleAdmin,
    'manager' => l10n.platformAdminRoleManager,
    'editor' => l10n.platformAdminRoleEditor,
    'viewer' => l10n.platformAdminRoleViewer,
    _ => role,
  };
}

String _formatDate(DateTime? date, AppLocalizations l10n) {
  if (date == null) return l10n.platformAdminNotAvailable;
  return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}

class PlatformAdministrationScreen extends ConsumerStatefulWidget {
  const PlatformAdministrationScreen({super.key});

  @override
  ConsumerState<PlatformAdministrationScreen> createState() =>
      _PlatformAdministrationScreenState();
}

class _PlatformAdministrationScreenState
    extends ConsumerState<PlatformAdministrationScreen> {
  late Future<PlatformDashboardData> _dashboard;

  @override
  void initState() {
    super.initState();
    _dashboard = _load();
  }

  Future<PlatformDashboardData> _load() {
    return ref.read(platformAdminRepositoryProvider).getDashboard();
  }

  void _reload() => setState(() => _dashboard = _load());

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
  Widget build(BuildContext context) {
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
              onPressed: _reload,
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
              onPressed: _logout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: AdaptiveContentWidth(
          child: FutureBuilder<PlatformDashboardData>(
            future: _dashboard,
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
                  onRetry: _reload,
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

class PlatformOrganizationsScreen extends ConsumerStatefulWidget {
  const PlatformOrganizationsScreen({super.key});

  @override
  ConsumerState<PlatformOrganizationsScreen> createState() =>
      _PlatformOrganizationsScreenState();
}

class _PlatformOrganizationsScreenState
    extends ConsumerState<PlatformOrganizationsScreen> {
  final _searchController = TextEditingController();
  Future<PlatformPage<PlatformOrganization>>? _organizations;
  String _status = 'all';
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload({int? page}) {
    setState(() {
      _page = page ?? 1;
      _organizations = ref
          .read(platformAdminRepositoryProvider)
          .getOrganizations(
            search: _searchController.text,
            status: _status == 'all' ? null : _status,
            page: _page,
          );
    });
  }

  Future<void> _setStatus(PlatformOrganization organization) async {
    final l10n = AppLocalizations.of(context)!;
    final nextStatus = organization.isActive ? 'inactive' : 'active';
    final confirmed = await _confirm(
      context,
      title: nextStatus == 'inactive'
          ? l10n.platformAdminDisableOrgTitle
          : l10n.platformAdminEnableOrgTitle,
      message: nextStatus == 'inactive'
          ? l10n.platformAdminDisableOrgMessage(organization.name)
          : l10n.platformAdminEnableOrgMessage(organization.name),
      destructive: nextStatus == 'inactive',
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(platformAdminRepositoryProvider)
          .updateOrganizationStatus(organization.id, nextStatus);
      if (mounted) {
        _message(
          nextStatus == 'inactive'
              ? l10n.platformAdminOrgDisabledMessage
              : l10n.platformAdminOrgEnabledMessage,
        );
        _reload(page: _page);
      }
    } on PlatformAdminException catch (error) {
      if (mounted) _message(error.message, danger: true);
    }
  }

  Future<void> _deleteOrganization(PlatformOrganization organization) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirm(
      context,
      title: l10n.platformAdminDeleteOrgTitle,
      message: l10n.platformAdminDeleteOrgMessage(organization.name),
      destructive: true,
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(platformAdminRepositoryProvider)
          .deleteOrganization(organization.id);
      if (mounted) {
        _message(l10n.platformAdminOrgDeletedMessage);
        _reload(page: _page);
      }
    } on PlatformAdminException catch (error) {
      if (mounted) _message(error.message, danger: true);
    }
  }

  Future<void> _fixPrimaryOwner(PlatformOrganization organization) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final fixed = await ref
          .read(platformAdminRepositoryProvider)
          .reconcilePrimaryOwner(organization.id);
      if (!mounted) return;
      _message(
        fixed.primaryOwnerMissing
            ? l10n.platformAdminNoEligibleOwnerMessage
            : l10n.platformAdminPrimaryOwnerAssignedMessage(
                fixed.primaryOwner?.name ?? '',
              ),
        danger: fixed.primaryOwnerMissing,
      );
      _reload(page: _page);
    } on PlatformAdminException catch (error) {
      if (mounted) _message(error.message, danger: true);
    }
  }

  Future<void> _createOrganization() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _CreateOrganizationDialog(),
    );
    if (created == true) _reload();
  }

  Future<void> _editOrganization(PlatformOrganization organization) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _EditOrganizationDialog(organization: organization),
    );
    if (updated == true) {
      _reload(page: _page);
    }
  }

  void _message(String value, {bool danger = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: danger ? AppColors.error : null,
        content: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
        appBar: AppBar(title: Text(l10n.platformAdminOrgsAppBarTitle)),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createOrganization,
          icon: const Icon(Icons.add_business_outlined),
          label: Text(l10n.platformAdminCreateOrgButton),
        ),
        body: AdaptiveContentWidth(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _reload(),
                      decoration: InputDecoration(
                        labelText: l10n.platformAdminSearchByNameOrOwnerHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          tooltip: l10n.platformAdminSearchTooltip,
                          onPressed: _reload,
                          icon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: <ButtonSegment<String>>[
                          ButtonSegment(
                            value: 'all',
                            label: Text(l10n.platformAdminFilterAllChip),
                          ),
                          ButtonSegment(
                            value: 'active',
                            label: Text(l10n.platformAdminOrgActiveStatus),
                          ),
                          ButtonSegment(
                            value: 'inactive',
                            label: Text(l10n.platformAdminOrgInactiveStatus),
                          ),
                        ],
                        selected: <String>{_status},
                        onSelectionChanged: (value) {
                          setState(() => _status = value.first);
                          _reload();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<PlatformPage<PlatformOrganization>>(
                  future: _organizations,
                  builder: (context, snapshot) {
                    final state =
                        snapshot.connectionState != ConnectionState.done
                        ? AppAsyncState.loading
                        : snapshot.hasError
                        ? AppAsyncState.error
                        : snapshot.data!.items.isEmpty
                        ? AppAsyncState.empty
                        : AppAsyncState.content;
                    return AppAsyncSwitcher(
                      state: state,
                      loading: const Center(child: CircularProgressIndicator()),
                      error: _PlatformErrorState(
                        error: snapshot.error,
                        onRetry: _reload,
                      ),
                      empty: AppEmptyState(
                        title: l10n.platformAdminNoMatchingOrgsTitle,
                        message: l10n.platformAdminNoMatchingOrgsMessage,
                        actionLabel: l10n.platformAdminCreateOrgButton,
                        onAction: _createOrganization,
                      ),
                      content: snapshot.hasData
                          ? _OrganizationList(
                              page: snapshot.data!,
                              onStatus: _setStatus,
                              onEdit: _editOrganization,
                              onDelete: _deleteOrganization,
                              onFixPrimaryOwner: _fixPrimaryOwner,
                              onPage: (page) => _reload(page: page),
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class PlatformOrganizationDetailScreen extends ConsumerStatefulWidget {
  const PlatformOrganizationDetailScreen({
    super.key,
    required this.organizationId,
  });

  final int organizationId;

  @override
  ConsumerState<PlatformOrganizationDetailScreen> createState() =>
      _PlatformOrganizationDetailScreenState();
}

class _PlatformOrganizationDetailScreenState
    extends ConsumerState<PlatformOrganizationDetailScreen> {
  late Future<PlatformOrganizationDetails> _details;

  @override
  void initState() {
    super.initState();
    _details = _load();
  }

  Future<PlatformOrganizationDetails> _load() => ref
      .read(platformAdminRepositoryProvider)
      .getOrganization(widget.organizationId);

  void _reload() => setState(() => _details = _load());

  Future<void> _fixPrimaryOwner() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final fixed = await ref
          .read(platformAdminRepositoryProvider)
          .reconcilePrimaryOwner(widget.organizationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: fixed.primaryOwnerMissing ? AppColors.error : null,
          content: Text(
            fixed.primaryOwnerMissing
                ? l10n.platformAdminNoEligibleOwnerMessage
                : l10n.platformAdminPrimaryOwnerAssignedMessage(
                    fixed.primaryOwner?.name ?? '',
                  ),
          ),
        ),
      );
      _reload();
    } on PlatformAdminException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(error.message),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
        appBar: AppBar(title: Text(l10n.platformAdminOrgDetailAppBarTitle)),
        body: AdaptiveContentWidth(
          child: FutureBuilder<PlatformOrganizationDetails>(
            future: _details,
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
                  onRetry: _reload,
                ),
                empty: const SizedBox.shrink(),
                content: snapshot.hasData
                    ? _OrganizationDetailsContent(
                        details: snapshot.data!,
                        onFixPrimaryOwner: _fixPrimaryOwner,
                      )
                    : const SizedBox.shrink(),
              );
            },
          ),
        ),
      );
  }
}

class PlatformUsersScreen extends ConsumerStatefulWidget {
  const PlatformUsersScreen({super.key});

  @override
  ConsumerState<PlatformUsersScreen> createState() =>
      _PlatformUsersScreenState();
}

class _PlatformUsersScreenState extends ConsumerState<PlatformUsersScreen> {
  final _searchController = TextEditingController();
  Future<PlatformPage<PlatformUser>>? _users;
  bool? _isActive;
  bool? _isSuperAdmin;
  int _organizationFilter = -1;
  String _membershipRoleFilter = 'all';
  int _page = 1;
  late final Future<PlatformPage<PlatformOrganization>> _filterOrganizations;

  @override
  void initState() {
    super.initState();
    _filterOrganizations = ref
        .read(platformAdminRepositoryProvider)
        .getOrganizations(perPage: 100);
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload({int? page}) {
    setState(() {
      _page = page ?? 1;
      _users = ref
          .read(platformAdminRepositoryProvider)
          .getUsers(
            search: _searchController.text,
            isActive: _isActive,
            isSuperAdmin: _isSuperAdmin,
            organizationId: _organizationFilter == -1
                ? null
                : _organizationFilter,
            membershipRole: _membershipRoleFilter == 'all'
                ? null
                : _membershipRoleFilter,
            page: _page,
          );
    });
  }

  Future<void> _createUser() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _CreateUserDialog(),
    );
    if (created == true) _reload();
  }

  Future<void> _changeStatus(PlatformUser user) async {
    final l10n = AppLocalizations.of(context)!;
    final next = !user.isActive;
    final confirmed = await _confirm(
      context,
      title: next
          ? l10n.platformAdminActivateAccountTitle
          : l10n.platformAdminDeactivateAccountTitle,
      message: next
          ? l10n.platformAdminActivateAccountMessage(user.email)
          : l10n.platformAdminDeactivateAccountMessage(user.email),
      destructive: !next,
    );
    if (confirmed != true) return;
    await _runUserAction(
      () => ref
          .read(platformAdminRepositoryProvider)
          .updateUserStatus(user.id, next),
      next
          ? l10n.platformAdminAccountActivatedMessage
          : l10n.platformAdminAccountDeactivatedMessage,
    );
  }

  Future<void> _deleteUser(PlatformUser user) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirm(
      context,
      title: l10n.platformAdminDeleteUserTitle,
      message: l10n.platformAdminDeleteUserMessage(user.email),
      destructive: true,
    );
    if (confirmed != true) return;
    await _runUserAction(
      () => ref.read(platformAdminRepositoryProvider).deleteUser(user.id),
      l10n.platformAdminUserDeletedMessage,
    );
  }

  Future<void> _changePlatformRole(PlatformUser user) async {
    final l10n = AppLocalizations.of(context)!;
    final next = !user.isSuperAdmin;
    final confirmed = await _confirm(
      context,
      title: next
          ? l10n.platformAdminGrantSuperAdminTitle
          : l10n.platformAdminRevokeSuperAdminTitle,
      message: next
          ? l10n.platformAdminGrantSuperAdminMessage(user.email)
          : l10n.platformAdminRevokeSuperAdminMessage(user.email),
      destructive: !next,
    );
    if (confirmed != true) return;
    await _runUserAction(
      () => ref
          .read(platformAdminRepositoryProvider)
          .updatePlatformRole(user.id, next),
      next
          ? l10n.platformAdminSuperAdminGrantedMessage
          : l10n.platformAdminSuperAdminRevokedMessage,
    );
  }

  Future<void> _editUser(PlatformUser user) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _EditUserDialog(user: user),
    );
    if (updated == true) _reload(page: _page);
  }

  Future<void> _editMemberships(PlatformUser user) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _MembershipEditorDialog(user: user),
    );
    if (updated == true) _reload(page: _page);
  }

  Future<void> _runUserAction(
    Future<void> Function() action,
    String success,
  ) async {
    try {
      await action();
      if (!mounted) return;
      _message(success);
      _reload(page: _page);
    } on PlatformAdminException catch (error) {
      if (mounted) _message(error.message, danger: true);
    }
  }

  void _message(String value, {bool danger = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: danger ? AppColors.error : null,
        content: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
        appBar: AppBar(title: Text(l10n.platformAdminUsersAppBarTitle)),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createUser,
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: Text(l10n.platformAdminAddUserButton),
        ),
        body: AdaptiveContentWidth(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _reload(),
                      decoration: InputDecoration(
                        labelText: l10n.platformAdminSearchByNameOrEmailHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          tooltip: l10n.platformAdminSearchTooltip,
                          onPressed: _reload,
                          icon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: <Widget>[
                        FilterChip(
                          label: Text(l10n.platformAdminActiveOnlyChip),
                          selected: _isActive == true,
                          onSelected: (selected) {
                            setState(() => _isActive = selected ? true : null);
                            _reload();
                          },
                        ),
                        FilterChip(
                          label: Text(l10n.platformAdminInactiveOnlyChip),
                          selected: _isActive == false,
                          onSelected: (selected) {
                            setState(() => _isActive = selected ? false : null);
                            _reload();
                          },
                        ),
                        FilterChip(
                          label: Text(l10n.platformAdminSuperAdminsChip),
                          selected: _isSuperAdmin == true,
                          onSelected: (selected) {
                            setState(
                              () => _isSuperAdmin = selected ? true : null,
                            );
                            _reload();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FutureBuilder<PlatformPage<PlatformOrganization>>(
                      future: _filterOrganizations,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        return Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            DropdownButton<int>(
                              value: _organizationFilter,
                              items: <DropdownMenuItem<int>>[
                                DropdownMenuItem(
                                  value: -1,
                                  child: Text(l10n.platformAdminAllOrgsOption),
                                ),
                                ...snapshot.data!.items.map(
                                  (organization) => DropdownMenuItem(
                                    value: organization.id,
                                    child: Text(organization.name),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _organizationFilter = value);
                                _reload();
                              },
                            ),
                            DropdownButton<String>(
                              value: _membershipRoleFilter,
                              items: <DropdownMenuItem<String>>[
                                DropdownMenuItem(
                                  value: 'all',
                                  child: Text(l10n.platformAdminAllRolesOption),
                                ),
                                ..._membershipRoles.map(
                                  (role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(_roleLabel(role, l10n)),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _membershipRoleFilter = value);
                                _reload();
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<PlatformPage<PlatformUser>>(
                  future: _users,
                  builder: (context, snapshot) {
                    final state =
                        snapshot.connectionState != ConnectionState.done
                        ? AppAsyncState.loading
                        : snapshot.hasError
                        ? AppAsyncState.error
                        : snapshot.data!.items.isEmpty
                        ? AppAsyncState.empty
                        : AppAsyncState.content;
                    return AppAsyncSwitcher(
                      state: state,
                      loading: const Center(child: CircularProgressIndicator()),
                      error: _PlatformErrorState(
                        error: snapshot.error,
                        onRetry: _reload,
                      ),
                      empty: AppEmptyState(
                        title: l10n.platformAdminNoMatchingUsersTitle,
                        message: l10n.platformAdminNoMatchingUsersMessage,
                        actionLabel: l10n.platformAdminAddUserButton,
                        onAction: _createUser,
                      ),
                      content: snapshot.hasData
                          ? _UserList(
                              page: snapshot.data!,
                              onStatus: _changeStatus,
                              onPlatformRole: _changePlatformRole,
                              onEdit: _editUser,
                              onMemberships: _editMemberships,
                              onDelete: _deleteUser,
                              onPage: (page) => _reload(page: page),
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
  }
}

/// Sprint G (role/permission remediation, 2026-08-09): the platform-wide
/// counterpart to `OrganizationAuditLogScreen` — super_admin only,
/// unrestricted by organization (`GET /admin/audit-logs`). Reuses
/// `AuditLogTile`/`AuditLogPagination` from the organization-scoped screen
/// rather than duplicating row rendering.
class PlatformAuditLogScreen extends ConsumerStatefulWidget {
  const PlatformAuditLogScreen({super.key});

  @override
  ConsumerState<PlatformAuditLogScreen> createState() =>
      _PlatformAuditLogScreenState();
}

class _PlatformAuditLogScreenState
    extends ConsumerState<PlatformAuditLogScreen> {
  final _actionController = TextEditingController();
  Future<PaginatedResult<AuditLogEntry>>? _entries;
  int _page = 1;
  int _organizationFilter = -1;
  late final Future<PlatformPage<PlatformOrganization>> _filterOrganizations;

  @override
  void initState() {
    super.initState();
    _filterOrganizations = ref
        .read(platformAdminRepositoryProvider)
        .getOrganizations(perPage: 100);
    _reload();
  }

  @override
  void dispose() {
    _actionController.dispose();
    super.dispose();
  }

  void _reload({int? page}) {
    setState(() {
      _page = page ?? 1;
      _entries = ref
          .read(platformAdminRepositoryProvider)
          .getAuditLogs(
            page: _page,
            action: _actionController.text,
            organizationId: _organizationFilter == -1
                ? null
                : _organizationFilter,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
        appBar: AppBar(title: Text(l10n.platformAdminAuditLogButton)),
        body: AdaptiveContentWidth(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _actionController,
                      onSubmitted: (_) => _reload(),
                      decoration: InputDecoration(
                        labelText: l10n.platformAdminFilterByActionHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          tooltip: l10n.platformAdminSearchTooltip,
                          onPressed: _reload,
                          icon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FutureBuilder<PlatformPage<PlatformOrganization>>(
                      future: _filterOrganizations,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        return Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: DropdownButton<int>(
                            value: _organizationFilter,
                            items: <DropdownMenuItem<int>>[
                              DropdownMenuItem(
                                value: -1,
                                child: Text(l10n.platformAdminAllOrgsOption),
                              ),
                              ...snapshot.data!.items.map(
                                (organization) => DropdownMenuItem(
                                  value: organization.id,
                                  child: Text(organization.name),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _organizationFilter = value);
                              _reload();
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<PaginatedResult<AuditLogEntry>>(
                  future: _entries,
                  builder: (context, snapshot) {
                    final state =
                        snapshot.connectionState != ConnectionState.done
                        ? AppAsyncState.loading
                        : snapshot.hasError
                        ? AppAsyncState.error
                        : snapshot.data!.items.isEmpty
                        ? AppAsyncState.empty
                        : AppAsyncState.content;
                    return AppAsyncSwitcher(
                      state: state,
                      loading: const Center(child: CircularProgressIndicator()),
                      error: _PlatformErrorState(
                        error: snapshot.error,
                        onRetry: _reload,
                      ),
                      empty: AppEmptyState(
                        icon: Icons.fact_check_outlined,
                        title: l10n.platformAdminNoMatchingEventsTitle,
                        message: l10n.platformAdminNoMatchingEventsMessage,
                      ),
                      content: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xxl,
                        ),
                        children: <Widget>[
                          ...(snapshot.data?.items ?? const <AuditLogEntry>[])
                              .map(
                                (entry) => AuditLogTile(
                                  entry: entry,
                                  showOrganization: true,
                                ),
                              ),
                          AuditLogPagination(
                            page: snapshot.data,
                            onPage: (page) => _reload(page: page),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class _AdminGuidePoint extends StatelessWidget {
  const _AdminGuidePoint({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value, this.icon, {this.danger = false});

  final String label;
  final int value;
  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    // Width now comes from the enclosing AdaptiveCardGrid, which sizes
    // every card in a row equally rather than this card carrying its own
    // fixed width (that fixed width was what produced "4 then 2" rows
    // with wasted trailing space — see the call site).
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: <Widget>[
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    value.toString(),
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: color),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.onViewAll});
  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      TextButton(
        onPressed: onViewAll,
        child: Text(AppLocalizations.of(context)!.platformAdminViewAllButton),
      ),
    ],
  );
}

class _OrganizationList extends StatelessWidget {
  const _OrganizationList({
    required this.page,
    required this.onStatus,
    required this.onEdit,
    required this.onDelete,
    required this.onFixPrimaryOwner,
    required this.onPage,
  });
  final PlatformPage<PlatformOrganization> page;
  final ValueChanged<PlatformOrganization> onStatus;
  final ValueChanged<PlatformOrganization> onEdit;
  final ValueChanged<PlatformOrganization> onDelete;
  final ValueChanged<PlatformOrganization> onFixPrimaryOwner;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: <Widget>[
        Text(
          l10n.platformAdminOrgCountLabel(page.total),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...page.items.map(
          (organization) => _OrganizationTile(
            organization: organization,
            onTap: () => context.push(
              RouteNames.platformOrganizationDetailPath.replaceFirst(
                ':id',
                organization.id.toString(),
              ),
            ),
            onFixPrimaryOwner: () => onFixPrimaryOwner(organization),
            actions: PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'edit':
                    onEdit(organization);
                    break;
                  case 'delete':
                    onDelete(organization);
                    break;
                  default:
                    onStatus(organization);
                }
              },
              itemBuilder: (_) => <PopupMenuEntry<String>>[
                PopupMenuItem(
                  value: 'edit',
                  child: Text(l10n.platformAdminEditOrgNameMenuItem),
                ),
                PopupMenuItem(
                  value: 'status',
                  child: Text(
                    organization.isActive
                        ? l10n.platformAdminDisableOrgTitle
                        : l10n.platformAdminReactivateMenuItem,
                  ),
                ),
                // Deletion is only offered once the organization is already
                // deactivated — mirrors the backend's own real precondition
                // (AdminOrganizationController::destroy()) instead of
                // showing an action that would just 422.
                if (!organization.isActive)
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(l10n.platformAdminDeleteOrgMenuItem),
                  ),
              ],
            ),
          ),
        ),
        _Pagination(page: page, onPage: onPage),
      ],
    );
  }
}

class _OrganizationTile extends StatelessWidget {
  const _OrganizationTile({
    required this.organization,
    required this.onTap,
    this.actions,
    this.onFixPrimaryOwner,
  });
  final PlatformOrganization organization;
  final VoidCallback onTap;
  final Widget? actions;
  // Null on the read-only dashboard summary tile — the warning still shows
  // there, just without an action button.
  final VoidCallback? onFixPrimaryOwner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusLabel = organization.isActive
        ? l10n.platformAdminOrgActiveStatus
        : l10n.platformAdminOrgInactiveStatus;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Icon(
            organization.isActive
                ? Icons.domain_outlined
                : Icons.domain_disabled_outlined,
          ),
        ),
        title: Text(organization.name),
        subtitle: organization.primaryOwnerMissing
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      '${l10n.platformAdminPrimaryOwnerMissingLabel} · '
                      '${l10n.platformAdminMembersCountLabel(organization.membersCount)}',
                      style: TextStyle(color: AppColors.warning),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onFixPrimaryOwner != null)
                    TextButton(
                      onPressed: onFixPrimaryOwner,
                      child: Text(l10n.platformAdminFixButton),
                    ),
                ],
              )
            : Text(
                l10n.platformAdminOrgSummaryLine(
                  organization.primaryOwner?.name ?? '—',
                  organization.membersCount,
                  _formatDate(organization.createdAt, l10n),
                ),
              ),
        trailing: actions == null
            ? StatusPill(
                label: statusLabel,
                tone: organization.isActive
                    ? PillTone.success
                    : PillTone.danger,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  StatusPill(
                    label: statusLabel,
                    tone: organization.isActive
                        ? PillTone.success
                        : PillTone.danger,
                  ),
                  actions!,
                ],
              ),
      ),
    );
  }
}

/// Replaces the vague "لا يوجد مالك فعّال" fallback text the 2026-08-12
/// audit flagged with an explicit, actionable alert: what's wrong, and a
/// button that calls the reconcile-primary-owner endpoint right from here.
class _PrimaryOwnerMissingBanner extends StatelessWidget {
  const _PrimaryOwnerMissingBanner({required this.onFix});
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.platformAdminPrimaryOwnerMissingLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.platformAdminPrimaryOwnerMissingBannerBody),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: onFix,
            child: Text(l10n.platformAdminFixButton),
          ),
        ],
      ),
    );
  }
}

class _OrganizationDetailsContent extends StatelessWidget {
  const _OrganizationDetailsContent({
    required this.details,
    required this.onFixPrimaryOwner,
  });
  final PlatformOrganizationDetails details;
  final VoidCallback onFixPrimaryOwner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final organization = details.organization;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        Text(
          organization.name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (organization.primaryOwnerMissing) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _PrimaryOwnerMissingBanner(onFix: onFixPrimaryOwner),
        ],
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            StatusPill(
              label: organization.isActive
                  ? l10n.platformAdminOrgActiveStatus
                  : l10n.platformAdminOrgInactiveStatus,
              tone: organization.isActive ? PillTone.success : PillTone.danger,
            ),
            StatusPill(
              label: l10n.platformAdminMembersCountLabel(
                organization.membersCount,
              ),
            ),
            StatusPill(
              label: l10n.platformAdminLastActivityLabel(
                _formatDate(organization.lastActivityAt, l10n),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _DetailSection(
          title: l10n.platformAdminMembersSectionTitle,
          child: details.members.isEmpty
              ? AppEmptyState(
                  compact: true,
                  title: l10n.platformAdminNoMembersTitle,
                  message: l10n.platformAdminNoMembersMessage,
                )
              : Column(
                  children: details.members
                      .map(
                        (member) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Text(
                              member.user.name.isEmpty
                                  ? '?'
                                  : member.user.name.substring(0, 1),
                            ),
                          ),
                          title: Text(member.user.name),
                          subtitle: Text(member.user.email),
                          trailing: StatusPill(
                            label: _roleLabel(member.role, l10n),
                            tone: member.status == 'active'
                                ? PillTone.neutral
                                : PillTone.warning,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _DetailSection(
          title: l10n.platformAdminSocialAccountsSectionTitle,
          child: details.socialAccounts.isEmpty
              ? AppEmptyState(
                  compact: true,
                  title: l10n.platformAdminNoSocialAccountsTitle,
                  message: l10n.platformAdminNoSocialAccountsMessage,
                )
              : Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: details.socialAccounts
                      .map(
                        (account) => StatusPill(
                          label:
                              '${account['provider'] ?? l10n.platformAdminUnnamedAccountFallback} · '
                              '${account['account_name'] ?? account['account_username'] ?? l10n.platformAdminUnnamedFallback}',
                          tone: account['is_active'] == true
                              ? PillTone.success
                              : PillTone.warning,
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _DetailSection(
          title: l10n.platformAdminPostsSummarySectionTitle,
          child: details.postsSummary.isEmpty
              ? AppEmptyState(
                  compact: true,
                  title: l10n.platformAdminNoPostsTitle,
                  message: l10n.platformAdminNoPostsMessage,
                )
              : Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: details.postsSummary.entries
                      .map(
                        (entry) =>
                            StatusPill(label: '${entry.key}: ${entry.value}'),
                      )
                      .toList(growable: false),
                ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    ),
  );
}

class _UserList extends StatelessWidget {
  const _UserList({
    required this.page,
    required this.onStatus,
    required this.onPlatformRole,
    required this.onEdit,
    required this.onMemberships,
    required this.onDelete,
    required this.onPage,
  });
  final PlatformPage<PlatformUser> page;
  final ValueChanged<PlatformUser> onStatus;
  final ValueChanged<PlatformUser> onPlatformRole;
  final ValueChanged<PlatformUser> onEdit;
  final ValueChanged<PlatformUser> onMemberships;
  final ValueChanged<PlatformUser> onDelete;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: <Widget>[
        Text(
          l10n.platformAdminUserCountLabel(page.total),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...page.items.map(
          (user) => _UserTile(
            user: user,
            actions: PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'edit':
                    onEdit(user);
                    break;
                  case 'memberships':
                    onMemberships(user);
                    break;
                  case 'status':
                    onStatus(user);
                    break;
                  case 'role':
                    onPlatformRole(user);
                    break;
                  case 'delete':
                    onDelete(user);
                    break;
                }
              },
              itemBuilder: (_) => <PopupMenuEntry<String>>[
                PopupMenuItem(
                  value: 'edit',
                  child: Text(l10n.platformAdminEditUserDataMenuItem),
                ),
                PopupMenuItem(
                  value: 'memberships',
                  child: Text(l10n.platformAdminManageMembershipsMenuItem),
                ),
                PopupMenuItem(
                  value: 'role',
                  child: Text(
                    user.isSuperAdmin
                        ? l10n.platformAdminRevokeSuperAdminTitle
                        : l10n.platformAdminGrantSuperAdminTitle,
                  ),
                ),
                PopupMenuItem(
                  value: 'status',
                  child: Text(
                    user.isActive
                        ? l10n.platformAdminDeactivateAccountTitle
                        : l10n.platformAdminActivateAccountTitle,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(l10n.platformAdminDeleteUserMenuItem),
                ),
              ],
            ),
          ),
        ),
        _Pagination(page: page, onPage: onPage),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, this.actions});
  final PlatformUser user;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(user.name.isEmpty ? '?' : user.name.substring(0, 1)),
        ),
        title: Text(user.name),
        subtitle: Text(
          '${user.email}\n${user.memberships.isEmpty ? l10n.platformAdminNoOrgLabel : user.memberships.map((membership) => '${membership.organizationName} (${_roleLabel(membership.role, l10n)})').join(' · ')}',
        ),
        isThreeLine: user.memberships.isNotEmpty,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (user.isSuperAdmin)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                child: StatusPill(
                  label: l10n.platformAdminSuperAdminBadge,
                  tone: PillTone.warning,
                ),
              ),
            StatusPill(
              label: user.isActive
                  ? l10n.platformAdminActiveLabel
                  : l10n.platformAdminInactiveLabel,
              tone: user.isActive ? PillTone.success : PillTone.danger,
            ),
            if (actions case final Widget actions) actions,
          ],
        ),
      ),
    );
  }
}

class _Pagination<T> extends StatelessWidget {
  const _Pagination({required this.page, required this.onPage});
  final PlatformPage<T> page;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    if (page.lastPage <= 1) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    // Code-quality review (2026-08-17), item B4/3.2: same fix as
    // AuditLogPagination in organization_audit_log_screen.dart — was
    // hardcoded regardless of locale (correct for RTL, backward in LTR).
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final previousIcon = isRtl ? Icons.chevron_right : Icons.chevron_left;
    final nextIcon = isRtl ? Icons.chevron_left : Icons.chevron_right;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          OutlinedButton.icon(
            onPressed: page.currentPage > 1
                ? () => onPage(page.currentPage - 1)
                : null,
            icon: Icon(previousIcon),
            label: Text(l10n.platformAdminPreviousPageButton),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              l10n.platformAdminPageIndicator(page.currentPage, page.lastPage),
            ),
          ),
          OutlinedButton.icon(
            onPressed: page.currentPage < page.lastPage
                ? () => onPage(page.currentPage + 1)
                : null,
            icon: Icon(nextIcon),
            label: Text(l10n.commonNext),
          ),
        ],
      ),
    );
  }
}

class _PlatformErrorState extends StatelessWidget {
  const _PlatformErrorState({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isForbidden =
        error is PlatformAdminException &&
        (error as PlatformAdminException).isForbidden;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AppEmptyState(
          icon: isForbidden ? Icons.lock_outline : Icons.cloud_off_outlined,
          title: isForbidden
              ? l10n.platformAdminUnauthorizedTitle
              : l10n.platformAdminLoadErrorTitle,
          message: isForbidden
              ? l10n.platformAdminForbiddenMessage
              : l10n.platformAdminGenericLoadErrorMessage,
          actionLabel: isForbidden ? null : l10n.commonRetry,
          onAction: isForbidden ? null : onRetry,
        ),
      ),
    );
  }
}

class _CreateOrganizationDialog extends ConsumerStatefulWidget {
  const _CreateOrganizationDialog();

  @override
  ConsumerState<_CreateOrganizationDialog> createState() =>
      _CreateOrganizationDialogState();
}

class _CreateOrganizationDialogState
    extends ConsumerState<_CreateOrganizationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _ownerName = TextEditingController();
  final _ownerEmail = TextEditingController();
  final _ownerPassword = TextEditingController();
  bool _useExistingOwner = false;
  bool _submitting = false;
  String? _error;
  PlatformUser? _selectedOwner;
  late Future<PlatformPage<PlatformUser>> _availableUsers;

  @override
  void initState() {
    super.initState();
    // Fetched eagerly regardless of _useExistingOwner (so switching to
    // "existing owner" later doesn't need to wait), but the FutureBuilder
    // that actually consumes this only builds once that toggle is flipped
    // — so a rejection before then would otherwise have zero listeners
    // attached at the moment it rejects, which Dart reports as an
    // "unhandled" async error even though it's genuinely handled once the
    // FutureBuilder builds. ignore() marks it handled for that reporting
    // purpose only — it does not consume or transform the result, so the
    // FutureBuilder still receives the real value/error normally.
    _availableUsers = ref.read(platformAdminRepositoryProvider).getUsers();
    _availableUsers.ignore();
  }

  @override
  void dispose() {
    _name.dispose();
    _ownerName.dispose();
    _ownerEmail.dispose();
    _ownerPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(platformAdminRepositoryProvider)
          .createOrganization(
            name: _name.text.trim(),
            ownerUserId: _useExistingOwner ? _selectedOwner?.id : null,
            newOwnerName: _useExistingOwner ? null : _ownerName.text.trim(),
            newOwnerEmail: _useExistingOwner ? null : _ownerEmail.text.trim(),
            newOwnerPassword: _useExistingOwner ? null : _ownerPassword.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on PlatformAdminException catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.message;
        });
      }
    } catch (error, stackTrace) {
      // A live E2E test found this dialog getting permanently stuck showing
      // its loading spinner after the organization was genuinely created
      // server-side — root cause: this catch only handled
      // PlatformAdminException, so any other exception (a response-parsing
      // edge case, a client-side error unrelated to the HTTP call itself)
      // propagated uncaught, and _submitting never reset. Any exception
      // now surfaces as a real error and re-enables the form instead of
      // leaving it stuck forever. The raw error is logged for
      // diagnosis (the exact wiring point a real Sentry/Crashlytics
      // integration would hook into) but never shown to the user — an
      // unclassified exception's message could contain implementation
      // detail that isn't meant to be user-facing.
      AppLogger.e('Unexpected error creating organization', error, stackTrace);
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = AppLocalizations.of(context)!.platformAdminUnexpectedError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.platformAdminCreateOrgButton),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: l10n.platformAdminOrgNameLabel,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.platformAdminOrgNameRequiredError
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<bool>(
                  segments: <ButtonSegment<bool>>[
                    ButtonSegment(
                      value: false,
                      label: Text(l10n.platformAdminNewOwnerSegment),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text(l10n.platformAdminExistingOwnerSegment),
                    ),
                  ],
                  selected: <bool>{_useExistingOwner},
                  onSelectionChanged: (value) =>
                      setState(() => _useExistingOwner = value.first),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_useExistingOwner)
                  FutureBuilder<PlatformPage<PlatformUser>>(
                    future: _availableUsers,
                    builder: (context, snapshot) {
                      // A failed fetch (network error, backend error) must not
                      // spin forever — only snapshot.hasData was checked
                      // before, so an error here left this picker showing an
                      // infinite loading spinner with no way to notice
                      // anything had actually gone wrong or retry. The raw
                      // error is logged (never shown raw to the user — same
                      // reasoning as the _submit() catch-alls above) and the
                      // message/button are localized rather than hardcoded
                      // Arabic, which would render even under an English
                      // locale.
                      if (snapshot.hasError) {
                        AppLogger.e(
                          'Failed to load platform admin owner picker users',
                          snapshot.error,
                          snapshot.stackTrace,
                        );
                        return Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                l10n.platformAdminOwnerListLoadError,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              OutlinedButton(
                                onPressed: () => setState(() {
                                  _availableUsers = ref
                                      .read(platformAdminRepositoryProvider)
                                      .getUsers();
                                }),
                                child: Text(l10n.commonRetry),
                              ),
                            ],
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: CircularProgressIndicator(),
                        );
                      }
                      final users = snapshot.data!.items
                          .where((user) => user.isActive)
                          .toList(growable: false);
                      return DropdownButtonFormField<PlatformUser>(
                        initialValue: _selectedOwner,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.platformAdminOwnerFieldLabel,
                        ),
                        items: users
                            .map(
                              (user) => DropdownMenuItem(
                                value: user,
                                child: Text(
                                  '${user.name} — ${user.email}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) =>
                            setState(() => _selectedOwner = value),
                        validator: (value) => value == null
                            ? l10n.platformAdminSelectActiveOwnerError
                            : null,
                      );
                    },
                  )
                else ...<Widget>[
                  TextFormField(
                    controller: _ownerName,
                    decoration: InputDecoration(
                      labelText: l10n.platformAdminNewOwnerNameLabel,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.platformAdminNewOwnerNameRequiredError
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _ownerEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.platformAdminNewOwnerEmailLabel,
                    ),
                    validator: (value) => value == null || !value.contains('@')
                        ? l10n.platformAdminValidEmailRequiredError
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _ownerPassword,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.platformAdminNewOwnerPasswordLabel,
                    ),
                    validator: (value) => value == null || value.length < 12
                        ? l10n.platformAdminPasswordMinLengthError
                        : null,
                  ),
                ],
                if (_error != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.platformAdminCreateOrgSubmitButton),
        ),
      ],
    );
  }
}

class _EditOrganizationDialog extends ConsumerStatefulWidget {
  const _EditOrganizationDialog({required this.organization});

  final PlatformOrganization organization;

  @override
  ConsumerState<_EditOrganizationDialog> createState() =>
      _EditOrganizationDialogState();
}

class _EditOrganizationDialogState
    extends ConsumerState<_EditOrganizationDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.organization.name,
  );
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      setState(
        () => _error = AppLocalizations.of(
          context,
        )!.platformAdminOrgNameRequiredError,
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(platformAdminRepositoryProvider)
          .updateOrganization(
            id: widget.organization.id,
            name: _name.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on PlatformAdminException catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.message;
        });
      }
    } catch (error, stackTrace) {
      // Same hardening as _CreateOrganizationDialog._submit() — see its
      // comment. Any exception must reset _submitting, not just the
      // specific HTTP-layer one, and the raw error is logged rather than
      // shown to the user.
      AppLogger.e('Unexpected error updating organization', error, stackTrace);
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = AppLocalizations.of(context)!.platformAdminUnexpectedError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.platformAdminEditOrgNameMenuItem),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.platformAdminOrgNameLabel,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

class _CreateUserDialog extends ConsumerStatefulWidget {
  const _CreateUserDialog();
  @override
  ConsumerState<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  String? _error;
  int _organizationId = -1;
  String _membershipRole = 'viewer';
  late final Future<PlatformPage<PlatformOrganization>> _organizations;

  @override
  void initState() {
    super.initState();
    _organizations = ref
        .read(platformAdminRepositoryProvider)
        .getOrganizations(perPage: 100);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(platformAdminRepositoryProvider)
          .createUser(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            organizationId: _organizationId == -1 ? null : _organizationId,
            membershipRole: _organizationId == -1 ? null : _membershipRole,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on PlatformAdminException catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.platformAdminAddUserButton),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: l10n.platformAdminNameLabel,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.platformAdminNameRequiredError
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.platformAdminEmailLabel,
                ),
                validator: (value) => value == null || !value.contains('@')
                    ? l10n.platformAdminValidEmailShortError
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.platformAdminPasswordLabel,
                ),
                validator: (value) => value == null || value.length < 12
                    ? l10n.platformAdminPasswordMinLengthError
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              FutureBuilder<PlatformPage<PlatformOrganization>>(
                future: _organizations,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      DropdownButton<int>(
                        value: _organizationId,
                        items: <DropdownMenuItem<int>>[
                          DropdownMenuItem(
                            value: -1,
                            child: Text(l10n.platformAdminNoOrgOption),
                          ),
                          ...snapshot.data!.items.map(
                            (organization) => DropdownMenuItem(
                              value: organization.id,
                              child: Text(organization.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => _organizationId = value);
                        },
                      ),
                      if (_organizationId != -1)
                        DropdownButton<String>(
                          value: _membershipRole,
                          items: _membershipRoles
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(_roleLabel(role, l10n)),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() => _membershipRole = value);
                          },
                        ),
                    ],
                  );
                },
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.platformAdminAddButtonShort),
        ),
      ],
    );
  }
}

class _EditUserDialog extends ConsumerStatefulWidget {
  const _EditUserDialog({required this.user});
  final PlatformUser user;
  @override
  ConsumerState<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<_EditUserDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.user.name,
  );
  late final TextEditingController _email = TextEditingController(
    text: widget.user.email,
  );
  bool _submitting = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(platformAdminRepositoryProvider)
          .updateUser(
            id: widget.user.id,
            name: _name.text.trim(),
            email: _email.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on PlatformAdminException catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.platformAdminEditUserDialogTitle),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: l10n.platformAdminNameLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.platformAdminEmailLabel,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

class _MembershipEditorDialog extends ConsumerStatefulWidget {
  const _MembershipEditorDialog({required this.user});
  final PlatformUser user;
  @override
  ConsumerState<_MembershipEditorDialog> createState() =>
      _MembershipEditorDialogState();
}

class _MembershipEditorDialogState
    extends ConsumerState<_MembershipEditorDialog> {
  late final List<PlatformMembership> _memberships;
  late Future<PlatformPage<PlatformOrganization>> _organizations;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _memberships = List<PlatformMembership>.from(widget.user.memberships);
    _organizations = ref
        .read(platformAdminRepositoryProvider)
        .getOrganizations();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(platformAdminRepositoryProvider)
          .syncMemberships(widget.user.id, _memberships);
      if (mounted) Navigator.of(context).pop(true);
    } on PlatformAdminException catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.platformAdminMembershipsDialogTitle(widget.user.name)),
      content: SizedBox(
        width: 600,
        child: FutureBuilder<PlatformPage<PlatformOrganization>>(
          future: _organizations,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final organizations = snapshot.data!.items;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(l10n.platformAdminMembershipsHint),
                  const SizedBox(height: AppSpacing.md),
                  ..._memberships.asMap().entries.map((entry) {
                    final index = entry.key;
                    final membership = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Row(
                          children: <Widget>[
                            Expanded(child: Text(membership.organizationName)),
                            DropdownButton<String>(
                              value: membership.role,
                              items: _membershipRoles
                                  .map(
                                    (role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(_roleLabel(role, l10n)),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (role) => role == null
                                  ? null
                                  : setState(
                                      () => _memberships[index] =
                                          PlatformMembership(
                                            organizationId:
                                                membership.organizationId,
                                            organizationName:
                                                membership.organizationName,
                                            organizationStatus:
                                                membership.organizationStatus,
                                            role: role,
                                            status: membership.status,
                                          ),
                                    ),
                            ),
                            IconButton(
                              tooltip:
                                  l10n.platformAdminRemoveMembershipTooltip,
                              onPressed: () =>
                                  setState(() => _memberships.removeAt(index)),
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  DropdownButtonFormField<PlatformOrganization>(
                    // Bug reported 2026-08-11: DropdownButtonFormField keeps
                    // its selected value in its own internal FormFieldState,
                    // separate from this widget's `items:` list. Picking an
                    // organization here calls setState() to add it to
                    // _memberships, which immediately filters that same
                    // organization OUT of `items` below (already-added
                    // orgs are excluded) — but without a key forcing a fresh
                    // State, the field's retained value is now an object
                    // matching zero entries in the rebuilt items list,
                    // tripping Flutter's "exactly one item must match value"
                    // assertion on every subsequent add/remove. Keying on the
                    // current membership set forces Flutter to discard the
                    // old State (and its stale value) and mount a fresh one
                    // that starts unselected — which is also the correct UX,
                    // since the just-added organization can no longer be
                    // picked again anyway.
                    key: ValueKey<String>(
                      _memberships.map((m) => m.organizationId).join(','),
                    ),
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.platformAdminAddToOrgLabel,
                    ),
                    items: organizations
                        .where(
                          (organization) => !_memberships.any(
                            (membership) =>
                                membership.organizationId == organization.id,
                          ),
                        )
                        .map(
                          (organization) => DropdownMenuItem(
                            value: organization,
                            child: Text(
                              organization.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (organization) {
                      if (organization == null) return;
                      setState(
                        () => _memberships.add(
                          PlatformMembership(
                            organizationId: organization.id,
                            organizationName: organization.name,
                            organizationStatus: organization.status,
                            role: 'viewer',
                            status: 'active',
                          ),
                        ),
                      );
                    },
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.platformAdminSaveMembershipsButton),
        ),
      ],
    );
  }
}

Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required bool destructive,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: AppColors.error)
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              destructive
                  ? l10n.platformAdminConfirmActionButton
                  : l10n.commonConfirm,
            ),
          ),
        ],
      );
    },
  );
}
