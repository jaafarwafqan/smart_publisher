import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/core/events/event_bus.dart';
import 'package:smart_publisher/src/core/events/event_dispatcher.dart'
    as app_events;
import 'package:smart_publisher/src/core/router/guard_state_provider.dart';
import 'package:smart_publisher/src/core/security/encryption_service.dart';
import 'package:smart_publisher/src/core/security/secrets_manager.dart';
import 'package:smart_publisher/src/core/security/secure_token_storage.dart';
import 'package:smart_publisher/src/core/security/token_lifecycle_manager.dart';
import 'package:smart_publisher/src/core/storage/in_memory_storage_service.dart';
import 'package:smart_publisher/src/features/analytics/data/repository/analytics_repository_impl.dart';
import 'package:smart_publisher/src/features/auth/application/auth_event_publisher.dart';
import 'package:smart_publisher/src/features/auth/application/auth_session_controller.dart';
import 'package:smart_publisher/src/features/auth/data/account_repository_impl.dart';
import 'package:smart_publisher/src/features/auth/domain/entities/user_entity.dart';
import 'package:smart_publisher/src/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:smart_publisher/src/features/notifications/data/notification_repository_impl.dart';
import 'package:smart_publisher/src/features/organizations/application/current_organization_access.dart';
import 'package:smart_publisher/src/features/organizations/domain/entities/organization_entity.dart';
import 'package:smart_publisher/src/features/posts/data/post_repository_impl.dart';
import 'package:smart_publisher/src/platforms/core/platform_factory.dart';

import '../../helpers/fake_network_client.dart';
import '../../helpers/localized_test_app.dart';

class _FakeSessionController extends AuthSessionController {
  _FakeSessionController()
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
        id: 'role-badge-test-user',
        name: 'Role Badge Tester',
        email: 'role-badge@example.com',
      ),
      role: UserRole.publisher,
    );
  }
}

Future<void> _pumpDashboard(
  WidgetTester tester,
  OrganizationAccessState accessState,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        authSessionControllerProvider.overrideWithValue(
          _FakeSessionController(),
        ),
        postRepositoryProvider.overrideWithValue(PostRepositoryImpl()),
        accountRepositoryProvider.overrideWithValue(
          AccountRepositoryImpl(platformFactory: PlatformFactory()),
        ),
        analyticsRepositoryProvider.overrideWithValue(
          AnalyticsRepositoryImpl(),
        ),
        notificationRepositoryProvider.overrideWithValue(
          NotificationRepositoryImpl(),
        ),
        currentOrganizationAccessProvider.overrideWith(
          (ref) async => accessState,
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: DashboardScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

OrganizationEntity _membership(String role) {
  return OrganizationEntity(
    id: 1,
    name: 'Test Organization',
    slug: 'test-organization',
    role: role,
    isCurrent: true,
  );
}

void main() {
  testWidgets('shows the real organization role, not a legacy account role', (
    tester,
  ) async {
    final membership = _membership('owner');
    await _pumpDashboard(
      tester,
      OrganizationAccessState.active(
        memberships: <OrganizationEntity>[membership],
        currentOrganization: membership,
      ),
    );

    expect(find.text('Organization Owner'), findsOneWidget);
    expect(find.text('PUBLISHER'), findsNothing);
    expect(find.text('Guest'), findsNothing);
  });

  testWidgets('reflects the admin role', (tester) async {
    final membership = _membership('admin');
    await _pumpDashboard(
      tester,
      OrganizationAccessState.active(
        memberships: <OrganizationEntity>[membership],
        currentOrganization: membership,
      ),
    );

    expect(find.text('Admin'), findsOneWidget);
  });

  testWidgets('reflects the manager role', (tester) async {
    final membership = _membership('manager');
    await _pumpDashboard(
      tester,
      OrganizationAccessState.active(
        memberships: <OrganizationEntity>[membership],
        currentOrganization: membership,
      ),
    );

    expect(find.text('Manager'), findsOneWidget);
  });

  testWidgets('reflects the editor role', (tester) async {
    final membership = _membership('editor');
    await _pumpDashboard(
      tester,
      OrganizationAccessState.active(
        memberships: <OrganizationEntity>[membership],
        currentOrganization: membership,
      ),
    );

    expect(find.text('Editor'), findsOneWidget);
  });

  testWidgets('reflects the viewer role', (tester) async {
    final membership = _membership('viewer');
    await _pumpDashboard(
      tester,
      OrganizationAccessState.active(
        memberships: <OrganizationEntity>[membership],
        currentOrganization: membership,
      ),
    );

    expect(find.text('Viewer'), findsOneWidget);
  });

  testWidgets(
    'prompts to choose an organization when memberships exist but none is active',
    (tester) async {
      final other = _membership('editor');
      await _pumpDashboard(
        tester,
        OrganizationAccessState.noActiveOrganization(
          memberships: <OrganizationEntity>[other],
        ),
      );

      expect(find.text('Choose an organization'), findsOneWidget);
    },
  );

  testWidgets('shows no active membership when the user belongs to none', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      OrganizationAccessState.noActiveOrganization(
        memberships: const <OrganizationEntity>[],
      ),
    );

    expect(find.text('No active membership'), findsOneWidget);
  });
}
