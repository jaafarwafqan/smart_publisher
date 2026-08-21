import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_curves.dart';
import '../../../../core/theme/app_duration.dart';
import '../../../../shared/widgets/adaptive_content_width.dart';
import '../../../../shared/widgets/app_async_switcher.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  AsyncValue<List<NotificationEntity>> _notifications = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _notifications = const AsyncLoading();
    });

    final result = await ref
        .read(notificationRepositoryProvider)
        .getNotifications();

    if (!mounted) {
      return;
    }

    setState(() {
      _notifications = result.isSuccess
          ? AsyncData(result.data ?? const <NotificationEntity>[])
          : AsyncError(
              StateError(result.message ?? 'Unable to load notifications.'),
              StackTrace.current,
            );
    });
  }

  Future<void> _markRead(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    final fallbackMessage = AppLocalizations.of(
      context,
    )!.notificationsLoadFailed;
    final result = await ref
        .read(notificationRepositoryProvider)
        .markAsRead(id);
    if (!mounted) {
      return;
    }
    if (!result.isSuccess) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? fallbackMessage)),
      );
      return;
    }
    await _loadNotifications();
  }

  Future<void> _markAllRead() async {
    final messenger = ScaffoldMessenger.of(context);
    final fallbackMessage = AppLocalizations.of(
      context,
    )!.notificationsLoadFailed;
    final result = await ref
        .read(notificationRepositoryProvider)
        .markAllAsRead();
    if (!mounted) {
      return;
    }
    if (!result.isSuccess) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? fallbackMessage)),
      );
      return;
    }
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final notifications =
        _notifications.valueOrNull ?? const <NotificationEntity>[];
    final unreadCount = notifications.where((item) => !item.isRead).length;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsAppBarTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.notificationsMarkAllReadTooltip,
            onPressed:
                _notifications is AsyncData<List<NotificationEntity>> &&
                    notifications.isNotEmpty
                ? _markAllRead
                : null,
            icon: const Icon(Icons.done_all),
          ),
        ],
      ),
      body: AdaptiveContentWidth(
        child: RefreshIndicator(
          onRefresh: _loadNotifications,
          // Code-quality review (2026-08-17), item B5/3.1: was a plain
          // `ListView(children: [...])` — every notification tile was
          // built eagerly. See posts_list_screen.dart's own conversion for
          // why a `CustomScrollView`+`SliverList` (not a shrinkWrap-ped
          // nested ListView.builder) is the real fix.
          child: CustomScrollView(
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Card(
                        child: ListTile(
                          title: Text(l10n.notificationsInboxSummaryTitle),
                          subtitle: Text(
                            l10n.notificationsInboxSummarySubtitle(
                              unreadCount,
                              notifications.length,
                            ),
                          ),
                          leading: const Icon(
                            Icons.notifications_active_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
              // Code-quality review (2026-08-17), item B3/4.1: was a
              // hand-rolled loading/error/empty if-chain, one of six
              // screens duplicating the exact shape AppAsyncSwitcher
              // already exists for. Each non-content state is its own
              // sliver (a single switcher can't itself span the content
              // SliverList below, which needs to stay lazily built), same
              // shape as posts_list_screen.dart's own conversion.
              if (_notifications.isLoading)
                SliverToBoxAdapter(
                  child: AppAsyncSwitcher(
                    state: AppAsyncState.loading,
                    loading: const Center(child: CircularProgressIndicator()),
                    error: const SizedBox.shrink(),
                    empty: const SizedBox.shrink(),
                    content: const SizedBox.shrink(),
                  ),
                )
              else if (_notifications.hasError)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: AppAsyncSwitcher(
                      state: AppAsyncState.error,
                      loading: const SizedBox.shrink(),
                      error: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(l10n.notificationsLoadFailed),
                              const SizedBox(height: AppSpacing.md),
                              OutlinedButton.icon(
                                onPressed: _loadNotifications,
                                icon: const Icon(Icons.refresh),
                                label: Text(l10n.commonRetry),
                              ),
                            ],
                          ),
                        ),
                      ),
                      empty: const SizedBox.shrink(),
                      content: const SizedBox.shrink(),
                    ),
                  ),
                )
              else if (notifications.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: AppAsyncSwitcher(
                      state: AppAsyncState.empty,
                      loading: const SizedBox.shrink(),
                      error: const SizedBox.shrink(),
                      empty: AppEmptyState(
                        message: l10n.notificationsEmpty,
                        icon: Icons.notifications_none_outlined,
                      ),
                      content: const SizedBox.shrink(),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _NotificationTile(
                          notification: notifications[index],
                          l10n: l10n,
                          onMarkRead: () => _markRead(notifications[index].id),
                        ),
                      ),
                      childCount: notifications.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.l10n,
    required this.onMarkRead,
  });

  final NotificationEntity notification;
  final AppLocalizations l10n;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    return AnimatedScale(
      scale: isUnread ? 1 : 0.99,
      duration: AppDuration.fast,
      curve: AppCurves.standard,
      child: AnimatedContainer(
        duration: AppDuration.normal,
        curve: AppCurves.standard,
        child: Card(
          color: isUnread
              ? Theme.of(
                  context,
                ).colorScheme.secondaryContainer.withValues(alpha: 0.42)
              : null,
          child: ListTile(
            leading: AnimatedSwitcher(
              duration: AppDuration.fast,
              switchInCurve: AppCurves.standard,
              switchOutCurve: AppCurves.standard,
              child: Icon(
                notification.isRead
                    ? Icons.mark_email_read_outlined
                    : Icons.mark_email_unread_outlined,
                key: ValueKey<bool>(notification.isRead),
              ),
            ),
            title: Text(notification.title),
            subtitle: Text(notification.body),
            trailing: AnimatedSwitcher(
              duration: AppDuration.normal,
              switchInCurve: AppCurves.standard,
              switchOutCurve: AppCurves.standard,
              child: notification.isRead
                  ? const Icon(
                      Icons.check,
                      key: ValueKey<String>('read'),
                      size: 18,
                    )
                  : TextButton(
                      key: const ValueKey<String>('unread'),
                      onPressed: onMarkRead,
                      child: Text(l10n.notificationsMarkReadButton),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
