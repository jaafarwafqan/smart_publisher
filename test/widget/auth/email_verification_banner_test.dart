import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/core/events/event_bus.dart';
import 'package:smart_publisher/src/core/events/event_dispatcher.dart'
    as app_events;
import 'package:smart_publisher/src/core/security/encryption_service.dart';
import 'package:smart_publisher/src/core/security/secrets_manager.dart';
import 'package:smart_publisher/src/core/security/secure_token_storage.dart';
import 'package:smart_publisher/src/core/security/token_lifecycle_manager.dart';
import 'package:smart_publisher/src/core/storage/in_memory_storage_service.dart';
import 'package:smart_publisher/src/features/auth/application/auth_event_publisher.dart';
import 'package:smart_publisher/src/features/auth/application/auth_session_controller.dart';
import 'package:smart_publisher/src/features/auth/presentation/widgets/email_verification_banner.dart';

import '../../helpers/fake_network_client.dart';
import '../../helpers/localized_test_app.dart';

AuthSessionController _controllerWith(FakeNetworkClient client) {
  return AuthSessionController(
    networkClient: client,
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
}

Future<void> _pump(WidgetTester tester, AuthSessionController controller) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        authSessionControllerProvider.overrideWithValue(controller),
      ],
      child: const MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: Scaffold(body: EmailVerificationBanner()),
      ),
    ),
  );
}

void main() {
  testWidgets('renders nothing once the email is already verified', (
    tester,
  ) async {
    final controller = _controllerWith(
      FakeNetworkClient(
        getHandler: (path) async {
          return Response<dynamic>(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: <String, dynamic>{
              'success': true,
              'data': <String, dynamic>{
                'user': <String, dynamic>{'email_verified': true},
              },
            },
          );
        },
      ),
    );

    await _pump(tester, controller);
    await tester.pumpAndSettle();

    expect(find.byType(EmailVerificationBanner), findsOneWidget);
    expect(find.text('Resend verification email'), findsNothing);
  });

  testWidgets(
    'shows a banner with a resend action while the email is unverified',
    (tester) async {
      var resendCalled = false;
      final controller = _controllerWith(
        FakeNetworkClient(
          getHandler: (path) async {
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'data': <String, dynamic>{
                  'user': <String, dynamic>{'email_verified': false},
                },
              },
            );
          },
          postHandler: (path, data) async {
            resendCalled = true;
            expect(path, '/auth/email/verification-notification');
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'data': <String, dynamic>{'message': 'Verification link sent.'},
              },
            );
          },
        ),
      );

      await _pump(tester, controller);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Please verify your email address to keep full access to your account.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Resend verification email'));
      await tester.pumpAndSettle();

      expect(resendCalled, isTrue);
      expect(
        find.text('Verification link sent. Check your email.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('fails closed to showing nothing when the status check errors', (
    tester,
  ) async {
    final controller = _controllerWith(
      FakeNetworkClient(
        getHandler: (path) async {
          throw DioException(
            requestOptions: RequestOptions(path: path),
            type: DioExceptionType.connectionError,
          );
        },
      ),
    );

    await _pump(tester, controller);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Please verify your email address to keep full access to your account.',
      ),
      findsNothing,
    );
  });
}
