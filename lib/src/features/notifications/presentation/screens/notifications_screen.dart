import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_curves.dart';
import '../../../../core/theme/app_duration.dart';
import '../../../../shared/widgets/adaptive_content_width.dart';
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
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
                  leading: const Icon(Icons.notifications_active_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_notifications.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_notifications.hasError)
                Card(
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
                )
              else if (notifications.isEmpty)
                AppEmptyState(
                  message: l10n.notificationsEmpty,
                  icon: Icons.notifications_none_outlined,
                )
              else
                ...notifications.map((notification) {
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
                            ? Theme.of(context).colorScheme.secondaryContainer
                                  .withValues(alpha: 0.42)
                            : null,
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                                    onPressed: () async =>
                                        _markRead(notification.id),
                                    child: Text(
                                      l10n.notificationsMarkReadButton,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
