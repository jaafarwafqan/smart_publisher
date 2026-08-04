import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/analytics/domain/entities/analytics_summary_entity.dart';
import 'package:smart_publisher/src/features/dashboard/presentation/widgets/publishing_health_card.dart';

import '../../helpers/localized_test_app.dart';

void main() {
  testWidgets('shows the computed success rate, not a hardcoded number', (
    tester,
  ) async {
    final summary = AnalyticsSummaryEntity(
      totalPosts: 100,
      published: 90,
      failed: 10,
      scheduled: 0,
      draft: 0,
      engagementScore: 0.5,
      engagementTrend: 'up',
      updatedAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: Scaffold(
          body: PublishingHealthCard(
            summary: summary,
            platformDistribution: const <String, int>{'facebook': 3, 'x': 1},
            connectedAccounts: 2,
            totalAccounts: 6,
          ),
        ),
      ),
    );

    // published / (published + failed) = 90 / 100 = 90%
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('2/6'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('flags queue health when the failure rate is high', (
    tester,
  ) async {
    final summary = AnalyticsSummaryEntity(
      totalPosts: 20,
      published: 10,
      failed: 10,
      scheduled: 0,
      draft: 0,
      engagementScore: 0,
      engagementTrend: 'down',
      updatedAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: Scaffold(
          body: PublishingHealthCard(
            summary: summary,
            platformDistribution: const <String, int>{},
            connectedAccounts: 1,
            totalAccounts: 1,
          ),
        ),
      ),
    );

    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Needs attention'), findsOneWidget);
  });

  testWidgets('no delivered posts yet reads as 100% (nothing has failed)', (
    tester,
  ) async {
    final summary = AnalyticsSummaryEntity(
      totalPosts: 0,
      published: 0,
      failed: 0,
      scheduled: 0,
      draft: 0,
      engagementScore: 0,
      engagementTrend: 'stable',
      updatedAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: Scaffold(
          body: PublishingHealthCard(
            summary: summary,
            platformDistribution: const <String, int>{},
            connectedAccounts: 0,
            totalAccounts: 0,
          ),
        ),
      ),
    );

    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Stable'), findsOneWidget);
  });
}
