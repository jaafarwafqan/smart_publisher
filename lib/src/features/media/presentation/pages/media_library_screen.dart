import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/theme/app_curves.dart';
import '../../../../core/theme/app_duration.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../shared/widgets/adaptive_content_width.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../organizations/application/current_organization_access.dart';
import '../../../posts/domain/entities/media_entity.dart';
import '../../../posts/domain/entities/post_entity.dart';

class MediaLibraryScreen extends ConsumerStatefulWidget {
  const MediaLibraryScreen({super.key});

  @override
  ConsumerState<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends ConsumerState<MediaLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MediaEntity> _items = const <MediaEntity>[];
  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 1;
  bool _hasMorePages = false;
  String? _error;
  String _typeFilter = 'all';
  String? _selectedMediaId;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool get _canCompressMedia {
    final access = ref.watch(currentOrganizationAccessProvider).valueOrNull;
    return access?.hasAnyPermission(<String>[
          OrganizationPermissions.postsUpdateOwn,
          OrganizationPermissions.postsUpdateAll,
        ]) ??
        false;
  }

  bool get _canDeleteMedia {
    final access = ref.watch(currentOrganizationAccessProvider).valueOrNull;
    return access?.hasAnyPermission(<String>[
          OrganizationPermissions.postsDeleteOwn,
          OrganizationPermissions.postsDeleteAll,
        ]) ??
        false;
  }

