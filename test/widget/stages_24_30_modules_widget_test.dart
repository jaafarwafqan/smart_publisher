import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/core/router/guard_state_provider.dart';
import 'package:smart_publisher/src/core/storage/in_memory_storage_service.dart';
import 'package:smart_publisher/src/core/storage/storage_provider.dart';
import 'package:smart_publisher/src/features/administration/presentation/screens/administration_screen.dart';
import 'package:smart_publisher/src/features/analytics/data/repository/analytics_repository_impl.dart';
import 'package:smart_publisher/src/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:smart_publisher/src/features/distribution/presentation/pages/production_release_screen.dart';
import 'package:smart_publisher/src/features/media/presentation/pages/media_library_screen.dart';
import 'package:smart_publisher/src/features/notifications/data/notification_repository_impl.dart';
import 'package:smart_publisher/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:smart_publisher/src/features/posts/data/post_repository_impl.dart';
import 'package:smart_publisher/src/features/schedule/presentation/pages/calendar_screen.dart';
import 'package:smart_publisher/src/features/settings/presentation/screens/settings_screen.dart';

void main() {
  Future<void> pumpModule(WidgetTester tester, Widget child) async {
    final storage = InMemoryStorageService();
    await storage.writeString(GuardStorageKeys.userRole, 'admin');

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          storageServiceProvider.overrideWithValue(storage),
          postRepositoryProvider.overrideWithValue(PostRepositoryImpl()),
          analyticsRepositoryProvider.overrideWithValue(
            AnalyticsRepositoryImpl(),
          ),
          notificationRepositoryProvider.overrideWithValue(
            NotificationRepositoryImpl(),
          ),
          currentUserRoleProvider.overrideWith((ref) async => UserRole.admin),
        ],
        child: MaterialApp(home: child),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('Media library screen renders', (tester) async {
    await pumpModule(tester, const MediaLibraryScreen());
    expect(find.text('Media Library'), findsOneWidget);
  });

  testWidgets('Calendar screen renders', (tester) async {
    await pumpModule(tester, const CalendarScreen());
    expect(find.text('Publishing Calendar'), findsOneWidget);
  });

  testWidgets('Analytics screen renders', (tester) async {
    await pumpModule(tester, const AnalyticsScreen());
    expect(find.text('Analytics'), findsOneWidget);
  });

  testWidgets('Notifications screen renders', (tester) async {
    await pumpModule(tester, const NotificationsScreen());
    expect(find.text('Notifications'), findsOneWidget);
  });

  testWidgets('Settings screen renders', (tester) async {
    await pumpModule(tester, const SettingsScreen());
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Administration screen renders', (tester) async {
    await pumpModule(tester, const AdministrationScreen());
    expect(find.text('Administration'), findsOneWidget);
  });

  testWidgets('Production release screen renders', (tester) async {
    await pumpModule(tester, const ProductionReleaseScreen());
    expect(find.text('Production Release'), findsOneWidget);
  });
}
