import 'package:flutter/material.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../posts/domain/entities/post_entity.dart';

/// A compact tile for one post-status view (Scheduled Today, Publishing
/// Queue, Failed Posts, Last Published, Upcoming Schedule) — fills the
/// space that used to sit empty below the stat tiles.
class PostStatusSection extends StatelessWidget {
  const PostStatusSection({
    super.key,
    required this.title,
    required this.icon,
    required this.posts,
    required this.onViewAll,
    this.emptyMessage,
  });

  final String title;
  final IconData icon;
  final List<PostEntity> posts;
  final VoidCallback onViewAll;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  '${posts.length}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (posts.isEmpty)
              Text(
                emptyMessage ?? l10n.postStatusSectionDefaultEmpty,
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              for (final post in posts.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    post.title.isEmpty ? l10n.postUntitled : post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            if (posts.isNotEmpty)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: onViewAll,
                  child: Text(l10n.viewAll),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
