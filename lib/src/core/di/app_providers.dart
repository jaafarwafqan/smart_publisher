import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart'
    show BaseOptions, Dio, DioException, RequestOptions;
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../events/event.dart';
import '../events/event_bus.dart';
import '../events/event_dispatcher.dart';
import '../events/logging_event_handler.dart';
import '../locale/locale_provider.dart';
import '../network/dio_network_client.dart';
import '../network/laravel_api.dart';
import '../network/network_client.dart';
import '../network/network_interceptor.dart';
import '../network/web_cookie_adapter.dart';
import '../release/release_config.dart';
import '../router/guard_storage_keys.dart';
import '../router/route_guard_snapshot_cache.dart';
import '../security/oauth_manager.dart';
import '../security/scope_authorizer.dart';
import '../security/secrets_manager.dart';
import '../security/secure_token_storage.dart';
import '../security/token_lifecycle_manager.dart';
import '../security/token_bundle.dart';
import '../security/web_session_config.dart';
import '../storage/storage_provider.dart';
import '../tenancy/active_organization_store.dart';
import '../../backend_contracts/v1/api_envelope_v1.dart';
import '../../backend_contracts/v1/auth_contract_v1.dart';
import '../../features/media/data/media_repository_impl.dart';
import '../../features/media/domain/repositories/media_repository.dart';
import '../../features/analytics/data/repository/analytics_repository_impl.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '../../features/auth/data/account_repository_impl.dart';
import '../../features/auth/application/auth_event_publisher.dart';
import '../../features/auth/application/auth_session_controller.dart';
import '../../features/auth/application/facebook_native_login_service.dart';
import '../../features/auth/application/two_factor_controller.dart';
import '../../features/auth/domain/repositories/account_repository.dart';
import '../../features/administration/data/system_settings_repository_impl.dart';
import '../../features/administration/domain/repositories/system_settings_repository.dart';
import '../../features/ai/data/ai_repository.dart';
import '../../features/notifications/data/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/organizations/data/organization_repository_impl.dart';
import '../../features/organizations/domain/repositories/organization_repository.dart';
import '../../features/posts/data/post_repository_impl.dart';
import '../../features/posts/domain/repositories/post_repository.dart';
import '../../features/posts/domain/usecases/compress_media.dart';
import '../../features/posts/domain/usecases/create_post.dart';
import '../../features/posts/domain/usecases/publish_post.dart';
import '../../features/posts/domain/usecases/schedule_post.dart';
import '../../features/posts/domain/usecases/upload_media.dart';
import '../../features/platform_administration/data/platform_admin_repository.dart';
import '../../features/schedule/data/schedule_repository_impl.dart';
import '../../features/schedule/domain/repositories/schedule_repository.dart';
import '../../offline/cache/draft_storage.dart';
import '../../offline/queue/outbox_store.dart';
import '../../offline/sync/conflict_resolution.dart';
import '../../offline/sync/outbox_sync_handlers.dart';
import '../../offline/sync/resumable_upload_manager.dart';
import '../../offline/sync/sync_worker.dart';

part 'app_providers.g.dart';

final activeOrganizationStoreProvider = Provider<ActiveOrganizationStore>((
  ref,
) {
  return ActiveOrganizationStore(storage: ref.read(storageServiceProvider));
});

