import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/router/guard_state_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/organizations/application/current_organization_access.dart';
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

String _roleLabel(String role) {
  return switch (role) {
    'owner' => 'مالك المؤسسة',
    'admin' => 'مدير المؤسسة',
    'manager' => 'مشرف',
    'editor' => 'محرر',
    'viewer' => 'مشاهد',
    _ => role,
  };
}

String _formatDate(DateTime? date) {
  if (date == null) return 'غير متاح';
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المنصة'),
          actions: <Widget>[
            IconButton(
              tooltip: 'تحديث البيانات',
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'تسجيل الخروج',
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
                content: _PlatformDashboardContent(data: snapshot.data!),
              );
            },
          ),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: <Widget>[
        Text(
          'نظرة عامة على المنصة',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'بيانات مباشرة من النظام عبر صلاحيات إدارة المنصة.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: <Widget>[
            _MetricCard(
              'إجمالي المؤسسات',
              data.organizationsTotal,
              Icons.domain_outlined,
            ),
            _MetricCard(
              'المؤسسات النشطة',
              data.organizationsActive,
              Icons.verified_outlined,
            ),
            _MetricCard(
              'المؤسسات المعطلة',
              data.organizationsInactive,
              Icons.pause_circle_outline,
            ),
            _MetricCard(
              'إجمالي المستخدمين',
              data.usersTotal,
              Icons.people_outline,
            ),
            _MetricCard(
              'مستخدمون جدد (30 يوماً)',
              data.usersLast30Days,
              Icons.person_add_alt_1_outlined,
            ),
            _MetricCard(
              'بلا مالك فعّال',
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
              label: const Text('إدارة المؤسسات'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push(RouteNames.platformUsersPath),
              icon: const Icon(Icons.manage_accounts_outlined),
              label: const Text('إدارة مستخدمي النظام'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(
          title: 'أحدث المؤسسات',
          onViewAll: () => context.push(RouteNames.platformOrganizationsPath),
        ),
        if (data.latestOrganizations.isEmpty)
          const AppEmptyState(
            compact: true,
            title: 'لا توجد مؤسسات حديثة',
            message: 'ستظهر المؤسسات هنا بعد إنشائها.',
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
          title: 'أحدث المستخدمين',
          onViewAll: () => context.push(RouteNames.platformUsersPath),
        ),
        if (data.latestUsers.isEmpty)
          const AppEmptyState(
            compact: true,
            title: 'لا يوجد مستخدمون حديثون',
            message: 'ستظهر الحسابات المنشأة حديثاً هنا.',
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
    final nextStatus = organization.isActive ? 'inactive' : 'active';
    final confirmed = await _confirm(
      context,
      title: nextStatus == 'inactive' ? 'تعطيل المؤسسة' : 'إعادة تفعيل المؤسسة',
      message: nextStatus == 'inactive'
          ? 'سيتم تعطيل «${organization.name}». لن تُحذف أي بيانات.'
          : 'سيتم إعادة تفعيل «${organization.name}».',
      destructive: nextStatus == 'inactive',
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(platformAdminRepositoryProvider)
          .updateOrganizationStatus(organization.id, nextStatus);
      if (mounted) {
        _message(
          nextStatus == 'inactive' ? 'تم تعطيل المؤسسة.' : 'تم تفعيل المؤسسة.',
        );
        _reload(page: _page);
      }
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('المؤسسات')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createOrganization,
          icon: const Icon(Icons.add_business_outlined),
          label: const Text('إنشاء مؤسسة'),
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
                        labelText: 'ابحث بالاسم أو المالك',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          tooltip: 'بحث',
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
                        segments: const <ButtonSegment<String>>[
                          ButtonSegment(value: 'all', label: Text('الكل')),
                          ButtonSegment(value: 'active', label: Text('نشطة')),
                          ButtonSegment(
                            value: 'inactive',
                            label: Text('معطلة'),
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
                        title: 'لا توجد مؤسسات مطابقة',
                        message: 'جرّب تعديل كلمات البحث أو أنشئ مؤسسة جديدة.',
                        actionLabel: 'إنشاء مؤسسة',
                        onAction: _createOrganization,
                      ),
                      content: _OrganizationList(
                        page: snapshot.data!,
                        onStatus: _setStatus,
                        onEdit: _editOrganization,
                        onPage: (page) => _reload(page: page),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تفاصيل المؤسسة')),
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
                content: _OrganizationDetailsContent(details: snapshot.data!),
              );
            },
          ),
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
    final next = !user.isActive;
    final confirmed = await _confirm(
      context,
      title: next ? 'تفعيل الحساب' : 'تعطيل الحساب',
      message: next
          ? 'سيتم تفعيل حساب ${user.email}.'
          : 'سيتم تعطيل حساب ${user.email} وإنهاء جلساته الحالية.',
      destructive: !next,
    );
    if (confirmed != true) return;
    await _runUserAction(
      () => ref
          .read(platformAdminRepositoryProvider)
          .updateUserStatus(user.id, next),
      next ? 'تم تفعيل الحساب.' : 'تم تعطيل الحساب.',
    );
  }

  Future<void> _changePlatformRole(PlatformUser user) async {
    final next = !user.isSuperAdmin;
    final confirmed = await _confirm(
      context,
      title: next ? 'منح مسؤول المنصة' : 'سحب مسؤول المنصة',
      message: next
          ? 'سيُمنح ${user.email} صلاحية مستقلة لإدارة المنصة.'
          : 'سيُسحب وصول ${user.email} إلى إدارة المنصة.',
      destructive: !next,
    );
    if (confirmed != true) return;
    await _runUserAction(
      () => ref
          .read(platformAdminRepositoryProvider)
          .updatePlatformRole(user.id, next),
      next ? 'تم منح صلاحية مسؤول المنصة.' : 'تم سحب صلاحية مسؤول المنصة.',
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مستخدمو النظام')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createUser,
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('إضافة مستخدم'),
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
                        labelText: 'ابحث بالاسم أو البريد الإلكتروني',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          tooltip: 'بحث',
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
                          label: const Text('النشطون فقط'),
                          selected: _isActive == true,
                          onSelected: (selected) {
                            setState(() => _isActive = selected ? true : null);
                            _reload();
                          },
                        ),
                        FilterChip(
                          label: const Text('المعطّلون فقط'),
                          selected: _isActive == false,
                          onSelected: (selected) {
                            setState(() => _isActive = selected ? false : null);
                            _reload();
                          },
                        ),
                        FilterChip(
                          label: const Text('مسؤولو المنصة'),
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
                                const DropdownMenuItem(
                                  value: -1,
                                  child: Text('كل المؤسسات'),
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
                                const DropdownMenuItem(
                                  value: 'all',
                                  child: Text('كل الأدوار'),
                                ),
                                ..._membershipRoles.map(
                                  (role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(_roleLabel(role)),
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
                        title: 'لا توجد حسابات مطابقة',
                        message: 'عدّل الفلاتر أو أضف مستخدماً جديداً.',
                        actionLabel: 'إضافة مستخدم',
                        onAction: _createUser,
                      ),
                      content: _UserList(
                        page: snapshot.data!,
                        onStatus: _changeStatus,
                        onPlatformRole: _changePlatformRole,
                        onEdit: _editUser,
                        onMemberships: _editMemberships,
                        onPage: (page) => _reload(page: page),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
    return SizedBox(
      width: 220,
      child: Card(
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
      TextButton(onPressed: onViewAll, child: const Text('عرض الكل')),
    ],
  );
}

class _OrganizationList extends StatelessWidget {
  const _OrganizationList({
    required this.page,
    required this.onStatus,
    required this.onEdit,
    required this.onPage,
  });
  final PlatformPage<PlatformOrganization> page;
  final ValueChanged<PlatformOrganization> onStatus;
  final ValueChanged<PlatformOrganization> onEdit;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      0,
      AppSpacing.lg,
      AppSpacing.xxl,
    ),
    children: <Widget>[
      Text(
        '${page.total} مؤسسة',
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
          actions: PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'edit') {
                onEdit(organization);
              } else {
                onStatus(organization);
              }
            },
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              const PopupMenuItem(
                value: 'edit',
                child: Text('تعديل اسم المؤسسة'),
              ),
              PopupMenuItem(
                value: 'status',
                child: Text(
                  organization.isActive ? 'تعطيل المؤسسة' : 'إعادة التفعيل',
                ),
              ),
            ],
          ),
        ),
      ),
      _Pagination(page: page, onPage: onPage),
    ],
  );
}

class _OrganizationTile extends StatelessWidget {
  const _OrganizationTile({
    required this.organization,
    required this.onTap,
    this.actions,
  });
  final PlatformOrganization organization;
  final VoidCallback onTap;
  final Widget? actions;

  @override
  Widget build(BuildContext context) => Card(
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
      subtitle: Text(
        '${organization.primaryOwner?.name ?? 'لا يوجد مالك فعّال'} · ${organization.membersCount} أعضاء · أنشئت ${_formatDate(organization.createdAt)}',
      ),
      trailing: actions == null
          ? StatusPill(
              label: organization.isActive ? 'نشطة' : 'معطلة',
              tone: organization.isActive ? PillTone.success : PillTone.danger,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                StatusPill(
                  label: organization.isActive ? 'نشطة' : 'معطلة',
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

class _OrganizationDetailsContent extends StatelessWidget {
  const _OrganizationDetailsContent({required this.details});
  final PlatformOrganizationDetails details;

  @override
  Widget build(BuildContext context) {
    final organization = details.organization;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        Text(
          organization.name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            StatusPill(
              label: organization.isActive ? 'نشطة' : 'معطلة',
              tone: organization.isActive ? PillTone.success : PillTone.danger,
            ),
            StatusPill(label: '${organization.membersCount} أعضاء'),
            StatusPill(
              label: 'آخر نشاط: ${_formatDate(organization.lastActivityAt)}',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _DetailSection(
          title: 'الأعضاء والأدوار',
          child: details.members.isEmpty
              ? const AppEmptyState(
                  compact: true,
                  title: 'لا يوجد أعضاء',
                  message: 'لا توجد عضويات مسجلة لهذه المؤسسة.',
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
                            label: _roleLabel(member.role),
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
          title: 'الحسابات الاجتماعية المرتبطة',
          child: details.socialAccounts.isEmpty
              ? const AppEmptyState(
                  compact: true,
                  title: 'لا توجد حسابات مرتبطة',
                  message: 'لا تظهر هنا أي رموز وصول أو أسرار.',
                )
              : Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: details.socialAccounts
                      .map(
                        (account) => StatusPill(
                          label:
                              '${account['provider'] ?? 'حساب'} · ${account['account_name'] ?? account['account_username'] ?? 'غير مسمى'}',
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
          title: 'ملخص المنشورات',
          child: details.postsSummary.isEmpty
              ? const AppEmptyState(
                  compact: true,
                  title: 'لا توجد منشورات',
                  message: 'سيظهر ملخص الحالات عند توفر منشورات.',
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
    required this.onPage,
  });
  final PlatformPage<PlatformUser> page;
  final ValueChanged<PlatformUser> onStatus;
  final ValueChanged<PlatformUser> onPlatformRole;
  final ValueChanged<PlatformUser> onEdit;
  final ValueChanged<PlatformUser> onMemberships;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      0,
      AppSpacing.lg,
      AppSpacing.xxl,
    ),
    children: <Widget>[
      Text(
        '${page.total} مستخدم',
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
              }
            },
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              const PopupMenuItem(value: 'edit', child: Text('تعديل البيانات')),
              const PopupMenuItem(
                value: 'memberships',
                child: Text('إدارة العضويات'),
              ),
              PopupMenuItem(
                value: 'role',
                child: Text(
                  user.isSuperAdmin ? 'سحب مسؤول المنصة' : 'منح مسؤول المنصة',
                ),
              ),
              PopupMenuItem(
                value: 'status',
                child: Text(user.isActive ? 'تعطيل الحساب' : 'تفعيل الحساب'),
              ),
            ],
          ),
        ),
      ),
      _Pagination(page: page, onPage: onPage),
    ],
  );
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, this.actions});
  final PlatformUser user;
  final Widget? actions;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: ListTile(
      leading: CircleAvatar(
        child: Text(user.name.isEmpty ? '?' : user.name.substring(0, 1)),
      ),
      title: Text(user.name),
      subtitle: Text(
        '${user.email}\n${user.memberships.isEmpty ? 'بلا مؤسسة' : user.memberships.map((membership) => '${membership.organizationName} (${_roleLabel(membership.role)})').join(' · ')}',
      ),
      isThreeLine: user.memberships.isNotEmpty,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (user.isSuperAdmin)
            const Padding(
              padding: EdgeInsetsDirectional.only(end: AppSpacing.xs),
              child: StatusPill(label: 'مسؤول المنصة', tone: PillTone.warning),
            ),
          StatusPill(
            label: user.isActive ? 'نشط' : 'معطل',
            tone: user.isActive ? PillTone.success : PillTone.danger,
          ),
          if (actions case final Widget actions) actions,
        ],
      ),
    ),
  );
}

