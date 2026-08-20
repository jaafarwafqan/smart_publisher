import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/core/events/event_bus.dart';
import 'package:smart_publisher/src/core/events/event_dispatcher.dart'
    as app_events;
import 'package:smart_publisher/src/core/result/app_result.dart';
import 'package:smart_publisher/src/core/router/guard_state_provider.dart';
import 'package:smart_publisher/src/core/security/secure_token_storage.dart';
import 'package:smart_publisher/src/core/security/secrets_manager.dart';
import 'package:smart_publisher/src/core/security/token_lifecycle_manager.dart';
import 'package:smart_publisher/src/core/storage/in_memory_storage_service.dart';
import 'package:smart_publisher/src/features/analytics/data/repository/analytics_repository_impl.dart';
import 'package:smart_publisher/src/features/auth/application/auth_event_publisher.dart';
import 'package:smart_publisher/src/features/auth/application/auth_session_controller.dart';
import 'package:smart_publisher/src/features/auth/data/account_repository_impl.dart';
import 'package:smart_publisher/src/features/auth/domain/entities/user_entity.dart';
import 'package:smart_publisher/src/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:smart_publisher/src/features/notifications/data/notification_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/data/post_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/post_entity.dart';

import '../../helpers/fake_network_client.dart';
import '../../helpers/localized_test_app.dart';

class _RetryingPostRepository extends PostRepositoryImpl {
  int getPostsCalls = 0;

  @override
  Future<AppResult<List<PostEntity>>> getPosts() async {
    getPostsCalls += 1;
    if (getPostsCalls == 1) {
      return const Failure<List<PostEntity>>('Network unavailable');
    }

    return const Success<List<PostEntity>>(<PostEntity>[]);
  }
}

class _AuthenticatedSessionController extends AuthSessionController {
  _AuthenticatedSessionController()
    : super(
        networkClient: FakeNetworkClient(),
        tokenLifecycleManager: TokenLifecycleManager(
          tokenStorage: EncryptedTokenStorage(
            secretsManager: InMemorySecretsManager(),
          ),
        ),
        storageService: InMemoryStorageService(),
        authEventPublisher: AuthEventPublisher(
          app_events.EventDispatcher(EventBus()),
        ),
      );

  @override
  Future<AuthSession?> currentSession() async {
    return const AuthSession(
      user: UserEntity(
        id: 'dashboard-test-user',
        name: 'Dashboard Tester',
        email: 'dashboard@example.com',
      ),
      role: UserRole.publisher,
    );
  }
}

void main() {
  testWidgets(
    'dashboard shows an error and retries instead of rendering failed data as empty',
    (tester) async {
      final posts = _RetryingPostRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            authSessionControllerProvider.overrideWithValue(
              _AuthenticatedSessionController(),
            ),
            postRepositoryProvider.overrideWithValue(posts),
            accountRepositoryProvider.overrideWithValue(
              AccountRepositoryImpl(),
            ),
            analyticsRepositoryProvider.overrideWithValue(
              AnalyticsRepositoryImpl(),
            ),
            notificationRepositoryProvider.overrideWithValue(
              NotificationRepositoryImpl(),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(
          'Dashboard could not be loaded. Check your connection and try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Dashboard Tester'), findsNothing);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(posts.getPostsCalls, 2);
      expect(
        find.text(
          'Dashboard could not be loaded. Check your connection and try again.',
        ),
        findsNothing,
      );
      expect(find.text('Dashboard Tester'), findsOneWidget);
    },
  );
}