@Riverpod(keepAlive: true)
NetworkClient networkClient(NetworkClientRef ref) {
  final releaseConfig = ReleaseConfig.fromEnvironment();
  final dio = Dio(
    BaseOptions(
      baseUrl: LaravelApi.apiBaseUrl,
      headers: <String, Object>{
        'Accept': LaravelApi.acceptHeader(),
        'X-Api-Version': LaravelApi.apiVersionHeaderValue(),
        'X-Release-Channel': releaseConfig.wireValue,
        // Opt in to the httpOnly-cookie transport only in Flutter Web. The
        // backend rejects a cookie unless this header is present, which makes
        // the CORS preflight an additional CSRF barrier.
        if (WebSessionConfig.usesHttpOnlyCookies) 'X-SP-Web-Client': '1',
      },
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  if (WebSessionConfig.usesHttpOnlyCookies) {
    configureBrowserCookieTransport(dio);
  }

  return DioNetworkClient(
    dio: dio,
    interceptors: <NetworkInterceptor>[
      AuthorizationInterceptor(
        tokenLifecycleManager: ref.read(tokenLifecycleManagerProvider),
        scopeAuthorizer: ref.read(scopeAuthorizerProvider),
        requiredScopesResolver: _requiredScopesForPath,
      ),
      OrganizationHeaderInterceptor(
        store: ref.read(activeOrganizationStoreProvider),
      ),
      LocaleHeaderInterceptor(localeReader: () => ref.read(localeProvider)),
      RefreshTokenInterceptor(
        tokenLifecycleManager: ref.read(tokenLifecycleManagerProvider),
      ),
      AuthorizationStateInvalidationInterceptor(
        onForbidden: () {
          ref.read(routeGuardSnapshotCacheProvider).invalidate();
        },
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
    defaultValue: false,
  );

  // Was `if (kIsWeb) return InMemorySecretsManager()` until 2026-08-11: true
  // that web storage can't guarantee hardware-backed protection the way a
  // phone's keystore can, but InMemorySecretsManager doesn't trade that
  // guarantee for a weaker persistent one — it holds the encryption key in
  // a plain in-process Map, gone on any full page reload. secureTokenStorage
  // (EncryptedTokenStorage) still finds its encrypted blob in
  // storageServiceProvider's now-persistent storage after such a reload,
  // but with the key to decrypt it gone, every read fails — the backend
  // then rejects whatever garbage Authorization header results with 401,
  // which is exactly what a real cross-origin OAuth redirect (Facebook
  // consent, then back) reproduced live: the reload past the redirect
  // landed the account "logged in" per local state but 401ing on the very
  // next real request. flutter_secure_storage (PlatformSecureSecretsManager)
  // has supported web all along, backed by the browser's own storage.
  if (kReleaseMode || kIsWeb) {
    return PlatformSecureSecretsManager();
  }

  if (allowInsecureForDebug) {
    return InMemorySecretsManager();
  }
  return PlatformSecureSecretsManager();
}

@Riverpod(keepAlive: true)
SecureTokenStorage secureTokenStorage(SecureTokenStorageRef ref) {
  return EncryptedTokenStorage(
    secretsManager: ref.read(secretsManagerProvider),
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
    onRefreshFailed: () async {
      final storage = ref.read(storageServiceProvider);
      await storage.delete(GuardStorageKeys.authToken);
      await storage.delete(GuardStorageKeys.userRole);
      await storage.delete(GuardStorageKeys.platformAdmin);
    },
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
    localeReader: () => ref.read(localeProvider),
  );
});

final twoFactorControllerProvider = Provider<TwoFactorController>((ref) {
  return TwoFactorController(networkClient: ref.read(networkClientProvider));
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepositoryImpl(networkClient: ref.read(networkClientProvider));
});

final facebookNativeLoginServiceProvider = Provider<FacebookNativeLoginService>(
  (ref) {
    return const FacebookNativeLoginService();
  },
);

final systemSettingsRepositoryProvider = Provider<SystemSettingsRepository>((
  ref,
) {
  return SystemSettingsRepositoryImpl(
    networkClient: ref.read(networkClientProvider),
  );
});

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepositoryImpl(
    networkClient: ref.read(networkClientProvider),
    store: ref.read(activeOrganizationStoreProvider),
  );
});

final platformAdminRepositoryProvider = Provider<PlatformAdminRepository>((
  ref,
) {
  return PlatformAdminRepository(
    networkClient: ref.read(networkClientProvider),
  );
});

@Riverpod(keepAlive: true)
DraftStorage draftStorage(DraftStorageRef ref) {
  return DraftStorage(storage: ref.read(storageServiceProvider));
}

@Riverpod(keepAlive: true)
OutboxStore outboxStore(OutboxStoreRef ref) {
  return OutboxStore(storage: ref.read(storageServiceProvider));
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

/// Reading this provider (once, at app start) is what actually drains the
/// offline outbox: it periodically calls [SyncWorker.runOnce] with real
/// handlers. Without it, SyncWorker exists but is never invoked and queued
/// operations never sync.
final syncSchedulerProvider = Provider<bool>((ref) {
  final syncWorker = ref.read(syncWorkerProvider);
  final handlers = buildOutboxSyncHandlers(
    postRepository: ref.read(postRepositoryProvider),
    mediaRepository: ref.read(mediaRepositoryProvider),
  );

  Future<void> runSync() async {
    try {
      await syncWorker.runOnce(
        handlers,
        currentOrganizationId: () =>
            ref.read(activeOrganizationStoreProvider).read(),
      );
    } catch (_) {
      // Best-effort background sync: per-entry retry/dead-letter handling
      // already happens inside runOnce, so a failure here just means we
      // try again on the next tick.
    }
  }

  unawaited(runSync());
  final timer = Timer.periodic(
    const Duration(seconds: 45),
    (_) => unawaited(runSync()),
  );
  ref.onDispose(timer.cancel);

  return true;
});

@Riverpod(keepAlive: true)
ScheduleRepository scheduleRepository(ScheduleRepositoryRef ref) {
  return ScheduleRepositoryImpl(networkClient: ref.read(networkClientProvider));
}

@Riverpod(keepAlive: true)
PostRepository postRepository(PostRepositoryRef ref) {
  return PostRepositoryImpl(
    networkClient: ref.read(networkClientProvider),
    eventDispatcher: ref.read(eventDispatcherProvider),
    draftStorage: ref.read(draftStorageProvider),
    outboxStore: ref.read(outboxStoreProvider),
    activeOrganizationStore: ref.read(activeOrganizationStoreProvider),
  );
}

@Riverpod(keepAlive: true)
MediaRepository mediaRepository(MediaRepositoryRef ref) {
  return MediaRepositoryImpl(
    networkClient: ref.read(networkClientProvider),
    eventDispatcher: ref.read(eventDispatcherProvider),
    outboxStore: ref.read(outboxStoreProvider),
    resumableUploadManager: ref.read(resumableUploadManagerProvider),
    activeOrganizationStore: ref.read(activeOrganizationStoreProvider),
  );
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl(
    networkClient: ref.read(networkClientProvider),
    storage: ref.read(storageServiceProvider),
  );
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    networkClient: ref.read(networkClientProvider),
  );
});

/// AI traffic still goes through the authenticated, tenant-aware API client;
/// no model provider key or direct model call exists in the Flutter app.
final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(ref.read(networkClientProvider));
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
  return SchedulePost(repository: ref.read(scheduleRepositoryProvider));
}

@Riverpod(keepAlive: true)
UploadMedia uploadMediaUseCase(UploadMediaUseCaseRef ref) {
  return UploadMedia(repository: ref.read(mediaRepositoryProvider));
}

@Riverpod(keepAlive: true)
CompressMedia compressMediaUseCase(CompressMediaUseCaseRef ref) {
  return CompressMedia(repository: ref.read(mediaRepositoryProvider));
}

/// Sprint (Help Center, 2026-08-10): the single place the app name,
/// version, and build number are read from — `AboutSystemScreen` must
/// never hardcode these, since they already live in `pubspec.yaml` at
/// build time and this reads them back at runtime instead of duplicating
/// the value in a second place.
@Riverpod(keepAlive: true)
Future<PackageInfo> packageInfo(PackageInfoRef ref) {
  return PackageInfo.fromPlatform();
}
