import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/core/result/app_result.dart';
import 'package:smart_publisher/src/features/notifications/domain/entities/notification_entity.dart';
import 'package:smart_publisher/src/features/notifications/domain/repositories/notification_repository.dart';
import 'package:smart_publisher/src/features/notifications/presentation/screens/notifications_screen.dart';

import '../helpers/localized_test_app.dart';

class _FailingNotificationRepository extends NotificationRepository {
  @override
  Future<AppResult<List<NotificationEntity>>> getNotifications() async {
    return const Failure<List<NotificationEntity>>('Network unavailable');
  }

  @override
  Future<AppResult<void>> markAllAsRead() async => const Success<void>(null);

  @override
  Future<AppResult<void>> markAsRead(String id) async =>
      const Success<void>(null);
}

void main() {
  testWidgets('notification load failure is distinct from an empty inbox', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          notificationRepositoryProvider.overrideWithValue(
            _FailingNotificationRepository(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          home: const NotificationsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text(
        'Notifications could not be loaded. Check your connection and try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('No notifications available.'), findsNothing);
  });
}
