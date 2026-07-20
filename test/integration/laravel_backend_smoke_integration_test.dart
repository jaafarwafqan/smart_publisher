import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/events/event_bus.dart';
import 'package:smart_publisher/src/core/events/event_dispatcher.dart'
    as app_events;
import 'package:smart_publisher/src/core/network/dio_network_client.dart';
import 'package:smart_publisher/src/core/network/laravel_api.dart';
import 'package:smart_publisher/src/core/network/network_client.dart';
import 'package:smart_publisher/src/core/security/encryption_service.dart';
import 'package:smart_publisher/src/core/security/secrets_manager.dart';
import 'package:smart_publisher/src/core/security/secure_token_storage.dart';
import 'package:smart_publisher/src/core/security/token_lifecycle_manager.dart';
import 'package:smart_publisher/src/core/storage/in_memory_storage_service.dart';
import 'package:smart_publisher/src/features/analytics/data/repository/analytics_repository_impl.dart';
import 'package:smart_publisher/src/features/auth/application/auth_event_publisher.dart';
import 'package:smart_publisher/src/features/auth/application/auth_session_controller.dart';
import 'package:smart_publisher/src/features/media/data/media_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/data/post_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/media_entity.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/post_entity.dart';
import 'package:smart_publisher/src/features/posts/domain/usecases/create_post.dart';
import 'package:smart_publisher/src/features/posts/domain/usecases/schedule_post.dart';

void main() {
  const runSmoke = bool.fromEnvironment(
    'SP_RUN_LARAVEL_SMOKE',
    defaultValue: false,
  );
  const smokeEmail = String.fromEnvironment('SP_SMOKE_EMAIL');
  const smokePassword = String.fromEnvironment('SP_SMOKE_PASSWORD');

  group('Integration - Laravel Backend Smoke', () {
    test('login/create/upload draft/schedule/analytics', () async {
      if (!runSmoke) {
        // Enabled only in environments with a running Laravel backend.
        return;
      }
      if (smokeEmail.trim().isEmpty || smokePassword.trim().isEmpty) {
        fail(
          'Missing SP_SMOKE_EMAIL or SP_SMOKE_PASSWORD for Laravel smoke run.',
        );
      }

      final networkClient = _buildNetworkClient();
      final storage = InMemoryStorageService();
      final tokenStorage = EncryptedTokenStorage(
        secretsManager: InMemorySecretsManager(),
        encryptionService: const DefaultEncryptionService(),
      );
      final authController = AuthSessionController(
        networkClient: networkClient,
        tokenLifecycleManager: TokenLifecycleManager(
          tokenStorage: tokenStorage,
        ),
        storageService: storage,
        authEventPublisher: AuthEventPublisher(
          app_events.EventDispatcher(EventBus()),
        ),
      );

      final session = await authController.login(
        email: smokeEmail,
        password: smokePassword,
      );
      expect(session.user.email, isNotEmpty);

      final postRepository = PostRepositoryImpl(networkClient: networkClient);
      final mediaRepository = MediaRepositoryImpl(networkClient: networkClient);
      final analyticsRepository = AnalyticsRepositoryImpl(
        networkClient: networkClient,
      );
      final createPost = CreatePost(repository: postRepository);
      final schedulePost = SchedulePost(repository: postRepository);

      final created = await createPost(
        PostEntity(
          id: 'smoke-${DateTime.now().microsecondsSinceEpoch}',
          title: 'Smoke Post ${DateTime.now().toIso8601String()}',
          body: 'Smoke flow through Laravel backend integration.',
          status: 'draft',
          platforms: const <String>['facebook'],
        ),
      );
      expect(created.isSuccess, isTrue, reason: created.message);
      final createdPost = created.data;
      expect(createdPost, isNotNull);

      final imageFile = await _createSmokePng();
      final uploadResult = await mediaRepository.uploadMedia(
        MediaEntity(
          id: 'smoke-media-${DateTime.now().microsecondsSinceEpoch}',
          postId: createdPost!.id,
          url: imageFile.path,
          mimeType: 'image/png',
          sizeInBytes: await imageFile.length(),
        ),
      );
      expect(uploadResult.isSuccess, isTrue, reason: uploadResult.message);

      final scheduled = await schedulePost(
        createdPost.copyWith(
          status: 'scheduled',
          scheduledAt: DateTime.now().add(const Duration(hours: 2)),
        ),
      );
      expect(scheduled.isSuccess, isTrue, reason: scheduled.message);

      final analytics = await analyticsRepository.getPostMetrics(
        createdPost.id,
      );
      expect(analytics.isSuccess, isTrue, reason: analytics.message);
      expect(analytics.data, isNotNull);

      await imageFile.delete();
    });
  });
}

NetworkClient _buildNetworkClient() {
  return DioNetworkClient(
    dio: Dio(
      BaseOptions(
        baseUrl: LaravelApi.apiBaseUrl,
        headers: <String, Object>{
          'Accept': LaravelApi.acceptHeader(),
          'X-Api-Version': LaravelApi.apiVersionHeaderValue(),
        },
      ),
    ),
  );
}

Future<File> _createSmokePng() async {
  final tempDir = await Directory.systemTemp.createTemp('sp_smoke_media');
  final file = File('${tempDir.path}/smoke.png');
  // Minimal PNG bytes header payload.
  final bytes = <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ];
  await file.writeAsBytes(bytes, flush: true);
  return file;
}