  Future<void> _loadMedia() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ref
        .read(mediaRepositoryProvider)
        .getMediaLibraryPage(
          type: _typeFilter == 'all' ? null : _typeFilter,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          page: 1,
        );

    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        final page = result.data;
        _items = page?.items ?? const <MediaEntity>[];
        _currentPage = page?.page ?? 1;
        _hasMorePages = page != null && _currentPage < page.totalPages;
      } else {
        _error = result.message ?? l10n.mediaFailedToLoad;
      }
    });
  }

  Future<void> _loadMoreMedia() async {
    setState(() {
      _loadingMore = true;
    });

    final result = await ref
        .read(mediaRepositoryProvider)
        .getMediaLibraryPage(
          type: _typeFilter == 'all' ? null : _typeFilter,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          page: _currentPage + 1,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _loadingMore = false;
      if (result.isSuccess) {
        final page = result.data;
        if (page != null) {
          _items = <MediaEntity>[..._items, ...page.items];
          _currentPage = page.page;
          _hasMorePages = _currentPage < page.totalPages;
        }
      }
      // A failed "load more" leaves the already-loaded items on screen —
      // only the initial load surfaces a page-replacing error state.
    });
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), _loadMedia);
  }

  Future<void> _deleteAsset(MediaEntity item) async {
    final result = await ref.read(mediaRepositoryProvider).deleteMedia(item.id);
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? l10n.mediaFailedDelete)),
      );
      return;
    }

    setState(() {
      _items = _items
          .where((asset) => asset.id != item.id)
          .toList(growable: false);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.mediaDeletedSuccess)));
  }

  Future<void> _compressAsset(MediaEntity item) async {
    final result = await ref.read(mediaRepositoryProvider).compressMedia(item);
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? l10n.mediaCompressedSuccess
              : result.message ?? l10n.mediaFailedCompress,
        ),
      ),
    );
    if (result.isSuccess) {
      await _loadMedia();
    }
  }

  Future<void> _reuseInPost(MediaEntity item) async {
    final postsResult = await ref.read(postRepositoryProvider).getPosts();
    final posts = postsResult.data ?? const <PostEntity>[];
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    if (posts.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.mediaNoPostsToAttach)));
      return;
    }

    final selectedPostId = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.mediaReuseDialogTitle),
        children: posts
            .map(
              (post) => SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(post.id),
                child: Text(
                  post.title.isEmpty ? l10n.postUntitled : post.title,
                ),
              ),
            )
            .toList(growable: false),
      ),
    );

    if (selectedPostId == null || !mounted) {
      return;
    }

    final result = await ref
        .read(mediaRepositoryProvider)
        .attachMediaToPost(mediaId: item.id, postId: selectedPostId);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? l10n.mediaAttachedSuccess
              : result.message ?? l10n.mediaFailedReuse,
        ),
      ),
    );
  }

  static String _typeOf(MediaEntity item) {
    if (item.mimeType.startsWith('video/')) {
      return 'video';
    }
    if (item.mimeType.startsWith('image/')) {
      return 'image';
    }
    return 'document';
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'image':
        return Icons.image_outlined;
      case 'video':
        return Icons.videocam_outlined;
      case 'document':
      default:
        return Icons.description_outlined;
    }
  }

  static String _formatDate(DateTime? date, AppLocalizations l10n) {
    if (date == null) {
      return l10n.mediaUnknownDate;
    }
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  /// Signed media URLs can include short-lived credentials in their query
  /// string. Only the path's final segment belongs in a visible or
  /// accessibility-facing label.
  static String _displayName(String value) {
    final path = Uri.tryParse(value)?.path ?? value.split('?').first;
    final segments = path
        .split('/')
        .where((segment) => segment.trim().isNotEmpty)
        .toList(growable: false);

    return segments.isEmpty ? 'media' : Uri.decodeComponent(segments.last);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mediaAppBarTitle)),
      body: AdaptiveContentWidth(
        child: RefreshIndicator(
          onRefresh: _loadMedia,
          // Code-quality review (2026-08-17), item B5/3.1: was a plain
          // `ListView(children: [...])` — every asset card was built
          // eagerly, not lazily as it scrolled into view. See
          // posts_list_screen.dart's own conversion for why a
          // `CustomScrollView`+`SliverList` (not a shrinkWrap-ped nested
          // ListView.builder) is the real fix.
          child: CustomScrollView(
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    Text(
                      l10n.mediaSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        labelText: l10n.mediaSearchLabel,
                        hintText: l10n.mediaSearchHint,
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: <Widget>[
                        _TypeChip(
                          label: l10n.mediaFilterAll,
                          selected: _typeFilter == 'all',
                          onTap: () {
                            setState(() => _typeFilter = 'all');
                            _loadMedia();
                          },
                        ),
                        _TypeChip(
                          label: l10n.mediaFilterImages,
                          selected: _typeFilter == 'image',
                          onTap: () {
                            setState(() => _typeFilter = 'image');
                            _loadMedia();
                          },
                        ),
                        _TypeChip(
                          label: l10n.mediaFilterVideos,
                          selected: _typeFilter == 'video',
                          onTap: () {
                            setState(() => _typeFilter = 'video');
                            _loadMedia();
                          },
                        ),
                        _TypeChip(
                          label: l10n.mediaFilterDocuments,
                          selected: _typeFilter == 'document',
                          onTap: () {
                            setState(() => _typeFilter = 'document');
                            _loadMedia();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ]),
                ),
              ),
              if (_loading)
                const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(_error!),
                            const SizedBox(height: AppSpacing.md),
                            OutlinedButton.icon(
                              onPressed: _loadMedia,
                              icon: const Icon(Icons.refresh),
                              label: Text(l10n.commonRetry),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else if (_items.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: AppEmptyState(
                      title: l10n.mediaEmptyTitle,
                      message: l10n.mediaEmptySubtitle,
                      icon: Icons.perm_media_outlined,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _items[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.md,
                          ),
                          child: _MediaCard(
                            item: item,
                            isSelected: _selectedMediaId == item.id,
                            canCompress: _canCompressMedia,
                            canDelete: _canDeleteMedia,
                            l10n: l10n,
                            onTap: () => setState(() {
                              _selectedMediaId =
                                  _selectedMediaId == item.id ? null : item.id;
                            }),
                            onCompress: () => _compressAsset(item),
                            onReuse: () => _reuseInPost(item),
                            onDelete: () => _deleteAsset(item),
                          ),
                        );
                      },
                      childCount: _items.length,
                    ),
                  ),
                ),
              if (!_loading && _error == null && _hasMorePages)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: OutlinedButton.icon(
                        onPressed: _loadingMore ? null : _loadMoreMedia,
                        icon: _loadingMore
                            ? const SizedBox(
                                width: AppSizes.iconSm,
                                height: AppSizes.iconSm,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.expand_more),
                        label: Text(l10n.mediaLoadMore),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({
    required this.item,
    required this.isSelected,
    required this.canCompress,
    required this.canDelete,
    required this.l10n,
    required this.onTap,
    required this.onCompress,
    required this.onReuse,
    required this.onDelete,
  });

  final MediaEntity item;
  final bool isSelected;
  final bool canCompress;
  final bool canDelete;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onCompress;
  final VoidCallback onReuse;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final type = _MediaLibraryScreenState._typeOf(item);
    final isImage = type == 'image';

    return AnimatedScale(
      scale: isSelected ? 1.01 : 1,
      duration: AppDuration.normal,
      curve: AppCurves.standard,
      child: AnimatedContainer(
        duration: AppDuration.normal,
        curve: AppCurves.standard,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: isSelected
              ? <BoxShadow>[
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.16),
                    blurRadius: AppSpacing.md,
                    offset: const Offset(0, AppSpacing.xs),
                  ),
                ]
              : null,
        ),
        child: Card(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (isImage && item.thumbnailUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Image.network(
                            item.thumbnailUrl!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                            errorBuilder: (context, error, stackTrace) =>
                                CircleAvatar(
                                  child: Icon(
                                    _MediaLibraryScreenState._iconForType(
                                      type,
                                    ),
                                  ),
                                ),
                          ),
                        )
                      else
                        CircleAvatar(
                          child: Icon(
                            _MediaLibraryScreenState._iconForType(type),
                          ),
                        ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _MediaLibraryScreenState._displayName(item.url),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${item.collection} • ${_MediaLibraryScreenState._formatDate(item.createdAt, l10n)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (item.tags.isNotEmpty) ...<Widget>[
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: item.tags
                                    .map(
                                      (tag) => Chip(
                                        label: Text(tag),
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    alignment: WrapAlignment.end,
                    children: <Widget>[
                      if (canCompress)
                        Tooltip(
                          message: isImage
                              ? l10n.mediaCompressTooltipImage
                              : l10n.mediaCompressTooltipOther,
                          child: OutlinedButton.icon(
                            onPressed: isImage ? onCompress : null,
                            icon: const Icon(Icons.compress, size: 18),
                            label: Text(l10n.mediaCompressButton),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: onReuse,
                        icon: const Icon(Icons.repeat, size: 18),
                        label: Text(l10n.mediaReuseInPostButton),
                      ),
                      if (canDelete)
                        IconButton(
                          tooltip: l10n.mediaDeleteTooltip,
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
