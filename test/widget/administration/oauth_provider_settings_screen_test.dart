import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/features/administration/data/system_settings_repository_impl.dart';
import 'package:smart_publisher/src/features/administration/presentation/screens/oauth_provider_settings_screen.dart';

import '../../helpers/fake_network_client.dart';
import '../../helpers/localized_test_app.dart';

void main() {
  testWidgets(
    'renders provider cards with the right Configured/Not Configured pill',
    (tester) async {
      final repository = SystemSettingsRepositoryImpl(
        networkClient: FakeNetworkClient(
          getHandler: (path) async {
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'data': <dynamic>[
                  <String, dynamic>{
                    'provider': 'facebook',
                    'client_id': 'fb-client-id',
                    'has_client_secret': true,
                    'is_enabled': true,
                  },
                  <String, dynamic>{
                    'provider': 'linkedin',
                    'client_id': null,
                    'has_client_secret': false,
                    'is_enabled': true,
                  },
                ],
              },
            );
          },
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemSettingsRepositoryProvider.overrideWith((ref) => repository),
          ],
          child: const MaterialApp(
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: OAuthProviderSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Facebook'), findsOneWidget);
      expect(find.text('LinkedIn'), findsOneWidget);
      expect(find.text('Configured (not yet tested)'), findsOneWidget);
      expect(find.text('Not Configured'), findsOneWidget);
      expect(find.text('Client ID: fb-client-id'), findsOneWidget);
      expect(find.text('Client ID: not set'), findsOneWidget);
    },
  );

  testWidgets(
    'renders a verified-status pill with last-tested time when the last test succeeded',
    (tester) async {
      final repository = SystemSettingsRepositoryImpl(
        networkClient: FakeNetworkClient(
          getHandler: (path) async {
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'data': <dynamic>[
                  <String, dynamic>{
                    'provider': 'facebook',
                    'client_id': 'fb-client-id',
                    'has_client_secret': true,
                    'is_enabled': true,
                    'last_test_success': true,
                    'last_tested_at': DateTime.now().toIso8601String(),
                  },
                ],
              },
            );
          },
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemSettingsRepositoryProvider.overrideWith((ref) => repository),
          ],
          child: const MaterialApp(
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: OAuthProviderSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('🟢 Configured'), findsOneWidget);
      expect(find.textContaining('Last verified:'), findsOneWidget);
      expect(find.text('Test Again'), findsNothing);
      expect(find.text('Test Connection'), findsOneWidget);
    },
  );

  testWidgets(
    'renders an invalid-configuration pill with a Test Again button when the last test failed',
    (tester) async {
      final repository = SystemSettingsRepositoryImpl(
        networkClient: FakeNetworkClient(
          getHandler: (path) async {
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'data': <dynamic>[
                  <String, dynamic>{
                    'provider': 'facebook',
                    'client_id': 'fb-client-id',
                    'has_client_secret': true,
                    'is_enabled': true,
                    'last_test_success': false,
                  },
                ],
              },
            );
          },
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemSettingsRepositoryProvider.overrideWith((ref) => repository),
          ],
          child: const MaterialApp(
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: OAuthProviderSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('🔴 Invalid Configuration'), findsOneWidget);
      expect(find.text('Test Again'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping Test Connection calls the repository and refreshes the status',
    (tester) async {
      var testCallCount = 0;

      final repository = SystemSettingsRepositoryImpl(
        networkClient: FakeNetworkClient(
          getHandler: (path) async {
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'data': <dynamic>[
                  <String, dynamic>{
                    'provider': 'facebook',
                    'client_id': 'fb-client-id',
                    'has_client_secret': true,
                    'is_enabled': true,
                    'last_test_success': testCallCount > 0 ? true : null,
                    'last_tested_at': testCallCount > 0
                        ? DateTime.now().toIso8601String()
                        : null,
                  },
                ],
              },
            );
          },
          postHandler: (path, data) async {
            testCallCount++;
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'data': <String, dynamic>{
                  'success': true,
                  'message': 'Facebook credentials verified successfully.',
                },
              },
            );
          },
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemSettingsRepositoryProvider.overrideWith((ref) => repository),
          ],
          child: const MaterialApp(
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: OAuthProviderSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configured (not yet tested)'), findsOneWidget);

      await tester.tap(find.text('Test Connection'));
      await tester.pumpAndSettle();

      expect(testCallCount, 1);
      expect(find.textContaining('🟢 Configured'), findsOneWidget);
      expect(
        find.text('Facebook credentials verified successfully.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'History sheet labels a userless audit entry as an automated check',
    (tester) async {
      final repository = SystemSettingsRepositoryImpl(
        networkClient: FakeNetworkClient(
          getHandler: (path) async {
            if (path.contains('audit-log')) {
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: <String, dynamic>{
                  'success': true,
                  'data': <dynamic>[
                    <String, dynamic>{
                      'action': 'tested',
                      'changed_fields': <String>[],
                      'success': true,
                      'user_name': null,
                      'created_at': DateTime.now().toIso8601String(),
                    },
                  ],
                },
              );
            }
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'data': <dynamic>[
                  <String, dynamic>{
                    'provider': 'facebook',
                    'client_id': 'fb-client-id',
                    'has_client_secret': true,
                    'is_enabled': true,
                  },
                ],
              },
            );
          },
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemSettingsRepositoryProvider.overrideWith((ref) => repository),
          ],
          child: const MaterialApp(
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: OAuthProviderSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Automated check'), findsOneWidget);
    },
  );

  testWidgets(
    'shows an error and retry instead of rendering a failed fetch as empty',
    (tester) async {
      final repository = SystemSettingsRepositoryImpl(
        networkClient: FakeNetworkClient(
          getHandler: (path) async {
            throw DioException(
              requestOptions: RequestOptions(path: path),
              error: 'Network unreachable',
            );
          },
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            systemSettingsRepositoryProvider.overrideWith((ref) => repository),
          ],
          child: const MaterialApp(
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: OAuthProviderSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load provider settings.'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
      expect(find.text('Facebook'), findsNothing);
    },
  );
}
