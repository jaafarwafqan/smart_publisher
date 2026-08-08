import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/feature_flags/feature_flags.dart';
import '../../../../core/result/app_result.dart';
import '../../../../core/router/guard_state_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/storage/storage_provider.dart';
import '../../../../core/theme/app_curves.dart';
import '../../../../core/theme/app_duration.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/web/current_uri.dart';
import '../../../../core/web/facebook_oauth_callback.dart';
import '../../../../shared/widgets/adaptive_content_width.dart';
import '../../../../shared/widgets/app_async_switcher.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../../analytics/domain/entities/analytics_summary_entity.dart';
import '../../../auth/application/auth_session_controller.dart';
import '../../../auth/domain/entities/account_entity.dart';
import '../../../notifications/domain/entities/notification_entity.dart';
import '../../../organizations/application/current_organization_access.dart';
import '../../../posts/domain/entities/post_entity.dart';
import '../../application/account_operation_access.dart';
import '../utils/dashboard_post_filters.dart';
import '../utils/platform_label.dart';
import '../widgets/accounts_grid.dart';
import '../widgets/add_telegram_channel_dialog.dart';
import '../widgets/connect_telegram_bot_dialog.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/post_status_section.dart';
import '../widgets/publishing_health_card.dart';
import '../widgets/recent_activity_list.dart';
import '../widgets/whatsapp_business_id_dialog.dart';
import '../widgets/workspace_modules_grid.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  // Web development can use localhost. Meta requires a valid HTTPS redirect
  // URI for the mobile browser flow, so test/production builds may supply a
  // public callback that relays back to the registered Android deep link.
  static const String _webDevelopmentOAuthRedirectUri =
      'http://localhost:5055/';
  static const String _mobileOAuthRedirectUri = String.fromEnvironment(
    'SP_SOCIAL_OAUTH_REDIRECT_URI',
    defaultValue: 'smartpublisher://oauth/callback',
  );

  @visibleForTesting
  static String oauthRedirectUriFor({required bool isWeb}) {
    return isWeb ? _webDevelopmentOAuthRedirectUri : _mobileOAuthRedirectUri;
  }

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Written just before the OAuth redirect and read back after the browser
  // returns with ?code=&state=, since the callback URL itself carries no hint
  // of which provider ('facebook' or 'whatsapp') started the flow.
  static const String _oauthPendingProviderKey = 'oauth.pending_provider';

  String get _oauthRedirectUri =>
      DashboardScreen.oauthRedirectUriFor(isWeb: kIsWeb);

  late final Future<AuthSession?> _sessionFuture;
  AsyncValue<_DashboardData> _dashboard = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    _sessionFuture = ref.read(authSessionControllerProvider).currentSession();
    unawaited(_refreshDashboard());
    _maybeCompleteOAuth();
  }

  Future<List<PostEntity>> _loadPosts() async {
    final result = await ref.read(postRepositoryProvider).getPosts();
    return _requireData(result, 'Posts could not be loaded.');
  }

  Future<List<AccountEntity>> _loadAccounts(String userId) async {
    final result = await ref
        .read(accountRepositoryProvider)
        .getAccounts(userId: userId);
    return _requireData(result, 'Accounts could not be loaded.');
  }

  Future<AnalyticsSummaryEntity> _loadSummary() async {
    final result = await ref.read(analyticsRepositoryProvider).getSummary();
    return _requireData(result, 'Analytics summary could not be loaded.');
  }

  Future<List<NotificationEntity>> _loadNotifications() async {
    final result = await ref
        .read(notificationRepositoryProvider)
        .getNotifications();
    return _requireData(result, 'Notifications could not be loaded.');
  }

  Future<_DashboardData> _loadDashboard() async {
    final session = await _sessionFuture;
    if (session == null) {
      throw StateError('No authenticated session is available.');
    }

    final results = await Future.wait<Object>(<Future<Object>>[
      _loadPosts(),
      _loadAccounts(session.user.id),
      _loadSummary(),
      _loadNotifications(),
    ]);

    return _DashboardData(
      session: session,
      posts: results[0] as List<PostEntity>,
      accounts: results[1] as List<AccountEntity>,
      summary: results[2] as AnalyticsSummaryEntity,
      notifications: results[3] as List<NotificationEntity>,
    );
  }

  T _requireData<T>(AppResult<T> result, String fallbackMessage) {
    final data = result.data;
    if (!result.isSuccess || data == null) {
      throw StateError(result.message ?? fallbackMessage);
    }

    return data;
  }

  Future<String?> _currentUserId() async {
    final session = await _sessionFuture;
    return session?.user.id;
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _dashboard = const AsyncLoading();
    });
    final dashboard = await AsyncValue.guard(_loadDashboard);
    if (!mounted) {
      return;
    }
    setState(() => _dashboard = dashboard);
  }

  void _showFeedback(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _connectAccount(AccountEntity account) async {
    if (!isBetaLaunchPlatform(account.platform)) {
      _showFeedback(
        AppLocalizations.of(
          context,
        )!.comingSoonSuffix(platformLabel(account.platform)),
      );
      return;
    }

    if (account.platform == 'telegram') {
      await _connectTelegramBot(account);
      return;
    }
    if (account.platform == 'facebook') {
      await _connectViaOAuth(account, 'facebook');
      return;
    }
    if (account.platform == 'whatsapp') {
      await _connectViaOAuth(account, 'whatsapp');
      return;
    }
    if (account.platform == 'instagram') {
      _showInstagramManagedViaFacebookDialog();
      return;
    }

    final userId = await _currentUserId();
    if (userId == null) {
      return;
    }
    final result = await ref
        .read(accountRepositoryProvider)
        .connectAccount(account, userId: userId);
    if (!mounted) {
      return;
    }
    unawaited(_refreshDashboard());
    final l10n = AppLocalizations.of(context)!;
    _showFeedback(
      result.isSuccess
          ? l10n.accountConnectedSuccess(account.name)
          : result.message ?? l10n.accountConnectFailed(account.name),
    );
  }

  Future<void> _connectTelegramBot(AccountEntity account) async {
    final botToken = await showConnectTelegramBotDialog(context);
    if (botToken == null || !mounted) {
      return;
    }
    final userId = await _currentUserId();
    if (userId == null) {
      return;
    }
    final result = await ref
        .read(accountRepositoryProvider)
        .connectTelegramBot(userId: userId, botToken: botToken);
    if (!mounted) {
      return;
    }
    unawaited(_refreshDashboard());
    final l10n = AppLocalizations.of(context)!;
    _showFeedback(
      result.isSuccess
          ? l10n.telegramBotConnectedSuccess
          : result.message ?? l10n.telegramBotConnectFailed,
    );
  }

  String _platformLabel(String provider) =>
      provider == 'whatsapp' ? 'WhatsApp' : 'Facebook';

  Future<void> _connectViaOAuth(AccountEntity account, String provider) async {
    final userId = await _currentUserId();
    if (userId == null) {
      return;
    }
    final repository = ref.read(accountRepositoryProvider);
    final result = provider == 'whatsapp'
        ? await repository.beginWhatsAppOAuth(
            userId: userId,
            redirectUri: _oauthRedirectUri,
          )
        : await repository.beginFacebookOAuth(
            userId: userId,
            redirectUri: _oauthRedirectUri,
          );
    if (!mounted) {
      return;
    }
    if (!result.isSuccess || result.data == null) {
      _showFeedback(
        result.message ??
            AppLocalizations.of(
              context,
            )!.platformConnectionStartFailed(_platformLabel(provider)),
      );
      return;
    }

    // The callback URL carries no hint of which provider started the flow,
    // so it's recorded here and read back in _maybeCompleteOAuth() once the
    // browser returns.
    await ref
        .read(storageServiceProvider)
        .writeString(_oauthPendingProviderKey, provider);

    // Full top-level navigation to Meta's real login/consent dialog — this
    // tab reloads once it redirects back with ?code=&state=, so nothing
    // after this call runs in the current app instance.
    await launchUrl(Uri.parse(result.data!), webOnlyWindowName: '_self');
  }

  Future<void> _maybeCompleteOAuth() async {
    final callback = FacebookOAuthCallback.fromUri(currentUri());
    if (!callback.isCallback) {
      return;
    }

    final storage = ref.read(storageServiceProvider);
    final provider =
        await storage.readString(_oauthPendingProviderKey) ?? 'facebook';
    await storage.delete(_oauthPendingProviderKey);

    if (callback.error != null) {
      if (!mounted) {
        return;
      }
      _showFeedback(
        AppLocalizations.of(
          context,
        )!.platformConnectionCancelled(_platformLabel(provider)),
      );
      return;
    }
    if (!callback.isSuccess) {
      return;
    }

    final userId = await _currentUserId();
    if (userId == null || !mounted) {
      return;
    }
    final repository = ref.read(accountRepositoryProvider);
    final result = provider == 'whatsapp'
        ? await repository.completeWhatsAppOAuth(
            userId: userId,
            code: callback.code!,
            state: callback.state!,
          )
        : await repository.completeFacebookOAuth(
            userId: userId,
            code: callback.code!,
            state: callback.state!,
          );
    if (!mounted) {
      return;
    }
    if (result.isSuccess) {
      unawaited(_refreshDashboard());
      _showFeedback(
        AppLocalizations.of(
          context,
        )!.platformConnectedSuccess(_platformLabel(provider)),
      );

      final account = result.data;
      if (provider == 'whatsapp' &&
          account != null &&
          !account.hasWhatsAppBusinessId) {
        await _promptWhatsAppBusinessId(account, userId);
      }
    }
    // A silent no-op on failure here is deliberate: this runs automatically
    // on every dashboard load, and a stale/refreshed page would otherwise
    // re-submit an already-consumed code, which the backend correctly (and
    // harmlessly) rejects — only user-initiated connect attempts surface
    // errors prominently.
  }

  Future<void> _promptWhatsAppBusinessId(
    AccountEntity account,
    String userId,
  ) async {
    final businessId = await showWhatsAppBusinessIdDialog(context);
    if (businessId == null || !mounted || account.remoteId == null) {
      return;
    }
    final result = await ref
        .read(accountRepositoryProvider)
        .setWhatsAppBusinessId(
          userId: userId,
          socialAccountId: account.remoteId!,
          businessId: businessId,
        );
    if (!mounted) {
      return;
    }
    if (result.isSuccess) {
      unawaited(_refreshDashboard());
    }
    final l10n = AppLocalizations.of(context)!;
    _showFeedback(
      result.isSuccess
          ? l10n.whatsappBusinessIdSaved
          : result.message ?? l10n.whatsappBusinessIdSaveFailed,
    );
  }

  void _showInstagramManagedViaFacebookDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      animationStyle: const AnimationStyle(
        duration: AppDuration.normal,
        reverseDuration: AppDuration.fast,
        curve: AppCurves.standard,
        reverseCurve: AppCurves.standard,
      ),
      builder: (context) => AlertDialog(
        title: Text(l10n.instagramDialogTitle),
        content: Text(l10n.instagramDialogBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.gotIt),
          ),
        ],
      ),
    );
  }

  Future<void> _syncPages(AccountEntity account) async {
    final userId = await _currentUserId();
    if (userId == null) {
      return;
    }
    final result = await ref
        .read(accountRepositoryProvider)
        .syncPages(account, userId: userId);
    if (!mounted) {
      return;
    }
    unawaited(_refreshDashboard());
    final l10n = AppLocalizations.of(context)!;
    _showFeedback(
      result.isSuccess
          ? l10n.pagesSyncedSuccess(account.name)
          : result.message ?? l10n.pagesSyncFailed(account.name),
    );
  }

  Future<void> _addChannel(AccountEntity account) async {
    final identifier = await showAddTelegramChannelDialog(context);
    if (identifier == null || !mounted) {
      return;
    }
    final userId = await _currentUserId();
    if (userId == null) {
      return;
    }
    final result = await ref
        .read(accountRepositoryProvider)
        .addPage(account, userId: userId, identifier: identifier);
    if (!mounted) {
      return;
    }
    unawaited(_refreshDashboard());
    final l10n = AppLocalizations.of(context)!;
    _showFeedback(
      result.isSuccess
          ? l10n.channelAddedSuccess(account.name)
          : result.message ?? l10n.channelAddFailed(account.name),
    );
  }

  Future<void> _saveSelectedPages(
    AccountEntity account,
    List<String> pageIds,
  ) async {
    final userId = await _currentUserId();
    if (userId == null) {
      return;
    }
    final result = await ref
        .read(accountRepositoryProvider)
        .selectPages(account, userId: userId, pageIds: pageIds);
    if (!mounted) {
      return;
    }
    unawaited(_refreshDashboard());
    final l10n = AppLocalizations.of(context)!;
    _showFeedback(
      result.isSuccess
          ? l10n.selectedPagesUpdatedSuccess(account.name)
          : result.message ?? l10n.selectedPagesUpdateFailed,
    );
  }

  Future<void> _deletePage(AccountEntity account, String pageId) async {
    final userId = await _currentUserId();
    if (userId == null) {
      return;
    }
    final result = await ref
        .read(accountRepositoryProvider)
        .deletePage(account, userId: userId, pageId: pageId);
    if (!mounted) {
      return;
    }
    unawaited(_refreshDashboard());
    final l10n = AppLocalizations.of(context)!;
    _showFeedback(
      result.isSuccess
          ? l10n.pageRemovedSuccess(account.name)
          : result.message ?? l10n.pageRemoveFailed,
    );
  }

  Future<void> _disconnectAccount(AccountEntity account) async {
    final userId = await _currentUserId();
    if (userId == null) {
      return;
    }
    final result = await ref
        .read(accountRepositoryProvider)
        .disconnectAccount(account, userId: userId);
    if (!mounted) {
      return;
    }
    unawaited(_refreshDashboard());
    final l10n = AppLocalizations.of(context)!;
    _showFeedback(
      result.isSuccess
          ? l10n.accountDisconnectedSuccess(account.name)
          : result.message ?? l10n.accountDisconnectFailed(account.name),
    );
  }

  Future<void> _refreshAccountToken(AccountEntity account) async {
    final userId = await _currentUserId();
    if (userId == null) {
      return;
    }
    final result = await ref
        .read(accountRepositoryProvider)
        .refreshToken(account, userId: userId);
    if (!mounted) {
      return;
    }
    unawaited(_refreshDashboard());
    final l10n = AppLocalizations.of(context)!;
    _showFeedback(
      result.isSuccess
          ? l10n.refreshTokenRequestedSuccess(account.name)
          : result.message ?? l10n.refreshTokenFailed(account.name),
    );
  }

  Future<void> _testConnection(AccountEntity account) async {
    final userId = await _currentUserId();
    if (userId == null) {
      return;
    }
    final result = await ref
        .read(accountRepositoryProvider)
        .testConnection(account, userId: userId);
    if (!mounted) {
      return;
    }
    // A real check can flip the account's status server-side (self-healing
    // or newly-expired), so the list is always reloaded regardless of
    // whether the check itself succeeded as a request.
    unawaited(_refreshDashboard());
    _showFeedback(
      result.isSuccess
          ? result.data!.message
          : result.message ??
                AppLocalizations.of(
                  context,
                )!.testConnectionFailed(account.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final organizationAccess = ref
        .watch(currentOrganizationAccessProvider)
        .when(
          data: (access) => access,
          loading: () => null,
          error: (_, _) => null,
        );
    final accountOperationAccess =
        AccountOperationAccess.fromOrganizationAccess(organizationAccess);
    final dashboard = _dashboard.valueOrNull;
    final dashboardState = _dashboard.isLoading
        ? AppAsyncState.loading
        : _dashboard.hasError
        ? AppAsyncState.error
        : AppAsyncState.content;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.logoutTooltip,
            onPressed: () async {
              await ref.read(authSessionControllerProvider).logout();
              await ref.read(activeOrganizationStoreProvider).clear();
              ref.invalidate(authStateProvider);
              ref.invalidate(currentUserRoleProvider);
              ref.invalidate(currentOrganizationAccessProvider);
              if (!context.mounted) {
                return;
              }
              context.go(RouteNames.loginPath);
            },
            icon: const Icon(Icons.logout),
          ),
          if (globalFeatureFlags.isEnabled(
            FeatureFlagKeys.performanceDashboard,
          ))
            IconButton(
              tooltip: l10n.performanceTooltip,
              onPressed: () => context.pushNamed(RouteNames.performanceDev),
              icon: const Icon(Icons.speed),
            ),
        ],
      ),
      body: AdaptiveContentWidth(
        maxWidth: 1200,
        child: AppAsyncSwitcher(
          state: dashboardState,
          duration: AppDuration.slow,
          reverseDuration: AppDuration.fast,
          loading: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.commonLoading),
              ],
            ),
          ),
          empty: const SizedBox.shrink(),
          error: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.cloud_off_outlined, size: 40),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.dashboardLoadFailed, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _refreshDashboard,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.commonRetry),
                  ),
                ],
              ),
            ),
          ),
          content: dashboard == null
              ? const SizedBox.shrink()
              : _buildDashboardContent(
                  context,
                  dashboard,
                  accountOperationAccess,
                  organizationAccess,
                ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    _DashboardData dashboard,
    AccountOperationAccess accountOperationAccess,
    OrganizationAccessState? organizationAccess,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final accounts = dashboard.accounts;
    final connected = accounts.where((account) => account.isConnected).length;
    final stats = <DashboardStat>[
      DashboardStat(
        label: l10n.dashboardStatPosts,
        value: '${dashboard.summary.totalPosts}',
        icon: Icons.article_outlined,
      ),
      DashboardStat(
        label: l10n.dashboardStatScheduled,
        value: '${dashboard.summary.scheduled}',
        icon: Icons.schedule,
      ),
      DashboardStat(
        label: l10n.dashboardStatPublished,
        value: '${dashboard.summary.published}',
        icon: Icons.send_outlined,
      ),
      DashboardStat(
        label: l10n.dashboardStatFailed,
        value: '${dashboard.summary.failed}',
        icon: Icons.error_outline,
      ),
      DashboardStat(
        label: l10n.dashboardStatAccounts,
        value: '$connected/${accounts.length}',
        icon: Icons.groups_2_outlined,
      ),
    ];
    final recent = dashboard.posts.toList()
      ..sort(
        (a, b) => (b.publishedAt ?? b.updatedAt ?? DateTime(0)).compareTo(
          a.publishedAt ?? a.updatedAt ?? DateTime(0),
        ),
      );
    final unread = dashboard.notifications
        .where((notification) => !notification.isRead)
        .length;

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          _Header(
            session: dashboard.session,
            canCreatePost:
                organizationAccess?.hasPermission(
                  OrganizationPermissions.postsCreate,
                ) ??
                false,
            canViewPosts:
                organizationAccess?.hasAnyPermission(<String>{
                  OrganizationPermissions.postsViewOwn,
                  OrganizationPermissions.postsViewAll,
                }) ??
                false,
            organizationAccess: organizationAccess,
          ),
          const SizedBox(height: AppSpacing.xl),
          _StatTileRow(stats: stats),
          const SizedBox(height: AppSpacing.xl),
          _PostStatusRow(posts: dashboard.posts, now: now),
          const SizedBox(height: AppSpacing.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 860;
              final accountsGrid = AccountsGrid(
                accounts: accounts,
                isLoading: false,
                onConnect: _connectAccount,
                onDisconnect: _disconnectAccount,
                onRefreshToken: _refreshAccountToken,
                onTestConnection: _testConnection,
                onSyncPages: _syncPages,
                onAddChannel: _addChannel,
                onSaveSelection: _saveSelectedPages,
                onDeletePage: _deletePage,
                operationAccess: accountOperationAccess,
              );
              final healthCard = PublishingHealthCard(
                summary: dashboard.summary,
                platformDistribution: platformDistribution(dashboard.posts),
                connectedAccounts: connected,
                totalAccounts: accounts.length,
              );

              if (stacked) {
                return Column(
                  children: <Widget>[
                    accountsGrid,
                    const SizedBox(height: AppSpacing.lg),
                    healthCard,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 3, child: accountsGrid),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(flex: 2, child: healthCard),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          WorkspaceModulesGrid(
            modules: _buildModules(
              context,
              dashboard.posts,
              unread,
              now,
              organizationAccess,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          RecentActivityList(posts: recent.take(8).toList(growable: false)),
        ],
      ),
    );
  }

  List<WorkspaceModule> _buildModules(
    BuildContext context,
    List<PostEntity> posts,
    int unreadNotifications,
    DateTime now,
    OrganizationAccessState? organizationAccess,
  ) {
    final todayCount = scheduledToday(posts, now).length;
    final l10n = AppLocalizations.of(context)!;

    return <WorkspaceModule>[
      WorkspaceModule(
        icon: Icons.perm_media_outlined,
        title: l10n.moduleMediaLibraryTitle,
        description: l10n.moduleMediaLibraryDescription,
        onTap: () => context.go(RouteNames.mediaLibraryPath),
      ),
      WorkspaceModule(
        icon: Icons.calendar_month_outlined,
        title: l10n.moduleCalendarTitle,
        description: l10n.moduleCalendarDescription,
        badge: todayCount > 0 ? l10n.moduleCalendarBadge(todayCount) : null,
        onTap: () => context.go(RouteNames.calendarPath),
      ),
      WorkspaceModule(
        icon: Icons.insights_outlined,
        title: l10n.moduleAnalyticsTitle,
        description: l10n.moduleAnalyticsDescription,
        onTap: () => context.go(RouteNames.analyticsPath),
      ),
      WorkspaceModule(
        icon: Icons.notifications_active_outlined,
        title: l10n.moduleNotificationsTitle,
        description: l10n.moduleNotificationsDescription,
        badge: unreadNotifications > 0 ? '$unreadNotifications' : null,
        onTap: () => context.go(RouteNames.notificationsPath),
      ),
      if (organizationAccess?.hasPermission(
            OrganizationPermissions.settingsManage,
          ) ??
          false) ...<WorkspaceModule>[
        WorkspaceModule(
          icon: Icons.settings_outlined,
          title: l10n.moduleSettingsTitle,
          description: l10n.moduleSettingsDescription,
          onTap: () => context.go(RouteNames.settingsPath),
        ),
        WorkspaceModule(
          icon: Icons.admin_panel_settings_outlined,
          title: l10n.moduleAdministrationTitle,
          description: l10n.moduleAdministrationDescription,
          onTap: () => context.go(RouteNames.administrationPath),
        ),
        WorkspaceModule(
          icon: Icons.rocket_launch_outlined,
          title: l10n.moduleProductionReleaseTitle,
          description: l10n.moduleProductionReleaseDescription,
          onTap: () => context.go(RouteNames.productionReleasePath),
        ),
      ],
    ];
  }
}

class _DashboardData {
  const _DashboardData({
    required this.session,
    required this.posts,
    required this.accounts,
    required this.summary,
    required this.notifications,
  });

  final AuthSession session;
  final List<PostEntity> posts;
  final List<AccountEntity> accounts;
  final AnalyticsSummaryEntity summary;
  final List<NotificationEntity> notifications;
}

/// The badge previously showed [AuthSession.role] — a legacy, account-wide
/// role (guest/publisher/admin) that has no bearing on what the user can
/// actually do; every real permission check in this app goes through the
/// CURRENT organization's membership role instead (owner/admin/manager/
/// editor/viewer), which wasn't shown anywhere. A user could be the full
/// owner of their own organization and still see "Guest" here. Mirrors
/// [OrganizationAccessState]'s own three states: an active membership (show
/// its role, switches immediately with the organization), memberships that
/// exist but none is currently selected ("choose an organization"), and no
/// memberships at all ("no active membership") — never "Guest" for any of
/// these, since that implied a real, if limited, access level.
String _organizationRoleBadgeLabel(
  OrganizationAccessState? organizationAccess,
  AppLocalizations l10n,
) {
  final access = organizationAccess;
  if (access == null) {
    return l10n.dashboardGuestRole;
  }
  if (!access.hasActiveOrganization) {
    return access.hasMemberships
        ? l10n.dashboardChooseOrganizationRole
        : l10n.dashboardNoActiveMembershipRole;
  }
  switch (access.currentOrganization!.role.trim().toLowerCase()) {
    case 'owner':
      return l10n.dashboardRoleOwner;
    case 'admin':
      return l10n.dashboardRoleAdmin;
    case 'manager':
      return l10n.dashboardRoleManager;
    case 'editor':
      return l10n.dashboardRoleEditor;
    case 'viewer':
      return l10n.dashboardRoleViewer;
    default:
      return access.currentOrganization!.role;
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.session,
    required this.canCreatePost,
    required this.canViewPosts,
    required this.organizationAccess,
  });

  final AuthSession? session;
  final bool canCreatePost;
  final bool canViewPosts;
  final OrganizationAccessState? organizationAccess;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[colorScheme.primary, colorScheme.primaryContainer],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.dashboardTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: colorScheme.onPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.dashboardSubtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              StatusPill(
                icon: Icons.person_outline,
                label:
                    session?.user.name ??
                    l10n.dashboardAuthenticatedUserFallback,
                foregroundColor: colorScheme.onPrimary,
                backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.14),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              StatusPill(
                icon: Icons.mail_outline,
                label: session?.user.email ?? l10n.dashboardNoEmailFallback,
                foregroundColor: colorScheme.onPrimary,
                backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.14),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              StatusPill(
                icon: Icons.verified_user_outlined,
                label: _organizationRoleBadgeLabel(organizationAccess, l10n),
                foregroundColor: colorScheme.onPrimary,
                backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.14),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              if (canCreatePost)
                _PressScale(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.onPrimary,
                      foregroundColor: colorScheme.primary,
                    ),
                    onPressed: () => context.go(RouteNames.postsCreatePath),
                    icon: const Icon(Icons.edit_note_outlined),
                    label: Text(l10n.dashboardCreatePostButton),
                  ),
                ),
              if (canViewPosts)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onPrimary,
                    side: BorderSide(
                      color: colorScheme.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                  onPressed: () => context.go(RouteNames.postsListPath),
                  icon: const Icon(Icons.library_books_outlined),
                  label: Text(l10n.dashboardPostsButton),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PressScale extends StatefulWidget {
  const _PressScale({required this.child});

  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed != value) {
      setState(() => _isPressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedContainer(
        duration: AppDuration.fast,
        curve: AppCurves.standard,
        transform: Matrix4.diagonal3Values(
          _isPressed ? 0.97 : 1,
          _isPressed ? 0.97 : 1,
          1,
        ),
        transformAlignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}

class _StatTileRow extends StatelessWidget {
  const _StatTileRow({required this.stats});

  final List<DashboardStat> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 36) / 4
            : constraints.maxWidth >= 640
            ? (constraints.maxWidth - 18) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: stats
              .map(
                (stat) => SizedBox(
                  width: cardWidth,
                  child: DashboardStatCard(stat: stat),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _PostStatusRow extends StatelessWidget {
  const _PostStatusRow({required this.posts, required this.now});

  final List<PostEntity> posts;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sections = <PostStatusSection>[
      PostStatusSection(
        title: l10n.dashboardSectionScheduledTodayTitle,
        icon: Icons.today_outlined,
        posts: scheduledToday(posts, now),
        onViewAll: () => context.go(RouteNames.postsListPath),
        emptyMessage: l10n.dashboardSectionScheduledTodayEmpty,
      ),
      PostStatusSection(
        title: l10n.dashboardSectionPublishingQueueTitle,
        icon: Icons.pending_actions_outlined,
        posts: publishingQueue(posts),
        onViewAll: () => context.go(RouteNames.postsListPath),
        emptyMessage: l10n.dashboardSectionPublishingQueueEmpty,
      ),
      PostStatusSection(
        title: l10n.dashboardSectionFailedPostsTitle,
        icon: Icons.report_gmailerrorred_outlined,
        posts: failedPosts(posts),
        onViewAll: () => context.go(RouteNames.postsListPath),
        emptyMessage: l10n.dashboardSectionFailedPostsEmpty,
      ),
      PostStatusSection(
        title: l10n.dashboardSectionLastPublishedTitle,
        icon: Icons.history_outlined,
        posts: lastPublished(posts),
        onViewAll: () => context.go(RouteNames.postsListPath),
        emptyMessage: l10n.dashboardSectionLastPublishedEmpty,
      ),
      PostStatusSection(
        title: l10n.dashboardSectionUpcomingScheduleTitle,
        icon: Icons.upcoming_outlined,
        posts: upcomingSchedule(posts, now),
        onViewAll: () => context.go(RouteNames.calendarPath),
        emptyMessage: l10n.dashboardSectionUpcomingScheduleEmpty,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 3
            : constraints.maxWidth >= 700
            ? 2
            : 1;
        final spacing = 12.0;
        final cardWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: sections
              .map((section) => SizedBox(width: cardWidth, child: section))
              .toList(growable: false),
        );
      },
    );
  }
}
