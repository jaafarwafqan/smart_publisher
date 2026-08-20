import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/app/app.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/core/events/event_bus.dart';
import 'package:smart_publisher/src/core/events/event_dispatcher.dart'
    as app_events;
import 'package:smart_publisher/src/core/locale/locale_provider.dart';
import 'package:smart_publisher/src/core/router/guard_state_provider.dart';
import 'package:smart_publisher/src/core/security/secure_token_storage.dart';
import 'package:smart_publisher/src/core/security/secrets_manager.dart';
import 'package:smart_publisher/src/core/security/token_lifecycle_manager.dart';
import 'package:smart_publisher/src/core/storage/in_memory_storage_service.dart';
import 'package:smart_publisher/src/core/storage/storage_provider.dart';
import 'package:smart_publisher/src/features/analytics/data/repository/analytics_repository_impl.dart';
import 'package:smart_publisher/src/features/auth/application/auth_event_publisher.dart';
import 'package:smart_publisher/src/features/auth/application/auth_session_controller.dart';
import 'package:smart_publisher/src/features/auth/data/account_repository_impl.dart';
import 'package:smart_publisher/src/features/notifications/data/notification_repository_impl.dart';
import 'package:smart_publisher/src/features/organizations/application/current_organization_access.dart';
import 'package:smart_publisher/src/features/organizations/domain/entities/organization_entity.dart';
import 'package:smart_publisher/src/features/posts/data/post_repository_impl.dart';

import 'helpers/fake_network_client.dart';
import 'helpers/organization_role_fixtures.dart';

class _EnglishLocaleNotifier extends LocaleNotifier {
  @override
  Locale build() => const Locale('en');
}

void main() {
  testWidgets('Splash redirects to login then login navigates to dashboard', (
    WidgetTester tester,
  ) async {
    final storage = InMemoryStorageService();
    final tokenStorage = EncryptedTokenStorage(
      secretsManager: InMemorySecretsManager(),
    );
    final networkClient = FakeNetworkClient(
      postHandler: (path, data) async {
        return Response<dynamic>(
          requestOptions: RequestOptions(path: path),
          statusCode: 200,
          data: <String, dynamic>{
            'success': true,
            'data': <String, dynamic>{
              'access_token': 'access-1',
              'refresh_token': 'refresh-1',
              'expires_in': 3600,
              'scope': 'posts.read posts.write',
              'user': <String, dynamic>{
                'id': 'user-1',
                'name': 'Jane Doe',
                'email': 'jane@example.com',
                'role': 'publisher',
              },
            },
          },
        );
      },
    );
    final authController = AuthSessionController(
      networkClient: networkClient,
      tokenLifecycleManager: TokenLifecycleManager(tokenStorage: tokenStorage),
      storageService: storage,
      authEventPublisher: AuthEventPublisher(
        app_events.EventDispatcher(EventBus()),
      ),
    );
    final accountRepository = AccountRepositoryImpl();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          // This is a golden-path smoke test asserting on literal English
          // copy across many screens — pinning the locale here keeps it
          // stable as screens get translated to Arabic (the app's real
          // default), rather than needing every assertion below rewritten
          // in lockstep with each screen's translation.
          localeProvider.overrideWith(() => _EnglishLocaleNotifier()),
          storageServiceProvider.overrideWithValue(storage),
          authSessionControllerProvider.overrideWithValue(authController),
          accountRepositoryProvider.overrideWithValue(accountRepository),
          // The Dashboard also loads posts/analytics/notifications now — no
          // network client means each falls back to its local/empty-data
          // path instead of hitting a real (absent, in this test) server.
          postRepositoryProvider.overrideWithValue(PostRepositoryImpl()),
          analyticsRepositoryProvider.overrideWithValue(
            AnalyticsRepositoryImpl(),
          ),
          notificationRepositoryProvider.overrideWithValue(
            NotificationRepositoryImpl(),
          ),
          currentOrganizationAccessProvider.overrideWith((_) async {
            final currentOrganization = OrganizationEntity(
              id: 1,
              name: 'Jane Doe Organization',
              slug: 'jane-doe-organization',
              role: 'owner',
              isCurrent: true,
              permissions: permissionsForRole('owner'),
            );
            return OrganizationAccessState.active(
              memberships: <OrganizationEntity>[currentOrganization],
              currentOrganization: currentOrganization,
            );
          }),
        ],
        child: const SmartPublisherApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Smart Publisher Login'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'jane@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == 'jane@example.com',
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text(
        'Manage Facebook, Instagram, Telegram, WhatsApp, LinkedIn, and X accounts.',
      ),
      300,
      scrollable: find.byType(Scrollable).last,
    );

    expect(
      find.text(
        'Manage Facebook, Instagram, Telegram, WhatsApp, LinkedIn, and X accounts.',
      ),
      findsOneWidget,
    );
    expect(find.text('Facebook'), findsWidgets);
    expect(find.text('Instagram'), findsWidgets);
    expect(find.text('Telegram'), findsWidgets);
    expect(find.text('WhatsApp'), findsWidgets);
    expect(find.text('LinkedIn'), findsWidgets);
    expect(find.text('X'), findsWidgets);
    expect(await storage.readString(GuardStorageKeys.authToken), 'access-1');
  });
}
