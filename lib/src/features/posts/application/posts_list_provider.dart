import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';
import '../domain/entities/post_entity.dart';

/// Code-quality review (2026-08-17), item B1/2.2: previously PostsListScreen
/// held pagination state (`_posts`/`_loading`/`_currentPage`/`_hasMorePages`)
/// as raw `setState`, refetched from scratch in `initState()` on every
/// navigation to the screen — even navigating away and immediately back
/// re-fetched page 1 from the network. This provider is `keepAlive` (the
/// default for [AsyncNotifierProvider], not `autoDispose`) specifically so
/// the fetched list survives navigation away/back; it only refetches on an
/// explicit trigger — [refresh] (pull-to-refresh), [loadMore], or a mutation
/// via [deletePost] — never on screen re-mount.
class PostsListState {
  const PostsListState({
    required this.items,
    required this.page,
    required this.hasMorePages,
  });

  static const PostsListState empty = PostsListState(
    items: <PostEntity>[],
    page: 1,
    hasMorePages: false,
  );

  final List<PostEntity> items;
  final int page;
  final bool hasMorePages;

  PostsListState copyWith({
    List<PostEntity>? items,
    int? page,
    bool? hasMorePages,
  }) {
    return PostsListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMorePages: hasMorePages ?? this.hasMorePages,
    );
  }
}

class PostsListNotifier extends AsyncNotifier<PostsListState> {
  @override
  Future<PostsListState> build() => _fetchPage(1);

  Future<PostsListState> _fetchPage(int page) async {
    final result = await ref
        .read(postRepositoryProvider)
        .getPostsPage(page: page);

    if (!result.isSuccess) {
      throw StateError(result.message ?? 'Failed to load posts');
    }

    final pageData = result.data;
    final items = pageData?.items ?? const <PostEntity>[];
    final currentPage = pageData?.page ?? page;
    final hasMorePages =
        pageData != null && currentPage < pageData.totalPages;

    return PostsListState(
      items: items,
      page: currentPage,
      hasMorePages: hasMorePages,
    );
  }

  /// Pull-to-refresh: replaces the whole cached list with a fresh page 1,
  /// same as the screen's previous `_loadPosts()`.
  Future<void> refresh() async {
    state = const AsyncValue<PostsListState>.loading().copyWithPrevious(
      state,
    );
    state = await AsyncValue.guard(() => _fetchPage(1));
  }

  /// A failed "load more" leaves the already-loaded posts on screen —
  /// matching the previous screen-local behavior: only the initial
  /// load/refresh surfaces a page-replacing error, since a load-more
  /// failure isn't "we have nothing to show," just "we couldn't get the
  /// next batch."
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMorePages) {
      return;
    }

    final result = await ref
        .read(postRepositoryProvider)
        .getPostsPage(page: current.page + 1);

    if (!result.isSuccess) {
      return;
    }

    final pageData = result.data;
    if (pageData == null) {
      return;
    }

    state = AsyncValue<PostsListState>.data(
      current.copyWith(
        items: <PostEntity>[...current.items, ...pageData.items],
        page: pageData.page,
        hasMorePages: pageData.page < pageData.totalPages,
      ),
    );
  }

  /// Deletes remotely, then updates the cached list in place — no refetch
  /// needed for a mutation this small.
  Future<bool> deletePost(String postId) async {
    final result = await ref.read(postRepositoryProvider).deletePost(postId);

    if (result.isSuccess) {
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncValue<PostsListState>.data(
          current.copyWith(
            items: current.items
                .where((PostEntity post) => post.id != postId)
                .toList(growable: false),
          ),
        );
      }
    }

    return result.isSuccess;
  }
}

final postsListProvider =
    AsyncNotifierProvider<PostsListNotifier, PostsListState>(
      PostsListNotifier.new,
    );
