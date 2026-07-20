import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/router/route_names.dart';
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

    final result = await ref.read(postRepositoryProvider).getPosts();
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _posts = result.data ?? const <PostEntity>[];
      } else {
        _error = result.message ?? 'Failed to load posts.';
      }
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

  @override
  Widget build(BuildContext context) {
    final posts = _filteredPosts;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Create post',
            onPressed: () => context.go(RouteNames.postsCreatePath),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            Text('Posts Library', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Search, filter, and edit your drafts, scheduled, and published posts.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Search posts',
                hintText: 'Title or content',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _StatusChip(
                  label: 'All',
                  selected: _statusFilter == 'all',
                  onSelected: () => setState(() => _statusFilter = 'all'),
                ),
                _StatusChip(
                  label: 'Draft',
                  selected: _statusFilter == 'draft',
                  onSelected: () => setState(() => _statusFilter = 'draft'),
                ),
                _StatusChip(
                  label: 'Scheduled',
                  selected: _statusFilter == 'scheduled',
                  onSelected: () => setState(() => _statusFilter = 'scheduled'),
                ),
                _StatusChip(
                  label: 'Published',
                  selected: _statusFilter == 'published',
                  onSelected: () => setState(() => _statusFilter = 'published'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(_error!, style: TextStyle(color: theme.colorScheme.error))
            else if (posts.isEmpty)
              const _EmptyPostsState()
            else
              ...posts.map(
                (post) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        post.title.isEmpty ? '?' : post.title[0].toUpperCase(),
                      ),
                    ),
                    title: Text(
                      post.title.isEmpty ? 'Untitled post' : post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 4),
                        Text(
                          post.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: <Widget>[
                            _StatusBadge(status: post.status),
                            if (post.scheduledAt != null)
                              _MetaBadge(
                                text:
                                    'Scheduled ${_formatDateTime(post.scheduledAt!)}',
                                icon: Icons.schedule,
                              ),
                            _MetaBadge(
                              text: '${post.attachments.length} media',
                              icon: Icons.attach_file,
                            ),
                            _MetaBadge(
                              text: '${post.platforms.length} platforms',
                              icon: Icons.public,
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      tooltip: 'Edit draft',
                      onPressed: () =>
                          context.go(RouteNames.postsCreatePath, extra: post),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(RouteNames.postsCreatePath),
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
      ),
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
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool warning = status == 'scheduled';
    final bool success = status == 'published';

    Color bg = colorScheme.secondaryContainer;
    Color fg = colorScheme.onSecondaryContainer;

    if (warning) {
      bg = colorScheme.tertiaryContainer;
      fg = colorScheme.onTertiaryContainer;
    }
    if (success) {
      bg = colorScheme.primaryContainer;
      fg = colorScheme.onPrimaryContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _EmptyPostsState extends StatelessWidget {
  const _EmptyPostsState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Icon(Icons.inbox_outlined, size: 40),
            SizedBox(height: 10),
            Text('No posts found for this filter.'),
          ],
        ),
      ),
    );
  }
}
