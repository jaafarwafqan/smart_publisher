import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/di/app_providers.dart';
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
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
            const SizedBox(height: 12),
            if (_notifications.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_notifications.hasError)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(l10n.notificationsLoadFailed),
                      const SizedBox(height: 12),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.notificationsEmpty),
                ),
              )
            else
              ...notifications.map(
                (notification) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(
                      notification.isRead
                          ? Icons.mark_email_read_outlined
                          : Icons.mark_email_unread_outlined,
                    ),
                    title: Text(notification.title),
                    subtitle: Text(notification.body),
                    trailing: notification.isRead
                        ? const Icon(Icons.check, size: 18)
                        : TextButton(
                            onPressed: () async => _markRead(notification.id),
                            child: Text(l10n.notificationsMarkReadButton),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
