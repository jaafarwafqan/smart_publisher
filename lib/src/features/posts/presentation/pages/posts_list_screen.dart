import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_curves.dart';
import '../../../../core/theme/app_duration.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../shared/widgets/adaptive_content_width.dart';
import '../../../../shared/widgets/app_async_switcher.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../../organizations/application/current_organization_access.dart';
import '../../application/posts_list_provider.dart';
import '../../domain/entities/post_entity.dart';

class PostsListScreen extends ConsumerStatefulWidget {
  const PostsListScreen({super.key});

  @override
  ConsumerState<PostsListScreen> createState() => _PostsListScreenState();
}

class _PostsListScreenState extends ConsumerState<PostsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _statusFilter = 'all';

  // Load-more-in-flight is transient, screen-local UI state (a spinner on
  // one button) — it deliberately stays local rather than living in
  // PostsListNotifier, which only tracks the data itself, not this
  // widget's own in-progress-tap feedback.
  bool _loadingMore = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PostEntity> _filterPosts(List<PostEntity> posts) {
    final query = _searchController.text.trim().toLowerCase();
    return posts
        .where((post) {
          final statusMatches =
              _statusFilter == 'all' || post.status == _statusFilter;
          final queryMatches =
              query.isEmpty ||
              post.title.toLowerCase().contains(query) ||
              post.body.toLowerCase().contains(query);
          return statusMatches && queryMatches;
        })
        .toList(growable: false);
  }

  bool get _canEditPosts {
    final access = ref.watch(currentOrganizationAccessProvider).valueOrNull;
    return access?.hasAnyPermission(<String>[
          OrganizationPermissions.postsUpdateOwn,
          OrganizationPermissions.postsUpdateAll,
        ]) ??
        false;
  }

  // Same shape as _canEditPosts: shown whenever the account holds either
  // the "own" or "all" grant, with the backend's PostPolicy::delete() doing
  // the real per-post ownership check (an "own"-only holder attempting a
  // colleague's post gets a 403 from the server) — the client button is a
  // usability convenience, not the trust boundary, matching every other
  // permission gate on this screen.
  bool get _canDeletePosts {
    final access = ref.watch(currentOrganizationAccessProvider).valueOrNull;
    return access?.hasAnyPermission(<String>[
          OrganizationPermissions.postsDeleteOwn,
          OrganizationPermissions.postsDeleteAll,
        ]) ??
        false;
  }

  final Set<String> _deletingIds = <String>{};

  Future<void> _loadMorePosts() async {
    setState(() => _loadingMore = true);
    await ref.read(postsListProvider.notifier).loadMore();
    if (!mounted) {
      return;
    }
    setState(() => _loadingMore = false);
  }

  Future<void> _deletePostWithConfirmation(PostEntity post) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.postsListDeleteDialogTitle),
        content: Text(l10n.postsListDeleteDialogBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _deletingIds.add(post.id));

    final success = await ref
        .read(postsListProvider.notifier)
        .deletePost(post.id);
    if (!mounted) {
      return;
    }

    setState(() => _deletingIds.remove(post.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? l10n.postsListDeleteSuccess : l10n.postsListDeleteFailed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsListProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final posts = _filterPosts(postsAsync.valueOrNull?.items ?? const []);
    final hasMorePages = postsAsync.valueOrNull?.hasMorePages ?? false;
    // AsyncLoading only means "no cached value to show yet" here — a
    // refresh() keeps the previous list visible (copyWithPrevious) rather
    // than blanking the screen, matching the prior _loading flag's role.
    final isInitialLoading = postsAsync.isLoading && !postsAsync.hasValue;
    final errorMessage = postsAsync.hasError
        ? (postsAsync.error is StateError
              ? (postsAsync.error! as StateError).message
              : postsAsync.error.toString())
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.postsListAppBarTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.postsListCreateTooltip,
            onPressed: () => context.push(RouteNames.postsCreatePath),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: AdaptiveContentWidth(
        child: RefreshIndicator(
          onRefresh: () => ref.read(postsListProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: <Widget>[
              Text(
                l10n.postsListHeadline,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.postsListSubtitle, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.postsListSearchLabel,
                  hintText: l10n.postsListSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  _StatusChip(
                    label: l10n.postsListFilterAll,
                    selected: _statusFilter == 'all',
                    onSelected: () => setState(() => _statusFilter = 'all'),
                  ),
                  _StatusChip(
                    label: l10n.postsListFilterDraft,
                    selected: _statusFilter == 'draft',
                    onSelected: () => setState(() => _statusFilter = 'draft'),
                  ),
                  _StatusChip(
                    label: l10n.postsListFilterScheduled,
                    selected: _statusFilter == 'scheduled',
                    onSelected: () =>
                        setState(() => _statusFilter = 'scheduled'),
                  ),
                  _StatusChip(
                    label: l10n.postsListFilterPublished,
                    selected: _statusFilter == 'published',
                    onSelected: () =>
                        setState(() => _statusFilter = 'published'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppAsyncSwitcher(
                state: isInitialLoading
                    ? AppAsyncState.loading
                    : errorMessage != null
                    ? AppAsyncState.error
                    : posts.isEmpty
                    ? AppAsyncState.empty
                    : AppAsyncState.content,
                loading: const Center(child: CircularProgressIndicator()),
                error: Text(
                  errorMessage ?? '',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                empty: AppEmptyState(message: l10n.postsListEmpty),
                content: _buildPostsContent(posts, l10n),
              ),
              if (!isInitialLoading && errorMessage == null && hasMorePages)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: _loadingMore ? null : _loadMorePosts,
                      icon: _loadingMore
                          ? const SizedBox(
                              width: AppSizes.iconSm,
                              height: AppSizes.iconSm,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.expand_more),
                      label: Text(l10n.postsListLoadMore),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.postsCreatePath),
        icon: const Icon(Icons.add),
        label: Text(l10n.postsListNewPostButton),
      ),
    );
  }

  Widget _buildPostsContent(List<PostEntity> posts, AppLocalizations l10n) {
    return Column(
      children: posts
          .map(
            (post) => Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    post.title.isEmpty ? '?' : post.title[0].toUpperCase(),
                  ),
                ),
                title: Text(
                  post.title.isEmpty ? l10n.postUntitled : post.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      post.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: <Widget>[
                        StatusPill(
                          label: _statusLabel(post.status, l10n),
                          tone: _toneForStatus(post.status),
                        ),
                        if (post.status == 'published' &&
                            post.publishedAt != null)
                          StatusPill(
                            label: l10n.postsListPublishedMeta(
                              _formatDateTime(post.publishedAt!),
                            ),
                            icon: Icons.check_circle_outline,
                          )
                        else if (post.status == 'scheduled' &&
                            post.scheduledAt != null)
                          StatusPill(
                            label: l10n.postsListScheduledMeta(
                              _formatDateTime(post.scheduledAt!),
                            ),
                            icon: Icons.schedule,
                          ),
                        StatusPill(
                          label: l10n.postsListMediaCountMeta(
                            post.attachments.length,
                          ),
                          icon: Icons.attach_file,
                        ),
                        StatusPill(
                          label: l10n.postsListPlatformsCountMeta(
                            post.platforms.length,
                          ),
                          icon: Icons.public,
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: !_canEditPosts && !_canDeletePosts
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (_canEditPosts)
                            IconButton(
                              tooltip: l10n.postsListEditTooltip,
                              onPressed: () => context.push(
                                RouteNames.postsCreatePath,
                                extra: post,
                              ),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                          if (_canDeletePosts)
                            IconButton(
                              tooltip: l10n.postsListDeleteTooltip,
                              onPressed: _deletingIds.contains(post.id)
                                  ? null
                                  : () => _deletePostWithConfirmation(post),
                              icon: _deletingIds.contains(post.id)
                                  ? const SizedBox(
                                      width: AppSizes.iconSm,
                                      height: AppSizes.iconSm,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.delete_outline),
                            ),
                        ],
                      ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }

  static PillTone _toneForStatus(String status) {
    switch (status) {
      case 'scheduled':
      case 'publishing':
      case 'partial_success':
        return PillTone.warning;
      case 'published':
        return PillTone.success;
      case 'failed':
        return PillTone.danger;
      case 'draft':
      case 'cancelled':
      default:
        return PillTone.neutral;
    }
  }

  static String _statusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'scheduled':
        return l10n.postsListFilterScheduled;
      case 'publishing':
        return l10n.postsListStatusPublishing;
      case 'published':
        return l10n.postsListFilterPublished;
      case 'failed':
        return l10n.postsListStatusFailed;
      case 'partial_success':
        return l10n.postsListStatusPartialSuccess;
      case 'cancelled':
        return l10n.postsListStatusCancelled;
      case 'draft':
      default:
        return l10n.postsListFilterDraft;
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: AnimatedContainer(
            duration: AppDuration.normal,
            curve: AppCurves.standard,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.secondaryContainer
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                AnimatedContainer(
                  duration: AppDuration.fast,
                  curve: AppCurves.standard,
                  width: selected ? AppSpacing.xl : 0,
                  height: AppSpacing.xs,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
