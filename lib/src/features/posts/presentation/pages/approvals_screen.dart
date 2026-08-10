import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/adaptive_content_width.dart';
import '../../../../shared/widgets/app_async_switcher.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/status_pill.dart';
import '../../domain/entities/post_entity.dart';

/// Manager/admin/owner review queue for posts an editor submitted for
/// approval (Sprint F, role/permission remediation). Reuses
/// PostsListScreen's exact loading/pagination/error-state shape — see that
/// file for the established pattern this mirrors — but lists only the
/// pending queue (GET /posts?approval_status=pending) and offers
/// approve/reject instead of edit.
class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  List<PostEntity> _posts = const <PostEntity>[];
  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 1;
  bool _hasMorePages = false;
  String? _error;

  // Tracks which post ids currently have an approve/reject request in
  // flight, so a double-tap can't fire the same decision twice and each
  // card can show its own inline spinner instead of blocking the page.
  final Set<String> _decidingIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ref
        .read(postRepositoryProvider)
        .getPendingApprovalsPage(page: 1);
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
        _error = result.message ?? l10n.approvalsFailedToLoad;
      }
    });
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);

    final result = await ref
        .read(postRepositoryProvider)
        .getPendingApprovalsPage(page: _currentPage + 1);
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
    });
  }

  Future<void> _approve(PostEntity post) async {
    setState(() => _decidingIds.add(post.id));

    final result = await ref.read(postRepositoryProvider).approvePost(post.id);
    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _decidingIds.remove(post.id);
      if (result.isSuccess) {
        _posts = _posts.where((item) => item.id != post.id).toList();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? l10n.approvalsApproveSuccess
              : result.message ?? l10n.approvalsFailedToLoad,
        ),
      ),
    );
  }

  Future<void> _rejectWithDialog(PostEntity post) async {
    final l10n = AppLocalizations.of(context)!;
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.approvalsRejectDialogTitle),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.approvalsRejectDialogNoteLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.approvalsRejectDialogConfirm),
          ),
        ],
      ),
    );

    final note = noteController.text;
    noteController.dispose();
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _decidingIds.add(post.id));

    final result = await ref
        .read(postRepositoryProvider)
        .rejectPost(post.id, note: note);
    if (!mounted) {
      return;
    }

    setState(() {
      _decidingIds.remove(post.id);
      if (result.isSuccess) {
        _posts = _posts.where((item) => item.id != post.id).toList();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? l10n.approvalsRejectSuccess
              : result.message ?? l10n.approvalsFailedToLoad,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.approvalsAppBarTitle)),
      body: AdaptiveContentWidth(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: <Widget>[
              Text(
                l10n.approvalsHeadline,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.approvalsSubtitle, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              AppAsyncSwitcher(
                state: _loading
                    ? AppAsyncState.loading
                    : _error != null
                    ? AppAsyncState.error
                    : _posts.isEmpty
                    ? AppAsyncState.empty
                    : AppAsyncState.content,
                loading: const Center(child: CircularProgressIndicator()),
                error: Text(
                  _error ?? '',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                empty: AppEmptyState(
                  message: l10n.approvalsEmpty,
                  icon: Icons.check_circle_outline,
                ),
                content: _buildContent(l10n),
              ),
              if (!_loading && _error == null && _hasMorePages)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: _loadingMore ? null : _loadMore,
                      icon: _loadingMore
                          ? const SizedBox(
                              width: AppSizes.iconSm,
                              height: AppSizes.iconSm,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.expand_more),
                      label: Text(l10n.approvalsLoadMore),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    return Column(
      children: _posts
          .map(
            (post) => _ApprovalCard(
              post: post,
              deciding: _decidingIds.contains(post.id),
              onApprove: () => _approve(post),
              onReject: () => _rejectWithDialog(post),
              l10n: l10n,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.post,
    required this.deciding,
    required this.onApprove,
    required this.onReject,
    required this.l10n,
  });

  final PostEntity post;
  final bool deciding;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              post.title.isEmpty ? l10n.postUntitled : post.title,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(post.body, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                if (post.authorName != null)
                  StatusPill(
                    label: l10n.approvalsRequestedByMeta(post.authorName!),
                    icon: Icons.person_outline,
                  ),
                StatusPill(
                  label: post.approvalRequestedAction == 'publish_now'
                      ? l10n.approvalsRequestedActionPublishNow
                      : l10n.approvalsRequestedActionSchedule,
                  tone: PillTone.warning,
                  icon: Icons.schedule_send_outlined,
                ),
                StatusPill(
                  label: l10n.postsListPlatformsCountMeta(
                    post.platforms.length,
                  ),
                  icon: Icons.public,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: deciding ? null : onReject,
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(l10n.approvalsRejectButton),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: deciding ? null : onApprove,
                  icon: deciding
                      ? const SizedBox(
                          width: AppSizes.iconSm,
                          height: AppSizes.iconSm,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(l10n.approvalsApproveButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
