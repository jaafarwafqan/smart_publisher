import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/di/app_providers.dart';
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
import '../../domain/entities/post_entity.dart';

class PostsListScreen extends ConsumerStatefulWidget {
  const PostsListScreen({super.key});

  @override
  ConsumerState<PostsListScreen> createState() => _PostsListScreenState();
}

class _PostsListScreenState extends ConsumerState<PostsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<PostEntity> _posts = const <PostEntity>[];
  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 1;
  bool _hasMorePages = false;
  String _statusFilter = 'all';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ref.read(postRepositoryProvider).getPostsPage(page: 1);
    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        final page = result.data;
        _posts = page?.items ?? const <PostEntity>[];
        _currentPage = page?.page ?? 1;
        _hasMorePages = page != null && _currentPage < page.totalPages;
      } else {
        _error = result.message ?? l10n.postsListFailedToLoad;
      }
    });
  }

  Future<void> _loadMorePosts() async {
    setState(() {
      _loadingMore = true;
    });

    final result = await ref
        .read(postRepositoryProvider)
        .getPostsPage(page: _currentPage + 1);
    if (!mounted) {
      return;
    }

    setState(() {
      _loadingMore = false;
      if (result.isSuccess) {
        final page = result.data;
        if (page != null) {
          _posts = <PostEntity>[..._posts, ...page.items];
          _currentPage = page.page;
          _hasMorePages = _currentPage < page.totalPages;
        }
      }
      // A failed "load more" leaves the already-loaded posts on screen —
      // only the initial load surfaces a page-replacing error state, since
      // a load-more failure isn't "we have nothing to show," just "we
      // couldn't get the next batch." The button stays available to retry.
    });
  }

  List<PostEntity> get _filteredPosts {
    final query = _searchController.text.trim().toLowerCase();
    return _posts
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

  @override
  Widget build(BuildContext context) {
    final posts = _filteredPosts;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.postsListAppBarTitle),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.postsListCreateTooltip,
            onPressed: () => context.go(RouteNames.postsCreatePath),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: AdaptiveContentWidth(
        child: RefreshIndicator(
          onRefresh: _loadPosts,
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
                spacing: 8,
                runSpacing: 8,
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
                state: _loading
                    ? AppAsyncState.loading
                    : _error != null
                    ? AppAsyncState.error
                    : posts.isEmpty
                    ? AppAsyncState.empty
                    : AppAsyncState.content,
                loading: const Center(child: CircularProgressIndicator()),
                error: Text(
                  _error ?? '',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                empty: AppEmptyState(message: l10n.postsListEmpty),
                content: _buildPostsContent(posts, l10n),
              ),
              if (!_loading && _error == null && _hasMorePages)
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
        onPressed: () => context.go(RouteNames.postsCreatePath),
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
                      spacing: 8,
                      runSpacing: 6,
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
                trailing: _canEditPosts
                    ? IconButton(
                        tooltip: l10n.postsListEditTooltip,
                        onPressed: () =>
                            context.go(RouteNames.postsCreatePath, extra: post),
                        icon: const Icon(Icons.edit_outlined),
                      )
                    : null,
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
