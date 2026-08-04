import 'package:intl/intl.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../posts/domain/entities/post_entity.dart';
import 'platform_label.dart';

/// Status-derived subtitle for a Recent Activity row, e.g. "Published to
/// Facebook", "Scheduled for tomorrow", "Failed on Instagram".
String activitySubtitle(
  PostEntity post,
  AppLocalizations l10n, {
  DateTime? now,
}) {
  final today = now ?? DateTime.now();

  switch (post.status) {
    case 'published':
      return l10n.activityPublishedTo(_firstPlatformLabel(post, l10n));
    case 'scheduled':
      return _scheduledSubtitle(post, today, l10n);
    case 'failed':
      return l10n.activityFailedOn(_firstPlatformLabel(post, l10n));
    case 'partial_success':
      return l10n.activityPartiallyPublished;
    case 'cancelled':
      return l10n.activityCancelled;
    case 'publishing':
      return l10n.activityCurrentlyPublishing;
    case 'draft':
    default:
      return l10n.activitySavedAsDraft;
  }
}

String _scheduledSubtitle(
  PostEntity post,
  DateTime now,
  AppLocalizations l10n,
) {
  final scheduledAt = post.scheduledAt;
  if (scheduledAt == null) {
    return l10n.activityScheduledForPublishing;
  }
  if (_isSameDay(scheduledAt, now)) {
    return l10n.activityScheduledForToday;
  }
  if (_isSameDay(scheduledAt, now.add(const Duration(days: 1)))) {
    return l10n.activityScheduledForTomorrow;
  }
  return l10n.activityScheduledForDate(_formatDate(scheduledAt, l10n));
}

String _formatDate(DateTime date, AppLocalizations l10n) =>
    DateFormat.yMMMd(l10n.localeName).format(date);

String _firstPlatformLabel(PostEntity post, AppLocalizations l10n) {
  if (post.platforms.isEmpty) {
    return l10n.activityThePlatform;
  }
  return platformLabel(post.platforms.first);
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
