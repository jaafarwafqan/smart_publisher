import '../../../backend_contracts/v1/api_envelope_v1.dart';
import '../../../backend_contracts/v1/notifications_contract_v1.dart';
import '../../../core/network/laravel_api.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/app_result.dart';
import '../domain/entities/notification_entity.dart';
import '../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl extends NotificationRepository {
  NotificationRepositoryImpl({this.networkClient});

  final NetworkClient? networkClient;
  final Map<String, NotificationEntity> _local = <String, NotificationEntity>{};

  @override
  Future<AppResult<List<NotificationEntity>>> getNotifications() async {
    if (networkClient != null) {
      return executeList(
        () async {
          final response = await networkClient!.get(
            LaravelEndpoints.notifications,
          );
          final payload = _unwrapPayload(response.data);
          final rawItems = payload is List<dynamic> ? payload : <dynamic>[];

          final items = rawItems
              .whereType<Map<String, dynamic>>()
              .map(_fromDto)
              .toList(growable: false);

          for (final item in items) {
            _local[item.id] = item;
          }

          return _sortedLocal();
        },
        operation: 'notifications.list.remote',
        fallbackMessage: 'Failed to load notifications',
      );
    }

    return executeList(
      () async {
        if (_local.isEmpty) {
          _seedLocalDefaults();
        }
        return _sortedLocal();
      },
      operation: 'notifications.list.local',
      fallbackMessage: 'Failed to load local notifications',
    );
  }

  @override
  Future<AppResult<void>> markAsRead(String id) async {
    if (networkClient != null) {
      return execute(
        () async {
          await networkClient!.patch(
            LaravelEndpoints.notificationById(id),
            data: <String, dynamic>{'is_read': true},
          );
          final existing = _local[id];
          if (existing != null) {
            _local[id] = NotificationEntity(
              id: existing.id,
              title: existing.title,
              body: existing.body,
              isRead: true,
            );
          }
        },
        operation: 'notifications.mark_read.remote',
        fallbackMessage: 'Failed to mark notification as read',
      );
    }

    return execute(
      () async {
        final existing = _local[id];
        if (existing == null) {
          return;
        }
        _local[id] = NotificationEntity(
          id: existing.id,
          title: existing.title,
          body: existing.body,
          isRead: true,
        );
      },
      operation: 'notifications.mark_read.local',
      fallbackMessage: 'Failed to mark local notification as read',
    );
  }

  @override
  Future<AppResult<void>> markAllAsRead() async {
    if (networkClient != null) {
      return execute(
        () async {
          await networkClient!.post(
            '${LaravelEndpoints.notifications}/mark-all-read',
            data: const <String, dynamic>{},
          );
          for (final entry in _local.entries.toList(growable: false)) {
            _local[entry.key] = NotificationEntity(
              id: entry.value.id,
              title: entry.value.title,
              body: entry.value.body,
              isRead: true,
            );
          }
        },
        operation: 'notifications.mark_all.remote',
        fallbackMessage: 'Failed to mark all notifications as read',
      );
    }

    return execute(
      () async {
        for (final entry in _local.entries.toList(growable: false)) {
          _local[entry.key] = NotificationEntity(
            id: entry.value.id,
            title: entry.value.title,
            body: entry.value.body,
            isRead: true,
          );
        }
      },
      operation: 'notifications.mark_all.local',
      fallbackMessage: 'Failed to mark all local notifications as read',
    );
  }

  NotificationEntity _fromDto(Map<String, dynamic> json) {
    final dto = NotificationResponseDtoV1.fromJson(json);
    return NotificationEntity(
      id: dto.id,
      title: dto.title,
      body: dto.body,
      isRead: dto.isRead,
    );
  }

  dynamic _unwrapPayload(dynamic raw) {
    if (raw is Map<String, dynamic> && raw.containsKey('success')) {
      return ApiEnvelopeV1.fromJson(raw).data;
    }
    return raw;
  }

  List<NotificationEntity> _sortedLocal() {
    final items = _local.values.toList(growable: false);
    items.sort((a, b) => b.id.compareTo(a.id));
    return items;
  }

  void _seedLocalDefaults() {
    final defaults = <NotificationEntity>[
      const NotificationEntity(
        id: 'local-1',
        title: 'Welcome to Notifications',
        body: 'Publishing alerts and job updates will appear here.',
      ),
      const NotificationEntity(
        id: 'local-2',
        title: 'Queue Health Stable',
        body: 'Background publish queue is operating normally.',
      ),
    ];

    for (final item in defaults) {
      _local[item.id] = item;
    }
  }
}
