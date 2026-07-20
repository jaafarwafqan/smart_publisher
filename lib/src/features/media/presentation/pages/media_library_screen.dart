import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../../posts/domain/entities/post_entity.dart';

class MediaLibraryScreen extends ConsumerStatefulWidget {
  const MediaLibraryScreen({super.key});

  @override
  ConsumerState<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends ConsumerState<MediaLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<_MediaAssetItem> _assets = const <_MediaAssetItem>[];
  bool _loading = true;
  String _typeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    setState(() {
      _loading = true;
    });

    final result = await ref.read(postRepositoryProvider).getPosts();
    final posts = result.data ?? const <PostEntity>[];
    final assets = <_MediaAssetItem>[];

    for (final post in posts) {
      for (final url in post.attachments) {
        assets.add(
          _MediaAssetItem(
            id: 'media-${url.hashCode.abs()}',
            postId: post.id,
            title: post.title,
            url: url,
            type: _guessType(url),
            status: post.status,
            addedAt: post.updatedAt ?? post.createdAt ?? DateTime.now(),
          ),
        );
      }
    }

    if (!mounted) {
      return;
    }

    assets.sort((a, b) => b.addedAt.compareTo(a.addedAt));

    setState(() {
      _assets = assets;
      _loading = false;
    });
  }

  Future<void> _deleteAsset(_MediaAssetItem item) async {
    final result = await ref.read(mediaRepositoryProvider).deleteMedia(item.id);
    if (!mounted) {
      return;
    }

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Failed to delete media asset.')),
      );
      return;
    }

    setState(() {
      _assets = _assets.where((asset) => asset.id != item.id).toList(growable: false);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Media asset removed from library queue.')),
    );
  }

  List<_MediaAssetItem> get _filteredAssets {
    final query = _searchController.text.trim().toLowerCase();
    return _assets.where((item) {
      final queryMatches = query.isEmpty ||
          item.url.toLowerCase().contains(query) ||
          item.title.toLowerCase().contains(query) ||
          item.postId.toLowerCase().contains(query);
      final typeMatches = _typeFilter == 'all' || item.type == _typeFilter;
      return queryMatches && typeMatches;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredAssets;

    return Scaffold(
      appBar: AppBar(title: const Text('Media Library')),
      body: RefreshIndicator(
        onRefresh: _loadMedia,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            Text(
              'Manage uploaded media assets across your posts.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Search media',
                hintText: 'URL, post title, or post ID',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: <Widget>[
                _TypeChip(
                  label: 'All',
                  selected: _typeFilter == 'all',
                  onTap: () => setState(() => _typeFilter = 'all'),
                ),
                _TypeChip(
                  label: 'Images',
                  selected: _typeFilter == 'image',
                  onTap: () => setState(() => _typeFilter = 'image'),
                ),
                _TypeChip(
                  label: 'Videos',
                  selected: _typeFilter == 'video',
                  onTap: () => setState(() => _typeFilter = 'video'),
                ),
                _TypeChip(
                  label: 'Documents',
                  selected: _typeFilter == 'document',
                  onTap: () => setState(() => _typeFilter = 'document'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (items.isEmpty)
              const _EmptyMediaLibrary()
            else
              ...items.map(
                (item) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(_iconForType(item.type))),
                    title: Text(item.title.isEmpty ? 'Untitled post' : item.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 4),
                        Text(item.url, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('Post: ${item.postId} • ${item.status.toUpperCase()}'),
                        Text('Added: ${_formatDate(item.addedAt)}'),
                      ],
                    ),
                    trailing: IconButton(
                      tooltip: 'Delete media asset',
                      onPressed: () => _deleteAsset(item),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _guessType(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp')) {
      return 'image';
    }
    if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.mkv')) {
      return 'video';
    }
    if (lower.endsWith('.pdf') || lower.endsWith('.doc') || lower.endsWith('.docx')) {
      return 'document';
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

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}

class _MediaAssetItem {
  const _MediaAssetItem({
    required this.id,
    required this.postId,
    required this.title,
    required this.url,
    required this.type,
    required this.status,
    required this.addedAt,
  });

  final String id;
  final String postId;
  final String title;
  final String url;
  final String type;
  final String status;
  final DateTime addedAt;
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
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
  }
}

class _EmptyMediaLibrary extends StatelessWidget {
  const _EmptyMediaLibrary();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Icon(Icons.perm_media_outlined, size: 40),
            SizedBox(height: 10),
            Text('No media assets found.'),
            SizedBox(height: 4),
            Text('Attach media to posts, then revisit this library.'),
          ],
        ),
      ),
    );
  }
}
