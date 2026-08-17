import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';
import '../../../core/result/app_result.dart';
import '../../analytics/domain/entities/analytics_summary_entity.dart';
import '../../auth/application/auth_session_controller.dart';
import '../../auth/domain/entities/account_entity.dart';
import '../../notifications/domain/entities/notification_entity.dart';
import '../../posts/domain/entities/post_entity.dart';

class DashboardData {
  const DashboardData({
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

/// Code-quality review (2026-08-17), item B1/2.2: same `keepAlive` +
/// explicit-refresh-only pattern as [PostsListNotifier]/
/// [AnalyticsDashboardNotifier] — see those classes' docblocks. This one
/// holds only the four data collections the dashboard screen renders
/// (posts/accounts/summary/notifications); the auth session future and the
/// Facebook/WhatsApp/X OAuth-redirect-completion flow stay screen-local in
/// DashboardScreen — they're genuinely per-screen-instance lifecycle
/// concerns (a redirect landing must be consumed exactly once per mount),
/// not cached cross-navigation data in the sense this refactor targets.
class DashboardDataNotifier extends AsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() => _load();

  Future<DashboardData> _load() async {
    final session = await ref
        .read(authSessionControllerProvider)
        .currentSession();
    if (session == null) {
      throw StateError('No authenticated session is available.');
    }

    final results = await Future.wait<Object>(<Future<Object>>[
      _loadPosts(),
      _loadAccounts(session.user.id),
      _loadSummary(),
      _loadNotifications(),
    ]);

    return DashboardData(
      session: session,
      posts: results[0] as List<PostEntity>,
      accounts: results[1] as List<AccountEntity>,
      summary: results[2] as AnalyticsSummaryEntity,
      notifications: results[3] as List<NotificationEntity>,
    );
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

  T _requireData<T>(AppResult<T> result, String fallbackMessage) {
    final data = result.data;
    if (!result.isSuccess || data == null) {
      throw StateError(result.message ?? fallbackMessage);
    }

    return data;
  }

  /// Called after every mutation that changes what the dashboard shows
  /// (account connect/disconnect, page sync, post changes elsewhere,
  /// etc.) — same explicit-trigger role `_refreshDashboard()` played
  /// locally before this refactor, just now backed by the shared provider
  /// so every screen watching it (not just this one instance) sees the
  /// update.
  Future<void> refresh() async {
    state = const AsyncValue<DashboardData>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(_load);
  }
}

final dashboardDataProvider =
    AsyncNotifierProvider<DashboardDataNotifier, DashboardData>(
      DashboardDataNotifier.new,
    );
