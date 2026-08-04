import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/core/router/guard_state_provider.dart';
import 'package:smart_publisher/src/core/storage/in_memory_storage_service.dart';
import 'package:smart_publisher/src/core/storage/storage_provider.dart';
import 'package:smart_publisher/src/features/analytics/data/repository/analytics_repository_impl.dart';
import 'package:smart_publisher/src/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:smart_publisher/src/features/posts/data/post_repository_impl.dart';

import '../../helpers/fake_network_client.dart';
import '../../helpers/localized_test_app.dart';

Future<Response<dynamic>> _dashboardResponse(
  String path, {
  String? bestPlatform,
  int? bestPublishHour,
}) async {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: <String, dynamic>{
      'success': true,
      'data': <String, dynamic>{
        'top_posts': <dynamic>[],
        'total_reach': 0,
        'total_engagement': 0,
        'total_impressions': 0,
        'average_engagement_rate': 0.0,
        'best_platform': bestPlatform,
        'best_publish_hour': bestPublishHour,
      },
    },
  );
}

Future<void> _pump(
  WidgetTester tester, {
  String? bestPlatform,
  int? bestPublishHour,
}) async {
  final storage = InMemoryStorageService();
  await storage.writeString(GuardStorageKeys.userRole, 'admin');

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        storageServiceProvider.overrideWithValue(storage),
        postRepositoryProvider.overrideWithValue(PostRepositoryImpl()),
        analyticsRepositoryProvider.overrideWithValue(
          AnalyticsRepositoryImpl(
            networkClient: FakeNetworkClient(
              getHandler: (path) => _dashboardResponse(
                path,
                bestPlatform: bestPlatform,
                bestPublishHour: bestPublishHour,
              ),
            ),
          ),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: AnalyticsScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  testWidgets(
    'shows "Not enough data yet" for Best Time/Platform when the backend reports null',
    (tester) async {
      await _pump(tester);

      expect(find.text('Best Time to Post'), findsOneWidget);
      expect(find.text('Best Platform'), findsOneWidget);
      expect(find.text('Not enough data yet'), findsNWidgets(2));
    },
  );

  testWidgets(
    'renders the real best time/platform once the backend has enough samples',
    (tester) async {
      await _pump(tester, bestPlatform: 'facebook', bestPublishHour: 14);

      expect(find.text('Facebook'), findsOneWidget);
      expect(find.text('2:00 PM'), findsOneWidget);
      expect(find.text('Not enough data yet'), findsNothing);
    },
  );

  testWidgets(
    'shows an error and retry instead of rendering a failed posts fetch as empty',
    (tester) async {
      final storage = InMemoryStorageService();
      await storage.writeString(GuardStorageKeys.userRole, 'admin');

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            storageServiceProvider.overrideWithValue(storage),
            postRepositoryProvider.overrideWithValue(
              PostRepositoryImpl(
                networkClient: FakeNetworkClient(
                  getHandler: (path) async {
                    throw DioException(
                      requestOptions: RequestOptions(path: path),
                      error: 'Network unreachable',
                    );
                  },
                ),
              ),
            ),
            analyticsRepositoryProvider.overrideWithValue(
              AnalyticsRepositoryImpl(
                networkClient: FakeNetworkClient(
                  getHandler: (path) => _dashboardResponse(path),
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: AnalyticsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No posts available for analytics yet.'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
    },
  );
}
