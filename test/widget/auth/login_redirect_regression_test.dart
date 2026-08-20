import 'dart:async';

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

import '../../helpers/fake_network_client.dart';
import '../../helpers/organization_role_fixtures.dart';

class _EnglishLocaleNotifier extends LocaleNotifier {
  @override
  Locale build() => const Locale('en');
}

/// Regression test for a real, live-reported bug: after a successful
/// login/register, `context.go()` only *starts* GoRouter's async redirect
/// (`RouteGuards.guardPath`, which awaits `currentPlatformAdminProvider`
/// before the route actually changes) — a prior version reset the submit
/// button's loading state unconditionally right after `context.go()`, so
/// during that in-flight window the login screen looked like a fresh, idle
/// form again instead of showing any loading feedback. A live tester read
/// this as "login succeeds in the backend but the UI stays on the login
/// page." `currentPlatformAdminProvider` is held open with a [Completer]
/// here to deterministically reproduce that in-flight window — real
/// network latency (or, before this session's separate fix, the backend
/// bug that made this exact call 500 for any user with an organization)
/// produces the same window in production.
void main() {
  testWidgets(
    'login keeps the submit button loading through an in-flight redirect instead of re-enabling the form early',
    (WidgetTester tester) async {
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
        tokenLifecycleManager: TokenLifecycleManager(
          tokenStorage: tokenStorage,
        ),
        storageService: storage,
        authEventPublisher: AuthEventPublisher(
          app_events.EventDispatcher(EventBus()),
        ),
      );
      final accountRepository = AccountRepositoryImpl();

      // The exact mechanism the reported bug went through: after a
      // successful login, RouteGuards.guardPath awaits this provider before
      // actually navigating to /dashboard. Holding it open here lets the
      // test observe the screen mid-redirect.
      final redirectGate = Completer<bool>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            localeProvider.overrideWith(() => _EnglishLocaleNotifier()),
            storageServiceProvider.overrideWithValue(storage),
            authSessionControllerProvider.overrideWithValue(authController),
            accountRepositoryProvider.overrideWithValue(accountRepository),
            postRepositoryProvider.overrideWithValue(PostRepositoryImpl()),
            analyticsRepositoryProvider.overrideWithValue(
              AnalyticsRepositoryImpl(),
            ),
            notificationRepositoryProvider.overrideWithValue(
              NotificationRepositoryImpl(),
            ),
            currentPlatformAdminProvider.overrideWith(
              (ref) => redirectGate.future,
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

      // The redirect is still pending — the login screen must still be
      // showing, with its submit button still in the loading state, not
      // reverted to a fresh, idle, re-enabled form. This is the exact
      // confusing state the reported bug produced.
      expect(find.text('Smart Publisher Login'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      final button = tester.widget<FilledButton>(
        find.byType(FilledButton).first,
      );
      expect(
        button.onPressed,
        isNull,
        reason:
            'submit button must stay disabled while the redirect is in flight',
      );

      // Now let the redirect actually resolve.
      redirectGate.complete(false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dashboard'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
