import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<NotificationEntity> _notifications = const <NotificationEntity>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
    });

    final result = await ref
        .read(notificationRepositoryProvider)
        .getNotifications();
    final notifications = result.data ?? const <NotificationEntity>[];

    if (!mounted) {
      return;
    }

    setState(() {
      _notifications = notifications;
      _loading = false;
    });
  }

  Future<void> _markRead(String id) async {
    final result = await ref
        .read(notificationRepositoryProvider)
        .markAsRead(id);
    if (!result.isSuccess || !mounted) {
      return;
    }
    await _loadNotifications();
  }

  Future<void> _markAllRead() async {
    final result = await ref
        .read(notificationRepositoryProvider)
        .markAllAsRead();
    if (!result.isSuccess || !mounted) {
      return;
    }
    await _loadNotifications();
  }

  void _clearRead() {
    setState(() {
      _notifications = _notifications
          .where((item) => !item.isRead)
          .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((item) => !item.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Mark all as read',
            onPressed: _notifications.isEmpty ? null : _markAllRead,
            icon: const Icon(Icons.done_all),
          ),
          IconButton(
            tooltip: 'Clear read',
            onPressed: _notifications.isEmpty ? null : _clearRead,
            icon: const Icon(Icons.cleaning_services_outlined),
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
                title: const Text('Inbox Summary'),
                subtitle: Text(
                  'Unread: $unreadCount • Total: ${_notifications.length}',
                ),
                leading: const Icon(Icons.notifications_active_outlined),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_notifications.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No notifications available.'),
                ),
              )
            else
              ..._notifications.map(
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
                            child: const Text('Mark read'),
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
