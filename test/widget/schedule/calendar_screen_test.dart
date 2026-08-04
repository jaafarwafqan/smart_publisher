import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/core/result/app_result.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/post_entity.dart';
import 'package:smart_publisher/src/features/schedule/domain/entities/schedule_entity.dart';
import 'package:smart_publisher/src/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:smart_publisher/src/features/schedule/presentation/pages/calendar_screen.dart';

import '../../helpers/localized_test_app.dart';

class _FakeScheduleRepository extends ScheduleRepository {
  _FakeScheduleRepository(this._entries, {this.failureMessage});

  final List<ScheduleEntity> _entries;
  final String? failureMessage;
  int getCalendarEntriesCalls = 0;

  @override
  Future<AppResult<List<ScheduleEntity>>> getCalendarEntries() async {
    getCalendarEntriesCalls += 1;
    if (failureMessage != null) {
      return Failure<List<ScheduleEntity>>(failureMessage!);
    }
    return Success<List<ScheduleEntity>>(_entries);
  }

  @override
  Future<AppResult<PostEntity>> schedulePost(PostEntity post) async {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> cancelSchedule(String postId) async {
    throw UnimplementedError();
  }
}

// The calendar's date picker + month/events cards push the day-list below
// the fold at the default test viewport size. `ListView(children:)` is
// Sliver-backed and only mounts widgets within the viewport + cache extent,
// so `find.*` finds nothing there unless the viewport is enlarged first.
Future<void> _pump(WidgetTester tester, ScheduleRepository fakeRepo) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        scheduleRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: const MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: CalendarScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'renders today\'s scheduled entry via getCalendarEntries, not getPosts',
    (tester) async {
      final today = DateTime.now();
      final fakeRepo = _FakeScheduleRepository(<ScheduleEntity>[
        ScheduleEntity(
          id: 'event-1',
          postId: '1',
          title: 'Launch announcement',
          status: 'scheduled',
          scheduledAt: DateTime(today.year, today.month, today.day, 9, 30),
        ),
      ]);

      await _pump(tester, fakeRepo);

      expect(fakeRepo.getCalendarEntriesCalls, 1);
      expect(find.text('Launch announcement'), findsOneWidget);
      expect(find.textContaining('Status: scheduled'), findsOneWidget);
    },
  );

  testWidgets('shows the empty state when nothing is scheduled today', (
    tester,
  ) async {
    final fakeRepo = _FakeScheduleRepository(const <ScheduleEntity>[]);

    await _pump(tester, fakeRepo);

    expect(find.text('No scheduled posts on this date.'), findsOneWidget);
  });

  testWidgets(
    'shows an error and retry instead of rendering a failed fetch as empty',
    (tester) async {
      final fakeRepo = _FakeScheduleRepository(
        const <ScheduleEntity>[],
        failureMessage: 'Network unreachable',
      );

      await _pump(tester, fakeRepo);

      expect(find.text('Network unreachable'), findsOneWidget);
      expect(find.text('No scheduled posts on this date.'), findsNothing);

      final retryButton = find.widgetWithText(OutlinedButton, 'Retry');
      expect(retryButton, findsOneWidget);

      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      expect(fakeRepo.getCalendarEntriesCalls, 2);
    },
  );
}
