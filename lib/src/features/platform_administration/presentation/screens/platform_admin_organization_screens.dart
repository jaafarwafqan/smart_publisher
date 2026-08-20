part of 'platform_admin_screens.dart';

class PlatformOrganizationsScreen extends ConsumerStatefulWidget {
  const PlatformOrganizationsScreen({super.key});

  @override
  ConsumerState<PlatformOrganizationsScreen> createState() =>
      _PlatformOrganizationsScreenState();
}

class _PlatformOrganizationsScreenState
    extends ConsumerState<PlatformOrganizationsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload({int? page}) {
    final query = ref.read(platformOrganizationsQueryProvider);
    ref.read(platformOrganizationsQueryProvider.notifier).state = (
      search: _searchController.text,
      status: query.status,
      page: page ?? 1,
    );
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
        _reload(page: ref.read(platformOrganizationsQueryProvider).page);
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
        _reload(page: ref.read(platformOrganizationsQueryProvider).page);
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
      _reload(page: ref.read(platformOrganizationsQueryProvider).page);
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
      _reload(page: ref.read(platformOrganizationsQueryProvider).page);
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
    final query = ref.watch(platformOrganizationsQueryProvider);
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
                      selected: <String>{query.status},
                      onSelectionChanged: (value) {
                        ref
                            .read(platformOrganizationsQueryProvider.notifier)
                            .state = (
                          search: _searchController.text,
                          status: value.first,
                          page: 1,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<PlatformPage<PlatformOrganization>>(
                future: ref.watch(
                  platformOrganizationsPageProvider(query).future,
                ),
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
  void _reload() => ref.invalidate(
    platformOrganizationDetailsProvider(widget.organizationId),
  );

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
          future: ref.watch(
            platformOrganizationDetailsProvider(widget.organizationId).future,
          ),
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
