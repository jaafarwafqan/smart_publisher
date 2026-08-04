import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';
import 'package:smart_publisher/src/features/dashboard/presentation/utils/activity_text.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/post_entity.dart';

void main() {
  final now = DateTime(2026, 6, 15, 12);
  final l10n = lookupAppLocalizations(const Locale('en'));

  setUpAll(() async {
    await initializeDateFormatting();
  });

  PostEntity post({
    required String status,
    DateTime? scheduledAt,
    List<String> platforms = const <String>[],
  }) {
    return PostEntity(
      id: '1',
      title: 'Test',
      body: 'body',
      status: status,
      scheduledAt: scheduledAt,
      platforms: platforms,
    );
  }

  test('published shows the first target platform', () {
    final result = activitySubtitle(
      post(status: 'published', platforms: <String>['facebook', 'x']),
      l10n,
      now: now,
    );
    expect(result, 'Published to Facebook');
  });

  test('published with no platforms falls back gracefully', () {
    final result = activitySubtitle(post(status: 'published'), l10n, now: now);
    expect(result, 'Published to the platform');
  });

  test('scheduled for later today', () {
    final result = activitySubtitle(
      post(status: 'scheduled', scheduledAt: DateTime(2026, 6, 15, 20)),
      l10n,
      now: now,
    );
    expect(result, 'Scheduled for today');
  });

  test('scheduled for tomorrow', () {
    final result = activitySubtitle(
      post(status: 'scheduled', scheduledAt: DateTime(2026, 6, 16, 8)),
      l10n,
      now: now,
    );
    expect(result, 'Scheduled for tomorrow');
  });

  test('scheduled for a specific future date', () {
    final result = activitySubtitle(
      post(status: 'scheduled', scheduledAt: DateTime(2026, 7, 4)),
      l10n,
      now: now,
    );
    expect(result, 'Scheduled for Jul 4, 2026');
  });

  test('scheduled with no date at all', () {
    final result = activitySubtitle(post(status: 'scheduled'), l10n, now: now);
    expect(result, 'Scheduled for publishing');
  });

  test('failed shows which platform', () {
    final result = activitySubtitle(
      post(status: 'failed', platforms: <String>['instagram']),
      l10n,
      now: now,
    );
    expect(result, 'Failed on Instagram');
  });

  test('publishing', () {
    final result = activitySubtitle(post(status: 'publishing'), l10n, now: now);
    expect(result, 'Currently publishing');
  });

  test('draft (and any unknown status) falls back to draft text', () {
    expect(
      activitySubtitle(post(status: 'draft'), l10n, now: now),
      'Saved as draft',
    );
    expect(
      activitySubtitle(post(status: 'something-else'), l10n, now: now),
      'Saved as draft',
    );
  });
}
