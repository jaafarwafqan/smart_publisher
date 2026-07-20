import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart'
    show BaseOptions, Dio, DioException, RequestOptions;
import 'package:flutter/foundation.dart';

import '../events/event.dart';
import '../events/event_bus.dart';
import '../events/event_dispatcher.dart';
import '../events/logging_event_handler.dart';
import '../network/dio_network_client.dart';
import '../network/laravel_api.dart';
import '../network/network_client.dart';
import '../network/network_interceptor.dart';
import '../release/release_config.dart';
import '../security/encryption_service.dart';
import '../security/oauth_manager.dart';
import '../security/scope_authorizer.dart';
import '../security/secrets_manager.dart';
import '../security/secure_token_storage.dart';
import '../security/token_lifecycle_manager.dart';
import '../security/token_bundle.dart';
import '../storage/storage_provider.dart';
import '../../backend_contracts/v1/api_envelope_v1.dart';
import '../../backend_contracts/v1/auth_contract_v1.dart';
import '../../features/media/data/media_repository_impl.dart';
import '../../features/media/domain/repositories/media_repository.dart';
import '../../features/analytics/data/repository/analytics_repository_impl.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '../../features/auth/data/account_repository_impl.dart';
import '../../features/auth/application/auth_event_publisher.dart';
import '../../features/auth/application/auth_session_controller.dart';
import '../../features/auth/domain/repositories/account_repository.dart';
import '../../features/notifications/data/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/posts/data/post_repository_impl.dart';
import '../../features/posts/domain/repositories/post_repository.dart';
import '../../features/posts/domain/usecases/compress_media.dart';
import '../../features/posts/domain/usecases/create_post.dart';
import '../../features/posts/domain/usecases/publish_post.dart';
import '../../features/posts/domain/usecases/schedule_post.dart';
import '../../features/posts/domain/usecases/upload_media.dart';
import '../../offline/cache/draft_storage.dart';
import '../../offline/queue/outbox_store.dart';
import '../../offline/sync/conflict_resolution.dart';
import '../../offline/sync/resumable_upload_manager.dart';
import '../../offline/sync/sync_worker.dart';
import '../../platforms/core/platform_factory.dart';
import '../../publish_engine/engine/publish_engine.dart';

part 'app_providers.g.dart';

@Riverpod(keepAlive: true)
NetworkClient networkClient(NetworkClientRef ref) {
  final releaseConfig = ReleaseConfig.fromEnvironment();
  return DioNetworkClient(
    dio: Dio(
      BaseOptions(
        baseUrl: LaravelApi.apiBaseUrl,
        headers: <String, Object>{
          'Accept': LaravelApi.acceptHeader(),
          'X-Api-Version': LaravelApi.apiVersionHeaderValue(),
          'X-Release-Channel': releaseConfig.channel.name,
          'X-Canary-Percent': releaseConfig.canaryPercent,
        },
      ),
    ),
    interceptors: <NetworkInterceptor>[
      AuthorizationInterceptor(
        tokenLifecycleManager: ref.read(tokenLifecycleManagerProvider),
        scopeAuthorizer: ref.read(scopeAuthorizerProvider),
        requiredScopesResolver: _requiredScopesForPath,
      ),
      RefreshTokenInterceptor(
        tokenLifecycleManager: ref.read(tokenLifecycleManagerProvider),
      ),
      RateLimiterInterceptor(),
      const RetryInterceptor(),
      const LoggingInterceptor(),
    ],
  );
}

Set<String> _requiredScopesForPath(RequestOptions options) {
  final path = options.path.toLowerCase();
  if (path.contains('/publish')) {
    return const <String>{'publish.write'};
  }
  if (path.contains('/analytics')) {
    return const <String>{'posts.read'};
  }
  if (path.contains('/notifications')) {
    return const <String>{'posts.read'};
  }
  if (path.contains('/media')) {
    return const <String>{'media.write'};
  }
  if (path.contains('/posts')) {
    if (options.method.toUpperCase() == 'GET') {
      return const <String>{'posts.read'};
    }
    return const <String>{'posts.write'};
  }
  return const <String>{};
}

@Riverpod(keepAlive: true)
SecretsManager secretsManager(SecretsManagerRef ref) {
  const allowInsecureForDebug = bool.fromEnvironment(
    'SP_ALLOW_INSECURE_SECRETS_IN_DEBUG',
    defaultValue: true,
  );

  if (kIsWeb) {
    // Web storage cannot guarantee hardware-backed secret protection.
    return InMemorySecretsManager();
  }

  if (kReleaseMode) {
    return PlatformSecureSecretsManager();
  }

  if (allowInsecureForDebug) {
    return InMemorySecretsManager();
  }
  return PlatformSecureSecretsManager();
}

@Riverpod(keepAlive: true)
EncryptionService encryptionService(EncryptionServiceRef ref) {
  return const DefaultEncryptionService();
}

@Riverpod(keepAlive: true)
SecureTokenStorage secureTokenStorage(SecureTokenStorageRef ref) {
  return EncryptedTokenStorage(
    secretsManager: ref.read(secretsManagerProvider),
    encryptionService: ref.read(encryptionServiceProvider),
  );
}

@Riverpod(keepAlive: true)
OAuthManager oauthManager(OauthManagerRef ref) {
  return OAuthManager(
    OAuthConfiguration(
      clientId: 'smart-publisher-mobile',
      authorizationEndpoint: Uri.parse(
        '${LaravelApi.oauthBaseUrl}/oauth/authorize',
      ),
      tokenEndpoint: Uri.parse('${LaravelApi.oauthBaseUrl}/oauth/token'),
      redirectUri: Uri.parse('smartpublisher://oauth/callback'),
      defaultScopes: const <String>{
        'posts.read',
        'posts.write',
        'media.write',
        'publish.write',
      },
    ),
  );
}