class _Pagination<T> extends StatelessWidget {
  const _Pagination({required this.page, required this.onPage});
  final PlatformPage<T> page;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    if (page.lastPage <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          OutlinedButton.icon(
            onPressed: page.currentPage > 1
                ? () => onPage(page.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('السابق'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text('${page.currentPage} / ${page.lastPage}'),
          ),
          OutlinedButton.icon(
            onPressed: page.currentPage < page.lastPage
                ? () => onPage(page.currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('التالي'),
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
    final isForbidden =
        error is PlatformAdminException &&
        (error as PlatformAdminException).isForbidden;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AppEmptyState(
          icon: isForbidden ? Icons.lock_outline : Icons.cloud_off_outlined,
          title: isForbidden ? 'غير مصرح لك' : 'تعذر تحميل البيانات',
          message: isForbidden
              ? 'تم رفض الوصول من الخادم. تأكد من أن للحساب صلاحية مسؤول المنصة.'
              : 'تعذر الاتصال ببيانات إدارة المنصة. حاول مجدداً.',
          actionLabel: isForbidden ? null : 'إعادة المحاولة',
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
    _availableUsers = ref.read(platformAdminRepositoryProvider).getUsers();
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
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('إنشاء مؤسسة'),
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
                decoration: const InputDecoration(labelText: 'اسم المؤسسة'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'اسم المؤسسة مطلوب.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<bool>(
                segments: const <ButtonSegment<bool>>[
                  ButtonSegment(value: false, label: Text('مالك جديد')),
                  ButtonSegment(value: true, label: Text('مالك موجود')),
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
                      decoration: const InputDecoration(
                        labelText: 'مالك المؤسسة',
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
                      validator: (value) =>
                          value == null ? 'اختر مالكاً فعّالاً.' : null,
                    );
                  },
                )
              else ...<Widget>[
                TextFormField(
                  controller: _ownerName,
                  decoration: const InputDecoration(labelText: 'اسم المالك'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'اسم المالك مطلوب.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _ownerEmail,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'بريد المالك الإلكتروني',
                  ),
                  validator: (value) => value == null || !value.contains('@')
                      ? 'أدخل بريداً إلكترونياً صحيحاً.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _ownerPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة مرور المالك (12 حرفاً على الأقل)',
                  ),
                  validator: (value) => value == null || value.length < 12
                      ? 'أدخل كلمة مرور من 12 حرفاً على الأقل.'
                      : null,
                ),
              ],
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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
        child: const Text('إلغاء'),
      ),
      FilledButton(
        onPressed: _submitting ? null : _submit,
        child: _submitting
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('إنشاء المؤسسة'),
      ),
    ],
  );
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
      setState(() => _error = 'اسم المؤسسة مطلوب.');
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
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('تعديل اسم المؤسسة'),
    content: SizedBox(
      width: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'اسم المؤسسة'),
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
        child: const Text('إلغاء'),
      ),
      FilledButton(
        onPressed: _submitting ? null : _submit,
        child: const Text('حفظ'),
      ),
    ],
  );
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
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('إضافة مستخدم'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'الاسم'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'الاسم مطلوب.' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
              validator: (value) => value == null || !value.contains('@')
                  ? 'أدخل بريداً صحيحاً.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور (12 حرفاً على الأقل)',
              ),
              validator: (value) => value == null || value.length < 12
                  ? 'أدخل كلمة مرور من 12 حرفاً على الأقل.'
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
                        const DropdownMenuItem(
                          value: -1,
                          child: Text('بدون مؤسسة'),
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
                                child: Text(_roleLabel(role)),
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
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: _submitting ? null : () => Navigator.of(context).pop(),
        child: const Text('إلغاء'),
      ),
      FilledButton(
        onPressed: _submitting ? null : _submit,
        child: _submitting
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('إضافة'),
      ),
    ],
  );
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
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('تعديل بيانات المستخدم'),
    content: SizedBox(
      width: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'الاسم'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
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
        child: const Text('إلغاء'),
      ),
      FilledButton(
        onPressed: _submitting ? null : _submit,
        child: const Text('حفظ'),
      ),
    ],
  );
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
  Widget build(BuildContext context) => AlertDialog(
    title: Text('عضويات ${widget.user.name}'),
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
                const Text(
                  'تغيير دور مالك أو إزالة عضويته يتطلب بقاء مالك فعّال واحد على الأقل؛ الخادم يتحقق من ذلك نهائياً.',
                ),
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
                                    child: Text(_roleLabel(role)),
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
                            tooltip: 'إزالة العضوية',
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
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'إضافة إلى مؤسسة',
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
        child: const Text('إلغاء'),
      ),
      FilledButton(
        onPressed: _submitting ? null : _submit,
        child: _submitting
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('حفظ العضويات'),
      ),
    ],
  );
}

Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required bool destructive,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AppColors.error)
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(destructive ? 'تأكيد الإجراء' : 'تأكيد'),
        ),
      ],
    ),
  );
}
