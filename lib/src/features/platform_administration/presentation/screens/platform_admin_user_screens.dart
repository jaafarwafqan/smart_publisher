part of 'platform_admin_screens.dart';

class PlatformUsersScreen extends ConsumerStatefulWidget {
  const PlatformUsersScreen({super.key});

  @override
  ConsumerState<PlatformUsersScreen> createState() =>
      _PlatformUsersScreenState();
}

class _PlatformUsersScreenState extends ConsumerState<PlatformUsersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload({int? page}) {
    final query = ref.read(platformUsersQueryProvider);
    ref.read(platformUsersQueryProvider.notifier).state = (
      search: _searchController.text,
      isActive: query.isActive,
      isSuperAdmin: query.isSuperAdmin,
      organizationId: query.organizationId,
      membershipRole: query.membershipRole,
      page: page ?? 1,
    );
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
    if (updated == true) {
      _reload(page: ref.read(platformUsersQueryProvider).page);
    }
  }

  Future<void> _editMemberships(PlatformUser user) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _MembershipEditorDialog(user: user),
    );
    if (updated == true) {
      _reload(page: ref.read(platformUsersQueryProvider).page);
    }
  }

  Future<void> _runUserAction(
    Future<void> Function() action,
    String success,
  ) async {
    try {
      await action();
      if (!mounted) return;
      _message(success);
      _reload(page: ref.read(platformUsersQueryProvider).page);
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
    final query = ref.watch(platformUsersQueryProvider);
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
                        selected: query.isActive == true,
                        onSelected: (selected) {
                          ref
                              .read(platformUsersQueryProvider.notifier)
                              .state = (
                            search: _searchController.text,
                            isActive: selected ? true : null,
                            isSuperAdmin: query.isSuperAdmin,
                            organizationId: query.organizationId,
                            membershipRole: query.membershipRole,
                            page: 1,
                          );
                        },
                      ),
                      FilterChip(
                        label: Text(l10n.platformAdminInactiveOnlyChip),
                        selected: query.isActive == false,
                        onSelected: (selected) {
                          ref
                              .read(platformUsersQueryProvider.notifier)
                              .state = (
                            search: _searchController.text,
                            isActive: selected ? false : null,
                            isSuperAdmin: query.isSuperAdmin,
                            organizationId: query.organizationId,
                            membershipRole: query.membershipRole,
                            page: 1,
                          );
                        },
                      ),
                      FilterChip(
                        label: Text(l10n.platformAdminSuperAdminsChip),
                        selected: query.isSuperAdmin == true,
                        onSelected: (selected) {
                          ref
                              .read(platformUsersQueryProvider.notifier)
                              .state = (
                            search: _searchController.text,
                            isActive: query.isActive,
                            isSuperAdmin: selected ? true : null,
                            organizationId: query.organizationId,
                            membershipRole: query.membershipRole,
                            page: 1,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FutureBuilder<PlatformPage<PlatformOrganization>>(
                    future: ref.watch(
                      platformFilterOrganizationsProvider.future,
                    ),
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
                            value: query.organizationId ?? -1,
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
                              ref
                                  .read(platformUsersQueryProvider.notifier)
                                  .state = (
                                search: _searchController.text,
                                isActive: query.isActive,
                                isSuperAdmin: query.isSuperAdmin,
                                organizationId: value == -1 ? null : value,
                                membershipRole: query.membershipRole,
                                page: 1,
                              );
                            },
                          ),
                          DropdownButton<String>(
                            value: query.membershipRole ?? 'all',
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
                              ref
                                  .read(platformUsersQueryProvider.notifier)
                                  .state = (
                                search: _searchController.text,
                                isActive: query.isActive,
                                isSuperAdmin: query.isSuperAdmin,
                                organizationId: query.organizationId,
                                membershipRole: value == 'all' ? null : value,
                                page: 1,
                              );
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
                future: ref.watch(platformUsersPageProvider(query).future),
                builder: (context, snapshot) {
                  final state = snapshot.connectionState != ConnectionState.done
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

  @override
  void dispose() {
    _actionController.dispose();
    super.dispose();
  }

  void _reload({int? page}) {
    final query = ref.read(platformAuditLogQueryProvider);
    ref.read(platformAuditLogQueryProvider.notifier).state = (
      search: _actionController.text,
      organizationId: query.organizationId,
      page: page ?? 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = ref.watch(platformAuditLogQueryProvider);
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
                    future: ref.watch(
                      platformFilterOrganizationsProvider.future,
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      return Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: DropdownButton<int>(
                          value: query.organizationId ?? -1,
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
                            ref
                                .read(platformAuditLogQueryProvider.notifier)
                                .state = (
                              search: _actionController.text,
                              organizationId: value == -1 ? null : value,
                              page: 1,
                            );
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
                future: ref.watch(platformAuditLogPageProvider(query).future),
                builder: (context, snapshot) {
                  final state = snapshot.connectionState != ConnectionState.done
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