@Riverpod(keepAlive: true)
ScopeAuthorizer scopeAuthorizer(ScopeAuthorizerRef ref) {
  return const ScopeAuthorizer();
}

@Riverpod(keepAlive: true)
TokenLifecycleManager tokenLifecycleManager(TokenLifecycleManagerRef ref) {
  return TokenLifecycleManager(
    tokenStorage: ref.read(secureTokenStorageProvider),
    refreshExecutor: (refreshToken) async {
      try {
        final response = await Dio().post<dynamic>(
          '${LaravelApi.authBaseUrl}${LaravelEndpoints.authRefresh}',
          data: <String, dynamic>{'refresh_token': refreshToken},
        );
        final raw = response.data;
        if (raw is! Map<String, dynamic>) {
          return null;
        }
        final payload = raw.containsKey('success')
            ? ApiEnvelopeV1.fromJson(raw).data
            : raw['data'];
        if (payload is! Map<String, dynamic>) {
          return null;
        }
        final dto = RefreshTokenResponseDtoV1.fromJson(payload);
        if (dto.accessToken.isEmpty) {
          return null;
        }
        final rotatedRefresh = dto.refreshToken ?? refreshToken;
        final scopes = (dto.scope
            .split(' ')
            .where((scope) => scope.trim().isNotEmpty)
            .toSet());
        return TokenBundle(
          accessToken: dto.accessToken,
          refreshToken: rotatedRefresh,
          expiresAt: DateTime.now().add(Duration(seconds: dto.expiresIn)),
          scopes: scopes,
        );
      } on DioException {
        return null;
      }
    },
  );
}

@Riverpod(keepAlive: true)
EventBus eventBus(EventBusRef ref) {
  final bus = EventBus();
  bus.register<AppEvent>(const LoggingEventHandler());
  return bus;
}

@Riverpod(keepAlive: true)
EventDispatcher eventDispatcher(EventDispatcherRef ref) {
  return EventDispatcher(ref.read(eventBusProvider));
}

@Riverpod(keepAlive: true)
AuthEventPublisher authEventPublisher(AuthEventPublisherRef ref) {
  return AuthEventPublisher(ref.read(eventDispatcherProvider));
}

final authSessionControllerProvider = Provider<AuthSessionController>((ref) {
  return AuthSessionController(
    networkClient: ref.read(networkClientProvider),
    tokenLifecycleManager: ref.read(tokenLifecycleManagerProvider),
    storageService: ref.read(storageServiceProvider),
    authEventPublisher: ref.read(authEventPublisherProvider),
  );
});

final platformFactoryProvider = Provider<PlatformFactory>((ref) {
  return PlatformFactory();
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepositoryImpl(
    networkClient: ref.read(networkClientProvider),
    platformFactory: ref.read(platformFactoryProvider),
  );
});

@Riverpod(keepAlive: true)
PublishEngine publishEngine(PublishEngineRef ref) {
  return PublishEngine(eventDispatcher: ref.read(eventDispatcherProvider));
}

@Riverpod(keepAlive: true)
DraftStorage draftStorage(DraftStorageRef ref) {
  return DraftStorage();
}

@Riverpod(keepAlive: true)
OutboxStore outboxStore(OutboxStoreRef ref) {
  return OutboxStore();
}

@Riverpod(keepAlive: true)
ResumableUploadManager resumableUploadManager(ResumableUploadManagerRef ref) {
  return ResumableUploadManager();
}

@Riverpod(keepAlive: true)
SyncWorker syncWorker(SyncWorkerRef ref) {
  return SyncWorker(
    outboxStore: ref.read(outboxStoreProvider),
    conflictResolver: const ConflictResolver(),
  );
}

@Riverpod(keepAlive: true)
PostRepository postRepository(PostRepositoryRef ref) {
  return PostRepositoryImpl(
    networkClient: ref.read(networkClientProvider),
    eventDispatcher: ref.read(eventDispatcherProvider),
    draftStorage: ref.read(draftStorageProvider),
    outboxStore: ref.read(outboxStoreProvider),
  );
}

@Riverpod(keepAlive: true)
MediaRepository mediaRepository(MediaRepositoryRef ref) {
  return MediaRepositoryImpl(
    networkClient: ref.read(networkClientProvider),
    eventDispatcher: ref.read(eventDispatcherProvider),
    outboxStore: ref.read(outboxStoreProvider),
    resumableUploadManager: ref.read(resumableUploadManagerProvider),
  );
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl(
    networkClient: ref.read(networkClientProvider),
  );
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    networkClient: ref.read(networkClientProvider),
  );
});

@Riverpod(keepAlive: true)
CreatePost createPostUseCase(CreatePostUseCaseRef ref) {
  return CreatePost(repository: ref.read(postRepositoryProvider));
}

@Riverpod(keepAlive: true)
PublishPost publishPostUseCase(PublishPostUseCaseRef ref) {
  return PublishPost(repository: ref.read(postRepositoryProvider));
}

@Riverpod(keepAlive: true)
SchedulePost schedulePostUseCase(SchedulePostUseCaseRef ref) {
  return SchedulePost(repository: ref.read(postRepositoryProvider));
}

@Riverpod(keepAlive: true)
UploadMedia uploadMediaUseCase(UploadMediaUseCaseRef ref) {
  return UploadMedia(repository: ref.read(mediaRepositoryProvider));
}

@Riverpod(keepAlive: true)
CompressMedia compressMediaUseCase(CompressMediaUseCaseRef ref) {
  return CompressMedia(repository: ref.read(mediaRepositoryProvider));
}
