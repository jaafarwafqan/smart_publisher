import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/core/events/event_bus.dart';
import 'package:smart_publisher/src/core/events/event_dispatcher.dart'
    as app_events;
import 'package:smart_publisher/src/core/router/guard_state_provider.dart';
import 'package:smart_publisher/src/core/security/encryption_service.dart';
import 'package:smart_publisher/src/core/security/secure_token_storage.dart';
import 'package:smart_publisher/src/core/security/secrets_manager.dart';
import 'package:smart_publisher/src/core/security/token_lifecycle_manager.dart';
import 'package:smart_publisher/src/core/storage/in_memory_storage_service.dart';
import 'package:smart_publisher/src/features/auth/application/auth_event_publisher.dart';
import 'package:smart_publisher/src/features/auth/application/auth_session_controller.dart';
import 'package:smart_publisher/src/features/auth/domain/entities/user_entity.dart';
import 'package:smart_publisher/src/features/organizations/application/current_organization_access.dart';
import 'package:smart_publisher/src/features/organizations/presentation/screens/organization_switcher_screen.dart';

import '../../helpers/fake_network_client.dart';
import '../../helpers/localized_test_app.dart';

// Sprint (2026-08-11): same fake-subclass pattern already established in
// dashboard_screen_state_test.dart's _AuthenticatedSessionController —
// currentSession() reads local storage only, so a real base-class instance
// wired to in-memory fakes is simplest, with currentSession() overridden
// directly to skip the storage round trip.
class _TestSessionController extends AuthSessionController {
  _TestSessionController()
    : super(
        networkClient: FakeNetworkClient(),
        tokenLifecycleManager: TokenLifecycleManager(
          tokenStorage: EncryptedTokenStorage(
            secretsManager: InMemorySecretsManager(),
            encryptionService: const DefaultEncryptionService(),
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
        id: 'switcher-test-user',
        name: 'New User',
        email: 'new-user@example.com',
      ),
      role: UserRole.publisher,
    );
  }
}

Future<void> _pumpSwitcher(
  WidgetTester tester,
  Future<OrganizationAccessState> Function() loadAccess,
) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        currentOrganizationAccessProvider.overrideWith((_) => loadAccess()),
        authSessionControllerProvider.overrideWithValue(
          _TestSessionController(),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: OrganizationSwitcherScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('shows a distinct empty state when the user has no memberships', (
    tester,
  ) async {
    await _pumpSwitcher(
      tester,
      () async =>
          OrganizationAccessState.noActiveOrganization(memberships: const []),
    );
    await tester.pumpAndSettle();

    expect(find.text('No organization yet'), findsOneWidget);
    expect(find.text('Account security'), findsOneWidget);
    // A user parked here (no organization yet) must still be able to leave
    // the session — see Sprint A's docblock on _logout().
    expect(find.byIcon(Icons.logout), findsOneWidget);

    // Regression coverage for the 2026-08-11 report: a freshly registered
    // account saw a bare "no organization" state with nothing recognizing
    // the account that was just created — the welcome header must greet
    // this specific signed-in user, not a generic placeholder.
    expect(find.text('Welcome, New User'), findsOneWidget);
    expect(find.text('new-user@example.com'), findsOneWidget);
  });

  testWidgets('shows the membership error and a retry action', (tester) async {
    await _pumpSwitcher(
      tester,
      () async => throw const OrganizationAccessException(
        'Membership service unavailable.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Membership service unavailable.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('keeps an explicit loading indicator until memberships resolve', (
    tester,
  ) async {
    final response = Completer<OrganizationAccessState>();
    await _pumpSwitcher(tester, () => response.future);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    response.complete(
      OrganizationAccessState.noActiveOrganization(memberships: const []),
    );
    await tester.pumpAndSettle();
    expect(find.text('No organization yet'), findsOneWidget);
    expect(find.text('Account security'), findsOneWidget);
  });
}
