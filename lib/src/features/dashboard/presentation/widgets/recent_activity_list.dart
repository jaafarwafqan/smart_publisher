import 'package:flutter/material.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../posts/domain/entities/post_entity.dart';
import '../utils/activity_text.dart';
import 'dashboard_section_card.dart';

class RecentActivityList extends StatelessWidget {
  const RecentActivityList({super.key, required this.posts});

  final List<PostEntity> posts;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return DashboardSectionCard(
      title: l10n.recentActivityTitle,
      subtitle: l10n.recentActivitySubtitle,
      child: posts.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                l10n.recentActivityEmpty,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : Column(
              children: <Widget>[
                for (final post in posts)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.secondaryContainer,
                      child: Icon(
                        _iconFor(post.status),
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    title: Text(
                      post.title.isEmpty ? l10n.postUntitled : post.title,
                    ),
                    subtitle: Text(activitySubtitle(post, l10n)),
                    trailing: Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.chevron_left
                          : Icons.chevron_right,
                    ),
                  ),
              ],
            ),
    );
  }

  IconData _iconFor(String status) {
    switch (status) {
      case 'published':
        return Icons.check_circle_outline;
      case 'scheduled':
        return Icons.schedule;
      case 'failed':
        return Icons.error_outline;
      case 'partial_success':
        return Icons.warning_amber_outlined;
      case 'cancelled':
        return Icons.block_outlined;
      case 'publishing':
        return Icons.sync;
      case 'draft':
      default:
        return Icons.article_outlined;
    }
  }
}
